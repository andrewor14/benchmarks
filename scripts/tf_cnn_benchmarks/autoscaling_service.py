#!/usr/bin/env python3

import json
import threading
import xmlrpc.server

import cnn_util


def log_fn(msg):
  cnn_util.log_fn("[Autoscaling service]: %s" % msg)

def listen_for_autoscaling_requests(benchmark_cnn, host_port):
  '''
  Start a server listening for autoscaling requests

  This is a simple RPC server that exposes an interface for adjusting
  the number of workers in a running job.
  '''
  log_fn("Listening for autoscaling requests on host port %s" % host_port)
  split = host_port.split(":")
  server = xmlrpc.server.SimpleXMLRPCServer(
    (split[0], int(split[1])), logRequests=False, allow_none=True)
  server.register_introspection_functions()
  server.register_multicall_functions()
  server.register_instance(AutoscalingService(benchmark_cnn))
  threading.Thread(target=server.serve_forever).start()


class AutoscalingService:
  '''
  A service for handling autoscaling requests.
  '''
  def __init__(self, benchmark_cnn):
    self.benchmark_cnn = benchmark_cnn

  def get_params(self):
    return str(self.benchmark_cnn.params)

  def get_cluster_spec(self):
    # Note: do not hold `self.initialize_lock` here because this is called during initialization
    params = self.benchmark_cnn.params
    cluster_spec = cnn_util.make_cluster_spec(params)
    return json.dumps(cluster_spec)

  def get_global_batch_size(self):
    # Note: do not hold `self.initialize_lock` here because this is called during initialization
    return self.benchmark_cnn.global_batch_size

  def join_cluster(self, host_port):
    '''
    Handle a join request, only called on the master server.

    If the join request comes from a new worker, inform everyone in the cluster to add
    this worker. Otherwise, do nothing. If the join request is received during initialization,
    the request will be handled only after initialization is complete.
    '''
    log_fn("Received join cluster request for %s" % host_port)
    cluster_spec = cnn_util.make_cluster_spec(self.benchmark_cnn.params)
    ps_hosts = cluster_spec["ps"] if "ps" in cluster_spec else []
    worker_hosts = cluster_spec["worker"]
    host_ports = ps_hosts + worker_hosts
    if host_port not in host_ports:
      # Wait until initialization is done
      self.benchmark_cnn.initialize_lock.acquire()
      self.benchmark_cnn.initialize_lock.release()
      # Calling autoscaling_client.add_worker directly will hang because this server
      # is single threaded and so cannot process the add_workers request asynchronously.
      # Thus, we should avoid sending the request to ourselves (the master server).
      client = self.benchmark_cnn.autoscaling_client
      for server in client.servers:
        if server != client.master_server:
          server.add_workers([host_port])
      self.add_workers([host_port])
    return True

  def add_workers(self, host_ports):
    log_fn("Adding these workers %s" % host_ports)
    self.benchmark_cnn.initialize_lock.acquire()
    try:
      cluster_spec = cnn_util.make_cluster_spec(self.benchmark_cnn.params)
      cluster_spec["worker"].extend(host_ports)
      self.benchmark_cnn.apply_cluster_spec(cluster_spec)
      self.benchmark_cnn.should_restart = True
    finally:
      self.benchmark_cnn.initialize_lock.release()

  def remove_workers(self, host_ports):
    log_fn("Removing these workers %s" % host_ports)
    self.benchmark_cnn.initialize_lock.acquire()
    try:
      cluster_spec = cnn_util.make_cluster_spec(self.benchmark_cnn.params)
      for hp in host_ports:
        cluster_spec["worker"].remove(hp)
        if hp == self.benchmark_cnn.params.host_port:
          self.benchmark_cnn.should_terminate = True
      self.benchmark_cnn.apply_cluster_spec(cluster_spec)
      self.benchmark_cnn.should_restart = True
    finally:
      self.benchmark_cnn.initialize_lock.release()


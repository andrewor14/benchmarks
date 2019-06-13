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
    params = self.benchmark_cnn.params
    cluster_spec = cnn_util.make_cluster_spec(params)
    return json.dumps(cluster_spec)

  def get_global_batch_size(self):
    return self.benchmark_cnn.global_batch_size

  def add_workers(self, host_ports):
    log_fn("Adding these workers %s" % host_ports)
    cluster_spec = cnn_util.make_cluster_spec(self.benchmark_cnn.params)
    cluster_spec["worker"].extend(host_ports)
    self.benchmark_cnn.apply_cluster_spec(cluster_spec)
    self.benchmark_cnn.should_restart = True

  def remove_workers(self, host_ports):
    log_fn("Removing these workers %s" % host_ports)
    cluster_spec = cnn_util.make_cluster_spec(self.benchmark_cnn.params)
    for hp in host_ports:
      cluster_spec["worker"].remove(hp)
      if hp == self.benchmark_cnn.params.host_port:
        self.benchmark_cnn.should_terminate = True
    self.benchmark_cnn.apply_cluster_spec(cluster_spec)
    self.benchmark_cnn.should_restart = True


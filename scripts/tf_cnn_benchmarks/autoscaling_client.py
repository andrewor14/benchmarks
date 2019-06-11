#!/usr/bin/env python3

import copy
import json
import xmlrpc.client
import sys
import time


# Offset between autoscaling RPC port and gRPC port
RPC_PORT_OFFSET = 7000
# How much time to wait before retrying a failed RPC
RETRY_INTERVAL_SECONDS = 1
# Are we running in a shell?
RUNNING_IN_SHELL = sys.__stdin__.isatty()


def log_fn(msg):
  msg = "[Autoscaling client]: %s" % msg
  if RUNNING_IN_SHELL:
    print(msg)
  else:
    import cnn_util
    cnn_util.log_fn(msg)

def convert_port(host_port):
  '''
  Helper method to convert a gRPC port to an autoscaling service port.
  '''
  split = host_port.split(":")
  new_port = int(split[1]) + RPC_PORT_OFFSET
  return "%s:%s" % (split[0], new_port)

def connect(host_port):
  '''
  Connect to the given host port and return the corresponding ServerProxy object.

  If `convert_port` is true, convert the gRPC port to an autoscaling RPC port.
  This method retries indefinitely until success.
  '''
  if not host_port.startswith("http://"):
    host_port = "http://%s" % host_port
  log_fn("Connecting to autoscaling server at %s" % host_port)
  server = xmlrpc.client.ServerProxy(host_port)
  while True:
    try:
      # The connection is not complete until we can access the server's methods
      server.system.listMethods()
      log_fn("Connected to autoscaling server at %s!" % host_port)
      return server
    except (ConnectionRefusedError, OSError) as e:
      log_fn("... connection to %s failed, trying again in %s second(s)"\
        % (host_port, RETRY_INTERVAL_SECONDS))
      time.sleep(RETRY_INTERVAL_SECONDS)
    except Exception as e:
      log_fn("Unexpected error %s (%s)" % (e, type(e)))
      raise e


class AutoscalingClient:

  def __init__(self, master_host_port):
    self.master_server = connect(master_host_port)
    self._cluster_spec = None
    self._servers = None
    self.reset()

  def reset(self):
    '''
    Open a connection to each server in the system, found by fetching the cluster spec
    from the given master host port.
    '''
    cluster_spec = self.master_server.get_cluster_spec()
    cluster_spec = json.loads(cluster_spec)
    self._cluster_spec = cluster_spec
    self._servers = {}

  @property
  def ps_hosts(self):
    return self._cluster_spec["ps"].copy() if "ps" in self._cluster_spec else []

  @property
  def worker_hosts(self):
    # Assume there will always be at least one worker
    return self._cluster_spec["worker"].copy()

  @property
  def hosts(self):
    return self.ps_hosts + self.worker_hosts

  @property
  def cluster_spec(self):
    return copy.deepcopy(self._cluster_spec)

  @property
  def servers(self):
    '''
    Return the ServerProxy objects associated with the hosts in the system.
    All RPC calls should go through this accessor.
    '''
    # If there are workers we know about but haven't connected to yet, connect to them
    if len(self.hosts) > len(self._servers):
      pending_hosts = list(set(self.hosts) - set(self._servers.keys()))
      for hp in pending_hosts:
        self._servers[hp] = connect(convert_port(hp))
    # Otherwise, if there are expired workers, remove them
    elif len(self.hosts) < len(self._servers):
      expired_hosts = list(set(self._servers.keys()) - set(self.hosts))
      for hp in expired_hosts:
        del self._servers[hp]
    # Make sure we are connected to all hosts we know about
    if len(self.hosts) != len(self._servers):
      raise ValueError("Number of hosts is different from number of server proxies!\n" +
        "Hosts: %s\nServer proxies: %s" % (self.hosts, self._servers.keys()))
    return list(self._servers.values())

  def add_worker(self, host_port):
    '''
    Add a worker identified by the given host_port to the system.
    '''
    self.add_workers([host_port])

  def remove_worker(self, host_port):
    '''
    Remove a worker identified by the given host_port from the system.
    '''
    self.remove_workers([host_port])

  def add_workers(self, host_ports):
    '''
    Add workers identified by the given host_ports to the system.
    '''
    known_host_ports = [hp for hp in host_ports if hp in self.worker_hosts]
    new_host_ports = [hp for hp in host_ports if hp not in self.worker_hosts]
    if len(known_host_ports) > 0:
      log_fn("Warning: not adding the following workers because they already exist: %s" % known_host_ports)
    for server in self.servers:
      server.add_workers(new_host_ports)
    self._cluster_spec["worker"].extend(new_host_ports)

  def remove_workers(self, host_ports):
    '''
    Remove workers identified by the given host_ports from the system.
    Note: the first worker may not be removed because that's the one we use for syncing cluster membership.
    '''
    known_host_ports = [hp for hp in host_ports if hp in self.worker_hosts]
    new_host_ports = [hp for hp in host_ports if hp not in self.worker_hosts]
    if len(new_host_ports) > 0:
      log_fn("Warning: not removing the following workers because they are not known to us: %s" % new_host_ports)
    if len(known_host_ports) == 0:
      log_fn("Warning: not removing any workers")
      return
    # Check if there are workers to remove in the first place
    workers = self._cluster_spec["worker"]
    if len(workers) == 0:
      raise ValueError("No workers to remove")
    # Do not allow removing the first worker
    first_worker = workers[0]
    if first_worker in known_host_ports:
      raise ValueError("Not allowed to remove the first worker %s" % first_worker)
    # Actually remove
    for server in self.servers:
      server.remove_workers(known_host_ports)
    for hp in known_host_ports:
      self._cluster_spec["worker"].remove(hp)


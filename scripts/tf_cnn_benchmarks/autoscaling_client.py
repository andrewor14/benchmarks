#!/usr/bin/env python3

import copy
import json
import xmlrpc.client
import sys


# Offset between autoscaling RPC port and gRPC port
RPC_PORT_OFFSET = 7000

def connect(host_port, convert_port=False):
  '''
  Connect to the given host port and return the corresponding ServerProxy object.
  If `convert_port` is true, convert the gRPC port to an autoscaling RPC port.
  '''
  if convert_port:
    split = host_port.split(":")
    new_port = int(split[1]) + RPC_PORT_OFFSET
    host_port = "%s:%s" % (split[0], new_port)
  if not host_port.startswith("http://"):
    host_port = "http://%s" % host_port
  return xmlrpc.client.ServerProxy(host_port)

class AutoscalingClient:

  def __init__(self, starting_host_port):
    '''
    Open a connection to each server in the system, found by fetching
    the cluster spec from the given starting host port.
    '''
    print("Connecting to server at %s" % starting_host_port)
    starting_server = connect(starting_host_port)
    cluster_spec = starting_server.get_cluster_spec()
    cluster_spec = json.loads(cluster_spec)
    print("Fetched cluster spec: %s" % cluster_spec)
    ps_hosts = cluster_spec["ps"] if "ps" in cluster_spec else []
    worker_hosts = cluster_spec["worker"] if "worker" in cluster_spec else []
    host_ports = ps_hosts + worker_hosts
    print("Parsed the following host ports from cluster spec: %s" % host_ports)
    self._hosts = cluster_spec
    self._pending_hosts = copy.deepcopy(cluster_spec)
    self._servers = []

  @property
  def worker_hosts(self):
    return self._hosts["worker"]

  @property
  def ps_hosts(self):
    return self._hosts["ps"]

  @property
  def hosts(self):
    return self.worker_hosts + self.ps_hosts

  @property
  def servers(self):
    '''
    Return the ServerProxy objects associated with the hosts in the system.

    This accessor checks if there are hosts still pending, i.e. hosts we know about
    but haven't connected to yet. If so, try to connect and, if successful, mark
    them as no longer pending.

    All RPC calls should go through this accessor.
    '''
    for k, v in self._pending_hosts.items():
      failed_hosts = []
      for hp in v:
        try:
          self._servers.append(connect(hp, convert_port=True))
        except ConnectionRefusedError:
          failed_hosts.append(hp)
      self._pending_hosts[k] = failed_hosts
      if len(failed_hosts) > 0:
        raise Exception("Unable to connect to the following hosts. Try again later.\n%s" % failed_hosts)
    return self._servers

  def add_worker(self, host_port):
    '''
    Add a worker identified by the given host_port to the system.
    Note: this call assumes the given worker process has already started.
    '''
    self.add_workers([host_port])

  def add_workers(self, host_ports):
    '''
    Add workers identified by the given host_ports to the system.
    Note: this call assumes the given worker processes have already started.
    '''
    for server in self.servers:
      server.add_workers(host_ports)
    self._hosts["worker"].extend(host_ports)
    self._pending_hosts["worker"].extend(host_ports)


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
    self._cluster_spec = cluster_spec
    self._servers = {}

  @property
  def ps_hosts(self):
    return self._cluster_spec["ps"]

  @property
  def worker_hosts(self):
    return self._cluster_spec["worker"]

  @property
  def hosts(self):
    return self.ps_hosts + self.worker_hosts

  @property
  def servers(self):
    '''
    Return the ServerProxy objects associated with the hosts in the system.
    All RPC calls should go through this accessor.
    '''
    # If there are workers we know about but haven't connected to yet, connect to them
    if len(self.hosts) > len(self._servers):
      pending_hosts = list(set(self.hosts) - set(self._servers.keys()))
      failed_hosts = []
      for hp in pending_hosts:
        try:
          self._servers[hp] = connect(hp, convert_port=True)
        except ConnectionRefusedError:
          failed_hosts.append(hp)
      # Fail if there were any hosts we couldn't connect to
      if len(failed_hosts) > 0:
        raise Exception("Unable to connect to the following hosts. Try again later.\n%s" % failed_hosts)
    # Otherwise, if there are expired workers, remove them
    elif len(self.hosts) < len(self._servers):
      expired_hosts = list(set(self._servers.keys()) - set(self.hosts))
      for hp in expired_hosts:
        del self._servers[hp]
    # Make sure we are connected to all hosts we know about
    if len(self.hosts) != len(self._servers):
      raise ValueError("Number of hosts is different from number of server proxies!\n" +
        "Hosts: %s\nServer proxies: %s" % (self.hosts, self._servers.keys()))
    return self._servers.values()

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
      print("Warning: not adding the following workers because they already exist: %s" % known_host_ports)
    for server in self.servers:
      server.add_workers(new_host_ports)
    self._cluster_spec["worker"].extend(new_host_ports)

  def remove_workers(self, host_ports):
    '''
    Remove workers identified by the given host_ports from the system.
    '''
    known_host_ports = [hp for hp in host_ports if hp in self.worker_hosts]
    new_host_ports = [hp for hp in host_ports if hp not in self.worker_hosts]
    if len(new_host_ports) > 0:
      print("Warning: not removing the following workers because they are not known to us: %s" % new_host_ports)
    for server in self.servers:
      server.remove_workers(host_ports)
    for hp in known_host_ports:
      self._cluster_spec["worker"].remove(hp)


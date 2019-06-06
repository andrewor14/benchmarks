#!/usr/bin/env python3

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
    print("Fetched cluster spec: %s" % cluster_spec)
    self.ps_hosts = cluster_spec["ps"] if "ps" in cluster_spec else []
    self.worker_hosts = cluster_spec["worker"] if "worker" in cluster_spec else []
    host_ports = self.ps_hosts + self.worker_hosts
    print("Parsed the following host ports from cluster spec: %s" % host_ports)
    self.servers = [connect(hp, convert_port=True) for hp in host_ports]

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
    self.worker_hosts.extend(host_ports)
    for server in self.servers:
      server.add_workers(host_ports)
    # TODO: connect to the new servers after they're up
    #self.servers.extend([connect(hp, convert_port=True) for hp in host_ports])


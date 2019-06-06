#!/usr/bin/env python3

import json
from cnn_util import log_fn, make_cluster_spec


class AutoscalingService:
  '''
  A service for handling autoscaling requests.
  '''
  def __init__(self, benchmark_cnn):
    self.benchmark_cnn = benchmark_cnn

  def greet(self, name):
    return "Hello %s!" % name

  def get_cluster_spec(self):
    return self.benchmark_cnn.params.cluster_spec

  def add_workers(self, host_ports):
    log_fn("AUTOSCALING(add_workers): adding these workers %s" % host_ports)
    cluster_spec = make_cluster_spec(self.benchmark_cnn.params)
    cluster_spec["worker"].extend(host_ports)
    self._new_cluster_spec(cluster_spec)

  def remove_workers(self, host_ports):
    log_fn("AUTOSCALING(remove_workers): removing these workers %s" % host_ports)
    cluster_spec = make_cluster_spec(self.benchmark_cnn.params)
    for hp in host_ports:
      cluster_spec["worker"].remove(hp)
      if hp == self.benchmark_cnn.params.host_port:
        self.benchmark_cnn.should_terminate = True
    self._new_cluster_spec(cluster_spec)

  def _new_cluster_spec(self, cluster_spec):
    '''
    Update `benchmark_cnn` parameters to reflect the change in cluster membership,
    then signal that a server restart is required.
    '''
    self.benchmark_cnn.params = self.benchmark_cnn.params._replace(
      cluster_spec=json.dumps(cluster_spec),
      worker_hosts=",".join(cluster_spec["worker"]))
    log_fn("AUTOSCALING(_new_cluster_spec): new worker_hosts = %s" % self.benchmark_cnn.params.worker_hosts)
    log_fn("AUTOSCALING(_new_cluster_spec): new cluster_spec = %s" % self.benchmark_cnn.params.cluster_spec)
    # TODO: calculate new local batch size here
    self.benchmark_cnn.should_restart = True


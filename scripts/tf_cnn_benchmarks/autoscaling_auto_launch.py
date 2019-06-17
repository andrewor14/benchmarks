#!/usr/bin/env python3

import os
import sys
import time

from autoscaling_client import AutoscalingClient
from autoscaling_params import *
from cnn_util import log_fn


# Helper script to launch a process every N seconds

def launch_worker_every_n_seconds(client):
  '''
  Launch a worker process every N seconds up to a maximum.
  '''
  max_workers = os.getenv(AUTOSCALING_MAX_WORKERS) or -1
  max_workers = int(max_workers)
  every_n_seconds = os.getenv(AUTOSCALING_LAUNCH_WORKER_EVERY_N_SECONDS) or -1
  every_n_seconds = int(every_n_seconds)
  if every_n_seconds > 0:
    log_fn("[Autoscaling] Launching a worker every %s seconds" % every_n_seconds)
    num_workers = len(client.master_server.get_cluster_spec()["worker"])
    while max_workers > 0 and num_workers < max_workers:
      log_fn("[Autoscaling] Waiting until the master worker starts RUNNING...")
      # Start the timer every time the master worker starts running
      previous_status = None
      new_status = None
      while True:
        previous_status = new_status
        new_status = AutoscalingStatus(client.master_server.get_status())
        if previous_status == AutoscalingStatus.SETTING_UP and new_status == AutoscalingStatus.RUNNING:
          break
        time.sleep(AUTOSCALING_RETRY_INTERVAL_SECONDS)
      log_fn("[Autoscaling] Master worker is now RUNNING, starting timer to launch new worker")
      time.sleep(every_n_seconds)
      log_fn("[Autoscaling] There are now %s worker(s). Launching one more..." % num_workers)
      client.launch_worker()
      num_workers = len(client.master_server.get_cluster_spec()["worker"])
    return True
  return False

def main():
  master_host_port = os.getenv(AUTOSCALING_MASTER_HOST_PORT)
  launch_worker_script = os.getenv(AUTOSCALING_LAUNCH_WORKER_SCRIPT)
  if master_host_port is None or launch_worker_script is None:
    print("ERROR: must set %s and %s" %\
      (AUTOSCALING_MASTER_HOST_PORT, AUTOSCALING_LAUNCH_WORKER_SCRIPT))
    sys.exit(1)
  client = AutoscalingClient(master_host_port)
  if not launch_worker_every_n_seconds(client):
    print("Did not launch any workers because %s is not set" %\
      AUTOSCALING_LAUNCH_WORKER_EVERY_N_SECONDS)

if __name__ == "__main__":
  main()


#!/usr/bin/env python3

from enum import Enum


# Statuses for syncing restart across replicas, state machine:
# State machine looks like the following:
#
#   READY_TO_SYNC --> SYNCING --> SYNCED --> RUNNING
#        ^                                      |
#        |                                      |
#        '--------------------------------------'
#
class AutoscalingStatus(Enum):
  READY_TO_SYNC = 1
  SYNCING = 2
  SYNCED = 3
  RUNNING = 4

# Client and server
AUTOSCALING_MASTER_HOST_PORT = "AUTOSCALING_MASTER_HOST_PORT"
AUTOSCALING_LAUNCH_WORKER_SCRIPT = "AUTOSCALING_LAUNCH_WORKER_SCRIPT"
AUTOSCALING_LAUNCH_WORKER_EVERY_N_SECONDS = "AUTOSCALING_LAUNCH_WORKER_EVERY_N_SECONDS"
AUTOSCALING_MIN_WORKERS = "AUTOSCALING_MIN_WORKERS"
AUTOSCALING_MAX_WORKERS = "AUTOSCALING_MAX_WORKERS"
AUTOSCALING_RETRY_INTERVAL_SECONDS = 1
AUTOSCALING_RPC_PORT_OFFSET = 7000

# Fake allreduce
AUTOSCALING_SAVE_LOCAL_GRADS = "AUTOSCALING_SAVE_LOCAL_GRADS"
AUTOSCALING_FAKE_ALLREDUCE_PATH = "AUTOSCALING_FAKE_ALLREDUCE_PATH"


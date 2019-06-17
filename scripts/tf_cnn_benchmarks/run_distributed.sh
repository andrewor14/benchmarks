#!/bin/bash

# ====================================================
#  Example script for running benchmark through slurm
# ====================================================

# Set common configs
source common_configs.sh

# If we're just trying to attach to an existing cluster,
# just launch 1 worker
if [[ -n "$AUTOSCALING_MASTER_HOST_PORT" ]]; then
  export NUM_WORKERS=1
  export NUM_PARAMETER_SERVERS=0
  export RUN_TAG="distributed-added"
else
  export NUM_WORKERS=1
  export NUM_PARAMETER_SERVERS=1
  export RUN_TAG="distributed"
fi

# Optional configs
export VARIABLE_UPDATE="parameter_server"
export DATASET="cifar10"
export MODEL="resnet56"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=8192
export SERVER_PROTOCOL="grpc"
export DISPLAY_EVERY="1"
export AUTOSCALING_DISABLE_CHECKPOINT_RESTORE="true"
export AUTOSCALING_LAUNCH_WORKER_SCRIPT="$(basename $0)"
export AUTOSCALING_LAUNCH_WORKER_EVERY_N_SECONDS=900
export AUTOSCALING_MAX_WORKERS=60

# Run it
./slurm_run_benchmark.sh


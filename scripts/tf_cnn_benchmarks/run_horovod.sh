#!/bin/bash

# ===========================
#  Run horovod through slurm
# ===========================

# Set common configs
source common_configs.sh

# If we're just trying to attach to an existing cluster,
# just launch 1 worker
if [[ -n "$AUTOSCALING_MASTER_HOST_PORT" ]]; then
  export NUM_WORKERS=1
  export RUN_TAG="horovod-added"
else
  export NUM_WORKERS=3
  export RUN_TAG="horovod"
fi

# Horovod
export NUM_PARAMETER_SERVERS="0"
export VARIABLE_UPDATE="horovod"
export SERVER_PROTOCOL="grpc+mpi"

# Other configs
export DATASET="cifar10"
export MODEL="resnet56"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=32
export DISPLAY_EVERY="1"
export AUTOSCALING_DISABLE_CHECKPOINT_RESTORE="true"

# Run it
./slurm_run_benchmark.sh


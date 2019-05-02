#!/bin/bash

# =========================================================================
#  Test cost of communication using horovod, varying the number of workers
# =========================================================================

# Set common configs
source common_configs.sh

# Do not touch these
export NUM_PARAMETER_SERVERS="0"
export VARIABLE_UPDATE="horovod"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export SERVER_PROTOCOL="grpc+mpi"

# Maybe modify these
export NUM_BATCHES="10"
export DATASET="cifar10"
export MODEL="tiny_trivial"
export DISPLAY_EVERY=1
export ENABLE_CHROME_TRACE="true"
export DISABLE_INPUT_PREPROCESSING="true"
export GLOBAL_BATCH_SIZE="8192"
export FORWARD_ONLY="true"
export AUTOSCALING_FAKE_ALLREDUCE_PATH="$BASE_TRAIN_DIR/fake-grads.npy"

# Run it
for num_workers in 2 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60; do
  export NUM_WORKERS="$num_workers"
  # If we are doing a fake allreduce, then limit the computation we do
  if [[ -n "$AUTOSCALING_FAKE_ALLREDUCE_PATH" ]]; then
    export BATCH_SIZE="16"
    export RUN_TAG="horovod_120MB_${num_workers}workers"
  else
    export BATCH_SIZE="$(($GLOBAL_BATCH_SIZE / $NUM_WORKERS))"
    export RUN_TAG="horovod_${GLOBAL_BATCH_SIZE}_${num_workers}workers"
  fi
  ./slurm_run_benchmark.sh
done


#!/bin/bash

# =========================================================================
#  Test cost of communication using horovod, varying the number of workers
# =========================================================================

# Set common configs
source common_configs.sh

# Required configs
export NUM_PARAMETER_SERVERS="0"

# Optional configs
export NUM_BATCHES="100"
export FATE_SHARING="true"

# Optional configs
export VARIABLE_UPDATE="horovod"
export DATASET="synthetic"
export MODEL="andrew_trivial"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=64
export SERVER_PROTOCOL="grpc+mpi"
export DISPLAY_EVERY=1

# Run it
for num_workers in 2 4 8 16 32 48 60; do
  export NUM_WORKERS="$num_workers"
  export RUN_TAG="horovod_${num_workers}workers"
  ./slurm_run_benchmark.sh
done


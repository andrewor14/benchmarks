#!/bin/bash

# ====================================================
#  Example script for running benchmark through slurm
# ====================================================

# Set common configs
source common_configs.sh

# Required configs
export NUM_WORKERS="4"
export NUM_PARAMETER_SERVERS="1"
export SUBMIT_TIMESTAMP="$(get_submit_timestamp)"

# Optional configs
export VARIABLE_UPDATE="horovod"
export DATASET="cifar10"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=64
export SERVER_PROTOCOL="grpc+mpi"

# Run it
./slurm_run_benchmark.sh


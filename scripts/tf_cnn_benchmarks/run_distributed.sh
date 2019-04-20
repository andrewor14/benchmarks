#!/bin/bash

# ====================================================
#  Example script for running benchmark through slurm
# ====================================================

# Set common configs
source common_configs.sh

# Required configs
export NUM_WORKERS="7"
export NUM_PARAMETER_SERVERS="1"
export SUBMIT_TIMESTAMP="$(get_submit_timestamp)"

# Optional configs
export VARIABLE_UPDATE="parameter_server"
export DATASET="cifar10"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=64
export SERVER_PROTOCOL="grpc"

# Run it
./slurm_run_benchmark.sh


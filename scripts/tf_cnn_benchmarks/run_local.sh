#!/bin/bash

# ==============================================
#  Example script for running benchmark locally
# ==============================================

# Required configs
export NUM_WORKERS="3"
export NUM_PARAMETER_SERVERS="1"
export SUBMIT_TIMESTAMP=`date +%s`

# Optional configs
export DATASET="cifar10"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=64

./run_with_env.sh run_benchmark_multiplex.sh


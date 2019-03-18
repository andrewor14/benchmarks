#!/bin/bash

# ==============================================
#  Example script for running benchmark locally
# ==============================================

# Required configs
export NUM_WORKERS="2"
export NUM_PARAMETER_SERVERS="1"
export SUBMIT_TIMESTAMP=`date +%s`

# Optional configs
export NUM_GPUS_PER_WORKER="1"
export DATASET="cifar10"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=64

./run_with_env.sh run_benchmark_multiplex.sh


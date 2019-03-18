#!/bin/bash

# ==============================================
#  Example script for running benchmark locally
# ==============================================

# Set common configs
source common_configs.sh

# Required configs
export NUM_WORKERS="2"
export NUM_PARAMETER_SERVERS="1"
export SUBMIT_TIMESTAMP="$(get_submit_timestamp)"

# Optional configs
export NUM_GPUS_PER_WORKER="1"
export DATASET="synthetic"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=64

# Run it
LOG_FILE="$LOG_DIR/benchmark-$SUBMIT_TIMESTAMP.out"
./run_with_env.sh run_benchmark_multiplex.sh 2>&1 | tee "$LOG_FILE"


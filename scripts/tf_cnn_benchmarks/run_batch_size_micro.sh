#!/bin/bash

# ========================================================
#  Test run time of each batch with increasing batch size
# ========================================================

# Set common configs
source common_configs.sh

# Required configs
export NUM_WORKERS="2"
export NUM_PARAMETER_SERVERS="1"
export SUBMIT_TIMESTAMP="$(get_submit_timestamp)"

# Optional configs
export NUM_GPUS_PER_WORKER="1"
export DATASET="synthetic"
export MODEL="resnet50_v1.5"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export NUM_BATCHES="100"

# Run it
for b in 1 2 4 8 16 32 64 128 256 512 1024; do
  export BATCH_SIZE="$b"
  export RUN_TAG="batch_size_micro_$b"
  LOG_FILE="$LOG_DIR/$RUN_TAG-$SUBMIT_TIMESTAMP.out"
  echo "Running batch size $b, logging to $LOG_FILE"
  ./run_with_env.sh run_benchmark_multiplex.sh > "$LOG_FILE" 2>&1
done


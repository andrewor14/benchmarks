#!/bin/bash

# ========================================================
#  Test run time of each batch with increasing batch size
# ========================================================

# Set common configs
source common_configs.sh

# Required configs
export NUM_WORKERS="2"
export NUM_PARAMETER_SERVERS="1"

# Optional configs
export NUM_GPUS_PER_WORKER="1"
#export DATASET="synthetic"
#export MODEL="resnet50_v1.5"
export DATASET="cifar10"
export MODEL="trivial"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export NUM_BATCHES="100"
export FATE_SHARING="true"

# Run it
for b in 1 2 4 8 16 32 64 128 256 512 1024; do
  export BATCH_SIZE="$b"
  RUN_TAG="batch_size_micro_$b"
  SUBMIT_TIMESTAMP="$(get_submit_timestamp)"
  export JOB_NAME="${RUN_TAG}-${SUBMIT_TIMESTAMP}"
  LOG_FILE="$LOG_DIR/$JOB_NAME.out"
  echo "Running batch size $b, logging to $LOG_FILE"
  ./run_with_env.sh run_benchmark_multiplex.sh > "$LOG_FILE" 2>&1
done


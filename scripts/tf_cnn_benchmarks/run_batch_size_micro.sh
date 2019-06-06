#!/bin/bash

# ========================================================
#  Test run time of each batch with increasing batch size
# ========================================================

# Set common configs
source common_configs.sh

# Required configs
export NUM_WORKERS="${NUM_WORKERS:=1}"
export NUM_PARAMETER_SERVERS="1"

# Optional configs
export DATASET="cifar10"
export MODEL="resnet56"
export NUM_GPUS_PER_WORKER="0"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export NUM_BATCHES="1000000"
export DISPLAY_EVERY="1"
export AUTOSCALING_DISABLE_CHECKPOINT_RESTORE="true"

# Run it
#for b in 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192; do
for b in 32; do
  export BATCH_SIZE="$b"
  RUN_TAG="batch_size_micro_$b"
  SUBMIT_TIMESTAMP="$(get_submit_timestamp)"
  export JOB_NAME="${RUN_TAG}-${SUBMIT_TIMESTAMP}"
  LOG_FILE="$LOG_DIR/$JOB_NAME.out"
  echo "Running batch size $b, logging to $LOG_FILE"
  ./run_with_env.sh run_benchmark_multiplex.sh > "$LOG_FILE" 2>&1
done


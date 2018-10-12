#!/bin/bash

SLURM_LOG_DIR="/home/andrewor/logs"
TIMESTAMP="$1"
MY_CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES"

# Note: This script currently only handles 1 ps + 1 worker on the same machine
# If you want to change any of these settings you MUST change how CUDA_VISIBLE_DEVICES
# is being set below.
export SLURM_JOB_NUM_PROCS_PER_NODE=2
export NUM_WORKERS=1
export NUM_GPUS=4

# For running REAL local mode (not through slurm)
if [[ -z "$SLURMD_NODENAME" ]]; then
  echo "SLURM mode not detected: Running real local mode!"
  export MODEL="trivial"
  export SLURM_JOB_NODELIST="localhost"
  export SLURM_JOB_NODENAME="localhost"
  export SLURM_JOB_NUM_NODES=1
  export SLURMD_NODENAME="localhost"
  export SLURM_JOB_ID="local"
  export KSYNC_MODE="sync"
  export DEVICE="cpu"
  export DATA_FORMAT="NHWC"
fi

function start_it() {
  export SLURMD_PROC_INDEX="$1"
  # Don't give the parameter server GPUs
  if [[ "$SLURMD_PROC_INDEX" == 0 ]]; then
    export CUDA_VISIBLE_DEVICES=""
  else
    export CUDA_VISIBLE_DEVICES="$MY_CUDA_VISIBLE_DEVICES"
  fi
  LOG_FILE="$SLURM_LOG_DIR/slurm-benchmark-$SLURM_JOB_ID-$SLURMD_PROC_INDEX-$TIMESTAMP.out"
  echo "Starting tensorflow process on $SLURMD_NODENAME ($SLURMD_PROC_INDEX), writing to $LOG_FILE"
  ./run_benchmark.sh "$TIMESTAMP" > "$LOG_FILE" 2>&1 &
}

# Actually start everything
for i in `seq 0 $(($SLURM_JOB_NUM_PROCS_PER_NODE - 1))`; do
  start_it $i
done

wait


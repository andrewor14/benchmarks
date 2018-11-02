#!/bin/bash

SLURM_LOG_DIR="/home/andrewor/logs"
TIMESTAMP="$1"
MY_CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES"

# Note: This script currently only handles 1 worker per node.
# If you want to run with multiple workers per node, you MUST
# change how CUDA_VISIBLE_DEVICES is being set below.
export NUM_WORKERS="$SLURM_JOB_NUM_NODES"
export NUM_PARAMETER_SERVERS=1
export NUM_GPUS=4
export SLURM_JOB_NUM_WORKERS_PER_NODE=1

# Check whether we should launch a parameter server on this node
SHOULD_LAUNCH_PARAMETER_SERVER="false"
EXPANDED_NODE_LIST="$(scontrol show hostname $SLURM_JOB_NODELIST)"
PARAMETER_SERVERS="$(echo "$EXPANDED_NODE_LIST" | head -n "$NUM_PARAMETER_SERVERS")"
for ps in $PARAMETER_SERVERS; do
  if [[ "$ps" == "$SLURMD_NODENAME" ]]; then
    SHOULD_LAUNCH_PARAMETER_SERVER="true"
  fi
done

function start_it() {
  export SLURMD_PROC_INDEX="$1"
  # Here we assume the worker will always be process 0
  # Don't give the parameter server any GPUs
  if [[ "$SLURMD_PROC_INDEX" == 0 ]]; then
    export CUDA_VISIBLE_DEVICES="$MY_CUDA_VISIBLE_DEVICES"
  else
    export CUDA_VISIBLE_DEVICES=""
  fi
  LOG_FILE="$SLURM_LOG_DIR/slurm-benchmark-$SLURM_JOB_ID-$SLURMD_NODENAME-$SLURMD_PROC_INDEX-$TIMESTAMP.out"
  echo "Starting tensorflow process on $SLURMD_NODENAME ($SLURMD_PROC_INDEX), writing to $LOG_FILE"
  ./run_benchmark.sh "$TIMESTAMP" > "$LOG_FILE" 2>&1 &
}

# Launch workers and/or parameter servers
start_it 0
if [[ "$SHOULD_LAUNCH_PARAMETER_SERVER" == "true" ]]; then
  start_it 1
fi

wait


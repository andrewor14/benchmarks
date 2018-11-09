#!/bin/bash

SLURM_LOG_DIR="/home/andrewor/logs"
TIMESTAMP="$1"
MY_CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES"

# Start multiple processes on a single node
export NUM_WORKERS=1
export NUM_GPUS=4
export SLURM_JOB_NUM_PROCS_PER_NODE=2

# This script is incompatible with single process local mode
if [[ "$LOCAL_MODE" == "true" ]]; then
  echo "Multiplex mode is not compatible with single process local mode"
  exit 1
fi

# Note: The MPI integration in tensorflow assumes exactly one
# process per machine, so here we fail fast if we detect MPI
if [[ "$SERVER_PROTOCOL" == *"mpi"* ]]; then
  echo "Multiplex mode is not compatible with server protocol '$SERVER_PROTOCOL'"
  exit 1
fi

# For running NOT through slurm
if [[ -z "$SLURMD_NODENAME" ]]; then
  echo "SLURM mode not detected: Running locally!"
  export SLURM_JOB_NODELIST="localhost"
  export SLURM_JOB_NODENAME="localhost"
  export SLURM_JOB_NUM_NODES=1
  export SLURMD_NODENAME="localhost"
  export SLURM_JOB_ID="${RUN_TAG:=local}"
  export DEVICE="cpu"
  export LOCAL_PARAMETER_DEVICE="cpu"
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


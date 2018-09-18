#!/bin/bash

SLURM_LOG_DIR="/home/andrewor/logs"
TIMESTAMP=`date +%s`

export SLURM_JOB_NUM_PROCS_PER_NODE=4
export NUM_GPUS=1

# For running REAL local mode (not through slurm)
if [[ -z "$SLURM_JOB_NODENAME" ]]; then
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
  export CUDA_VISIBLE_DEVICES="$1"
  LOG_FILE="$SLURM_LOG_DIR/slurm-benchmark-$SLURM_JOB_ID-$SLURMD_PROC_INDEX-$TIMESTAMP.out"
  echo "Starting tensorflow process on $SLURMD_NODENAME ($SLURMD_PROC_INDEX), writing to $LOG_FILE"
  ./run_benchmark.sh "$TIMESTAMP" > "$LOG_FILE" 2>&1 &
}

# Actually start everything
for i in `seq 0 $(($SLURM_JOB_NUM_PROCS_PER_NODE - 1))`; do
  start_it $i
done

wait


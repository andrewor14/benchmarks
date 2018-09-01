#!/bin/bash

SLURM_LOG_DIR="/home/andrewor/logs"
TIMESTAMP=`date +%s`

# Start 4 processes on each node we get from slurm
# Since we assume the nodes have 4 GPUs each, the number of GPUs per node is 1
export SLURM_JOB_NUM_PROCS_PER_NODE=4
export NUM_GPUS=1

function start_it() {
  export SLURMD_PROC_INDEX="$1"
  LOG_FILE="$SLURM_LOG_DIR/slurm-benchmark-local-$SLURMD_PROC_INDEX-$TIMESTAMP.out"
  echo "Starting tensorflow process on $SLURMD_NODENAME ($SLURMD_PROC_INDEX), writing to $LOG_FILE"
  ./run_benchmark.sh "$TIMESTAMP" > "$LOG_FILE" 2>&1 &
}

# Actually start everything
for i in `seq 0 $(($SLURM_JOB_NUM_PROCS_PER_NODE - 1))`; do
  start_it $i
done

wait


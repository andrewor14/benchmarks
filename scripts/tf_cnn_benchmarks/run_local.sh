#!/bin/bash

RUN_TAG="benchmark"
if [[ -n "$1" ]]; then
  RUN_TAG="$RUN_TAG-$1"
fi
export RUN_TAG
export BYPASS_GPU_TEST="true"
export TIMESTAMP=`date +%s`

export DATASET="imagenet"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=64
export ENABLE_CHROME_TRACE="true"
export NUM_WORKERS="3"
export SLURM_JOB_NUM_PROCS_PER_NODE="4"

./run_with_env.sh run_benchmark_multiplex.sh "$TIMESTAMP"


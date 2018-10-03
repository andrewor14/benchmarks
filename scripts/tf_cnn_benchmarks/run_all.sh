#!/bin/bash

RUN_TAG="benchmark"
if [[ -n "$1" ]]; then
  RUN_TAG="$RUN_TAG-$1"
fi
export RUN_TAG

OPTIMIZER="momentum" CROSS_REPLICA_SYNC="false" sbatch slurm_run_benchmark.sh
OPTIMIZER="momentum" CROSS_REPLICA_SYNC="true" sbatch slurm_run_benchmark.sh
KSYNC_MODE="sync" sbatch slurm_run_benchmark.sh
#KSYNC_MODE="async" sbatch slurm_run_benchmark.sh
#KSYNC_MODE="ksync" sbatch slurm_run_benchmark.sh


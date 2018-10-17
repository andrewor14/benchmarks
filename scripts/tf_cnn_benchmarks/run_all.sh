#!/bin/bash

RUN_TAG="benchmark"
if [[ -n "$1" ]]; then
  RUN_TAG="$RUN_TAG-$1"
fi
export RUN_TAG

#OPTIMIZER="momentum" CROSS_REPLICA_SYNC="false" sbatch slurm_run_benchmark.sh
#OPTIMIZER="momentum" CROSS_REPLICA_SYNC="true" sbatch slurm_run_benchmark.sh
#KSYNC_MODE="sync" sbatch slurm_run_benchmark.sh
#KSYNC_MODE="async" sbatch slurm_run_benchmark.sh
#KSYNC_MODE="ksync" sbatch slurm_run_benchmark.sh

export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"

#VARIABLE_UPDATE="parameter_server" GPU_THREAD_MODE="gpu_shared" USE_FP16=false sbatch slurm_run_benchmark.sh
#VARIABLE_UPDATE="parameter_server" GPU_THREAD_MODE="gpu_private" USE_FP16=false sbatch slurm_run_benchmark.sh
#VARIABLE_UPDATE="parameter_server" GPU_THREAD_MODE="gpu_shared" USE_FP16=true sbatch slurm_run_benchmark.sh
#VARIABLE_UPDATE="parameter_server" GPU_THREAD_MODE="gpu_private" USE_FP16=true sbatch slurm_run_benchmark.sh

#VARIABLE_UPDATE="distributed_replicated" GPU_THREAD_MODE="gpu_shared" USE_FP16=false sbatch slurm_run_benchmark.sh
#VARIABLE_UPDATE="distributed_replicated" GPU_THREAD_MODE="gpu_private" USE_FP16=false sbatch slurm_run_benchmark.sh
#VARIABLE_UPDATE="distributed_replicated" GPU_THREAD_MODE="gpu_shared" USE_FP16=true sbatch slurm_run_benchmark.sh
VARIABLE_UPDATE="distributed_replicated" GPU_THREAD_MODE="gpu_private" USE_FP16=true sbatch slurm_run_benchmark.sh


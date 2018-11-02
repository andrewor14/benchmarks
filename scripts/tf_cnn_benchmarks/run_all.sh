#!/bin/bash

RUN_TAG="benchmark"
if [[ -n "$1" ]]; then
  RUN_TAG="$RUN_TAG-$1"
fi
export RUN_TAG
export SLURM_RUN_SCRIPT="slurm_run_benchmark.sh"
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=256
export ENABLE_CHROME_TRACE="false"
export SERVER_PROTOCOL="grpc+mpi"
#export USE_FACEBOOK_BASE_LEARNING_RATE="true"
#export RESNET_BASE_LEARNING_RATE="0.8"

#VARIABLE_UPDATE="parameter_server" GPU_THREAD_MODE="gpu_shared" USE_FP16=false sbatch "$SLURM_RUN_SCRIPT"
#VARIABLE_UPDATE="parameter_server" GPU_THREAD_MODE="gpu_private" USE_FP16=false sbatch "$SLURM_RUN_SCRIPT"
#VARIABLE_UPDATE="parameter_server" GPU_THREAD_MODE="gpu_shared" USE_FP16=true sbatch "$SLURM_RUN_SCRIPT"
#VARIABLE_UPDATE="parameter_server" GPU_THREAD_MODE="gpu_private" USE_FP16=true sbatch "$SLURM_RUN_SCRIPT"

#VARIABLE_UPDATE="distributed_replicated" GPU_THREAD_MODE="gpu_shared" USE_FP16=false sbatch "$SLURM_RUN_SCRIPT"
#VARIABLE_UPDATE="distributed_replicated" GPU_THREAD_MODE="gpu_private" USE_FP16=false sbatch "$SLURM_RUN_SCRIPT"
#VARIABLE_UPDATE="distributed_replicated" GPU_THREAD_MODE="gpu_shared" USE_FP16=true sbatch "$SLURM_RUN_SCRIPT"
VARIABLE_UPDATE="distributed_replicated" GPU_THREAD_MODE="gpu_private" USE_FP16=true sbatch "$SLURM_RUN_SCRIPT"

# Old stuff

#OPTIMIZER="momentum" CROSS_REPLICA_SYNC="false" sbatch "$SLURM_RUN_SCRIPT"
#OPTIMIZER="momentum" CROSS_REPLICA_SYNC="true" sbatch "$SLURM_RUN_SCRIPT"
#KSYNC_MODE="sync" sbatch "$SLURM_RUN_SCRIPT"
#KSYNC_MODE="async" sbatch "$SLURM_RUN_SCRIPT"
#KSYNC_MODE="ksync" sbatch "$SLURM_RUN_SCRIPT"


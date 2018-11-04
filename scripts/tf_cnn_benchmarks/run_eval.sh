#!/bin/bash

# Modify this before running this script
TRAIN_EXPERIMENT="resnet50_imagenet_1541273929"

# Do not touch these
RUN_TAG="eval-$TRAIN_EXPERIMENT"
if [[ -n "$1" ]]; then
  RUN_TAG="$RUN_TAG-$1"
fi
export RUN_TAG
export EVAL="true"
export SLURM_RUN_SCRIPT="slurm_run_eval.sh"
export TRAIN_DIR="/tigress/andrewor/saved_logs/$TRAIN_EXPERIMENT"

# Other configs
export OPTIMIZER="momentum"
export CROSS_REPLICA_SYNC="true"
export BATCH_SIZE=256
export ENABLE_CHROME_TRACE="false"
export SERVER_PROTOCOL="grpc+mpi"
export VARIABLE_UPDATE="parameter_server"
export GPU_THREAD_MODE="gpu_private"
export USE_FP16=true

sbatch "$SLURM_RUN_SCRIPT"


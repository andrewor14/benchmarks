#!/bin/bash

# Modify this before running this script
#TRAIN_EXPERIMENT="resnet50_imagenet_1541403236"
TRAIN_EXPERIMENT="resnet50_imagenet_1541584401"

# Do not touch these
RUN_TAG="eval-$TRAIN_EXPERIMENT"
if [[ -n "$1" ]]; then
  RUN_TAG="$RUN_TAG-$1"
fi
export RUN_TAG
export EVAL="true"
export SLURM_RUN_SCRIPT="slurm_run_benchmark_local.sh"
export TRAIN_DIR="/tigress/andrewor/saved_logs/$TRAIN_EXPERIMENT"

# Other configs
# Note: variable update must be parameter_server since the original run
# also used parameter_server, otherwise the variable names will not match
export VARIABLE_UPDATE="parameter_server"
export BATCH_SIZE=256
export GPU_THREAD_MODE="gpu_private"
export USE_FP16=true

# TODO: make distinction between single process mode and local mode
if [[ "$LOCAL_EVAL" == "true" ]]; then
  TIMESTAMP=`date +%s`
  export BYPASS_GPU_TEST="true"
  # Note: single process local mode actually fails due to some assertion error
  # caused by how GRPC channels are initialized in tensorflow. Here we bypass
  # that error by running in multiplex mode instead.
  ./run_with_env.sh run_benchmark_multiplex.sh "$TIMESTAMP"
else
  sbatch "$SLURM_RUN_SCRIPT"
fi


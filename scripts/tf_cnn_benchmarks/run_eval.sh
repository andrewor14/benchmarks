#!/bin/bash

# =====================================================================
#  Example script for running evaluation on a previously trained model
# =====================================================================

# Modify this before running this script
TRAIN_EXPERIMENT="resnet50_imagenet_1541584401"

# Do not touch these
export EVAL="true"
export RUN_TAG="eval-$TRAIN_EXPERIMENT"
export TRAIN_DIR="$BASE_TRAIN_DIR/$TRAIN_EXPERIMENT"

# Other configs
# Note: variable update must be parameter_server since the original run
# also used parameter_server, otherwise the variable names will not match
export VARIABLE_UPDATE="parameter_server"
export BATCH_SIZE=256
export GPU_THREAD_MODE="gpu_private"
export USE_FP16=true

if [[ "$LOCAL_EVAL" == "true" ]]; then
  # Note: single process local mode actually fails due to some assertion error
  # caused by how GRPC channels are initialized in tensorflow. Here we bypass
  # that error by running in multiplex mode instead.
  export SUBMIT_TIMESTAMP=`date +%s`
  export NUM_WORKERS="1"
  export NUM_PARAMETER_SERVERS="1"
  ./run_with_env.sh run_benchmark_multiplex.sh
else
  sbatch "slurm_run_benchmark.sh"
fi


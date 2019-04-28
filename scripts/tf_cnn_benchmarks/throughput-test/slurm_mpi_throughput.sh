#!/bin/bash

# Set common configs
source ../common_configs.sh

export RUN_TAG="throughput-test"
export SUBMIT_TIMESTAMP="$(get_submit_timestamp)"
export JOB_NAME="${RUN_TAG}-${SUBMIT_TIMESTAMP}"
export NUM_NODES="2"
export RUN_COMMAND="mpirun --output-filename $LOG_DIR/mpi-$JOB_NAME a.out"

./slurm_test.sh


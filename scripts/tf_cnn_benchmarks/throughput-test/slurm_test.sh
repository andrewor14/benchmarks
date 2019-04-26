#!/bin/bash

# Set common configs
source ../common_configs.sh

# Run configs
RUN_TAG="${RUN_TAG:=test}"
SUBMIT_TIMESTAMP="$(get_submit_timestamp)"
NUM_NODES="${NUM_NODES:=4}"
NUM_TASKS_PER_NODE="1"
NUM_CPUS_PER_NODE="${NUM_CPUS_PER_NODE:=$DEFAULT_NUM_CPUS_PER_NODE}"
NUM_GPUS_PER_NODE="${NUM_GPUS_PER_NODE:=$DEFAULT_NUM_GPUS_PER_NODE}"
MEMORY_PER_NODE="${MEMORY_PER_NODE:=$DEFAULT_MEMORY_PER_NODE}"
RUN_COMMAND="srun --output=$LOG_DIR/slurm-%x-%j-%n.out test.sh"

sbatch\
  --nodes="$NUM_NODES"\
  --ntasks="$NUM_NODES"\
  --ntasks-per-node="$NUM_TASKS_PER_NODE"\
  --cpus-per-task="$NUM_CPUS_PER_NODE"\
  --mem="$MEMORY_PER_NODE"\
  --time="144:00:00"\
  --job-name="${RUN_TAG}-${SUBMIT_TIMESTAMP}"\
  --mail-type="begin"\
  --mail-type="end"\
  --mail-user="$EMAIL"\
  --wrap "$RUN_COMMAND"


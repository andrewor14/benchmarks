#!/bin/bash

# Set common configs
source common_configs.sh

if [[ "$#" != "2" ]]; then
  echo "Usage: run_benchmark_multiplex [num_processes] [submit_timestamp]"
  exit 1
fi

if [[ -n "$NUM_PROCESSES" ]]; then
  echo "ERROR: NUM_PROCESSES should not be set yet"
fi

if [[ -n "$NUM_WORKERS" ]]; then
  echo "ERROR: NUM_WORKERS should not be set yet"
fi

# Assume 1 parameter server for now
export NUM_PROCESSES="$1"
export NUM_PARAMETER_SERVERS="1"
export NUM_WORKERS="$((NUM_PROCESSES-NUM_PARAMETER_SERVERS))"
export NUM_GPUS="${NUM_GPUS:=$DEFAULT_NUM_GPUS}"

# Use the same timestamp across all nodes to identify experiment
SUBMIT_TIMESTAMP="$2"

# Decide which GPUs each worker gets, e.g. if CUDA_VISIBLE_DEVICES is "0,1,2,3"
# and NUM_GPUS is 2, then CUDA_VISIBLE_DEVICES_PER_WORKER will be ("0,1", "2,3").
# In this case, NUM_WORKERS must be 2 or the program will fail.
CUDA_VISIBLE_DEVICES_PER_WORKER=()
ORIGINAL_CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES"
if [[ -n "$CUDA_VISIBLE_DEVICES" ]]; then
  i=1
  current_device_string=""
  for device in $(echo "$CUDA_VISIBLE_DEVICES" | sed "s/,/ /g"); do
    # Add the current device to current_device_string
    if [[ -z "$current_device_string" ]]; then
      current_device_string="$device"
    else
      current_device_string="$current_device_string,$device"
    fi
    # Collect and reset current_device_string
    if [[ "$((i % $NUM_GPUS))" = "0" ]]; then
      CUDA_VISIBLE_DEVICES_PER_WORKER+=("$current_device_string")
      current_device_string=""
    fi
    i="$((i+1))"
  done
  # Make sure we have the right number of workers
  if [[ "${#CUDA_VISIBLE_DEVICES_PER_WORKER[*]}" != "$NUM_WORKERS" ]]; then
    echo "ERROR: GPUs do not split evenly among workers:"
    echo "  NUM_GPUS (per worker): $NUM_GPUS"
    echo "  NUM_WORKERS: $NUM_WORKERS"
    echo "  CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "  CUDA_VISIBLE_DEVICES_PER_WORKER: ${CUDA_VISIBLE_DEVICES_PER_WORKER[*]}"
    exit 1
  fi
fi

# This script is incompatible with single process mode
if [[ "$SINGLE_PROCESS_MODE" == "true" ]]; then
  echo "Multiplex mode is not compatible with single process mode"
  exit 1
fi

# Note: The MPI integration in tensorflow assumes exactly one
# process per machine, so here we fail fast if we detect MPI
if [[ "$SERVER_PROTOCOL" == *"mpi"* ]]; then
  echo "Multiplex mode is not compatible with server protocol '$SERVER_PROTOCOL'"
  exit 1
fi

# For running NOT through slurm
if [[ -z "$SLURMD_NODENAME" ]]; then
  echo "SLURM mode not detected: Running locally!"
  export SLURM_JOB_NODELIST="localhost"
  export SLURM_JOB_NODENAME="localhost"
  export SLURM_JOB_NUM_NODES=1
  export SLURMD_NODENAME="localhost"
  export SLURM_JOB_ID="${RUN_TAG:=local}"
  export JOB_NAME="benchmark-$SUBMIT_TIMESTAMP"
else
  export JOB_NAME="slurm-benchmark-${SLURM_JOB_ID}-${SUBMIT_TIMESTAMP}"
fi

function start_it() {
  index="$1"
  # Don't give the parameter server GPUs
  if [[ "$index" < "$NUM_PARAMETER_SERVERS" ]]; then
    export CUDA_VISIBLE_DEVICES=""
  else if [[ -n "$CUDA_VISIBLE_DEVICES_PER_WORKER" ]]; then
    # Export the right set of devices for this worker
    worker_index="$((index-NUM_PARAMETER_SERVERS))"
    export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES_PER_WORKER[$worker_index]}"
  fi
    # In the non-GPU case, just pass on the original CUDA_VISIBLE_DEVICES
    export CUDA_VISIBLE_DEVICES="$ORIGINAL_CUDA_VISIBLE_DEVICES"
  fi
  LOG_FILE="$LOG_DIR/${JOB_NAME}_${index}.out"
  # Start the process
  echo "Starting tensorflow process on $SLURMD_NODENAME ($index), writing to $LOG_FILE"
  export SLURMD_PROC_INDEX="$index"
  export SLURM_JOB_NUM_PROCS_PER_NODE="$NUM_PROCESSES"
  ./run_benchmark.sh "$SUBMIT_TIMESTAMP" > "$LOG_FILE" 2>&1 &
}

# Actually start everything
for i in `seq 0 $((NUM_PROCESSES - 1))`; do
  start_it $i
done

wait


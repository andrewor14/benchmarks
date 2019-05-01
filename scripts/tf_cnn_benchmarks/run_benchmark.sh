#!/bin/bash

# =============================================================
#  The main entry point to launching a tensorflow process
#
#  This expects the following environment variables to be set:
#  JOB_NAME and NUM_WORKERS
# =============================================================

# Set common configs
source common_configs.sh

if [[ -z "$JOB_NAME" ]]; then
  echo "ERROR: JOB_NAME must be set."
  exit 1
fi

if [[ -z "$NUM_WORKERS" ]]; then
  echo "ERROR: NUM_WORKERS must be set."
  exit 1
fi

if [[ -n "$NUM_GPUS" ]]; then
  echo "ERROR: Do not set NUM_GPUS. Set NUM_GPUS_PER_WORKER instead."
  exit 1
fi

# General configs
NUM_GPUS_PER_WORKER="${NUM_GPUS_PER_WORKER:=$DEFAULT_NUM_GPUS_PER_WORKER}"
DEVICE="${DEVICE:=gpu}"
DATA_FORMAT="${DATA_FORMAT:=NCHW}"
OPTIMIZER="${OPTIMIZER:=momentum}"
CROSS_REPLICA_SYNC="${CROSS_REPLICA_SYNC:=false}"
BATCH_SIZE="${BATCH_SIZE:=64}"
DATASET="${DATASET:=imagenet}"
GPU_THREAD_MODE="${GPU_THREAD_MODE:=gpu_shared}"
ALL_REDUCE_SPEC="${ALL_REDUCE_SPEC:=}"
GRADIENT_REPACKING="${GRADIENT_REPACKING:=0}"
VARIABLE_UPDATE="${VARIABLE_UPDATE:=parameter_server}"
LOCAL_PARAMETER_DEVICE="${LOCAL_PARAMETER_DEVICE:=gpu}"
SERVER_PROTOCOL="${SERVER_PROTOCOL:=grpc}"
ENABLE_CHROME_TRACE="${ENABLE_CHROME_TRACE:=false}"
DISPLAY_EVERY="${DISPLAY_EVERY:=10}"
XLA="${XLA:=false}"
XLA_COMPILE="${XLA_COMPILE:=false}"

# Note: the tensorflow benchmark code assumes --num_gpus to always be at least 1
if [[ "$NUM_GPUS_PER_WORKER" == "0" ]]; then
  NUM_GPUS_PER_WORKER="1"
fi

# Stop condition configs
if [[ -z "$NUM_BATCHES" ]]; then
  NUM_EPOCHS="${NUM_EPOCHS:=100}"
  NUM_BATCHES="0"
elif [[ -z "$NUM_EPOCHS" ]]; then
  NUM_EPOCHS="0"
else
  echo "ERROR: NUM_BATCHES ($NUM_BATCHES) and NUM_EPOCHS ($NUM_EPOCHS) cannot both be set!"
  exit 1
fi

# Checkpoint/eval configs
SAVE_MODEL_SECS="${SAVE_MODEL_SECS:=600}"
EVAL_INTERVAL_SECS="${EVAL_INTERVAL_SECS:=$SAVE_MODEL_SECS}"
EVAL_DURING_TRAINING_EVERY_N_EPOCHS="${EVAL_DURING_TRAINING_EVERY_N_EPOCHS:=0}"
EVAL="${EVAL:=false}"

# Dataset-specific configs
if [[ "$DATASET" = "synthetic" ]]; then
  DATA_DIR=""
  MODEL="${MODEL:=resnet50_v1.5}"
  USE_FP16="${USE_FP16:=false}"
elif [[ "$DATASET" = "cifar10" ]]; then
  DATA_DIR="$CIFAR10_DATA_DIR"
  MODEL="${MODEL:=resnet56}"
  USE_FP16="${USE_FP16:=false}"
elif [[ "$DATASET" = "imagenet" ]]; then
  DATA_DIR="$IMAGENET_DATA_DIR"
  MODEL="${MODEL:=resnet50_v1.5}"
  USE_FP16="${USE_FP16:=true}"
  # Optionally set base learning rate according to Facebook paper:
  # Accurate, Large Minibatch SGD: Training ImageNet in 1 Hour
  if [[ "$USE_FACEBOOK_BASE_LEARNING_RATE" == "true" ]]; then
    if [[ -n "$RESNET_BASE_LEARNING_RATE" ]]; then
      echo "ERROR: USE_FACEBOOK_BASE_LEARNING_RATE is not compatible with RESNET_BASE_LEARNING_RATE"
      exit 1
    fi
    RESNET_BASE_LEARNING_RATE="$(($BATCH_SIZE * $NUM_WORKERS * $NUM_GPUS_PER_WORKER / 256))"
    export RESNET_BASE_LEARNING_RATE="0.$RESNET_BASE_LEARNING_RATE" # divide by 10
  fi
  if [[ -n "$RESNET_BASE_LEARNING_RATE" ]]; then
    echo "Resnet base learning rate = $RESNET_BASE_LEARNING_RATE"
  fi
fi

# Set up working directories
TRAIN_DIR="${TRAIN_DIR:=$BASE_TRAIN_DIR/$JOB_NAME}"
EVAL_DIR="${EVAL_DIR:=$BASE_EVAL_DIR/$JOB_NAME}"
mkdir -p "$TRAIN_DIR"
mkdir -p "$EVAL_DIR"

# Optionally enable chrome trace
if [[ "$ENABLE_CHROME_TRACE" == "true" ]]; then
  TRACE_FILE="$TRAIN_DIR/chrome.trace"
fi

# Optionally enable network trace
if [[ "$ENABLE_NETWORK_TRACE" == "true" ]]; then
  ./collect_network_trace.sh &
fi

# Enable horovod trace by default
if [[ "$VARIABLE_UPDATE" == "horovod" ]]; then
  export HOROVOD_TIMELINE="$TRAIN_DIR/horovod_timeline.json"
fi

echo "Running this commit: $(git log --oneline | head -n 1)"

DIFF="$(git diff)"
if [[ -n "$DIFF" ]]; then
  echo -e "\n=========================================================================="
  echo -e "git diff"
  echo -e "--------------------------------------------------------------------------"
  echo -e "$DIFF"
  echo -e "==========================================================================\n"
fi

echo -e "\n=========================================================================="
echo -e "My environment variables:"
echo -e "--------------------------------------------------------------------------"
printenv
echo -e "==========================================================================\n"

"$PYTHON_COMMAND" tf_cnn_benchmarks.py\
  --num_gpus="$NUM_GPUS_PER_WORKER"\
  --device="$DEVICE"\
  --local_parameter_device="$DEVICE"\
  --data_format="$DATA_FORMAT"\
  --batch_size="$BATCH_SIZE"\
  --model="$MODEL"\
  --print_training_accuracy=true\
  --display_every="$DISPLAY_EVERY"\
  --num_epochs="$NUM_EPOCHS"\
  --num_batches="$NUM_BATCHES"\
  --data_dir="$DATA_DIR"\
  --train_dir="$TRAIN_DIR"\
  --eval_dir="$EVAL_DIR"\
  --trace_file="$TRACE_FILE"\
  --save_model_steps="$SAVE_MODEL_SECS"\
  --eval_interval_secs="$EVAL_INTERVAL_SECS"\
  --eval_during_training_every_n_epochs="$EVAL_DURING_TRAINING_EVERY_N_EPOCHS"\
  --eval="$EVAL"\
  --optimizer="$OPTIMIZER"\
  --cross_replica_sync="$CROSS_REPLICA_SYNC"\
  --gpu_thread_mode="$GPU_THREAD_MODE"\
  --all_reduce_spec="$ALL_REDUCE_SPEC"\
  --variable_update="$VARIABLE_UPDATE"\
  --local_parameter_device="$LOCAL_PARAMETER_DEVICE"\
  --use_fp16="$USE_FP16"\
  --gradient_repacking="$GRADIENT_REPACKING"\
  --server_protocol="$SERVER_PROTOCOL"\
  --xla="$XLA"\
  --xla_compile="$XLA_COMPILE"

# Kill any lingering network measurement processes
if [[ "$ENABLE_NETWORK_TRACE" == "true" ]]; then
  ps aux | grep "collect_network_trace.sh\|ping" | awk '{print $2}' | xargs kill -9
fi


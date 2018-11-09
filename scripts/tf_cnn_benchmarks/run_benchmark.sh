#!/bin/bash

# General configs
NUM_WORKERS="${NUM_WORKERS:=4}"
NUM_GPUS="${NUM_GPUS:=4}"
DEVICE="${DEVICE:=gpu}"
DATA_FORMAT="${DATA_FORMAT:=NCHW}"
OPTIMIZER="${OPTIMIZER:=ksync}"
CROSS_REPLICA_SYNC="${CROSS_REPLICA_SYNC:=false}"
KSYNC_MODE="${KSYNC_MODE:=sync}"
BATCH_SIZE="${BATCH_SIZE:=64}"
DATASET="${DATASET:=imagenet}"
GPU_THREAD_MODE="${GPU_THREAD_MODE:=gpu_shared}"
ALL_REDUCE_SPEC="${ALL_REDUCE_SPEC:=}"
GRADIENT_REPACKING="${GRADIENT_REPACKING:=0}"
VARIABLE_UPDATE="${VARIABLE_UPDATE:=parameter_server}"
LOCAL_PARAMETER_DEVICE="${LOCAL_PARAMETER_DEVICE:=gpu}"
SERVER_PROTOCOL="${SERVER_PROTOCOL:=grpc}"
ENABLE_CHROME_TRACE="${ENABLE_CHROME_TRACE:=false}"
XLA="${XLA:=false}"
XLA_COMPILE="${XLA_COMPILE:=false}"
# Checkpoint/eval configs
SAVE_MODEL_SECS="${SAVE_MODEL_SECS:=600}"
EVAL_INTERVAL_SECS="${EVAL_INTERVAL_SECS:=$SAVE_MODEL_SECS}"
EVAL_DURING_TRAINING_EVERY_N_EPOCHS="${EVAL_DURING_TRAINING_EVERY_N_EPOCHS:=0}"
EVAL="${EVAL:=false}"

# Dataset-specific configs
if [[ "$DATASET" = "cifar10" ]]; then
  DATA_DIR="/tigress/andrewor/dataset/cifar10-dataset/cifar-10-batches-py"
  TRAIN_DIR="${TRAIN_DIR:=/tigress/andrewor/train_logs/resnet_cifar10_model_$1}"
  EVAL_DIR="/tigress/andrewor/eval_logs/resnet_cifar10_model_$1"
  MODEL="${MODEL:=resnet56}"
  USE_FP16="${USE_FP16:=false}"
elif [[ "$DATASET" = "imagenet" ]]; then
  DATA_DIR="/tigress/andrewor/dataset/imagenet-dataset"
  TRAIN_DIR="${TRAIN_DIR:=/tigress/andrewor/train_logs/resnet50_imagenet_$1}"
  EVAL_DIR="/tigress/andrewor/eval_logs/resnet50_imagenet_$1"
  MODEL="${MODEL:=resnet50_v1.5}"
  USE_FP16="${USE_FP16:=true}"
  # Optionally set base learning rate according to Facebook paper:
  # Accurate, Large Minibatch SGD: Training ImageNet in 1 Hour
  if [[ "$USE_FACEBOOK_BASE_LEARNING_RATE" == "true" ]]; then
    if [[ -n "$RESNET_BASE_LEARNING_RATE" ]]; then
      echo "ERROR: USE_FACEBOOK_BASE_LEARNING_RATE is not compatible with RESNET_BASE_LEARNING_RATE"
      exit 1
    fi
    RESNET_BASE_LEARNING_RATE="$(($BATCH_SIZE * $NUM_WORKERS * $NUM_GPUS / 256))"
    export RESNET_BASE_LEARNING_RATE="0.$RESNET_BASE_LEARNING_RATE" # divide by 10
  fi
  if [[ -n "$RESNET_BASE_LEARNING_RATE" ]]; then
    echo "Resnet base learning rate = $RESNET_BASE_LEARNING_RATE"
  fi
fi

# Enable chrome trace by setting the trace file name
if [[ "$ENABLE_CHROME_TRACE" == "true" ]]; then
  TRACE_FILE="$TRAIN_DIR/chrome.trace"
fi

# In local mode, everything is launched in one process
if [[ "$LOCAL_MODE" == "true" ]]; then
  unset SLURM_JOB_NODELIST
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

python tf_cnn_benchmarks.py\
  --num_gpus="$NUM_GPUS"\
  --device="$DEVICE"\
  --local_parameter_device="$DEVICE"\
  --data_format="$DATA_FORMAT"\
  --batch_size="$BATCH_SIZE"\
  --model="$MODEL"\
  --print_training_accuracy=true\
  --num_epochs=100\
  --data_dir="$DATA_DIR"\
  --train_dir="$TRAIN_DIR"\
  --eval_dir="$EVAL_DIR"\
  --trace_file="$TRACE_FILE"\
  --save_model_steps="$SAVE_MODEL_SECS"\
  --eval_interval_secs="$EVAL_INTERVAL_SECS"\
  --eval_during_training_every_n_epochs="$EVAL_DURING_TRAINING_EVERY_N_EPOCHS"\
  --eval="$EVAL"\
  --optimizer="$OPTIMIZER"\
  --ksync_num_replicas=4\
  --ksync_scaling_duration=6500\
  --ksync_mode="$KSYNC_MODE"\
  --cross_replica_sync="$CROSS_REPLICA_SYNC"\
  --gpu_thread_mode="$GPU_THREAD_MODE"\
  --all_reduce_spec="$ALL_REDUCE_SPEC"\
  --variable_update="$VARIABLE_UPDATE"\
  --local_parameter_device="$LOCAL_PARAMETER_DEVICE"\
  --use_fp16="$USE_FP16"\
  --gradient_repacking="$GRADIENT_REPACKING"\
  --server_protocol="$SERVER_PROTOCOL"\
  --xla="$XLA"\
  --xla_compile="$XLA_COMPILE"\
  --fp16_enable_auto_loss_scale=false # TODO: try me


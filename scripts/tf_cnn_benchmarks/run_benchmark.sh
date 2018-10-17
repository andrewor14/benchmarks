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
VARIABLE_UPDATE="${VARIABLE_UPDATE:=parameter_server}"
LOCAL_PARAMETER_DEVICE="${LOCAL_PARAMETER_DEVICE:=cpu}"

# Dataset-specific configs
if [[ "$DATASET" = "cifar10" ]]; then
  DATA_DIR="/tigress/andrewor/dataset/cifar10-dataset/cifar-10-batches-py"
  TRAIN_DIR="/tigress/andrewor/logs/resnet_cifar10_model_$1"
  MODEL="${MODEL:=resnet56}"
  USE_FP16="${USE_FP16:=false}"
elif [[ "$DATASET" = "imagenet" ]]; then
  DATA_DIR="/tigress/haoyuz/imagenet-dataset/"
  TRAIN_DIR="/tigress/andrewor/logs/resnet50_imagenet_$1"
  MODEL="${MODEL:=resnet50_v1.5}"
  USE_FP16="${USE_FP16:=true}"
  # Set base learning rate according to Facebook paper:
  # Accurate, Large Minibatch SGD: Training ImageNet in 1 Hour
  # RESNET_BASE_LEARNING_RATE="$(($BATCH_SIZE * $NUM_WORKERS * $NUM_GPUS / 256))"
  # export RESNET_BASE_LEARNING_RATE="0.$RESNET_BASE_LEARNING_RATE" # divide by 10
  # echo "Resnet base learning rate = $RESNET_BASE_LEARNING_RATE"
fi

# In true local mode, everything is launched in one process
if [[ -n "$TRUE_LOCAL_MODE" ]]; then
  unset SLURM_JOB_NODELIST
fi

echo "Running this commit: $(git log --oneline | head -n 1)"

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
  --fp16_enable_auto_loss_scale=false # TODO: try me


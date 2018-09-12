#!/bin/bash

DATA_DIR="/tigress/andrewor/dataset/cifar10-dataset/cifar-10-batches-py"
TRAIN_DIR="/tigress/andrewor/logs/resnet_cifar10_model_$1"
NUM_GPUS="${NUM_GPUS:=4}"
OPTIMIZER="${OPTIMIZER:=ksync}"
KSYNC_MODE="${KSYNC_MODE:=sync}"
MODEL="${MODEL:=resnet32}"

echo "Running this commit: $(git log --oneline | head -n 1)"

python tf_cnn_benchmarks.py\
  --num_gpus="$NUM_GPUS"\
  --batch_size=128\
  --model="$MODEL"\
  --print_training_accuracy=true\
  --num_epochs=100\
  --data_dir="$DATA_DIR"\
  --train_dir="$TRAIN_DIR"\
  --optimizer="$OPTIMIZER"\
  --ksync_num_replicas=4\
  --ksync_scaling_duration=6500\
  --ksync_mode="$KSYNC_MODE"\
  --cross_replica_sync=false


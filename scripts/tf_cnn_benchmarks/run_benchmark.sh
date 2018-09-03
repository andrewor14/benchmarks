#!/bin/bash

DATA_DIR="/tigress/andrewor/dataset/cifar10-dataset/cifar-10-batches-py"
TRAIN_DIR="/tigress/andrewor/logs/resnet_cifar10_model_$1"
NUM_GPUS="${NUM_GPUS:=4}"
KSYNC_MODE="${KSYNC_MODE:=sync}"

python tf_cnn_benchmarks.py\
  --num_gpus="$NUM_GPUS"\
  --batch_size=128\
  --model=resnet56\
  --print_training_accuracy=true\
  --num_epochs=100\
  --data_dir="$DATA_DIR"\
  --train_dir="$TRAIN_DIR"\
  --optimizer=ksync\
  --ksync_num_replicas=4\
  --ksync_mode="$KSYNC_MODE"\
  --cross_replica_sync=false


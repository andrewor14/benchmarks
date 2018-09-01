#!/bin/bash

DATA_DIR="/tigress/andrewor/dataset/cifar10-dataset/cifar-10-batches-py"
TRAIN_DIR="/tigress/andrewor/logs/resnet_cifar10_model_$1"
NUM_GPUS="${NUM_GPUS:=4}"

python tf_cnn_benchmarks.py\
  --num_gpus="$NUM_GPUS"\
  --batch_size=128\
  --model=resnet56\
  --print_training_accuracy=true\
  --data_dir="$DATA_DIR"\
  --train_dir="$TRAIN_DIR"\
  --optimizer=ksync\
  --ksync_num_replicas=3\
  --ksync_mode=sync\
  --cross_replica_sync=false


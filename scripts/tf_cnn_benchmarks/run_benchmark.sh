#!/bin/bash

DATA_DIR="/tigress/andrewor/dataset/cifar10-dataset/cifar-10-batches-py"
TRAIN_DIR="/tigress/andrewor/logs/resnet_cifar10_model_$1"

python tf_cnn_benchmarks.py\
  --num_gpus=4\
  --batch_size=128\
  --model=resnet56\
  --print_training_accuracy=True\
  --data_dir="$DATA_DIR"\
  --train_dir="$TRAIN_DIR"\
  --optimizer=momentum


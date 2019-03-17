#!/bin/bash

# Set this to 'visiongpu' or 'tigergpu'
ENVIRONMENT="visiongpu"

if [[ "$ENVIRONMENT" = "tigergpu" ]]; then
  export LOG_DIR="/home/andrewor/logs"
  export BENCHMARKS_DIR="/home/andrewor/benchmarks/scripts/tf_cnn_benchmarks"
  export IMAGENET_DATA_DIR="/tigress/andrewor/dataset/imagenet-dataset"
  export CIFAR10_DATA_DIR="/tigress/andrewor/dataset/cifar10-dataset/cifar-10-batches-py"
  export BASE_TRAIN_DIR="/tigress/andrewor/train_logs/"
  export BASE_EVAL_DIR="/tigress/andrewor/eval_logs/"
  export DEFAULT_NUM_GPUS="4"
elif [[ "$ENVIRONMENT" = "visiongpu" ]]; then
  export LOG_DIR="/home/andrewor/workspace/logs"
  export BENCHMARKS_DIR="/home/andrewor/workspace/benchmarks/scripts/tf_cnn_benchmarks"
  export IMAGENET_DATA_DIR="" #TODO: fill this in
  export CIFAR10_DATA_DIR="" # TODO: fill this in
  export BASE_TRAIN_DIR="/home/andrewor/workspace/train_data"
  export BASE_EVAL_DIR="/home/andrewor/workspace/eval_data"
  export DEFAULT_NUM_GPUS="2"
else
  echo "ERROR: Unknown environment '$ENVIRONMENT'"
  exit 1
fi


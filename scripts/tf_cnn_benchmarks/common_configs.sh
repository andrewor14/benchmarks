#!/bin/bash

# ==========================================================
#  A central collection of hard-coded environment variables
# ==========================================================

# Environment is either 'visiongpu' or 'tigergpu'
export ENVIRONMENT="visiongpu"
export SLURM_EMAIL="andrewor@princeton.edu"
export DEFAULT_NUM_NODES="4"
export DEFAULT_NUM_PARAMETER_SERVERS="1"

if [[ "$ENVIRONMENT" = "tigergpu" ]]; then
  export LOG_DIR="/home/andrewor/logs"
  export BENCHMARK_DIR="/home/andrewor/benchmarks/scripts/tf_cnn_benchmarks"
  export IMAGENET_DATA_DIR="/tigress/andrewor/dataset/imagenet-dataset"
  export CIFAR10_DATA_DIR="/tigress/andrewor/dataset/cifar10-dataset/cifar-10-batches-py"
  export BASE_TRAIN_DIR="/tigress/andrewor/train_logs/"
  export BASE_EVAL_DIR="/tigress/andrewor/eval_logs/"
  export TF_PKG="/home/andrewor/tensorflow_pkg/tensorflow-1.10.1-cp36-cp36m-linux_x86_64.whl"
  export DEFAULT_NUM_GPUS="4"
  export DEFAULT_NUM_CPUS="28"
  export DEFAULT_MEMORY="64G"
elif [[ "$ENVIRONMENT" = "visiongpu" ]]; then
  export LOG_DIR="/home/andrewor/workspace/logs"
  export BENCHMARK_DIR="/home/andrewor/workspace/benchmarks/scripts/tf_cnn_benchmarks"
  export IMAGENET_DATA_DIR="" # TODO: fill this in
  export CIFAR10_DATA_DIR="" # TODO: fill this in
  export BASE_TRAIN_DIR="/home/andrewor/workspace/train_data"
  export BASE_EVAL_DIR="/home/andrewor/workspace/eval_data"
  export TF_PKG="/home/andrewor/workspace/tensorflow_pkg/tensorflow-1.12.0rc1-cp35-cp35m-linux_x86_64.whl"
  export DEFAULT_NUM_GPUS="2"
  export DEFAULT_NUM_CPUS="88" # Note: not used
  export DEFAULT_MEMORY="64G" # Note: not used
else
  echo "ERROR: Unknown environment '$ENVIRONMENT'"
  exit 1
fi


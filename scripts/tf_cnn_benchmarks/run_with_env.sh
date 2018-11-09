#!/bin/bash

if [[ "$#" -lt 1 ]]; then
  echo "Usage: run_with_env.sh <script_name> [<arg1>] [<arg2>] ..."
  exit 1
fi

TF_PKG="/home/andrewor/tensorflow_pkg/tensorflow-1.10.1-cp36-cp36m-linux_x86_64.whl"

module load anaconda3/5.2.0
module load cudnn/cuda-9.2/7.3.1
module load openmpi/gcc/3.0.0/64

# Use our custom Open MPI library, which just points to the one we just loaded
export MPI_HOME="/home/andrewor/lib/openmpi"

# Make sure we're running our custom version of tensorflow
# Note: Do not uncomment this if you're running tensorflow in the mean time!
#pip uninstall -y tensorflow tensorflow-gpu
#pip install --user "$TF_PKG"

if [[ "$BYPASS_GPU_TEST" != "true" ]]; then
  python test_gpu_support.py
  if [[ "$?" -ne 0 ]]; then
    echo "GPU test failed. Exiting."
    exit 1
  fi
fi

bash "$@"


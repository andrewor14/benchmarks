#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=64G
#SBATCH --gres=gpu:4
#SBATCH --time=48:00:00
#
#SBATCH --job-name=benchmark-local
#SBATCH --output=slurm-%x-%j.out
#
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=andrewor@princeton.edu

RUN_PATH="/home/andrewor/benchmarks/scripts/tf_cnn_benchmarks/run_with_env.sh"
SCRIPT_NAME="run_benchmark_local.sh"

srun "$RUN_PATH" "$SCRIPT_NAME"


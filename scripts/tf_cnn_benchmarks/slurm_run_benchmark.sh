#!/bin/bash
#
#SBATCH --nodes=5
#SBATCH --ntasks=5
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=64G
#SBATCH --gres=gpu:4
#SBATCH --time=1:00:00
#
#SBATCH --job-name=benchmark
#SBATCH --output=slurm-%x-%j.out
#
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=andrewor@princeton.edu

SLURM_LOG_DIR="/home/andrewor/logs"
RUN_PATH="/home/andrewor/benchmarks/scripts/tf_cnn_benchmarks/run_with_env.sh"
SCRIPT_NAME="run_benchmark.sh"
TIMESTAMP=`date +%s`

srun --output="$SLURM_LOG_DIR/slurm-$RUN_TAG-$KSYNC_MODE-%j-%n-$TIMESTAMP.out" "$RUN_PATH" "$SCRIPT_NAME" "$TIMESTAMP"


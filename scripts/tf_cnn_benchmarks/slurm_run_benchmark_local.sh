#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=64G
#SBATCH --gres=gpu:4
#SBATCH --time="144:00:00"
#
#SBATCH --job-name=benchmark-local
#SBATCH --output=slurm-%x-%j.out
#
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=andrewor@princeton.edu

SLURM_LOG_DIR="/home/andrewor/logs"
RUN_PATH="/home/andrewor/benchmarks/scripts/tf_cnn_benchmarks/run_with_env.sh"
SCRIPT_NAME="run_benchmark.sh"
TIMESTAMP=`date +%s`
RUN_TAG="$RUN_TAG-local"

export LOCAL_MODE="true"
export NUM_WORKERS="1"
export LOCAL_PARAMETER_DEVICE="cpu"
export EVAL_DURING_TRAINING_EVERY_N_EPOCHS="5"

srun --output="$SLURM_LOG_DIR/slurm-$RUN_TAG-%j-%n-$TIMESTAMP.out" "$RUN_PATH" "$SCRIPT_NAME" "$TIMESTAMP"


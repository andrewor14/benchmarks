#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=64G
#SBATCH --gres=gpu:4
#SBATCH --time=00:10:00
#
#SBATCH --job-name=benchmark-local
#SBATCH --output=slurm-%x-%j.out
#
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=andrewor@princeton.edu

SLURM_LOG_DIR="/home/andrewor/logs"
RUN_PATH="/home/andrewor/benchmarks/scripts/tf_cnn_benchmarks/run_with_env.sh"
SCRIPT_NAME="run_benchmark_local.sh"
TIMESTAMP=`date +%s`

if [[ -n "$KSYNC_MODE" ]]; then
  MODE="$KSYNC_MODE"
elif [[ -n "$OPTIMIZER" ]]; then
  MODE="$OPTIMIZER"
  if [[ -n "$CROSS_REPLICA_SYNC" ]]; then
    MODE="$MODE-$CROSS_REPLICA_SYNC"
  fi
fi

if [[ -n "$MODE" ]]; then
  RUN_TAG="$RUN_TAG-$MODE"
fi

srun --output="$SLURM_LOG_DIR/slurm-$RUN_TAG-%j-%n-$TIMESTAMP.out" "$RUN_PATH" "$SCRIPT_NAME" "$TIMESTAMP"


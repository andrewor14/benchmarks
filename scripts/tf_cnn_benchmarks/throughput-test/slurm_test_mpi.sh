#!/bin/bash
#
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#
#SBATCH --job-name=mpi-test
#SBATCH --output=slurm-%x-%j.out
#
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=andrewor@princeton.edu

SLURM_LOG_DIR="/home/andrewor/logs"
RUN_SCRIPT="/home/andrewor/test/a.out"
TIMESTAMP=`date +%s`

srun --output="$SLURM_LOG_DIR/mpi-test-%j-%n-$TIMESTAMP.out" "$RUN_SCRIPT"


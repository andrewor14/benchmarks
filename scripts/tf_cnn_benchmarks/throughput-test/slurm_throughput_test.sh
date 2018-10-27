#!/bin/bash
#
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --ntasks-per-node=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#
#SBATCH --job-name=throughput-test
#SBATCH --output=slurm-%x-%j.out
#
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=andrewor@princeton.edu

SLURM_LOG_DIR="/home/andrewor/logs"
RUN_SCRIPT="throughput_test.sh"
TIMESTAMP=`date +%s`

# This doesn't seem necessary? Not sure.
#module load openmpi/gcc/3.0.0/64

srun --output="$SLURM_LOG_DIR/mpi-throughput-test-$TIMESTAMP" $RUN_SCRIPT


#!/bin/bash
#
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --ntasks-per-node=1
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
RUN_SCRIPT="/home/andrewor/benchmarks/scripts/tf_cnn_benchmarks/throughput-test/a.out"
TIMESTAMP=`date +%s`

module load openmpi/gcc/3.0.0/64

srun --output="$SLURM_LOG_DIR/mpi-test-%j-%n-$TIMESTAMP.out" "$RUN_SCRIPT"


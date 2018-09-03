#!/bin/bash

KSYNC_MODE="sync" sbatch slurm_run_benchmark.sh
KSYNC_MODE="async" sbatch slurm_run_benchmark.sh
KSYNC_MODE="ksync" sbatch slurm_run_benchmark.sh


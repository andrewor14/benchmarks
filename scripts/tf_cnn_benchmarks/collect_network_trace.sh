#!/bin/bash

# ==========================================================================
#  Helper script that logs network statistics until the end of its lifetime
# ==========================================================================

# Set common configs
source common_configs.sh

# Listen on first interface
INTERFACE="$(ifconfig | grep -e "^\w" | awk -F ':' '{print $1}' | head -n 1)"

# Set trace file location
if [[ "$SERVER_PROTOCOL" == *"mpi"* ]]; then
  # Note: for MPI, we can't rely on SLURM_NODEID anymore because
  # sometimes slurm and MPI don't agree on the number of processes
  TRACE_FILE="$LOG_DIR/mpi-$JOB_NAME/1/rank.$OMPI_COMM_WORLD_RANK/eth.txt"
else
  TRACE_FILE="$LOG_DIR"/eth-"$SLURM_JOB_NAME"-"$SLURM_NODEID".txt
fi

# Header
echo "timestamp rx_bytes tx_bytes" > "$TRACE_FILE"

# Measure every ms
while sleep .001; do
  timestamp="$(date +%s%3N)"
  stats="$(ethtool -S $INTERFACE | grep '^\s*rx_bytes\|^\s*tx_bytes' | awk '{print $2}' | xargs)"
  printf "%s %s\n" "$timestamp" "$stats" >> "$TRACE_FILE"
done


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
  NODE_INDEX="$OMPI_COMM_WORLD_RANK"
  TRACE_FILE="$LOG_DIR/mpi-$JOB_NAME/1/rank.$NODE_INDEX/eth.txt"
else
  NODE_INDEX="$SLURM_NODEID"
  TRACE_FILE="$LOG_DIR"/eth-"$SLURM_JOB_NAME"-"$NODE_INDEX".txt
fi

# Header
echo "Recording network activity to $TRACE_FILE"
echo "timestamp rx_bytes tx_bytes" > "$TRACE_FILE"

# Start a steady stream of ping packets in the background.
# This is necessary because we rely on network counters. Because these counters
# are not updated frequently, it's hard to tell the difference between an idle
# period no network activity and the counters not being updated. Therefore here
# we force some minimal communication in the background.
if [[ -n "$SLURM_JOB_NODELIST" ]] && [[ -n "$SLURM_JOB_NUM_NODES" ]]; then
  # First find target server to ping; everyone will ping the next server in the nodelist
  # This is +1 for the next node index, and +1 because we want the (n+1)th line
  TARGET_NODE_INDEX="$((($NODE_INDEX + 1) % $SLURM_JOB_NUM_NODES))"
  TARGET_NODE_INDEX="$(($TARGET_NODE_INDEX + 1))"
  TARGET_NODE_HOSTNAME="$(python tensorflow_on_slurm.py $SLURM_JOB_NODELIST | sed -n ${TARGET_NODE_INDEX}p)"
  NETWORK_TRACE_PING_INTERVAL_SECONDS="${NETWORK_TRACE_PING_INTERVAL_SECONDS:=0.5}"
  echo "Pinging $TARGET_NODE_HOSTNAME in the background at interval = ${NETWORK_TRACE_PING_INTERVAL_SECONDS}s"
  ping -i "$NETWORK_TRACE_PING_INTERVAL_SECONDS" "$TARGET_NODE_HOSTNAME" > /dev/null 2>&1 &
else
  echo "Warning: not pinging next server because SLURM_NODELIST or SLURM_NNODES is not defined" 
fi

# Measure every ms
while sleep .001; do
  timestamp="$(date +%s%3N)"
  stats="$(ethtool -S $INTERFACE | grep '^\s*rx_bytes\|^\s*tx_bytes' | awk '{print $2}' | xargs)"
  printf "%s %s\n" "$timestamp" "$stats" >> "$TRACE_FILE"
done


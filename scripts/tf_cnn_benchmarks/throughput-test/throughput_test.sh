#!/bin/bash

SERVER_NODE="$(scontrol show hostname $SLURM_JOB_NODELIST | head -n 1)"
CLIENT_NODE="$(scontrol show hostname $SLURM_JOB_NODELIST | tail -n 1)"
IPERF_PATH="/home/andrewor/lib/iperf-2.0.5/src"
STAY_ALIVE_DURATION=60 # seconds

echo "Slurm node list: $SLURM_JOB_NODELIST"
echo "Server node: $SERVER_NODE"
echo "Client node: $CLIENT_NODE"
echo "Me: $SLURMD_NODENAME"

# We're the first node, so send the stuff
if [[ "$SLURMD_NODENAME" == "$SERVER_NODE" ]]; then
  echo "I am the server node ($SERVER_NODE). Starting server."
  "$IPERF_PATH"/iperf -s -m
elif [[ "$SLURMD_NODENAME" == "$CLIENT_NODE" ]]; then
  echo "I am the client node ($CLIENT_NODE). Connecting to server $SERVER_NODE."
  "$IPERF_PATH"/iperf -c $SERVER_NODE -m
fi

echo "Staying alive for $STAY_ALIVE_DURATION seconds"
sleep "$STAY_ALIVE_DURATION"

echo "Done."


# --------------------------------------------------------------------
# Code derived from
# https://github.com/deepsense-ai/tensorflow_on_slurm
# --------------------------------------------------------------------

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os


SLURM_JOB_NODELIST = "SLURM_JOB_NODELIST"
SLURM_JOB_NUM_NODES = "SLURM_JOB_NUM_NODES"
SLURMD_NODENAME = "SLURMD_NODENAME"

# For multiplexing a node to multiple processes
SLURMD_PROC_INDEX = "SLURMD_PROC_INDEX"
SLURM_JOB_NUM_PROCS_PER_NODE = "SLURM_JOB_NUM_PROCS_PER_NODE"

def running_through_slurm():
  return SLURM_JOB_NODELIST in os.environ and SLURMD_NODENAME in os.environ

def tf_config_from_slurm(ps_number, port_number=2222):
  """
  Creates configuration for a distributed tensorflow session
  from environment variables  provided by the Slurm cluster
  management system.

  Note: This assumes that nodes are either ps or workers,
  and so does not work with the estimator API.

  @param: ps_number number of parameter servers to run
  @param: port_number port number to be used for communication
  @return: a tuple containing cluster with fields cluster_spec,
           task_name and task_id
  """

  if not running_through_slurm():
    raise ValueError("Slurm environment variables not found.")

  node_name = os.environ[SLURMD_NODENAME]
  node_list = _expand_node_list(os.environ[SLURM_JOB_NODELIST])
  num_nodes = int(os.environ[SLURM_JOB_NUM_NODES])
  proc_index = int(os.getenv(SLURMD_PROC_INDEX) or 0)
  num_procs_per_node = int(os.getenv(SLURM_JOB_NUM_PROCS_PER_NODE) or 1)

  if num_procs_per_node > 4:
    raise ValueError("We currently don't support more than 4 processes on one node")

  if len(node_list) != num_nodes:
    raise ValueError("Number of slurm nodes {} not equal to {}"
                     .format(len(node_list), num_nodes))

  if node_name not in node_list:
    raise ValueError("Node name ({}) not in node list ({}). This should not happen! "
                     .format(node_name, node_list))

  if proc_index < 0 or proc_index >= num_procs_per_node:
    raise ValueError("{} must be between 0 and {}, was {}"
                     .format(SLURMD_PROC_INDEX, num_procs_per_node - 1, proc_index))

  # Attach the port number to each node and maybe expand each node into multiple processes
  new_node_list = []
  for node in node_list:
    for i in range(num_procs_per_node):
      new_node_name = "%s:%s" % (node, port_number + i)
      new_node_list.append(new_node_name)
      if node == node_name and i == proc_index:
        node_name = new_node_name
  node_list = new_node_list

  # Assign parameter servers and workers
  ps_nodes = [node for i, node in enumerate(node_list) if i < ps_number]
  worker_nodes = [node for i, node in enumerate(node_list) if i >= ps_number]

  if node_name in ps_nodes:
    my_job_name = "ps"
    my_task_index = ps_nodes.index(node_name)
  elif node_name in worker_nodes:
    my_job_name = "worker"
    my_task_index = worker_nodes.index(node_name)
  else:
    raise ValueError("Node name ({}) is neither a ps nor a worker!".format(node_name))

  cluster = {"ps": ps_nodes, "worker": worker_nodes}

  return cluster, my_job_name, my_task_index

def _expand_node_list(node_list):
  """
  Updated by haoyuz:
  The following implementation (commented, from original code) does not understand
  patterns like "tiger-i19g7,tiger-i20g[5-7]"
  At this moment we cannot find code that correctly converts the node_list to hostnames.
  The command `scontrol` does the trick:
    scontrol show hostnames 'compute-b24-[1-3,5-9],compute-b25-[1,4,8]'
  Note that this only works for Python 3.5+ and is NOT backwards compatible.

  :param node_list: list of Slurm node in shortened format
  :return: list of strings, each one is a hostname
  """

  import subprocess
  return subprocess.run(
      ["scontrol show hostname $SLURM_JOB_NODELIST"],
      shell=True,
      stdout=subprocess.PIPE).stdout.decode('utf-8').split()

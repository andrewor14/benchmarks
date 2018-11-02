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
SLURM_JOB_NUM_WORKERS_PER_NODE = "SLURM_JOB_NUM_WORKERS_PER_NODE"

def running_through_slurm():
  return SLURM_JOB_NODELIST in os.environ and SLURMD_NODENAME in os.environ

def tf_config_from_slurm(num_parameter_servers, port_number=2222):
  """
  Creates configuration for a distributed tensorflow session
  from environment variables  provided by the Slurm cluster
  management system.

  Note: This assumes that nodes are either ps or workers,
  and so does not work with the estimator API.

  @param: num_parameter_servers number of parameter servers to run
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
  num_workers_per_node = int(os.getenv(SLURM_JOB_NUM_WORKERS_PER_NODE) or 1)
  num_parameter_servers_remaining = num_parameter_servers

  if num_workers_per_node > 4:
    raise ValueError("We currently don't support more than 4 processes on one node")

  if len(node_list) != num_nodes:
    raise ValueError("Number of slurm nodes {} not equal to {}"
                     .format(len(node_list), num_nodes))

  if node_name not in node_list:
    raise ValueError("Node name ({}) not in node list ({}). This should not happen! "
                     .format(node_name, node_list))

  # proc_index can be == num_workers_per_node because this might be a PS
  if proc_index < 0 or proc_index > num_workers_per_node:
    raise ValueError("{} must be between 0 and {}, was {}"
                     .format(SLURMD_PROC_INDEX, num_workers_per_node, proc_index))

  if num_parameter_servers > num_nodes:
    raise ValueError("Number of parameter servers {} cannot be greater than the number of nodes {}"
                     .format(num_parameter_servers, num_nodes))

  # Attach the port number to each node and maybe expand each node into multiple processes
  my_proc_name = None
  ps_procs = []
  worker_procs = []
  for node in node_list:
    # The first N nodes have 1 extra process, where N = num parameter servers
    num_procs = num_workers_per_node
    if num_parameter_servers_remaining > 0:
      num_procs += 1
      num_parameter_servers_remaining -= 1
    for i in range(num_procs):
      proc_name = "%s:%s" % (node, port_number + i)
      if node == node_name and i == proc_index:
        my_proc_name = proc_name
      # Assign parameter servers and workers
      if i < num_workers_per_node:
        worker_procs.append(proc_name)
      else:
        ps_procs.append(proc_name)

  assert my_proc_name is not None

  if my_proc_name in ps_procs:
    my_job_name = "ps"
    my_task_index = ps_procs.index(my_proc_name)
  elif my_proc_name in worker_procs:
    my_job_name = "worker"
    my_task_index = worker_procs.index(my_proc_name)
  else:
    raise ValueError("Process ({}) is neither a ps nor a worker!".format(my_proc_name))

  cluster = {"ps": ps_procs, "worker": worker_procs}

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

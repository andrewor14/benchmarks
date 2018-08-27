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

  nodename = os.environ[SLURMD_NODENAME]
  nodelist = _expand_nodelist(os.environ[SLURM_JOB_NODELIST])
  num_nodes = int(os.environ[SLURM_JOB_NUM_NODES])

  if len(nodelist) != num_nodes:
    raise ValueError("Number of slurm nodes {} not equal to {}".format(len(nodelist), num_nodes))

  if nodename not in nodelist:
    raise ValueError("Nodename({}) not in nodelist({}). This should not happen! ".format(nodename, nodelist))

  ps_nodes = [node for i, node in enumerate(nodelist) if i < ps_number]
  worker_nodes = [node for i, node in enumerate(nodelist) if i >= ps_number]

  if nodename in ps_nodes:
    my_job_name = "ps"
    my_task_index = ps_nodes.index(nodename)
  elif nodename in worker_nodes:
    my_job_name = "worker"
    my_task_index = worker_nodes.index(nodename)
  else:
    raise ValueError("Nodename({}) is neither a ps nor a worker!".format(nodename))

  ps_ipports = [":".join([node, str(port_number)]) for node in ps_nodes]
  worker_ipports  = [":".join([node, str(port_number)]) for node in worker_nodes]
  cluster = {"ps": ps_ipports, "worker": worker_ipports}

  return cluster, my_job_name, my_task_index

def _expand_nodelist(nodelist):
  """
  Updated by haoyuz:
  The following implementation (commented, from original code) does not understand
  patterns like "tiger-i19g7,tiger-i20g[5-7]"
  At this moment we cannot find code that correctly converts the nodelist to hostnames.
  The command `scontrol` does the trick:
    scontrol show hostnames 'compute-b24-[1-3,5-9],compute-b25-[1,4,8]'
  Note that this only works for Python 3.5+ and is NOT backwards compatible.

  :param nodelist: list of Slurm node in shortened format
  :return: list of strings, each one is a hostname
  """

  import subprocess
  return subprocess.run(
      ["scontrol show hostname $SLURM_JOB_NODELIST"],
      shell=True,
      stdout=subprocess.PIPE).stdout.decode('utf-8').split()

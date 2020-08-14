#!/bin/bash
#
# Add replica servers using minos.
#

PID=$$

if [ $# -le 2 ]; then
  echo "USAGE: $0 <cluster-name> <cluster-meta-list> <replica-task-id-list>"
  echo
  echo "For example:"
  echo "  $0 onebox 127.0.0.1:34601,127.0.0.1:34602 1,2,3"
  echo
  exit 1
fi

cluster=$1
meta_list=$2
replica_task_id_list=$3

pwd="$( cd "$( dirname "$0"  )" && pwd )"
shell_dir="$( cd $pwd/.. && pwd )"
cd $shell_dir

echo "Check the argument..."
source ./scripts/pegasus_check_arguments.sh add_node_list $cluster $meta_list $replica_task_id_list

if [ $? -ne 0 ]; then
    echo "ERROR: the argument check failed"
    exit 1
fi

echo "Set meta level to steady..."
echo "set_meta_level steady" | ./run.sh shell --cluster $meta_list &>/tmp/$UID.$PID.pegasus.add_node_list.set_meta_level
set_ok=`grep 'control meta level ok' /tmp/$UID.$PID.pegasus.add_node_list.set_meta_level | wc -l`
if [ $set_ok -ne 1 ]; then
  echo "ERROR: set meta level to steady failed"
  exit 1
fi

for id in $task_id_list
do
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  minos_bootstrap $cluster replica $id
  if [ $? -ne 0 ]; then
    echo "ERROR: online replica task $id failed"
    exit 1
  fi
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
done

source ./scripts/pegasus_rebalance_cluster $cluster $meta_list true

echo "Finish time: `date`"
all_finish_time=$((`date +%s`))
echo "add node list done, elasped time is $((all_finish_time - all_start_time)) seconds."

rm -f /tmp/$UID.$PID.pegasus.* &>/dev/null

#!/bin/bash

source "./common.sh"

workload="zipfian95"
num_threads=80

# setup crdb servers
echo "Setting up crdb servers"
for i in "${!crdb_machines[@]}"
do
	remote_cmd="cd $crdb_wdir; `echoCrdbEnvVars 0 $lhfallback_prob`; `echoCrdbStartCmd ${crdb_internal_ips[$i]}`"
	if [ $i == 0 ]; then
		ssh ${crdb_machines[$i]} "$remote_cmd" &
	else
		ssh ${crdb_machines[$i]} "$remote_cmd --join=${crdb_internal_ips[0]}:$crdb_port" &
	fi
done
sleep 10

# init db
ssh ${crdb_machines[0]} "cd $crdb_wdir; echo 'num_replicas: $num_replicas' | ./cockroach --url='${pg_urls[0]}' zone set .default -f -"
ssh ${crdb_machines[0]} "cd $crdb_wdir; echo 'range_max_bytes: $range_max_bytes' | ./cockroach --url='${pg_urls[0]}' zone set .default -f -"
ssh ${crdb_machines[0]} "cd $crdb_wdir; ./cockroach sql --url='${pg_urls[0]}' --execute='create database $db_name'"
ssh $ycsb_machine "cd $ycsb_wdir; $cmd_ycsb_create_table"

# load workload
echo "Loading $workload workload"
ssh $ycsb_machine "cd $ycsb_wdir; `echoYcsbCmd load workloads/zipfian95 20`"

for (( i = 0; i < 10; i++ )); do
	echo "Running YCSB for $num_threads threads"
	ssh $ycsb_machine "cd $ycsb_wdir; `echoYcsbCmd run workloads/$workload $num_threads`"
	echo "Finished running YCSB"
done

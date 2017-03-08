#!/bin/bash
#
# Usage: ./master.sh <arg>
# If "clean" is supplied as arg, only cleanup is done
#

source "./common.sh"

function cleanup {
	echo "Cleaning up YCSB client"
	ssh $ycsb_machine "cd $ycsb_wdir; $cmd_kill_nmon; $cmd_rm_nmon_files"

	echo "Cleaning up crdb servers"
	for server in "${crdb_machines[@]}"
	do
		ssh $server "cd $crdb_wdir; $cmd_kill_crdb; $cmd_rm_crdb_files; $cmd_kill_nmon; $cmd_rm_nmon_files"
	done
}

# $1: read_type
# $2: workload
# $3: count
function run {
	read_type=$1
	workload=$2
	count=$3

	printf "\n\n\n"
	echo "!!!RUN STARTED [read_type: $read_type, workload: $workload, count: $count]"

	benchmark_dir="$benchmark_dir_prefix.$read_type.$workload.$count"

	# setup crdb servers
	echo "Setting up crdb servers"
	for i in "${!crdb_machines[@]}"
	do
		remote_cmd="cd $crdb_wdir; `echoCrdbEnvVars $read_type $lhfallback_prob`; `echoCrdbStartCmd ${crdb_internal_ips[$i]}`"
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
	ssh $ycsb_machine "cd $ycsb_wdir; `echoYcsbCmd load workloads/$workload 20`"

	# warmup
	echo "Warming up using $workload workload"
	ssh $ycsb_machine "cd $ycsb_wdir; `echoYcsbCmd run workloads/$workload 20`"
	sleep 5

	# run benchmark
	"./run-benchmark.sh" "$benchmark_dir" "$workload"

	# fetch db logs
	for i in "${!crdb_machines[@]}"
	do
		fetchUsingSsh "${crdb_names[$i]}" "${crdb_machines[$i]}" "$crdb_wdir/cockroach-data/logs/*" "benchmarks/$benchmark_dir/logs/${crdb_names[$i]}"
	done

	echo "RUN FINISHED!!!"
	printf "\n\n\n"
}

if [[ $# == 1 ]] && [[ $1 == "clean" ]]; then
	cleanup
	exit 0
fi

for read_type in "${read_types[@]}"
do
	for workload in "${workloads[@]}"
	do
		for (( c=0; c<$repetitions; c++ ))
		do
			cleanup
			run $read_type $workload $c
		done
	done
done
cleanup

if [[ ! -z ${all_ec2_ids[@]} ]]; then
	echo "Terminating EC2 instances..."
	python "ec2.py" "stop" "${all_ec2_ids[@]}"	
fi

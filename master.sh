#!/bin/bash
#
# Usage: ./master.sh
# Uses:
#		local:	init-test-db.sh, run-benchmark.sh
#		remote:	startup.sh, cleanup.sh
#

benchmark_dir_prefix="02.26.17"
read_types=( "0" "1" "2" "3" )
workloads=( "uniform" "zipfian" )
repetitions=3

all_machines=( "dsl0" "dsl1" "dsl2" "dsl3" )
crdb_machines=( "dsl0" "dsl1" "dsl2" )
wdir="~/tanuj"
ycsb_machine="dsl3"
ycsb_wdir="~/tanuj/ycsb-jdbc-binding-0.11.0"

function cleanup {
	echo "Cleaning up YCSB client"
	ssh $ycsb_machine "cd $ycsb_wdir; ./cleanup.sh"

	echo "Cleaning up crdb servers"
	for server in "${crdb_machines[@]}"
	do
		ssh $server "cd $wdir; ./cleanup.sh"
	done
}

# $1: read_type
# $2: workload
# $3: count
function run {
	read_type=$1
	workload=$2
	count=$3

	echo "Run started [read_type: $read_type, workload: $workload, count: $count]"

	benchmark_dir="$benchmark_dir_prefix.$read_type.$workload.$count"
	
	# setup YCSB client
	echo "Setting up YCSB client"
	ssh $ycsb_machine "cd $ycsb_wdir; ./startup.sh"

	# setup crdb servers
	echo "Setting up crdb servers"
	for server in "${crdb_machines[@]}"
	do
		ssh $server "cd $wdir; export COCKROACH_READ_TYPE=$read_type; ./startup.sh" &
	done
	sleep 10

	# init db
	"./init-test-db.sh"

	# load workload
	echo "Loading $workload workload"
	ssh "$ycsb_machine" "cd $ycsb_wdir; bin/ycsb load jdbc -P cockroachdb-ycsb/$workload -P cockroachdb-ycsb/cockroachdb.properties -s -cp cockroachdb-ycsb/bin/postgresql-9.4.1212.jre7.jar -threads 20"
	sleep 5

	# run benchmark
	"./run-benchmark.sh" "$benchmark_dir" "$workload"

	echo "Run finished!"
	echo ""
}

# main
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

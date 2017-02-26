#!/bin/bash
#
# Usage: ./run-benchmark.sh <benchmarks_dir>
# Runs a ycsb benchmark for different num of threads
#

benchmarks_dir="$1"
num_threads=( 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 )
all_machines=( "dsl0" "dsl1" "dsl2" "dsl3" )
crdb_machines=( "dsl0" "dsl1" "dsl2" )
ycsb_machine="dsl3"
nmon_time_secs="120"

for num in "${num_threads[@]}"
do
	# start nmon
	for server in "${all_machines[@]}"
	do
		echo "Starting nmon on $server"
		ssh $server "cd tanuj; nmon -f -s1 -c $nmon_time_secs"
	done

	start_ts=`date +%s`

	# start ycsb
	echo "Running YCSB for $num threads"
	ssh $ycsb_machine "cd tanuj/ycsb-jdbc-binding-0.11.0; bin/ycsb run jdbc -P cockroachdb-ycsb/workload -P cockroachdb-ycsb/cockroachdb.properties -s -cp cockroachdb-ycsb/bin/postgresql-9.4.1212.jre7.jar -threads $num &> ycsb-results"
	echo "Finished running YCSB"

	# wait for nmon to finish
	finish_ts=`date +%s`
	elapsed_ts=$(($finish_ts-$start_ts))
	to_wait_ts=$(($nmon_time_secs-$elapsed_ts))
	echo "Waiting $to_wait_ts secs for nmon to finish..."
	sleep $to_wait_ts

	path="./benchmarks/$benchmarks_dir/$num"
	mkdir -p $path

	# fetch ycsb_results
	"./fetch-using-ssh.sh" "$ycsb_machine" "~/tanuj/ycsb-jdbc-binding-0.11.0/ycsb-results" "$path"

	# fetch data.dump
	for server in "${crdb_machines[@]}"
	do
		"./fetch-using-ssh.sh" "$server" "~/tanuj/data.dump" "$path/$server"
	done

	# fetch *.nmon
	for server in "${all_machines[@]}"
	do
		"./fetch-using-ssh.sh" "$server" "~/tanuj/*.nmon" "$path/$server"
	done

	echo ""
done

# fetch raft-leaders.csv
path="./benchmarks/$benchmarks_dir"
"./fetch-using-ssh.sh" "$ycsb_machine" "~/tanuj/ycsb-jdbc-binding-0.11.0/raft-leaders.csv" "$path"

#!/bin/bash
#
# Usage: ./run-benchmark.sh <benchmarks_dir> <workload>
# Runs a ycsb benchmark for different num of threads
#

source "./common.sh"

benchmarks_dir="$1"
workload="$2"

# remove initial data.dump files
for i in "${!crdb_machines[@]}"
do
	echo "Removing *.dump from ${crdb_names[$i]}"
	ssh ${crdb_machines[$i]} "cd $crdb_wdir; rm -rf *.dump"
done

# run benchmark for diff num of threads
for num in "${num_threads[@]}"
do
	# start nmon
	for i in "${!all_machines[@]}"
	do
		echo "Starting nmon on ${all_names[$i]}"
		ssh ${all_machines[$i]} "cd $nmon_wdir; nmon -f -s1 -c 10000"
	done

	# start ycsb
	echo "Running YCSB for $num threads"
	ssh $ycsb_machine "cd $ycsb_wdir; `echoYcsbCmd run workloads/$workload $num` &> ycsb-results"
	echo "Finished running YCSB"

	path="./benchmarks/$benchmarks_dir/$num"
	mkdir -p "$path"

	# fetch ycsb_results
	fetchUsingSsh "$ycsb_name" "$ycsb_machine" "$ycsb_wdir/ycsb-results" "$path"

	# fetch *.nmon
	for i in "${!all_machines[@]}"
	do
		echo "Stopping nmon on ${all_names[i]}"
		ssh ${all_machines[$i]} "$cmd_stop_nmon"
		fetchUsingSsh "${all_names[$i]}" "${all_machines[$i]}" "$nmon_wdir/*.nmon" "$path/${all_names[$i]}"
	done

	# fetch data.dump
	for i in "${!crdb_machines[@]}"
	do
		fetchUsingSsh "${crdb_names[$i]}" "${crdb_machines[$i]}" "$crdb_wdir/data.dump" "$path/${crdb_names[$i]}"
	done

	echo ""
done

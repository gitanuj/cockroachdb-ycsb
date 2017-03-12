#!/bin/bash
#
# Usage: ./run-benchmark.sh <benchmark_dir> <workload>
# Runs a ycsb benchmark for different num of threads
#

source "./common.sh"

benchmark_dir="$1"
workload="$2"

# run benchmark for diff num of threads
for num in "${num_threads[@]}"
do
	startNmon
	runYcsb $workload $num

	path="./benchmarks/$benchmark_dir/$num"
	mkdir -p "$path"

	fetchUsingSsh "$ycsb_name" "$ycsb_machine" "$ycsb_wdir/ycsb-results" "$path"
	stopAndFetchNmonResults $path
	fetchDataDump $path

	echo ""
done

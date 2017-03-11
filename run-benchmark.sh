#!/bin/bash
#
# Usage: ./run-benchmark.sh <benchmarks_dir> <workload>
# Runs a ycsb benchmark for different num of threads
#

source "./common.sh"

benchmarks_dir="$1"
workload="$2"

# remove initial data.dump files
removeDataDump

# run benchmark for diff num of threads
for num in "${num_threads[@]}"
do
	startNmon
	runYcsb $workload $num

	path="./benchmarks/$benchmarks_dir/$num"
	mkdir -p "$path"

	fetchUsingSsh "$ycsb_name" "$ycsb_machine" "$ycsb_wdir/ycsb-results" "$path"
	stopAndFetchNmonResults $path
	fetchDataDump $path

	echo ""
done

#!/bin/bash
#
# Usage: ./run-benchmark-ntimes.sh
# Runs run-benchmark.sh n times
# PS: Update run-benchmark.sh and vars below
#

benchmark_dirs=( "02.26.17.1" "02.26.17.2" "02.26.17.3" )

for benchmark_dir in "${benchmark_dirs[@]}"
do
	echo "Running benchmark: $benchmark_dir"
	"./run-benchmark.sh" "$benchmark_dir"
done

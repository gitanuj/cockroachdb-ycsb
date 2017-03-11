#!/bin/bash
#
# Usage: ./master.sh <arg>
# If "clean" is supplied as arg, only cleanup is done
#

source "./common.sh"

# $1: read_type
# $2: workload
# $3: count
# $4: num of threads
function run {
	read_type=$1
	workload=$2
	count=$3
	num=$4

	printf "\n\n\n"
	echo "!!!RUN STARTED [read_type: $read_type, workload: $workload, count: $count]"

	benchmark_dir="$benchmark_dir_prefix.$read_type.$workload.$count"
	path="./benchmarks/$benchmark_dir/$num"
	mkdir -p "$path"

	setup
	loadAndWarmupDb $workload

	removeDataDump
	startNmon
	runYcsb $workload $num

	fetchUsingSsh "$ycsb_name" "$ycsb_machine" "$ycsb_wdir/ycsb-results" "$path"
	stopAndFetchNmonResults $path
	fetchDataDump $path

	echo "RUN FINISHED!!!"
	printf "\n\n\n"
}

if [[ $# == 1 ]] && [[ $1 == "clean" ]]; then
	cleanup
	exit 0
fi

run "1" "zipfian95" "0" "40"
cleanup

run "1" "zipfian95" "0" "45"
cleanup

run "2" "zipfian95" "0" "40"
cleanup

run "3" "zipfian95" "0" "70"
cleanup

run "3" "zipfian95" "0" "80"
cleanup

# for read_type in "${read_types[@]}"
# do
# 	for workload in "${workloads[@]}"
# 	do
# 		for (( c=0; c<$repetitions; c++ ))
# 		do
# 			cleanup
# 			run $read_type $workload $c
# 		done
# 	done
# done
# cleanup

# if [[ ! -z ${all_ec2_ids[@]} ]]; then
# 	echo "Terminating EC2 instances..."
# 	python "ec2.py" "stop" "${all_ec2_ids[@]}"	
# fi

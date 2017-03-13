#!/bin/bash
#
# Usage: ./master.sh <arg>
# If "clean" is supplied as arg, only cleanup is done
#

source "./common.sh"

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

	setup $read_type $lhfallback_prob
	loadAndWarmupDb $workload

	removeDataDump
	"./run-benchmark.sh" $benchmark_dir $workload

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
		# for lhfallback_prob in "${lhfallback_probs[@]}"
		# do
		for (( c=0; c<$repetitions; c++ ))
		do
			cleanup
			run $read_type $workload $c
		done
		# done
	done
done
cleanup

say "Benchmark Complete"

# if [[ ! -z ${all_ec2_ids[@]} ]]; then
# 	echo "Terminating EC2 instances..."
# 	python "ec2.py" "stop" "${all_ec2_ids[@]}"	
# fi

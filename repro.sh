#!/bin/bash
#
# To repro the 'zipfian' workload bug in crdb
#

source "./common.sh"

workload="zipfian95"
num_threads=80

cleanup

setup 0 0
loadAndWarmupDb $workload

for (( i = 0; i < 10; i++ )); do
	runYcsb $workload $num_threads
done

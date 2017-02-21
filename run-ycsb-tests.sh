#!/bin/bash
num_threads=( 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 )
ycsb_machine="dsl3"
benchmarks_dir="02.20.17.1"
for num in "${num_threads[@]}"
do
	"./start-nmon.sh"

	echo "Running YCSB for $num threads"
	ssh $ycsb_machine "cd tanuj/ycsb-jdbc-binding-0.11.0; ./run-ycsb-test.sh $num"
	echo "Finished running YCSB"

	echo "Waiting 120s for nmon to finish..."
	sleep 120

	path="./benchmarks/$benchmarks_dir/$num"
	mkdir -p $path
	echo "Fetching ycsb-results from $ycsb_machine"
	scp "$ycsb_machine:~/tanuj/ycsb-jdbc-binding-0.11.0/ycsb-results" $path
	"./fetch-nmon-results.sh"
	mv dsl* $path
	echo ""
done
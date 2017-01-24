#!/bin/bash
num_threads=( 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 )
for num in "${num_threads[@]}"
do
	"./start-nmon.sh"

	echo "Running YCSB for $num threads"
	ssh dsl0 "cd tanuj/ycsb-jdbc-binding-0.11.0; ./run-ycsb-test.sh $num"
	echo "Finished running YCSB"

	echo "Waiting 120s for nmon to finish..."
	sleep 120

	path="./benchmarks/01.24.17.5/$num"
	mkdir -p $path
	echo "Fetching ycsb-results from dsl0"
	scp "dsl0:~/tanuj/ycsb-jdbc-binding-0.11.0/ycsb-results" $path
	"./fetch-nmon-results.sh"
	mv dsl* $path
	echo ""
done
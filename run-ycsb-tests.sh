#!/bin/bash
num_threads=( 1 5 10 15 20 25 )
for num in "${num_threads[@]}"
do
	echo "Running YCSB for $num threads"

	"./start-nmon.sh"
	ssh dsl3 "cd tanuj/ycsb-jdbc-binding-0.11.0; ./run-ycsb-test.sh $num"
	sleep 2m

	path="./benchmarks/01.23.17.2/$num"
	mkdir -p $path
	scp "dsl3:~/tanuj/ycsb-jdbc-binding-0.11.0/ycsb-results" $path
	"./fetch-nmon-results.sh"
	mv "dsl*" $path
done
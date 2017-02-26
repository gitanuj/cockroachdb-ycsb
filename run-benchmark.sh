#!/bin/bash
#
# Usage: ./run-benchmark.sh <benchmarks_dir>
# Runs a ycsb benchmark for different num of threads
# PS: Update workload file and the vars below
#

benchmarks_dir="$1"
num_threads=( 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 )
all_machines=( "dsl0" "dsl1" "dsl2" "dsl3" )
crdb_machines=( "dsl0" "dsl1" "dsl2" )
wdir="~/tanuj"
ycsb_machine="dsl3"
ycsb_wdir="~/tanuj/ycsb-jdbc-binding-0.11.0"

# start record-raft-leaders.py
echo "Starting record-raft-leaders.py on $ycsb_machine"
ssh "$ycsb_machine" "cd $ycsb_wdir; python -u cockroachdb-ycsb/record-raft-leaders.py &> raft-leaders.csv &"

for num in "${num_threads[@]}"
do
	# start nmon
	for server in "${all_machines[@]}"
	do
		echo "Starting nmon on $server"
		ssh "$server" "cd $wdir; nmon -f -s1 -c 10000"
	done

	# start ycsb
	echo "Running YCSB for $num threads"
	ssh "$ycsb_machine" "cd $ycsb_wdir; bin/ycsb run jdbc -P cockroachdb-ycsb/workload -P cockroachdb-ycsb/cockroachdb.properties -s -cp cockroachdb-ycsb/bin/postgresql-9.4.1212.jre7.jar -threads $num &> ycsb-results"
	echo "Finished running YCSB"

	path="./benchmarks/$benchmarks_dir/$num"
	mkdir -p $path

	# fetch ycsb_results
	"./fetch-using-ssh.sh" "$ycsb_machine" "$ycsb_wdir/ycsb-results" "$path"

	# fetch *.nmon
	for server in "${all_machines[@]}"
	do
		echo "Stopping nmon on $server"
		ssh "$server" "cd $wdir; kill -USR2 \$(ps -ef | grep 'nmon' | grep -v grep | awk '{ print \$2 }')"
		"./fetch-using-ssh.sh" "$server" "$wdir/*.nmon" "$path/$server"
	done

	# fetch data.dump
	for server in "${crdb_machines[@]}"
	do
		"./fetch-using-ssh.sh" "$server" "$wdir/data.dump" "$path/$server"
	done

	echo ""
done

# stop record-raft-leaders.csv
echo "Stopping record-raft-leaders.py on $ycsb_machine"
ssh "$ycsb_machine" "cd $ycsb_wdir; kill -9 \$(ps -ef | grep 'record-raft-leaders' | grep -v grep | awk '{ print \$2 }')"

# fetch raft-leaders.csv
path="./benchmarks/$benchmarks_dir"
"./fetch-using-ssh.sh" "$ycsb_machine" "$ycsb_wdir/raft-leaders.csv" "$path"

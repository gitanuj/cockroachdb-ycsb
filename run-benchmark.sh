#!/bin/bash
#
# Usage: ./run-benchmark.sh <benchmarks_dir> <workload>
# Runs a ycsb benchmark for different num of threads
# PS: Update workload file and the vars below
#

benchmarks_dir="$1"
workload="$2"

num_threads=( 20 )
all_machines=( "dsl0" "dsl1" "dsl2" "dsl3" )
crdb_machines=( "dsl0" "dsl1" "dsl2" )
wdir="~/tanuj"
ycsb_machine="dsl3"
ycsb_wdir="~/tanuj/ycsb-jdbc-binding-0.11.0"

# $1: ssh addr
# $2: remote path
# $3: local path
function fetchUsingSsh {
	ssh_addr=$1
	remote_path=$2
	local_path=$3

	echo "Fetching $remote_path from $ssh_addr"
	mkdir -p "$local_path"
	scp "$ssh_addr:$remote_path" "$local_path"
	ssh "$ssh_addr" "rm -rf $remote_path"
}

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
	ssh "$ycsb_machine" "cd $ycsb_wdir; bin/ycsb run jdbc -P cockroachdb-ycsb/$workload -P cockroachdb-ycsb/cockroachdb.properties -s -cp cockroachdb-ycsb/bin/postgresql-9.4.1212.jre7.jar -threads $num &> ycsb-results"
	echo "Finished running YCSB"

	path="./benchmarks/$benchmarks_dir/$num"
	mkdir -p "$path"

	# fetch ycsb_results
	fetchUsingSsh "$ycsb_machine" "$ycsb_wdir/ycsb-results" "$path"

	# fetch *.nmon
	for server in "${all_machines[@]}"
	do
		echo "Stopping nmon on $server"
		ssh "$server" "kill -USR2 \$(ps -ef | grep 'nmon' | grep -v grep | awk '{ print \$2 }')"
		fetchUsingSsh "$server" "$wdir/*.nmon" "$path/$server"
	done

	# fetch data.dump
	for server in "${crdb_machines[@]}"
	do
		fetchUsingSsh "$server" "$wdir/data.dump" "$path/$server"
	done

	echo ""
done

# stop record-raft-leaders.csv
echo "Stopping record-raft-leaders.py on $ycsb_machine"
ssh "$ycsb_machine" "kill -9 \$(ps -ef | grep 'record-raft-leaders' | grep -v grep | awk '{ print \$2 }')"

# fetch raft-leaders.csv
path="./benchmarks/$benchmarks_dir"
fetchUsingSsh "$ycsb_machine" "$ycsb_wdir/raft-leaders.csv" "$path"

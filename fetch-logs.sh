#!/bin/bash
servers=( "dsl0" "dsl1" "dsl2" )
for server in "${servers[@]}"
do
	echo "Fetching logs from $server..."
	rm -rf $server
	mkdir $server
	scp "$server:~/tanuj/cockroach-data/logs/cockroach.ERROR" "$server"
	scp "$server:~/tanuj/cockroach-data/logs/cockroach.WARNING" "$server"
	scp "$server:~/tanuj/cockroach-data/logs/cockroach.INFO" "$server"
	scp "$server:~/tanuj/cockroach-data/logs/*.nmon" "$server"
done

echo "Fetching logs from dsl3..."
rm -rf "dsl3"
mkdir "dsl3"
scp "dsl3:~/tanuj/ycsb-jdbc-binding-0.11.0/*.nmon" "dsl3"
scp "dsl3:~/tanuj/ycsb-jdbc-binding-0.11.0/raft-leaders.csv" "dsl3"
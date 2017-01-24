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
done
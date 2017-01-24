#!/bin/bash
#
# Fecthes and then deletes nmon results from remote machines
#
servers=( "dsl0" "dsl1" "dsl2" )
for server in "${servers[@]}"
do
	echo "Fetching nmon results from $server"
	mkdir $server
	scp "$server:~/tanuj/*.nmon" "$server"
	ssh $server "cd tanuj; rm -rf *.nmon"
done
#!/bin/bash
#
# Fecthes and then deletes nmon results from remote machines
#
servers=( "dsl0" )
for server in "${servers[@]}"
do
	echo "Fetching nmon results from $server"
	mkdir $server
	scp "$server:~/tanuj/*.nmon" "$server"
	ssh $server "cd tanuj; rm -rf *.nmon"
done
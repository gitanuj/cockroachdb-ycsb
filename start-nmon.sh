#!/bin/bash
#
# Starts nmon on remote machines
#
servers=( "dsl0" "dsl1" "dsl2" "dsl3" )
for server in "${servers[@]}"
do
	echo "Starting nmon on $server"
	ssh $server "cd tanuj; nmon -f -s1 -c 5"
done
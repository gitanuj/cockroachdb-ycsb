#!/bin/bash
#
# Starts nmon on remote machines
#
servers=( "dsl0" )
for server in "${servers[@]}"
do
	echo "Starting nmon on $server"
	ssh $server "cd tanuj; nmon -f -s1 -c 120"
done
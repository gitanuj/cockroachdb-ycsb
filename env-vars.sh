#!/bin/bash

# benchmark vars
benchmark_dir_prefix="03.04.2017.ec2minirun"
read_types=( "0" "1" )
workloads=( "uniform" )
repetitions=1
num_threads=( 1 5 15 20 25 30 35 40 45 50 55 60 65 70 75 80 )


# remote addrs
all_machines=( "c0" "c1" "c2" "c3" "c4" "y0" )
all_ips=( "128.111.44.238" "128.111.44.163" )

crdb_machines=( "c0" "c1" "c2" "c3" "c4" )
crdb_ips=( "128.111.44.238" )
crdb_internal_ips=( "128.111.44.238" )

ycsb_machine="y0"
ycsb_ip="128.111.44.163"


# below vars usually won't change
db_name="test"
crdb_port="26267"
crdb_http_port="8081"

for i in "${!crdb_ips[@]}"
do
	if [ $i == 0 ]; then
		jdbc_urls="jdbc:postgresql://${crdb_ips[$i]}:$crdb_port/$db_name"
	else
		jdbc_urls="$jdbc_urls,jdbc:postgresql://${crdb_ips[$i]}:$crdb_port/$db_name"
	fi
done

crdb_wdir="~/tanuj"
ycsb_wdir="~/tanuj"
nmon_wdir="~/tanuj"

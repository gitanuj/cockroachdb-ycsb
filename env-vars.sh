#!/bin/bash

# benchmark vars
benchmark_dir_prefix="03.04.2017.ec2minirun"
read_types=( "1" "3" )
workloads=( "uniform" )
repetitions=1
num_threads=( 1 5 15 20 25 30 35 40 45 50 55 60 65 70 75 80 )


# assumes the last addr to be ycsb_machine
all_machines=( "c0" "c1" "c2" "c3" "c4" "y0" )
all_ips=( "52.32.6.197" "35.166.212.5" "35.164.148.116" "35.165.122.221" "35.161.27.54" "50.112.51.152" )
all_internal_ips=( "172.31.16.168" "172.31.25.137" "172.31.19.199" "172.31.17.31" "172.31.16.115" "placeholder" )
len_all=${#all_machines[@]}

crdb_machines=${all_machines[@]:0:$len_all-1}
crdb_ips=${all_ips[@]:0:$len_all-1}
crdb_internal_ips=${all_internal_ips[@]:0:$len_all-1}

ycsb_machine=${all_machines[$len_all-1]}
ycsb_ip=${all_ips[$len_all-1]}


# below vars usually won't change
db_name="test"
crdb_port="26267"
crdb_http_port="8081"
num_replicas=$(($len_all-1))
lhfallback_prob=`go run lhfallback-prob.go $num_replicas`

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

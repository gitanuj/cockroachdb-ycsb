#!/bin/bash

########################
### custom variables ###
########################

benchmark_dir_prefix="03.05.2017.t2.micro"
read_types=( "0" )
workloads=( "zipfian" )
repetitions=3
num_threads=( 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 )

# Use ec2.py to generate
# all_ec2_ids=( id1 id2 id3 )
# all_names=( n1 n2 n3 )
# all_ips=( 1.1.1.1 2.2.2.2 3.3.3.3 )
# all_internal_ips=( 1.1.1.1 2.2.2.2 3.3.3.3 )

ssh_user="ubuntu"
ssh_id_file="~/.ssh/tanuj.pem"

db_name="test"
crdb_port="26267"
crdb_http_port="8081"

crdb_wdir="~/tanuj"
ycsb_wdir="~/tanuj"
nmon_wdir="~/tanuj"

#########################
### derived variables ###
#########################

all_machines=()
for ip in "${all_ips[@]}"
do
	all_machines+=("-i $ssh_id_file $ssh_user@$ip")
done
len_all=${#all_machines[@]}
crdb_names=("${all_names[@]:0:$len_all-1}")
crdb_machines=("${all_machines[@]:0:$len_all-1}")
crdb_ips=("${all_ips[@]:0:$len_all-1}")
crdb_internal_ips=("${all_internal_ips[@]:0:$len_all-1}")
ycsb_name=${all_names[$len_all-1]}
ycsb_machine=${all_machines[$len_all-1]}
ycsb_ip=${all_ips[$len_all-1]}

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

########################
### common functions ###
########################

# $1: name
# $2: ssh addr
# $3: remote path
# $4: local path
function fetchUsingSsh {
	name=$1
	ssh_addr=$2
	remote_path=$3
	local_path=$4

	echo "Fetching $remote_path from $name"
	mkdir -p "$local_path"
	scp $ssh_addr:$remote_path "$local_path"
	ssh $ssh_addr "rm -rf $remote_path"
}

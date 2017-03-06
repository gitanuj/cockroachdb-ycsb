#!/bin/bash

########################
### custom variables ###
########################

benchmark_dir_prefix="03.06.2017.dsl"
read_types=( "0" "1" "2" "3" )
workloads=( "zipfian" )
repetitions=3
num_threads=( 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 )

# Use ec2.py to generate
all_ec2_ids=()
all_names=( dsl0 dsl1 dsl2 dsl3 )
all_ips=( 128.111.44.237 128.111.44.241 128.111.44.238 128.111.44.163 )
all_internal_ips=( 128.111.44.237 128.111.44.241 128.111.44.238 128.111.44.163 )

ssh_user="migr"
ssh_id_file=""

db_name="test"
crdb_port="26267"
crdb_http_port="8081"

crdb_wdir="~/tanuj"
ycsb_wdir="~/tanuj"
nmon_wdir="~/tanuj"

#########################
### derived variables ###
#########################

machine_prefix=""
if [[ ! -z $ssh_id_file ]]; then
	machine_prefix="-i $ssh_id_file"	
fi
all_machines=()
for ip in "${all_ips[@]}"
do
	all_machines+=("$machine_prefix $ssh_user@$ip")
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
range_max_bytes=$((10*64*1024*1024))
lhfallback_prob=`go run lhfallback-prob.go $num_replicas`

pg_urls=()
for i in "${!crdb_ips[@]}"
do
	pg_urls+=("postgresql://root@${crdb_ips[$i]}:$crdb_port/$db_name?sslmode=disable")
done

jdbc_urls=()
for i in "${!crdb_ips[@]}"
do
	jdbc_urls+=("jdbc:postgresql://${crdb_ips[$i]}:$crdb_port/$db_name?loglevel=1")
done

postgresql_jar="postgresql-9.4.1212.jre7.jar"
jdbc_binding_jar="ycsb/lib/jdbc-binding-0.13.0-SNAPSHOT.jar"

################
### Commands ###
################

cmd_kill_crdb="kill -9 \$(ps -ef | grep 'cockroach' | grep -v grep | awk '{ print \$2 }')"
cmd_kill_nmon="kill -9 \$(ps -ef | grep 'nmon' | grep -v grep | awk '{ print \$2 }')"
cmd_stop_nmon="kill -USR2 \$(ps -ef | grep 'nmon' | grep -v grep | awk '{ print \$2 }')"

cmd_rm_crdb_files="rm -rf cockroach-data; rm -rf *.dump"
cmd_rm_nmon_files="rm -rf *.nmon"

cmd_setup_crdb_env_vars="export COCKROACH_READ_TYPE=$read_type; export COCKROACH_LHFALLBACK_PROB=$lhfallback_prob"
cmd_ycsb_create_table="java -cp $jdbc_binding_jar:$postgresql_jar com.yahoo.ycsb.db.JdbcDBCreateTable -P cockroachdb.properties -n usertable -p db.url='${jdbc_urls[0]}'"

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

# $1: delimiter
function joinBy {
	delimiter="$1"

	local IFS="$delimiter"
	shift
	echo "$*"
}

# $1: load or run
# $2: workload
# $3: threads
function echoYcsbCmd {
	loadOrRun="$1"
	workload="$2"
	threads="$3"

	echo "ycsb/bin/ycsb $loadOrRun jdbc -P $workload -P cockroachdb.properties -p db.url='`joinBy , ${jdbc_urls[@]}`' -s -cp $postgresql_jar -threads $threads"
}

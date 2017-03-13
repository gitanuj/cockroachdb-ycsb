#!/bin/bash

########################
### custom variables ###
########################

benchmark_dir_prefix="ec2.m3.2xl"
read_types=( 1 )
workloads=( "hotspot8007" "hotspot8008" )
repetitions=2
num_threads=( 70 )

# Use ec2.py to generate
# all_ec2_ids=()
# all_names=( dsl0 dsl1 dsl2 dsl3 )
# all_ips=( 128.111.44.237 128.111.44.241 128.111.44.238 128.111.44.163 )
# all_internal_ips=( 128.111.44.237 128.111.44.241 128.111.44.238 128.111.44.163 )

all_ec2_ids=( i-02466e55ab8c1b7a5 i-0bebcfaf81cdbb75d i-098dc4e38d29d8e2d i-065c3af2270b9054d i-0c3231eb4358eb799 i-059626e6d9fffab13 )
all_names=( c0 c1 c2 c3 c4 y0 )
all_ips=( 52.43.100.5 54.68.108.196 35.163.105.229 54.68.137.94 35.162.178.148 35.164.157.184 )
all_internal_ips=( 172.31.3.152 172.31.11.125 172.31.7.41 172.31.0.207 172.31.10.222 172.31.1.89 )

ssh_user="ubuntu"
ssh_id_file="~/.ssh/tanuj.pem"

db_name="test"
crdb_port="26267"
crdb_http_port="8081"

crdb_wdir="~"
ycsb_wdir="~"
nmon_wdir="~"

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
	jdbc_urls+=("jdbc:postgresql://${crdb_ips[$i]}:$crdb_port/$db_name")
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

function cleanup {
	echo "Cleaning up YCSB client"
	ssh $ycsb_machine "cd $ycsb_wdir; $cmd_kill_nmon; $cmd_rm_nmon_files"

	echo "Cleaning up crdb servers"
	for server in "${crdb_machines[@]}"
	do
		ssh $server "cd $crdb_wdir; $cmd_kill_crdb; $cmd_rm_crdb_files; $cmd_kill_nmon; $cmd_rm_nmon_files"
	done
}

# $1: read_type
# $2: lhfallback_prob
function setup {
	read_type=$1
	lhfallback_prob=$2

	# setup crdb servers
	echo "Setting up crdb servers"
	for i in "${!crdb_machines[@]}"
	do
		remote_cmd="cd $crdb_wdir; `echoCrdbEnvVars $read_type $lhfallback_prob`; `echoCrdbStartCmd ${crdb_internal_ips[$i]}`"
		if [ $i == 0 ]; then
			ssh ${crdb_machines[$i]} "$remote_cmd" &
		else
			ssh ${crdb_machines[$i]} "$remote_cmd --join=${crdb_internal_ips[0]}:$crdb_port" &
		fi
	done
	sleep 10

	# init db
	ssh ${crdb_machines[0]} "cd $crdb_wdir; echo 'num_replicas: $num_replicas' | ./cockroach --url='${pg_urls[0]}' zone set .default -f -"
	ssh ${crdb_machines[0]} "cd $crdb_wdir; echo 'range_max_bytes: $range_max_bytes' | ./cockroach --url='${pg_urls[0]}' zone set .default -f -"
	ssh ${crdb_machines[0]} "cd $crdb_wdir; ./cockroach sql --url='${pg_urls[0]}' --execute='create database $db_name'"
	ssh $ycsb_machine "cd $ycsb_wdir; $cmd_ycsb_create_table"
}

# $1: workload
function loadAndWarmupDb {
	workload=$1

	# load workload
	echo "Loading $workload workload"
	ssh $ycsb_machine "cd $ycsb_wdir; `echoYcsbCmd load workloads/$workload 20`"

	# warmup
	echo "Warming up using $workload workload"
	ssh $ycsb_machine "cd $ycsb_wdir; `echoYcsbCmd run workloads/$workload 20`"
	sleep 5
}

# $1: benchmark_dir
function fetchDbLogs {
	benchmark_dir=$1

	# fetch db logs
	for i in "${!crdb_machines[@]}"
	do
		fetchUsingSsh "${crdb_names[$i]}" "${crdb_machines[$i]}" "$crdb_wdir/cockroach-data/logs/*" "benchmarks/$benchmark_dir/logs/${crdb_names[$i]}"
	done
}

# $1: read type
# $2: lhfallback prob
function echoCrdbEnvVars {
	read_type=$1
	lhfallback_prob=$2

	echo "export COCKROACH_MAX_TXN_RETRIES=1000 export COCKROACH_READ_TYPE=$read_type; export COCKROACH_LHFALLBACK_PROB=$lhfallback_prob"
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

# $1: host
function echoCrdbStartCmd {
	host=$1

	echo "./cockroach start --background --insecure --host=$host --port=$crdb_port --http-port=$crdb_http_port"
}

function removeDataDump {
	for i in "${!crdb_machines[@]}"
	do
		echo "Removing *.dump from ${crdb_names[$i]}"
		ssh ${crdb_machines[$i]} "cd $crdb_wdir; rm -rf *.dump"
	done
}

# $1: workload
# $2: num of threads
function runYcsb {
	workload=$1
	num=$2

	echo "Running YCSB for $num threads"
	ssh $ycsb_machine "cd $ycsb_wdir; `echoYcsbCmd run workloads/$workload $num` &> ycsb-results"
	echo "Finished running YCSB"
}

function startNmon {
	for i in "${!all_machines[@]}"
	do
		echo "Starting nmon on ${all_names[$i]}"
		ssh ${all_machines[$i]} "cd $nmon_wdir; nmon -f -s1 -c 10000"
	done
}

# $1: path
function stopAndFetchNmonResults {
	path=$1

	for i in "${!all_machines[@]}"
	do
		echo "Stopping nmon on ${all_names[i]}"
		ssh ${all_machines[$i]} "$cmd_stop_nmon"
		fetchUsingSsh "${all_names[$i]}" "${all_machines[$i]}" "$nmon_wdir/*.nmon" "$path/${all_names[$i]}"
	done
}

# $1: path
function fetchDataDump {
	path=$1

	for i in "${!crdb_machines[@]}"
	do
		fetchUsingSsh "${crdb_names[$i]}" "${crdb_machines[$i]}" "$crdb_wdir/data.dump" "$path/${crdb_names[$i]}"
	done
}

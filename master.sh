#!/bin/bash
#
# Usage: ./master.sh <arg>
# If "clean" is supplied as arg, only cleanup is done
#

source "./common.sh"

function cleanup {
	echo "Cleaning up YCSB client"
	ssh $ycsb_machine "cd $ycsb_wdir; ./cleanup.sh"

	echo "Cleaning up crdb servers"
	for server in "${crdb_machines[@]}"
	do
		ssh $server "cd $crdb_wdir; ./cleanup.sh"
	done
}

# $1: read_type
# $2: workload
# $3: count
function run {
	read_type=$1
	workload=$2
	count=$3

	printf "\n\n\n"
	echo "!!!RUN STARTED [read_type: $read_type, workload: $workload, count: $count]"

	benchmark_dir="$benchmark_dir_prefix.$read_type.$workload.$count"

	# setup crdb servers
	echo "Setting up crdb servers"
	for i in "${!crdb_machines[@]}"
	do
		remote_cmd="cd $crdb_wdir; export COCKROACH_READ_TYPE=$read_type; export COCKROACH_LHFALLBACK_PROB=$lhfallback_prob; ./cockroach start --background --insecure --host=${crdb_internal_ips[i]} --port=$crdb_port --http-port=$crdb_http_port"
		if [ $i == 0 ]; then
			ssh ${crdb_machines[$i]} "$remote_cmd" &
		else
			ssh ${crdb_machines[$i]} "$remote_cmd --join=${crdb_internal_ips[0]}:$crdb_port" &
		fi
	done
	sleep 10

	# init db
	echo "num_replicas: $num_replicas" | ./cockroach --url="postgresql://root@${crdb_ips[0]}:$crdb_port?sslmode=disable" zone set .default -f -
	echo "range_max_bytes: $range_max_bytes" | ./cockroach --url="postgresql://root@${crdb_ips[0]}:$crdb_port?sslmode=disable" zone set .default -f -
	./cockroach sql --url="postgresql://root@${crdb_ips[0]}:$crdb_port?sslmode=disable" --execute="create database $db_name"
	java -cp ycsb-client-files/lib/jdbc-binding-0.12.0.jar:ycsb-client-files/bin/postgresql-9.4.1212.jre7.jar com.yahoo.ycsb.db.JdbcDBCreateTable -P ycsb-client-files/cockroachdb.properties -n usertable -p db.url=jdbc:postgresql://${crdb_ips[0]}:$crdb_port/$db_name

	# load workload
	echo "Loading $workload workload"
	ssh $ycsb_machine "cd $ycsb_wdir; bin/ycsb load jdbc -P workloads/$workload -P cockroachdb.properties -p db.url=$jdbc_urls -s -cp bin/postgresql-9.4.1212.jre7.jar -threads 20"

	# warmup
	echo "Warming up using $workload workload"
	ssh $ycsb_machine "cd $ycsb_wdir; bin/ycsb run jdbc -P workloads/$workload -P cockroachdb.properties -p db.url=$jdbc_urls -s -cp bin/postgresql-9.4.1212.jre7.jar -threads 20"
	sleep 5

	# run benchmark
	"./run-benchmark.sh" "$benchmark_dir" "$workload"

	# fetch db logs
	for i in "${!crdb_machines[@]}"
	do
		fetchUsingSsh "${crdb_names[$i]}" "${crdb_machines[$i]}" "$crdb_wdir/cockroach-data/logs/*" "$benchmark_dir/logs/${crdb_names[$i]}"
	done

	echo "RUN FINISHED!!!"
	printf "\n\n\n"
}

if [[ $# == 1 ]] && [[ $1 == "clean" ]]; then
	cleanup
	exit 0
fi

for read_type in "${read_types[@]}"
do
	for workload in "${workloads[@]}"
	do
		for (( c=0; c<$repetitions; c++ ))
		do
			cleanup
			run $read_type $workload $c
		done
	done
done
cleanup

echo "Terminating EC2 instances..."
python "ec2.py" "stop" "${all_ec2_ids[@]}"

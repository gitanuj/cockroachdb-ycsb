#
# Usage ./kill-all.sh
#

all_machines=( "dsl0" "dsl1" "dsl2" "dsl3" )
crdb_machines=( "dsl0" "dsl1" "dsl2" )
wdir="~/tanuj"
ycsb_machine="dsl3"
ycsb_wdir="~/tanuj/ycsb-jdbc-binding-0.11.0"

# cleanup *.nmon
for server in "${all_machines[@]}"
do
	echo "Cleaning up *.nmon on $server"
	ssh "$server" "kill -USR2 \$(ps -ef | grep 'nmon' | grep -v grep | awk '{ print \$2 }'); cd $wdir; rm -rf *.nmon"
done

# cleanup data.dump
for server in "${crdb_machines[@]}"
do
	echo "Cleaning up data.dump on $server"
	ssh "$server" "cd $wdir; rm -rf data.dump"
done

# cleanup raft-leaders.csv
echo "Cleaning up raft-leaders.csv on $ycsb_machine"
ssh "$ycsb_machine" "kill -9 \$(ps -ef | grep 'record-raft-leaders' | grep -v grep | awk '{ print \$2 }'); cd $wdir; rm -rf raft-leaders.csv"
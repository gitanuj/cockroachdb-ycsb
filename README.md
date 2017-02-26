# Steps
1. ./cleanup.sh every server
2. ./startup.sh crdb servers
3. ./init-test-db.sh on local machine
4. load YCSB workload
4. ./run-ycsb-tests.sh on local machine

# Run YCSB on cockroachdb

### Load a workload
```
bin/ycsb load jdbc -P cockroachdb-ycsb/workload -P cockroachdb-ycsb/cockroachdb.properties -s -cp cockroachdb-ycsb/bin/postgresql-9.4.1212.jre7.jar -threads 10
```

### Run a workload
```
bin/ycsb run jdbc -P cockroachdb-ycsb/workload -P cockroachdb-ycsb/cockroachdb.properties -s -cp cockroachdb-ycsb/bin/postgresql-9.4.1212.jre7.jar -threads 1
```

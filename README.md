# Run YCSB on cockroachdb

### Load a workload
```
bin/ycsb load jdbc -P cockroachdb-ycsb/workload -P cockroachdb-ycsb/config/cockroachdb.properties -s -cp cockroachdb-ycsb/config/postgresql-9.4.1212.jre7.jar -threads 10
```

### Run a workload
```
bin/ycsb run jdbc -P cockroachdb-ycsb/workload -P cockroachdb-ycsb/config/cockroachdb.properties -s -cp cockroachdb-ycsb/config/postgresql-9.4.1212.jre7.jar -threads 1
```

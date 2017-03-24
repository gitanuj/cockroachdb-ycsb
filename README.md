# Benchmarking Read Scalability in Raft

This repo contains all the scripts to run YCSB benchmarks on cockroachDB cluster.
* `common.sh`, `run-benchmark.sh` and `master.sh` are the scripts responsible to setting up machines and running benchamarks.
* `ec2.py` is a helper script to start/stop ec2 instances.
* `lhfallback-prob.go` is a helper script to generate `x` for lease-holder reads ratio.
* `plot.py` and `extract-results.py` are data extraction and plot generation scripts.

## Setup machines
### Cockroach Server
1. Install `nmon`
2. Copy over `cockroach` binary

### YCSB Client
1. Install `python`, `java` and `nmon`
2. Copy over contents from `ycsb-client-files`

### Master machine
1. Copy over `common.sh`, `master.sh` and `run-benchmark.sh`
2. (Optional) Copy over `ec2.py` and `lhfallback-prob.go`

## Steps to run
1. Update vars in `common.sh`
2. Execute `master.sh`

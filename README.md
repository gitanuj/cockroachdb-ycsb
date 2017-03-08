# Setup
### Cockroach Server
1. Install `nmon`
2. Copy over `cockroach` binary

### YCSB Client
1. Install `python`, `java` and `nmon`
2. Copy over contents from `ycsb-client-files`

### Master machine
1. Copy over `common.sh`, `master.sh` and `run-benchmark.sh`
2. (Optional) Copy over `ec2.py` and `lhfallback-prob.go`

# Steps
1. Update vars in `common.sh`
2. Execute `master.sh`

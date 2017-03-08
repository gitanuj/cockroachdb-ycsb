# Setup
### Cockroach Server (ubuntu 14.04 or 16.04)
1. Install `nmon`
2. Copy over `cockroach` binary

### YCSB Client (ubuntu 14.04 or 16.04)
1. Install `python`, `java` and `nmon`
2. Copy over contents from `ycsb-client-files`

### Master machine (macOS 10.12)
1. Install `python` (for extract scripts)
2. Install `go` (for lhfallback-prob.go script)

# Steps
1. Update vars in `common.sh`
2. Execute `master.sh`

# Setup
### Cockroach Server (ubuntu 14.04 or 16.04)
1. Install `nmon`
2. Copy over `cockroach` binary
3. Copy over contents from `cockroach-server-files`

### YCSB Client (ubuntu 14.04 or 16.04)
1. Install `python`, `java` and `nmon`
2. Copy over contents from `ycsb-client-files`

### Master machine (macOS 10.12)
1. Install `python`, `java` and `go`
2. Copy over `cockroach` binary

# Steps (on master machine)
1. Update vars in `env-vars.sh`
2. Execute `master.sh`

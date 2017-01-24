#!/bin/bash
scp "dsl3:~/tanuj/ycsb-jdbc-binding-0.11.0/raft-leaders.csv" .
ssh "dsl3" "rm -f tanuj/ycsb-jdbc-binding-0.11.0/raft-leaders.csv"
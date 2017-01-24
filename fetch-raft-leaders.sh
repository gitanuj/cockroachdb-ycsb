#!/bin/bash
scp "dsl0:~/tanuj/ycsb-jdbc-binding-0.11.0/raft-leaders.csv" .
ssh "dsl0" "rm -f tanuj/ycsb-jdbc-binding-0.11.0/raft-leaders.csv"
#!/bin/bash
kill -9 $(ps -ef | grep "nmon" | grep -v grep | awk '{ print $2 }')
rm -rf ~/tanuj/*.nmon
kill -9 $(ps -ef | grep "record-raft-leaders" | grep -v grep | awk '{ print $2 }')
rm -rf ~/tanuj/ycsb-jdbc-binding-0.11.0/raft-leaders.csv
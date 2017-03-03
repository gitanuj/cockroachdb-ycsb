#!/bin/bash
kill -9 $(ps -ef | grep "nmon" | grep -v grep | awk '{ print $2 }')
rm -rf *.nmon
kill -9 $(ps -ef | grep "record-raft-leaders" | grep -v grep | awk '{ print $2 }')
rm -rf *.csv

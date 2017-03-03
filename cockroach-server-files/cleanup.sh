#!/bin/bash
kill -9 $(ps -ef | grep "cockroach" | grep -v grep | awk '{ print $2 }')
rm -rf cockroach-data
rm -rf *.dump

kill -USR2 $(ps -ef | grep "nmon" | grep -v grep | awk '{ print $2 }')
rm -rf *.nmon

#!/bin/bash
#
# ./fetch-using-ssh.sh <ssh_addr> <remote_path> <local_path>
# Fetches and then deletes a file from remote machine
#
ssh_addr=$1
remote_path=$2
local_path=$3
echo "Fetching $remote_path from $ssh_addr"
mkdir -p $local_path
scp "$ssh_addr:$remote_path" "$local_path"
ssh "$ssh_addr" "rm -rf $remote_path"

#!/bin/bash

if [ "$#" -ne "1" ] ; then
    echo "usage: get_server_key <ip>"
    exit 2
fi

server_ip=$1
cat ./shell/master/info/server.list |grep -E ":\s*"${server_ip}"\s*" |awk -F: '{gsub(/[ \t]*/,"",$1);print $1}'
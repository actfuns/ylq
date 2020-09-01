#!/bin/bash

if [ "$#" -ne "1" ] ; then
    echo "usage: get_ip <server_key>"
    exit 2
fi

server_key=$1
cat ./shell/master/info/server.list |grep -E "^\s*"${server_key}"\s*:"
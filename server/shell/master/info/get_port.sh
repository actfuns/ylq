#!/bin/bash

if [ "$#" -ne "1" ] ; then
    echo "usage: get_port <server_key>"
    exit 2
fi

SERVER_KEY=$1
SERVER_TYPE=`./shell/master/info/get_server_type.sh ${SERVER_KEY}`
if [ -z "$SERVER_TYPE" ]; then
    echo "get_port err server_key" ${SERVER_KEY}
    exit 3
fi
./shell/master/info/get_port_by_type.sh ${SERVER_TYPE}

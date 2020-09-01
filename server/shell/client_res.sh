#!/bin/bash
if [ $# -lt 1 ] ; then
    echo "usage: client_res <server_type>"
    exit 2
fi

SERVER_TYPE=$1

PORT=`./shell/master/info/get_port_by_type.sh ${SERVER_TYPE}`
if [ -z "$PORT" ]; then
    echo "client_res wrong server port "${SERVER_TYPE}
    exit 3
fi
echo "client_res"|nc -q 1 127.0.0.1 ${PORT}
echo "client_res finish "${SERVER_TYPE} ${PORT}

#!/bin/bash
if [ $# -lt 2 ] ; then
    echo "usage: update_fix <server_type> <func_name>"
    exit 2
fi

SERVER_TYPE=$1
FUNC_NAME=$2

PORT=`./shell/master/info/get_port_by_type.sh ${SERVER_TYPE}`
if [ -z "$PORT" ]; then
    echo "update_fix wrong server port "${SERVER_TYPE}
    exit 3
fi
echo "update_fix ${FUNC_NAME}"|nc -q 1 127.0.0.1 ${PORT}
echo "update_fix finish "${SERVER_TYPE} ${PORT} ${FUNC_NAME}

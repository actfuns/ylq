#!/bin/bash
if [ $# -lt 2 ] ; then
    echo "usage: update_code <server_type> [filename...] [protoflag]"
    exit 2
fi

SERVER_TYPE=$1
FILE_NAME=$2
for i in $( seq 3 `expr $# - 1` )
do
    FILE_NAME=${FILE_NAME}","${!i}
done

PROTO_FLAG="0"
if [ $# -gt 2 ] ; then
    if [ ${!#} -ge 0 ] 2>/dev/null ; then
        PROTO_FLAG=${!#}
    else
        FILE_NAME=${FILE_NAME}","${!#}
    fi
fi

PORT=`./shell/master/info/get_port_by_type.sh ${SERVER_TYPE}`
if [ -z "$PORT" ]; then
    echo "update_code wrong server port "${SERVER_TYPE}
    exit 3
fi
echo "update_code ${FILE_NAME} ${PROTO_FLAG}"|nc -q 1 127.0.0.1 ${PORT}
echo "update_code finish "${SERVER_TYPE} ${PORT} ${FILE_NAME} ${PROTO_FLAG}

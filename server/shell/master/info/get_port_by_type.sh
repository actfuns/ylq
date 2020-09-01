#!/bin/bash

if [ "$#" -ne "1" ] ; then
    echo "usage: get_port <server_type>"
    exit 2
fi

SERVER_TYPE=$1
if [ ${SERVER_TYPE} == "cs" ] ; then
    echo "10002"
elif [ ${SERVER_TYPE} == "bs" ] ; then
    echo "20002"
elif [ ${SERVER_TYPE} == "gs" ] ; then
    echo "7002"
else
    echo "get_port_by_type error "${SERVER_TYPE}
    exit 3
fi
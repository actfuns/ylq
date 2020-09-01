#!/bin/bash

if [ "$#" -ne "1" ] ; then
    echo "usage: get_port <server_key>"
    exit 2
fi

SERVER_KEY=$1
SERVER_TYPE=`echo ${SERVER_KEY} | awk '{ match($0,"_[a-z]+") ; print substr($0,RSTART+1,RLENGTH-1)}'`
echo ${SERVER_TYPE}

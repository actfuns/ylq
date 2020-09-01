#!/bin/bash
if [ "$#" -ne "4" ] ; then
    echo "usage: pressure_execute <hostname> <script> <num>"
    exit 2
fi

HOST_NAME=$1
SCRIPT_NAME=$2
PLAYER_NUM=$3
PORT_NUM=$4

ssh $HOST_NAME "cd waifu/tools/robot; ./bench.sh -a 192.168.8.136 -s $SCRIPT_NAME -c $PLAYER_NUM -f $HOST_NAME -p $PORT_NUM"

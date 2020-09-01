#!/bin/bash
if [ $# -lt 1 ] ; then
    echo "usage: gs_close <server_list or server_key> [notify] [flag]"
    exit 2
fi

./shell/master/distribute.py remote $1 ./shell/gs_close.sh "${@:2}"

#!/bin/bash
if [ $# -lt 1 ] ; then
    echo "usage: gs_run <server_list or server_key> [flag]"
    exit 2
fi

./shell/master/distribute.py remote $1 ./shell/gs_run.sh "${@:2}"

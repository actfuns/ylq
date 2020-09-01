#!/bin/bash
if [ $# -lt 1 ] ; then
    echo "usage: update_res <server_list or server_key> [notify] [flag]"
    exit 2
fi

./shell/master/distribute.py remote $1 ./shell/update_res.sh "${@:2}"

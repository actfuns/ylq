#!/bin/bash
if [ $# -lt 1 ] ; then
    echo "usage: update_fix <server_list or server_key> [func_name]"
    exit 2
fi

./shell/master/distribute.py remote $1 ./shell/update_fix.sh "${@:2}"

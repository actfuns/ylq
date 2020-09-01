#!/bin/bash
if [ $# -lt 1 ] ; then
    echo "usage: update_code <server_list or server_key> [filename...] [protoflag]"
    exit 2
fi

./shell/master/distribute.py remote $1 ./shell/update_code.sh "${@:2}"

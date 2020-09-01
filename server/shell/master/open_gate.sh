#!/bin/bash
if [ $# -lt 1 ] ; then
    echo "usage: open_gate <server_list or server_key> [op] [flag]"
    exit 2
fi

./shell/master/distribute.py remote $1 ./shell/open_gate.sh "${@:2}"

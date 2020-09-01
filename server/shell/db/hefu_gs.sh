#!/bin/bash
if [ $# -lt 2 ] ; then
    echo "usage: hefu_gs <server_key dir> <server_key dir>"
    exit 2
fi

python ./shell/db/hefu_gs.py "$1" "$2"
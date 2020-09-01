#!/bin/bash
if [ $# -lt 2 ] ; then
    echo "usage: hefu_cs <server_list or server_key> <server_list or server_key>"
    exit 2
fi

is_known_server=`./shell/master/info/is_known_server_key.sh $1`
if [ "$is_known_server" = "" ] ; then
    echo "usage args1 err"
    exit 2
fi

is_known_server=`./shell/master/info/is_known_server_key.sh $2`
if [ "$is_known_server" = "" ] ; then
    echo "usage args2 err"
    exit 2
fi

python ./shell/db/hefu_cs_backup.py "$1"
python ./shell/db/hefu_cs.py "$1" "$2"
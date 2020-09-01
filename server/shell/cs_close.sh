#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_cs
fi

ps aux|grep 'skynet' | grep $FLAG |grep -v 'grep'
if [ $? -eq 0 ] ; then
    echo 'closing cs'
    echo 'close_cs' | nc 127.0.0.1 10002
    sleep 6
fi

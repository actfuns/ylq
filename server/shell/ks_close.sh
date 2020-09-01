#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_ks
fi

ps aux|grep 'skynet' | grep $FLAG |grep -v 'grep'
if [ $? -eq 0 ] ; then
    echo 'closing ks'
    echo 'close_ks' | nc 127.0.0.1 20012
    sleep 6
fi

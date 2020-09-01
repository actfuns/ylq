#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_bs
fi

ps aux|grep 'skynet' | grep $FLAG |grep -v 'grep'
if [ $? -eq 0 ] ; then
    echo 'closing bs'
    echo 'close_bs' | nc 127.0.0.1 20002
    sleep 6
fi

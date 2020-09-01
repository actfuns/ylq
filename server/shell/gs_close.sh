#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_gs
fi

ps aux|grep 'skynet' | grep $FLAG |grep -v 'grep' 1>/dev/null
if [ $? -eq 0 ] ; then
    echo 'closing gs'
    echo 'close_gs' | nc 127.0.0.1 7002
    sleep 12
fi

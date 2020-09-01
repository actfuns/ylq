#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_cs
fi

ps aux|grep 'skynet'|grep $FLAG|grep -v 'grep'|awk '{print $2}'|xargs kill -9

#!/bin/bash

now_path=`pwd`
now_path=${now_path//trunk.*/trunk}'/tools/robot'
echo $now_path

script=$1
if [ ! $script ] ; then
    script=test
fi
script='./client_scripts/'$script'.lua'
#echo $script
#exit 0

echo 1, `pwd`
cd $now_path
echo 2, `pwd`
./client.sh -s $script

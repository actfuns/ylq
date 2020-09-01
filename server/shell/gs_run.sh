#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_gs
fi

LOG_BAK_ROUT="bak"
if [ -f ./log/gs.log ]; then
    echo 'backup log'
    if [ ! -d ./log/$LOG_BAK_ROUT ]; then
        mkdir ./log/$LOG_BAK_ROUT
    fi
    dict=`pwd`
    cd ./log/$LOG_BAK_ROUT
    ls -t | awk '{if(NR>=10){print $0}}' | xargs rm -f
    cd $dict
    mv ./log/gs.log ./log/$LOG_BAK_ROUT/gs_`date +%Y%m%d-%H%M%S`.log
fi

# rm -Rf ./log/gs.log
echo 'checking local'
./shell/check_lua.sh

echo 'starting server'
nohup ./build/skynet ./config/gs_config.lua $FLAG > log/gs.out 2>&1 &

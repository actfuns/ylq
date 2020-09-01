#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_bs
fi

echo 'clear log'
rm -Rf ./log/bs.log
echo 'checking local'
./shell/check_lua.sh

echo 'starting server'
nohup ./build/skynet ./config/bs_config.lua $FLAG > log/bs.out 2>&1 &

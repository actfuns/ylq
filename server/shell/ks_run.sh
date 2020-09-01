#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_ks
fi

echo 'clear log'
rm -Rf ./log/ks.log
echo 'checking local'
./shell/check_lua.sh

echo 'starting server'
nohup ./build/skynet ./config/ks_config.lua $FLAG > log/ks.out 2>&1 &

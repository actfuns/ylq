#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_cs
fi

echo 'clear log'
rm -Rf ./log/cs.log
echo 'checking local'
./shell/check_lua.sh
echo 'starting server'

python ./shell/gen_show_id.py

nohup ./build/skynet ./config/cs_config.lua $FLAG > log/cs.out 2>&1 &

#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_gs
fi

./shell/gs_kill.sh $FLAG
./shell/gs_run.sh $FLAG

sleep 12
./shell/open_gate.sh 2 $FLAG

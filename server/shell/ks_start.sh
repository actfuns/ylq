#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_ks
fi

./shell/ks_kill.sh $FLAG
./shell/ks_run.sh $FLAG

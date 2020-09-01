#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_bs
fi

./shell/bs_kill.sh $FLAG
./shell/bs_run.sh $FLAG

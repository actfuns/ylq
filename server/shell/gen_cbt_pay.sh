#!/bin/bash

if [ -f "./shell/cbt_pay.db" ]; then
    echo "exist cbt_pay.db, import to mongodb, waiting..."
    content=`mongo -u root -p bCrfAptbKeW8YoZU --authenticationDatabase admin game --eval 'db.cbt_pay.find().count()'`
    IFS='
'
    arr=($content)
    if [ ${arr[${#arr[@]} - 1]} -eq 0 ] ; then
        mongoimport -u root -p bCrfAptbKeW8YoZU --authenticationDatabase admin -d game -c cbt_pay --drop ./shell/cbt_pay.db
        echo "cbt_pay.db import finish"
    else
        echo "cbt_pay is exist, pass"
    fi
else
    echo "unexist cbt_pay.db, please make sure it is correct ..."
fi
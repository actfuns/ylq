#!/bin/bash

FLAG=$1
if [ ! $FLAG ] || [ $FLAG != "dropall" ] ; then
    echo "[警告]执行此指令将删除以下所有数据库,若确定执行,请执行./shell/drop_all_db.sh dropall"
    mongo -u root -p bCrfAptbKeW8YoZU --authenticationDatabase admin --quiet --eval "load('./shell/dropdbs.js'); GetDropDBs();"
    exit
fi

mongo -u root -p bCrfAptbKeW8YoZU --authenticationDatabase admin --quiet --eval "load('./shell/dropdbs.js'); DropDBs();"

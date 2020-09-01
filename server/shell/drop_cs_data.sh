#!/bin/bash

SERVER_KEY=$1

if [ ! ${SERVER_KEY} ]; then
    echo "usage: drop_cs_data <serverkey>"
    exit 2
fi

FLAG=$2
if [ ! $FLAG ] || [ $FLAG != "dropall" ] ; then
    echo "[警告]执行此指令将删除CS数据库game.roleinfo,game.requestpay,game.pay中所有关于"${SERVER_KEY}"的数据！！确定执行,请执行./shell/drop_cs_data.sh "${SERVER_KEY}" dropall"
    exit 3
fi

mongo -u root -p YXTxsaj22WSJ7wTG --authenticationDatabase admin game --eval 'db.roleinfo.remove({"server":"'${SERVER_KEY}'"})'
mongo -u root -p YXTxsaj22WSJ7wTG --authenticationDatabase admin game --eval 'db.requestpay.remove({"serverId":"'${SERVER_KEY}'"})'
mongo -u root -p YXTxsaj22WSJ7wTG --authenticationDatabase admin game --eval 'db.pay.remove({"serverkey":"'${SERVER_KEY}'"})'
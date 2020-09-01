#!/bin/bash
# echo $1
if [ $# -lt 3 ] ; then
    echo "usage: pull_data args error"
    exit 2
fi

SERVER_KEY=$1
CLUSTER=${SERVER_KEY%_*}
output=`./shell/master/distribute.py remote $CLUSTER ./shell/pull_data.sh "$@"`

BS_SERVER_KEY=$CLUSTER"_bs"
BS_IP=`./shell/master/info/get_ip.sh ${BS_SERVER_KEY}`
scp -P 932 cilu@${BS_IP}:/home/cilu/${BS_SERVER_KEY}/pulldata/$3.json .

ssh -p 932 cilu@${BS_IP} "rm /home/cilu/${BS_SERVER_KEY}/pulldata/${3}.json"
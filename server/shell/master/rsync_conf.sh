#!/bin/bash
if [ $# -lt 1 ] ; then
    echo "usage: sync_code <server_key> <pack_name>"
    exit 2
fi

SERVER_KEY=$1
PACK_NAME=$2
SERVER_IP=`./shell/master/info/get_ip.sh ${SERVER_KEY}`

if [ -z "$SERVER_IP" ]; then
    echo "sync_code wrong server key"
    exit 3
fi

rsync -avzc --stats\
        --delete\
        --exclude 'log'\
        --exclude 'config/*.lua'\
        -e 'ssh -p 932' $PACK_NAME/ cilu@$SERVER_IP:~/${SERVER_KEY}/

ssh -fnp 932 cilu@${SERVER_IP} "
cd ${SERVER_KEY};
./shell/gen_config.sh ${SERVER_KEY};
"
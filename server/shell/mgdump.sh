#!/bin/bash

USERNAME="hellowork"
MONGO_DATABASE="game"
APP_NAME="n1"
MONGO_HOST="127.0.0.1"
MONGO_PORT="27017"
TIMESTAMP=`date +%F-%H%M`
MONGODUMP_PATH="/usr/bin/mongodump"
BACKUPS_DIR="/home/$USERNAME/backups/$APP_NAME"
BACKUP_NAME="$APP_NAME-$TIMESTAMP"
# mongo -u root -p bCrfAptbKeW8YoZU --authenticationDatabase admin --eval "printjson(db.fsyncLock())"
# $MONGODUMP_PATH -h $MONGO_HOST:$MONGO_PORT -d $MONGO_DATABASE
$MONGODUMP_PATH -d $MONGO_DATABASE
# mongo -u root -p bCrfAptbKeW8YoZU --authenticationDatabase admin --eval "printjson(db.fsyncUnlock())"
mkdir -p $BACKUPS_DIR
mv dump $BACKUP_NAME
rm -rf $BACKUPS_DIR/**
tar -zcvf $BACKUPS_DIR/$BACKUP_NAME.tgz $BACKUP_NAME
rm -rf $BACKUP_NAME

# -*-  coding: utf-8  -*-
from pymongo import MongoClient


def DoScript():
    conn = MongoClient("mongodb://root:bCrfAptbKeW8YoZU@127.0.0.1:27017/")
    db = conn.backend
    mContent = {"ip":"106.75.134.210","id":"qqtest_gs10001","name":"月见岛","isNewServer":1,"serverIndex":10001}
    db.gameserver.insert(mContent)
    mContent = {"id":10001,"name":"月见岛"}
    db.servergroup.insert(mContent)

def AddServer():
    conn = MongoClient("mongodb://root:bCrfAptbKeW8YoZU@127.0.0.1:27017/")
    db = conn.game
    collection = db.global
    sServerKey = "pro_gs10001"
    mAddServer = {
        "id":sServerKey,
        "serverIndex":10001,
        "isNewServer":1,
        "openAtStr":"",
        "openTime":"",
    }
    for mData in collection.find({"name":"svrsetter"}):
        mServer = mData["srv"]
        mServer[sServerKey] = mAddServer
        db.global.update({"name":"svrsetter"},{"$set":{"data":mData}})


if __name__ == "__main__":
    DoScript()


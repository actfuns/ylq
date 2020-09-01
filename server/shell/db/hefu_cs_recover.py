#!/usr/bin/python
# -*-  coding: utf-8  -*-
from pymongo import MongoClient
import sys
import time
import os

def ReadFile(sFile):
    f = open(sFile,"r")
    try:
        fileContent = f.read()
        return fileContent
    finally:
        f.close()

def GetBackCSInfo():
    sPath = os.environ['HOME'] + "/csback.txt"
    sContent = ReadFile(sPath)
    lPidInfo = sContent.split(",")
    mPid = {}
    for _,sInfo in enumerate(lPidInfo):
        iPid,iFromServer = sInfo.split(":")
        mPid[iPid] = iFromServer
    return mPid

def CS_RecoverServer():
    mPid = GetBackCSInfo()
    conn = MongoClient("mongodb://root:bCrfAptbKeW8YoZU@127.0.0.1:27017/")
    db = conn["game"]
    coll = db["roleinfo"]
    for data in coll.find():
        iPid = data["pid"]
        if mPid.has_key(iPid):
            iFromServer = mPid[iPid]
            db["roleinfo"].update({"pid":iPid},{"$set":{"server":iFromServer}})

if __name__ == "__main__":
    CS_RecoverServer()
# -*-  coding: utf-8  -*-
from pymongo import MongoClient
import sys
import os
import time

def CS_TestStartHefu():
    conn = MongoClient("mongodb://root:bCrfAptbKeW8YoZU@127.0.0.1:27017/")
    db = conn["datacenter"]
    iPid = 10000
    iNow = time.time()
    print(iNow)
    for i in range(100):
        iNo = 10001+i
        sServerKey = "dev_gs%d"%(iNo)
        for i in range(100000):
            iPid = iPid + 1
            mData = {
                "pid" : iPid,
                "grade" : 1,
                "platfrom" : 1,
                "name" : "DEBUG%s"%(iPid),
                "channel" : 0,
                "account" : iPid,
                "server" : sServerKey,
            }
            db.roleinfo.insert(mData)
    print(time.time(),time.time()-iNow)

if __name__ == "__main__":
    CS_TestStartHefu()
#!/usr/bin/python
# -*-  coding: utf-8  -*-
import sys
from pymongo import MongoClient

def WriteFile(sFile,data):
    f = open(sFile,"w")
    try:
        f.write(data)
    finally:
        f.close()

def BackUpHefu(from_server):
    conn = MongoClient("mongodb://root:bCrfAptbKeW8YoZU@127.0.0.1:27017/")
    db = conn["game"]
    coll = db["roleinfo"]
    lBackInfo = []
    for data in coll.find():
        if data["server"] == from_server:
            sInfo = "%s:%s"%(data["pid"],from_server)
            lBackInfo.append(sInfo)
    sBack = ",".join(lBackInfo)
    sPath = os.environ['HOME'] + "/csback.txt"
    if not os.path.exists(sPath):
        os.mknod(sPath)
    WriteFile(sPath,sBack)

if __name__ == "__main__":
    if len(sys.argv) == 2:
        from_server = sys.argv[1]
        BackUpHefu(from_server)
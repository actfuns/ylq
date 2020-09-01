# -*-  coding: utf-8  -*-
from pymongo import MongoClient
import sys
import time

def CS_StartHefu(from_server,to_server):
    conn = MongoClient("mongodb://root:bCrfAptbKeW8YoZU@127.0.0.1:27017/")
    db = conn["game"]
    coll = db["roleinfo"]
    for data in coll.find():
        if data["server"] == from_server:
            iPid = data["pid"]
            db["roleinfo"].update({"pid":iPid},{"$set":{"server":to_server}})

if __name__ == "__main__":
    if len(sys.argv) == 3:
        from_server = sys.argv[1]
        to_server = sys.argv[2]
        CS_StartHefu(from_server,to_server)
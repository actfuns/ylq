#!/usr/bin/python
# -*-  coding: utf-8  -*-
import sys
import os
import time
import bson
import json
import shutil
import hefu_global
import hefu_rank
import hefu_world

dbpath = os.path.abspath(os.curdir) + "/shell/"
sys.path.append(dbpath)
import pyutils.dbdata as db

def GetMainHomeDir():
    return os.environ['HOME']

def DealNewDir(dir):
    if os.path.isdir(dir):
        ls = os.listdir(dir)
        for i in ls:
            path = os.path.join(dir,i)
            os.remove(path)
        return
    os.mkdir(dir)

def CopyMetaJsonFile(from_dir,to_dir,new_dir):
    lTables = ["global","rank","world","achieve","house","picture","image","offline","org","partner","player","warfilm"]
    for sTable in lTables:
        from_file = "%s/%s.metadata.json"%(to_dir,sTable)
        new_file = "%s/%s.metadata.json"%(new_dir,sTable)
        if os.path.exists(from_file):
            shutil.copyfile(from_file,new_file)
        else:
            from_file = "%s/%s.metadata.json"%(from_dir,sTable)
            if not os.path.exists(from_file):
                print("CopyMetaJsonFile err:%s"%(sTable))
                return
            shutil.copyfile(from_file,new_file)

def ReadFile(sFile):
    f = open(sFile,"r")
    try:
        fileContent = f.read()
        resBson = bson.decode_all(fileContent)
        return resBson
    finally:
        f.close()

def WriteFile(sFile,data):
    f = open(sFile,"w")
    try:
        f.write(data)
    finally:
        f.close()

def GS_StartHefu(from_server,to_server):
    main_dir = GetMainHomeDir()
    from_dir = "%s/mergedb/%s"%(main_dir,from_server)
    to_dir = "%s/mergedb/%s"%(main_dir,to_server)
    new_dir = "%s/mergedb/newdb"%(main_dir)
    DealNewDir(new_dir)
    CopyMetaJsonFile(from_dir,to_dir,new_dir)

    lTables = ["global","rank","world"]
    for sTable in lTables:
        sFromFile = "%s/%s.bson"%(from_dir,sTable)
        sDestFile = "%s/%s.bson"%(to_dir,sTable)
        sNewFile = "%s/%s.bson"%(new_dir,sTable)
        print("-----------hefu,start:%s----------"%(sTable))
        if not os.path.exists(sFromFile):
            os.mknod(sFromFile)
        if not os.path.exists(sDestFile):
            os.mknod(sDestFile)
        mFromRes = ReadFile(sFromFile)
        mDestRes = ReadFile(sDestFile)
        
        if sTable == "global" :
            mDestRes = hefu_global.StartDealGlobal(mFromRes,mDestRes)
        elif sTable == "rank" :
            mDestRes = hefu_rank.StartDealRank(mFromRes,mDestRes)
        elif sTable == "world":
            hefu_world.StartDealWorld(mFromRes,mDestRes)

        if not os.path.exists(sNewFile):
            os.mknod(sNewFile)
        fp = open(sNewFile,"wb+")
        for sKey,mData in enumerate(mDestRes):
            mNewData = db.BeforeSave(mData)
            data = bson.BSON.encode(mNewData)
            fp.write(data)
        fp.close()

    lTables = ["achieve","house","picture","image","offline","org","partner","player","warfilm"]
    for sTable in lTables:
        sFromFile = "%s/%s.bson"%(from_dir,sTable)
        sDestFile = "%s/%s.bson"%(to_dir,sTable)
        sNewFile = "%s/%s.bson"%(new_dir,sTable)
        print("-----------hefu,start:%s----------"%(sTable))
        if not os.path.exists(sFromFile):
            os.mknod(sFromFile)
        if not os.path.exists(sDestFile):
            os.mknod(sDestFile)
        mFromRes = ReadFile(sFromFile)
        mDestRes = ReadFile(sDestFile)
        for mFromData in mFromRes:
            mDestRes.append(mFromData)

        if not os.path.exists(sNewFile):
            os.mknod(sNewFile)
        fp = open(sNewFile,"wb+")
        for mData in mDestRes:
            data = bson.BSON.encode(mData)
            fp.write(data)
        fp.close()
    print("-----------hefu:end----------")

if __name__ == "__main__":
    if len(sys.argv) == 3:
        from_server = sys.argv[1]
        to_server = sys.argv[2]
        GS_StartHefu(from_server,to_server)
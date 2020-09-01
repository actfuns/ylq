#!/usr/bin/python
# -*-  coding: utf-8  -*-

import sys
import os

dbpath = os.path.abspath(os.curdir) + "/shell/"
sys.path.append(dbpath)
import pyutils.dbdata as db

def StartDealRank(lFromRes,lDestRes):
    mFromRes = {}
    mDestRes = {}
    for mData in lFromRes:
        mFromRes[mData["name"]] = db.AfterLoad(mData)
    for mData in lDestRes:
        mDestRes[mData["name"]] = db.AfterLoad(mData)

    for sName,mFromData in mFromRes.items():
        sKey = "rank_data"
        if not mDestRes.has_key(sName):
            mDestRes[sName] = {}
        mDestData = mDestRes[sName]
        if not mDestData.has_key(sKey):
            mDestData[sKey] = {}
        mDestRankData = mDestData[sKey]
        mFromRankData= mFromData[sKey]
        sKey = "rank_data"
        if not mDestRankData.has_key(sKey):
            mDestRankData[sKey] = {}
        mDestSaveRankData = mDestRankData[sKey]
        mFromSaveRankData = mFromRankData[sKey]
        for sKey,mData in mFromSaveRankData.items():
            mDestSaveRankData[sKey] = mData
        
        #hcdebug,test
        if not mDestRes[sName].has_key("name"):
            mDestRes[sName]["name"] = sName
        if not mDestRes[sName].has_key("_id"):
            mDestRes[sName]["_id"] = mFromRes[sName]["_id"]

    return mDestRes.values()




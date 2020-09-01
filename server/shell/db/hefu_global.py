#!/usr/bin/python
# -*-  coding: utf-8  -*-
import sys
import time
import os

dbpath = os.path.abspath(os.curdir) + "/shell/"
sys.path.append(dbpath)
import pyutils.dbdata as db

def IsGlobalSave(sName):
    lName = ["achieve","hongbao","partner","arenagame","dialytask","equalarena",
    "orgfuben","pata","travel"]
    for sGlobalName in lName:
        if sName == sGlobalName:
            return True;
    return False;

def InitGlobalData(sName,mFromRes,mDestRes):
    if not mFromRes.has_key(sName):
        mFromRes[sName] = {}
    mFromData = mFromRes[sName]
    if not mDestRes.has_key(sName):
        mDestRes[sName] = {}
    mDestData = mDestRes[sName]
    sKey = "data"
    if not mFromData.has_key(sKey):
        mFromData[sKey] = {}
    if not mDestData.has_key(sKey):
        mDestData[sKey] = {}

def StartDealGlobal(lFromRes,lDestRes):
    mFromRes = {}
    mDestRes = {}
    for mData in lFromRes:
        mFromRes[mData["name"]] = db.AfterLoad(mData)
    for mData in lDestRes:
        mDestRes[mData["name"]] = db.AfterLoad(mData)

    for sName in mFromRes.keys():
        if not IsGlobalSave(sName):
            continue
        InitGlobalData(sName,mFromRes,mDestRes)
        mFromData = mFromRes[sName]
        mDestData = mDestRes[sName]
        if sName == "achieve":
            StartDealGlobalAchieve(mFromData,mDestData)
        elif sName == "hongbao":
            StartDealGlobalHongBao(mFromData,mDestData)
        elif sName == "partner":
            StartDealGlobalPartner(mFromData,mDestData)
        elif sName == "arenagame":
            StartDealGlobalArenagame(mFromData,mDestData)
        elif sName == "dialytask":
            StartDealGlobalDialyTask(mFromData,mDestData)
        elif sName == "equalarena":
            StartDealGlobalEqualArean(mFromData,mDestData)
        elif sName == "orgfuben":
            StartDealGlobalOrgFuben(mFromData,mDestData)
        elif sName =="pata":
            StartDealGolbalPata(mFromData,mDestData)
        elif sName == "travel":
            StartDealGlobalTravel(mFromData,mDestData)
        #hcdebug,test
        if not mDestRes[sName].has_key("name"):
            mDestRes[sName]["name"] = sName
        if not mDestRes[sName].has_key("_id"):
            mDestRes[sName]["_id"] = mFromRes[sName]["_id"]
    return mDestRes.values()
        
def StartDealGlobalAchieve(mFromData,mDestData):
    sKey = "data"
    mFromAchieveData = mFromData[sKey]
    mDestAchieveData = mDestData[sKey]

    sAchCntKey = "achcnt"
    mAchieveCnt = mFromAchieveData[sAchCntKey]
    if not mDestAchieveData.has_key(sAchCntKey):
        mDestAchieveData[sAchCntKey] = {}
    mDestAchieveCnt = mDestAchieveData[sAchCntKey]
    for sAchieve,iCnt in mAchieveCnt.items():
        if not mDestAchieveCnt.has_key(sAchieve):
            mDestAchieveCnt[sAchieve] = 0
        mDestAchieveCnt[sAchieve] = mDestAchieveCnt[sAchieve] + iCnt

def StartDealGlobalHongBao(mFromData,mDestData):
    sKey = "data"
    mHbFromData = mFromData[sKey]
    mHbDestData = mDestData[sKey]
    sKey = "hbid"
    if mHbFromData.has_key(sKey):
        iFromHbid = mHbFromData[sKey]
        if not mHbFromData.has_key(sKey):
            mHbFromData[sKey] = 0
        if mHbFromData[sKey] > mHbDestData[sKey]:
            mHbDestData[sKey] = mHbFromData[sKey]
    sKey = "hongbao"
    if mHbFromData.has_key(sKey):
        mFromHbObjSave = mHbFromData[sKey]
        if not mHbDestData.has_key(sKey):
            mHbDestData[sKey] = {}
        mDestHbObjSave = mHbDestData[sKey]
        for hid,mData in mFromHbObjSave.items():
            mDestHbObjSave[hid] = mData
        mHbDestData[sKey] = mDestHbObjSave
    mDestData["data"] = mHbDestData

def StartDealGlobalPartner(mFromData,mDestData):
    sKey = "data"
    mFromPartnerCmtData = mFromData[sKey]
    mDestPartnerCmtData = mDestData[sKey]
    for sKey,mFromCmt in mFromPartnerCmtData.items():
        if not mDestPartnerCmtData.has_key(sKey):
            mDestPartnerCmtData[sKey] = {}
        mDestCmt = mDestPartnerCmtData[sKey]
        if not mDestCmt.has_key("list"):
            mDestCmt["list"] = []
        lDestCmtList = mDestCmt["list"]
        lFromCmtList = mFromCmt["list"]
        for mCmtData in lFromCmtList:
            if len(lDestCmtList) >= 200:
                break
            lDestCmtList.append(mCmtData)
        lFromHotCmtList =mFromCmt["hot_list"]
        for mCmtData in lFromHotCmtList:
            lDestCmtList.append(mCmtData)

def StartDealGlobalArenagame(mFromData,mDestData):
    sKey = "data"
    mFromArenagame = mFromData[sKey]
    mDestArenagame = mDestData[sKey]
    sKey = "show"
    mFromRecordList = mFromArenagame[sKey]
    if not mDestArenagame.has_key(sKey):
        mDestArenagame[sKey] = {}
    mDestRecordList = mDestArenagame[sKey]

    for sStage,lRecordList in mFromRecordList.items():
        if not mDestRecordList.has_key(sStage):
            mDestRecordList[sStage] = []
        lDestRecord = mDestRecordList[sStage]
        for key,mUnit in enumerate(lRecordList):
            lDestRecord.append(mUnit)
    mDestArenagame[sKey] = mDestRecordList

def StartDealGlobalDialyTask(mFromData,mDestData):
    sKey = "data"
    mFromDialyTask = mFromData[sKey]
    mDestDialyTask = mDestData[sKey]
    for sShowId,lBarrage in mFromDialyTask.items():
        if not mDestDialyTask.has_key(sShowId):
            mDestDialyTask[sShowId] = []
        lDestBarrage = mDestDialyTask[sShowId]
        for mBarrage in lBarrage:
            if len(lDestBarrage) >= 100:
                break
            lDestBarrage.append(mBarrage)
        mDestDialyTask[sShowId] = lDestBarrage
    mDestData[sKey] = mDestDialyTask

def StartDealGlobalEqualArean(mFromData,mDestData):
    sKey = "data"
    mFromArenagame = mFromData[sKey]
    mDestArenagame = mDestData[sKey]

    sKey = "show"
    mFromRecordList = mFromArenagame[sKey]
    if not mDestArenagame.has_key(sKey):
        mDestArenagame[sKey] = {}
    mDestRecordList = mDestArenagame[sKey]

    for sStage,lFromRecordList in mFromRecordList.items():
        if not mDestRecordList.has_key(sStage):
            mDestRecordList[sStage] = []
        lDestRecord = mDestRecordList[sStage]
        for key,mUnit in enumerate(lFromRecordList):
            lDestRecord.append(mUnit)

    sKey = "rank"
    mFromRankData = mFromArenagame[sKey]
    if not mDestArenagame.has_key(sKey):
        mDestArenagame[sKey] = {}
    mDestRankData = mDestArenagame[sKey]
    for iWeekNo,mPoint in mFromRankData.items():
        if not mDestRankData.has_key(iWeekNo):
            mDestRankData[iWeekNo] = {}
        mDestPoint = mDestRankData[iWeekNo]
        iFromPoint = mPoint["point"]
        if not mDestPoint.has_key("point"):
            mDestPoint["point"] = 0
        if iFromPoint < mDestPoint["point"]:
            mDestPoint["point"] = iFromPoint

def StartDealGlobalOrgFuben(mFromData,mDestData):
    sKey = "data"
    mFromOrgData = mFromData[sKey]
    mDestOrgData = mDestData[sKey]

    sKey = "boss"
    mFromOrgBossData = mFromOrgData[sKey]
    if not mDestOrgData.has_key(sKey):
        mDestOrgData[sKey] = {}

    mDestOrgBossData = mDestOrgData[sKey]
    for iOrg,mData in mFromOrgBossData.items():
        mDestOrgBossData[iOrg] = mData


def StartDealGolbalPata(mFromData,mDestData):
    sKey = "data"
    mFromPataData = mFromData[sKey]
    mDestPataData = mDestData[sKey]

    sKey = "sweepinfo"
    mFromSweepinfo = mFromPataData[sKey]
    if not mDestPataData.has_key(sKey):
        mDestPataData[sKey] = {}
    mDestSweepinfo = mDestPataData[sKey]
    for sPid,mData in mFromSweepinfo.items():
        mDestSweepinfo[sPid] = mData

    sKey = "sweepreward"
    mFromSweepReward = mFromPataData[sKey]
    if not mDestPataData.has_key(sKey):
        mDestPataData[sKey] = {}
    mDestSweepReward = mDestPataData[sKey]
    for sPid,lShape in mFromSweepReward.items():
        mDestSweepReward[sPid] = lShape

def StartDealGlobalTravel(mFromData,mDestData):
    sKey = "data"
    mFromTravelData = mFromData[sKey]
    mDestTravelData = mDestData[sKey]

    sKey = "game"
    mFromGameData = mFromTravelData[sKey]
    if not mDestTravelData.has_key(sKey):
        mDestTravelData[sKey] = {}
    mDestGameData = mDestTravelData[sKey]

    for sPid,mData in mFromGameData.items():
        mDestGameData[sPid] = mData
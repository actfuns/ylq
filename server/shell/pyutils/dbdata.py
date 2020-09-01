#!/usr/bin/python
#coding:utf-8

import pymongo

def GetConnection(host = "127.0.0.1", port = 27017):
    conn = pymongo.MongoClient("mongodb://root:bCrfAptbKeW8YoZU@%s:%d/"%(host, port))
    return conn

def AfterLoad(rData):
    if not isinstance(rData, dict):
        return rData

    sIntKey = "_meta_intkey"
    if sIntKey not in rData:
        for k, v in rData.items():
            rData[k] = AfterLoad(v)
        return rData

    lIntKeys = rData[sIntKey]
    del rData[sIntKey]
    lIntKeys.sort()

    bIsList = True
    for k in rData.iterkeys():
        if not isinstance(k, unicode):
            bIsList = False
        if not k.isdigit() or int(k) not in lIntKeys:
            bIsList = False
    if bIsList:
        for n, k in enumerate(lIntKeys):
            if n + 1 != k:
                bIsList = False

    if bIsList:
        lData = []
        for k in lIntKeys:
            lData.append(AfterLoad(rData[unicode(k)]))
        return lData
    else:
        for k in lIntKeys:
            rData[k] = rData[unicode(k)]
            del rData[unicode(k)]

        for k, v in rData.items():
            rData[k] = AfterLoad(v)
        return rData


def BeforeSave(rData):
    if not rData:
        return rData
    if isinstance(rData, list):
        mData = {}
        lIntKeys= []
        for k, v in enumerate(rData):
            k = k + 1
            mData[unicode(k)] = BeforeSave(v)
            lIntKeys.append(k)
        mData[u"_meta_intkey"] = lIntKeys
        return mData

    elif isinstance(rData, dict):
        lIntKeys = []
        for k, v in rData.items():
            if isinstance(k, int) or isinstance(k, float):
                lIntKeys.append(k)
        for k in lIntKeys:
            rData[unicode(k)] = rData[k]
            del rData[k]
        for k, v in rData.items():
            rData[k] = BeforeSave(v)
        if lIntKeys:
            rData[u"_meta_intkey"] = lIntKeys
        return rData

    else:
        return rData

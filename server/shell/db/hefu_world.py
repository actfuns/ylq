#!/usr/bin/python
# -*-  coding: utf-8  -*-

import sys
import time

def StartDealWorld(mFromRes,mDestRes):
    if len(mFromRes) <= 0:
        return
    if len(mDestRes) <= 0:
        mDestRes.append(mFromRes[0])
    mFromData = mFromRes[0]
    mDestData = mDestRes[0]
    sKey = "data"
    if not mFromData.has_key(sKey):
        return
    mFromWorldData = mFromData[sKey]
    if not mDestData.has_key(sKey):
        mDestData[sKey] = {}
    mDestWorldData = mDestData[sKey]
    #起服之后是否合服标记
    mDestWorldData["is_hefu"] = 1
    sKey = "link"
    if not mFromWorldData.has_key(sKey):
        return
    iFromLint = mFromWorldData[sKey]
    if not mDestWorldData[sKey] or mDestWorldData[sKey] < iFromLint:
        mDestWorldData[sKey] = iFromLint
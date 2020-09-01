--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sImageTableName = "image"

function LoadImage(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:Find(sImageTableName, {pid = mData.pid})
    local mRet = {}
    while m:hasNext() do
        local mUnit = m:next()
        mRet[mUnit.key]=mUnit
    end
    return {
        data = mRet,
        pid = mData.pid
    }
end

function SaveImage(mCond, mData)
    local oGameDb = global.oGameDb
    local bUpsert = true
    local pid =mData.pid
    local mImageData = mData.Image or {}
    for key,mSetInfo in pairs(mImageData) do
        mSetInfo["pid"] = pid
        oGameDb:Update(sImageTableName, {key = key}, {["$set"]=mSetInfo}, bUpsert)
    end
end

function FindNoPassImage(mCond,mData)
    local oGameDb = global.oGameDb
    local mRet = {}
    local m = oGameDb:Find(sImageTableName, {check = 0})
    m = m:sort({_time = 1}):limit(100)
    local mRet = {}
    while m:hasNext() do
        table.insert(mRet, m:next())
    end
    return {
        data = mRet
    }
end

function CheckImagePass(mCond,mData)
    local oGameDb = global.oGameDb
    local keylist = mData.keylist or {}
    for key,_ in pairs(keylist) do
        oGameDb:Update(sImageTableName, {key = key}, {["$set"]={check=1}})
    end
end


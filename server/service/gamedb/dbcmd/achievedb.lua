--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sAchieveTableName = "achieve"
local sPictureTableName = "picture"
local sTaskTableName = "task"

function LoadAchieve(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sAchieveTableName, {pid = mData.pid}, {achieve = true})
    m = m or {}
    return {
        data = m.achieve or {},
        pid = mData.pid,
    }
end

function SaveAchieve(mCond, mData)
    local oGameDb = global.oGameDb
    local bUpsert = true
    oGameDb:Update(sAchieveTableName, {pid = mData.pid}, {["$set"]={achieve = mData.data}}, bUpsert)
end

function LoadPicture(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPictureTableName, {pid = mData.pid}, {picture = true})
    m = m or {}
    return {
        data = m.picture or {},
        pid = mData.pid,
    }
end

function SavePicture(mCond, mData)
     local oGameDb = global.oGameDb
    local bUpsert = true
    oGameDb:Update(sPictureTableName, {pid = mData.pid}, {["$set"]={picture=mData.data}}, bUpsert)
end

function LoadSevenDay(mRecord, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sAchieveTableName, {pid = mData.pid}, {sevenday = true})
    m = m or {}
    return {
        data = m.sevenday or {},
        pid = mData.pid,
    }
end

function SaveSevenDay(mRecord, mData)
    local oGameDb = global.oGameDb
    local bUpsert = true
    oGameDb:Update(sAchieveTableName, {pid = mData.pid}, {["$set"]={sevenday = mData.data}}, bUpsert)
end

function LoadTask(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sTaskTableName, {pid = mData.pid}, {task = true})
    m = m or {}
    return {
        data = m.task or {},
        pid = mData.pid,
    }
end

function SaveTask(mCond, mData)
     local oGameDb = global.oGameDb
    local bUpsert = true
    oGameDb:Update(sTaskTableName, {pid = mData.pid}, {["$set"]={task=mData.data}}, bUpsert)
end
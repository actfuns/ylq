--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sIdCounterTableName = "idcounter"

function SavePlayerIdCounter(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sIdCounterTableName, {type = "player"}, {["$set"]={data = mData.data}}, true)
end

function LoadPlayerIdCounter(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sIdCounterTableName, {type = "player"}, {data = true})
    m = m or {}
    return {
        data = m.data or {}
    }
end

function SaveOrgIdCounter(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sIdCounterTableName, {type = "org"}, {["$set"]={data = mData.data}}, true)
end

function LoadOrgIdCounter(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sIdCounterTableName, {type = "org"}, {data = true})
    m = m or {}
    return {
        data = m.data or {}
    }
end
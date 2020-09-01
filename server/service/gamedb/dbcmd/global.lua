--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sGlobalTableName = "global"
local sAssistHDTableName = "assithd"

function LoadGlobal(mRecord, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sGlobalTableName, {name = mData.name}, {data = true})
    m = m or {}
    return {
        data = m.data or {},
        name = mData.name
    }
end

function SaveGlobal(mRecord, mData)
    local oGameDb = global.oGameDb
    local err = safe_call(oGameDb.Update,oGameDb,sGlobalTableName,{name = mData.name}, {["$set"]={data = mData.data}},true)
    if not err then
        print("SaveGlobal:ERR",mData.name)
    end
    --oGameDb:Update(sGlobalTableName, {name = mData.name}, {["$set"]={data = mData.data}},true)
end


function LoadAssistHD(mRecord, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sAssistHDTableName, {name = mData.name}, {data = true})
    m = m or {}
    return {
        data = m.data or {},
        name = mData.name
    }
end

function SaveAssistHD(mRecord, mData)
    local oGameDb = global.oGameDb
    local err = safe_call(oGameDb.Update,oGameDb,sAssistHDTableName,{name = mData.name}, {["$set"]={data = mData.data}},true)
    if not err then
        print("SaveGlobal:ERR",mData.name)
    end
end


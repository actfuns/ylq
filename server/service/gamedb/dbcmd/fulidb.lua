--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sFuliTableName = "fuli"

function LoadFuli(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sFuliTableName, {name = mData.name}, {data = true})
    m = m or {}
    return {
        data = m.data,
        name = mData.name,
    }
end

function SaveFuli(mCond, mData)
    local oGameDb = global.oGameDb
    local err = safe_call(oGameDb.Update,oGameDb,sFuliTableName,{name = mData.name}, {["$set"]={data = mData.data}},true)
    if not err then
        print("SaveFuli:ERR",mData.name)
    end
end

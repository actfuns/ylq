--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sNameCounterTableName = "namecounter"

function InsertNewNameCounter(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sNameCounterTableName, {name = mData.name})
    if m then
        return {
            success = false,
            errmsg = "exist name",
        }
    end
    local bOk, sErr = oGameDb:Insert(sNameCounterTableName, {name = mData.name})
    return {
        success = bOk,
        errmsg = sErr,
    }
end

function FindName(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sNameCounterTableName, {name = mData.name})
    local bOk = false
    if m then
        bOk = true
    end
    return {
        success = bOk
    }
end

function DeleteName(mCond, mData)
    local oGameDb = global.oGameDb
    local bOk = oGameDb:Delete(sNameCounterTableName, {name = mData.name})
    assert(bOk, string.format("delete name fail, %s", mData.name))
end

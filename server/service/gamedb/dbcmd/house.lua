--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sHouseTableName = "house"

function LoadHouse(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sHouseTableName, {pid = mData.pid}, {house_info = true})
    local mRet
    if m then
        mRet = {
            success = true,
            data = m.house_info or {},
            pid = mData.pid,
        }
    else
        mRet = {
            success = false,
        }
    end
    return mRet
end

function SaveHouse(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sHouseTableName, {pid = mData.pid}, {["$set"]={house_info = mData.data}},true)
end
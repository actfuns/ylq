--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sInviteCodeTableName = "invitecode"

function SetAccountInviteCode(mCond,mData)
    local oGameDb = global.oGameDb
    local iAccount = mData.data.account
    local m = oGameDb:FindOne(sInviteCodeTableName, {account = mData.data.account}, {})
    if m and m.account then
        mData.data.account = nil
        oGameDb:Update(sInviteCodeTableName, {account=iAccount},{["$set"]=mData.data})
    else
        oGameDb:Insert(sInviteCodeTableName, mData.data)
    end
end

function GetAcountInviteCode(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sInviteCodeTableName, {account = mData.account}, {})
    return {
        data = m,
        account = mData.account
    }
end

function GetInviteCode(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sInviteCodeTableName, {invitecode = mData.invitecode}, {})
    return {
        data = m,
        account = mData.account
    }
end
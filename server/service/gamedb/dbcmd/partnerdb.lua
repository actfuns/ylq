--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sPartnerTableName = "partner"

function LoadPartner(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPartnerTableName, {pid = mData.pid}, {partner = true})
    m = m or {}
    return {
        data = m.partner or {},
        pid = mData.pid,
    }
end

function SavePartner(mCond, mData)
    local oGameDb = global.oGameDb
    local bUpsert = true
    oGameDb:Update(sPartnerTableName, {pid = mData.pid}, {["$set"]={partner = mData.data}}, bUpsert)
end

function LoadPartnerItem(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPartnerTableName, {pid = mData.pid}, {item=true})
    m = m or {}
    return {
        data = m.item or {},
        pid = mData.pid
    }
end

function SavePartnerItem(mCond, mData)
    local oGameDb = global.oGameDb
    local bUpsert = true
    oGameDb:Update(sPartnerTableName, {pid = mData.pid},  {["$set"]={item = mData.data}}, bUpsert)
end
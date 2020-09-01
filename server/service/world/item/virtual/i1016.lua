local global = require "global"
local skynet = require "skynet"

local virtualbase = import(service_path("item/virtual/virtualbase"))
local loaditem = import(service_path("item/loaditem"))

CItem = {}
CItem.__index = CItem
inherit(CItem,virtualbase.CItem)

function CItem:GetRewardSID()
    local res = require "base.res"
    local iStart = self:GetData("star")
    local iType = self:GetData("type")
    local iPart = self:GetData("pos")
    local mData = res["daobiao"]["partner_item"]["equip_index"]
    local sid = mData[iType][iPart][iStart]
    return sid
end

function CItem:Reward(oPlayer, sReason, mArgs)
    local res = require "base.res"
    local iStart = self:GetData("star")
    local iType = self:GetData("type")
    local iPart = self:GetData("pos")
    local mData = res["daobiao"]["partner_item"]["equip_index"]
    local sid = mData[iType][iPart][iStart]
    oPlayer:GiveItem({{sid,1}},sReason,mArgs)
    local oItem = loaditem.GetItem(sid)
    return {iteminfo=oItem:GetBriefInfo()}
end

function CItem:GetShowInfo()
    local res = require "base.res"
    local iStart = self:GetData("star")
    local iType = self:GetData("type")
    local iPart = self:GetData("pos")
    local mData = res["daobiao"]["partner_item"]["equip_index"]
    local iShape = mData[iType][iPart][iStart]
    return {
        id = self:ID(),
        sid = iShape,
        virtual = self:SID(),
        amount = self:GetAmount(),
    }
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

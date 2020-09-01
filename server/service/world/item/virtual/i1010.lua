local global = require "global"
local skynet = require "skynet"

local virtualbase = import(service_path("item/virtual/virtualbase"))
local loadpartner = import(service_path("partner/loadpartner"))

CItem = {}
CItem.__index = CItem
inherit(CItem,virtualbase.CItem)

function CItem:Reward(oPlayer,sReason,mArgs)
    mArgs = mArgs or {}
    local iPartner = self:GetData("partner")
    if not iPartner then
        return
    end
    local iVal = self:GetData("value",1)
    local oNotifyMgr = global.oNotifyMgr
    local mArg = {star = self:GetData("star")}
    oPlayer.m_oPartnerCtrl:GivePartner({{iPartner, iVal, mArg}}, sReason, mArgs)
    local mResult = {
    id = self.m_ID,
    sid = iPartner,
    name = "",
    amount = 1,
    maxamount = 1,
    }
    return {iteminfo = mResult}
end

function CItem:GetShowInfo()
    return {
        id = self:ID(),
        sid = self:GetData("partner"),
        virtual = self:SID(),
        amount = self:GetData("value", 1),
    }
end

function CItem:GetRwardSid()
    return string.format("%s(partner=%s)",self:SID(),self:GetData("partner"))
end

function CItem:RealName()
    local iPartner = self:GetData("partner")
    local mData = loadpartner.GetPartnerData(iPartner)
    return mData["name"]
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end
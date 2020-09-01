local global = require "global"
local skynet = require "skynet"

local virtualbase = import(service_path("item/virtual/virtualbase"))
local partnerctrl = import(service_path("house.partnerctrl"))

CItem = {}
CItem.__index = CItem
inherit(CItem,virtualbase.CItem)

function CItem:Reward(oPlayer,sReason,mArgs)
    local oHouseMgr = global.oHouseMgr
    mArgs = mArgs or {}
    local iPartner = self:GetData("house_partner")
    if not iPartner then
        return
    end
    local iPid = oPlayer:GetPid()
    oHouseMgr:LoadHouse(iPid, function(oHouse)
        local oPartner = partnerctrl.NewPartner(iPartner)
        oHouse:AddPartner(oPartner,sReason,{cancel_show = 1})
    end)
    global.oUIMgr:AddKeepItem(iPid, self:GetShowInfo())
end

function CItem:GetShowInfo()
    return {
        id = self:ID(),
        sid = self:GetData("house_partner"),
        virtual = self:SID(),
        amount = self:GetData("value", 1),
    }
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end
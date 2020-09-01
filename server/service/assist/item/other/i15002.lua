local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/other/otherbase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:TrueUse(oPlayer, target, iAmount)
    local sReason = "压测道具"
    oPlayer.m_oItemCtrl:AddAmount(self,-iAmount,sReason)
    local mData = {
        cmd = "UseTest",
        reason = sReason,
    }
    oPlayer:SetRemoteItemData(mData)
end
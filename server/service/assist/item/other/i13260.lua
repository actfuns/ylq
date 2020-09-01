local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/other/otherbase"))

random = math.random

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:TrueUse(oPlayer, iTarget, iAmount,mArgs)
    local res = require "base.res"
    local m = res["daobiao"]["partner_item"]["partner_chip"]
    local lChipID = table_key_list(m)
    local lGive = {}
    for i = 1, iAmount do
        local idx = random(#lChipID)
        table.insert(lGive, {lChipID[idx], 1})
    end
    if not oPlayer.m_oItemCtrl:ValidGive(lGive,{cancel_tip = 1}) then
        return
    end
    local sReason = string.format("使用%s",self:Name())
    local mArgs = {
        cancel_tip=1,
    }

    oPlayer.m_oItemCtrl:AddAmount(self,-iAmount,sReason)
    oPlayer:GiveItem(lGive, sReason, mArgs)
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end
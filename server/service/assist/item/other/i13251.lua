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
    mArgs = mArgs or {}
    local iPid = oPlayer:GetPid()
    local lReward = self:GetUseReward()
    local lGiveItem = self:GetGiveItemList(lReward, iAmount)
    if #lGiveItem == 0 then
        return
    end
    if not oPlayer:ValidGive(lGiveItem,{cancel_tip = 1}) then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(iPid, "使用失败，背包已满")
        return
    end
    local sReason = string.format("使用%s",self:Name())
    local mArgs = {
        cancel_tip=1,
    }
    oPlayer.m_oItemCtrl:AddAmount(self,-iAmount,sReason)
    oPlayer:GiveItem(lGiveItem, sReason, mArgs)
end

function CItem:GetGiveItemList(lItem, iAmount)
    local iTotalWeight = 10000
    local lGiveItem = {}
    local lChoose = {}
    for i = 1, iAmount do
        local iRanWeight = random(iTotalWeight)
        local iWeight = 0
        local bChoose = false
        for _, mItem in ipairs(lItem) do
            iWeight = iWeight + mItem.weight
            if mItem.weight == 0 then
                self:AddFilterItem(lGiveItem, mItem.sid,mItem.amount)
            elseif not bChoose and iWeight >= iRanWeight then
                self:AddFilterItem(lGiveItem, mItem.sid,mItem.amount)
                bChoose = true
            end
        end
    end
    return lGiveItem
end

function CItem:FilterChoose(lChoose)
    local lGive = {}
    for _, m in ipairs(lChoose) do
        local sSid, iAmount = table.unpack(m)
        self:AddFilterItem(lGive, sSid, iAmount)
    end
    return lGive
end

function CItem:AddFilterItem(lGive, sSid, iAmount)
        assert(iAmount > 0, string.format("item config err:%s", self:SID()))
        local lSid = split_string(sSid, "#")
        for i=1, iAmount do
            local idx = random(#lSid)
            local sid = lSid[idx]
            table.insert(lGive, {tonumber(sid) or sid, 1})
        end
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end
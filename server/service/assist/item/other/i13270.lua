local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"
local fstring = require "public.colorstring"

local gamedefines = import(lualib_path("public.gamedefines"))

local itembase = import(service_path("item/itembase"))
local loaditem = import(service_path("item/loaditem"))
local itemdefines = import(service_path("item/itemdefines"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    o.m_iStage = 4
    return o
end

function CItem:TrueUse(oPlayer, target, iAmount, mArgs)
    mArgs = mArgs or {}
    local lChoose = self:GetUseReward()
    local iCanUse = self:ChooseAmount()
    local lItemSids = mArgs["itemsids"] or {}
    if self:ValidChoose(oPlayer, target, lItemSids) then
        local sReason = string.format("使用[％s]", self:Name())
        local lGiveItem = {}
        for _, sSid in ipairs(lItemSids) do
            table.insert(lGiveItem, {sSid, 1})
        end
        if oPlayer:ValidGive(lGiveItem) then
            oPlayer.m_oItemCtrl:AddAmount(self,-#lItemSids,sReason)
            oPlayer:GiveItem(lGiveItem,sReason, {cancel_tip = 1})
        end
    end
end

function CItem:ValidChoose(oPlayer, target, lItemSids)
    local iPid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    local iCanUse = self:ChooseAmount()
    if iCanUse <= 0 then
        oNotifyMgr:Notify(iPid, "该礼包无法打开")
        return false
    end
    local iAmount = #lItemSids
    if iAmount ~= iCanUse then
        oNotifyMgr:Notify(iPid, "使用数量有误")
        return false
    end
    if iAmount <= 0 then
        oNotifyMgr:Notify(iPid, "参数有误")
        return false
    end
    if self:GetAmount() < iAmount then
        oNotifyMgr:Notify(iPid, "数量不足")
        return false
    end
    for _, sSid in ipairs(lItemSids) do
        local oItem = loaditem.GetItem(sSid)
        if oItem:ItemType() ~= "parsoul" then
            oNotifyMgr:Notify(iPid, "参数有误，不属于御灵道具")
            return false
        end
        if oItem:QualityLevel() ~= self.m_iStage then
            oNotifyMgr:Notify(iPid, "品质有误")
            return false
        end
    end
    return true
end
local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

local itembase = import(service_path("item/other/otherbase"))



CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:TrueUse(oPlayer, target, iAmount, mArgs)
    mArgs = mArgs or {}
    iAmount = iAmount or 1
    local oNotifyMgr = global.oNotifyMgr
    local lChoose = self:GetUseReward()
    local iCanUse = self:ChooseAmount()
    local lItemSids = mArgs["itemsids"] or {}
    if self:ValidChoose(oPlayer, target, iAmount, lItemSids) then
        local mChoose = {}
        for _, m in ipairs(lChoose) do
            mChoose[m.sid] = m.amount * iAmount
        end
        local lGiveItem = {}
        for _, sSid in ipairs(lItemSids) do
            table.insert(lGiveItem, {sSid, mChoose[sSid]})
        end
        local sReason = string.format("使用[％s]", self:Name())
        if oPlayer:ValidGive(lGiveItem) then
            oPlayer.m_oItemCtrl:AddAmount(self,-iAmount,sReason)
            oPlayer:GiveItem(lGiveItem,sReason, {cancel_tip = 1})
        end
    end
end

function CItem:ValidChoose(oPlayer, target, iAmount, lItemSids)
    local iPid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    local iCanUse = self:ChooseAmount()
    if iCanUse <= 0 then
        oNotifyMgr:Notify(iPid, "该礼包无法打开")
        -- record.error(string.format("玩家：%s打开礼包：%s失败，other表gift_choose_amount字段需大于０", iPid, self:SID()))
        return false
    end
    if #lItemSids ~= iCanUse then
        oNotifyMgr:Notify(iPid, "使用数量有误")
        -- record.error(string.format("玩家：%s打开礼包：%s失败，可选数量:%s ~= %s", iPid, self:SID(), iCanUse, #lItemSids))
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
    local mDuplicate = {}
    for _, sSid in ipairs(lItemSids) do
        if mDuplicate[sSid] then
            oNotifyMgr:Notify(iPid, "参数有误")
            return false
        end
        mDuplicate[sSid] = 1
    end
    local lChoose = self:GetUseReward()
    if #lChoose <= 0 then
        return false
    end
    for _, m in ipairs(lChoose) do
        mDuplicate[m.sid] = nil
    end
    if next(mDuplicate) then
        oNotifyMgr:Notify(iPid, "参数有误")
        return false
    end
    return true
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end


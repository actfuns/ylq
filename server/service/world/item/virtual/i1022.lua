local global = require "global"
local skynet = require "skynet"

local virtualbase = import(service_path("item/virtual/virtualbase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,virtualbase.CItem)

function CItem:Reward(oPlayer,sReason,mArgs)
    local iValue = self:GetData("value")
    if not iValue then
        return
    end
    oPlayer.m_oActiveCtrl:AddSkillPoint(iValue, sReason)
    local oNotifyMgr = global.oNotifyMgr
    local lMessage = {}
    local sMsg = string.format("获得%s#amount", "技能点")
    local mNotifyArgs = {
        amount = iValue
    }
    if not mArgs.cancel_tip then
        table.insert(lMessage,"GS2CNotify")
    end
    if not mArgs.cancel_channel then
        table.insert(lMessage,"GS2CConsumeMsg")
    end
    if #lMessage > 0 then
        oNotifyMgr:BroadCastNotify(oPlayer.m_iPid,lMessage,sMsg,mNotifyArgs)
    end
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end
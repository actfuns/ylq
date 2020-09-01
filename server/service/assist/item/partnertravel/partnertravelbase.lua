local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/itembase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "partnertravel"

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end


function CItem:New(sid)
    local o = super(CItem).New(self, sid)
    return o
end

function CItem:TrueUse(oPlayer, iTarget, iAmount,mArgs)
    local partner_travel = mArgs.partner_travel or 0
    if partner_travel == 1 then
        global.oNotifyMgr:Notify(oPlayer:GetPid(),"使用失败,未取消道具")
        return
    end
    local sReason = string.format("使用％s", self:Name())
    oPlayer.m_oItemCtrl:AddAmount(self,-1,sReason)
    local mArgs = {
        speed_info = self:PackSpeedInfo(),
    }
    local mData = {
        cmd = "PartnerTravel",
        reason = sReason,
        args = mArgs,
    }
    oPlayer:SetRemoteItemData(mData)
end

function CItem:PackSpeedInfo()
    local mData = self:GetItemData()
    local mRet = {}
    mRet["sid"] = self:SID()
    mRet["start_time"] = get_time()
    mRet["end_time"] = get_time() + mData["add_time"]
    mRet["apply"] = {
        ["exp"] = mData["exp_rate"],
        ["coin"] = mData["coin_rate"],
    }
    return mRet
end
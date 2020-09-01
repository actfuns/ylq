local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))

local itembase = import(service_path("item/other/otherbase"))



CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:GetHongBaoInfo()
    local res = require "base.res"
    return res["daobiao"]["hongbao"]["hb_config"][self:SID()]
end

function CItem:TrueUse(oPlayer, target, iAmount)
    local iPid = oPlayer:GetPid()
    local mData = {sContent={"公会频道","世界频道"}}
    local id = self:ID()
    local func = function (oPlayer,mData)
        local iAnswer = mData["answer"]
        if iAnswer == 1 then
            local oItem = oPlayer.m_oItemCtrl:HasItem(id)
            local mData = oItem:GetHongBaoInfo()
            local iOrgID = oPlayer:GetOrgID()
            if not oItem or oItem:GetAmount() <= 0 then return end
            if iOrgID == 0 then
                oPlayer:NotifyMessage("请先加入公会")
                return
            end
            oPlayer.m_oItemCtrl:AddAmount(oItem,-1,"公会频道红包")
            global.oHbMgr:SendHongBao(oPlayer,"orgchannel",mData["gold"],mData["cnt"])
            oPlayer:NotifyMessage("成功发放红包")
        else
            oPlayer:NotifyMessage("暂未开放世界频道，尽请期待")
        end
    end
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(iPid, "GS2CHongBaoUI", mData, nil, func)
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end


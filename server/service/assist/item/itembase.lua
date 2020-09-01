local global = require "global"

local itembase = import(lualib_path("public.itembase"))
local itemdefines = import(service_path("item.itemdefines"))

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

CItem.m_ItemType = "base"

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:GetContainer()
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetOwner()
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local iType = self:Type()
        return oPlayer.m_oItemCtrl:GetContainer(iType)
    end
end

function CItem:GetPlayerObj(iPid)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetOwner()
    return oAssistMgr:GetOnlinePlayerByPid(iPid)
end

function CItem:Setup()
    if self:GetData("Time") then
        local iTime = self:GetData("Time",0) - get_time()
        if iTime > 0 then
            self:DelTimeCb("timeout")
            local iItemID = self.m_ID
            local oAssistMgr = global.oAssistMgr
            local iPid = self:GetOwner()
            local fCallback = function ()
                local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    local oItem = oPlayer.m_oItemCtrl:HasItem(iItemID)
                    if oItem then
                        oItem:TimeOut()
                    end
                end
            end
            self:AddTimeCb("timeout",iTime*1000,fCallback)
        else
            self:TimeOut()
        end
    end
end

function CItem:TimeOut()
    self:Dirty()
    local iAmount = self:GetAmount()
    local oContainer = self:GetContainer()
    if oPlayer then
        oPlayer.m_oItemCtrl:AddAmount(self,-iAmount,"TimeOut")
    else
        self:AddAmount(-iAmount,"TimeOut")
    end
end

function CItem:GetOwner()
    return self:GetPid()
end

function CItem:ValidUse(oPlayer, iUseAmount,mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if not iUseAmount or iUseAmount <= 0 then
        oNotifyMgr:Notify(iPid, "使用数量需大于1")
        return false
    end
    local iAmount = self:GetAmount()
    if iAmount < iUseAmount then
        oNotifyMgr:Notify(iPid, "道具不足")
        return false
    end
    mArgs = mArgs or {}
    local iGrade = mArgs.grade or oPlayer:GetGrade()
    if iGrade < self:MinUseGrade() then
        oNotifyMgr:Notify(iPid, "等级过低，无法使用")
        return false
    end
    if iGrade > self:MaxUseGrade() then
        oNotifyMgr:Notify(iPid, "等级过高，无法使用")
        return false
    end
    return true
end

function CItem:Use(oPlayer,target,iAmount,mArgs)
    iAmount = iAmount or 1
    mArgs = mArgs or {}
    if not self:ValidUse(oPlayer, iAmount,mArgs) then
        return
    end
    self:TrueUse(oPlayer, target, iAmount,mArgs)
end

function CItem:TrueUse(oPlayer,target, amount,mArgs)
    --
end

--道具加锁
function CItem:SetLock()
    if self:IsLock() then
        self:SetData("lock", 0)
    else
        self:SetData("lock", 1)
    end
end

function CItem:IsLock()
    return self:GetData("lock", 0) == 1
end

function CItem:GetLock()
    return self:GetData("lock", 0)
end


function CItem:GS2CConsumeMsg(oPlayer)
    if oPlayer then
        local oChatMgr = global.oChatMgr
        local iColor = self:Quality()
        local res = require "base.res"
        local mItemColor = res["daobiao"]["itemcolor"][iColor]
        local mAmountColor = res["daobiao"]["othercolor"]["amount"]
        assert(mItemColor, string.format("itemcolor config id: %d not exit", iColor))
        local sMsg = string.format("使用%s个%s", mAmountColor.color, mItemColor.color)
        sMsg = string.format(sMsg, self:GetUseCostAmount(), self:Name() )
        oChatMgr:HandleMsgChat(oPlayer, sMsg)
    end
end

function CItem:PackRemoteData()
    local m = self:Save()
    m.id = self:ID()
    return m
end



function CItem:PackAssistData()
    local mArgs = {}
    local oPlayer = self:GetOwner()
    if oPlayer then
        mArgs = oPlayer:GetRemoteItemData()
    end
    return mArgs
end
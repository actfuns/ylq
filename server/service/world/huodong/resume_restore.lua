-- import module
local res = require "base.res"
local global = require "global"

local huodongbase = import(service_path("huodong.huodongbase"))
local loaditem = import(service_path("item/loaditem"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "resume_restore"
CHuodong.m_sTempName = "消费预存"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_bStart = false
    o.m_iStartTime = 0
    o.m_iEndTime = 0
    o.m_iCurId = 0
    return o
end

function CHuodong:GetOpenObj()
    local oHuodong = global.oHuodongMgr:GetHuodong("limitopen")
    return oHuodong
end

function CHuodong:CheckStart()
    self:DelTimeCb("CheckStart")
    local oOpenObj = self:GetOpenObj()
    if not oOpenObj then
        return
    end
    local iCurId = oOpenObj:GetUsePlan(self.m_sName)
    if not iCurId then
        return
    end
    self.m_iCurId = tonumber(iCurId)
    self.m_iStartTime = oOpenObj:StartTime(self.m_sName)
    self.m_iEndTime = oOpenObj:EndTime(self.m_sName)
    if self.m_iStartTime and self.m_iEndTime then
        local iNowTime = get_time()
        local iDis = self.m_iStartTime - iNowTime
        if oOpenObj:IsOpen(self.m_sName) then
            self:DelTimeCb("CloseHuodong")
            self:AddTimeCb("CloseHuodong",(self.m_iEndTime-iNowTime)*1000,function()
                local oHuodong = global.oHuodongMgr:GetHuodong("resume_restore")
                if oHuodong then
                    oHuodong:CloseHuodong()
                end
            end)
            self:BrocastOnLinePlayer()
            self.m_bStart = true
            return
        elseif iDis > 0 and iDis < 3600 then
            self:AddTimeCb("CheckStart",iDis*1000,function()
                local oHuodong = global.oHuodongMgr:GetHuodong("resume_restore")
                if oHuodong then
                    oHuodong:CheckStart()
                end
            end)
        end
    end
    self.m_bStart = false
end

function CHuodong:CloseHuodong()
    self:DelTimeCb("CloseHuodong")
    self.m_bStart = false
    self:BrocastOnLinePlayer()
end

function CHuodong:IsOpen()
    return self.m_bStart
end

function CHuodong:CanGet()
    if self:IsOpen() and not self:CanRestore() then
        return true
    end
    return false
end

function CHuodong:CanRestore()
    if self:IsOpen() and (self.m_iEndTime and (self.m_iEndTime - get_time()) >24*60*60) then
        return true
    end
    return false
end

function CHuodong:NewHour()
    self:CheckStart()
end

function CHuodong:AfterResumeGoldCoin(oPlayer,iAmount)
    if self:CanRestore() then
        oPlayer.m_oHuodongCtrl:AfterResumeGoldCoin(iAmount,self.m_sName)
    end
end

function CHuodong:BrocastOnLinePlayer()
    local mOnline = global.oWorldMgr:GetOnlinePlayerList()
    for iPid,oPlayer in pairs(mOnline) do
        local mInfo = oPlayer.m_oHuodongCtrl:PackResumeRestoreInfo()
        if not self.m_bStart then
            oPlayer.m_oHuodongCtrl:ClearResumeRestoreInfo(self.m_iStartTime)
        end
        oPlayer:Send("GS2CResumeRestore",{start_time = self.m_iStartTime,end_time = self.m_iEndTime,plan_id = self.m_iCurId})
        oPlayer.m_oHuodongCtrl:RefreshResumeRestore()
    end
end

function CHuodong:OnLogin(oPlayer,bRenter)
    if self:IsOpen() then
        local mInfo = oPlayer.m_oHuodongCtrl:PackResumeRestoreInfo()
        if mInfo["start_time"] ~= self.m_iStartTime then
            oPlayer.m_oHuodongCtrl:ClearResumeRestoreInfo(self.m_iStartTime)
        end
        oPlayer:Send("GS2CResumeRestore",{start_time = self.m_iStartTime,end_time = self.m_iEndTime,plan_id = self.m_iCurId})
        oPlayer.m_oHuodongCtrl:RefreshResumeRestore()
    end
end

function CHuodong:GetResumeRestoreReward(oPlayer)
    if not self:IsOpen() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"活动已结束")
        return
    end
    if not self:CanGet() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"未到领取时间")
        return
    end
    if not oPlayer.m_oHuodongCtrl:ValidGetResumeRestoreReward() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"已领取过该奖励")
        return
    end
    local mResume = oPlayer.m_oHuodongCtrl:PackResumeRestoreInfo()
    local iResume = mResume["resume"]
    if iResume <= 0 then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"暂无可领取水晶")
        return
    end
    local iRatio = self:GetRatio()
    if not iRatio or iRatio <= 0 then
        return
    end
    oPlayer.m_oHuodongCtrl:GetResumeRestoreReward()
    oPlayer:RewardGoldCoin(iResume*iRatio,"领取消费预存红包")
    oPlayer.m_oHuodongCtrl:RefreshResumeRestore()
end

function CHuodong:GetRatio()
    -- body
    local sTmp = global.oWorldMgr:QueryGlobalData("resume_restore_ratio")
    local mAmount = split_string(sTmp,",")
    local sAmount = mAmount[self.m_iCurId]
    if not sAmount then
        return
    end
    return tonumber(sAmount)
end
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
CHuodong.m_sName = "timelimitresume"
CHuodong.m_sTempName = "限时消费"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_bStart = false
    o.m_iStartTime = 0
    o.m_iEndTime = 0
    o.m_bInit = false
    o.m_iCurId = 0
    return o
end

function CHuodong:GetOpenObj()
    local oHuodong = global.oHuodongMgr:GetHuodong("limitopen")
    return oHuodong
end

function CHuodong:CheckStart()
    self:DelTimeCb("CheckStart")
    self.m_bInit = true
    local oOpenObj = self:GetOpenObj()
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
                local oHuodong = global.oHuodongMgr:GetHuodong("timelimitresume")
                if oHuodong then
                    oHuodong:CloseHuodong()
                end
            end)
            self:BrocastOnLinePlayer()
            self.m_bStart = true
            return
        elseif iDis > 0 and iDis < 3600 then
            self:AddTimeCb("CheckStart",iDis*1000,function()
                local oHuodong = global.oHuodongMgr:GetHuodong("timelimitresume")
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

function CHuodong:NewHour()
    self:CheckStart()
end

function CHuodong:AfterResumeGoldCoin(oPlayer,iAmount)
    if self:IsOpen() then
        oPlayer.m_oHuodongCtrl:AfterResumeGoldCoin(iAmount,self.m_sName)
    end
end

function CHuodong:BrocastOnLinePlayer()
    local mOnline = global.oWorldMgr:GetOnlinePlayerList()
    for iPid,oPlayer in pairs(mOnline) do
        oPlayer:Send("GS2CTimeResumeInfo",{start_time = self.m_iStartTime,end_time = self.m_iEndTime,plan_id = self.m_iCurId})
        oPlayer.m_oHuodongCtrl:RefreshTimeResume()
    end
end

function CHuodong:OnLogin(oPlayer,bRenter)
    if not self.m_bInit then
        self:CheckStart()
        return
    end
    if self:IsOpen() then
        oPlayer:Send("GS2CTimeResumeInfo",{start_time = self.m_iStartTime,end_time = self.m_iEndTime,plan_id = self.m_iCurId})
        oPlayer.m_oHuodongCtrl:RefreshTimeResume()
    end
end

function CHuodong:GetPlanItem()
    local res = require "base.res"
    assert(res["daobiao"]["timelimit_resume"]["plan_info"][self.m_iCurId], "no timelimit_plan id "..self.m_iCurId)
    local mReward = res["daobiao"]["timelimit_resume"]["plan_info"][self.m_iCurId]["item_list"]
    return mReward
end

function CHuodong:GetTimeResumeReward(oPlayer,iReward)
    if not self:IsOpen() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"活动已结束")
        return
    end
    local mPlanInfo = self:GetPlanItem()
    if not table_in_list(mPlanInfo,iReward) then
        return
    end
    if not oPlayer.m_oHuodongCtrl:ValidGetTimeResumeReward(iReward) then
        return
    end
    oPlayer.m_oHuodongCtrl:GetTimeResumeReward(iReward)
    local mReward = self:GetRewardInfo(iReward)
    if not mReward then
        return
    end
    local mItemList = {}
    for _,info in pairs(mReward) do
        table.insert(mItemList,{info["sid"],info["num"]})
    end
    oPlayer:GiveItem(mItemList,"限时消费"..iReward,{cancel_tip=true})
    global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
    oPlayer.m_oHuodongCtrl:RefreshTimeResume(iReward)
end

function CHuodong:GetRewardInfo(iReward)
    local res = require "base.res"
    assert(res["daobiao"]["timelimit_resume"]["reward_info"][iReward], "no timelimit_resume id "..iReward)
    if res["daobiao"]["timelimit_resume"]["reward_info"][iReward]["open"] ~= 1 then
        return
    end
    local mReward = res["daobiao"]["timelimit_resume"]["reward_info"][iReward]["reward"]
    return mReward
end
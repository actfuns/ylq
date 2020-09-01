-- import module
local res = require "base.res"
local global = require "global"
local record = require "public.record"

local huodongbase = import(service_path("huodong.huodongbase"))
local loaditem = import(service_path("item/loaditem"))
local record = require "public.record"

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "chargescore"
CHuodong.m_sTempName = "充值积分活动"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_bHasInit = false
    return o
end

function CHuodong:GetOpenObj()
    return global.oHuodongMgr:GetHuodong("limitopen")
end

function CHuodong:InitData()
    self.m_bHasInit = true
    self.m_iCurId = 0
    self.m_iStatus = 0          ---0关闭 1开启
    self.m_iStartTime = 0
    self.m_iEndTime = 0
    self:CheckStart()
    self:CheckEnd()
end

function CHuodong:NewHour()
    self:CheckEnd()
    self:CheckStart()
end

function CHuodong:CheckStart()
    local obj = self:GetOpenObj()
    if not obj then
        return
    end
    local iCurId = obj:GetUsePlan(self.m_sName)
    if not iCurId then
        return
    end
    self.m_iCurId = tonumber(iCurId)
    if self.m_iStatus ~= 1 and  obj:IsOpen(self.m_sName) then
        self.m_iStartTime = obj:StartTime(self.m_sName)
        self.m_iEndTime = obj:EndTime(self.m_sName)
        self:Start()
    end
end

function CHuodong:Start()
    self.m_iStatus = 1
    local mOnlinePlayer = global.oWorldMgr:GetOnlinePlayerList()
    for iPid,oPlayer in pairs(mOnlinePlayer) do
        local mInfo = oPlayer.m_oHuodongCtrl:PackChargeScoreInfo()
        local iActivity = mInfo["activityid"] or 0
        if iActivity ~= 0 and iActivity ~= self.m_iCurId then
            oPlayer.m_oHuodongCtrl:ClearChargeScoreInfo(self.m_iCurId)
        end
        oPlayer:Send("GS2CChargeScore",{cur_id = self.m_iCurId,status = self.m_iStatus,start_time = self.m_iStartTime,end_time = self.m_iEndTime})
    end
end

function CHuodong:CheckEnd()
    if self.m_iCurId == 0 then
        return
    end
    local obj = self:GetOpenObj()
    if not obj then
        return
    end
    if not obj:IsOpen(self.m_sName) then
        self:End()
    end
end

function CHuodong:End()
    self.m_iStatus = 0
    local mOnlinePlayer = global.oWorldMgr:GetOnlinePlayerList()
    for iPid,oPlayer in pairs(mOnlinePlayer) do
        oPlayer:Send("GS2CChargeScore",{cur_id = self.m_iCurId,status = self.m_iStatus,start_time = self.m_iStartTime,end_time = self.m_iEndTime})
        oPlayer.m_oHuodongCtrl:ClearChargeScoreInfo(self.m_iCurId)
    end
end

function CHuodong:GetActivityInfo(iID)
    local mInfo = res["daobiao"]["rechagescore"]["config"][iID]
    assert(mInfo,"miss config of activity:"..iID)
    return mInfo
end

function CHuodong:GetItemPoolInfo(iID)
    local mInfo = res["daobiao"]["rechagescore"]["config"][iID]
    assert(mInfo,"miss config of activity:"..iID)
    return mInfo["sale_item"]
end

function CHuodong:GetItemInfo(iID)
    local mInfo = res["daobiao"]["rechagescore"]["item_pool"][iID]
    assert(mInfo,"miss config of item:"..iID)
    return mInfo
end

function CHuodong:GetStartTime(iID)
    local mInfo = self:GetActivityInfo(iID)
    local sStartTime = mInfo["start_time"]
    local mArgs = split_string(sStartTime,"/")
    local iStartYear,iStartMonth,iStartDay = table.unpack(mArgs)
    return os.time({year=tonumber(iStartYear),month=tonumber(iStartMonth),day=tonumber(iStartDay),hour=0,min=0,sec=0})
end

function CHuodong:GetEndTime(iID)
    local mInfo = self:GetActivityInfo(iID)
    local sEndTime = mInfo["end_time"]
    local mArgs = split_string(sEndTime,"/")
    local iEndYear,iEndMonth,iEndDay = table.unpack(mArgs)
    return os.time({year=tonumber(iEndYear),month=tonumber(iEndMonth),day=tonumber(iEndDay),hour=23,min=59,sec=59})
end

function CHuodong:OnLogin(oPlayer,bReEnter)
    if not self.m_bHasInit then
        self:InitData()
    end
    local mInfo = oPlayer.m_oHuodongCtrl:PackChargeScoreInfo()
    local iActivity = mInfo["activityid"] or 0
    if iActivity ~= 0 and iActivity ~= self.m_iCurId then
        oPlayer:Send("GS2CChargeScore",{cur_id = self.m_iCurId,status = self.m_iStatus,start_time = self.m_iStartTime,end_time = self.m_iEndTime})
        oPlayer.m_oHuodongCtrl:ClearChargeScoreInfo(self.m_iCurId)
        return
    end
    local mScoreInfo = self:PackNetInfo(mInfo["score_info"] and mInfo["score_info"] or {})
    oPlayer:Send("GS2CChargeScore",{cur_id = self.m_iCurId,status = self.m_iStatus,score_info = mScoreInfo,start_time = self.m_iStartTime,end_time = self.m_iEndTime})
end

function CHuodong:BuyItem(oPlayer,iID,iTime)
    if self.m_iStatus == 0 then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"不在活动时间内")
        return
    end
    local mInfo = self:GetItemPoolInfo(self.m_iCurId)
    if not table_in_list(mInfo,iID) then
        record.error("充值积分购买物品并未上架"..iID)
        return
    end
    local mItemInfo = self:GetItemInfo(iID)
    local iCost = mItemInfo["point"]
    local iLimit = mItemInfo["buy_limit"]
    local iDoneTimes = oPlayer.m_oHuodongCtrl:GetChargeScoreBuyTimes(iID)
    local iScore = oPlayer.m_oHuodongCtrl:GetChargeScore()
    if iLimit ~= 0 and iDoneTimes > iLimit then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"购买次数达到上限")
        return
    end
    if iCost*iTime > iScore then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"积分不足")
        return
    end
    local iNewTimes,iNewScore = oPlayer.m_oHuodongCtrl:BuyChargeScoreItem(iID,iTime,iCost*iTime)
    self:GiveItem(oPlayer,{mItemInfo["reward"]},"充值积分购买物品",{times = iTime})
    oPlayer:Send("GS2CUpdateCSBuyTimes",{id = iID,buy_times = iNewTimes,score = iNewScore})
    record.user("chargescore","resumescore",{pid = oPlayer.m_iPid,itemid = iID,resume_times = iTime,resume_score = iCost*iTime,new_score = iNewScore,time = get_time(),plan = self.m_iCurId})
end

function CHuodong:GiveItem(oPlayer,mReward,sReason,mArgs)
    local mItem = self:BuildItemList(mReward,mArgs)
    local mLogItem = {}
    for _,oItem in pairs(mItem) do
        table.insert(mLogItem,oItem:LogInfo())
        oPlayer:RewardItem(oItem,sReason,mArgs)
    end
end

function CHuodong:BuildItemList(mReward,mArgs)
    local mItem = {}
    for _,info in pairs(mReward) do
        local sShape = info["sid"]
        local iAmount = info["num"]* (mArgs["times"] or 1)
        for iNo=1,100 do
            local oItem = loaditem.ExtCreate(sShape)
            local iAddAmount = math.min(oItem:GetMaxAmount(),iAmount)
            iAmount = iAmount - iAddAmount
            oItem:SetAmount(iAddAmount)
            table.insert(mItem,oItem)
            if iAmount <= 0 then
                break
            end
        end
    end
    return mItem
end

function CHuodong:AfterCharge(oPlayer,iAmount)
    if self.m_iStatus == 1 then
        local iRate = global.oWorldMgr:QueryGlobalData("charge2score")
        iRate = tonumber(iRate)
        local iAddScore = iAmount*iRate
        local iNewScore = oPlayer.m_oHuodongCtrl:AfterCharge(iAddScore)
        oPlayer:Send("GS2CUpdateCSBuyTimes",{score = iNewScore})
        record.user("chargescore","addscore",{pid = oPlayer.m_iPid,add_score = iAddScore,new_score = iNewScore,time = get_time(),plan = self.m_iCurId})
    end
end

function CHuodong:PackNetInfo(mInfo)
    local iScore = mInfo["score"] or 0
    local m = mInfo["buy_info"] or {}
    local mBuyInfo = {}
    for iID,iTimes in pairs(m) do
        table.insert(mBuyInfo,{id = iID,buy_times = iTimes})
    end
    return {score = iScore,buy_info = mBuyInfo}
end

-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"
local record = require "public.record"
local loaditem = import(service_path("item/loaditem"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "onlinegift"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
end

function CHuodong:NewDay(iWeekDay)
    local mOnlinePlayer = global.oWorldMgr:GetOnlinePlayerList()
    for iPid,oPlayer in pairs(mOnlinePlayer) do
        local mOnlineGift = {status = 0,onlinetime = 0,lastrecordtime = get_time(),reward = {}}
        oPlayer.m_oToday:Set("onlinegift",mOnlineGift)
        oPlayer.m_oToday:Set("onlinetime",0)
        oPlayer:Send("GS2COnlineGift",{status = 0,onlinetime = 0})
        record.user("onlinegift","reset",{pid = oPlayer.m_iPid,status = 0,onlinetime=0,lastrecordtime=get_time(),reason = "newday"})
    end
end

function CHuodong:OnLogin(oPlayer)
    local mOnlineGift = oPlayer.m_oToday:Query("onlinegift",{})
    if oPlayer.m_oActiveCtrl:GetData("disconnect",1) == 1 then
        self:Dirty()
        mOnlineGift["lastrecordtime"] = get_time()
        oPlayer.m_oToday:Set("onlinegift",mOnlineGift)
        oPlayer.m_oActiveCtrl:SetData("disconnect",0) 
        record.user("onlinegift","reset",{pid = oPlayer.m_iPid,status = mOnlineGift["status"] or 0,onlinetime=mOnlineGift["onlinetime"] or 0,lastrecordtime=mOnlineGift["lastrecordtime"] or 0,reason = "login"})
    end
    oPlayer:Send("GS2COnlineGift",{status = mOnlineGift["status"],onlinetime = mOnlineGift["onlinetime"],reward = mOnlineGift["reward"]})
end

function CHuodong:OnDisconnected(oPlayer)
    self:Dirty()
    local iLoginTime = oPlayer.m_oActiveCtrl:GetData("login_time",0)
    local iOnlineTime = oPlayer.m_oToday:Query("onlinetime",0)
    local mOnlineGift = oPlayer.m_oToday:Query("onlinegift",{})
    local iLastRecordTime = mOnlineGift["lastrecordtime"] or 0
    if iLastRecordTime == 0 then
        iLastRecordTime = iLoginTime
    end
    iOnlineTime = (get_time() - iLastRecordTime) + iOnlineTime
    oPlayer.m_oToday:Set("onlinetime",iOnlineTime)
    mOnlineGift["onlinetime"] = iOnlineTime
    mOnlineGift["lastrecordtime"] = get_time()
    oPlayer.m_oToday:Set("onlinegift",mOnlineGift)
    oPlayer.m_oActiveCtrl:SetData("disconnect",1)
    record.user("onlinegift","reset",{pid = oPlayer.m_iPid,status = mOnlineGift["status"] or 0,onlinetime=mOnlineGift["onlinetime"] or 0,lastrecordtime=mOnlineGift["lastrecordtime"] or 0,reason = "disconnect"})
    -- body
end

function CHuodong:OnLogout(oPlayer)
    if oPlayer.m_oActiveCtrl:GetData("disconnect",1) == 1 then
        return
    end
    local iLoginTime = oPlayer.m_oActiveCtrl:GetData("login_time",0)
    local iOnlineTime = oPlayer.m_oToday:Query("onlinetime",0)
    local mOnlineGift = oPlayer.m_oToday:Query("onlinegift",{})
    local iLastRecordTime = mOnlineGift["lastrecordtime"] or 0
    if iLastRecordTime == 0 then
        iLastRecordTime = iLoginTime
    end
    iOnlineTime = (get_time() - iLastRecordTime) + iOnlineTime
    oPlayer.m_oToday:Set("onlinetime",iOnlineTime)
    mOnlineGift["onlinetime"] = iOnlineTime
    mOnlineGift["lastrecordtime"] = get_time()
    oPlayer.m_oToday:Set("onlinegift",mOnlineGift)
    record.user("onlinegift","reset",{pid = oPlayer.m_iPid,status = mOnlineGift["status"] or 0,onlinetime=mOnlineGift["onlinetime"] or 0,lastrecordtime=mOnlineGift["lastrecordtime"] or 0,reason = "logout"})
end

function CHuodong:BuildItemList(mReward)
    local mItem = {}
    for _,info in pairs(mReward) do
        local sShape = info["sid"]
        local iAmount = info["num"]
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

function CHuodong:RandomReward(oPlayer,mReward,iRewardId)
    local iTotalWeight = 0
    for _,info in ipairs(mReward) do
        iTotalWeight = iTotalWeight + info["ratio"]
    end
    local mRewardInfo = oPlayer.m_oActiveCtrl:GetData("onlinegift_rewardtimes",{})
    local iRewardTimes = mRewardInfo[iRewardId] or 0
    mRewardInfo[iRewardId] = iRewardTimes + 1
    oPlayer.m_oActiveCtrl:SetData("onlinegift_rewardtimes",mRewardInfo)
    if iRewardTimes == 0 then
        return {mReward[1]},1
    end

    local iRandom = math.random(iTotalWeight)
    local iCur = 0
    for iIndex,info in ipairs(mReward) do
        iCur = iCur + info["ratio"]
        if iRandom <= iCur then
            return {info},iIndex
        end
    end
    return {},0
end

function CHuodong:ReceiveReward(oPlayer,iRewardId)
    if self:HasReward(oPlayer,iRewardId) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"已领取过该奖励")
        return
    end
    if not self:CanReward(oPlayer,iRewardId) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"未达到领取条件")
        return
    end
    self:SetReward(oPlayer,iRewardId)
    local mGift = self:GetConfigData(iRewardId)
    local mStableReward = mGift["reward"]
    local mRandomList = mGift["randomlist"]
    local mItem = self:BuildItemList(mStableReward)
    local mRecord = {rewardid = iRewardId,stable_reward = {},random_reward={}}
    for _,oItem in pairs(mItem) do
        table.insert(mRecord["stable_reward"],{amount=oItem:GetAmount(),sid=oItem:SID()})
        oPlayer:RewardItem(oItem,"在线奖励领取固定奖励",{cancel_tip = true})
    end
    local mRandom,iIndex = self:RandomReward(oPlayer,mRandomList,iRewardId)
    mItem = self:BuildItemList(mRandom)
    for _,oItem in pairs(mItem) do
        table.insert(mRecord["random_reward"],{amount=iIndex,sid=oItem:SID()})
        oPlayer:RewardItem(oItem,"在线奖励领取随机奖励",{cancel_tip = true})
    end
    local mOnlineGift = oPlayer.m_oToday:Query("onlinegift",{})
    mOnlineGift["reward"] = mOnlineGift["reward"] or {}
    table.insert(mOnlineGift["reward"],mRecord)
    oPlayer.m_oToday:Set("onlinegift",mOnlineGift)
    global.oUIMgr:ShowKeepItem(oPlayer.m_iPid)
    record.user("onlinegift","reward",{pid = oPlayer.m_iPid,status = mOnlineGift["status"] or 0,onlinetime=mOnlineGift["onlinetime"] or 0,lastrecordtime=mOnlineGift["lastrecordtime"] or 0,reward = mRecord})
    oPlayer:Send("GS2COnlineGift",{status = mOnlineGift["status"],onlinetime = mOnlineGift["onlinetime"],reward = mOnlineGift["reward"]})
    global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,"领取在线奖励",{value=1})

end

function CHuodong:HasReward(oPlayer,iRewardId)
    local mOnlineGift = oPlayer.m_oToday:Query("onlinegift",{})
    local iRewardStatus = mOnlineGift["status"] or 0
    local iBit = 1 << (iRewardId - 1)
    local iBitStatus = iRewardStatus & iBit
    return iBitStatus ~= 0
end

function CHuodong:CanReward(oPlayer,iRewardId)
    local mOnlineGift = oPlayer.m_oToday:Query("onlinegift",{})
    local iOnlineTime = mOnlineGift["onlinetime"] or 0
    local iLastRecordTime = mOnlineGift["lastrecordtime"] or 0
    local mData = self:GetConfigData(iRewardId)
    local iNeedTime = mData["online_time"]
    local iCurOnlineTime = (iOnlineTime + (get_time() - iLastRecordTime))
    return ( iCurOnlineTime < 0 )or (iNeedTime <= (iOnlineTime + (get_time() - iLastRecordTime)))
end

function CHuodong:GetConfigData(iReward)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["onlinegift"][iReward]
    assert(mData,string.format("CHuodong:GetRewardData err:%s %d", self.m_sName, iReward))
    return mData
end

function CHuodong:SetReward(oPlayer,iRewardId)
    self:Dirty()
    local iBit = 1 << (iRewardId - 1)
    local mOnlineGift = oPlayer.m_oToday:Query("onlinegift",{})
    local iRewardStatus = mOnlineGift["status"] or 0
    local iBitStatus = iRewardStatus | iBit
    mOnlineGift["status"] = iBitStatus
    local iOnlineTime = mOnlineGift["onlinetime"] or 0
    local iLastRecordTime = mOnlineGift["lastrecordtime"] or oPlayer.m_oActiveCtrl:GetData("login_time",0)
    iOnlineTime = (get_time() - iLastRecordTime) + iOnlineTime
    mOnlineGift["onlinetime"] = iOnlineTime
    mOnlineGift["lastrecordtime"] = get_time()
    oPlayer.m_oToday:Set("onlinegift",mOnlineGift)
    oPlayer.m_oToday:Set("onlinetime",iOnlineTime)
    oPlayer:Send("GS2COnlineGiftStatus",{status = iBitStatus})
    record.user("onlinegift","reset",{pid = oPlayer.m_iPid,status = mOnlineGift["status"] or 0,onlinetime=mOnlineGift["onlinetime"] or 0,lastrecordtime=mOnlineGift["lastrecordtime"] or 0,reason = "reward"})
end

function CHuodong:GMNewDay(oPlayer)
    local mOnlineGift = {status = 0,onlinetime = 0,lastrecordtime = get_time(),reward = {}}
    oPlayer.m_oToday:Set("onlinegift",mOnlineGift)
    oPlayer.m_oToday:Set("onlinetime",0)
    oPlayer:Send("GS2COnlineGift",{status = 0,onlinetime = 0})
end
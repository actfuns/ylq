--伙伴游历数据
local skynet = require "skynet"
local global = require "global"
local interactive = require "base.interactive"
local extend = require "base/extend"
local record = require "public.record"

local defines = import(service_path("offline.defines"))
local datactrl = import(lualib_path("public.datactrl"))
local loadpartner = import(service_path("partner.loadpartner"))
local CBaseOfflineCtrl = import(service_path("offline.baseofflinectrl")).CBaseOfflineCtrl

CTravelCtrl = {}
CTravelCtrl.__index = CTravelCtrl
inherit(CTravelCtrl, CBaseOfflineCtrl)

function CTravelCtrl:New(iPid)
    local o = super(CTravelCtrl).New(self, iPid)
    o.m_sDbFlag = "Travel"
    o.m_mTravel = {}
    o.m_mFrdInvite = {}
    o.m_mTravelContent = {} --游记内容
    o.m_mMineInvite = {} --发出邀请
    o.m_mReward = {} --奖励
    o.m_iTravelStatus = 0 --游历状态
    o.m_iStartTime = 0
    o.m_iEndTime = 0
    o.m_iTravelCnt = 0 --游历获取奖励次数
    o.m_iGapSec = 15 * 60 --游历间隔
    o.m_iTravelType = 0 --游历类型
    o.m_oFrdTravel = nil
    o.m_oMineTravel = nil
    o.m_oSpeedItem = nil
    o.m_iGamePush = 0
    return o
end

function CTravelCtrl:Save()
    local mData = {}
    local mTravel = {}
    for iPos, o in pairs(self.m_mTravel) do
        mTravel[db_key(iPos)] = o:Save()
    end
    mData["travel"] = mTravel
    local mFrdInvite = {}
    for iFrdPid, m in pairs(self.m_mFrdInvite) do
        mFrdInvite[db_key(iFrdPid)] = m
    end
    mData["frd_invite"] = mFrdInvite
    local mMineInvite = {}
    for iFrdPid, iTime in pairs(self.m_mMineInvite) do
        mMineInvite[db_key(iFrdPid)] = iTime
    end
    mData["mine_invite"] = mMineInvite
    local mReward = {}
    for sid, iVal in pairs(self.m_mReward) do
        mReward[db_key(sid)] = iVal
    end
    mData["travel_reward"] = mReward

    mData["travel_content"] = self.m_mTravelContent
    mData["travel_status"] = self.m_iTravelStatus
    mData["start_time"] = self.m_iStartTime
    mData["end_time"] = self.m_iEndTime
    mData["travel_cnt"] = self.m_iTravelCnt
    mData["gap_second"] = self.m_iGapSec
    mData["travel_type"] = self.m_iTravelType
    if self.m_oFrdTravel then
        mData["frd_travel"] = self.m_oFrdTravel:Save()
    end
    if self.m_oMineTravel then
        mData["mine_travel"] = self.m_oMineTravel:Save()
    end
    if self.m_oSpeedItem then
        mData["speed_item"] = self.m_oSpeedItem:Save()
    end
    mData["game_push"] = self.m_iGamePush
    return mData
end

function CTravelCtrl:Load(mData)
    mData = mData or {}
    local iPid = self:GetPid()
    local mTravel = mData["travel"] or {}
    for sPos, m in pairs(mTravel) do
        local iPos = tonumber(sPos)
        local o = CTravelPartner:New(iPid)
        o:Init(m)
        self.m_mTravel[iPos] = o
    end

    local mFrdInvite = mData["frd_invite"] or {}
    for sFrdPid, m in pairs(mFrdInvite) do
        local iFrdPid = tonumber(sFrdPid)
        self.m_mFrdInvite[iFrdPid] = m
    end

    local mMineInvite = mData["mine_invite"] or {}
    for sFrdPid, iTime in pairs(mMineInvite) do
        local iFrdPid = tonumber(sFrdPid)
        self.m_mMineInvite[iFrdPid] = iTime
    end

    local mReward = mData["travel_reward"] or {}
    for sSid, iVal in pairs(mReward) do
        mReward[sSid] = iVal
    end
    self.m_mReward =mReward

    self.m_mTravelContent = mData["travel_content"] or {}
    self.m_iTravelStatus = mData["travel_status"] or 0
    self.m_iStartTime = mData["start_time"] or 0
    self.m_iEndTime = mData["end_time"] or 0
    self.m_iTravelCnt = mData["travel_cnt"] or 0
    self.m_iGapSec = mData["gap_second"] or self.m_iGapSec
    self.m_iTravelType = mData["travel_type"] or 0
    self.m_iGamePush = mData["game_push"] or 0
    local mSpeedItem = mData["speed_item"] or {}
    if next(mSpeedItem) then
        local oSpeedItem = CSpeedItem:New(iPid)
        oSpeedItem:Init(mSpeedItem)
        self.m_oSpeedItem = oSpeedItem
    end

    local mFrdTravel = mData["frd_travel"] or {}
    if next(mFrdTravel) then
        local iFrdPid = mFrdTravel["frd_pid"]
        if iFrdPid then
            local oFrdPartner = CFrdTravel:New(iPid, iFrdPid)
            oFrdPartner:Init(mFrdTravel)
            self.m_oFrdTravel = oFrdPartner
        end
    end

    local mMineTravel = mData["mine_travel"] or {}
    if next(mMineTravel) then
        local iFrdPid = mMineTravel["frd_pid"]
        if iFrdPid then
            local oMineTravel = CMineTravel:New(iPid, iFrdPid)
            oMineTravel:Init(mMineTravel)
            self.m_oMineTravel = oMineTravel
        end
    end
end

function CTravelCtrl:OnLogin(oPlayer, bReEnter)
    self:PreCheck(oPlayer, bReEnter)
    self:CheckMineTravel()
    local mNet = {}
    mNet["travel_partner"] = self:PackTravelInfoNet()
    mNet["pos_info"] = self:PackTravelPos()
    if self.m_oSpeedItem then
        mNet["item_info"] = self.m_oSpeedItem:PackNetInfo()
    end
    local lNet = {}
    for _, m in ipairs(self.m_mTravelContent) do
        table.insert(lNet, table_deep_copy(m))
    end
    mNet["travel_content"] = lNet
    lNet = {}
    for iFrdPid, iTime in pairs(self.m_mMineInvite) do
        table.insert(lNet, self:PackMineInvite(iFrdPid))
    end
    mNet["mine_invite"] = lNet
    oPlayer:Send("GS2CLoginTravelPartner", mNet)
    self:GS2CMineTravelPartnerInfo()
    self:GS2CFrdTravelPartnerInfo()
end

function CTravelCtrl:PreCheck(oPlayer, bReEnter)
    -- self:CheckSpeedItem()
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:PreCheck(self, bReEnter)
    end
end

function CTravelCtrl:OnLogout()
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:OnLogout(self)
    end
end

function CTravelCtrl:IsDirty()
    local bDirty = super(CTravelCtrl).IsDirty(self)
    if bDirty then
        return true
    end
    if self.m_oSpeedItem and self.m_oSpeedItem:IsDirty() then
        return true
    end
    if self.m_oFrdTravel and self.m_oFrdTravel:IsDirty() then
        return true
    end
    if self.m_oMineTravel and self.m_oMineTravel:IsDirty() then
        return true
    end
    return false
end

function CTravelCtrl:SpeedItem()
    return self.m_oSpeedItem
end

function CTravelCtrl:FrdTravelPartner()
    return self.m_oFrdTravel
end

function CTravelCtrl:MineTravelPartner()
    return self.m_oMineTravel
end

function CTravelCtrl:TravelPartners()
    return self.m_mTravel
end

function CTravelCtrl:TravelPartner(iPos)
    return  self.m_mTravel[iPos]
end

function CTravelCtrl:EndTime()
    return self.m_iEndTime
end

function CTravelCtrl:StartTime()
    return self.m_iStartTime
end

function CTravelCtrl:GapSec()
    return self.m_iGapSec
end

function CTravelCtrl:TravelType()
    return self.m_iTravelType or 0
end

function CTravelCtrl:SetTravelType(iType)
    self:Dirty()
    iType = iType or 0
    self.m_iTravelType = iType
end

function CTravelCtrl:TravelStart(iStartTime, iEndTime, iGapSec)
    self:Dirty()
    self.m_iStartTime = iStartTime
    self.m_iEndTime = iEndTime
    self.m_iGapSec = iGapSec
    self.m_iTravelStatus = 1
    self:ClearReward()
    self:ClearTravelConent()
    self:GS2CTravelPartnerInfo()
    self:GS2CClearTravelContent()
end

function CTravelCtrl:TravelCnt()
    return self.m_iTravelCnt
end

function CTravelCtrl:AddCnt(iAdd, sReason)
    self:Dirty()
    self.m_iTravelCnt = self.m_iTravelCnt + iAdd
end

function CTravelCtrl:MaxTravelCnt()
    local iSecs = self:EndTime() - self:StartTime()
    return iSecs // self.m_iGapSec
end

function CTravelCtrl:NowTravelCnt()
    local iNow = get_time()
    local iEndTime = math.min(iNow, self:EndTime())
    local iSecs = iEndTime - self:StartTime()
    return iSecs // self.m_iGapSec
end

function CTravelCtrl:ClearTravelCnt()
    self:Dirty()
    self.m_iTravelCnt = 0
end

function CTravelCtrl:TravelEnd(bRefresh)
    self:Dirty()
    self:RemoveFrdTravel(true)
    self.m_iStartTime = 0
    self.m_iEndTime = 0
    self.m_iTravelStatus = 0
    self.m_iTravelCnt = 0
    if bRefresh then
        self:GS2CTravelPartnerInfo()
    end
end

function CTravelCtrl:SyncTravelPartner(lInfo)
    for _, m in ipairs(lInfo) do
        self:RemoveTravelPartner(m.pos)
    end
    local iPid = self:GetPid()
    for _, m in ipairs(lInfo) do
        if m.parid > 0 then
            -- local oPartner = loadpartner.NewPartner(iPid, m.data)
            local o = CTravelPartner:New(iPid)
            o:Init(m.data)
            self:AddTravelPartner(m.pos, o)
        end
    end
    self:GS2CTravelPartnerPos()
end

function CTravelCtrl:UpdateTravelPartner(iPos, mData)
    if not mData.key then
        return
    end
    if iPos < 5 then
        local oPartner = self:TravelPartner(iPos)
        if oPartner then
            oPartner:SetData(mData.key, mData.value)
            self:SendPartnerInfo(oPartner, iPos)
        end
    elseif iPos == 5 then
        if self.m_oMineTravel then
            self.m_oMineTravel:SetData(mData.key, mData.value)
            self:SendPartnerInfo(self.m_oMineTravel, iPos)
            local iPos = 6
            local iFrdPid = self.m_oMineTravel:FrdPid()
            local oWorldMgr = global.oWorldMgr
            oWorldMgr:LoadTravel(iFrdPid, function(oFrdTravel)
                oFrdTravel:UpdateTravelPartner(iPos, mData)
            end)
        end
    elseif iPos == 6 then
            if self.m_oFrdTravel then
                self.m_oFrdTravel:SetData(mData.key, mData.value)
                self:SendPartnerInfo(self.m_oFrdTravel, iPos)
            end
    end
end

function CTravelCtrl:RemoveTravelPartner(iPos)
    self:Dirty()
    self.m_mTravel[iPos] = nil
end

function CTravelCtrl:AddTravelPartner(iPos, oPartner)
    self:Dirty()
    self.m_mTravel[iPos] = oPartner
end

function CTravelCtrl:IsTravel()
    return self.m_iTravelStatus == 1
end

function CTravelCtrl:HasTravelPartner()
    if next(self.m_mTravel) then
        return true
    end
    return false
end

function CTravelCtrl:HasMineTravel()
    if self.m_oMineTravel then
        return true
    end
    return false
end

function CTravelCtrl:HasFrdTravel()
    if self.m_oFrdTravel then
        return true
    end
    return false
end

function CTravelCtrl:IsSpeeding()
    if self.m_oSpeedItem then
        return true
    end
    return false
end

function CTravelCtrl:FrdInvites()
    return self.m_mFrdInvite
end

function CTravelCtrl:FrdInvite(iFrdPid)
    return self.m_mFrdInvite[iFrdPid]
end

function CTravelCtrl:AddFrdInvite(iFrdPid, mInvite)
    self:Dirty()
    self.m_mFrdInvite[iFrdPid] = mInvite

    local oWorldMgr = global.oWorldMgr
    local f1
    local iPid = self:GetPid()
    f1 = function(oTravel, oProfile)
         local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
         if oPlayer and oTravel and oProfile then
            local o = oPlayer:GetTravel()
            self:SendAddTravel(oPlayer, o:PackFrdInvite(iPid, oTravel, oProfile))
         end
    end
    self:LoadTravelAndProfile(iFrdPid, f1)
end

function CTravelCtrl:RemoveFrdInvite(iFrdPid)
    self:Dirty()
    self.m_mFrdInvite[iFrdPid] = nil
    self:GS2CDelTravelInvite(iFrdPid)
end

function CTravelCtrl:AddMineInvite(iFrdPid, iTime)
    self:Dirty()
    self.m_mMineInvite[iFrdPid] = iTime or get_time()
end

function CTravelCtrl:RemoveMineInvite(iFrdPid)
    self:Dirty()
    self.m_mMineInvite[iFrdPid] = nil
end

function CTravelCtrl:ClearFrdInvite()
    self:Dirty()
    self.m_mFrdInvite = {}
    self:GS2CClearTravelInvite()
end

function CTravelCtrl:ClearReward()
    self:Dirty()
    -- for iPos, oPartner in pairs(self.m_mTravel) do
    --     oPartner:ClearReward()
    -- end
    self.m_mReward = {}
    for iPos , oPartner in pairs(self.m_mTravel) do
        oPartner:ClearExp()
    end
end

function CTravelCtrl:ClearTravelConent()
    self:Dirty()
    self.m_mTravelContent = {}
end

function CTravelCtrl:PackInviteNet(iFrdPid)
    local mInvite = self.m_mFrdInvite[iFrdPid]
    local mNet = {}
    if mInvite then
        mNet =  {
            frd_pid = iFrdPid,
            frd_name = mInvite["frd_name"],
            frd_shape = mInvite["frd_shape"],
            invite_time = mInvite["invite_time"],
            invite_content = mInvite["invite_content"],
        }
    end
    return mNet
end

function CTravelCtrl:PackMineInvite(iFrdPid)
    local iInviteTime = self.m_mMineInvite[iFrdPid] or 0
    return {
        frd_pid =iFrdPid,
        invite_time = iInviteTime,
    }
end

function CTravelCtrl:Rewardable()
    if next(self.m_mReward) then
        return true
    end
    for iPos, oPartner in pairs(self.m_mTravel) do
        if oPartner:Rewardable() then
            return true
        end
    end
    return  false
end

function CTravelCtrl:AddTravelReward(mRwd)
    self:Dirty()
    mRwd = mRwd or {}
    for sid, iVal in pairs(mRwd) do
        sid = tostring(sid)
        local iHave = self.m_mReward[sid] or 0
        self.m_mReward[sid] = iHave + iVal
    end
end

function CTravelCtrl:AddTravelPartnerExp(mExp)
    self:Dirty()
    mExp = mExp or {}
    for iPos, iExp in pairs(mExp) do
        if iPos == 0 then
            if self.m_oFrdTravel then
                global.oWorldMgr:LoadTravel(self.m_oFrdTravel:FrdPid(), function(oFrdTravel)
                    oFrdTravel:AddMineTravelExp(iExp)
                end)
            end
        else
            local oPartner = self:TravelPartner(iPos)
            if oPartner then
                oPartner:AddExp(iExp)
            end
        end
    end
end

function CTravelCtrl:AddMineTravelExp(iExp)
    self:Dirty()
    if self.m_oMineTravel then
        self.m_oMineTravel:AddExp(iExp)
    end
end

function CTravelCtrl:ClearTravelPartnerExp()
    self:Dirty()
    for iPos, oPartner in pairs(self.m_mTravel) do
        oPartner:ClearExp()
    end
end

function CTravelCtrl:TravelRewardInfo()
    return self.m_mReward or {}
end

function CTravelCtrl:AddTravelContent(lContents)
    self:Dirty()
    list_combine(self.m_mTravelContent, lContents)
    -- self:GS2CAddTravelContent(mContent)
end

function CTravelCtrl:AddSpeedItem(mData, bRefresh)
    self:Dirty()
    local oSpeedItem = CSpeedItem:New(iPid)
    oSpeedItem:Init(mData)
    self.m_oSpeedItem = oSpeedItem
    self:GS2CTravelItemInfo()
end

function CTravelCtrl:RemoveSpeedItem(bRefresh)
    if self.m_oSpeedItem then
        self:Dirty()
        baseobj_safe_release(self.m_oSpeedItem)
        self.m_oSpeedItem = nil
    end
    if bRefresh then
        self:GS2CDelTravelItem()
    end
end

function CTravelCtrl:CheckSpeedItem()
    if self.m_oSpeedItem then
        if self.m_oSpeedItem:TimeOut() then
            self:RemoveSpeedItem()
        end
    end
end

function CTravelCtrl:AddFrdTravel(iFrdPid, mPartner)
    local iPid = self:GetPid()
    local oFrdPartner = CFrdTravel:New(iPid, iFrdPid)
    oFrdPartner:Init(mPartner)
    self.m_oFrdTravel = oFrdPartner

    --pid|玩家id,travel_type|游历类型,friend_pid|寄存好友pid,partnerid|寄存伙伴的id
    local mLog = {
        pid = iPid,
        friend_pid = iFrdPid,
        travel_type = self:TravelType(),
        partnerid = oFrdPartner:ParId(),
    }
    record.user("travel", "friend_travel_mine", mLog)
end

function CTravelCtrl:RemoveFrdTravel(bRefresh)
    if self.m_oFrdTravel then
        self:Dirty()
        local oWorldMgr = global.oWorldMgr
        local iFrdPid = self.m_oFrdTravel:FrdPid()
        oWorldMgr:LoadTravel(iFrdPid, function (oTravel)
            oTravel:MineTravelFinish()
        end)
        if bRefresh then
            self:GS2CDelFrdTravel()
        end
        baseobj_safe_release(self.m_oFrdTravel)
        self.m_oFrdTravel = nil
    end
end

function CTravelCtrl:CheckMineTravel()
    local oWorldMgr = global.oWorldMgr
    if self.m_oMineTravel then
        local iFrdPid = self.m_oMineTravel:FrdPid()
        if self.m_oMineTravel:TimeOut() then
            local oTarget = oWorldMgr:GetOnlinePlayerByPid(iFrdPid)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
            if oPlayer and not oTarget then
                oWorldMgr:LoadTravel(iFrdPid, function(oFrdTravel)
                    oFrdTravel:PreCheck(false)
                end)
            end
        else
            local iSecs = self.m_oMineTravel:EndTime() - get_time()
            self:AddMineTraveTimer(iFrdPid, iSecs)
        end
    end
end

function CTravelCtrl:AddMineTraveTimer(iFrdPid, iSecs)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetPid()
    if iSecs > 0 then
        self:DelTimeCb("TravelFinish")
        self:AddTimeCb("TravelFinish", iSecs * 1000, function()
            local oTarget = oWorldMgr:GetOnlinePlayerByPid(iFrdPid)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer and not oTarget then
                oWorldMgr:LoadTravel(iFrdPid, function(oFrdTravel)
                    oFrdTravel:PreCheck(false)
                    -- oFrdTravel:RemoveFrdTravel(false)
                end)
            end
        end)
    end
end

--Mine Travel
function CTravelCtrl:AddMineTravel(iFrdPid, mData)
    local oWorldMgr = global.oWorldMgr
    self:Dirty()
    local oMineTravel = CMineTravel:New(self:GetPid(), iFrdPid)
    oMineTravel:Init(mData)
    self.m_oMineTravel = oMineTravel
    local iEndSecs = oMineTravel:EndTime() - oMineTravel:StartTime()
    self:AddMineTraveTimer(iFrdPid, iEndSecs)

    --pid|玩家id,travel_type|游历类型,friend_pid|寄存好友pid,partnerid|寄存伙伴的id
    local mLog = {
        pid = self:GetPid(),
        friend_pid = iFrdPid,
        travel_type = self:TravelType(),
        partnerid = oMineTravel:ParId(),
    }
    record.user("travel", "mine_travel_friend", mLog)
end

function CTravelCtrl:MineTravelFinish()
    if self.m_oMineTravel then
        self:Dirty()
        self.m_oMineTravel:TravelFinish()
        self:GS2CMineTravelPartnerInfo()
    end
end

function CTravelCtrl:RemoveMineTravel()
    if self.m_oMineTravel then
        self:Dirty()
        local iParId = self.m_oMineTravel:ParId()
        baseobj_safe_release(self.m_oMineTravel)
        self.m_oMineTravel = nil
        return iParId
    end
end

function CTravelCtrl:AddMineTravelReward(mRwd)
    -- if self.m_oMineTravel then
    --     self.m_oMineTravel:AddReward(mRwd)
    -- end
end

function CTravelCtrl:MineTravelReward()
    if self.m_oMineTravel then
        return self.m_oMineTravel:RewardInfo()
    end
end

function CTravelCtrl:QueryFrdInvite()
    local oWorldMgr = global.oWorldMgr
    local iCount = table_count(self.m_mFrdInvite)
    local mHandle = {
        list = {},
        is_send = false,
        count = iCount,
    }
    local iPid = self:GetPid()
    local f1
    f1 = function(oTravel, oProfile)
        local o = oWorldMgr:GetTravel(iPid)
        if o then
            if not oTravel or not oProfile then
                mHandle.count = mHandle.count - 1
                o:_JudgeSend(iPid, mHandle, o.SendFrdInvite)
            else
                o:_HandleQueryInvite(iPid,oTravel, oProfile, mHandle, o.SendFrdInvite)
            end
        end
    end
    if iCount == 0 then
        self:_JudgeSend(iPid, mHandle, self.SendFrdInvite)
    else
        for iFrdPid, _ in pairs(self.m_mFrdInvite) do
            self:LoadTravelAndProfile(iFrdPid, f1)
        end
    end
end

function CTravelCtrl:LoadTravelAndProfile(iFrdPid, func)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iFrdPid, function (o)
        oWorldMgr:LoadTravel(iFrdPid, function (oTravel)
            local oProfile = oWorldMgr:GetProfile(iFrdPid)
            func(oTravel, oProfile)
            end)
    end)

end

function CTravelCtrl:_HandleQueryInvite(iPid, oTravel, oProfile, mHandle, sendfunc)
    mHandle.count = mHandle.count - 1
    local mInvite = self:FrdInvite(oProfile:GetPid())
    if mInvite then
        table.insert(mHandle.list, self:PackFrdInvite(iPid, oTravel, oProfile))
    end
    self:_JudgeSend(iPid, mHandle, sendfunc)
end

function CTravelCtrl:_JudgeSend(iPid, mHandle, sendfunc)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer and mHandle.count <= 0 and not mHandle.is_send then
        if sendfunc then
            sendfunc(self, oPlayer, mHandle.list)
        end
        mHandle.is_send = true
    end
end

function CTravelCtrl:SendFrdInvite(oPlayer, invites)
    oPlayer:Send("GS2CInviteInfoList", {invites = invites})
end

function CTravelCtrl:SendAddTravel(oPlayer, info)
    oPlayer:Send("GS2CAddTravelInvite", {travel_invite = info})
end

function CTravelCtrl:PackFrdInvite(iPid, oTarget, oProfile)
    local mInvite = self:FrdInvite(oTarget:GetPid())
    local mNet = {}
    mNet["frd_pid"] = oProfile:GetPid()
    mNet["frd_name"] = oProfile:GetName()
    mNet["frd_shape"] = oProfile:GetShape()
    mNet["invite_content"] = mInvite.invite_content
    mNet["invite_time"] = mInvite.invite_time
    mNet["travel"] = 0
    if oTarget:IsTravel() then
        mNet["travel"] = 1
        if oTarget:HasFrdTravel() then
            mNet["frd_travel"] = 1
        end
        mNet["end_time"] = oTarget:EndTime()
    end
    return mNet
end

function CTravelCtrl:PackTravelInfoNet()
    local mNet = {}
    mNet["status"] = self.m_iTravelStatus
    mNet["start_time"] = self.m_iStartTime
    mNet["end_time"] = self.m_iEndTime
    mNet["server_time"] = get_time()
    mNet["reward"] =  0
    if self:Rewardable() then
        mNet["reward"] =  1
    end
    return mNet
end

function CTravelCtrl:PackTravelPos()
    local lNet = {}
    for iPos, oPartner in pairs(self.m_mTravel) do
        table.insert(lNet, {
            pos = iPos,
            parid = oPartner:ParId(),
            par_name = oPartner:ParName(),
            par_grade = oPartner:ParGrade(),
            par_model = oPartner:ParModel(),
            par_star = oPartner:ParStar(),
            par_awake = oPartner:ParAwake(),
            })
    end
    return lNet
end

function CTravelCtrl:PackTravelPartner()
    local lNet = {}
    for iPos, oPartner in pairs(self.m_mTravel) do
        local m = oPartner:PackNetInfo()
        m.pos = iPos
        table.insert(lNet, m)
    end
    return lNet
end

function CTravelCtrl:SendFrdTravelInfo(oPlayer)
    if oPlayer then
        local mNet = {}
        mNet["travel_partner"] = self:PackTravelInfoNet()
        mNet["pos_partner"] = self:PackTravelPos()
        if self.m_oSpeedItem then
            mNet["item_info"] = self.m_oSpeedItem:PackNetInfo()
        end
        mNet["frd_pid"] = self:GetPid()
        if self.m_oFrdTravel then
            mNet["frd_partner"] = self.m_oFrdTravel:PackNetInfo()
        end
        oPlayer:Send("GS2CFrdTravelList", mNet)
    end
end

function CTravelCtrl:SendPartnerInfo(oPartner, iPos)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        local mNet = oPartner:PackParInfo()
        mNet.pos = iPos
        oPlayer:Send("GS2CUpdateTravelPartner", {parinfo = mNet})
    end
end

function CTravelCtrl:GS2CTravelPartnerPos()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CTravelPartnerPos", {pos_info = self:PackTravelPos()})
    end
end

function CTravelCtrl:GS2CTravelItemInfo(iStatus)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        if self.m_oSpeedItem then
            local mNet = {}
            mNet["item_info"] = self.m_oSpeedItem:PackNetInfo()
            oPlayer:Send("GS2CTravelItemInfo", mNet)
        end
    end
end

function CTravelCtrl:GS2CDelTravelItem()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CDelTravelItem", {})
    end
end

function CTravelCtrl:GS2CFrdTravelPartnerInfo()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        local mNet = {}
        if self.m_oFrdTravel then
            oPlayer:Send("GS2CFrdTravelPartnerInfo",{frd_partner = self.m_oFrdTravel:PackNetInfo()})
        end
    end
end

function CTravelCtrl:GS2CDelFrdTravel()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CDelFrdTravel", {})
    end
end

function CTravelCtrl:GS2CMineTravelPartnerInfo()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        if self.m_oMineTravel then
            oPlayer:Send("GS2CMineTravelPartnerInfo", self.m_oMineTravel:PackNetInfo())
        end
    end
end

function CTravelCtrl:GS2CDelMineTravel()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CDelMineTravel", {})
    end
end

function CTravelCtrl:GS2CAddTravelInvite(iFrdPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        local mInvite = self.m_mFrdInvite[iFrdPid]
        if mInvite then
            oPlayer:Send("GS2CAddTravelInvite", {travel_invite = self:PackInviteNet(iFrdPid)})
        end
    end
end

function CTravelCtrl:GS2CDelTravelInvite(iFrdPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CDelTravelInvite", {frd_pid = iFrdPid})
    end
end

function CTravelCtrl:GS2CClearTravelInvite()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CClearTravelInvite", {})
    end
end

function CTravelCtrl:GS2CAddTravelContent(lContents)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CAddTravelContent", {travel_content = lContents})
    end
end

function CTravelCtrl:GS2CTravelPartnerInfo()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CTravelPartnerInfo", {travel_partner = self:PackTravelInfoNet()})
    end
end

function CTravelCtrl:GS2CClearTravelContent()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CClearTravelContent", {})
    end
end

function CTravelCtrl:SetGamePush(iValue)
    self:Dirty()
    self.m_iGamePush = iValue
end

function CTravelCtrl:IsGamePush()
    if self.m_iGamePush == 0 then
        return false
    end
    return true
end


CSpeedItem = {}
CSpeedItem.__index = CSpeedItem
inherit(CSpeedItem, datactrl.CDataCtrl)

function CSpeedItem:New(iPid)
    local o = super(CSpeedItem).New(self,{pid = iPid})
    return o
end

function CSpeedItem:Init(mData)
    self:SetData("sid", mData["sid"])
    self:SetData("start_time", mData["start_time"])
    self:SetData("end_time", mData["end_time"])
    self.m_mApply = mData["apply"] or {}
end

function CSpeedItem:Save()
    local mData = {}
    mData["sid"] = self:SID()
    mData["start_time"] = self:StartTime()
    mData["end_time"] = self:EndTime()
    mData["apply"] = self.m_mApply

    return mData
end

function CSpeedItem:TimeOut()
    return get_time() >= self:EndTime()
end

function CSpeedItem:SID()
    return self:GetData("sid")
end

function CSpeedItem:StartTime()
    return self:GetData("start_time")
end

function CSpeedItem:EndTime()
    return self:GetData("end_time", 0)
end

function CSpeedItem:GetExpSpeed()
    return self.m_mApply["exp"] or 0
end

function CSpeedItem:GetCoinSpeed()
    return self.m_mApply["coin"] or 0
end

function CSpeedItem:PackNetInfo()
    return {
        sid = self:SID(),
        start_time = self:StartTime(),
        end_time = self:EndTime(),
        server_time = get_time(),
    }
end

function CSpeedItem:PackTravelInfo()
    return {
        sid = self:SID(),
        coin_speed = self:GetCoinSpeed(),
        exp_speed = self:GetExpSpeed(),
    }
end

CFrdTravel = {}
CFrdTravel.__index = CFrdTravel
inherit(CFrdTravel, datactrl.CDataCtrl)

function CFrdTravel:New(iPid, iFrdPid)
    local o = super(CFrdTravel).New(self, {pid = iPid})
    o:SetData("frd_pid", iFrdPid)
    return o
end

function CFrdTravel:Init(mData)
    self:SetData("parid", mData["parid"])
    self:SetData("frd_name", mData["frd_name"])
    self:SetData("par_name", mData["par_name"])
    self:SetData("par_model", mData["par_model"] or {})
    self:SetData("par_grade", mData["par_grade"] or 0)
    self:SetData("start_time", mData["start_time"])
    self:SetData("end_time", mData["end_time"])
    self:SetData("par_star", mData["par_star" or 1])
    self:SetData("par_awake", mData["par_awake"] or 0)
end

function CFrdTravel:Save()
    local mData = {
        frd_pid = self:FrdPid(),
        parid = self:ParId(),
        frd_name = self:FrdName(),
        par_name = self:ParName(),
        par_grade = self:ParGrade(),
        start_time = self:StartTime(),
        end_time = self:EndTime(),
        par_model = self:ParModel(),
        par_star = self:ParStar(),
        par_awake = self:ParAwake(),
    }
    return mData
end

function CFrdTravel:ParId()
    return self:GetData("parid")
end

function CFrdTravel:FrdName()
    return self:GetData("frd_name")
end

function CFrdTravel:ParName()
    return self:GetData("par_name")
end

function CFrdTravel:ParGrade()
    return self:GetData("par_grade")
end

function CFrdTravel:ParModel()
    return self:GetData("par_model")
end

function CFrdTravel:StartTime()
    return self:GetData("start_time")
end

function CFrdTravel:EndTime()
    return self:GetData("end_time")
end

function CFrdTravel:FrdPid()
    return self:GetData("frd_pid")
end

function CFrdTravel:ParStar()
    return self:GetData("par_star", 1)
end

function CFrdTravel:ParAwake()
    return self:GetData("par_awake", 0)
end

function CFrdTravel:PackNetInfo()
    return {
        frd_pid = self:FrdPid(),
        frd_name = self:FrdName(),
        start_time = self:StartTime(),
        end_time = self:EndTime(),
        server_time = get_time(),
        parinfo = self:PackParInfo(),
    }
end

function CFrdTravel:PackTravelInfo()
    return {
        parid = self:ParId(),
        par_name = self:ParName(),
        par_grade = self:ParGrade(),
    }
end

function CFrdTravel:PackParInfo()
    return {
            parid = self:ParId(),
            pos = 6,
            par_name = self:ParName(),
            par_grade = self:ParGrade(),
            par_model = self:ParModel(),
            par_star = self:ParStar(),
            par_awake = self:ParAwake(),
    }
end


CMineTravel = {}
CMineTravel.__index = CMineTravel
inherit(CMineTravel, datactrl.CDataCtrl)

function CMineTravel:New(iPid, iFrdPid)
    local o = super(CMineTravel).New(self, {pid = iPid})
    o:SetData("frd_pid", iFrdPid)
    return o
end

function CMineTravel:Init(mData)
    self:SetData("parid", mData["parid"])
    self:SetData("par_name", mData["par_name"])
    self:SetData("frd_name", mData["frd_name"])
    self:SetData("par_grade", mData["par_grade"])
    self:SetData("start_time", mData["start_time"])
    self:SetData("end_time", mData["end_time"])
    self:SetData("recieve_status", mData["recieve_status"] or 0)
    self:SetData("par_star", mData["par_star"] or 1)
    self:SetData("par_awake", mData["par_awake"] or 0)
    self:SetData("par_model", mData["par_model"] or {})
    self.m_iAddExp = mData["add_exp"] or 0
end

function CMineTravel:Save()
    local mData = {
        frd_pid = self:FrdPid(),
        parid = self:ParId(),
        par_name = self:ParName(),
        par_grade = self:ParGrade(),
        start_time = self:StartTime(),
        end_time = self:EndTime(),
        recieve_status = self:RecieveStatus(),
        add_exp = self.m_iAddExp,
        par_star = self:ParStar(),
        par_awake = self:ParAwake(),
        par_model = self:ParModel(),
    }
    return mData
end

function CMineTravel:ParId()
    return self:GetData("parid")
end

function CMineTravel:ParGrade()
    return self:GetData("par_grade")
end

function CMineTravel:ParName()
    return self:GetData("par_name")
end

function CMineTravel:StartTime()
    return self:GetData("start_time")
end

function CMineTravel:EndTime()
    return self:GetData("end_time")
end

function CMineTravel:FrdPid()
    return self:GetData("frd_pid")
end

function CMineTravel:RecieveStatus()
    return self:GetData("recieve_status")
end

function CMineTravel:Exp()
    return self.m_iAddExp
end

function CMineTravel:ParStar()
    return self:GetData("par_star", 1)
end

function CMineTravel:ParAwake()
    return self:GetData("par_awake", 0)
end

function CMineTravel:ParModel()
    return self:GetData("par_model")
end

function CMineTravel:Recievable()
    return self:RecieveStatus() == 1
end

function CMineTravel:TravelFinish()
    self:SetData("recieve_status", 1)
end

function CMineTravel:AddReward(mRwd)
    -- self:Dirty()
    -- for sType, iVal in pairs(mRwd) do
    --     local iHave = self.m_mReward[sType] or 0
    --     self.m_mReward[sType] = iHave + iVal
    -- end
end

function CMineTravel:AddExp(iExp)
    self:Dirty()
    iExp = iExp or 0
    self.m_iAddExp = self.m_iAddExp + iExp
end

function CMineTravel:RewardInfo()
    return table_copy(self.m_mReward)
end

function CMineTravel:ClearReward()
    self:Dirty()
    self.m_mReward = {}
end

function CMineTravel:TimeOut()
    return self:EndTime() <= get_time()
end

function CMineTravel:PackNetInfo()
    return {
        frd_pid = self:FrdPid(),
        parinfo = self:PackParInfo(),
        start_time = self:StartTime(),
        end_time = self:EndTime(),
        server_time = get_time(),
        recieve_status = self:RecieveStatus(),
    }
end

function CMineTravel:PackParInfo()
    return {
            parid = self:ParId(),
            pos = 5,
            par_name = self:ParName(),
            par_grade = self:ParGrade(),
            par_model = self:ParModel(),
            par_star = self:ParStar(),
            par_awake = self:ParAwake(),
    }
end


CTravelPartner = {}
CTravelPartner.__index = CTravelPartner
inherit(CTravelPartner, datactrl.CDataCtrl)

function CTravelPartner:New(iPid)
    local o = super(CTravelPartner).New(self, {pid = iPid})
    return o
end

function CTravelPartner:Init(mData)
    self:SetData("parid", mData["parid"])
    self:SetData("par_grade", mData["par_grade"])
    self:SetData("par_name", mData["par_name"])
    self:SetData("par_model", mData["par_model"] or {})
    self:SetData("par_star", mData["par_star"] or 1)
    self:SetData("par_awake", mData["par_awake"] or 0)
    self.m_iAddExp = mData["add_exp"] or 0

    -- local mReward = mData["reward"] or {}
    -- local lKey = {"partnerexp", "coin"}
    -- for sKey, iVal in pairs(mReward) do
    --     if table_in_list(lKey, sKey) then
    --         mReward[sKey] = iVal
    --     else
    --         local iKey = tonumber(sKey)
    --         mReward[iKey] = iVal
    --     end
    -- end
    -- self.m_mReward = mReward
end

function CTravelPartner:Save()
    -- local mReward = {}
    -- for key, iVal in pairs(self.m_mReward) do
    --     mReward[db_key(key)] = iVal
    -- end
    local mData = {
        parid = self:ParId(),
        -- reward = mReward,
        par_grade = self:ParGrade(),
        par_name = self:ParName(),
        par_model = self:ParModel(),
        par_star = self:ParStar();
        add_exp = self.m_iAddExp,
        par_awake = self:ParAwake(),
    }
    return mData
end

function CTravelPartner:ParId()
    return self:GetData("parid")
end

function CTravelPartner:ParGrade()
    return self:GetData("par_grade")
end

function CTravelPartner:ParName()
    return self:GetData("par_name")
end

function CTravelPartner:ParModel()
    return self:GetData("par_model")
end

function CTravelPartner:ParStar()
    return self:GetData("par_star", 1)
end

function CTravelPartner:ParAwake()
    return self:GetData("par_awake", 0)
end

function CTravelPartner:Exp()
    return self.m_iAddExp
end

function CTravelPartner:Rewardable()
    if self.m_iAddExp > 0 then
        return true
    end
    return false
end

function CTravelPartner:AddReward(mRwd)
    -- self:Dirty()
    -- for sType, iVal in pairs(mRwd) do
    --     local iHave = self.m_mReward[sType] or 0
    --     self.m_mReward[sType] = iHave + iVal
    -- end
end

function CTravelPartner:AddExp(iExp)
    self:Dirty()
    iExp = iExp or 0
    self.m_iAddExp = self.m_iAddExp + iExp
end

function CTravelPartner:RewardInfo()
    return table_copy(self.m_mReward)
end

function CTravelPartner:ClearExp()
    self:Dirty()
    self.m_iAddExp = 0
end

function CTravelPartner:PackNetInfo()
    return {
        parid = self:ParId(),
        par_name = self:ParName(),
        par_grade = self:ParGrade(),
        par_model = self:ParModel(),
    }
end

function CTravelPartner:PackTravelInfo()
    return {
        parid = self:ParId(),
        par_name = self:ParName(),
        par_grade = self:ParGrade(),
    }
end

function CTravelPartner:PackParInfo()
    return {
            parid = self:ParId(),
            par_name = self:ParName(),
            par_grade = self:ParGrade(),
            par_model = self:ParModel(),
            par_star = self:ParStar(),
            par_awake = self:ParAwake(),
    }
end
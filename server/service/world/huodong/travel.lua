--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"

local xgpush = import(lualib_path("public.xgpush"))
local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local loaditem = import(service_path("item.loaditem"))
local datactrl = import(lualib_path("public.datactrl"))

local CARD_STATUS = gamedefines.TRAVEL_CARD_STATUS
local TRAVEL_REWARD_TYPE = gamedefines.TRAVEL_REWARD_TYPE

local random = math.random
local VIRTUAL_COIN = {1002, 1003}

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_mGames = {}
    return o
end

function CHuodong:Init()
    self:TryStartRewardMonitor()
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
    end
end

function CHuodong:OnLogin(oPlayer, bReEnter)
    local iPid = oPlayer:GetPid()
    local oGame = self:GetGame(iPid)
    if oGame then
        if oGame:IsMaxCount() then
            self:GameOver(iPid)
        else
            oGame:OnLogin(oPlayer, bReEnter)
        end
    end
end

function CHuodong:OnLogout(oTravel)
    local iPid = oTravel:GetPid()
    local sTimeCB = string.format("TravelStart_%s", iPid)
    self:DelTimeCb(sTimeCB)

    local sTimeCB = string.format("UseSpeedItem_%s", iPid)
    self:DelTimeCb(sTimeCB)
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:IsDirty()
    if super(CHuodong).IsDirty(self) then
        return true
    end
    for iPos, oGame in pairs(self.m_mGames) do
        if oGame:IsDirty() then
            return true
        end
    end
    return false
end

function CHuodong:Save()
    local mData = {}
    local mGame = {}
    for iPid, oGame in pairs(self.m_mGames) do
        mGame[db_key(iPid)] = oGame:Save()
    end
    mData["game"] = mGame
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    local mGame = mData["game"] or {}
    for sPid, m in pairs(mGame) do
        local iPid = tonumber(sPid)
        local oGame = CGame:New(iPid)
        oGame:Load(m)
        if not oGame:IsMaxCount() then
            self.m_mGames[iPid] = oGame
        else
            --todo
        end
    end
end

function CHuodong:MergeFrom(mFromData)
    self:Dirty()
    mFromData = mFromData or {}
    local mGame = mFromData["game"] or {}
    for sPid, m in pairs(mGame) do
        local iPid = tonumber(sPid)
        local oGame = CGame:New(iPid)
        oGame:Load(m)
        if not oGame:IsMaxCount() then
            self.m_mGames[iPid] = oGame
        end
    end
end

function CHuodong:PreCheck(oTravel, bReEnter)
    if not bReEnter then
        self:CheckTravelPartner(oTravel)
        self:CheckSpeedItem(oTravel)
    end
end

function CHuodong:CheckTravelPartner(oTravel)
    local iPid = oTravel:GetPid()
    if not oTravel:IsTravel() then
        return
    end
    local iStartTime = oTravel:StartTime()
    local iEndTime = oTravel:EndTime()
    local iOldCnt = oTravel:TravelCnt()
    local iGapSecs = oTravel:GapSec()
    local iNow = get_time()
    local iCnt = oTravel:NowTravelCnt()
    local iMaxCnt = oTravel:MaxTravelCnt()
    if iOldCnt < iCnt then
        for i = iOldCnt + 1, iCnt do
            local iTravelTime = iStartTime + (i * iGapSecs)
            self:AddTravelReward(oTravel, iTravelTime)
        end
    else
        self:CheckTravelTimer(oTravel)
    end
end

function CHuodong:CheckSpeedItem(oTravel)
    local oSpeedItem = oTravel:SpeedItem()
    if oSpeedItem then
        local iPid = oTravel:GetPid()
        local iNow = get_time()
        local iEndTime = oSpeedItem:EndTime()
        if iEndTime - iNow > 0 then
            local f1
            f1 = function()
                local oTravel = global.oWorldMgr:GetTravel(iPid)
                if oTravel then
                    oTravel:RemoveSpeedItem(true)
                end
            end
            local sTimeCB = string.format("UseSpeedItem_%s", iPid)
            self:DelTimeCb(sTimeCB)
            self:AddTimeCb(sTimeCB, (iEndTime  - iNow) * 1000, f1)
        else
            oTravel:RemoveSpeedItem(true)
        end
    end
end

function CHuodong:GetTravelData(iTravel)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["travel_type"][iTravel]
    assert(mData, string.format("huodong:travel travel_type, not exsit:%s", iTravel))
    return mData
end

function CHuodong:ValidStartTravel(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local oTravel = oPlayer:GetTravel()
    if oTravel:IsTravel() then
        oNotifyMgr:Notify(oPlayer:GetPid(), "正在游历")
        return false
    end
    if not oTravel:HasTravelPartner() then
        oNotifyMgr:Notify(oPlayer:GetPid(), "先上阵伙伴")
        return false
    end
    if oTravel:Rewardable() then
        oNotifyMgr:Notify(oPlayer:GetPid(), "先领取奖励")
        return false
    end
    return true
end

function CHuodong:TravelStart(oPlayer, iTravel)
    local iPid = oPlayer:GetPid()
    local iNow = get_time()
    local mData = self:GetTravelData(iTravel)
    local iEndSecs = oPlayer:GetInfo("test_travel_time") or mData["travel_time"]
    local iGapSecs = oPlayer:GetInfo("test_gap_time") or mData["travel_gap"]
    local iEndTime = iNow + iEndSecs
    local oTravel = oPlayer:GetTravel()
    oTravel:TravelStart(iNow, iEndTime, iGapSecs)
    oTravel:SetTravelType(iTravel)
    local sTimeCB = string.format("TravelStart_%s", iPid)
    self:DelTimeCb(sTimeCB)
    self:AddTimeCb(sTimeCB, iGapSecs * 1000, function()
        self:OnTravelStart(iPid, get_time())
    end)
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30026,1)
    oPlayer:AddSchedule("travel")
    oPlayer:PushAchieve("开始伙伴游历次数", {value = 1})
    --pid|玩家id,travel_type|游历类型,travel_second|游历时长,gap_second|奖励间隔,reason|原因
    local mLog = {
        pid = iPid,
        travel_type = iTravel,
        travel_second = iEndSecs,
        gap_second = iGapSecs,
        reason = "开启游历",
    }
    record.user("travel", "travel_start", mLog)
end

function CHuodong:OnTravelStart(iPid, iTravelTime)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    oWorldMgr:LoadTravel(iPid, function(oTravel)
        self:_OnTravelStart(oTravel, iTravelTime)
    end)
end

function CHuodong:_OnTravelStart(oTravel, iTravelTime)
    local iPid = oTravel:GetPid()
    local iMaxCnt = oTravel:MaxTravelCnt()
    if oTravel:TravelCnt() < iMaxCnt then
        self:AddTravelReward(oTravel, iTravelTime)
    else
        self:TravelEnd(iPid)
    end
end

function CHuodong:AddTravelReward(oTravel, iTravelTime)
    oTravel:AddCnt(1, "OnTravelStart")
    local iCnt = oTravel:TravelCnt()
    local iRwdType = self:TravelType(iCnt)
    if iRwdType == TRAVEL_REWARD_TYPE.EXP then
        self:TravelAddExp(oTravel,iRwdType,iTravelTime)
    else
        self:TravelAddItem(oTravel,iRwdType, iTravelTime)
    end
end

function CHuodong:TravelType(iCnt)
    if iCnt % 2 == 0 then
        return 2
    else
        return 1
    end
end

function CHuodong:RanTravelItem(oProfile, iTravelType)
    local res = require "base.res"
    local lTravel = {}
    local mData = res["daobiao"]["huodong"][self.m_sName]["reward_pool"][iTravelType]
    if mData then
        local iRan = math.random(#mData["item_pool"])
        local iReward = mData["item_pool"][iRan]
        local mRewardInfo = self:GetRewardData(iReward)
        local iRate = mRewardInfo.rate
        if iRate < math.random(10000) then
            return {}
        end
        return self:GenRewardContent(oProfile, mRewardInfo, mArgs)
    end
    return {}
end

function CHuodong:TravelAddExp(oTravel, iRwdType, iTravelTime)
    local oWorldMgr = global.oWorldMgr
    local mPartner = {}
    for iPos, o in pairs(oTravel:TravelPartners()) do
        mPartner[iPos] = o:PackTravelInfo()
    end
    local oFrdPartner = oTravel:FrdTravelPartner()
    if oFrdPartner then
        mPartner[0] = oFrdPartner:PackTravelInfo()
    end

    local mSpeedItem
    if oTravel:IsSpeeding() then
        local oSpeedItem = oTravel:SpeedItem()
        mSpeedItem = oSpeedItem:PackTravelInfo()
    end
    local iPid = oTravel:GetPid()

    local mArgs = {
        rtype = iRwdType,
        count = oTravel:TravelCnt(),
        travel_time = iTravelTime,
    }
    oWorldMgr:LoadProfile(iPid, function(oProfile)
        if oProfile then
            self:_TravelAddExp(oProfile,mSpeedItem, mPartner,mArgs)
        else
            record.warning("TravelAddExp pid:%s, obj not exsit !", iPid)
        end
    end)
end

function CHuodong:_TravelAddExp(oProfile,mSpeedItem,mPartner,mArgs)
    local oWorldMgr = global.oWorldMgr
    local iPid = oProfile:GetPid()
    local mReward = {}
    local lContent = {}
    local iRwdType = mArgs.rtype
    local iCnt = mArgs.count
    local iTravelTime = mArgs.travel_time
    local mData = self:RanTravelTypeData(iRwdType)
    for iPos, mPar in pairs(mPartner) do
        --pid|玩家id,travel_type|游历类型,reward_count|奖励次数,pos|伙伴位置,partnerid|伙伴id,partner_exp|获得经验
        local mLog = {
            pid = iPid,
            pos = iPos,
            partnerid = mPar["parid"],
            travel_type = iRwdType,
            reward_count = iCnt,
            partner_exp = 0,
        }
        local mItem = self:RanTravelItem(oProfile, iRwdType)
        if mItem.partnerexp ~= "" and mItem.partnerexp ~= "0" then
            local iExp = self:TransReward(nil,mItem.partnerexp, {level = mPar.par_grade})
            local iExtraExp = self:SpeedExtraExp(mSpeedItem, iExp)
            iExp = iExp + iExtraExp
            local mEnv = {
                parname = mPar["par_name"],
                item_name = "经验",
                amount = iExp,
            }
            local sStr = mData.content
            for ss, val in pairs(mEnv) do
                sStr = string.gsub(sStr, ss, val)
            end
            local mContent = {
                travel_time = iTravelTime,
                content = sStr,
            }
            if iExtraExp > 0 then
                local sExtra = self:SpeedExtraContent(mSpeedItem,"经验",iExtraExp, mData.item_cnt)
                mContent.content = table.concat({sStr, sExtra}, "")
            end
            table.insert(lContent, mContent)
            mReward[iPos] = iExp
            mLog.partner_exp = iExp
        end
        record.user("travel", "add_travel_exp", mLog)
    end
    local mRwd = {
        parexp = mReward,
    }
    oWorldMgr:LoadTravel(iPid, function(oTravel)
        if oTravel then
            self:OnTravelStartEnd(oTravel, mRwd, lContent)
        else
            record.warning("_TravelAddExp obj not exsit!")
        end
    end)
    self:CheckTriggerTrader(oProfile, mData.trigger_trader, iTravelTime)
end

function CHuodong:OnTravelStartEnd(oTravel,mReward, lContent)
    local iPid = oTravel:GetPid()
    mReward = mReward or {}
    if mReward.parexp then
        oTravel:AddTravelPartnerExp(mReward.parexp)
    end
    if mReward.item then
        oTravel:AddTravelReward(mReward.item)
    end
    if next(lContent) then
        oTravel:AddTravelContent(lContent)
        oTravel:GS2CAddTravelContent(lContent)
    end
    self:CheckTravelTimer(oTravel)
end

function CHuodong:CheckTravelTimer(oTravel)
    local iPid = oTravel:GetPid()
    local iCnt = oTravel:TravelCnt()
    local iMaxCnt = oTravel:MaxTravelCnt()
    if iCnt >= iMaxCnt then
        self:TravelEnd(iPid)
    else
        local iNow = get_time()
        local iGapSecs = oTravel:GapSec()
        local iStartTime = oTravel:StartTime()
        iCnt = iCnt + 1
        local iNextCBSecs= iStartTime + (iCnt * iGapSecs) - iNow
        if iNextCBSecs > 0 then
            local sTimeCB = string.format("TravelStart_%s", iPid)
            self:DelTimeCb(sTimeCB)
            self:AddTimeCb(sTimeCB, iNextCBSecs * 1000, function()
                self:OnTravelStart(iPid, get_time())
            end)
        end
    end
end

function CHuodong:CheckTriggerTrader(oProfile, iWeight, iTravelTime)
    if not self:ValidTriggerTrader(oProfile) then
        return
    end
    iWeight = iWeight or 0
    if oProfile:IsFirstTriggerTrader() then
        iWeight = 10000
        oProfile:UnSetFirstTrigger()
    end
    if random(10000) <= iWeight then
        self:TriggerTrader(oProfile:GetPid(), 0, iTravelTime, "中途奖励触发")
    end
end

function CHuodong:SpeedExtraExp(mSpeedItem, iExp)
    local iExtra = 0
    if mSpeedItem then
        local iSpeed = mSpeedItem["exp_speed"] or 0
        iExtra = math.ceil(iExp * (iSpeed / 10000))
    end
    return iExtra
end

function CHuodong:SpeedExtraCoin(mSpeedItem, iCoin)
    local iExtra = 0
    if mSpeedItem then
        local iSpeed = mSpeedItem["coin_speed"] or 0
        iExtra =  math.ceil(iCoin * (iSpeed / 10000))
    end
    return iExtra
end

function CHuodong:SpeedExtraContent(mSpeedItem, sName, iExtra, sExtra)
    if mSpeedItem then
        local iSid = mSpeedItem["sid"]
        if iSid then
            local oItem = loaditem.GetItem(iSid)
            local mEnv = {
                item_use = oItem:Name(),
                item_name = sName,
                amount = iExtra,
            }
            for ss, val in pairs(mEnv) do
                sExtra = string.gsub(sExtra, ss, val)
            end
        end
    end
    return sExtra
end

function CHuodong:TravelAddItem(oTravel,iRwdType, iTravelTime)
    local oWorldMgr = global.oWorldMgr
    local mPartner = {}
    for iPos, o in pairs(oTravel:TravelPartners()) do
        mPartner[iPos] = o:PackTravelInfo()
    end
    local oFrdPartner = oTravel:FrdTravelPartner()
    if oFrdPartner then
        mPartner[0] = oFrdPartner:PackTravelInfo()
    end
    -- mPartner[0] = oTravel:FrdTravelPartner()
    local mSpeedItem
    if oTravel:IsSpeeding() then
        local oSpeedItem = oTravel:SpeedItem()
        mSpeedItem = oSpeedItem:PackTravelInfo()
    end
    local iPid = oTravel:GetPid()

    local mArgs = {
        rtype = iRwdType,
        count = oTravel:TravelCnt(),
        travel_time = iTravelTime,
    }
    oWorldMgr:LoadProfile(iPid, function(oProfile)
        if oProfile then
            self:_TravelAddItem(oProfile,mSpeedItem, mPartner,mArgs)
        else
            record.warning("TravelAddItem pid:%s, obj not exsit !", iPid)
        end
    end)
end

function CHuodong:_TravelAddItem(oProfile, mSpeedItem, mPartner, mArgs)
    local oWorldMgr = global.oWorldMgr

    local mReward = {}
    local lContent = {}
    local iPid = oProfile:GetPid()
    local iRwdType = mArgs.rtype
    local iCnt = mArgs.count
    local iTravelTime = mArgs.travel_time
    local mData = self:RanTravelTypeData(iRwdType)
    for iPos, mPar in pairs(mPartner) do
        --pid|玩家id,travel_type|游历类型,reward_count|奖励次数,pos|伙伴位置,partnerid|伙伴id,sid|道具id,amount|获得数量
        local mLog = {
            pid = iPid,
            pos = iPos,
            partnerid = mPar["parid"],
            travel_type = iRwdType,
            reward_count = iCnt,
            sid = 0,
            amount = 0,
        }
        local mItem = self:RanTravelItem(oProfile, iRwdType)
        if next(mItem.iteminfo) then
            local iCoin = 0
            local iRecord = 0
            local lItemObj = mItem.iteminfo.item or {}
            local sItemName = lItemObj[1] and lItemObj[1]:Name()
            mLog.sid = lItemObj[1] and lItemObj[1]:SID()
            for _, oItem in ipairs(lItemObj) do
                local sid = oItem:SID()
                local iAdd
                if oItem:ItemType() == "virtual" then
                    sid = oItem:GetRwardSid()
                    iAdd = oItem:GetData("value", 1)
                end
                if oItem:SID() == 1002 then
                    iCoin = iCoin + iAdd
                else
                    local iHave = mReward[sid] or 0
                    mReward[sid] = iHave + oItem:GetAmount()
                    iRecord = iRecord + oItem:GetAmount()
                    if oItem:SID() == 1003 then
                        iRecord = iAdd
                    end
                end
            end
            mLog.amount = iRecord

            if iCoin > 0 then
                local iExtraCoin = self:SpeedExtraCoin(mSpeedItem, iCoin)
                iCoin = iCoin + iExtraCoin
                local sSid = string.format("%s(value=%s)", 1002, iCoin)
                mReward[sSid] = 1
                local mEnv = {
                    parname = mPar["par_name"],
                    item_name = "金币",
                    amount = iCoin,
                }
                local sStr = mData.content
                for ss, val in pairs(mEnv) do
                    sStr = string.gsub(sStr, ss, val)
                end
                local mContent = {
                    travel_time = iTravelTime,
                    content = sStr,
                }
                if iExtraCoin > 0 then
                    local sExtra = self:SpeedExtraContent(mSpeedItem,"金币",iExtraCoin, mData.item_cnt)
                    mContent.content = table.concat({sStr, sExtra}, "")
                end
                table.insert(lContent, mContent)
            elseif sItemName then
                local mEnv = {
                    parname = mPar["par_name"],
                    item_name = sItemName,
                    amount = iRecord,
                }
                local sStr = mData.content
                for ss, val in pairs(mEnv) do
                    sStr = string.gsub(sStr, ss, val)
                end
                local mContent = {
                    travel_time = iTravelTime,
                    content = sStr,
                }
                table.insert(lContent, mContent)
            end
        end
        record.user("travel", "add_travel_reward", mLog)
    end

    local mRwd = {
        item = mReward,
    }
    oWorldMgr:LoadTravel(iPid, function(oTravel)
        if oTravel then
            self:OnTravelStartEnd(oTravel, mRwd, lContent)
        else
            record.warning("_TravelAddItem obj not exsit!")
        end
    end)
    self:CheckTriggerTrader(oProfile, mData.trigger_trader, iTravelTime)
end

function CHuodong:RanTravelTypeData(iType)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["travel"]
    local mType = {}
    for id, m in pairs(mData) do
        if m.type == iType then
            mType[id] = 1
        end
    end
    local id = table_choose_key(mType)
    return mData[id]
end

--手动结束
function CHuodong:TravelStop(oPlayer)
    local oTravel = oPlayer:GetTravel()
    if oTravel:IsTravel() then
        self:TravelEnd(oPlayer:GetPid())
    end
end

function CHuodong:TravelEnd(iPid, sReason)
    sReason = sReason or "游历结束"
    local oWorldMgr = global.oWorldMgr
    self:DelTimeCb(string.format("TravelStart_%s", iPid))
    oWorldMgr:LoadTravel(iPid,function(oTravel)
        if oTravel then
            --pid|玩家id,travel_type|游历类型,travel_second|游历时长,gap_second|奖励间隔,reason|原因
            local mLog = {
                pid = iPid,
                travel_type = oTravel:TravelType(),
                travel_second = oTravel:EndTime() - oTravel:StartTime(),
                gap_second = oTravel:GapSec(),
                reason = sReason,
            }
            oTravel:TravelEnd(true)
            record.user("travel", "travel_stop", mLog)
            if oTravel:IsGamePush() then
                xgpush.PushById(iPid, 10001)
            end
        end
    end)
end

function CHuodong:AcceptTravelReward(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local oMailMgr = global.oMailMgr

    local sReason = "领取游历奖励"
    local iPid = oPlayer:GetPid()
    local oTravel = oPlayer:GetTravel()
    local bManual = false
    if oTravel:IsTravel() then
        self:TravelEnd(oPlayer:GetPid(), sReason)
        bManual = true
    end
    if not oTravel:Rewardable() then
        return
    end

    --pid|玩家id,travel_type|游历类型,iteminfo|奖励详情,partner_exp|伙伴经验详情
    local mLog = {
        pid = iPid,
        travel_type = oTravel:TravelType(),
        iteminfo = "",
        partner_exp = "",
    }
    local mPartner = oTravel:TravelPartners()
    local mParExp = {}
    for iPos, oPar in pairs(mPartner) do
        local iExp = oPar:Exp()
        if iExp > 0 then
            mParExp[oPar:ParId()] = iExp
        end
    end
    local mReward = oTravel:TravelRewardInfo()
    local mArgs = {}
    if next(mParExp) then
        oPlayer.m_oPartnerCtrl:AddPartnerListExp(mParExp,sReason, mArgs)
    end
    local mAnalyParExp = table_deep_copy(mParExp)
    mLog.partner_exp = ConvertTblToStr(mParExp)

    local mAnalyItem = {}
    if next(mReward) then
        local lGiveItem = {}
        local mSumCoin = {}
        for sid, iAmount in pairs(mReward) do
            local oItem = loaditem.GetItem(sid)
            local iShape = oItem:SID()
            local iLog = iAmount
            if table_in_list(VIRTUAL_COIN, iShape) then
                local iVal = mSumCoin[iShape] or 0
                mSumCoin[iShape] = iVal + oItem:GetData("value", 0) * iAmount
                iLog = oItem:GetData("value", 0) * iAmount
            else
                table.insert(lGiveItem, {sid, iAmount})
            end
            mAnalyItem[iShape] = (mAnalyItem[iShape] or 0) + iLog
        end
        for iShape, iVal in pairs(mSumCoin) do
            local sSid = string.format("%s(value=%s)", iShape, iVal)
            table.insert(lGiveItem, {sSid, 1})
        end
        if oPlayer:ValidGive(lGiveItem,{cancel_tip = 1}) then
            oPlayer:GiveItem(lGiveItem, sReason, mArgs)
        else
            local oMailMgr  = global.oMailMgr
            local iMailId = 1
            local mData, name = oMailMgr:GetMailInfo(iMailId)
            local lReward = {}
            for _, m in ipairs(lGiveItem) do
                local sid , iAmount = table.unpack(m)
                local oItem = loaditem.ExtCreate(sid)
                oItem:SetAmount(iAmount)
                table.insert(lReward, oItem)
            end
            oMailMgr:SendMail(0, name, iPid, mData, {}, lReward)
            oNotifyMgr:Notify(iPid, "你的背包已满，奖励内容将以邮件的形式发送至游戏，请及时领取")
        end
        oTravel:ClearTravelConent()
        mLog.iteminfo = ConvertTblToStr(lGiveItem)
    end

    oTravel:ClearReward()
    oTravel:ClearTravelCnt()
    oTravel:GS2CTravelPartnerInfo()
    if not bManual then
        local iTravelType = oTravel:TravelType()
        if iTravelType > 0 then
            self:CheckCardGame(oPlayer:GetProfile(), iTravelType)
        end
        global.oAchieveMgr:PushAchieve(iPid, "正常完成游历次数", {value=1})
    end
    oTravel:SetTravelType(0)
    record.user("travel", "receive_travel_reward", mLog)
    local mAnalyLog = {}
    -- mAnalyLog["type"] = 0
    -- mAnalyLog["reason"] = "正常停止"
    -- if bManual then
    --     mAnalyLog["reason"] = "中途停止"
    -- end
    oPlayer:LogAnalyGame(mAnalyLog, "travel", mAnalyItem, {}, mAnalyParExp, 0)
end

function CHuodong:AcceptMineTravelReward(oPlayer)
    local oTravel = oPlayer:GetTravel()
    local oMinePar =oTravel:MineTravelPartner()
    if oMinePar then
        if not oMinePar:Recievable() then
            return
        end
        local mAnalyParExp = {}
        local iAddExp = oMinePar:Exp()
        if iAddExp > 0 then
            local sReason = "领取寄存伙伴奖励"
            local mArgs = {}
            local iParId = oMinePar:ParId()
            oPlayer.m_oPartnerCtrl:AddPartnerListExp({[iParId] = iAddExp},sReason,mArgs)
            mAnalyParExp[iParId] = iAddExp
        end
        local iParId = oTravel:RemoveMineTravel()
        if iParId then
            oPlayer.m_oPartnerCtrl:RemoveMineTravelPartner(iParId)
            oTravel:GS2CDelMineTravel()
        end

        --pid|玩家id,friend_pid|寄存好友pid,partner_exp|经验信息
        local mLog = {
            pid = oPlayer:GetPid(),
            friend_pid = iParId,
            partner_exp = iAddExp or 0,
        }
        record.user("travel", "receive_friend_reward", mLog)

        local mAnalyLog = {}
        -- mAnalyLog["type"] = 1
        oPlayer:LogAnalyGame(mAnalyLog, "travel", {}, {}, mAnalyParExp, 0)
    end
end

function CHuodong:UseSpeedItem(oPlayer, mApply)
    local iPid = oPlayer:GetPid()
    local iEndTime = mApply["end_time"]
    local iNow = get_time()
    if iEndTime <= iNow then
        return
    end
    local f1
    f1 = function()
        local oTravel = global.oWorldMgr:GetTravel(iPid)
        if oTravel then
            oTravel:RemoveSpeedItem(true)
        end
    end
    local sTimeCB = string.format("UseSpeedItem_%s", iPid)
    self:DelTimeCb(sTimeCB)
    self:AddTimeCb(sTimeCB, (iEndTime  - iNow) * 1000, f1)
    local oTravel = oPlayer:GetTravel()
    oTravel:AddSpeedItem(mApply)
end

function CHuodong:CancelSpeed(oPlayer)
    local oTravel = oPlayer:GetTravel()
    local oSpeedItem = oTravel:SpeedItem()
    if oSpeedItem then
        local sTimeCB = string.format("UseSpeedItem_%s", iPid)
        self:DelTimeCb(sTimeCB)
        oTravel:RemoveSpeedItem(true)
        global.oNotifyMgr:Notify(oPlayer:GetPid(), "取消成功")
    end
end

function CHuodong:InviteTravel(oPlayer, lFrdPids)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local oTravel = oPlayer:GetTravel()
    if not oTravel:IsTravel() then
        global.oNotifyMgr:Notify(iPid, "开始游历后才可邀请好友")
        return
    end
    local oFriend = oPlayer:GetFriend()
    local lInviteNet = {}
    local iNow = get_time()
    for _, iFrdPid in ipairs(lFrdPids) do
        if oFriend:IsBothFriend(iFrdPid) then
            oTravel:AddMineInvite(iFrdPid, iNow)
            table.insert(lInviteNet, oTravel:PackMineInvite(iFrdPid))
            oWorldMgr:LoadTravel(iFrdPid, function(oFrdTravel)
                local oMinePar = oFrdTravel:MineTravelPartner()
                if not oMinePar then
                    self:AddFrdInvite(iPid, oFrdTravel)
                end
            end)
        end
    end
    if next(lInviteNet) then
        oPlayer:Send("GS2CRefreshMineInvite", {mine_invites = lInviteNet})
    end
    global.oNotifyMgr:Notify(iPid, "已发出邀请")
end

function CHuodong:AddFrdInvite(iPid, oFrdTravel)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oTravel = oPlayer:GetTravel()
        local oSpeedItem = oTravel:SpeedItem()
        local mInvite = {}
        mInvite["frd_name"] = oPlayer:GetName()
        mInvite["frd_shape"] = oPlayer:GetShape()
        mInvite["invite_time"] = get_time()
        mInvite["invite_content"] = "欢迎加入我的游历队伍~~"
        if oSpeedItem then
            local iSid = oSpeedItem:SID()
            if iSid then
                local oItem = loaditem.GetItem(iSid)
                mInvite["invite_content"] = string.format("我正在使用【%s】，欢迎加入我的游历队伍~~", oItem:Name())
            else
                record.debug("gtxiedebug CTravel:AddFrdInvite, pid:%s, ", iPid)
            end
        end
        oFrdTravel:AddFrdInvite(iPid, mInvite)
    end
end

function CHuodong:DelTravelInvite(oPlayer, iFrdPid)
    local oTravel = oPlayer:GetTravel()
    local m = oTravel:FrdInvite(iFrdPid)
    if m then
        oTravel:RemoveFrdInvite(iFrdPid)
    end
end

function CHuodong:ClearTravelInvite(oPlayer)
    local oTravel = oPlayer:GetTravel()
    local mInvite = oTravel:FrdInvites()
    if next(mInvite) then
        oTravel:ClearFrdInvite()
    end
end

function CHuodong:GetFrdTravelInfo(oPlayer, iFrdPid)
    local oWorldMgr = global.oWorldMgr

    local iPid = oPlayer:GetPid()
    oWorldMgr:LoadTravel(iFrdPid, function(oFrdTravel)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oFrdTravel:SendFrdTravelInfo(oPlayer)
        end
    end)
end

function CHuodong:SetMinePartner2Frd(oPlayer, iFrdPid, iParId)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    local oTravel = oPlayer:GetTravel()
    if oTravel:HasMineTravel() then
        oNotifyMgr:Notify(iPid, "已存在寄养伙伴")
        return
    end
    local oFrdCtrl = oPlayer:GetFriend()
    if not oFrdCtrl:HasFriend(iFrdPid) then
        oNotifyMgr:Notify(iPid, "玩家非好友关系")
        return
    end
    oWorldMgr:LoadTravel(iFrdPid, function(oFrdTravel)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            if not oFrdTravel:IsTravel() then
                oNotifyMgr:Notify(iPid, "游历暂未开始")
                oFrdTravel:SendFrdTravelInfo(oPlayer)
                return
            end
            if not oFrdTravel:HasFrdTravel() then
                oPlayer.m_oPartnerCtrl:Forward("C2GSSetFrdPartnerTravel", oPlayer:GetPid(), {
                    frd_pid = iFrdPid,
                    parid = iParId,
                    })
            else
                oFrdTravel:SendFrdTravelInfo(oPlayer)
                oNotifyMgr:Notify(iPid, "已存在寄养伙伴")
            end
        end
    end)
end

function CHuodong:GetGame(iPid)
    return self.m_mGames[iPid]
end

function CHuodong:GetTravelGameData(idx)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["travel_game"][idx]
    assert(mData, string.format("huodong:travel travel_game, not exsit:%s", idx))
    return mData
end

function CHuodong:TravelGameMaxCount()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["travel_game"]
    return table_count(mData)
end

function CHuodong:StartTravelCardGame(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oGame = self:GetGame(iPid)
    if oGame then
        if self:ValidStartGame(oPlayer, oGame) then
            local iStartCoin = oGame:StartCoin()
            oPlayer:ResumeCoin(iStartCoin, self.m_sName, mArgs)
            oGame:Start(oPlayer)

            --pid|玩家id,travel_type|游历类型,count|翻牌玩法次数
            local mLog = {
                pid = oPlayer:GetPid(),
                travel_type = oGame:TravelType(),
                play_count = oGame:PlayCount(),
            }
            record.user("travel", "draw_card_start", mLog)
        end
    else
        oNotifyMgr:Notify(iPid, "奇遇玩法次数已完结   请期待下次触发奇遇商人")
    end
end

function CHuodong:ValidStartGame(oPlayer, oGame)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if oGame:IsStart() then
        oNotifyMgr:Notify(iPid, "不可重复游戏")
        return false
    end
    if oGame:IsMaxCount() then
        oGame:GameOver()
        oNotifyMgr:Notify(iPid, "已达最大次数")
        return false
    end
    local iStartCoin = oGame:StartCoin()
    if not oPlayer:ValidCoin(iStartCoin) then
        return false
    end
    return true
end

function CHuodong:ValidTriggerTrader(oProfile)
    local iMaxTigger = self:GetConfigValue("daily_trigger_trader") or 10
    if oProfile.m_oToday:Query("daily_trigger_trader", 0) >= iMaxTigger then
        return false
    end
    local iPid = oProfile:GetPid()
    local oGame = self:GetGame(iPid)
    if oGame then
        if oGame:IsMaxCount() and oGame:IsStop() then
            oGame:GameOver()
        end
        return false
    end

    return true
end

function CHuodong:CheckCardGame(oProfile, iTravel, sReason)
    sReason = sReason or "游历结束"
    if not self:ValidTriggerTrader(oProfile) then
        return
    end
    local mData = self:GetTravelData(iTravel)
    local iGameRate = mData["game_rate"]
    if random(10000) <= iGameRate then
        self:TriggerTrader(oProfile:GetPid(), iTravel, get_time(), sReason)
    end
end

function CHuodong:TriggerTrader(iPid, iTravel, iTiggerTime,sReason)
    local oNotifyMgr = global.oNotifyMgr
    local oGame = CGame:New(iPid)
    oGame:Init({travel_type = iTravel})
    self.m_mGames[iPid] = oGame
    oGame:SendTravelCardGrid()
    oGame:SendTravelShowCardInfo()
    oGame:SendFirstOpenUI()
    -- oNotifyMgr:Notify(iPid, "恭喜你在游历中偶遇#G奇遇商人#n，正等待着你玩游戏呢")

    --pid|玩家id,travel_type|游历类型,end_second|结束时长,reason|原因
    local mLog = {
        pid = iPid,
        travel_type = iTravel,
        end_second = iTiggerTime,
        reason = sReason,
    }
    record.user("travel", "trigger_draw_card", mLog)
end

function CHuodong:GameOver(iPid)
    local oWorldMgr = global.oWorldMgr
    local oGame = self:GetGame(iPid)
    if oGame then
        self:Dirty()
        --pid|玩家id,travel_type|游历类型,play_count|翻牌玩法次数
        local mLog = {
            pid = iPid,
            travel_type = oGame:TravelType(),
            play_count = oGame:PlayCount(),
        }
        record.user("travel", "remove_draw_card", mLog)
        self.m_mGames[iPid] = nil
    end
end

function CHuodong:StopTravelCardGame(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oGame = self:GetGame(iPid)
    if oGame then
        oGame:Stop(oPlayer)
    end
end

function CHuodong:IsClose(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if oWorldMgr:IsClose("travel") then
        oNotifyMgr:Notify(iPid, "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return true
    end

    return false
end

function CHuodong:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("travel", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CHuodong:ValidOpenTravelView(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    if self:IsClose(oPlayer) then
        return false
    end
    if not self:IsOpenGrade(oPlayer) then
        local iOpenGrade = oWorldMgr:QueryControl("travel", "open_grade")
        oNotifyMgr:Notify(iPid, string.format("等级不足，需达到%s级才可开启该玩法", iOpenGrade))
        return false
    end
    if not oPlayer:IsSingle() then
        oNotifyMgr:Notify(iPid, "请离开当前队伍")
        return false
    end

    return true
end

function CHuodong:OpenTravelView(oPlayer, oNpc)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oUIMgr = global.oUIMgr
    local oCbMgr = global.oCbMgr
    local oHuodongMgr = global.oHuodongMgr

    local iPid = oPlayer:GetPid()
    local iNpcShape = oNpc:Type()
    local mDialogInfo = self:GetDialogInfo(iNpcShape)
    local m = {}
    m["dialog"] = {{
        ["type"] = mDialogInfo["type"],
        ["pre_id_list"] = mDialogInfo["pre_id_list"],
        ["content"] = oNpc:GetText(),
        ["voice"] = mDialogInfo["voice"],
        ["last_action"] = mDialogInfo["last_action"],
        ["next"] = mDialogInfo["next"],
        ["ui_mode"] = mDialogInfo["ui_mode"],
        ["status"] = mDialogInfo["status"],
    }}
    m["dialog_id"] = iNpcShape
    m["npc_id"] = oNpc:ID()
    m["npc_name"] = oNpc:Name()
    m["shape"] = oNpc:Shape()
    local func = function(oPlayer, mData)
        local oHuodong = oHuodongMgr:GetHuodong("travel")
        if oHuodong and mData.answer == 1 then
            if oHuodong:ValidOpenTravelView(oPlayer) then
                oUIMgr:GS2COpenView(oPlayer, 1013)
            end
        end
    end
    oCbMgr:SetCallBack(iPid,"GS2CDialog",m,nil,func)
end

function CHuodong:GetDialogInfo(iDialog)
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["dialog"]
    assert(mData,string.format("Not Dialog Config:%s",self.m_sName))
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CHuodong:ShowTravelCard(oPlayer, iPos)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oGame = self:GetGame(iPid)
    if oGame then
        if oGame:IsStart() then
            oGame:ShowCard(oPlayer, iPos)
        else
            oNotifyMgr:Notify(iPid, "游戏未开始")
        end
    else
        oNotifyMgr:Notify(iPid, "奇遇玩法次数已完结   请期待下次触发奇遇商人")
    end
end

function CHuodong:FirstOpenTravelUI(oPlayer)
    local iPid = oPlayer:GetPid()
    local oGame = self:GetGame(iPid)
    if oGame then
        if oGame:IsMaxCount() then
            oGame:GameOver()
        elseif oGame:IsFirstOpen() then
            oGame:SetFirstOpen(false)
            oGame:SendFirstOpenUI()
        end
    end
end

function CHuodong:TestOP(oPlayer, iCmd, ...)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local mArgs = {...}
    if iCmd == 100 then

    elseif iCmd == 101 then
        local iTravel = math.random(1, 2)
        local oGame = self:GetGame(iPid)
        if oGame then
            oNotifyMgr:Notify(iPid, "先关闭奇遇玩法界面")
            return
        end
        self:CheckCardGame(oPlayer,iTravel)
    elseif iCmd == 102 then
        local iTestTime, iGapSecs = table.unpack(mArgs)
        iGapSecs = iGapSecs or 5
        if type(iTestTime) == "number" and iTestTime > 0 and iGapSecs > 0 then
            if iGapSecs > iTestTime then
                oNotifyMgr:Notify(iPid, "间隔时间不可大于游历时间")
            else
                oPlayer:SetInfo("test_travel_time", iTestTime)
                oPlayer:SetInfo("test_gap_time", iGapSecs)
                oNotifyMgr:Notify(iPid, string.format("设置游历时间:%s 秒, 间隔时间:%s秒", iTestTime, iGapSecs))
            end
        else
            oPlayer:SetInfo("test_travel_time", nil)
            oPlayer:SetInfo("test_gap_time", nil)
            oNotifyMgr:Notify(iPid, "取消设置游历时间")
        end
    end
end



CGame = {}
CGame.__index = CGame
inherit(CGame, datactrl.CDataCtrl)

function CGame:New(iPid, iTravelType)
    local o = super(CGame).New(self, {pid = iPid})
    o.m_iStatus = 0 --状态
    o.m_iCount  = 0 --已玩次数
    o.m_iBoutEnd = 0 --回合结束
    o.m_iType = 0 --游历类型, 0-中途奖励触发
    o.m_bFirst = true --是否打开游历界面
    o.m_mCards = {} --卡片信息
    o.m_oLastCard = nil --前一个卡
    o:InitCard()
    return o
end

function CGame:Init(mArgs)
    self:SetTravelType(mArgs["travel_type"] or 0)
end

function CGame:GetPid()
    return self:GetInfo("pid")
end

function CGame:GetHuodong()
    return global.oHuodongMgr:GetHuodong("travel")
end

function CGame:SetTravelType(iTravelType)
    self:Dirty()
    self.m_iType = iTravelType or 0
end

function CGame:SetFirstOpen(bFirst)
    self:Dirty()
    self.m_bFirst = bFirst
end

function CGame:IsFirstOpen()
    return self.m_bFirst == true
end

function CGame:TimeOut()
    if self.m_iEndTime <= get_time() then
        self:SetEndTime(0)
        return true
    end
    return false
end

function CGame:InitCard()
    local res = require "base.res"
    local mParnter = res["daobiao"]["partner"]["partner_info"]
    local lParType = table_key_list(mParnter)
    local lType = {}
    for i=1,8 do
        local iLen = #lParType
        local idx = random(#lParType)
        table.insert(lType, lParType[idx])
        lParType[idx] = lParType[iLen]
        lParType[iLen] = nil
    end
    local mType = {}
    for iPos =1, 16 do
        local iLen = #lType
        local idx = random(iLen)
        local iType = lType[idx]
        local oCard = CCardGrid:New(iPos)
        oCard:Init({shape = iType})
        self.m_mCards[iPos] = oCard
        local iHave = mType[iType] or 0
        if iHave >= 1 then
            lType[idx] = lType[iLen]
            lType[iLen] = nil
        else
            mType[iType] = iHave + 1
        end
    end
end

function CGame:Load(mData)
    mData = mData or {}
    self.m_iStatus = mData["status"] or 0
    self.m_iCount = mData["count"] or 0
    self.m_iType = mData["travel_type"] or 0
    self.m_bFirst = mData["first_open"] or true

    local mCard = mData["card_info"] or {}
    for sPos, m in pairs(mCard) do
        local iPos = tonumber(sPos)
        local oCard = CCardGrid:New(iPos)
        oCard:Init(m)
        self.m_mCards[iPos] = oCard
    end
end

function CGame:Save()
    local mData = {}
    mData["status"] = self.m_iStatus
    mData["count"] = self.m_iCount
    mData["travel_type"] = self.m_iType
    mData["first_open"] = self.m_bFirst or true

    local mCard = {}
    for iPos, oCard in pairs(self.m_mCards) do
        mCard[db_key(iPos)] = oCard:Save()
    end
    mData["card_info"] = mCard
    return mData
end

function CGame:OnLogin(oPlayer, bReEnter)
    self:SendTravelCardGrid()
    self:SendTravelShowCardInfo()
    self:SendFirstOpenUI()
end

function CGame:IsWatch()
    return self.m_iStatus == CARD_STATUS.WATCH
end

function CGame:IsStart()
    return self.m_iStatus == CARD_STATUS.START
end

function CGame:IsStop()
    return self.m_iStatus == CARD_STATUS.END
end

function CGame:PlayCount()
    return self.m_iCount
end

function CGame:TravelType()
    return self.m_iType or 0
end

function CGame:IsMaxCount()
    local iMaxCnt = self:MaxCount()
    return self.m_iCount >= iMaxCnt
end

function CGame:MaxCount()
    local oHuodong = self:GetHuodong()
    local iMaxCnt  = oHuodong:TravelGameMaxCount() or 2
    return iMaxCnt
end

function CGame:WatchSec()
    local oHuodong = self:GetHuodong()
    local idx = math.min(self:MaxCount(), self.m_iCount + 1)
    local mData = oHuodong:GetTravelGameData(idx)
    return mData["watch_sec"]
end

function CGame:StartCoin()
    local oHuodong = self:GetHuodong()
    local idx = math.min(self:MaxCount(), self.m_iCount + 1)
    local mData = oHuodong:GetTravelGameData(idx)
    return mData["cost_coin"]
end

function CGame:CardGrid(iPos)
    return self.m_mCards[iPos]
end

function CGame:AddScore(iAdd)
    local iPid = self:GetPid()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local sReason = "游历翻牌"
        oPlayer:AddTravelScore(iAdd, sReason, mArgs)

        local mCurrency = {}
        mCurrency[gamedefines.COIN_FLAG.COIN_TRAVEL] = iAdd
        oPlayer:LogAnalyGame({}, "travel_trader", {}, mCurrency)
    end
end

function CGame:Start()
    self:Dirty()
    self.m_oLastCard = nil
    self:InitCard()
    local iNow = get_time()
    local iWatchSecs = self:WatchSec()
    self.m_iBoutEnd = iNow + iWatchSecs
    self.m_iStatus = CARD_STATUS.WATCH
    self.m_iCount = self.m_iCount + 1
    self:SendTravelCardGrid()
    self:SendTravelShowCardInfo()
    local iPid = self:GetPid()
    -- self:SetClose(false)
    self:DelTimeCb("game_watch")
    self:AddTimeCb("game_watch", iWatchSecs * 1000, function()
        local oHuodong = global.oHuodongMgr:GetHuodong("travel")
        if oHuodong then
            local oGame = oHuodong:GetGame(iPid)
            if oGame then
                oGame:OnStart()
            end
        end
    end)
    global.oAchieveMgr:PushAchieve(iPid, "游历奇遇翻牌次数", {value=1})
end

function CGame:OnStart()
    self:Dirty()
    self.m_iStatus = CARD_STATUS.START
    local iNow = get_time()
    local iPlaySecs = 30
    self.m_iBoutEnd = iNow + iPlaySecs
    self:SendTravelShowCardInfo()
    local iPid = self:GetPid()
    self:DelTimeCb("game_start")
    self:AddTimeCb("game_start", iPlaySecs * 1000, function()
        local oHuodong = global.oHuodongMgr:GetHuodong("travel")
        if oHuodong then
            local oGame = oHuodong:GetGame(iPid)
            if oGame then
                oGame:SendTravelGameResult()
                -- oGame:NotifyGameResult()
                oGame:Stop()
            end
        end
    end)
end

function CGame:Stop()
    self:Dirty()
    self.m_iStatus = CARD_STATUS.END
    self.m_oLastCard = nil
    self.m_mCards = {}
    self:DelTimeCb("game_watch")
    self:DelTimeCb("game_start")
    self:DelTimeCb("show_card")
    self:SendTravelCardGrid()
    self:SendTravelShowCardInfo()

    if self:IsMaxCount() then
        self:GameOver(true)
    end

    --pid|玩家id,travel_type|游历类型,count|翻牌玩法次数
    local mLog = {
        pid = self:GetPid(),
        travel_type = self:TravelType(),
        play_count = self:PlayCount(),
    }
    record.user("travel", "draw_card_stop", mLog)
end

function CGame:GameOver(bCancel)
    local oHuodong = self:GetHuodong()
    if oHuodong then
        oHuodong:GameOver(self:GetPid())
    end
    if not bCancel then
        self:SendTravelCardGrid()
        self:SendTravelShowCardInfo()
    end
    self:SendGameOver()
end

function CGame:ShowCard(oPlayer, iPos)
    if not self:ValidShowCard(oPlayer, iPos) then
        return
    end
    local iPid = self:GetPid()
    local oCard = self:CardGrid(iPos)
    local lPos = {iPos}
    if self.m_oLastCard then
        table.insert(lPos, self.m_oLastCard:Pos())
        if self.m_oLastCard:Shape() == oCard:Shape() then
            self:DelTimeCb("show_card")
            self:Reverse(oCard)
            local oHuodong = self:GetHuodong()
            local iAddScore = oHuodong:GetConfigValue("score") or 10
            self:AddScore(iAddScore)
            if self:AllCardOpen() then
                self:SendTravelGameResult()
                -- self:NotifyGameResult()
                self:Stop()
            end
        else
            self:Reverse(self.m_oLastCard)
        end
        self.m_oLastCard = nil
    else
        self:Reverse(oCard)
        self.m_oLastCard = oCard
        self:DelTimeCb("show_card")
        self:AddTimeCb("show_card", 3 * 1000, function()
            local oHuodongMgr = global.oHuodongMgr
            local oHuodong = oHuodongMgr:GetHuodong("travel")
            if oHuodong then
                local oGame = oHuodong:GetGame(iPid)
                if oGame then
                    oGame:ShowCardTimeOut()
                end
            end
        end)
    end
    self:SendTravelCardGrid(lPos)
end

function CGame:ShowCardTimeOut()
    local oLast = self.m_oLastCard
        if oLast then
            self:Reverse(oLast)
            self.m_oLastCard = nil
            self:SendTravelCardGrid({oLast:Pos()})
        end
end

function CGame:ValidShowCard(oPlayer, iPos)
    local oCard = self:CardGrid(iPos)
    if not oCard then
        return false
    end
    if not oCard:IsReverse() then
        return false
    end
    if self.m_oLastCard and self.m_oLastCard:Pos() == iPos then
        return false
    end
    return true
end

function CGame:Reverse(oCard)
    if oCard:IsReverse() then
        oCard:SetStatus(1)
    else
        oCard:SetStatus(0)
    end
end

function CGame:AllCardOpen()
    for iPos, oCard in pairs(self.m_mCards) do
        if oCard:IsReverse() then
            return false
        end
    end
    return true
end

function CGame:SendTravelShowCardInfo()
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetPid()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CTravelShowCardInfo", {show_card = self:PackShowCard()})
    end
end

function CGame:SendTravelCardGrid(lPos)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetPid()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        if not lPos then
            lPos = {}
            for iPos, oCard in pairs(self.m_mCards) do
                table.insert(lPos, iPos)
            end
        end
        local lNet = {}
        for _, iPos in ipairs(lPos) do
            local oCard = self:CardGrid(iPos)
            if oCard then
                table.insert(lNet, oCard:PackNetInfo())
            end
        end
        oPlayer:Send("GS2CRefreshTravelCardGrid", {card_grids = lNet})
    end
end

function CGame:SendGameOver()
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetPid()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CRemoveTravelGame", {})
    end
end

function CGame:SendTravelGameResult()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CTravelGameResult", {result = self:AllCardOpen()})
    end
end

function CGame:NotifyGameResult()
    local oNotifyMgr = global.oNotifyMgr
    local iPid = self:GetPid()
    if next(self.m_mCards) then
        if self:AllCardOpen() then
            oNotifyMgr:Notify(iPid, "游戏胜利")
        else
            oNotifyMgr:Notify(iPid, "游戏结束")
        end
    end
end

function CGame:SendFirstOpenUI()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:Send("GS2CFirstOpenTraderUI", {is_first = self.m_bFirst})
    end
end

function CGame:PackShowCard()
    return {
        status = self.m_iStatus,
        play_count = self.m_iCount,
        watch_secs = self:WatchSec(),
        start_cost = self:StartCoin(),
        end_time = self.m_iBoutEnd,
        server_time = get_time(),
    }
end


CCardGrid = {}
CCardGrid.__index = CCardGrid
inherit(CCardGrid, datactrl.CDataCtrl)

function CCardGrid:New(iPos)
    local o = super(CCardGrid).New(self)
    o:SetData("pos", iPos)
    return o
end

function CCardGrid:Init(mData)
    self:SetData("shape", mData["shape"])
    self:SetData("status", mData["status"] or 0)
end

function CCardGrid:Pos()
    return self:GetData("pos")
end

function CCardGrid:Shape()
    return self:GetData("shape")
end

function CCardGrid:Status()
    return self:GetData("status")
end

function CCardGrid:SetStatus(iStatus)
    iStatus = iStatus or 0
    self:SetData("status", iStatus)
end

function CCardGrid:IsReverse()
    return self:Status() == 0
end

function CCardGrid:Save()
    return {
        pos = self:Pos(),
        shape = self:Shape(),
        status = self:Status(),
    }
end

function CCardGrid:PackNetInfo()
    return {
        pos = self:Pos(),
        shape = self:Shape(),
        status = self:Status(),
    }
end
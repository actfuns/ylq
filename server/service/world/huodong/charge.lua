local global = require "global"
local res = require "base.res"
local interactive = require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"
local net = require "base.net"
local colorstring = require "public.colorstring"

local analy = import(lualib_path("public.dataanaly"))
local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local loaditem = import(service_path("item.loaditem"))

local STATUS_UNCHARGE = 0
local STATUS_REWARD = 1
local STATUS_REWARDED = 2

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "运营活动"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_mMonthCard = {}          --月卡
    self.m_mZskCard = {}                --终身卡
    self.m_mTodayMonthCard = {} --当天的月卡特权
    self.m_mChargeReward = {}
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.month_card = {}
    for iPid, mInfo in pairs(self.m_mMonthCard) do
        mData.month_card[db_key(iPid)] = mInfo
    end
    mData.zsk_card = {}
    for iPid, mInfo in pairs(self.m_mZskCard) do
        mData.zsk_card[db_key(iPid)] = mInfo
    end
    mData.charge_reward = self.m_mChargeReward
    return mData
end

function CHuodong:Load(m)
    if not m then return end
    local mMonthCard = m.month_card or {}
    for sPid, mInfo in pairs(mMonthCard) do
        self.m_mMonthCard[tonumber(sPid)] = mInfo
    end
    local mZskCard = m.zsk_card or {}
    for sPid,mInfo in pairs(mZskCard) do
        self.m_mZskCard[tonumber(sPid)] = mInfo
    end
    for iPid,mInfo in pairs(self.m_mMonthCard) do
        for sKey,_ in pairs(mInfo) do
            if sKey == "yk" then
                self.m_mTodayMonthCard[iPid] = 1
            end
        end
    end
    self.m_mChargeReward = m.charge_reward or self.m_mChargeReward
end

function CHuodong:MergeFrom(mFromData)
    self:Dirty()
    mFromData = mFromData or {}
    local mMonthCard = mFromData.month_card or {}
    for sPid, mInfo in pairs(mMonthCard) do
        self.m_mMonthCard[tonumber(sPid)] = mInfo
    end
    local mZskCard = mFromData.zsk_card or {}
    for sPid,mInfo in pairs(mZskCard) do
        self.m_mZskCard[tonumber(sPid)] = mInfo
    end
    return true
end

function CHuodong:NewDay(iWeekDay)
    local iCheckDay = self:GetDayNo()
    self.m_mTodayMonthCard = {}
    for iPid, mInfo in pairs(self.m_mMonthCard) do
        for sKey, mData in pairs(mInfo) do
            safe_call(self.TryRewardMonthCardByMail, self, iPid, sKey, iCheckDay)
        end
    end
    local sKey = "zsk"
    for iPid,mInfo in pairs(self.m_mZskCard) do
        safe_call(self.TryRewardZskCardByMail, self, iPid,sKey,iCheckDay)
    end
    safe_call(self.CheckChargeReward,self)
end

function CHuodong:IsBackendOpen()
    local oLimitHuodong = self:GetLimitHuodong()
    if oLimitHuodong:IsOpen(self.m_sName) then
        return true
    end
    return false
end


function CHuodong:CheckChargeReward()
    local oLimitHuodong = self:GetLimitHuodong()
    if oLimitHuodong:IsOpen(self.m_sName) then
        return
    end
    --self:Dirty()
    --self.m_mChargeReward = {}
end

function CHuodong:BackendOpen()
    self:ClearChargeReward()
end

function CHuodong:ClearChargeReward()
    self:Dirty()
    self.m_mChargeReward = {}
end

function CHuodong:GetLimitHuodong()
    local oHuodongMgr = global.oHuodongMgr
    return oHuodongMgr:GetHuodong("limitopen")
end

function CHuodong:GetChargeRewardOpenTime()
    local oLimitHuodong = self:GetLimitHuodong()
    return oLimitHuodong:StartTime(self.m_sName)
end

function CHuodong:GetChargeRewardEndTime()
    local oLimitHuodong = self:GetLimitHuodong()
    return oLimitHuodong:EndTime(self.m_sName)
end

function CHuodong:IsLimitChargeReward(oPlayer,iRmb)
    local mRewardData = self:GetChargeRewardInfo(iRmb)
    local iLimit = mRewardData["limit"]
    if not iLimit then
        return true
    end
    local iPid = oPlayer:GetPid()
    local iGetRwdCnt = self:GetChargeRewardCnt(iPid,iRmb)
    if iGetRwdCnt < iLimit then
        return false
    end
    return true
end

function CHuodong:GetChargeRewardCnt(iPid,iRmb)
    local mRewardData = self.m_mChargeReward[iPid] or {}
    return mRewardData[iRmb] or 0
end

function CHuodong:AddChargeRewardCnt(oPlayer,iRmb)
    self:Dirty()
    local iPid = oPlayer:GetPid()
    local mData = self.m_mChargeReward[iPid] or {}
    if not mData[iRmb] then
        mData[iRmb] = 0
    end
    mData[iRmb] = mData[iRmb] + 1
    self.m_mChargeReward[iPid] = mData
    self:RefreshChargeReward(oPlayer,iRmb)
end

function CHuodong:RefreshChargeReward(oPlayer,iRmb)
    local mRewardData = self:GetChargeRewardInfo(iRmb)
    local iLimit = mRewardData["limit"]
    local iPid = oPlayer:GetPid()
    local iGetRwdCnt = self:GetChargeRewardCnt(iPid,iRmb)
    local iLeftAmount = math.max(iLimit-iGetRwdCnt,0)
    local mNet = {
        rmb=iRmb,
        left_amount = iLeftAmount
    }
    oPlayer:Send("GS2CRefreshChargeReward",{reward_info=mNet})
end

function CHuodong:SendClientChargeReward(oPlayer)
    local oLimitHuodong = self:GetLimitHuodong()
    local sName = self.m_sName
    local mNet = {}
    local iSchedule = 0
    if oLimitHuodong:IsOpen(sName) then
        iSchedule = oLimitHuodong:GetUsePlan(sName)
        local mData = res["daobiao"]["huodong"][self.m_sName]["charge_reward"]
        local mScheduleData = mData[iSchedule] or {}
        local iPid = oPlayer:GetPid()
        for iRmb,mRewardData in pairs(mScheduleData) do
            local iLimit = mRewardData["limit"]
            local iGetRwdCnt = self:GetChargeRewardCnt(iPid,iRmb)
            local iLeftAmount = math.max(iLimit - iGetRwdCnt,0)
            table.insert(mNet,{
                rmb = iRmb,
                left_amount = iLeftAmount,
            })
        end
    end
    local mData = {
        start_time = self:GetChargeRewardOpenTime(),
        end_time = self:GetChargeRewardEndTime(),
        schedule = iSchedule,
        reward_info = mNet,
    }
    oPlayer:Send("GS2CChargeRewrad",mData)
end

function CHuodong:GetChargeRewardInfo(iRmb)
    local oLimitHuodong = self:GetLimitHuodong()
    local iSchedule = oLimitHuodong:GetUsePlan(self.m_sName)
    local mData = res["daobiao"]["huodong"][self.m_sName]["charge_reward"]
    local mScheduleData = mData[iSchedule] or {}
    local mRewardData = mScheduleData[iRmb] or {}
    return mRewardData
end

function CHuodong:GetChargeRewardIdx(iRmb)
    local mRewardData = self:GetChargeRewardInfo(iRmb)
    return mRewardData["reward_id"] or {}
end

function CHuodong:Notify(iPid, iChat, mReplace)
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(iChat)
    oNotifyMgr:BroadCastNotify(iPid,{"GS2CNotify"},sMsg,mReplace)
end

function CHuodong:BroadCast(oPlayer,iChat)
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(iChat)
    sMsg = colorstring.FormatColorString(sMsg, {role=oPlayer:GetName()})
    oNotifyMgr:SendSysChat(sMsg,1,1)
end

function CHuodong:OnLogin(oPlayer, bReEnter)
    local mNet = {}
    mNet.czjj_is_buy = self:IsBuyGradeGift(oPlayer)
    mNet.czjj_grade_list = self:PackGradeGift(oPlayer)
    mNet.charge_card = self:PackCardInfo(oPlayer)
    mNet = net.Mask("GS2CChargeGiftInfo", mNet)
    oPlayer:Send("GS2CChargeGiftInfo", mNet)
    self:ChargeLogin(oPlayer)
    local iPid = oPlayer:GetPid()
    if self:IsMonthVipNotify(iPid) and oPlayer.m_oToday:Query("month_card_notify",0) ==0 then
        local mNet = {
            left_day = self:GetMonthCardLeftDay(iPid)
        }
        oPlayer:Send("GS2CPopBuyMonthCard",mNet)
        oPlayer.m_oToday:Set("month_card_notify",1)
    end
    self:SendClientChargeReward(oPlayer)
end

function CHuodong:ChargeLogin(oPlayer)
    local mConfig = self:GetChargeConfig()
    local lChargeList = {}
    for iKey, mInfo in pairs(mConfig) do
        local sKey = self:GenKey(iKey)
        local iVal = oPlayer:Query(sKey, STATUS_UNCHARGE)
        local mUnit = {key = sKey, val = iVal}
        table.insert(lChargeList, mUnit)
    end
    oPlayer:Send("GS2CPayForColorCoinInfo", {colorcoin_list = lChargeList})
end

function CHuodong:OnChargeAnalyLog(oPlayer,iAdd,iVal,iOldColorCoin,iOrderId,sType)
     local mLog = oPlayer:GetPubAnalyData()
     mLog.recharge_num = iAdd
     mLog.vip_level_before = 0
     mLog.vip_level_after = 0
     mLog.crystal_before = iOldColorCoin
     mLog.gain_crystal = iVal
     mLog.crystal_bd_before = 0
     mLog.gain_crystal_bd = 0
     mLog.card = "none"
     if oPlayer:IsZskVip() then
         mLog.card = "forever"
     elseif oPlayer:IsMonthCardVip() then
         mLog.card = "month"
     end
     mLog.orderid = iOrderId
     mLog.type = sType
     analy.log_data("Recharge", mLog)
end

---------------------充值----------------
function CHuodong:PayForGold(oPlayer, sKey,sProductKey,iOrderId,mArgs)
    mArgs = mArgs or {}
    local mConfig = self:GetChargeConfig()
    local iKey = tonumber(sKey)
    local mInfo = mConfig[iKey]
    if not mInfo then
        return
    end
    local sKeepKey = self:GenKey(iKey)
    local iCnt = oPlayer:Query(sKeepKey, 0)
    local iGoldCoin = mInfo.gold_coin_gains

    local iRmb = mArgs.rmb
    if not iRmb then
        iRmb = self:GetProductRmb(sProductKey)
    end

    local iAdd = iGoldCoin
    if iCnt <= 0 then
        iGoldCoin = iGoldCoin + mInfo.first_reward
    else
        iGoldCoin = iGoldCoin + mInfo.reward_gold_coin
    end
    oPlayer:Set(sKeepKey, 1+iCnt)
    local mChargeArgs = {
        cancel_tip = 1,
        cancel_channel = 1,
    }
    local iOldGoldCoin = oPlayer:GoldCoin()
    oPlayer:ChargeGoldCoin(iGoldCoin, sKeepKey,mChargeArgs)
    self:RefreshPayForGold(oPlayer, sKeepKey)
    local mRecordInfo = {
        action = "pay_for_gold",
        goldcoin = iGoldCoin,
        cnt = oPlayer:Query(sKeepKey, 0),
        payid = mInfo.payid
    }
    record.log_db("huodong", "charge", {pid=oPlayer:GetPid(), info=mRecordInfo})

    local sReason = "商店充值"
    oPlayer:AddHistoryCharge(iRmb)
    oPlayer:AfterChargeGold(iRmb,"充值")
    self:OnChangeWelFare(oPlayer,iRmb,sReason,mArgs)
    self:OnAddCharge(oPlayer, iRmb, sReason)
    self:OnDayCharge(oPlayer, iRmb, sReason)

    local bNoLog = mArgs.no_analylog
    if not bNoLog then
        self:OnChargeAnalyLog(oPlayer,iRmb,iGoldCoin,iOldGoldCoin,iOrderId,"shopcharge")
    end
    local iPid = oPlayer:GetPid()
    local mRewardArgs = {
        cancel_tip = 1,
        cancel_channel = 1,
    }
    local oLimitHuodong = self:GetLimitHuodong()
    if oLimitHuodong:IsOpen(self.m_sName) and not self:IsLimitChargeReward(oPlayer, iRmb) then
        self:AddChargeRewardCnt(oPlayer,iRmb)
        local lRewardIdx = self:GetChargeRewardIdx(iRmb)
        for _,iRewardIdx in ipairs(lRewardIdx) do
            self:Reward(iPid,iRewardIdx,mRewardArgs)
        end
    end
    global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
end

function CHuodong:GenKey(iKey)
    return string.format("goldcoinstore_%s", iKey)
end

function CHuodong:GetChargeConfig()
    return res["daobiao"]["goldcoinstore"]
end

function CHuodong:GetGradeGift()
    return res["daobiao"]["huodong"][self.m_sName]["grade_gift"]
end

function CHuodong:GetCardConfig()
    return res["daobiao"]["huodong"][self.m_sName]["card"]
end

function CHuodong:GetGiftBagConfig()
    return res["daobiao"]["huodong"][self.m_sName]["gift_bag"]
end

function CHuodong:GetPrivilege()
    return res["daobiao"]["huodong"][self.m_sName]["privilege"]
end

function CHuodong:GenGiftBagKey()
    local mInfo = self:GetGiftBagConfig()
    return table_key_list(mInfo)
end

--商品价值：单位（元）
function CHuodong:GetProductRmb(sProductKey)
    local mData = res["daobiao"]["pay"][sProductKey]
    if not mData then
        record.error("GetProductRmb error: no such product %s", sProductKey)
        return 0
    end
    local iValue = mData["value"]
    if not iValue or iValue <= 0 then
        record.error("GetProductRmb error: product %s error value %s", sProductKey, iValue)
        return 0
    end
    return math.floor(iValue / 100)
end


function CHuodong:RefreshPayForGold(oPlayer, sKey)
    local mUnit = {}
    mUnit.key = sKey
    mUnit.val = oPlayer:Query(sKey, STATUS_UNCHARGE)
    oPlayer:Send("GS2CRefreshChargeColorCoin", {unit = mUnit})
end

--iValue表示数目
function CHuodong:OnCharge(oPlayer, iProductAmount, sKeyWord, sProductKey,iOrderId,mArgs)
    mArgs = mArgs or {}
    local iRmb = mArgs.rmb
    if not iRmb then
        iRmb = self:GetProductRmb(sProductKey)
    end
    local iOldGoldCoin = oPlayer:GoldCoin()
    local lGiftBagKey = self:GenGiftBagKey()
    local sReason = "oncharge"
    if extend.Array.find({"grade_gift1",}, sKeyWord) then
        local iRet = self:ValidRewardGradeGift(oPlayer, sKeyWord, 0)
        if iRet == 1002 then
            oPlayer:Set(sKeyWord, STATUS_REWARD)
            sReason = "buyfund"
            self:BuyGradeGift(oPlayer,sKeyWord)
        else
            record.warning("can't charge again grade_gift:%s %s %s", oPlayer:GetPid(), sKeyWord, sProductKey)
        end
    elseif extend.Array.find({"yk",}, sKeyWord) then    --月卡
        sReason = "buymonth"
        self:MonthCardChargeReward(oPlayer, sKeyWord)
    elseif extend.Array.find({"zsk",}, sKeyWord) then   --终身卡
        sReason = "buyforever"
        self:ZskCardChargeReward(oPlayer,sKeyWord)
    elseif extend.Array.find(lGiftBagKey,sKeyWord) then
        sReason = "giftbag"
        self:BuyGiftBag(oPlayer,mArgs)
        if mArgs.goods_key then
            sReason = string.format("giftbag_goods_%s",mArgs.goods_key)
        elseif mArgs.grade_key then
            sReason = string.format("giftbag_grade_%d",mArgs.grade_key)
        elseif mArgs.one_RMB_gift then
            sReason = string.format("one_RMB_%d",mArgs.one_RMB_gift)
        end
    end
    oPlayer:AddHistoryCharge(iRmb)
    oPlayer:AfterChargeGold(iRmb,sReason)
    local iGoldCoin = oPlayer:GoldCoin()
    local bNoLog = mArgs.no_analylog
    if not bNoLog then
        self:OnChargeAnalyLog(oPlayer,iRmb,iGoldCoin,iOldGoldCoin,iOrderId,sReason)
    end
    self:OnChangeWelFare(oPlayer,iRmb,sReason,mArgs)
    self:OnAddCharge(oPlayer, iRmb, sReason)
    self:OnDayCharge(oPlayer, iRmb, sReason)
end

function CHuodong:OnChangeWelFare(oPlayer,iRmb,sReason,mArgs)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("welfare")
    if oHuodong then
        oHuodong:AfterCharge(oPlayer,iRmb,sReason,mArgs)
    end
end

function CHuodong:OnAddCharge(oPlayer,iRmb,sReason)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("addcharge")
    if oHuodong then
        oHuodong:AddChargeProgress(oPlayer,iRmb,sReason)
    end
end

function CHuodong:OnDayCharge(oPlayer,iRmb,sReason)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("daycharge")
    if oHuodong then
        oHuodong:DayCharge(oPlayer,iRmb,sReason)
    end
end

--各种活动的礼包购买
function CHuodong:BuyGiftBag(oPlayer,mArgs)
    local iGoodsKey = mArgs.goods_key
    local iGradeKey = mArgs.grade_key
    local iOneRMBKey = mArgs.one_RMB_gift
    if iGoodsKey then
        local iShoop = 212
        global.oStoreMgr:RMBPlay(oPlayer,iShoop,iGoodsKey)
        if table_in_list({212024,212016,212025},iGoodsKey) then
            self:OnBuyGiftBagWelFare(oPlayer,iGoodsKey,"goods")
        end
        oPlayer:AddSchedule("buy_giftbag")
    elseif iGradeKey then
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("gradegift")
        if oHuodong then
            oHuodong:BuyGradeGift(oPlayer,iGradeKey)
            self:OnBuyGiftBagWelFare(oPlayer,iGradeKey,"gradegift")
        end
    elseif iOneRMBKey then
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("oneRMBgift")
        if oHuodong then
            oHuodong:BuyGift(oPlayer, iOneRMBKey)
            self:OnBuyGiftBagWelFare(oPlayer,iOneRMBKey,"onermb")
        end
    end
end

function CHuodong:OnBuyGiftBagWelFare(oPlayer,iKey,sType)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("welfare")
    if oHuodong then
        oHuodong:AfterBuyGiftBag(oPlayer,iKey,sType)
    end
end

function CHuodong:BuyGradeGift(oPlayer,sKeyWord)
    local mNet = {}
    mNet.czjj_is_buy = self:IsBuyGradeGift(oPlayer)
    mNet.czjj_grade_list = self:PackGradeGift(oPlayer)
    mNet = net.Mask("GS2CChargeGiftInfo", mNet)
    oPlayer:Send("GS2CChargeGiftInfo", mNet)
    local mInfo = {
        keyword = sKeyWord,
        action = "buy_grade_gift",
    }
    record.log_db("huodong", "charge", {pid=oPlayer:GetPid(), info=mInfo})
    local sAccount = oPlayer:GetAccount()
    global.oAccountMgr:AccountBuyCZJJ(sAccount)
    self:BroadCast(oPlayer,3003)
end

--------------------------------成长基金--------------------
function CHuodong:TryRewardGradeGift(oPlayer, sType, iGrade)
    local iPid = oPlayer:GetPid()
    local iRet, mReplace = self:ValidRewardGradeGift(oPlayer, sType, iGrade)
    if iRet ~= 1 then
        self:Notify(iPid, iRet, mReplace)
        return
    end

    local sKey = string.format("%s_%s", sType, iGrade)
    local mConfig = self:GetGradeGift()
    local mGift = mConfig[sKey]
    if not mGift then return end

    oPlayer:Set(sKey, STATUS_REWARDED)
    local mArgs = {
        cancel_tip = 1,
        cancel_channel = 1,
    }
    if iGrade ~= 0 then
        oPlayer:RewardGoldCoin(mGift.goldcoin, sKey,mArgs)
        self:RefreshGradeGiftUnit(oPlayer, sKey)
    else
        oPlayer:RewardGoldCoin(mGift.goldcoin,sKey,mArgs)
        local mNet = {}
        mNet.czjj_is_buy = self:IsBuyGradeGift(oPlayer)
        mNet.czjj_grade_list = self:PackGradeGift(oPlayer)
        mNet = net.Mask("GS2CChargeGiftInfo", mNet)
        oPlayer:Send("GS2CChargeGiftInfo", mNet)
    end
    global.oUIMgr:ShowKeepItem(iPid)
    local mInfo = {
        keyword = sKey,
        action = "grade_gift",
        payid = mGift.payid
    }
    record.log_db("huodong", "charge", {pid=oPlayer:GetPid(), info=mInfo})
end

function CHuodong:CanBuyGradeGift(oPlayer)
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local sKey = "charge_czjj"
     if oWorldMgr:IsClose(sKey) then
        return
    end
    local iGrade = res["daobiao"]["global_control"][sKey]["open_grade"]
    if oPlayer:GetGrade() < iGrade then
        self:Notify(iPid, 2004, {grade=iGrade})
        return false
    end
    if oPlayer:Query("grade_gift1",STATUS_UNCHARGE) == STATUS_REWARD then
        self:Notify(iPid, 2003)
        return false
    end
    return true
end

function CHuodong:IsBuyGradeGift(oPlayer)
    if oPlayer:Query("grade_gift1",STATUS_UNCHARGE) == STATUS_REWARD then
        return STATUS_REWARD
    end
end

function CHuodong:ValidRewardGradeGift(oPlayer, sType, iGrade)
    local iGrade = global.oWorldMgr:QueryGlobalData("czjj_grade")
    iGrade = tonumber(iGrade)
    if oPlayer:GetGrade() < iGrade then
        return 1001
    end
    if oPlayer:Query(sType, STATUS_UNCHARGE) <= STATUS_UNCHARGE then
        return 1002
    end
    if oPlayer:GetGrade() < iGrade then
        return 1004, {grade=iGrade}
    end
    local sKey = string.format("%s_%s", sType, iGrade)
    if oPlayer:Query(sKey, STATUS_UNCHARGE) == STATUS_REWARDED then
        return 1003
    end
    return 1
end

function CHuodong:PackGradeGift(oPlayer, sKey)
    local mConfig = self:GetGradeGift()
    local mNet = {}
    for sKey, _ in pairs(mConfig) do
        local mUnit = {}
        mUnit.key = sKey
        mUnit.val = self:GetGradeGiftStatus(oPlayer, sKey)
        table.insert(mNet, mUnit)
    end
    return mNet
end

function CHuodong:GetGradeGiftStatus(oPlayer, sKey)
    local sType = string.sub(sKey, 1, 11)
    local iStatus = oPlayer:Query(sType, STATUS_UNCHARGE)
    if iStatus == STATUS_UNCHARGE then
        return STATUS_UNCHARGE
    else
        return oPlayer:Query(sKey, STATUS_UNCHARGE)
    end
end

function CHuodong:RefreshGradeGiftUnit(oPlayer, sKey)
    local mUnit = {}
    mUnit.key = sKey
    mUnit.val = self:GetGradeGiftStatus(oPlayer, sKey)
    oPlayer:Send("GS2CChargeRefreshUnit", {unit=mUnit})
end

--------------------------------------------月卡,终身卡

function CHuodong:PackCardInfo(oPlayer)
    local mNet = {}
    local iPid = oPlayer:GetPid()
    local mConfig = self:GetCardConfig()
    local iCurDay = self:GetDayNo()
    for sKey, _ in pairs(mConfig) do
        local mData = self:GetCardNetInfo(oPlayer,sKey)
        table.insert(mNet, mData)
    end
    return mNet
end

function CHuodong:CanBuyMonthCard(iPid)
    local oWorldMgr = global.oWorldMgr
    local sKey = "monthly_card"
    local iGrade = res["daobiao"]["global_control"][sKey]["open_grade"]
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    if oWorldMgr:IsClose(sKey) then
        return
    end
    if oPlayer:GetGrade() < iGrade then
        return false
    end
    return true
end

function CHuodong:CanBuyZskCard(iPid)
    local oWorldMgr = global.oWorldMgr
    if self.m_mZskCard[iPid] then
        self:Notify(iPid,2001)
        return false
    end
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    local sKey = "permanent_card"
    local iGrade = res["daobiao"]["global_control"][sKey]["open_grade"]
    if oPlayer:GetGrade() < iGrade then
        self:Notify(iPid,2002,{grade=iGrade})
        return false
    end
    if oWorldMgr:IsClose(sKey) then
        return
    end
    return true
end

function CHuodong:GetDayNo()
    return self.m_iTestDayNo or get_dayno()
end

--月卡充值初次奖励
function CHuodong:MonthCardChargeReward(oPlayer, sKey)
    local iPid = oPlayer:GetPid()

    local mConfig = self:GetCardConfig()
    local mGift = mConfig[sKey]
    if not mGift then return end

    local iCurDay = self:GetDayNo()
    local iContinue = mGift.days - 1
    self:Dirty()
    local mData = table_get_depth(self.m_mMonthCard, {iPid, sKey})
    if mData and mData.end_day < iCurDay then
        mData = nil
    end
    if not mData then
        mData = {last_day=iCurDay-1, start_day=iCurDay, end_day=iCurDay+iContinue}
        table_set_depth(self.m_mMonthCard, {iPid}, sKey, mData)
    else
        mData.end_day = mData.end_day + mGift.days
    end
    local iOldGoldCoin = oPlayer:GoldCoin()
    local iGoldCoin = mGift.goldcoin_first
    oPlayer:ChargeGoldCoin(mGift.goldcoin_first, mGift.payid)
    self:RefreshCardUnit(oPlayer, sKey)
    self:TryRewardMonthCardByMail(iPid,sKey,iCurDay)
    local lRewardIdx = mGift.reward_id or {}
    for _,iRewardIdx in ipairs(lRewardIdx) do
        self:Reward(iPid,iRewardIdx)
    end
    oPlayer:Set(sKey,iCurDay)
    local sProductKey = mGift.payid
    local mInfo = {
        keyword = sKey,
        data = mData,
        action = "charge_yk_first",
        payid = sProductKey
    }
    record.log_db("huodong", "charge", {pid=iPid, info=mInfo})
    oPlayer:OnChargeCard(sKey)
    self:BroadCast(oPlayer,3002)
end

--终身卡充值初次奖励
function CHuodong:ZskCardChargeReward(oPlayer,sKey)
    local iPid = oPlayer:GetPid()
    if not self:CanBuyZskCard(iPid) then
        return
    end

    local mConfig = self:GetCardConfig()
    local mGift = mConfig[sKey]
    if not mGift then
        return
    end

    self:Dirty()
    local iCurDay = self:GetDayNo()
    self.m_mZskCard[iPid] = {last_day=iCurDay-1,start_day=iCurDay}
    local iOldGoldCoin = oPlayer:GoldCoin()
    local iGoldCoin = mGift.goldcoin_first
    oPlayer:ChargeGoldCoin(mGift.goldcoin_first, mGift.payid)
    self:TryRewardZskCardByMail(iPid,sKey,iCurDay)

    self:RefreshCardUnit(oPlayer, sKey)
    local lRewardIdx = mGift.reward_id or {}
    for _,iRewardIdx in ipairs(lRewardIdx) do
        self:Reward(iPid,iRewardIdx)
    end
    oPlayer:Set(sKey,iCurDay)
    local sProductKey = mGift.payid
    local mInfo = {
        keyword = sKey,
        data = mData,
        action = "charge_zsk_first",
        payid = sProductKey
    }
    record.log_db("huodong", "charge", {pid=iPid, info=mInfo})
    oPlayer:OnChargeCard(sKey)
    self:BroadCast(oPlayer,3001)
end

--后续奖励， 初次奖励不在此领取
function CHuodong:TryRewardMonthCard(oPlayer, sKey)
    local mConfig = self:GetCardConfig()
    local mGift = mConfig[sKey]
    if not mGift then
        return
    end
    --[[
    if oPlayer.m_oToday:Query(sKey,0) ~= 0 then
        self:Notify(iPid, 1003)
        return
    end
    ]]

    local iPid = oPlayer:GetPid()
    local mData = table_get_depth(self.m_mMonthCard, {iPid, sKey})
    if not mData then
        return
    end

    local iCurDay = self:GetDayNo()
    if iCurDay == mData.last_day then
        self:Notify(iPid, 1003)
        return
    end

    if iCurDay > mData.end_day then
        self:Dirty()
        self.m_mMonthCard[iPid][sKey] = nil
        return
    end

    self:Dirty()
    oPlayer:RewardGoldCoin(mGift.goldcoin_after, mGift.payid)
    self.m_mMonthCard[iPid][sKey]["last_day"] = iCurDay

    if iCurDay == mData.end_day then
        self.m_mMonthCard[iPid][sKey] = nil
        local mMailData, sName = global.oMailMgr:GetMailInfo(56)
        global.oMailMgr:SendMail(0, sName, iPid, mMailData)
    end
    self:RefreshCardUnit(oPlayer, sKey)
    oPlayer.m_oToday:Set(sKey,1)

    local mInfo = {
        keyword = sKey,
        data = mData,
        action = "yk_goldcoin_after",
        payid = mGift.payid
    }
    record.log_db("huodong", "charge", {pid=iPid, info=mInfo})
end

--终身卡后续奖励， 初次奖励不在此领取
function CHuodong:TryRewardZskCard(oPlayer, sKey)
    local mConfig = self:GetCardConfig()
    local mGift = mConfig[sKey]
    if not mGift then
        return
    end
    --[[
    if oPlayer.m_oToday:Query(sKey,0) ~= 0 then
        self:Notify(iPid, 1003)
        return
    end
    ]]

    local iPid = oPlayer:GetPid()
    local mData = self.m_mZskCard[iPid]
    if not mData then
        return
    end

    local iCurDay = self:GetDayNo()
    if iCurDay == mData.last_day then
        self:Notify(iPid, 1003)
        return
    end
    self:Dirty()
    self.m_mZskCard[iPid]["last_day"] = iCurDay
    oPlayer:RewardGoldCoin(mGift.goldcoin_after, mGift.payid)
    self:RefreshCardUnit(oPlayer, sKey)
    oPlayer.m_oToday:Set(sKey,1)
    local mInfo = {
        keyword = sKey,
        data = mData,
        action = "zsk_goldcoin_after",
        payid = mGift.payid
    }
    record.log_db("huodong", "charge", {pid=iPid, info=mInfo})
end

function CHuodong:RefreshCardUnit(oPlayer, sKey)
    local mNet = self:GetCardNetInfo(oPlayer,sKey)
    oPlayer:Send("GS2CChargeCard", {charge_card = mNet})
end

function CHuodong:GetCardNetInfo(oPlayer,sKey)
    local mNet = {}
    local iPid = oPlayer:GetPid()
    mNet.type = sKey
    if sKey == "zsk" then
        mNet.val = self:GetZskCardStatus(iPid,sKey)
    else
        mNet.val = self:GetCardStatus(iPid,sKey)
    end
    mNet.left_count = self:GetCardLeftCount(iPid,sKey)
    mNet.next_time = self:GetNextTime()
    return mNet
end

function CHuodong:GetNextTime()
    local iNowTime = get_time()
    local mDate = get_daytime({day=1})
    return math.max(0,mDate.time - iNowTime)
end

function CHuodong:GetCardLeftCount(iPid,sKey)
    local iLeftDay = 0
    if table_in_list({"yk"},sKey) then
        local mData = table_get_depth(self.m_mMonthCard,{iPid,sKey})
        if not mData then
            return iLeftDay
        end
        local iCurDay = self:GetDayNo()
        if mData.end_day < iCurDay then
            return iLeftDay
        end
        local iLastDay = mData.last_day
        local iEndDay = mData.end_day
        return iEndDay - iLastDay
    end
    return iLeftDay
end

function CHuodong:GetCardStatus(iPid, sKey)
    local mData = table_get_depth(self.m_mMonthCard, {iPid, sKey})
    if not mData then
        return STATUS_UNCHARGE
    end
    local iCurDay = self:GetDayNo()
    if mData.end_day < iCurDay then
        return STATUS_UNCHARGE
    end

    if mData.last_day < iCurDay then
        return STATUS_REWARD
    else
        return STATUS_REWARDED
    end
end

function CHuodong:GetZskCardStatus(iPid)
    local mData = self.m_mZskCard[iPid]
    if not mData then
        return STATUS_UNCHARGE
    end
    local iCurDay = self:GetDayNo()
    if mData.last_day < iCurDay then
        return STATUS_REWARD
    else
        return STATUS_REWARDED
    end
end

--是否充值终身卡
function CHuodong:IsZskVip(iPid)
    if self.m_mZskCard[iPid] then
        return true
    end
    return false
end

--是否是月卡
function CHuodong:IsMonthCardVip(iPid)
    if self.m_mTodayMonthCard[iPid] then
        return true
    end
    local iCurDay = self:GetDayNo()
    local sKey = "yk"
    local mData = table_get_depth(self.m_mMonthCard, {iPid, sKey})
    if not mData then
        return false
    end
    local iEndDay = mData.end_day
    if iEndDay < iCurDay then
        return false
    end
    return true
end

--月卡领取次数小于３次时是否提示
function CHuodong:IsMonthVipNotify(iPid)
    local res = require "base.res"
    local sType = "yk"
    if not self.m_mMonthCard[iPid] then
        return false
    end
    local mData = self.m_mMonthCard[iPid][sType]
    if not mData then
        return false
    end
    local iLeftDay = res["daobiao"]["global"]["charge_card_notify"]["value"]
    iLeftDay = tonumber(iLeftDay)
    local iCurDay = self:GetDayNo()
    local iEndDay = mData.end_day
    if iEndDay - iCurDay < iLeftDay then
        return true
    end
    return false
end

function CHuodong:GetMonthCardLeftDay(iPid)
    local sType = "yk"
    local mData = self.m_mMonthCard[iPid][sType]
    if not mData then
        return 0
    end
    local iCurDay = self:GetDayNo()
    local iEndDay = mData.end_day
    local iLeftDay = math.max(iEndDay - iCurDay,0)
    return iLeftDay
end

function CHuodong:TryRewardMonthCardByMail(iPid, sKey, iCheckDay)
    local mData = table_get_depth(self.m_mMonthCard, {iPid, sKey})
    if not mData then
        return
    end

    local mConfig = self:GetCardConfig()
    local mGift = mConfig[sKey]
    if not mGift then
        return
    end
    if iCheckDay > mData.last_day then
        self:Dirty()
        mData.last_day = iCheckDay
        local oMailMgr = global.oMailMgr
        local iGoldCoin = mGift.goldcoin_after
        local iMailId = 55
        local mMailData, sName = oMailMgr:GetMailInfo(iMailId)
        local oItem = loaditem.Create(10030)
        oItem:SetAmount(5)
        oMailMgr:SendMail(0, sName, iPid, mMailData, {{sid=1, value=iGoldCoin}}, {oItem,})

        self.m_mTodayMonthCard[iPid] = 1

        if iCheckDay  >= mData.end_day then
            self.m_mMonthCard[iPid][sKey] = nil
            local mMailData, sName = global.oMailMgr:GetMailInfo(56)
            global.oMailMgr:SendMail(0, sName, iPid, mMailData)
        end
        local mLogInfo = {
            keyword = sKey,
            data = mData,
            action = "yk_goldcoin_mail",
        }
        record.log_db("huodong", "charge", {pid=iPid, info=mLogInfo})
    end

    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        self:RefreshCardUnit(oPlayer,sKey)
    end
end

function CHuodong:TryRewardZskCardByMail(iPid,sKey,iCheckDay)
    local mData = self.m_mZskCard[iPid]
    if not mData then
        return
    end

    local mConfig = self:GetCardConfig()
    local mGift = mConfig[sKey]
    if not mGift then
        return
    end
    if iCheckDay > mData.last_day then
        self:Dirty()
        mData.last_day = iCheckDay
        local iGoldCoin = mGift.goldcoin_after
        local iMailId = 63
        local oMailMgr = global.oMailMgr
        local mMailData, sName = oMailMgr:GetMailInfo(iMailId)
        local oItem = loaditem.Create(10030)
        oItem:SetAmount(10)
        oMailMgr:SendMail(0, sName, iPid, mMailData, {{sid=1, value=iGoldCoin}}, {oItem,})

        local mLogInfo = {
            keyword = sKey,
            data = mData,
            action = "zsk_goldcoin_mail",
        }
        record.log_db("huodong", "charge", {pid=iPid, info=mLogInfo})
    end

    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        self:RefreshCardUnit(oPlayer,sKey)
    end
end

function CHuodong:TestOP(oMaster,iFlag,...)
    local mArgs = {...}
    local iPid = oMaster:GetPid()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oNotifyMgr = global.oNotifyMgr
    self.m_OrderID = self.m_OrderID or 1000
    self.m_OrderID = self.m_OrderID + 1
    if iFlag == 100 then
        global.oNotifyMgr:Notify(iPid, [[
        201 - 模拟充值月卡
        202 - 模拟充值终身卡
        203 - 离线发放月卡,终身卡邮件奖励
        204 - 模拟刷天 {1}
        205 - 清除月卡终身卡信息
        301 - 模拟充值98(充值基金)
        302 - 领取等级元宝 {sType, grade}
        401 - 模拟充值 {iType}
        501 - 数据中心充值LOG
        ]])
    elseif iFlag == 101 then
        self:InitOpenTime()
    elseif iFlag == 102 then
        self:Dirty()
        self.m_iStartTime = 0
        self.m_iEndTime = 0
        self.m_iRewardSchedule = 0
    elseif iFlag == 103 then
        print("hcdebug111",os.date("*t",self.m_iStartTime))
        print("hcdebug111",os.date("*t",self.m_iEndTime))
    elseif iFlag == 201 then
        local mPayArgs = {
            no_analylog = true,
        }
        self:OnCharge(oMaster, 1, "yk", "com.kaopu.ylq.appstore.yk",0,mPayArgs)
    elseif iFlag == 202 then
        local mPayArgs = {
            no_analylog = true,
        }
        self:OnCharge(oMaster, 1, "zsk", "com.kaopu.ylq.appstore.zsk",0,mPayArgs)
    elseif iFlag == 203 then
        self:NewDay()
    elseif iFlag == 204 then
        self.m_iTestDayNo = get_dayno() + mArgs[1]
        self:NewDay()
    elseif iFlag == 205 then
        self:Dirty()
        self.m_iTestDayNo = nil
        self:Init()
    elseif iFlag == 206 then
        if #mArgs < 1 then
            return
        end
        local iPid = mArgs[1]
        self:Dirty()
        self.m_mMonthCard[iPid] = nil
        self.m_mTodayMonthCard[iPid] = nil
        self:RefreshCardUnit(oMaster,"yk")
    elseif iFlag == 207 then
        local iDay = self:GetDayNo()
        iDay = iDay - get_dayno()
        local sMsg = string.format("当前设置天数%d",iDay)
        global.oNotifyMgr:Notify(oMaster:GetPid(),sMsg)
    elseif iFlag == 208 then
        self.m_iTestDayNo = nil
        local iDay = self:GetDayNo()
        iDay = iDay - get_dayno()
        local sMsg = string.format("当前设置天数%d",iDay)
        global.oNotifyMgr:Notify(oMaster:GetPid(),sMsg)
    elseif iFlag == 209 then
        local iPid = oMaster:GetPid()
        local mData = self.m_mMonthCard[iPid]
        print(mData,self.m_iTestDayNo,get_dayno())
    elseif iFlag == 301 then
        local mPayArgs = {
            no_analylog = true,
        }
        self:OnCharge(oMaster, 1, "grade_gift1", "com.kaopu.ylq.czjj",0,mPayArgs)
    elseif iFlag == 302 then
        local sType = "grade_gift1"
        local iGrade = mArgs[1]
        self:TryRewardGradeGift(oMaster, sType, iGrade)
    elseif iFlag == 401 then
        --sKey:1001-1006
        local sKey = mArgs[1]
        local mConfig = self:GetChargeConfig()
        local iKey = tonumber(sKey)
        local mInfo = mConfig[iKey]
        local mPayArgs = {
            no_analylog = true,
        }
        self:PayForGold(oMaster, mArgs[1],mInfo.payid,0,mPayArgs)
    elseif iFlag == 501 then
        local mOrder = {
            amount = 6,
            product_key = "com.kaopu.ylq.6",
            product_amount = 1,
            orderid = math.random(10001, 99999),
        }
        global.oPayMgr:PaySuccessLog(oMaster:GetPid(), mOrder)
    elseif iFlag == 601 then
        if #mArgs < 1 then
            return
        end
        local iPid = mArgs[1]
        local mOrder = {
            product_key = "com.kaopu.ylq.appstore.648",
            product_amount = 1,
        }
        print("charge",iPid,mOrder)
        global.oPayMgr:DealSucceedOrder(iPid,mOrder)
    elseif iFlag == 1001 then
        local sProductKey = mArgs[1]
        local iGoodsKey = mArgs[2]
        local mPayArgs = {
            goods_key = iGoodsKey,
        }
        global.oPayMgr:TryPay(oMaster, sProductKey,1, "demi",mPayArgs)
    elseif iFlag == 1002 then
        local mArgs = {
            goods_key = 212011,
        }
        self:OnCharge(oMaster,1,"giftbag_1","com.kaopu.ylq.appstore.lb.1",self.m_OrderID,mArgs)
    elseif iFlag == 1003 then
        local oNotifyMgr = global.oNotifyMgr
        local iGoodsKey = mArgs[1]
        if not iGoodsKey then
            return
        end
        local mItem = global.oStoreMgr:GetItem(iGoodsKey)
        local sProductKey = mItem["iospayid"]
        local mData = assert(res["daobiao"]["pay"][sProductKey], string.format("deal order error product key %s", sProductKey))
        local lArgs = mData["args"]
        local mArgs = {
            goods_key = iGoodsKey,
        }
        self:OnCharge(oMaster,1,table.unpack(lArgs),sProductKey,self.m_OrderID,mArgs)
    elseif iFlag == 1004 then
        local mArgs = {
            grade_key = 16,
        }
        self:OnCharge(oMaster,1,"giftbag_1","com.kaopu.ylq.appstore.lb.1",self.m_OrderID,mArgs)
    elseif iFlag == 1005 then
        local iKey, sKeyWord, sProductKey = table.unpack(mArgs)
        local mArg = {
            one_RMB_gift =iKey
        }
        self:OnCharge(oMaster,1,sKeyWord, sProductKey, self.m_OrderID,mArg)
    elseif iFlag == 1006 then
        local iKey, sKeyWord, sProductKey = table.unpack(mArgs)
        local mArg = {
            grade_key =iKey
        }
        self:OnCharge(oMaster,1,sKeyWord, sProductKey, self.m_OrderID,mArg)
    end
end


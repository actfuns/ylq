--import module
local global = require "global"
local res = require "base.res"
local extend = require "base.extend"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local defines = import(service_path("house.defines"))
local timectrl = import(lualib_path("public.timectrl"))
local gamedefines = import(lualib_path("public.gamedefines"))

CPartnerCtrl = {}
CPartnerCtrl.__index = CPartnerCtrl
inherit(CPartnerCtrl, datactrl.CDataCtrl)

function CPartnerCtrl:New(iPid)
    local o = super(CPartnerCtrl).New(self, {pid = iPid})
    o.m_iOwner = iPid
    o.m_mList = {}
    o.m_iLoveCnt = defines.PARTNER_MAX_LOVE_CNT              --爱抚次数
    o.m_iLastLoveTime = 0                                                           --最后一次爱抚的时间
    o.m_iExtendTrainSpace = 0                                                    --购买的特训空间
    o.m_iCoinTime = 0                                                        --产出金币时间
    o.m_iTotalShip =0                                                       --总亲密度
    o.m_iBuffStage = 0                                             --总亲密度等级
    o.m_oToday = timectrl.CToday:New(iPid)
    return o
end

function CPartnerCtrl:NewDay(iWeekDay)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetOwner())
    if oPlayer then
        self:SendPartnerExchangeUI(1)
    end
end

function CPartnerCtrl:Load(mData)
    mData = mData or {}
    local mPartnerData = mData["partner"] or {}
    for _,mData in pairs(mPartnerData) do
        local iType = mData["type"]
        local oPartner = NewPartner(iType)
        oPartner:Load(mData)
        oPartner:SetOwner(self.m_iOwner)
        self.m_mList[iType] = oPartner
        oPartner:Setup()
    end
    local iLoveCnt = mData["love_cnt"] or self.m_iLoveCnt
    iLoveCnt = math.min(iLoveCnt, self.m_iLoveCnt)
    iLoveCnt = math.max(iLoveCnt, 0)
    self.m_iLoveCnt = iLoveCnt
    self.m_iLastLoveTime = mData["last_love_time"] or self.m_iLastLoveTime
    self.m_iExtendTrainSpace = mData["extend_train_space"] or self.m_iExtendTrainSpace
    self.m_iCoinTime = mData["coin_time"] or 0
    self.m_iTotalShip = mData["total_ship"] or 0
    self.m_iBuffStage = mData["total_ship_level"] or 0
    local mToday = mData["today"] or {}
    self.m_oToday:Load(mToday)

    self:CheckPartner()
    self:CheckPartnerCoin()
end

function CPartnerCtrl:Save()
    local mData = {}
    local mPartnerData = {}
    for _,oPartner in pairs(self.m_mList) do
        table.insert(mPartnerData,oPartner:Save())
    end
    mData["partner"] = mPartnerData
    mData["love_cnt"] = self.m_iLoveCnt
    mData["extend_train_space"] = self.m_iExtendTrainSpace
    mData["last_love_time"] = self.m_iLastLoveTime
    mData["today"] = self.m_oToday:Save()
    mData["coin_time"] = self.m_iCoinTime or 0
    mData["total_ship"] = self.m_iTotalShip or 0
    mData["total_ship_level"] = self.m_iBuffStage or 0
    return mData
end

function CPartnerCtrl:Setup()
    self:CheckLoveCnt()
end

function CPartnerCtrl:CheckPartner()
    local res = require "base.res"
    local mData = res["daobiao"]["housepartner"]
    local sReason = "默认伙伴"
    for iType, m in pairs(mData) do
        if m.unlock_type == 0  and  not self:GetPartner(iType) then
            local oPartner = NewPartner(iType)
            self:AddPartner(oPartner,sReason)
        end
    end
end

function CPartnerCtrl:CheckPartnerCoin()
    if self:ValidRandomCoin() then
        local iSecs = self.m_iCoinTime - get_time()
        if iSecs > 0 then
            self:DelTimeCb("random_coin")
            self:AddTimeCb("random_coin", iSecs * 1000, function()
                self:RandomCoin()
            end)
        else
            self:RandomCoin()
        end
    end
end

function CPartnerCtrl:GetOwner()
    return self.m_iOwner
end

function CPartnerCtrl:GetHouse()
    local oHouseMgr = global.oHouseMgr
    local oHouse = oHouseMgr:GetHouse(self.m_iOwner)
    return oHouse
end

function CPartnerCtrl:AddPartner(oPartner, sReason)
    local iType = oPartner:Type()
    if self:GetPartner(iType) then
        return
    end
    self:Dirty()
    oPartner:SetOwner(self.m_iOwner)
    self.m_mList[iType] = oPartner
    record.user("house", "addpartner", {
        pid = self:GetOwner(),
        partype = iType,
        reason = sReason,
        })
end

function CPartnerCtrl:GetPartner(iType)
    return self.m_mList[iType]
end

function CPartnerCtrl:CountPartner()
    return table_count(self.m_mList)
end

function CPartnerCtrl:OnEnter(iPid)
    self:SendPartnerExchangeUI()
end

function CPartnerCtrl:ValidShowLove(iPid)
    if self:GetLoveCnt() <= 0 then
        return false
    end
    return true
end

function CPartnerCtrl:ShowLove(iPid,iType,sPart)
    self:Dirty()
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local iMaxCnt = defines.PARTNER_MAX_LOVE_CNT
    local bFlag = false
    if self:GetLoveCnt() == iMaxCnt then
        bFlag = true
    end
    local oPartner = self:GetPartner(iType)
    if bFlag then
        self.m_iLastLoveTime = get_time()
        local iOwner = self:GetOwner()
        local oHouseMgr = global.oHouseMgr
        self:DelTimeCb("SuppleLoveCnt")
        self:AddTimeCb("SuppleLoveCnt",self:LoveCntCD() * 1000,function ()
            local oHouse = oHouseMgr:GetHouse(iOwner)
            if oHouse and oHouse.m_oPartnerCtrl then
                oHouse.m_oPartnerCtrl:SuppleLoveCnt()
            end
         end)
    end
    self:AddLoveCnt(-1, "ShowLove")
    oPartner:ShowLove(iPid,sPart)
end

function CPartnerCtrl:CheckLoveCnt()
    if self:GetLoveCnt() >= defines.PARTNER_MAX_LOVE_CNT then
        return
    end
    local iSuppleTime = self.m_iLastLoveTime
    local iRecoverCD = self:LoveCntCD()
    local iHour = math.floor((get_time() - iSuppleTime) / iRecoverCD)
    if iHour > 0 then
        self:Dirty()
        self.m_iLastLoveTime = self.m_iLastLoveTime + iHour * iRecoverCD
        self:AddLoveCnt(iHour, "CheckLoveCnt")
    end
    local iSecs = iRecoverCD - ((get_time() - iSuppleTime) % iRecoverCD)
    if iSecs > 0 then
        local iPid = self:GetOwner()
        local oHouseMgr = global.oHouseMgr
        self:DelTimeCb("SuppleLoveCnt")
        self:AddTimeCb("SuppleLoveCnt",iSecs * 1000,function ()
            local oHouse = oHouseMgr:GetHouse(iPid)
            if oHouse and oHouse.m_oPartnerCtrl then
                oHouse.m_oPartnerCtrl:SuppleLoveCnt()
            end
        end)
    end
end

function CPartnerCtrl:GetSuppleTime()
    if self:GetLoveCnt() >= defines.PARTNER_MAX_LOVE_CNT then
        return 0
    end
    local iTime = self:LoveCntCD() - (get_time() - self.m_iLastLoveTime)
    return math.max(iTime,0)
end

function CPartnerCtrl:SuppleLoveCnt()
    self:DelTimeCb("SuppleLoveCnt")
    if self:GetLoveCnt() >= defines.PARTNER_MAX_LOVE_CNT then
        return
    end
    self:Dirty()
    self.m_iLastLoveTime = get_time()
    local iPid = self:GetOwner()
    local oHouseMgr = global.oHouseMgr
    self:AddTimeCb("SuppleLoveCnt",self:LoveCntCD() * 1000,function ()
        local oHouse = oHouseMgr:GetHouse(iPid)
        if oHouse and oHouse.m_oPartnerCtrl then
            oHouse.m_oPartnerCtrl:SuppleLoveCnt()
        end
    end)
    local iCnt = 1
    self:AddLoveCnt(iCnt, "SuppleLoveCnt")
end

function CPartnerCtrl:GetLoveCnt()
    return self.m_iLoveCnt
end

function CPartnerCtrl:AddLoveCnt(iCnt, sReason)
    self:Dirty()
    local iLoveCnt = self.m_iLoveCnt
    local iOldCnt = iLoveCnt
    iLoveCnt = iLoveCnt + iCnt
    iLoveCnt = math.min(iLoveCnt, defines.PARTNER_MAX_LOVE_CNT)
    iLoveCnt = math.max(iLoveCnt,0)
    self.m_iLoveCnt = iLoveCnt
    local iPid = self:GetOwner()
    local oHouse = self:GetHouse()
    if oHouse:InHouse(iPid) then
        self:SendPartnerExchangeUI()
    end

    record.user("house", "parlove_count", {
        pid = iPid,
        old_cnt = iOldCnt,
        remain_cnt = self.m_iLoveCnt,
        reason = sReason,
        })
end

function CPartnerCtrl:TrainSpace()
    local iDefaultSpace = 1
    return iDefaultSpace + self.m_iExtendTrainSpace
end

function CPartnerCtrl:GetUsedSpace()
    local iCnt = 0
    for _,oPartner in pairs(self.m_mList) do
        if oPartner:IsTraining() then
            iCnt = iCnt + 1
        end
    end
    return iCnt
end

function CPartnerCtrl:ValidTrainPartner(iType,iTrainType)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = self:GetOwner()
    if self:TrainSpace() <= self:GetUsedSpace() then
        oNotifyMgr:Notify(iPid, "您的特训位已被占满")
        return false
    end
    local oPartner = self:GetPartner(iType)
    if not oPartner then
        oNotifyMgr:Notify(iPid, string.format("伙伴:%s不存在", iType))
        return false
    end
    if oPartner:TrainType() ~= 0 then
        oNotifyMgr:Notify(iPid, "伙伴正在特训")
        return false
    end
    for iType, oPartner in pairs(self.m_mList) do
        if oPartner:TrainType() == iTrainType then
            oNotifyMgr:Notify(iPid, "该特训位已被占满")
            return false
        end
    end
    return true
end

function CPartnerCtrl:TrainPartner(iType,iTrainType)
    local oPartner = self:GetPartner(iType)
    local iPid = self.m_iOwner
    oPartner:StartTrain(iPid,iTrainType)
end

function CPartnerCtrl:PromoteWarmLimit()
    local iPromoteLimit = 0
    for _,oPartner in pairs(self.m_mList) do
        iPromoteLimit = iPromoteLimit + oPartner:PromoteWarmLimit()
    end
    return iPromoteLimit
end

function CPartnerCtrl:LoveCntCD()
    local sVal = res["daobiao"]["global"]["house_recover_cnt_time"]["value"]
    return tonumber(sVal)
end

function CPartnerCtrl:RandomCoin()
    if self:ValidRandomCoin() then
        local iCoin = math.random(2000, 3000)
        local iType = table_random_key(self.m_mList)
        local oPartner = self:GetPartner(iType)
        if oPartner then
            oPartner:SetCoin(iCoin)
            oPartner:BroadCast()
        end
    end
end

function CPartnerCtrl:ValidRandomCoin()
    local iDailyCnt = self.m_oToday:Query("random_coin_cnt", 0)
    local iMaxCnt = defines.GetDaobiaoDefines("daily_coin_count")
    if iDailyCnt >= iMaxCnt then
        return false
    end
    if self:WithCoinPartner() then
        return false
    end

    return true
end

function CPartnerCtrl:WithCoinPartner()
    for iType, oPartner in pairs(self.m_mList) do
        if oPartner:HasCoin() then
            return oPartner
        end
    end
end

function CPartnerCtrl:ValidPartnerCoin(iFrdPid)
    local o = self:WithCoinPartner()
    if not o then
        global.oNotifyMgr:Notify(iFrdPid, "金币已被领取")
        return false
    end
    return true
end

function CPartnerCtrl:RecievePartnerCoin(iFrdPid)
    local oWorldMgr = global.oWorldMgr
    local oFrd = oWorldMgr:GetOnlinePlayerByPid(iFrdPid)
    local oPartner = self:WithCoinPartner()
    -- local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetOwner())
    if oPartner and oFrd then
        local iCoin = oPartner:GetCoin()
        oPartner:SetCoin(0)
        self.m_oToday:Add("random_coin_cnt", 1)
        self:CheckRandomCoin()
        oFrd:RewardCoin(iCoin, "领取好友宅邸金币")
        oPartner:BroadCast()
        --pid|玩家id,frd_pid|好友id,partype|伙伴id,daily_cnt|每日次数,coin|金币数量
        record.user("house", "receive_house_coin", {
            pid = self:GetOwner(),
            frd_pid = iFrdPid,
            partype = oPartner:Type(),
            daily_cnt = self.m_oToday:Query("random_coin_cnt", 0),
            coin = iCoin,
            })

        local mCurrency = {}
        mCurrency[gamedefines.COIN_FLAG.COIN_COIN] = iCoin
        local mLog = {}
        -- mLog["frd_pid"] = iFrdPid
        -- mLog["operation"] = "receive_house_coin"
        oFrd:LogAnalyGame(mLog,"house",{},mCurrency,{},0)
    end
end

function CPartnerCtrl:CheckRandomCoin()
    local oHouseMgr = global.oHouseMgr
    local iPid = self:GetOwner()

    self.m_iCoinTime = 0
    local iDailyCnt = self.m_oToday:Query("random_coin_cnt", 0)
    local iDailyMax = defines.GetDaobiaoDefines("daily_coin_count")
    if iDailyCnt < iDailyMax then
        local iSecs = math.random(defines.RANDOM_COIN_TIME.MIN_TIME, defines.RANDOM_COIN_TIME.MAX_TIME)
        self.m_iCoinTime = get_time() + iSecs
        self:DelTimeCb("random_coin")
        self:AddTimeCb("random_coin", iSecs * 1000, function()
            local oHouse = oHouseMgr:GetHouse(iPid)
            if oHouse then
                oHouse.m_oPartnerCtrl:RandomCoin()
            end
        end)
    end
end

function CPartnerCtrl:IsMaxBuffStage()
    return self.m_iBuffStage >= defines.TOTAL_LOVE_BUFF_STAGE
end

function CPartnerCtrl:CheckTotalLoveLevel(sReason)
    if self:IsMaxBuffStage()  then
        return
    end

    self:Dirty()
    self:CheckBuffStage(sReason)
end

function CPartnerCtrl:CheckBuffStage(sReason)
    local iOldStage = self.m_iBuffStage
    local mLoveBuff = defines.GetLoveBuffData(iOldStage)
    if not mLoveBuff then
        return
    end
    local iUpLv = mLoveBuff.total_level
    local iCntLv = self:CountPartnerLevel()
    if iCntLv > iUpLv then
        local res = require "base.res"
        local mData =  res["daobiao"]["house_lovebuff"]
        for iStage, mLove in pairs(mData) do
            if mLove.total_level <=  iCntLv then
                self.m_iBuffStage = math.max(self.m_iBuffStage, iStage)
            end
        end
    end
    if self.m_iBuffStage > iOldStage then
        self:UpdatePlayerBuff()
        self:RefreshLoveBuff()

        record.user("house", "love_buff_stage", {
            pid = self:GetOwner(),
            old_stage = iOldStage,
            now_stage = self.m_iBuffStage,
            reason = sReason,
            })
    end
end

function CPartnerCtrl:CountPartnerLevel()
    local iCnt = 0
    for iType, oPartner in pairs(self.m_mList) do
        iCnt = iCnt + oPartner:LoveLevel()
    end
    return iCnt
end

function CPartnerCtrl:RefreshLoveBuff()
    local iPid = self:GetOwner()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oHouse = self:GetHouse()
    if not oHouse then
        return
    end
    local iStage = self.m_iBuffStage
    oPlayer:Send("GS2CRefreshHouseBuff", {buff_info = self:PackHouseBuff()})
end

function CPartnerCtrl:UpdatePlayerBuff()
    local iPid = self:GetOwner()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    if self.m_iBuffStage == 0 then
        return
    end
    local mBuff = self:GetHouseBuff()
    oPlayer:UpdateHouseAttr(mBuff)
end

function CPartnerCtrl:GetHouseBuff()
    local mBuff = {}
    local iStage = self.m_iBuffStage
    local mLoveBuff = defines.GetLoveBuffData(iStage)
    local sAttr = mLoveBuff.buff
    if sAttr and sAttr ~= "" then
        mBuff.attr = formula_string(sAttr, {})
    end
    local sRatio = mLoveBuff.buff_ratio
    if sRatio and sRatio  ~= "" then
        mBuff.ratio = formula_string(sRatio, {})
    end
    return mBuff
end

function CPartnerCtrl:SendPartnerExchangeUI(iHandle)
    local iPid = self:GetOwner()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oHouse = self:GetHouse()
    if not oHouse then
        return
    end
    oPlayer:Send("GS2CPartnerExchangeUI",{
        love_cnt = self:GetLoveCnt(),
        max_love_cnt = defines.PARTNER_MAX_LOVE_CNT,
        partner_gift_cnt = oHouse:ParnterGiftCnt(),
        max_gift_cnt = defines.PARTNER_MAX_GIFT_CNT,
        supple_love_time = self:GetSuppleTime(),
        daily_buy_gift = oHouse:GetGiftBuyCnt(oPlayer),
        handle_type = iHandle,
    })
end

function CPartnerCtrl:PackNetInfo()
    local mNet = {}
    for _,oPartner in pairs(self.m_mList) do
        table.insert(mNet,oPartner:PackNetInfo())
    end
    return mNet
end

function CPartnerCtrl:PackHouseBuff()
    return {
        stage = self.m_iBuffStage,
        loveship = self.m_iTotalShip,
    }
end

function CPartnerCtrl:IsDirty()
    local bFlag = super(CPartnerCtrl).IsDirty(self)
    if bFlag then
        return true
    end
    for _,oPartner in pairs(self.m_mList) do
        if oPartner:IsDirty() then
            return true
        end
    end
    return false
end

function CPartnerCtrl:UnDirty()
    super(CPartnerCtrl).UnDirty(self)
    for _,oPartner in pairs(self.m_mList) do
        oPartner:UnDirty()
    end
end

CPartner = {}
CPartner.__index = CPartner
inherit(CPartner,datactrl.CDataCtrl)

function CPartner:New(iType)
    local o = super(CPartner).New(self)
    o.m_iType = iType
    o.m_iLoveShip = 0                                                 --亲密度
    o.m_iLoveLevel = 0                                                --亲密等级
    o.m_iTrainTime = 0                                                --特训结束时间
    o.m_iTrainType = defines.TRAIN_STATUS.FREE  --特训类型
    o.m_iRanCoin = 0                                                        --随机金币
    o.m_mUnChainLevel = {}                                       --已经解锁的等级
    return o
end

function CPartner:Load(mData)
    mData = mData or {}
    self.m_iLoveShip = mData["love_ship"] or self.m_iLoveShip
    self.m_iLoveLevel = mData["love_level"] or self.m_iLoveLevel
    self.m_iTrainTime = mData["train_time"] or self.m_iTrainTime
    self.m_iTrainType = mData["train_type"] or self.m_iTrainType
    self.m_mUnChainLevel = mData["unchain_level"] or self.m_mUnChainLevel
    self.m_iLoveLevel  = math.min(self.m_iLoveLevel, 100)
    self.m_iRanCoin = mData["ran_coin"]  or 0
end

function CPartner:Save()
    local mData = {}
    mData["type"] = self.m_iType
    mData["love_ship"] = self.m_iLoveShip
    mData["love_level"] = self.m_iLoveLevel
    mData["train_time"] = self.m_iTrainTime
    mData["train_type"] = self.m_iTrainType
    mData["unchain_level"] = self.m_mUnChainLevel
    mData["rand_coin"] = self.m_iRanCoin or 0
    return mData
end

function CPartner:Setup()
    if self.m_iTrainTime > 0 then
        if get_time() < self.m_iTrainTime then
            local iTime = self.m_iTrainTime - get_time()
            local iPid = self:GetOwner()
            local iType = self.m_iType
            self:AddTimeCb("TrainOver",iTime*1000,function ()
                local oPartner = defines.GetPartner(iPid,iType)
                if oPartner then
                    oPartner:TrainOver(true)
                end
            end)
        else
            self:TrainOver(true)
        end
    end
end

function CPartner:GetPartnerData()
    local res = require "base.res"
    local mData = res["daobiao"]["housepartner"][self.m_iType]
    return mData
end

function CPartner:GetHouseLoveData(iLevel)
    local res = require "base.res"
    local mData = res["daobiao"]["houselove"][iLevel]
    assert(mData,string.format("house love err:%s",iLevel))
    return mData
end

function CPartner:GetLoveStageData()
    local res = require "base.res"
    return res["daobiao"]["lovestage"]
end

function CPartner:GetPartnerLoveData(sPart)
    local res = require "base.res"
    local iStage = self:LoveStage()
    local mData = res["daobiao"]["partner_love"][self.m_iType][iStage]
    mData = mData[sPart]
    return mData
end

function CPartner:GetTrainData(iTrainType)
    local res = require "base.res"
    local mData = res["daobiao"]["partner_train"][iTrainType]
    assert(mData,string.format("partner train GetTrainData err :%s",iTrainType))
    return mData
end

function CPartner:GetParterTaskData(iLevel)
    local res = require "base.res"
    local mData = res["daobiao"]["partner_task"][self.m_iType][iLevel]
    return mData
end

function CPartner:EffectArgs(iLevel)
    local mData = self:GetHouseLoveData(iLevel)
    local sEffect = mData["effect"]
    local mArgs = {}
    if not sEffect or sEffect == "" then
        return mArgs
    end
    local mEnv = {}
    mArgs = formula_string(sEffect,{})
    return mArgs
end

function CPartner:SetOwner(iOwner)
    self.m_iOwner = iOwner
end

function CPartner:GetOwner()
    return self.m_iOwner
end

function CPartner:GetHouse()
    local iOwner = self:GetOwner()
    local oHouseMgr = global.oHouseMgr
    local oHouse = oHouseMgr:GetHouse(iOwner)
    return oHouse
end

function CPartner:GetScene()
    local oHouse = self:GetHouse()
    if not oHouse then
        return
    end
    return oHouse:GetScene()
end

function CPartner:Type()
    return self.m_iType
end

function CPartner:TrainType()
    return self.m_iTrainType
end

function CPartner:HasCoin()
    return self.m_iRanCoin > 0
end

function CPartner:GetCoin()
    return self.m_iRanCoin
end

function CPartner:SetCoin(iCoin)
    self:Dirty()
    iCoin = iCoin or 0
    self.m_iRanCoin = iCoin
end

function CPartner:VipLoveShip(iAdd)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetOwner()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local iAddRatio = 0
        if oPlayer:IsMonthCardVip() then
            iAddRatio = iAddRatio + 0.05
        end
        if oPlayer:IsZskVip() then
            iAddRatio = iAddRatio + 0.1
        end
        return math.ceil(iAdd * (1+iAddRatio))
    end
    return iAdd
end

function CPartner:AddLoveShip(iLoveShip, sReason)
    self:Dirty()
    iLoveShip = self:VipLoveShip(iLoveShip)
    local iOldExp = self.m_iLoveShip
    self.m_iLoveShip = self.m_iLoveShip + iLoveShip
    self:CheckUpLevel(sReason)
    local oHouse = self:GetHouse()
    -- oHouse.m_oPartnerCtrl:AddTotalLoveShip(iLoveShip, sReason)

    record.user("house", "partnerexp", {
        pid = self:GetOwner(),
        partype = self:Type(),
        old_exp = iOldExp,
        new_exp = self.m_iLoveShip,
        reason = sReason,
        })
    return iLoveShip
end

function CPartner:CheckUpLevel(sReason)
    local iLevel = self.m_iLoveLevel
    if iLevel >= 100 then
        return
    end
    local iOldLv = iLevel
    local bUpLevel = false
    local mData = self:GetHouseLoveData(iLevel)
    local iLoveShip = mData["loveship"] or 100
    local oHouse = self:GetHouse()
    while(self.m_iLoveShip >= iLoveShip) do
        self:Dirty()
        self.m_iLoveShip = self.m_iLoveShip - iLoveShip
        self.m_iLoveLevel = self.m_iLoveLevel + 1
        self:OnUpLevel(iLevel)
        iLevel = self.m_iLoveLevel
        mData = self:GetHouseLoveData(iLevel)
        iLoveShip = mData["loveship"]
        bUpLevel = true

        local iType = defines.FURNITURE_TYPE.WORK_DESK
        local oFurniture = oHouse:GetFurniture(iType)
        oFurniture:CheckUnlockDeskByParLv(true)
        if self.m_iLoveLevel >= 100 then
            break
        end
    end
    if bUpLevel then
        local oHouse = self:GetHouse()
        oHouse.m_oPartnerCtrl:CheckTotalLoveLevel(sReason)
    end
    record.user("house", "partner_level", {
        pid = self:GetOwner(),
        partype = self:Type(),
        old_level = iOldLv,
        new_level = self.m_iLoveLevel,
        })
end

function CPartner:OnUpLevel(iLevel)
    --[[
    local mArgs = self:EffectArgs(iLevel)
    local iShape = mArgs["sid"]
    if not iShape then
        return
    end
    local iAmount = mArgs["amount"]
    if not iAmount then
        return
    end
    local oHouse = self:GetHouse()
    oHouse.m_oItemCtrl:GiveItem({[iShape] = iAmount})
    ]]
end

--亲密度阶段
function CPartner:LoveStage()
    local mData = self:GetLoveStageData()
    local iCurLevel = self.m_iLoveLevel
    local iDefaultStage = 1
    for _,mLoveData in pairs(mData) do
        local iStage = mLoveData["stage"]
        local iMinLevel = mLoveData["min_level"]
        local iMaxLevel = mLoveData["max_level"]
        if iCurLevel >= iMinLevel and iCurLevel <= iMaxLevel then
            return iStage
        end
    end
    return iDefaultStage
end

function CPartner:LoveLevel()
    return self.m_iLoveLevel
end

function CPartner:ShowLove(iPid,sPart)
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mData = self:GetPartnerLoveData(sPart)
    for _,mArgs in pairs(mData) do
        local sType = mArgs["type"]
        local iValue = mArgs["value"]
        if sType == "loveship" then
            local iValue = self:AddLoveShip(iValue, "伙伴爱抚")
            -- oNotifyMgr:Notify(iPid,string.format("+亲密度%s",iValue))
            break
        end
    end
    self:Refresh(iPid)
    if oPlayer then
        oPlayer:AddSchedule("partner_love")
        oPlayer:PushAchieve("互动", {value = 1})
    end
end

--特训状态
function CPartner:TrainStatus()
    if self.m_iTrainStatus then
        return self.m_iTrainStatus
    end
    if self.m_iTrainTime > 0 then
        if get_time() < self.m_iTrainTime then
            self.m_iTrainStatus = defines.TRAIN_STATUS.TRAINING
        else
            self.m_iTrainStatus = defines.TRAIN_STATUS.TRAINED
        end
    else
        self.m_iTrainStatus = defines.TRAIN_STATUS.FREE
    end
    return self.m_iTrainStatus
end

function CPartner:IsTraining()
    if self:TrainStatus() == defines.TRAIN_STATUS.TRAINING then
        return true
    end
    return false
end

function CPartner:StartTrain(iPid,iTrainType)
    self:Dirty()
    self.m_iTrainType = iTrainType
    local mData = self:GetTrainData(iTrainType)
    local oHouse = self:GetHouse()
    local iTrainSecs =  oHouse and oHouse:GetTestInfo("partner_train_time")
    if not iTrainSecs then
        iTrainSecs = mData["time"] * 60
    end
    self.m_iTrainTime = get_time() + iTrainSecs
    self.m_iTrainStatus = defines.TRAIN_STATUS.TRAINING
    local iPid = self:GetOwner()
    local iType = self.m_iType
    self:DelTimeCb("TrainOver")
    self:AddTimeCb("TrainOver",iTrainSecs*1000,function ()
        local oPartner = defines.GetPartner(iPid,iType)
        if oPartner then
            oPartner:TrainOver()
        end
    end)
    self:BroadCast()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:PushAchieve("特训", {value = 1})
    end
    self:LogTrainStatus()
end

function CPartner:TrainOver(bNoRefresh)
    self:Dirty()
    local iTrainType = self.m_iTrainType
    self.m_iTrainTime = 0
    self.m_iTrainStatus = defines.TRAIN_STATUS.TRAINED
    if not bNoRefresh then
        self:BroadCast()
    end
    self:LogTrainStatus()
end

function CPartner:ValidRecieveTrain(oPlayer)
    if self.m_iTrainType == 0 then
        self.m_iTrainStatus = defines.TRAIN_STATUS.FREE
        self:BroadCast()
        return false
    end
    if self:TrainStatus() == defines.TRAIN_STATUS.FREE then
        self.m_iTrainType = 0
        self.m_iTrainTime = 0
        self:BroadCast()
        return false
    end
    if self:TrainStatus() ~= defines.TRAIN_STATUS.TRAINED then
        return false
    end
    return true
end

function CPartner:RecieveTrainReward()
    local sReason = "特训奖励"
    local oNotifyMgr = global.oNotifyMgr
    local iTrainType = self.m_iTrainType
    self.m_iTrainType = 0
    self.m_iTrainStatus = defines.TRAIN_STATUS.FREE
    local mData = self:GetTrainData(iTrainType)
    local iLoveShip = mData["loveship"]
    self:AddLoveShip(iLoveShip, sReason)
    self:BroadCast()
    oNotifyMgr:Notify(self.m_iOwner, string.format("+亲密度%s",iLoveShip))
    self:LogTrainStatus()
end

function CPartner:PromoteWarmLimit()
    local iLimit = 0
    local mLevel = {25,50,75,100}
    for _,iLevel in pairs(mLevel) do
        local mArgs = self:EffectArgs(iLevel)
        local iValue = mArgs["warm_degree_limit"]
        iLimit = iLimit + iValue
    end
    return 0
end

function CPartner:ValidUnChainRewardLevel(iLevel)
    if iLevel > self.m_iLoveLevel then
        return false
    end
    if table_in_list(self.m_mUnChainLevel,iLevel) then
        return false
    end
    return true
end

function CPartner:UnChainRewardLevel(iPid,iLevel)
    self:Dirty()
    table.insert(self.m_mUnChainLevel,iLevel)
    self:Refresh(iPid)
end

function CPartner:RemoveUnChainLevel(iPid, iLevel)
    self:Dirty()
    extend.Array.remove(self.m_mUnChainLevel, iLevel)
    self:Refresh(iPid)
end

function CPartner:Refresh(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CPartnerInfo",{
            partner_info = self:PackNetInfo()
        })
    end
end

function CPartner:BroadCast()
    local oScene = self:GetScene()
    if not oScene then
        return
    end
    oScene:BroadCast("GS2CPartnerInfo",{
        partner_info = self:PackNetInfo()
    })
end

function CPartner:PackNetInfo()
    return {
        type = self.m_iType,
        love_level = self.m_iLoveLevel,
        love_ship = self.m_iLoveShip,
        train_type = self.m_iTrainType,
        train_time = math.max(self.m_iTrainTime - get_time(),0),
        unchain_level = self.m_mUnChainLevel,
        coin = self.m_iRanCoin,
    }
end

function CPartner:LogTrainStatus()
    local mLog = {
        pid = self:GetOwner(),
        partype = self:Type(),
        status = self.m_iTrainStatus,
        train_end = self.m_iTrainTime,
    }
    record.user("house", "partner_train_status",mLog)
end

function NewPartner(iType)
    local o = CPartner:New(iType)
    return o
end

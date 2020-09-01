--离线档案
local skynet = require "skynet"
local global = require "global"
local interactive = require "base.interactive"
local extend = require "base/extend"
local record = require "public.record"
local colorstring = require "public.colorstring"

local analy = import(lualib_path("public.dataanaly"))
local defines = import(service_path("offline.defines"))
local CBaseOfflineCtrl = import(service_path("offline.baseofflinectrl")).CBaseOfflineCtrl
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item.loaditem"))
local playerctrl = import(service_path("playerctrl.init"))


local COIN_FLAG = gamedefines.COIN_FLAG
local MAX_GOLD_COIN = gamedefines.COIN_TYPE[COIN_FLAG.COIN_GOLD].max
local MAX_COLOR_COIN = gamedefines.COIN_TYPE[COIN_FLAG.COIN_COLOR].max

CProfileCtrl = {}
CProfileCtrl.__index = CProfileCtrl
inherit(CProfileCtrl, CBaseOfflineCtrl)

function CProfileCtrl:New(iPid)
    local o = super(CProfileCtrl).New(self, iPid)
    o.m_sDbFlag = "Profile"

    o.m_iGoldCoin = 0
    o.m_iRplGoldCoin = 0
    o.m_iColorCoin = 0
    o.m_iFrozenSession = 0
    o.m_mFrozenMoney = {}
    o.m_iUpvote = 0
    o.m_oToday = playerctrl.NewTodayCtrl(iPid)
    o.m_iHistoryCharge = 0
    o.m_bFirstTravelTrader = true
    o.m_iShowId = iPid
    o.m_iGoldCoinConsume = 0

    return o
end

function CProfileCtrl:Save()
    local data = {}
    data["now_server"] = self.m_sNowServer
    data["born_server"] = self.m_sBornServer
    data["show_id"] = self.m_iShowId
    data["grade"] = self.m_iGrade
    data["name"] = self.m_sName
    data["school"] = self.m_iSchool
    data["power"] = self.m_iPower
    data["school_branch"] = self.m_iSchoolBranch
    --data["position"] = self.m_sPosition --地理位置
    --data["position_hide"] = self.m_iPositionHide --隐藏位置
    data["model_info"] = self.m_mModelInfo
    data["goldcoin"] = self.m_iGoldCoin or 0
    data["rplgoldcoin"] = self.m_iRplGoldCoin or 0
    data["color_coin"] = self.m_iColorCoin or 0
    data["frozen_session"] = self.m_iFrozenSession
    data["frozen_money"] = self.m_mFrozenMoney

    data["pt_maxlv"] = self:GetData("pt_maxlv",1)
    data["pt_time"] = self:GetData("pt_time",0)
    data["warpower"] = self.m_WarPower
    data["war_record"] = self:GetData("war_record",{})
    data["addorgtime"] = self:GetData("addorgtime",0)
    data["upvote_count"] = self.m_iUpvote
    data["today"] = self.m_oToday:Save()
    data["leave_org"] = self.m_LeaveOrgInfo

    data["account"] = self.m_sAccount
    data["channel"] = self.m_iChannel
    data["platform"] = self.m_iPlatform

    data["ip"] = self.m_sIP
    data["mac"] = self.m_sMac
    data["device"] = self.m_sDevice
    data["cps"] = self.m_sCpsChannel
    data["historycharge"] = self.m_iHistoryCharge
    data["first_travel_trader"] = self.m_bFirstTravelTrader
    data["goldcoin_consume"] = self.m_iGoldCoinConsume

    return data
end

function CProfileCtrl:Load(data)
    data = data or {}
    self.m_sNowServer = data["now_server"] or get_server_tag()
    self.m_sBornServer = data["born_server"] or get_server_tag()
    self.m_iShowId = data["show_id"] or self:GetPid()
    self.m_iGrade = data["grade"] or 0
    self.m_sName = data["name"] or ""
    self.m_iSchool = data["school"] or 0
    self.m_iPower = data["power"] or 0
    self.m_iSchoolBranch = data["school_branch"] or 1
    --self.m_sPosition = data["position"] or ""
    --self.m_iPositionHide = data["position_hide"]
    self.m_mModelInfo = data["model_info"] or {}

    self.m_iGoldCoin = data["goldcoin"] or 0
    self.m_iRplGoldCoin = data["rplgoldcoin"] or 0
    self.m_iColorCoin = data["color_coin"] or 0
    self.m_iFrozenSession = data["frozen_session"] or self.m_iFrozenSession
    self.m_mFrozenMoney = data["frozen_money"] or self.m_mFrozenMoney
    self:SetData("pt_maxlv",data["pt_maxlv"] or 1)
    self:SetData("pt_time",data["pt_time"] or 0)
    self.m_WarPower = data["warpower"] or 0
    self:SetData("war_record",data["war_record"] or {})
    self:SetData("addorgtime",data["addorgtime"] or 0)
    self.m_iUpvote = data["upvote_count"] or 0
    self.m_oToday:Load(data["today"] or {})
    self.m_sAccount = data["account"] or ""
    self.m_iChannel = data["channel"] or ""
    self.m_iPlatform = data["platform"] or 0
    self.m_sIP = data["ip"] or ""
    self.m_sMac = data["mac"] or ""
    self.m_sDevice = data["device"] or ""
    self.m_sCpsChannel = data["cps"] or ""

    self.m_LeaveOrgInfo = data["leave_org"] or {}
    self.m_iHistoryCharge = data["historycharge"] or 0
    self.m_bFirstTravelTrader = data['first_travel_trader'] or self.m_bFirstTravelTrader
    self.m_iGoldCoinConsume = data["goldcoin_consume"] or 0
end

function CProfileCtrl:OnLogin(oPlayer, bReEnter)
    self:Dirty()
    self.m_sNowServer = oPlayer:GetNowServer()
    self.m_sBornServer = oPlayer:GetBornServer()
    self.m_iGrade = oPlayer:GetGrade()
    self.m_sName = oPlayer:GetName()
    self.m_iSchool = oPlayer:GetSchool()
    self.m_iPower =oPlayer:GetPower()
    --self.m_sPosition = oPlayer:GetPosition()
    --self.m_iPositionHide = oPlayer:GetPositionHide()
    self.m_mModelInfo = oPlayer:GetModelInfo()
    self.m_sAccount = oPlayer:GetAccount()
    self.m_iPlatform = oPlayer:GetPlatform()

    self.m_sIP = oPlayer:GetIP()
    self.m_sMac = oPlayer:GetMac()
    self.m_sDevice = oPlayer:GetDevice()
    self.m_iChannel = oPlayer:GetChannel()
    self.m_sCpsChannel = oPlayer:GetCpsChannel()

    self.m_WarPower = oPlayer:GetWarPower()
end

function CProfileCtrl:GetBornServer()
    return self.m_sBornServer
end

function CProfileCtrl:GetNowServer()
    return self.m_sNowServer
end

function CProfileCtrl:GetPosition()
    return self.m_sPosition
end

function CProfileCtrl:GetPositionHide()
    return self.m_iPositionHide
end

function CProfileCtrl:GetAccount()
    return self.m_sAccount
end

function CProfileCtrl:GetPlatform()
    return self.m_iPlatform or 0
end

function CProfileCtrl:GetPlatformName()
    return gamedefines.GetPlatformName(self.m_iPlatform) or string.format("未知平台%s",self.m_iPlatform)
end

function CProfileCtrl:GetIP()
    return self.m_sIP
end

function CProfileCtrl:GetDevice()
    return self.m_sDevice
end

function CProfileCtrl:GetMac()
    return self.m_sMac
end

function CProfileCtrl:GetChannel()
    return self.m_iChannel
end

function CProfileCtrl:GetCpsChannel()
    return self.m_sCpsChannel
end

function CProfileCtrl:GetName()
    return self.m_sName
end

function CProfileCtrl:GetGrade()
    return self.m_iGrade
end

function CProfileCtrl:GetPower()
    return self.m_iPower or 0
end

function CProfileCtrl:SchoolBranch()
    return self.m_iSchoolBranch
end

function CProfileCtrl:GetSchool()
    return self.m_iSchool
end

function CProfileCtrl:GetModelInfo()
    return self.m_mModelInfo
end

function CProfileCtrl:GetShape()
    return self:GetModelInfo().shape
end

function CProfileCtrl:IsFirstTriggerTrader()
    return self.m_bFirstTravelTrader
end

function CProfileCtrl:UnSetFirstTrigger()
    self:Dirty()
    self.m_bFirstTravelTrader = false
end

function CProfileCtrl:IsCharge()
    if self:HistoryCharge() > 0 then
        return 1
    end
    return 0
end

function CProfileCtrl:GetPubAnalyData()
    return {
        account_id = self:GetAccount(),
        role_id = self.m_iPid,
        role_name = self:GetName(),
        role_level = self:GetGrade(),
        fight_point = self:GetPower(),
        ip = self:GetIP(),
        device_model = self:GetDevice(),
        os = "",
        version = "",
        app_channel = self:GetChannel(),
        sub_channel = self:GetCpsChannel(),
        server= MY_SERVER_KEY,
        plat = self:GetPlatform(),
        profession = self:GetSchool(),
        udid = "",
        is_recharge = self:IsCharge(),
    }
end

function CProfileCtrl:BaseMtbiInfo()
    return {
        account = self:GetAccount(),
        pid = self.m_iPid,
        name = self:GetName(),
        school = self:GetSchool(),
        grade = self:GetGrade(),
        ip = self:GetIP(),
        mac = self:GetMac(),
        channel = self:GetChannel(),
        subchannel = self:GetCpsChannel(),
        server = get_server_key(),
        plat = self:GetPlatform()
    }
end

function CProfileCtrl:GetShowId()
    return self.m_iShowId
end

function CProfileCtrl:SetShowId(iNewShowId)
    self.m_iShowId = iNewShowId
    self:Dirty()
end

function CProfileCtrl:OnLogout(oPlayer)
    if oPlayer then
        self:SyncPlayerData(oPlayer)
    end
    super(CProfileCtrl).OnLogout(self, oPlayer)
end


function CProfileCtrl:SyncPlayerData(oPlayer)
    self:Dirty()
    self.m_sNowServer = oPlayer:GetNowServer()
    self.m_sBornServer = oPlayer:GetBornServer()
    self.m_iGrade = oPlayer:GetGrade()
    self.m_sName = oPlayer:GetName()
    self.m_iSchool = oPlayer:GetSchool()
    self.m_iPower =oPlayer:GetPower()
    self.m_iSchoolBranch = oPlayer:GetSchoolBranch()
    self.m_mModelInfo = oPlayer:GetModelInfo()
    self.m_WarPower = oPlayer:GetWarPower()

    self.m_sIP = oPlayer:GetIP()
    self.m_sMac = oPlayer:GetMac()
    self.m_sDevice = oPlayer:GetDevice()
    self.m_iPlatform = oPlayer:GetPlatform()
    self.m_sAccount = oPlayer:GetAccount()
    self.m_iChannel = oPlayer:GetChannel()
    self.m_sCpsChannel = oPlayer:GetCpsChannel()
end

function CProfileCtrl:SyncPlayerProp(oPlayer)
    self.m_iPower =oPlayer:GetPower()
    self.m_WarPower = oPlayer:GetWarPower()
end


function CProfileCtrl:GetWarPower(oPlayer)
    return self.m_WarPower
end

function CProfileCtrl:GetOrgFubenCnt()
    local oWorldMgr = global.oWorldMgr
    local oHuodongMgr = global.oHuodongMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    local oHuoDong = oHuodongMgr:GetHuodong("orgfuben")
    if oHuoDong and oPlayer then
        return oHuoDong:GetOrgFubenCnt(oPlayer)
    end
    return 0
end

function CProfileCtrl:ChargeGoldCoin(iGoldCoin,sReason,mArgs)
    self:AddGoldCoin(iGoldCoin,sReason,mArgs)
end

function CProfileCtrl:AddHistoryCharge(iVal)
    self:Dirty()
    self.m_iHistoryCharge = self.m_iHistoryCharge + iVal
end

function CProfileCtrl:SetHistoryCharge(iVal)
    self:Dirty()
    self.m_iHistoryCharge = iVal
end

function CProfileCtrl:HistoryCharge()
    return self.m_iHistoryCharge
end

function CProfileCtrl:GoldCoinIcon()
    local m = gamedefines.COIN_TYPE[COIN_FLAG.COIN_GOLD]
    return m.icon or m.name
end

function CProfileCtrl:ColorCoinIcon()
    local m = gamedefines.COIN_TYPE[COIN_FLAG.COIN_COLOR]
    return m.icon or m.name
end

function CProfileCtrl:AddGoldCoin(iGoldCoin,sReason,mArgs)
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local oNotifyMgr = global.oNotifyMgr

    self:Dirty()
    local iPid = self:GetPid()
    local iOldGoldCoin = self.m_iGoldCoin
    assert(iGoldCoin>0,string.format("%d AddGoldCoin err %d %d",self.m_iPid,self.m_iGoldCoin,iGoldCoin))
    local iHaveGoldCoin = self:GoldCoin()
    local iAddGoldCoin = math.min(iGoldCoin, MAX_GOLD_COIN - iHaveGoldCoin)
    local iOverGoldCoin = iGoldCoin - iAddGoldCoin
    self.m_iGoldCoin  = self.m_iGoldCoin + iAddGoldCoin
    local mLog ={
        pid = iPid,
        amount = iGoldCoin,
        reason = sReason,
        old = iHaveGoldCoin,
        now = self:GoldCoin(),
    }
    record.user("coin","gold",mLog)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iPid)
    if oPlayer then
        if iAddGoldCoin > 0 then
            local lMessage = {}
            local sMsg = string.format("获得%s#amount", self:GoldCoinIcon())
            local mNotifyArgs = {
                amount = iAddGoldCoin
            }
            if not mArgs.cancel_tip then
                table.insert(lMessage,"GS2CNotify")
            end
            if not mArgs.cancel_channel then
                table.insert(lMessage,"GS2CConsumeMsg")
            end
            if #lMessage > 0 then
                oNotifyMgr:BroadCastNotify(self.m_iPid,lMessage,sMsg,mNotifyArgs)
            end
            oPlayer:PropChange("goldcoin")
            local oItem = loaditem.GetItem(1003)
            local mShowInfo = oItem:GetShowInfo()
            mShowInfo.amount = iAddGoldCoin
            global.oUIMgr:AddKeepItem(self:GetInfo("pid"), mShowInfo)
            oPlayer:PushBookCondition("获得水晶", {value = iAddGoldCoin})
        end
        if iOverGoldCoin > 0 then
            local oMailMgr = global.oMailMgr
            local mData, sName = oMailMgr:GetMailInfo(1)
            local lMoney = {{sid=COIN_FLAG.COIN_GOLD, value = iOverGoldCoin},}
            oMailMgr:SendMail(0, sName, self:GetPid(), mData, lMoney, {}, {})
            oNotifyMgr:Notify(self:GetPid(), "你的水晶已满，超出的水晶将以邮件的形式发送至邮箱，请及时领取")
        end
        if iAddGoldCoin > 0 then
            local mLog = self:GetPubAnalyData()
            mLog["currency_type"] = COIN_FLAG.COIN_GOLD
            mLog["num"] = iAddGoldCoin
            mLog["remain_crystal_bd"] = 0
            mLog["remain_crystal"] = self:ColorCoin()
            mLog["reason"] = sReason
            mLog["remain_currency"] = self:GoldCoin()
            analy.log_data("currency",mLog)
        end
        self:PushGainGoldCoin2KP(oPlayer, iAddGoldCoin, mArgs, sReason)
    end
end

function CProfileCtrl:PushGainGoldCoin2KP(oPlayer, iAddGoldCoin, mArgs, sReason)
    -- mArgs = mArgs or {}
    -- local mGain = global.oWorldMgr:GetUpDataRes("gain_goldcoin", mArgs.from_id)
    -- if mGain then
        local mData = {}
        mData.code = 0
        mData.gainwayid = 0
        mData.gainwayname = sReason
        mData.gaincount = iAddGoldCoin
        mData.surpluscount = self:GoldCoin()
        mData.eventtime = get_time()
        global.oKaopuMgr:GainGoldCoin(oPlayer, mData)
    -- end
end

function CProfileCtrl:PushCostGoldCoin2KP(oPlayer, iVal, mArgs, sReason)
    mArgs = mArgs or {}
    -- local mGain = global.oWorldMgr:GetUpDataRes("cost_goldcoin", mArgs.from_id)
    -- if mGain then
        local mData = {}
        mData.consumewayid = 0
        mData.consumewayname = sReason
        mData.consumecount = iVal
        mData.surpluscount = self:GoldCoin()
        mData.eventtime = get_time()
        global.oKaopuMgr:ConsumeGoldCoin(oPlayer, mData)
    -- end
end

function  CProfileCtrl:AddRplGoldCoin(iRplGold,sReason,mArgs)
    mArgs = mArgs or {}
    self:Dirty()
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = self:GetPid()
    assert(iRplGold>0,string.format("%d AddRplGoldCoin err %d %d",iPid, self.m_iRplGoldCoin, iRplGold))
    local iGoldCoin = self:GoldCoin()
    local iAddGoldCoin = math.min(iRplGold, MAX_GOLD_COIN - iGoldCoin)
    local iOverGoldCoin = iRplGold - iAddGoldCoin
    -- local iOldRplGoldCoin = self.m_RplGoldCoin
    self.m_iRplGoldCoin = self.m_iRplGoldCoin + iAddGoldCoin
    local mLog ={
        pid = iPid,
        amount = iRplGold,
        reason = sReason,
        old = iGoldCoin,
        now = self:GoldCoin(),
    }
    record.user("coin","gold",mLog)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        if iAddGoldCoin > 0 then
            local sMsg = string.format("获得%s#amount", self:ColorCoinIcon())
            local mNotifyArgs = {
                amount = iRplGold,
            }
            local lMessage = {}
            if not mArgs.cancel_tip then
                table.insert(lMessage,"GS2CNotify")
            end
            if not mArgs.cancel_channel then
                table.insert(lMessage,"GS2CConsumeMsg")
            end
            if #lMessage > 0 then
                oNotifyMgr:BroadCastNotify(iPid,lMessage,sMsg,mNotifyArgs)
            end
            oPlayer:PropChange("goldcoin")
        end
        if iOverGoldCoin > 0 then
            local oMailMgr = global.oMailMgr
            local mData, sName = oMailMgr:GetMailInfo(1)
            local lMoney = {{sid=COIN_FLAG.COIN_GOLD, value = iOverGoldCoin}, }
            oMailMgr:SendMail(0, sName, self:GetPid(), mData, lMoney, {}, {})
            oNotifyMgr:Notify(iPid, "你的水晶已满，超出的水晶将以邮件的形式发送至邮箱，请及时领取")
        end
        oPlayer:PushBookCondition("累积获得水晶", {value = iAddGoldCoin})
    end
end

function CProfileCtrl:GoldCoin()
    local iGold = self.m_iGoldCoin + self.m_iRplGoldCoin
    iGold = iGold - self:GetFrozenMoney("goldcoin")
    return iGold
end

function CProfileCtrl:ValidGoldCoin(iGold,mArgs)
    mArgs = mArgs or {}
    local iSumGold = self:GoldCoin()
    if iSumGold >= iGold then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "水晶不足"
    end
    local bShort = mArgs.short
    if not mArgs.cancel_tip then
        if bShort then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(self.m_iPid,sTip)
        end
    end

    if not bShort then
        local oUIMgr = global.oUIMgr
        oUIMgr:GS2CShortWay(self.m_iPid,2)
    end
    return false
end

-- 优先绑定
function CProfileCtrl:ResumeGoldCoin(iVal,sReason,mArgs)
    self:Dirty()
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = self:GetPid()
    local iOldGoldCoin = self:GoldCoin()
    assert(iVal > 0 and iOldGoldCoin >= iVal, string.format("pid:%s, ResumeGoldCoin err: %d, %d, %s", iPid, iOldGoldCoin, iVal, sReason))

    if self.m_iRplGoldCoin >= iVal then
        self.m_iRplGoldCoin = self.m_iRplGoldCoin - iVal
    else
        iVal = iVal -  self.m_iRplGoldCoin
        self.m_iRplGoldCoin = 0
        self.m_iGoldCoin = self.m_iGoldCoin - iVal
    end

    local mLog ={
        pid = iPid,
        amount = -iVal,
        reason = sReason,
        old = iOldGoldCoin,
        now = self:GoldCoin(),
    }
    record.user("coin","gold",mLog)

    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local lMessage = {}
        local sMsg = string.format("消耗%s#resume", self:GoldCoinIcon())
        local mNotifyArgs = {
            resume = iVal
        }
        sMsg = mArgs.tip or sMsg
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel  then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(iPid,lMessage,sMsg,mNotifyArgs)
        end
        oPlayer:PropChange("goldcoin")
        global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"累计消耗水晶",{value=iVal})
        global.oFuliMgr:AddConsumePoint(oPlayer,iVal)
        local mLog = self:GetPubAnalyData()
        mLog["currency_type"] = COIN_FLAG.COIN_GOLD
        mLog["num"] = -iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = self:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:GoldCoin()
        analy.log_data("currency",mLog)
        self:PushCostGoldCoin2KP(oPlayer, iVal, mArgs, sReason)
    end
    self.m_iGoldCoinConsume = self.m_iGoldCoinConsume + iOldGoldCoin - self:GoldCoin()
    global.oRankMgr:PushDataToConsumeRank(self)
    local mHuodong = {"timelimitresume","resume_restore"}
    for _,sHuodong in pairs(mHuodong) do
        local oHuodong = global.oHuodongMgr:GetHuodong(sHuodong)
        if oHuodong then
            oHuodong:AfterResumeGoldCoin(oPlayer,iVal)
        end
    end
end

function CProfileCtrl:SumGoldCoinConsume()
    return self.m_iGoldCoinConsume or 0
end

function CProfileCtrl:RewardColorCoin(iColorCoin,sReason,mArgs)
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local oNotifyMgr = global.oNotifyMgr

    self:Dirty()
    local iPid = self:GetPid()
    assert(iColorCoin>0,string.format("%d RewardColorCoin err %d %d",self.m_iPid,self.m_iColorCoin,iColorCoin))
    local iHaveColorCoin = self.m_iColorCoin
    local iAddColorCoin = math.min(iColorCoin, MAX_COLOR_COIN - iHaveColorCoin)
    local iOverColorCoin = iColorCoin - iAddColorCoin
    self.m_iColorCoin  = self.m_iColorCoin + iAddColorCoin
    local mLog ={
        pid = iPid,
        amount = iColorCoin,
        reason = sReason,
        old = iHaveColorCoin,
        now = self.m_iColorCoin,
    }
    record.user("coin","color_coin",mLog)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iPid)
    if oPlayer then
        if iAddColorCoin > 0 then
            local lMessage = {}
            local sMsg = string.format("获得%s#amount", self:ColorCoinIcon())
            local mNotifyArgs = {
                amount = iAddColorCoin
            }
            if not mArgs.cancel_tip then
                table.insert(lMessage,"GS2CNotify")
            end
            if not mArgs.cancel_channel then
                table.insert(lMessage,"GS2CConsumeMsg")
            end
            if #lMessage > 0 then
                oNotifyMgr:BroadCastNotify(self.m_iPid,lMessage,sMsg,mNotifyArgs)
            end
            oPlayer:PropChange("color_coin")
            local oItem = loaditem.GetItem(1001)
            local mShowInfo = oItem:GetShowInfo()
            mShowInfo.amount = iAddColorCoin
            global.oUIMgr:AddKeepItem(self:GetInfo("pid"), mShowInfo)
        end
        if iOverColorCoin > 0 then
            local oMailMgr = global.oMailMgr
            local mData, sName = oMailMgr:GetMailInfo(1)
            local lMoney = {{sid=COIN_FLAG.COIN_COLOR, value = iOverColorCoin},}
            oMailMgr:SendMail(0, sName, self:GetPid(), mData, lMoney, {}, {})
            oNotifyMgr:Notify(self:GetPid(), "你的彩晶已满，超出的彩晶将以邮件的形式发送至邮箱，请及时领取")
        end
        if iAddColorCoin > 0 then
            local mLog = self:GetPubAnalyData()
            mLog["currency_type"] = COIN_FLAG.COIN_COLOR
            mLog["num"] = iAddColorCoin
            mLog["remain_crystal_bd"] = 0
            mLog["remain_crystal"] = self:ColorCoin()
            mLog["reason"] = sReason
            mLog["remain_currency"] = self:ColorCoin()
            analy.log_data("currency",mLog)
        end
    end
end

function CProfileCtrl:ValidColorCoin(iVal, mArgs)
    mArgs = mArgs or {}

    local iPid  = self:GetPid()
    local iCoin = self:ColorCoin()
    assert(iCoin>=0,string.format("%d color coin err %d", iPid, iCoin))
    assert(iVal>0,string.format("%d cost color coin err %d", iPid, iVal))
    if iCoin >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "彩晶不足"
    end
    local bShort = mArgs.short
    if not mArgs.cancel_tip then
        if bShort then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(iPid,sTip)
        end
    end

    if not bShort then
        local oUIMgr = global.oUIMgr
        oUIMgr:GS2CShortWay(iPid,9)
    end
    return false
end

function CProfileCtrl:ResumeColorCoin(iVal, sReason, mArgs)
    self:Dirty()
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    mArgs = mArgs or {}

    local iPid = self:GetPid()
    local iCoin = self:ColorCoin()
    assert(iVal > 0 and iCoin >= iVal,string.format("pid:%s ResumeColorCoin err:%d, %d, %s", iPid, iCoin, iVal, sReason))

    self.m_iColorCoin = self.m_iColorCoin - iVal

    local mLog ={
        pid = iPid,
        amount = -iVal,
        reason = sReason,
        old = iCoin,
        now = self:ColorCoin(),
    }
    record.user("coin","color_coin",mLog)

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:PropChange("color_coin")
        local lMessage = {}
        local sMsg = string.format("消耗了%s#resume", self:ColorCoinIcon())
        local mNotifyArgs = {resume = iVal}
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(iPid,lMessage,sMsg,mNotifyArgs)
        end
    end
    if  iVal > 0 then
        if not table_in_list({"水晶兑换","金币兑换"},sReason) then
            global.oFuliMgr:AddConsumePoint(oPlayer,iVal*10)
        end
        global.oAchieveMgr:PushAchieve(iPid,"消耗彩晶",{value=iVal})
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_COLOR
        mLog["num"] = -iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = self:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = self:ColorCoin()
        analy.log_data("currency",mLog)
    end
end

function CProfileCtrl:ColorCoin()
    return self.m_iColorCoin - self:GetFrozenMoney("color_coin")
end

function CProfileCtrl:DispathFrozenSession()
    local iSession = self.m_iFrozenSession or 0
    iSession = iSession + 1
    self.m_iFrozenSession = iSession
    return iSession
end

function CProfileCtrl:FrozenMoney(sType,iVal,sReason)
    local mFrozen = self.m_mFrozenMoney or {}
    local iSession = self:DispathFrozenSession()
    iSession = tostring(iSession)
    mFrozen[iSession] = {sType,iVal,sReason}
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    assert(iVal > 0, string.format("pid:%s, FrozenMoney err: %s, %d, %s", iPid, sType, iVal, sReason))
    if sType == "goldcoin" then
        if oPlayer then
            oPlayer:PropChange("goldcoin")
        end
    elseif sType == "coin" then
        if oPlayer then
            oPlayer:PropChange("coin")
        end
    end
    return iSession
end

function CProfileCtrl:UnFrozenMoney(iSession)
    local mFrozen = self.m_mFrozenMoney or {}
    iSession = tostring(iSession)
    local mData = table_copy(mFrozen[iSession])
    assert(mData,string.format("UnFrozenMoney err:%s",self:GetInfo("pid")))
    mFrozen[iSession] = nil
    self.m_mFrozenMoney = mFrozen
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local sType,iVal,sReason = table.unpack(mData)
    if sType == "goldcoin" then
        if oPlayer then
            oPlayer:PropChange("goldcoin")
        end
    elseif sType == "coin" then
        if oPlayer then
            oPlayer:PropChange("coin")
        end
    end
    return mData
end

function CProfileCtrl:GetFrozenMoney(sType)
    local mFrozen = self.m_mFrozenMoney or {}
    local iPrice = 0
    for iSession,mData in pairs(mFrozen) do
        local sMoneyType,iVal,sReason = table.unpack(mData)
        if sMoneyType == sType then
            iPrice = iPrice + iVal
        end
    end
    return iPrice
end

function CProfileCtrl:GetUpvoteAmount()
    return self.m_iUpvote
end


function CProfileCtrl:AddUpvote(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if iPid == self:GetPid() then
        return
    end
    local mUpvote = self.m_oToday:Query("upvote",{})
    if extend.Array.member(mUpvote,iPid) then
        oPlayer:Send("GS2CUpvotePlayer", {succuss = 0, target_pid = self:GetPid()})
        oNotifyMgr:Notify(iPid, "同一个玩家一天只能点赞一次!")
        return
    end
    self:Dirty()
    oPlayer.m_oToday:Add("UpvoteCnt",1)
    table.insert(mUpvote,iPid)
    self.m_oToday:Set("upvote",mUpvote)
    self.m_iUpvote = self.m_iUpvote + 1
    local otherplayer = oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if otherplayer then
        otherplayer:PropChange("upvote_amount")
    end
    oPlayer:Send("GS2CUpvotePlayer", {succuss = 1, target_pid = self:GetPid()})
    oNotifyMgr:Notify(iPid, "点赞成功，人气+1")
end

function CProfileCtrl:IsUpvote(iTargetPid)
    local mUpvote = self.m_oToday:Query("upvote",{})
    if extend.Array.member(mUpvote,iTargetPid) then
        return true
    end
    return false
end

function CProfileCtrl:GetSchoolName()
    local res = require "base.res"
    local mData = res["daobiao"]["school"][self.m_iSchool]
    assert(mData, string.format("school data not exist! %s, %s", self:GetPid(), self.m_iSchool))
    return mData.name
end

function CProfileCtrl:GetSchoolBranchName()
    local res = require "base.res"
    local mData = res["daobiao"]["rolebranch"][self.m_iSchool][self.m_iSchoolBranch]
    assert(mData, string.format("rolebranch data not exist! %s, %s, %s", self:GetPid(), self.m_iSchool, self.m_iSchoolBranch))
    return mData.name
end

function CProfileCtrl:SetLeaveOrgInfo(iTime,iOrgID)
    self:Dirty()
    local mLeave = self.m_LeaveOrgInfo or {}
    mLeave["leavetime"] = iTime
    mLeave["orgid"] = iOrgID
    self.m_LeaveOrgInfo = mLeave
end

function CProfileCtrl:GetPreLeaveOrgInfo()
    return self.m_LeaveOrgInfo or {}
end

function CProfileCtrl:LogAnalyGame(mLog,sGameName,mItemList,mCurrency,mPartnerExp,exp)
    exp = exp or 0
    mLog = mLog or {}
    mLog = table_combine(mLog,self:GetPubAnalyData())
    mLog["gamename"]=sGameName
    mLog["reward_detail"] = analy.datajoin(mItemList)
    mLog["reward_currency"] = analy.datajoin(mCurrency)
    mLog["reward_exp"] = exp
    mLog["reward_partnerexp"] = analy.datajoin(mPartnerExp)
    analy.log_data("Game_Reward",mLog)
end
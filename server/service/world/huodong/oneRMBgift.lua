--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local loaditem = import(service_path("item.loaditem"))

local CLOSE = 0
local OPEN = 1

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    o.m_iOpen = CLOSE
    return o
end

function CHuodong:NewDay(iWeekDay)
    if self:IsOpen() then
        local oWorldMgr = global.oWorldMgr
        local mOnline = oWorldMgr:GetOnlinePlayerList()
        for iPid, oPlayer in pairs(mOnline) do
            if self:IsOpenGrade(oPlayer) then
                self:InitData(oPlayer, true)
            end
        end
    end
end


function CHuodong:OnLogin(oPlayer, bReEnter)
    if self:IsOpenGrade(oPlayer) then
        if not bReEnter then
            self:PreCheck(oPlayer)
        end
        if self:IsOpen() then
            self:SendGiftInfo(oPlayer)
        end
    end
end

function CHuodong:PreCheck(oPlayer)
    local mMyData = self:GetTodayBuyInfo(oPlayer)
    local obj = self:GetOpenObj()
    if obj then
        if not obj:CheckDispatchID(self.m_sName, mMyData.dispatch_id) then
            self:ClearData(oPlayer, false)
            if self:IsOpen() then
                self:InitData(oPlayer, false)
            end
        elseif not mMyData.add_list then
            self:InitData(oPlayer, false)
        end
    end
end

function CHuodong:CheckSameHour(t1, t2)
    local iHour = 1
    local iTime1 = t1 + iHour * 3600
    local iTime2 = t2 + iHour * 3600
    local date = os.date("*t",iTime1)
    iTime1 = os.time({year=date.year,month=date.month,day=date.day,hour=date.hour,min=0,sec=0})
    date = os.date("*t", iTime2)
    iTime2 = os.time({year=date.year,month=date.month,day=date.day,hour=date.hour,min=0,sec=0})
    return iTime1 == iTime2
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.is_open = self.m_iOpen
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    self.m_iOpen =mData.is_open or 0
end

function CHuodong:NewHour(iWeekDay, iHour)
    local obj = self:GetOpenObj()
    if  obj then
        if self:IsOpen() and obj:IsClose(self.m_sName) then
            self:SetOpen(CLOSE)
            self:ClearOnlineData()
        elseif not self:IsOpen() and obj:IsOpen(self.m_sName) then
            self:SetOpen(OPEN)
            self:InitOnlineData()
        end
    end
end

function CHuodong:OnUpGrade(oPlayer, iGrade)
    local obj = self:GetOpenObj()
    if obj and obj:EqualOpenGrade(self.m_sName, oPlayer) then
        self:PreCheck(oPlayer)
        if self:IsOpen() then
            self:SendGiftInfo(oPlayer)
        end
    end
end

function CHuodong:IsOpen()
    return self.m_iOpen == OPEN
end

function CHuodong:GetOpenObj()
    local oHuodongMgr = global.oHuodongMgr
    return oHuodongMgr:GetHuodong("limitopen")
end

function CHuodong:IsOpenGrade(oPlayer)
    local obj =self:GetOpenObj()
    return obj and obj:IsOpenGrade(self.m_sName, oPlayer)
end

function CHuodong:SetOpen(iOpen)
    self:Dirty()
    self.m_iOpen = iOpen
    record.user("one_RMB_gift", "open", {
        name = self.m_sName,
        open = iOpen,
        })
end

function CHuodong:GetBuyDaoBiaoList()
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["oneRMBgift"]
end

function CHuodong:GetBuyDaoBiao(iKey)
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["oneRMBgift"][iKey]
end

function CHuodong:GetTodayBuyInfo(oPlayer)
    local m = oPlayer.m_oToday:Query("one_RMB_gift", {})
    return m
end

function CHuodong:SetTodayBuyInfo(oPlayer, mBuy)
    oPlayer.m_oToday:Set("one_RMB_gift", mBuy)
end

function CHuodong:ClearOnlineData()
    local oWorldMgr = global.oWorldMgr
    local online = oWorldMgr:GetOnlinePlayerList()
    for iPid, oPlayer in pairs(online) do
        if self:IsOpenGrade(oPlayer) then
            self:ClearData(oPlayer, true)
        end
    end
end

function CHuodong:ClearData(oPlayer, bSend)
    local mMyData = self:GetTodayBuyInfo(oPlayer)
    if next(mMyData) then
        self:SetTodayBuyInfo(oPlayer, nil)
        if bSend then
            oPlayer:Send("GS2CCloseHuodong", {name = self.m_sName})
        end
        --record log
        record.user("one_RMB_gift", "cleardata", {
            name = self.m_sName,
            pid = oPlayer:GetPid(),
            plan = mMyData.plan or 0,
            dispatch_id = mMyData.dispatch_id or 0,
            })
    end
end

function CHuodong:InitOnlineData()
    local oWorldMgr = global.oWorldMgr
    local online = oWorldMgr:GetOnlinePlayerList()
    for iPid, oPlayer in pairs(online) do
        if self:IsOpenGrade(oPlayer) then
            self:InitData(oPlayer, true)
        end
    end
end

function CHuodong:InitData(oPlayer,bSend)
    local obj = self:GetOpenObj()
    if not obj then
        return
    end
    local mMyData = {}
    mMyData.dispatch_id = obj:GetDispatchID(self.m_sName)
    mMyData.plan = obj:GetUsePlan(self.m_sName)
    mMyData.add_list = {}
    for id, m in pairs(self:GetBuyDaoBiaoList() or {}) do
        if m.plan == mMyData.plan then
            mMyData.add_list[id] = {done = 0}
        end
    end
    self:SetTodayBuyInfo(oPlayer, mMyData)
    if bSend then
        self:SendGiftInfo(oPlayer)
    end
    record.user("one_RMB_gift", "initdata", {
        name = self.m_sName,
        pid = oPlayer:GetPid(),
        plan = mMyData.plan,
        dispatch_id = mMyData.dispatch_id,
        })
end


function CHuodong:IsBuy(oPlayer, iKey)
    local mMyData = self:GetTodayBuyInfo(oPlayer)
    local mBuy = mMyData.add_list[iKey]
    return mBuy.done == 1
end

function CHuodong:ValidProductKey(oPlayer, iKey, sProductKey)
    local mDaoBiao = self:GetBuyDaoBiao(iKey)
    if mDaoBiao.payid == sProductKey then
        return true
    end
    if mDaoBiao.iospayid == sProductKey then
        return true
    end
    return false
end

function CHuodong:ValidBuyGift(oPlayer,iKey,sProductKey)
    local iPid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    if not self:IsOpen() then
        oNotifyMgr:Notify(iPid,self:GetTextData(1004))
        return false
    end
    if not self:IsOpenGrade(oPlayer) then
        oNotifyMgr:Notify(iPid,self:GetTextData(1005))
        return false
    end
    local mMyData = self:GetTodayBuyInfo(oPlayer)
    if not mMyData.add_list then
        oNotifyMgr:Notify(iPid,self:GetTextData(1006))
        return false
    end
    if self:IsBuy(oPlayer, iKey) then
        oNotifyMgr:Notify(iPid,self:GetTextData(1001))
        return false
    end
    local mDaoBiao = self:GetBuyDaoBiao(iKey)
    if not mDaoBiao then
        oNotifyMgr:Notify(iPid,self:GetTextData(1002))
        return false
    end
    if not self:ValidProductKey(oPlayer, iKey, sProductKey) then
        oNotifyMgr:Notify(iPid,self:GetTextData(1003))
        return false
    end
    return true
end

function CHuodong:BuyGift(oPlayer, iKey, bNoTip)
    local mDaoBiao = self:GetBuyDaoBiao(iKey)
    if mDaoBiao then
        local mRwdItem = mDaoBiao.itemlist
        local mMyData = self:GetTodayBuyInfo(oPlayer)
        local mBuy = mMyData.add_list[iKey]
        mBuy.done = 1
        self:SetTodayBuyInfo(oPlayer, mMyData)
        local lGive = {}
        for _, m in ipairs(mRwdItem) do
            table.insert(lGive, {m.sid, m.amount})
        end
        oPlayer:GiveItem(lGive, "购买一元礼包", {cancel_tip = 1})
        self:UpdateGiftInfo(oPlayer, iKey)
        if not bNoTip then
            global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
        end
        record.user("one_RMB_gift", "buy", {
            pid = oPlayer:GetPid(),
            key = iKey,
            done = mBuy.done,
            item = ConvertTblToStr(mRwdItem),
            })
    else
        record.error("one_RMB_gift config err, pid:%s, key:%s", oPlayer:GetPid(), iKey)
    end
end

function CHuodong:UpdateGiftInfo(oPlayer, iKey)
    local mMyData = self:GetTodayBuyInfo(oPlayer)
    local mBuy = mMyData.add_list[iKey]
    local mNet = {key = iKey, done = mBuy.done}
    oPlayer:Send("GS2CUpdateOneRMBGift", {gift = mNet})
end

function CHuodong:SendGiftInfo(oPlayer)
    local obj = self:GetOpenObj()
    local mMyData = self:GetTodayBuyInfo(oPlayer)
    local mNet = {}
    mNet.gift = {}
    mNet.starttime = obj and obj:StartTime(self.m_sName)
    mNet.endtime = obj and obj:EndTime(self.m_sName)
    for iKey, m in pairs(mMyData.add_list or {}) do
        table.insert(mNet.gift, {key = iKey, done = m.done})
    end
    oPlayer:Send("GS2COneRMBGift", mNet)
end

function CHuodong:TestOP(oPlayer, iFlag, ...)
    local iPid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    local mArgs ={...}
    if iFlag == 101 then
        local iKey = table.unpack(mArgs)
        local mData = self:GetBuyDaoBiao(iKey)
        if mData then
            if self:ValidBuyGift(oPlayer, iKey, mData.payid) then
                local oCharge = global.oHuodongMgr:GetHuodong("charge")
                if oCharge then
                    oCharge:TestOP(oPlayer, 1005, iKey, "giftbag_" .. mData.price, mData.payid)
                end
            end
        else
            oNotifyMgr:Notify(iPid,self:GetTextData(1002))
        end
    elseif iFlag == 102 then
        local obj = self:GetOpenObj()
        if obj and obj:IsOpen(self.m_sName) then
            self:SetOpen(OPEN)
            self:ClearOnlineData()
            self:InitOnlineData()
        else
            oNotifyMgr:Notify(iPid, "后台活动未开始")
        end
    end
end
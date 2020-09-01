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

function CHuodong:OnLogin(oPlayer, bReEnter)
    if self:IsOpenGrade(oPlayer) then
        if not bReEnter then
            self:PreCheck(oPlayer)
        end
        if self:IsOpen() then
            self:SendDayCharge(oPlayer)
        end
    end
end

function CHuodong:PreCheck(oPlayer)
    local mMyData = self:GetDayChargeData(oPlayer)
    local obj = self:GetOpenObj()
    if obj then
        if not obj:CheckDispatchID(self.m_sName, mMyData.dispatch_id) then
            self:ClearData(oPlayer, false)
            if self:IsOpen() then
                self:InitData(oPlayer, false)
            end
        end
    end
end

function CHuodong:OnUpGrade(oPlayer, iGrade)
    local obj = self:GetOpenObj()
    if obj and obj:EqualOpenGrade(self.m_sName, oPlayer) then
        self:PreCheck(oPlayer)
        if self:IsOpen() then
            self:SendDayCharge(oPlayer)
        end
    end
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
            --cleardata && broadcast close
            self:SetOpen(CLOSE)
            self:ClearOnlineData()
        elseif not self:IsOpen() and obj:IsOpen(self.m_sName) then
            --initdata && broadcast open
            self:SetOpen(OPEN)
            self:InitOnlineData()
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

    record.user("hd_day_charge", "open", {
        name = self.m_sName,
        open = iOpen,
        })
end

function CHuodong:GetDayChargeData(oPlayer)
    return oPlayer.m_oActiveCtrl:GetData("hd_day_charge", {})
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
    oPlayer.m_oToday:Set("hd_day_charge", nil)
    local mMyData = self:GetDayChargeData(oPlayer)
    if next(mMyData) then
        oPlayer.m_oActiveCtrl:SetData("hd_day_charge", {})
        if bSend then
            oPlayer:Send("GS2CCloseHuodong", {name = self.m_sName})
        end
        local oItems = {}
        for id, m in pairs(mMyData.add_list or {}) do
            local mDaoBiao = self:GetDayChargeDaoBiao()[id]
            if mDaoBiao.day <= mMyData.progress and m.receive == 0 then
                for _, mItem in ipairs(mDaoBiao.itemlist) do
                    local oItem = loaditem.ExtCreate(mItem.sid)
                    oItem:SetAmount(mItem.amount)
                    table.insert(oItems, oItem)
                end
            end
        end
        if next(oItems) then
            local iMailId = 88
            local oMailMgr = global.oMailMgr
            local m, name = oMailMgr:GetMailInfo(iMailId)
            oMailMgr:SendMail(0, name, oPlayer:GetPid(), m, {}, oItems)
        end
        --record log
        record.user("hd_day_charge", "cleardata", {
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
    mMyData.progress = 0
    mMyData.add_list = {}
    for id, m in pairs(self:GetDayChargeDaoBiao() or {}) do
        if m.plan == mMyData.plan then
            mMyData.add_list[id] = {receive = 0}
        end
    end
    oPlayer.m_oActiveCtrl:SetData("hd_day_charge", mMyData)
    if bSend then
        self:SendDayCharge(oPlayer)
    end

    record.user("hd_day_charge", "initdata", {
        name = self.m_sName,
        pid = oPlayer:GetPid(),
        plan = mMyData.plan,
        dispatch_id = mMyData.dispatch_id,
        })
end

function CHuodong:GetDayChargeDaoBiao()
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["daycharge"]
end

function CHuodong:ValidReceive(oPlayer, id, code)
    local iPid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    local mDaoBiao = self:GetDayChargeDaoBiao()[id]
    if not mDaoBiao then
        oNotifyMgr:Notify(iPid,self:GetTextData(1001))
        return false
    end
    if not self:IsOpen() then
        oNotifyMgr:Notify(iPid,self:GetTextData(1002))
        return false
    end
    if not self:IsOpenGrade(oPlayer) then
        oNotifyMgr:Notify(iPid,self:GetTextData(1003))
        return false
    end
    local mMyData = self:GetDayChargeData(oPlayer)
    if not next(mMyData) then
        oNotifyMgr:Notify(iPid,self:GetTextData(1004))
        return false
    end
    if mMyData.dispatch_id ~= code then
        self:CheckCode(oPlayer)
        oNotifyMgr:Notify(iPid,self:GetTextData(1008))
        return false
    end
    if mMyData.progress < mDaoBiao.day then
        oNotifyMgr:Notify(iPid,self:GetTextData(1005))
        return false
    end
    local mAddList = mMyData.add_list or {}
    if not mAddList[id] then
        oNotifyMgr:Notify(iPid,self:GetTextData(1006))
        return false
    end
    if mAddList[id].receive == 1 then
        oNotifyMgr:Notify(iPid,self:GetTextData(1007))
        return false
    end
    return true
end

function CHuodong:ReceiveReward(oPlayer, id, code)
    if not self:ValidReceive(oPlayer, id, code) then
        return
    end
    local mDaoBiao = self:GetDayChargeDaoBiao()[id]
    local mMyData = self:GetDayChargeData(oPlayer)
    mMyData.add_list[id].receive = 1
    oPlayer.m_oActiveCtrl:SetData("hd_day_charge", mMyData)
    local lGive = {}
    for _, m in ipairs(mDaoBiao.itemlist) do
        table.insert(lGive, {m.sid, m.amount})
    end
    if #lGive > 0 then
        oPlayer:GiveItem(lGive, "限时累充奖励", {cancel_tip=1})
    end
    global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
    self:UpdateAddCharge(oPlayer, id)
    record.user("hd_day_charge", "receive", {
        id = id,
        name = self.m_sName,
        pid = oPlayer:GetPid(),
        plan = mMyData.plan,
        dispatch_id = mMyData.dispatch_id,
        progress = mMyData.progress,
        })
end

function CHuodong:DayCharge(oPlayer, iValue, sReason)
    if not self:IsOpen() then
        return
    end
    if oPlayer.m_oToday:Query("hd_day_charge") then
        return
    end
    local mMyData = self:GetDayChargeData(oPlayer)
    mMyData.progress = (mMyData.progress or 0) + 1
    oPlayer.m_oToday:Set("hd_day_charge", 1)
    oPlayer.m_oActiveCtrl:SetData("hd_day_charge", mMyData)
    self:UpdateAddChargeProgress(oPlayer)

    record.user("hd_day_charge", "add_progress", {
        name = self.m_sName,
        pid = oPlayer:GetPid(),
        plan = mMyData.plan,
        dispatch_id = mMyData.dispatch_id,
        progress = mMyData.progress,
        reason = sReason,
        })
end

function CHuodong:UpdateAddCharge(oPlayer, id)
    local mMyData = self:GetDayChargeData(oPlayer)
    local mAddList = mMyData.add_list or {}
    local mNet = {}
    mNet.unit = {id = id, receive = mAddList[id].receive}
    oPlayer:Send("GS2CHDUpdateDayCharge", mNet)
end

function CHuodong:UpdateAddChargeProgress(oPlayer)
    local mMyData = self:GetDayChargeData(oPlayer)
    oPlayer:Send("GS2CHDDayChargeProgress", {progress = mMyData.progress})
end

function CHuodong:SendDayCharge(oPlayer)
    local obj = self:GetOpenObj()
    local mMyData = self:GetDayChargeData(oPlayer)
    local mNet = {}
    mNet.list = {}
    mNet.progress = mMyData.progress
    mNet.code = mMyData.dispatch_id
    mNet.starttime = obj and obj:StartTime(self.m_sName)
    mNet.endtime = obj and obj:EndTime(self.m_sName)
    for id, m in pairs(mMyData.add_list) do
        table.insert(mNet.list, {id = id, receive = m.receive})
    end
    oPlayer:Send("GS2CHDDayChargeInfo", mNet)
end

function CHuodong:CheckRewardPlan(plan)
    local mDaoBiao = self:GetDayChargeDaoBiao()
    for id, m in pairs(mDaoBiao) do
        if m.plan == plan then
            return true
        end
    end
    return false
end

function CHuodong:CheckCode(oPlayer)
    local mMyData = self:GetDayChargeData(oPlayer)
    local obj = self:GetOpenObj()
    if obj:CheckDispatchID(self.m_sName, mMyData.dispatch_id) then
        self:ClearData(oPlayer)
        if self:IsOpen() then
            self:InitData(oPlayer, true)
        end
    end
end


function CHuodong:TestOP(oPlayer, iFlag, ...)
    local iPid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    local mArgs = {...}
    if iFlag == 101 then
        local obj = self:GetOpenObj()
        if obj and obj:IsOpen(self.m_sName) then
            self:SetOpen(OPEN)
            self:ClearOnlineData()
            self:InitOnlineData(oPlayer, true)
        else
            oNotifyMgr:Notify(iPid, "后台活动未开始")
        end
    else
        oNotifyMgr:Notify(iPid, "指令不存在")
    end
end
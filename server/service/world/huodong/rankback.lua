--import module
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local router = require "base.router"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local loaditem = import(service_path("item.loaditem"))
local loadpartner = import(service_path("partner.loadpartner"))

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
    if self:IsOpenGrade(oPlayer) and self:IsOpen() then
        self:SendRankBackInfo(oPlayer)
    else
        self:CheckRankBack(oPlayer)
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
            self:SetOpen(CLOSE)
            self:QueryRankBack()
        elseif not self:IsOpen() and obj:IsOpen(self.m_sName) then
            self:SetOpen(OPEN)
            self:NotifyOnlinePlayer()
        end
    end
end

function CHuodong:NotifyOnlinePlayer()
    local oWorldMgr = global.oWorldMgr
    local mOnline = oWorldMgr:GetOnlinePlayerList()
    for iPid, oPlayer in pairs(mOnline) do
        if self:IsOpenGrade(oPlayer) then
            self:SendRankBackInfo(oPlayer)
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

    record.user("hd_rankback", "open", {
        name = self.m_sName,
        open = iOpen,
        })
end

function CHuodong:QueryRankBack()
    record.info("rankback, start query")
    local res = require "base.res"
    local mDaoBiao = res["daobiao"]["welfare_rank"]
    local lRankIdx = table_key_list(mDaoBiao)
    interactive.Send(".rank", "rank", "QueryRankBack", {idxs = lRankIdx})

    record.user("hd_rankback", "save", {
        rank_idxs = ConvertTblToStr(lRankIdx),
        })
end

function CHuodong:DoRankBack(lRankData)
    local oWorldMgr = global.oWorldMgr
    lRankData = lRankData or {}
    local mHandle = {
            is_send = false,
            count = #lRankData,
            account = {},
    }
    for _, rank in ipairs(lRankData) do
        oWorldMgr:LoadProfile(rank.pid, function(oProfile)
            self:_DoRankBack(oProfile, mHandle, rank)
        end)
    end
    record.user("hd_rankback", "save_count", {
        status =0,
        count = #lRankData,
        })
end

function CHuodong:_DoRankBack(oProfile, mHandle, mRank)
    mHandle.count = mHandle.count - 1
    if oProfile then
        local sAccount = oProfile:GetAccount()
        local l = mHandle.account[sAccount] or {}
        table.insert(l, {
            idx = mRank.idx,
            rank = mRank.rank,
            subtype = mRank.subtype, --该字段多榜会用到
            })
        mHandle.account[sAccount] = l
    end
    self:JudgeSendRankBack(mHandle)
end

function CHuodong:JudgeSendRankBack(mHandle)
    if mHandle.count <= 0 and not mHandle.is_send then
        record.info("rankback, start save")
        mHandle.is_send = true
        router.Send("cs", ".serversetter", "fuli", "UpdateRushRankBack", {data = mHandle.account})

        local iSendCount = 0
        for sAccount, m in pairs(mHandle.account) do
            iSendCount = iSendCount + #m
        end
        record.user("hd_rankback", "save_count", {
            status = 1,
            count = iSendCount,
            })
    end
end

function CHuodong:CheckRankBack(oPlayer)
    if oPlayer:FuliQuery("bRankBack", 0) ~= 0 then
        return
    end
    oPlayer:FuliSet("bRankBack", 1)
    local iPid = oPlayer:GetPid()
    local sAccount = oPlayer:GetAccount()
    router.Request("cs", ".serversetter", "fuli", "QueryRushRank", {account=oPlayer:GetAccount()}, function(mRecord, mData)
        self:_CheckRankBack(iPid, mData.info)
    end)
end

function CHuodong:_CheckRankBack(iPid, lRankData)
    lRankData = lRankData or {}
    for _, m in ipairs(lRankData) do
        local mDaoBiao = self:GetRankBackDaoBiao(m.idx, m.subtype)
        if mDaoBiao then
            local lItems = self:FilterItem(m, mDaoBiao)
            if #lItems > 0 then
                local iMailId = 89
                local sName = tostring(m.rank)
                --伙伴榜用90号邮件
                if m.subtype ~= 0 then
                    iMailId = 90
                    local mPar = loadpartner.GetPartnerData(m.subtype)
                    sName = mPar and mPar.name
                end
                local oMailMgr = global.oMailMgr
                local m, name = oMailMgr:GetMailInfo(iMailId)
                m.context = string.format(m.context, sName)
                oMailMgr:SendMail(0, name, iPid, m, {}, lItems)
            end
        else
            record.error("rank back config not exist! %s, %s, %s", iPid, m.idx, m.subtype)
        end
    end
end

function CHuodong:GetRankBackDaoBiao(idx, iSubType)
    local res = require "base.res"
    local m = res["daobiao"]["welfare_rank"]
    return m[idx] and m[idx][iSubType]
end

function CHuodong:FilterItem(mRank, lDaoBiao)
    local lItems = {}
    for _, m in ipairs(lDaoBiao) do
        local mRange = m.range
        if mRank.rank >= mRange.lower and mRank.rank <= mRange.upper then
            for _, mItem in ipairs(m.reward or {}) do
                local oItem = loaditem.ExtCreate(mItem.sid)
                oItem:SetAmount(mItem.amount or 1)
                table.insert(lItems, oItem)
            end
            break
        end
    end
    return lItems
end

function CHuodong:SendRankBackInfo(oPlayer)
    local obj = self:GetOpenObj()
    if obj then
        local mNet = {}
        mNet.starttime = obj:StartTime(self.m_sName)
        mNet.endtime =obj:EndTime(self.m_sName)
        oPlayer:Send("GS2CRankBack", mNet)
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
            self:NotifyOnlinePlayer()
        else
            oNotifyMgr:Notify(iPid, "后台活动未开始")
        end
    elseif iFlag == 102 then
        self:QueryRankBack()
            oNotifyMgr:Notify(iPid,"排行榜奖励已发送")
    elseif iFlag == 103 then
        oPlayer:FuliSet("bRankBack", nil)
        oNotifyMgr:Notify(iPid,"已重置")
    elseif iFlag == 104 then
        self:SetOpen(CLOSE)
        oNotifyMgr:Notify(iPid,"已关闭")
    end
end
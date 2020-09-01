--import module
local global = require "global"
local interactive = require "base.interactive"
local record = require "public.record"

local huodongbase = import(service_path("huodong.huodongbase"))

local SEND_TIME = 10 * 60
local RANK_END = 1
local RANK_SHOW_END = 2

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "限时冲榜"

inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_mSendRwd = {}
    local mConf = self:GetRushConfig()
    for idx, m in pairs(mConf) do
        self.m_mSendRwd[idx] = 0
    end
end

function CHuodong:LoadFinish()
    self:CheckRushClose()
end

--重启检测,看策划方案
function CHuodong:CheckRushClose()
    local oWorldMgr = global.oWorldMgr
    local iOpenDay = oWorldMgr:GetOpenDays()
    local mConf = self:GetRushConfig()
    local lEndRank = {}
    for idx, m in pairs(mConf) do
        local iCloseDay = self:RushCloseDay(idx)
        if self:IsSendRwd(idx) then
            if self:EndTime(idx) < get_time() then
                table.insert(lEndRank, {idx = idx, status = RANK_END})
            elseif self:ShowEndTime(idx) < get_time() then
                table.insert(lEndRank, {idx = idx, status = RANK_SHOW_END})
            end
        end
    end
    if next(lEndRank) then
        -- interactive.Send(".rank", "rank", "CheckRushRankEnd", {ranks = lEndRank})
    end
end

function CHuodong:SetSendRwd(idx, iSend)
    self:Dirty()
    self.m_mSendRwd[idx] = iSend or 1
end

function CHuodong:GetRushConfig()
    local res = require "base.res"
    local mData = res["daobiao"]["rushconfig"]
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    local mSend = mData["send_reward"] or {}
    for sIdx, iSend in pairs(mSend) do
        self.m_mSendRwd[tonumber(sIdx)] = iSend or self.m_mSendRwd[idx]
    end
end

function CHuodong:Save()
    local mData = {}

    local mSend = {}
    for idx, iSend in pairs(self.m_mSendRwd) do
        mSend[db_key(idx)] = iSend or 0
    end
    mData["send_reward"] = mSend
    return mData
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:OnLogin(oPlayer, bReEnter)
    if not self:IsShowClose() then
        self:SendRushRankInfo(oPlayer)
    end
end

function CHuodong:OnLogout(oPlayer)

end

function CHuodong:IsSendRwd(idx)
    if self.m_mSendRwd[idx] == 1 then
        return true
    end
    return false
end

function CHuodong:NewDay(iWeekDay)
    local oWorldMgr = global.oWorldMgr
    local iOpenDay = oWorldMgr:GetOpenDays()
    local mConf = self:GetRushConfig()
    local lRank = {}
    for idx, m in pairs(mConf) do
        local iCloseDay = self:RushCloseDay(idx)
        if m.open == 1 and not self:IsSendRwd(idx) and iCloseDay < iOpenDay then
            self:SetSendRwd(idx, 1)
            table.insert(lRank, idx)
        end
    end
    if next(lRank) then
        self:DoRushRankReward(lRank)
    end
end

function CHuodong:DoRushRankReward(lRank, sReason)
    sReason = sReason or "冲榜发奖"
    local oRankMgr = global.oRankMgr
    oRankMgr:DoRushRankReward(lRank)
    for _, idx in ipairs(lRank) do
        record.user("rank", "rushrank_send", {
            idx = idx,
            reason = sReason,
            })
    end
end

function CHuodong:EndTime(idx)
    return get_time() + self:EndSec(idx)
end

function CHuodong:RushCloseDay(idx)
    local mData = self:GetRushConfig()[idx]
    assert(mData, string.format("Huodong RushRnak, config:%s not exist!", idx))
    return mData.open_day
end

function CHuodong:IsClose()
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if oWorldMgr:IsClose("rushrank") then
        return true
    end
    local res = require "base.res"
    local mData = res["daobiao"]["rushconfig"]
    for idx, m in pairs(mData) do
        if self:EndTime(idx) > get_time() then
            return false
        end
    end
    return true
end

function CHuodong:IsShowClose()
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if oWorldMgr:IsClose("rushrank") then
        return true
    end
    local res = require "base.res"
    local mData = res["daobiao"]["rushconfig"]
    local iNow = get_time()
    for idx, m in pairs(mData) do
        if m.open == 1 and self:ShowEndTime(idx) > iNow then
            return false
        end
    end
    return true
end

function CHuodong:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("rushrank", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CHuodong:SendRushRankInfo(oPlayer)
    local lNet = {}
    local res = require "base.res"
    local mData = res["daobiao"]["rushconfig"]
    for idx, m in pairs(mData) do
        table.insert(lNet, {idx= idx, endtime = self:EndTime(idx), show_endtime = self:ShowEndTime(idx)})
    end
    oPlayer:Send("GS2CRushRankInfo", {rush = lNet})
end

function CHuodong:ShowEndTime(idx)
    return get_time() + self:EndSec(idx) + 24 * 60 * 60
end

function CHuodong:EndSec(idx)
    if self.m_iTestEnd then
        return self.m_iTestEnd
    end
    local oWorldMgr = global.oWorldMgr
    local iOpenDay = oWorldMgr:GetOpenDays()
    local mData = self:GetRushConfig()[idx]
    local iCloseDay = self:RushCloseDay(idx)
    local m = get_hourtime({hour = 0})
    local m2 = get_hourtime({factor = 1, hour = 24 - m.date.hour})
    local iSec = m2.time - get_time()
    return iSec + (iCloseDay - iOpenDay)* 24 * 60 *60
end

function CHuodong:TestOP(oPlayer, iCmd, ...)
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local iPid = oPlayer:GetPid()
    local mArgs = {...}
    if iCmd == 100 then
        oChatMgr:HandleMsgChat(oPlayer, "101-重置当前时间为开始时间")
        oChatMgr:HandleMsgChat(oPlayer, "102-发放冲榜奖励")
    elseif iCmd == 101 then
        self:Dirty()
        self.m_mSendRwd = {}
        self:SendRushRankInfo(oPlayer)
        oPlayer:NotifyMessage("已重置奖励")
    elseif iCmd == 102 then
        local lRank = {}
        local mConf = self:GetRushConfig()
        for idx, m in pairs(mConf) do
            local iCloseDay = self:RushCloseDay(idx)
            if not self:IsSendRwd(idx)then
                self:SetSendRwd(idx, 1)
                table.insert(lRank, idx)
            end
        end
        if next(lRank) then
            self:DoRushRankReward(lRank, "gm")
            oPlayer:NotifyMessage("奖励已经发放榜:" .. table.concat(table_value_list(lRank), ", "))
        else
            oPlayer:NotifyMessage("无可发放奖励，先执行重置指令")
        end
    elseif iCmd == 103 then
        self.m_iTestEnd = mArgs[1]
        oPlayer:NotifyMessage(string.format("设置冲榜过期时间：%s 秒", self.m_iTestEnd or 0))
    else
        print(self.m_mSendRwd)
    end
end
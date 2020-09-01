local global = require "global"
local record = require "public.record"
local res = require "base.res"
local datactrl = import(lualib_path("public.datactrl"))


function NewMonitor(...)
    return CNormalMonitor:New(...)
end

CBaseMonitor = {}
CBaseMonitor.__index = CBaseMonitor
inherit(CBaseMonitor, datactrl.CDataCtrl)

function CBaseMonitor:New()
    local o = super(CBaseMonitor).New(self)
    o.m_mRecord = {}
    return o
end

function CBaseMonitor:GetLimitInfo(...)
    return {}
end

function CBaseMonitor:Start()
    self.m_IsOpen = true
end

function CBaseMonitor:Stop()
    self.m_IsOpen = false
end

function CBaseMonitor:IsOpen()
    return self.m_IsOpen == true
end

function CBaseMonitor:CheckRewardGroup(...)
    return true
end

function CBaseMonitor:ClearRecordInfo(iPid)
    if iPid then
        if self.m_mRecord[iPid] then
            self.m_mRecord[iPid] = nil
        end
    else
        self.m_mRecord = {}
    end
end

----------------------------
CNormalMonitor = {}
CNormalMonitor.__index = CNormalMonitor
inherit(CNormalMonitor, CBaseMonitor)

function CNormalMonitor:New(sName, lUrl)
    local o = super(CNormalMonitor).New(self)
    o.m_sName = sName
    o.m_lUrl = lUrl
    return o
end

function CNormalMonitor:GetLimitInfo()
    local mInfo = table_get_depth(res["daobiao"], self.m_lUrl)
    if mInfo then
        return mInfo["rewardlimit"]
    end
    return super(CNormalMonitor).GetLimitInfo(self)
end

function CNormalMonitor:CheckRewardGroup(oPlayer, iReward, iCnt, mArgs)
    if not self:IsOpen() then return true end
    local sReward = tostring(iReward)
    local mLimitInfo = self:GetLimitInfo()
    if not mLimitInfo or not mLimitInfo[sReward] then return true end
    if oPlayer:GetData("testman", 0) == 99 then return true end

    iCnt = iCnt or 1
    local iPid = oPlayer:GetPid()
    local iTimes = table_get_depth(self.m_mRecord, {iPid, sReward}) or 0

    if iTimes < mLimitInfo[sReward] then
        iTimes = iTimes + iCnt
        table_set_depth(self.m_mRecord, {iPid}, sReward, iTimes)
        return true
    else
        record.error("%s get rewardidx %s in %s reach limit %d",
            oPlayer:GetPid(),
            sReward,
            self.m_sName,
            mLimitInfo[sReward]
        )
        return false
    end
end

function CNormalMonitor:CheckAddNumeric(oPlayer, sType, iVal)
    if not self:IsOpen() then return true end
    local mLimitInfo = self:GetLimitInfo()
    if not mLimitInfo[sType] then return true end
    if oPlayer:GetData("testman", 0) == 99 then return true end

    local iPid = oPlayer:GetPid()
    local iOld = table_get_depth(self.m_mRecord, {iPid, sType}) or 0

    if iOld < mLimitInfo[sType] then
        local iNew = iOld + iVal
        table_set_depth(self.m_mRecord, {iPid}, sType, iNew)
        return true
    else
        record.error("%s get reward %s %s in %s reach limit %s",
            oPlayer:GetPid(),
            sType,
            iVal,
            self.m_sName,
            mLimitInfo[sType]
        )
        --TODO notify?
        return false
    end
end

--------------------------------------
CTaskRewardMonitor = {}
CTaskRewardMonitor.__index = CTaskRewardMonitor
inherit(CTaskRewardMonitor, CBaseMonitor)

function CTaskRewardMonitor:New()
    local o = super(CTaskRewardMonitor).New(self)
    o.m_iDayNo = get_morningdayno(get_time())
    o:Start()
    return o
end

function CTaskRewardMonitor:TouchDayRefresh()
    local iCurDayNo = get_morningdayno(get_time())
    if self.m_iDayNo ~= iCurDayNo then
        self.m_iDayNo = iCurDayNo
        self.m_mRecord = {}
    end
end

function CTaskRewardMonitor:GetLimitInfo(sType)
    if not sType then
        return nil
    end
    return table_get_depth(res["daobiao"], {"reward", sType, "rewardlimit"})
end

function CTaskRewardMonitor:CheckRewardGroup(oPlayer, sType, sReward, iCnt, mArgs)
    if not self:IsOpen() then return true end
    if oPlayer:GetData("testman", 0) == 99 then return true end
    local iPid = oPlayer:GetPid()
    return self:CheckRewardGroupByPid(iPid, sType, sReward, iCnt, mArgs)
end

-- @param sReward: 默认是奖励表id转的string，也可以是特别定制的奖励标记(e.g. "total")
function CTaskRewardMonitor:CheckRewardGroupByPid(iPid, sType, sReward, iCnt, mArgs)
    local sRewardId = tostring(sReward)
    local mLimitInfo = self:GetLimitInfo(sType)
    if not mLimitInfo then return true end
    local iLimit = mLimitInfo[sRewardId]
    if not iLimit then return true end

    self:TouchDayRefresh()

    local iOldRewardTimes = table_get_depth(self.m_mRecord, {iPid, sType, sRewardId}) or 0
    local iRewardTimes = iOldRewardTimes + iCnt
    if iRewardTimes > iLimit then
        record.error("%s reward overlimit, pid:%d, rewardid:%s, rewardedtimes:%d, thiscnt:%d", sType, iPid, sRewardId, iOldRewardTimes, iCnt)
        return false
    end
    table_set_depth(self.m_mRecord, {iPid, sType}, sRewardId, iRewardTimes)
    return true
end

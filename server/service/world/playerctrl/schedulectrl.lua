local global = require "global"
local extend = require "base.extend"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local loadschedule = import(service_path("schedule.loadschedule"))
local loaditem = import(service_path("item.loaditem"))

local DAY_TASK = 3

CScheduleCtrl = {}
CScheduleCtrl.__index = CScheduleCtrl
inherit(CScheduleCtrl, datactrl.CDataCtrl)

function CScheduleCtrl:New(pid)
    local o = super(CScheduleCtrl).New(self, {pid = pid})
    o.m_mSchedules = {}
    return o
end

function CScheduleCtrl:RewardInfo()
    local res = require "base.res"
    return res["daobiao"]["schedule"]["activereward"]
end

function CScheduleCtrl:Load(mData)
    local mData = mData or {}
    local mSchedule = mData.schedules or {}
    local mArg = {pid=self:GetInfo("pid")}
    for _, data in pairs(mSchedule) do
        local oSchedule = loadschedule.LoadSchedule(data["id"], data,mArg)
        assert(oSchedule, string.format("schedule id error:%s,%s", self:GetInfo("pid"), data["id"]))
        self.m_mSchedules[oSchedule:ID()] = oSchedule
    end
    self:SetData("dayno", mData.dayno)
    self:SetData("reward", mData.reward)
    self:SetData("day_task",mData.daytask)
end

function CScheduleCtrl:Save()
    local mData = {}
    local mSchedule = {}
    for k, oSchedule in pairs(self.m_mSchedules) do
        table.insert(mSchedule, oSchedule:Save())
    end
    mData.schedules = mSchedule
    mData.dayno = self:GetData("dayno")
    mData.reward = self:GetData("reward")
    mData.daytask = self:GetData("day_task")
    return mData
end

function CScheduleCtrl:Release()
    for _,oSchedule in pairs(self.m_mSchedules) do
        baseobj_safe_release(oSchedule)
    end
    self.m_mSchedules = {}
    super(CScheduleCtrl).Release(self)
end

function CScheduleCtrl:UnDirty()
    super(CScheduleCtrl).UnDirty(self)
    for _, oSchedule in pairs(self.m_mSchedules) do
        if oSchedule:IsDirty() then
            oSchedule:UnDirty()
        end
    end
end

function CScheduleCtrl:IsDirty()
    local bDirty = super(CScheduleCtrl).IsDirty(self)
    if bDirty then
        return true
    end
    for _,oSchedule in pairs(self.m_mSchedules) do
        if oSchedule:IsDirty() then
            return true
        end
    end
    return false
end

function CScheduleCtrl:OnLogin(oPlayer, bReEnter)
    self:Refresh()
    self:GS2CLoginSchedule(oPlayer)
end

function CScheduleCtrl:OnLogout(oPlayer)
end

function CScheduleCtrl:OnDisconnected(oPlayer)
end

function CScheduleCtrl:Refresh()
    local todayno = get_dayno()
    if todayno > self:GetData("dayno", 0) then
        self:Reset()
    end
end

function CScheduleCtrl:Reset()
    local oWorldMgr = global.oWorldMgr
    local todayno = get_dayno()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    local iGrade = oPlayer:GetGrade()
    local mLog = {
    pid = self:GetInfo("pid",0),
    oldday = self:GetData("dayno",0),
    today = todayno,
    }
    record.user("schedule","schedule_reset",mLog)
    for _,oSchedule in pairs(self.m_mSchedules) do
        baseobj_safe_release(oSchedule)
    end
    self.m_mSchedules = {}
    self:SetData("dayno", todayno)
    self:SetData("reward", 0)
    local res = require "base.res"
    local mSelectTask = self:BuildTodayTaskList(iGrade)
    self:SetData("day_task",mSelectTask)
    self:Dirty()
end

function CScheduleCtrl:BuildTodayTaskList(iGrade)
    local res = require "base.res"
    local mPublic = res["daobiao"]["schedule"]["public"]
    local iServerDay = global.oWorldMgr:GetOpenDays()
    local mSelectTask = {}
    local iWeekDay = get_weekday()
    for iTask,m in pairs(mPublic) do
        local mGrade = m["grade"]
        local iOpenDay = m["server_day"] or 0
        if  m["maxfinish"] > 0 and mGrade["min"] <= iGrade and iGrade <= mGrade["max"] and iServerDay >= iOpenDay then
            if #m["open_week"] == 0 or table_in_list(m["open_week"],iWeekDay) then
                table.insert(mSelectTask,iTask)
            end
        end
    end
    return mSelectTask
end

function CScheduleCtrl:OnUpGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("schedule","open_grade")
    if iOpenGrade > oPlayer:GetGrade() then
        return
    end
    local res = require "base.res"
    local mDayTask = self:GetData("day_task",{})
    local mSelectTask = self:BuildTodayTaskList(oPlayer:GetGrade())
    local bChange = false
    for _,iTask in ipairs(mSelectTask) do
        if not table_in_list(mDayTask,iTask) then
            table.insert(mDayTask,iTask)
            bChange = true
        end
    end
    if bChange then
        self:SetData("day_task",mDayTask)
        self:GS2CLoginSchedule(oPlayer)
    end
end

function CScheduleCtrl:ValidSchedule(sid)
    local res = require "base.res"
    local mPublic = res["daobiao"]["schedule"]["public"]
    local mSchedule = mPublic[sid]
    if not mSchedule then
        return false
    end
    return true
end

function CScheduleCtrl:Name2ID(sName)
    local res = require "base.res"
    local mData = res["daobiao"]["schedule"]["name2id"]
    return mData[sName]
end

function CScheduleCtrl:AddByName(sName, mArgs)
    local id = self:Name2ID(sName)
    if id then
        self:Add(id, mArgs)
    end
end

function CScheduleCtrl:Add(id, mArgs)
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    self:Refresh()
    local oSchedule = self:GetSchedule(id)
    if not oSchedule then
        return
    end
    local res = require "base.res"
    local mPublic = res["daobiao"]["schedule"]["public"]
    local mSchedule = mPublic[id]
    local bTodayTask = false
    local mDayTask = self:GetData("day_task",{})
    if table_in_list(mDayTask,id) then
        bTodayTask = true
    end
    if #mSchedule["open_week"] > 0 and not bTodayTask then
        return false
    end

    mArgs["today"] = bTodayTask
    if not oSchedule.Add then
        record.error(string.format("addschedule %s %s",self:GetInfo("pid"),id))
    end
    local iResult = oSchedule:Add(mArgs)
    if iResult then
        self:GS2CRefreshSchedule(oSchedule)
    end
end

function CScheduleCtrl:GetSchedule(sid)
    local oSchedule = self.m_mSchedules[sid]
    if not oSchedule then
        if not self:ValidSchedule(sid) then
            return
        end
        local res = require "base.res"
        local mData = res["daobiao"]["schedule"]["public"]
        assert(mData[sid],string.format("createschedule err %d",sid))
        oSchedule = loadschedule.CreateSchedule(sid,{pid=self:GetInfo("pid")})
        self.m_mSchedules[sid] = oSchedule
        self:Dirty()
    end
    return oSchedule
end


function CScheduleCtrl:GetDoneTimes(id)
    self:Refresh()
    local oSchedule = self.m_mSchedules[id]
    if not oSchedule then
        return 0
    end
    return oSchedule:GetDoneTimes()
end

function CScheduleCtrl:GetActivePoint(id)
    self:Refresh()
    local oSchedule = self.m_mSchedules[id]
    if not oSchedule then
        return 0
    end
    return oSchedule:GetActivePoint()
end

function CScheduleCtrl:GetTotalPoint()
    self:Refresh()
    local total = 0
    for _, oSchedule in pairs(self.m_mSchedules) do
        total = total + oSchedule:GetActivePoint()
    end
    return total
end

function CScheduleCtrl:IsDone(id)
    self:Refresh()
    local oSchedule = self.m_mSchedules[id]
    if not oSchedule then
        return false
    end
    return oSchedule:IsDone()
end

function CScheduleCtrl:HasReward()
    local mActiveReward = self:GetInfo("activereward", {})
    local iTotPoint = self:GetTotalPoint()
    local maxidx = 0
    for idx, info in pairs(mActiveReward) do
        if iTotPoint >= info["point"] and idx > maxidx then
            maxidx = idx
        end
    end

    local iRewardMask = self:GetData("reward", 0)
    for i=1,maxidx do
        if 1 << i & iRewardMask == 0 then
            return true
        end
    end
    return false
end

function CScheduleCtrl:GetReward(idx)
    self:Refresh()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if not oPlayer then
        return
    end
    local iReward = self:GetData("reward", 0)
    if iReward & (1 << idx) == 1 << idx then
        return
    end
    local mActiverward = self:RewardInfo()
    local point = mActiverward[idx]["active"] or 999
    if self:GetTotalPoint() < point then
        return
    end
    local  mLog=  {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        idx  = idx,
        }
    record.user("schedule","get_reward",mLog)

    iReward = iReward | (1 << idx)

    self:SetData("reward", iReward)

    self:Reward(oPlayer, idx)
    oPlayer:Send("GS2CGetScheduleReward", {["rewardidx"]=iReward})
end

function CScheduleCtrl:Reward(oPlayer, idx)
    local oNotifyMgr = global.oNotifyMgr
     local mActiverward = self:RewardInfo()
     local mRewardList = mActiverward[idx]["reward"]
     local oHuodongMgr = global.oHuodongMgr
     local oHuodong = oHuodongMgr:GetHuodong("globaltemple")
     local iPid = oPlayer:GetPid()
     for _,iReward in ipairs(mRewardList) do
        oHuodong:Reward(iPid,iReward, {cancel_tip = 1})
     end
     oHuodong:LogAnalyGame("schedule",oPlayer)
    global.oUIMgr:ShowKeepItem(iPid)
end



function CScheduleCtrl:GS2CSchedule()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if not oPlayer then
        return
    end
    local oHuodongMgr = global.oHuodongMgr
    local res = require "base.res"
    local mPublic = res["daobiao"]["schedule"]["public"]
    local mDayTask = self:GetData("day_task",{})

    local mNet = {}
    mNet["schlist"] = {}
    for iTask,m in pairs(mPublic) do
        local oSchedule
        if m["def_create"] == 1 or table_in_list(mDayTask,iTask) then
            oSchedule = self:GetSchedule(iTask)
        else
            oSchedule = self.m_mSchedules[iTask]
        end
        if oSchedule then
            table.insert(mNet["schlist"],oSchedule:PackState(oPlayer))
        end
    end

    mNet["activepoint"] = self:GetTotalPoint()
    mNet["rewardidx"]  = self:GetData("reward", 0)
    mNet["open_day"] = oWorldMgr:GetOpenDays()
    oPlayer:Send("GS2CSchedule",mNet)
end

function CScheduleCtrl:GS2CLoginSchedule(oPlayer)
    local mNet = {}
    mNet["activepoint"] = self:GetTotalPoint()
    mNet["rewardidx"]  = self:GetData("reward", 0)
    mNet["day_task"] = self:GetData("day_task",{})
    oPlayer:Send("GS2CLoginSchedule",mNet)
end


function CScheduleCtrl:GS2CRefreshSchedule(oSchedule)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if not oPlayer then
        return
    end
    local mNet = {}
    mNet["activepoint"] = self:GetTotalPoint()
    mNet["schstate"] = oSchedule:PackState(oPlayer)
    oPlayer:Send("GS2CRefreshSchedule",mNet)
end

function CScheduleCtrl:ClickSchedule(oPlayer,sid)
    local res = require "base.res"
    local mData = res["daobiao"]["schedule"]["public"]
    if not mData[sid] then
        return
    end
    local oSchedule = self:GetSchedule(sid)
    if oSchedule then
        oSchedule:ClickSchedule(oPlayer)
    end
end

function CScheduleCtrl:SetScheduleStatus(oPlayer,sid,iStatus)
    local res = require "base.res"
    local mData = res["daobiao"]["schedule"]["public"]
    if not mData[sid] then
        return
    end
    local oSchedule = self:GetSchedule(sid)
    if oSchedule then
        oSchedule:SetScheduleStatus(oPlayer,iStatus)
    end
end
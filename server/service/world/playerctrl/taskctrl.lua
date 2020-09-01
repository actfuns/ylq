local skynet = require "skynet"
local global = require "global"
local extend = require "base.extend"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local tasknet = import(service_path("netcmd/task"))
local loadtask = import(service_path("task/loadtask"))
local gamedefines = import(lualib_path("public.gamedefines"))

local max = math.max
local min = math.min
local LILIAN_TASK_ID = 500
local REWARD_TIMES = 20
local LILIAN_OPEN_DAY = 0
local SHIMEN_TASKITEM_ID = 11616

TASK_CAN_ABANDON = {
    ["story"] = false
}

CTaskCtrl = {}
CTaskCtrl.__index = CTaskCtrl
inherit(CTaskCtrl, datactrl.CDataCtrl)

LOGIN_RELOAD_TEACHINFO = {
    [30007] = "addorgtime",
}

function CTaskCtrl:New(pid)
    local o = super(CTaskCtrl).New(self, {pid = pid})
    o.m_Owner = pid
    o.m_mList = {}
    o.m_mPartnerTask = {}   ---记录伙伴支线任务状态
    o.m_mError = {}
    return o
end

function CTaskCtrl:Release()
    for _,oTask in pairs(self.m_mList) do
        baseobj_safe_release(oTask)
    end
    self.m_mList = {}
    super(CTaskCtrl).Release(self)
end

function CTaskCtrl:Save()
    local mData = {}
    mData["Data"] = self.m_mData
    local mTaskData = {}
    for taskid,oTask in pairs(self.m_mList) do
        mTaskData[db_key(taskid)] = oTask:Save()
    end
    mData["TaskData"] = mTaskData
    mData["delay_event"] = self.m_DelayEvent
    mData["partnertask"] = self.m_mPartnerTask
    return mData
end

function CTaskCtrl:Load(mData)
    local m = mData or {}
    self.m_mData = table_deep_copy(m["Data"] or {})
    self.m_mTaskData = table_deep_copy(m["TaskData"] or {})
    self.m_DelayEvent = table_deep_copy(m["delay_event"] or {})
    self.m_mPartnerTask = table_deep_copy(m["partnertask"] or {})
end

function CTaskCtrl:ValidAddTask(oTask)
    local iType = oTask:Type()
    if iType == 12 or iType == 3 then
        if not self:ValidAcceptSideTask(oTask) then
            return false
        end
    end
    for _,taskobj in pairs(self.m_mList) do
        if taskobj.m_ID == oTask.m_ID then
            return false
        end
    end
    return true
end

function CTaskCtrl:AddTask(oTask,npcobj)
    if not self:ValidAddTask(oTask) then
        baseobj_delay_release(oTask)
        return
    end
    self:Dirty()
    oTask:Config(self.m_Owner,npcobj)
    oTask:Setup()
    self.m_mList[oTask.m_ID] = oTask
    oTask:SetTaskStatus(gamedefines.TASK_STATUS.TASK_CANACCEPT,"CreateTask")
    self:GS2CAddTask(oTask)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    record.user("task","add_task",{pid = self.m_Owner,name = oPlayer:GetName(),grade = oPlayer:GetGrade(),taskid = oTask.m_ID,tasktype = oTask:TaskType()})
    oTask:NewMessage(self.m_Owner,npcobj)
end

function CTaskCtrl:AddLilianTask()
    if not self:ValidGiveLilianTask() then
        return
    end
    local oLilianTask = loadtask.LoadTask(LILIAN_TASK_ID)
    if not oLilianTask then
        return
    end
    self:AddTask(oLilianTask)
    oLilianTask:AssignToPlayer(self.m_Owner)
    self:AddLilianTimes(20,"达到20级开启历练任务")
end

function CTaskCtrl:AddTeachTask(iTaskId)
    local oTeachTask = loadtask.LoadTask(iTaskId,{})
    if not oTeachTask then
        return
    end
    self:AddTask(oTeachTask)
    oTeachTask:AssignToPlayer(self.m_Owner)
end

function CTaskCtrl:AddHuodongTask(oTask)
    self:AddTask(oTask)
    oTask:AssignToPlayer(self.m_Owner)
    oTask:StartCountDownTime()
end

function CTaskCtrl:AcceptTask(iTaskId)
    local oTask = self.m_mList[iTaskId]
    if not oTask then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    local bResult,iError = oTask:PreCondition(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    if not bResult then
        if iError == 1 then
            oNotifyMgr:Notify(self.m_Owner,"等级不足，参加活动快速升级吧！")
        elseif iError == 2 then
            oNotifyMgr:Notify(self.m_Owner,"背包空间不足，请先整理背包")
        end
        return
    end
    oTask:AssignToPlayer(self.m_Owner)
end

function CTaskCtrl:AcceptSideTask(iTaskid)
    local oTask = loadtask.CreateTask(iTaskid)
    if not oTask then
        return
    end
    self:AddTask(oTask)
end

function CTaskCtrl:RemoveTask(oTask)
    self:Dirty()
    self.m_mList[oTask.m_ID] = nil
    self:GS2CRemoveTask(oTask)
    if oTask.m_ID >= 2000 and oTask.m_ID < 2999 then
        self:FinishDailyTask()
    end
    baseobj_delay_release(oTask)
end

function CTaskCtrl:ValidAbandon(sName)
    return TASK_CAN_ABANDON[sName]
end

function CTaskCtrl:TaskList()
    return self.m_mList
end

function CTaskCtrl:GetTask(taskid)
   return self.m_mList[taskid]
end

function CTaskCtrl:HasTask(taskid)
   local oTask = self.m_mList[taskid]
    if oTask then
        return oTask
    end
    return false
end

function CTaskCtrl:HasTaskType(iTaskType)
    for _,oTask in pairs(self.m_mList) do
        if oTask:Type() == iTaskType then
            return oTask
        end
    end
    return false
end

function CTaskCtrl:HasAnlei(iMap)
    for _,oTask in pairs(self.m_mList) do
        if oTask:IsAnlei() and oTask:ValidTriggerAnlei(iMap) then
            return true
        end
    end
    return false
end

function CTaskCtrl:IsDirty()
    local bDirty = super(CTaskCtrl).IsDirty(self)
   if bDirty then
        return true
    end
    for taskid,oTask in pairs(self.m_mList) do
        if oTask:IsDirty() then
            return true
        end
    end
    return false
end

function CTaskCtrl:UnDirty()
    super(CTaskCtrl).UnDirty(self)
    for taskid,oTask in pairs(self.m_mList) do
        if oTask:IsDirty() then
            oTask:UnDirty()
        end
    end
end

function CTaskCtrl:GS2CAddTask(oTask)
    local mNet = {}
    local mData = oTask:PackTaskInfo()
    mNet["taskdata"] = mData
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if oPlayer then
         oPlayer:Send("GS2CAddTask",mNet)
    end
end

function CTaskCtrl:GS2CRemoveTask(oTask,iDone)
    local mNet = {}
    mNet["taskid"] = oTask.m_ID
    mNet["done"] = iDone or 0
    local oPlayer = self:GetPlayer()
    if oPlayer then
        oPlayer:Send("GS2CDelTask",mNet)
    end
end

function CTaskCtrl:GetPlayer()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    return oPlayer
end

function CTaskCtrl:NewDay()
    self:UpdateShimenStatus()
end

function CTaskCtrl:OnLogin(oPlayer, bReEnter)
    --有常驻修行任务
    if not bReEnter then
        local res = require "base.res"
        local mTaskData = self.m_mTaskData or {}
        for taskid,mArgs in pairs(mTaskData) do
            taskid = tonumber(taskid)
            local oTask 
            if not self:CheckError(taskid,mArgs) then
                oTask = loadtask.LoadTask(taskid,mArgs)
            end
            if oTask then
                if not oTask:IsTimeOut() then
                    if oTask:GetStatus() ~= gamedefines.TASK_STATUS.TASK_CANACCEPT then
                        oTask:AssignToPlayer(self.m_Owner)
                    end
                    self.m_mList[taskid] = oTask
                else
                    oTask:TimeOut()
                    if oTask:TimeoutRemove() then
                        baseobj_safe_release(oTask)
                    else
                        self.m_mList[taskid] = oTask
                    end
                end
            end
        end
    else
        for iTaskId,_ in pairs(self.m_mList) do
            if self:CheckError(iTaskId) then
                self.m_mList[iTaskId] = nil
            end
        end
    end
    local mNet = {}
    local mData = {}
    for _,oTask in pairs(self.m_mList) do
        if oTask.m_ID == LILIAN_TASK_ID then
            oTask:OnLogin()
        end
        table.insert(mData,oTask:PackTaskInfo())
    end
    mNet["taskdata"] = mData
    if oPlayer then
        mNet["shimen_status"] = self:GetShimenStatus()
        oPlayer:Send("GS2CLoginTask",mNet)
    end
    local oTask = self:GetTask(LILIAN_TASK_ID)
    if oTask then
        self:CheckLilianOfflineRewardTime()
    end

    local oWorldMgr = global.oWorldMgr
    for iTaskid,sArgsName in pairs(LOGIN_RELOAD_TEACHINFO) do
        if self.m_mList[iTaskid] then
            oWorldMgr:LoadProfile(self.m_Owner,function (oProfile)
                local iTimes = oProfile:GetData(sArgsName,0)
                if iTimes > 0 then
                    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
                    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(iTaskid,iTimes)
                    oProfile:SetData(sArgsName,0)
                end
            end)
        end
    end
    self:RefreshTeachProgress()
    self:CheckVersionTask(oPlayer)
    self:CheckDelayEvent(oPlayer,bReEnter)
    self:RefreshPartnerTask(true)
    self:CheckLlianTask()
    self:AcceptErrorTask()
end

function CTaskCtrl:CheckError(iTaskid,mArgs)
    ----修复坏任务
    self.m_mError = self.m_mError or {}
    local res = require "base.res"
    local mErrorTask = res["daobiao"]["task"]["errortask"]
    if mErrorTask[iTaskid] then
        self.m_mError[mErrorTask[iTaskid]["new_task"]] = true
        return true
    end
    return false
end

function CTaskCtrl:AcceptErrorTask()
    if self.m_mError and table_count(self.m_mError) > 0 then
        for iTaskId,_ in pairs(self.m_mError) do
            local oTask = loadtask.CreateTask(iTaskId)
            self:AddTask(oTask)
        end
    end
end

function CTaskCtrl:CheckDelayEvent(oPlayer,bReEnter)
    if not bReEnter and table_count(self.m_DelayEvent)>0 then
        local iCurTime = get_time()
        for sEvent,iRefreshTime in pairs(self.m_DelayEvent) do
            if iCurTime >= iRefreshTime then
                self:DoDelayEvent(sEvent)
            else
                local iPid = self.m_Owner
                local func = function()
                    local oOwner = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
                    oOwner.m_oTaskCtrl:DoDelayEvent(sEvent)
                end
                self:AddTimeCb(sEvent,(iRefreshTime-iCurTime+1)*1000,func)
            end
        end
    end
end

function CTaskCtrl:CheckVersionTask(oPlayer)
    local iLastTask = oPlayer.m_oActiveCtrl:GetData("lasttask",0)
    if iLastTask == 0 then
        return
    end
    local res = require "base.res"
    local sArgs = res["daobiao"]["global"]["version_task"]["value"]
    if sArgs == 0 then
        return
    end
    local mArgs = split_string(sArgs,"-")
    local iOldTask,iNewTask = table.unpack(mArgs)
    if iLastTask == tonumber(iOldTask) then
        local oTask = loadtask.CreateTask(tonumber(iNewTask))
        if not oTask then
            return
        end
        self:AddTask(oTask)
    end
end

function CTaskCtrl:CheckLlianTask()
    local res = require "base.res"
    local mControlData = res["daobiao"]["global_control"]["lilian"]
    local iOpenSys = mControlData["is_open"] or "y"
    if iOpenSys ~= "y" then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = self:GetPlayer()
    if not oPlayer then
        return false
    end
    if oPlayer:GetGrade() >= mControlData.open_grade and not self:GetLilianTask() then
        self:AddLilianTask()
    end
end

function CTaskCtrl:OnLogout(oPlayer)
    local oTask = self:GetTask(LILIAN_TASK_ID)
    if oTask then
        oTask:ClearMonsterNpc()
    end
    for sEvent,_ in pairs(self.m_DelayEvent) do
        self:DelTimeCb(sEvent)
    end
end

function CTaskCtrl:OnDisconnected(oPlayer)
    local mTask = {10001,10004}
    for _,iTask in pairs(mTask) do
        local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
        if oWar and oWar:GetData("task_id") == iTask then
            local mArgs = {
                war_result = 2
            }
            oWar:TestCmd("warend",oPlayer:GetPid(),mArgs)
        end
    end
end

function CTaskCtrl:_CheckSelf()
    
end

function CTaskCtrl:GetShimenRatio()
    local res = require "base.res"
    return res["daobiao"]["shimenratio"]
end

function CTaskCtrl:ValidGiveShimenTask(iRing)
    local oPlayer = self:GetPlayer()
    if not oPlayer then
        return false
    end
    if oPlayer.m_oToday:Query("shimen_receive",0) > 2 then
        return false
    end
    if iRing > gamedefines.SHIMEN_MAXRING then
        return false
    end
    if self:GetShimenTask() then
        return false
    end
    return true
end

function CTaskCtrl:ValidGiveLilianTask()
    local res = require "base.res"
    local mControlData = res["daobiao"]["global_control"]["lilian"]
    local iOpenSys = mControlData["is_open"] or "y"
    if iOpenSys ~= "y" then
        return false
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = self:GetPlayer()
    if not oPlayer then
        return false
    end
    if oPlayer:GetGrade() < mControlData.open_grade then
        return false
    end
    local iServerDay = global.oWorldMgr:GetOpenDays()
    if iServerDay < LILIAN_OPEN_DAY then
        local mRefreshTime = get_daytime({day=LILIAN_OPEN_DAY-iServerDay,anchor=0})
        local iLeftTime = mRefreshTime.time - get_time()
        local iPid = self.m_Owner
        local func = function()
            local oOwner = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oOwner then
                oOwner.m_oTaskCtrl:DoDelayEvent("AL500")
            end
        end
        self:AddTimeCb("AL500",(iLeftTime+1)*1000,func)
        self.m_DelayEvent = self.m_DelayEvent or {}
        self.m_DelayEvent["AL500"] = mRefreshTime.time
        return false
    end
    local oTask = self:GetTask(LILIAN_TASK_ID)
    if oTask then
        return false
    end
    return true
end

function CTaskCtrl:DoDelayEvent(sEvent)
    self:Dirty()
    self:DelTimeCb(sEvent)
    self:DoScript(nil,self.m_Owner,nil,{sEvent},nil)
    self.m_DelayEvent[sEvent] = nil
end

function CTaskCtrl:AddShimenTask(iTaskId,iRing)
    if not self:ValidGiveShimenTask(iRing) then
        return
    end
    local taskobj = loadtask.CreateTask(iTaskId)
    if not taskobj then
        return
    end
    taskobj:SetData("Ring",iRing)
    self:AddTask(taskobj)
    self:AcceptTask(iTaskId)
end

function CTaskCtrl:AddAchieveTask(iTaskId,iTaskType)
    self.m_mAchieveInfo = self.m_mAchieveInfo or {}
    self.m_mAchieveInfo[iTaskType] = self.m_mAchieveInfo[iTaskType] or {}
    self.m_mAchieveInfo[iTaskType][iTaskId] = iTaskId
end

function CTaskCtrl:OnUpGrade(iGrade)
    if self.m_mAchieveInfo and self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_UPGRADE] then
        for _,iTaskId in pairs(self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_UPGRADE]) do
            local oTask = self.m_mList[iTaskId]
            oTask:OnUpGrade()
        end
    end
    self:CheckUpGradeEvent(iGrade)
end

function CTaskCtrl:GetTaskConfigData(iGrade)
    local res = require "base.res"
    local mConfigData = res["daobiao"]["task"]["config"][iGrade]
    mConfigData = mConfigData and table_deep_copy(mConfigData) or {}
    return mConfigData
end

function CTaskCtrl:CheckUpGradeEvent( iGrade )
    local mConfigData = self:GetTaskConfigData(iGrade)
    local mEvent = mConfigData["event"]
    self:DoScript(nil,self.m_Owner,nil,mEvent,nil)
end

function CTaskCtrl:OnAddFriend(iValue)
    if self.m_mAchieveInfo and self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_ADDFRIEND] then
        for _,iTaskId in pairs(self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_ADDFRIEND]) do
            local oTask = self.m_mList[iTaskId]
            oTask:OnAchieveTaskChange(gamedefines.ACHIEVE_TASK_TYPE.TASK_ADDFRIEND,iValue)
        end
    end
end

function CTaskCtrl:OnAddPartner(iValue)
    if self.m_mAchieveInfo and self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_ADDPARTNER] then
        for _,iTaskId in pairs(self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_ADDPARTNER]) do
            local oTask = self.m_mList[iTaskId]
            oTask:OnAchieveTaskChange(gamedefines.ACHIEVE_TASK_TYPE.TASK_ADDPARTNER,iValue)
        end
    end
end

function CTaskCtrl:OnAddPower(iValue)
    if self.m_mAchieveInfo and self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_ADDPOWER] then
        for _,iTaskId in pairs(self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_ADDPOWER]) do
            local oTask = self.m_mList[iTaskId]
            oTask:OnAchieveTaskChange(gamedefines.ACHIEVE_TASK_TYPE.TASK_ADDPOWER,iValue)
        end
    end
end

function CTaskCtrl:OnChouKa(iValue)
    if self.m_mAchieveInfo and self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_CHOUKA] then
        for _,iTaskId in pairs(self.m_mAchieveInfo[gamedefines.ACHIEVE_TASK_TYPE.TASK_CHOUKA]) do
            local oTask = self.m_mList[iTaskId]
            oTask:OnAchieveTaskChange(gamedefines.ACHIEVE_TASK_TYPE.TASK_CHOUKA,iValue)
        end
    end
end

function CTaskCtrl:DelAchieveTask(iType,iTaskId)
    if self.m_mAchieveInfo and self.m_mAchieveInfo[iType] then
        self.m_mAchieveInfo[iType][iTaskId] = nil
    end
end

function CTaskCtrl:TaskItemChange(mChangeInfo)
    for _,info in pairs(mChangeInfo) do
        local iTaskId,iSid = info.taskid,info.sid
        local oTask = self:HasTask(iTaskId)
        if not oTask then
            return
        end
        if extend.Table.find({gamedefines.TASK_STATUS.TASK_CANACCEPT,gamedefines.TASK_STATUS.TASK_FAILED},oTask:GetStatus()) or not extend.Table.find({gamedefines.TASK_TYPE.TASK_FIND_ITEM},oTask:TaskType()) then
            return
        end
        oTask:TaskItemChange(iSid)
    end
end

function CTaskCtrl:AddLilianTimes(iValue,sReason)
    local oTask = self:GetTask(LILIAN_TASK_ID)
    if not oTask then
        return
    end
    local mLilianInfo = self:GetLilianInfo()
    local iOldTimes = mLilianInfo.lefttime or 0
    local iNowTimes = iOldTimes + iValue
    if iNowTimes > 50 then
        iNowTimes = 50
    end
    local iCurDay = get_dayno()
    local m = os.date("*t", get_time())
    local iCurHour = m.hour
    local iCurMin = m.min
    local mRewardTime = {day=iCurDay,hour = iCurHour,min = iCurMin}
    self:Dirty()
    oTask:RefreshLilianTimes(iNowTimes,mRewardTime)
    record.user("lilian","times_change",{pid=self.m_Owner,oldtimes=iOldTimes,newtimes=iNowTimes,reason = sReason})
end

function CTaskCtrl:DelLilianTimes(iValue,sReason)
    local oTask = self:GetTask(LILIAN_TASK_ID)
    if not oTask then
        return
    end
    self:Dirty()
    local mLilianInfo = self:GetLilianInfo()
    local iOldTimes = mLilianInfo.lefttime or 0
    local iNowTimes = iOldTimes - iValue
    if iNowTimes < 0 then
        iNowTimes = 0
    end
    mLilianInfo.lefttime = iNowTimes
    oTask:RefreshLilianTimes(iNowTimes)
    record.user("lilian","times_change",{pid=self.m_Owner,oldtimes=iOldTimes,newtimes=iNowTimes,reason = sReason})
end

function CTaskCtrl:AddLilianReward(mReward)
    local oTask = self:GetTask(500)
    if oTask then
        oTask:AddLilianReward(mReward)
    end
end

function CTaskCtrl:GetLilianInfo()
    local oTask = self:GetLilianTask()
    return oTask:GetLilianInfo() or {}
end

function CTaskCtrl:GetLilianTask()
    return self:GetTask(LILIAN_TASK_ID)
end

function CTaskCtrl:GetLilianTimes()
    local mLilianInfo = self:GetLilianInfo()
    return (mLilianInfo.lefttime or 0)
end

function CTaskCtrl:CheckLilianOfflineRewardTime()
    local mLilianInfo = self:GetLilianInfo()
    local mRewardTime = mLilianInfo.rewardtime
    if not mRewardTime then
        return
    end
    local iLastRewardDay = mRewardTime.day
    local iLastRewardHour = mRewardTime.hour
    local iLastRewardMin = mRewardTime.min
    local iCurDay = get_dayno()
    local m = os.date("*t", get_time())
    local iCurHour = m.hour
    local iCurMin = m.min
    local iTotalRewardTime = 0
    if iCurDay > iLastRewardDay then
        iTotalRewardTime = iCurDay - iLastRewardDay
    end
    if iTotalRewardTime > 0 then
        self:AddLilianTimes(iTotalRewardTime*REWARD_TIMES,"奖励离线次数")
    end
end

function CTaskCtrl:DoScript(oTask,iPid,npcobj,s,mArgs)
    mArgs = mArgs or {}
    mArgs.cancel_tip = 1
    local iTipType = oTask and oTask:TipType() or nil
    if not iTipType or iTipType == 0 then
        mArgs.cancel_tip = nil
    end
    if type(s) ~= "table" then
        return
    end
    for _,ss in pairs(s) do
        self:DoScript2(oTask,iPid,npcobj,ss,mArgs)
    end
    if oTask then
        local iTaskid = oTask.m_ID
        local oHaveTask = self:GetTask(iTaskid)
        if oHaveTask then
            oHaveTask:DoScriptEnd(iPid)
        end
    end
end

function CTaskCtrl:DoScript2(oTask,iPid,npcobj,s,mArgs)
    if string.sub(s,1,4) == "DONE" then
        self:MissionDone(oTask,iPid)
        return
    elseif string.sub(s,1,2) == "NT" or string.sub(s,1,2) == "AP" or string.sub(s,1,2) == "AS" then
        local iTaskid = string.sub(s,3,-1)
        iTaskid = tonumber(iTaskid)
        self:NextTask(iTaskid,npcobj)
        return
    elseif string.sub(s,1,2) == "AL" then
        self:AddLilianTask()
    elseif string.sub(s,1,2) == "AT" then
        local iTaskid = string.sub(s,3,-1)
        iTaskid = tonumber(iTaskid)
        self:AddTeachTask(iTaskid)
    elseif string.sub(s,1,2 ) == "AD" then
        self:TirggerDailyTask()
    elseif string.sub(s,1,2) == "TP" then
        local iTaskid = string.sub(s,3,-1)
        assert(mArgs["parid"],"liuwei-debug:TriggerPartnerTask failed:"..iTaskid)
        self:_TrueTriggerPartnerTask(tonumber(iTaskid),mArgs["parid"])
    end
    if oTask then
        oTask:DoScript2(iPid,npcobj,s,mArgs)
    end
end

function CTaskCtrl:NextTask(iTask,npcobj)
    local oTask = loadtask.CreateTask(iTask)
    if not oTask then
        return
    end
    self:AddTask(oTask,npcobj)
end

function CTaskCtrl:MissionDone(oTask,iPid)
    if not self.m_mList[oTask.m_ID] then
        print("liuwei-debug:DONE了2次,"..oTask.m_ID)
        return
    end
    --assert(self.m_mList[oTask.m_ID],string.format("DONE了2次,%s",oTask.m_ID))
    --先解除玩家引用
    self:Dirty()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    assert(oPlayer,"MissionDone failed:"..iPid)
    self.m_mList[oTask.m_ID] = nil
    self:GS2CRemoveTask(oTask,1)
    local iTaskId = oTask.m_ID
    
    oTask:OnMissionDone(iPid,"任务完成")

    local mRewardArgs = oTask:GetRewardArgs()
    oTask:RewardMissionDone(iPid,nil, mRewardArgs)
    local mData = oTask:GetTaskData()
    self:DoScript(oTask,iPid,nil,mData["missiondone"])
    oTask:AfterMissionDone(iPid)
    oTask:DoScriptEnd(iPid)
    local iTipType = oTask:TipType()
    if iTipType and iTipType == 1 then
        global.oUIMgr:ShowKeepItem(iPid)
    end
    global.oUIMgr:ClearKeepItem(iPid)

    if oTask.m_sName == "daily" then
        self:FinishDailyTask()
    elseif oTask.m_sName == "story" then
        oPlayer.m_oHuodongCtrl:OnFinishStoryTask()
    end

    baseobj_delay_release(oTask)
    
    if oPlayer then
        oPlayer.m_oActiveCtrl:SetData("lasttask",iTaskId)
    end
end

function CTaskCtrl:AddTeachTaskProgress(iTaskid,iTimes)
    if not self.m_mList[iTaskid] then
        return
    end
    local oTask = self.m_mList[iTaskid]
    local iOldStatus = oTask:GetStatus()
    oTask:AddDoneTime(iTimes)
    local iStatus = oTask:GetStatus()
    if iStatus == gamedefines.TASK_STATUS.TASK_CANCOMMIT and iOldStatus~= iStatus then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = self:GetPlayer()
        local mProgress = oPlayer.m_oActiveCtrl:GetTeachTaskProgress() or {}
        mProgress["times"] = (mProgress["times"] or 0) + 1
        oPlayer.m_oActiveCtrl:SetTeachTaskProgress(mProgress)
        self:RefreshTeachProgress()
    end
end

function CTaskCtrl:GetTeachTaskReward(iTaskid)
    if not self.m_mList[iTaskid] then
        return
    end
    local oTask = self.m_mList[iTaskid]
    if not oTask:CanGetReward() then
        return
    end
    self:Dirty()
    local sType = oTask:GetType()
    oTask:GetReward()
    self:GS2CRemoveTask(oTask,1)
    baseobj_delay_release(oTask)
    self.m_mList[iTaskid] = nil
end

function CTaskCtrl:RefreshTeachProgress()
    local oPlayer = self:GetPlayer()
    local mProgress = oPlayer.m_oActiveCtrl:GetTeachTaskProgress()
    oPlayer:Send("GS2CTeachProgress",mProgress)
end


function CTaskCtrl:GetTeachProgressReward(iTimes)
    local oPlayer = self:GetPlayer()
    local mProgress = oPlayer.m_oActiveCtrl:GetTeachTaskProgress()
    local mGetStatus = mProgress["reward_status"] or 0
    if mGetStatus & 2 ^ (iTimes - 1) ~= 0 then
        return
    end
    if (mProgress["times"] or 0) < iTimes then
        return
    end
    local mRewardData = self:GetTeachProgressRewardInfo(iTimes)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("globaltemple")
    for _,idx in pairs(mRewardData) do
        oHuodong:Reward(self.m_Owner,idx)
    end
    mProgress["reward_status"] = mGetStatus | 2 ^ (iTimes - 1)
    oPlayer.m_oActiveCtrl:SetTeachTaskProgress(mProgress)
    self:RefreshTeachProgress()
end

function CTaskCtrl:GetTeachProgressRewardInfo(iTimes)
    local res = require "base.res"
    local mTeachBaseData = res["daobiao"]["task"]["teach"]["progress_reward"]
    for _,tbl in pairs(mTeachBaseData) do
        if tbl["progress"] == iTimes then
            return table_deep_copy(tbl["reward"])
        end
    end
    assert(false,string.format("not progress_reward config,progress:%d",iTimes))
end

function CTaskCtrl:ClickTaskInScene(oPlayer,iTaskid,iSceneId)
    local oTask = self:GetTask(iTaskid)
    if not oTask then
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene.m_fClickTaskFunc then
        oScene.m_fClickTaskFunc(oPlayer,iTaskid)
        return
    else
        oTask:Click(oPlayer.m_iPid)
    end
end

function CTaskCtrl:GetDailyTaskData()
    local res = require"base.res"
    return res["daobiao"]["task"]["daily"]["task"]
end

function CTaskCtrl:HasDailyTask()
    return (self:GetData("hasdailytask",0) == 1) and true or false
end

function CTaskCtrl:TirggerDailyTask()
    self:SetData("hasdailytask",1)
    self.m_HasDailyTask = true
    local mKey = table_key_list(self:GetDailyTaskData())
    assert(#mKey > 0 ,"每日任务导表无数据")
    local id = mKey[math.random(#mKey)]
    local oTask = loadtask.CreateTask(id)
    if not oTask then
        return
    end
    self:AddTask(oTask)
    local oPlayer = self:GetPlayer()
    if oPlayer then
        local iCurTimes = oPlayer.m_oToday:Query("dailytask",0)
        oPlayer.m_oToday:Set("dailytask",iCurTimes+1)
    end
end

function CTaskCtrl:FinishDailyTask()
    self:SetData("hasdailytask",0)
end

function CTaskCtrl:SyncTraceInfo(iTaskid,iCurMap,iCurPosX,iCurPosY)
    local oTask = self.m_mList[iTaskid]
    if not oTask then
        return
    end
    oTask:SyncTraceInfo(iTaskid,iCurMap,iCurPosX,iCurPosY)
end

function CTaskCtrl:TriggerPartnerTask(iParId)
    if self.m_mPartnerTask[iParId] then
        ---已经触发过
        return
    end
    local res = require "base.res"
    local mParterTaskConfig = res["daobiao"]["task"]["partner"]["config"]
    if mParterTaskConfig[iParId] then
        self:DoScript(nil,self.m_Owner,nil,mParterTaskConfig[iParId]["event"],{parid = iParId})
    end
end

function CTaskCtrl:_TrueTriggerPartnerTask(iTaskid,iParId)
    if self.m_mPartnerTask[iParId] then
        ---已经触发过
        return
    end
    self:Dirty()
    self.m_mPartnerTask[iParId] = {status=1,taskid=iTaskid}
    local oPlayer = self:GetPlayer()
    if oPlayer then
        oPlayer:Send("GS2CRefreshPartnerTask",{partnertask_progress = {{parid = iParId,status = 1,taskid = iTaskid}},refresh_id = 1})
    end
end

function CTaskCtrl:ValidAcceptSideTask(oTask)
    local iType = oTask:Type()
    if iType == 12 then  ----伙伴支线任务，最多只能接一个
        for iTaskid,oT in pairs(self.m_mList) do
            if oT.m_sName == "partner" then
                global.oNotifyMgr:Notify(self.m_Owner,"请先完成当前伙伴任务")
                return false
            end
        end
    elseif iType == 3 then  ----成就支线任务，最多可以接2个
    end
    return true
end

function CTaskCtrl:RefreshPartnerTask(bLogin,iParId,iTaskid)
    if bLogin then
        self:RefreshPartnerTask1()
    else
        self:RefreshPartnerTask2(iParId,iTaskid)
    end
end

function CTaskCtrl:RefreshPartnerTask1()
    local mProgress = {}
    for iParId,info in pairs(self.m_mPartnerTask) do
        table.insert(mProgress,{parid = iParId,status = info.status,taskid = info.taskid})
    end
    local oPlayer = self:GetPlayer()
    if oPlayer then
        oPlayer:Send("GS2CRefreshPartnerTask",{partnertask_progress = mProgress})
    end
end

function CTaskCtrl:RefreshPartnerTask2(iParId,iTaskid)
    self:Dirty()
    if iTaskid then
        self.m_mPartnerTask[iParId] = {status=2,taskid=iTaskid}
    else
        self.m_mPartnerTask[iParId] = {status=3}
    end
    local oPlayer = self:GetPlayer()
    if oPlayer then
        oPlayer:Send("GS2CRefreshPartnerTask",{partnertask_progress = {{parid = iParId,status = self.m_mPartnerTask[iParId]["status"],taskid = self.m_mPartnerTask[iParId]["taskid"]}},refresh_id = 1})
    end
end

--获取当前主线任务ID
function CTaskCtrl:GetCurStoryTaskId()
    for iTaskid,oTask in pairs(self.m_mList) do
        if oTask.m_sName == "story" then
            return iTaskid
        end
    end
    return 0
end

function CTaskCtrl:TriggerPatrolFight(iTask)
    local oTask = self:GetTask(iTask)
    if not oTask or oTask:TaskType() ~= gamedefines.TASK_TYPE.TASK_PATROL then
        return
    end
    oTask:TriggerPatrolFight()
end

function CTaskCtrl:GetShiMenRingTime()
    local oPlayer = self:GetPlayer()
    return oPlayer.m_oToday:Query("shimen_finish",0)
end

function CTaskCtrl:GetShimenTask()
    for iTaskid,oTask in pairs(self.m_mList) do
        if oTask.m_sName == "shimen" then
            return oTask
        end
    end
end

function CTaskCtrl:GetShimenStatus()
    local oPlayer = self:GetPlayer()
    local oTask = self:GetShimenTask()
    if oTask then
            return 2
    end
    if oPlayer:GetItemAmount(SHIMEN_TASKITEM_ID) > 0 then
        return 3
    end
    
    if oPlayer.m_oToday:Query("shimen_receive",0) < 2 then
        return 1
    else
        return 0
    end
end

function CTaskCtrl:UpdateShimenStatus()
    local iStatus = self:GetShimenStatus()
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CUpdateShimenStatus",{shimen_status = iStatus})
end
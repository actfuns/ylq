--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"

local analy = import(lualib_path("public.dataanaly"))
local loaditem = import(service_path("item/loaditem"))
local clientnpc = import(service_path("task/clientnpc"))
local loadtask = import(service_path("task/loadtask"))
local tasknet = import(service_path("netcmd/task"))
local gamedefines = import(lualib_path("public.gamedefines"))

local templ = import(service_path("templ"))

local min = math.min
local max = math.max
local floor = math.floor
local gsub = string.gsub

CTask = {}
CTask.__index = CTask
CTask.m_sName = "taskbase"
inherit(CTask, templ.CTempl)

function CTask:New(taskid)
    local o = super(CTask).New(self)
    o.m_ID = taskid
    o.m_SendRewardMailOnce = true
    o.m_PopRewardUIFirst = true
    o:Init()
    return o
end

function CTask:Init()
    self.m_Owner = 0
    self.m_mEvent = {}
    self.m_mNeedItem = {}
    self.m_mClientNpc = {}
    self.m_mTaskItem = {}
    self.m_mPlaceData = {}
    self.m_mAchieveInfo = {}
    self.m_mChangeShapeInfo = {}
    self.m_mTraceInfo = {}
    self.m_mStatusInfo = {}
    self.m_mGiveTaskItem = {}
    self.m_iGuideDesc = 1               --导航面板显示第几条描述
end

function CTask:GetTaskBaseData( ... )
   local res = require "base.res"
    local mData = res["daobiao"]["task"][self.m_sName] or {}
    return mData
end

function CTask:GetTaskData()
    local mData = self:GetTaskBaseData()
    mData = mData["task"][self.m_ID]
    assert(mData,string.format("CTask GetTaskData err%d",self.m_ID))
    return mData
end

function CTask:GetNpcGroupData(iGroup)
    local res = require "base.res"
    local mData = res["daobiao"]["npcgroup"] or {}
    mData = mData[iGroup]
    assert(mData,string.format("CTask GetNpcGroupData err%d",iGroup))
    return mData["npc"]
end

function CTask:GetTempNpcData(iTempNpc)
    local res = require "base.res"
    local iOwner = self.m_Owner
    local mData = self:GetTaskBaseData()
    local mData = mData["tasknpc"] or {}
    local mTempData = mData[iTempNpc]
    assert(mTempData,string.format("CTask GetTempNpcData err:%d player:%s",iTempNpc,iOwner))
    return mTempData
end

function CTask:GetEventData(iEvent)
    local res = require "base.res"
    local mData = self:GetTaskBaseData()
    mData = mData["taskevent"] or {}
    mData = mData[iEvent]
    local iOwner = self.m_Owner
    assert(mData,string.format("CTask GetEventData err:%d player:%s",iEvent,iOwner))
    return mData
end

function CTask:GetDialogData(iDialog)
    local res = require "base.res"
    local mData = self:GetTaskBaseData()
    mData = mData["taskdialog"] or {}
    mData = mData[iDialog]
    assert(mData,string.format("CTask:GetDialogData err:%d",iDialog))
    return table_deep_copy(mData["Dialog"])
end

function CTask:GetTaskItemData(itemid)
    local res = require "base.res"
    local mData = self:GetTaskBaseData()
    local mData = mData["taskitem"]
    mData = mData[itemid]
    local iOwner = self.m_Owner
    assert(mData,string.format("CTask:GetTaskItem err:%d player:%s",itemid,iOwner))
    return mData
end

function CTask:GetSceneGroup(iGroup)
    local res = require "base.res"
    local mData = res["daobiao"]["scenegroup"][iGroup]
    mData = mData["maplist"]
    assert(mData,string.format("CTask:scenegroup err:%d",iGroup))
    return mData
end

function CTask:GetTextData(iText)
    local mData = self:GetTaskBaseData()
    local mData = mData["tasktext"] or {}
    mData = mData[iText]
    assert(mData,string.format("CTask:GetTextData err:%d",iText))
    return mData["content"]
end

function CTask:GetTollGateData(iFight)
    local res = require "base.res"
    local mData = res["daobiao"]["tollgate"][self.m_sName]
    return mData[iFight]
end

function CTask:GetMonsterData(iMonsterIdx)
    local res = require "base.res"
    local mData = res["daobiao"]["monster"][self.m_sName]
    return mData[iMonsterIdx]
end

--任务类型:寻人，寻物等
function CTask:TaskType()
    local mData = self:GetTaskData()
    return mData["tasktype"]
end

function CTask:PlayID()
    local mData = self:GetTaskData()
    return mData["playid"]
end

function CTask:TypeName()
    local res = require "base.res"
    local mData = res["daobiao"]["task"]["tasktype"]
    local iType = self:Type()
    if not mData[iType] then return "未知任务类型" end
    return mData[iType]["name"]
end

--玩法分类
function CTask:Type()
    local mData = self:GetTaskData()
    return mData["type"]
end

--寻路类型
function CTask:AutoType()
    local mData = self:GetTaskData()
    return mData["autotype"]
end

function CTask:Name()
    local mData = self:GetTaskData()
    return self:TransString(self.m_Owner,nil,mData["name"])
end

--目标描述
function CTask:TargetDesc()
    local mData = self:GetTaskData()
    return self:TransString(self.m_Owner,nil,mData["goalDesc"][self.m_iGuideDesc])
end

--任务描述
function CTask:DetailDesc()
    local mData = self:GetTaskData()
    return self:TransString(self.m_Owner,nil,mData["description"])
end

--提示类型
function CTask:TipType()
    local mData = self:GetTaskData()
    return mData.tip_type
end

function CTask:NewMessage(pid,npcobj)
    local mData = self:GetTaskData()
    self:DoScript(pid,npcobj,mData["acceptDialogConfig"])
end

function CTask:InitNpcInfo()
    local mData = self:GetTaskData()
    local npctype = mData["acceptNpcId"]
    local iAcceptNpc = self:GetData("acceptnpc",0)
    if npctype ~= 0 and iAcceptNpc == 0 then
        if npctype < 1000 then
            local npclist = self:GetNpcGroupData(npctype)
            npctype = npclist[math.random(#npclist)]
        end
        self:SetData("acceptnpc",npctype)
    end
    npctype = mData["submitNpcId"]
    local iSubmitNpc = self:GetData("submitnpc",0)
    if npctype ~= 0 and iSubmitNpc == 0 then
        if npctype < 1000 then
            local npclist = self:GetNpcGroupData(npctype)
            npctype = npclist[math.random(#npclist)]
        end
        self:SetData("submitnpc",npctype)
    end
end


--设置行动目标
function CTask:SetTarget(npctype)
    self:Dirty()
    self:SetData("Target",npctype)
    if self:GetStatus() ~= gamedefines.TASK_STATUS.TASK_CANACCEPT then
        self:Refresh()
    end
end

--行动目标
function CTask:Target()
    local iTarget = self:GetData("Target")
    if iTarget then
        return iTarget
    end
    for _,oClientNpc in ipairs(self.m_mClientNpc) do
        return oClientNpc:Type()
    end
    for npctype,iEvent in pairs(self.m_mEvent) do
        return npctype
    end
end

function CTask:Config(pid,npcobj)
    self:Dirty()
    self.m_Owner = pid
    self:InitNpcInfo()
    local mData = self:GetTaskData()
    local sConfig = mData["config"]
    self:DoScript(pid,npcobj,sConfig)
    sConfig = mData["submitConditionStr"]
    self:DoScript(pid,npcobj,sConfig)
    self:SubConfig(pid)
end

function CTask:SubConfig()
    --
end

function CTask:ValidAssign(iPid)
    return true
end

function CTask:AssignToPlayer(iPid,bAutoAsign)
    if extend.Table.find({gamedefines.TASK_TYPE.TASK_ACHIEVE},self:TaskType()) then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oTaskCtrl:AddAchieveTask(self.m_ID,self.m_mAchieveInfo.type)
    end
    if self:GetStatus() ~= gamedefines.TASK_STATUS.TASK_CANACCEPT then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    if not self:ValidAssign(iPid) then
        if not bAutoAsign then
            oNotifyMgr:Notify(iPid,"组队状态下不可进行当前任务")
        end
        return
    end
    self:SetData("accepttime",get_time())
    self:SetData("owner",iPid)
    self:GiveTaskItem()
    local oNpc = self:GetNpcObjByType(self:GetData("acceptnpc",0))
    self:DoNpcEvent(self.m_Owner,oNpc.m_ID)
    self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_HASACCEPT,"Accept Task")
    self:AfterAssign()
end

function CTask:AfterAssign()
    local iTaskType = self:TaskType()
    if iTaskType == gamedefines.TASK_TYPE.TASK_FIND_ITEM then
        if self:ValidTakeItem(self.m_Owner) then
            local iNewStatus = gamedefines.TASK_STATUS.TASK_CANCOMMIT
            self:SetTaskStatus(iNewStatus,"任务完成")
        end
    elseif iTaskType == gamedefines.TASK_TYPE.TASK_ESCORT then
    else
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    assert(oPlayer,string.format("afterassign task failed,pid:%s",self.m_Owner))
    record.user("task","receive_task",{pid = self.m_Owner,name = oPlayer:GetName(),grade = oPlayer:GetGrade(),taskid = self.m_ID,tasktype = self:TaskType()})

    if loadtask.GetDir(self.m_ID) == "story" then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["main_step_id"] = self.m_ID
        mLog["main_step_type"] = "story"
        mLog["operation"] = 1
        mLog["consume_time"] = 0
        mLog["consume_detail"] = ""
        mLog["reward"] = ""
        analy.log_data("mainStep",mLog)
    end
end

function CTask:ChangeShape()
    self:Dirty()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    local mModelInfo = oPlayer:GetModelInfo()
    local iTaskShape = mModelInfo.shape
    oPlayer.m_oBaseCtrl:ChangeShape(self.m_mChangeShapeInfo.shape)
    self.m_mChangeShapeInfo.shape = iTaskShape
    local iNewStatus = gamedefines.TASK_STATUS.TASK_CANCOMMIT
    self:SetTaskStatus(iNewStatus,"任务完成")
end

function CTask:GiveTaskItem()
    if (#self.m_mGiveTaskItem <= 0 ) or self.m_mGiveTaskItem[4] then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    local iSid,iAmount,iBind = table.unpack(self.m_mGiveTaskItem)
    while(iAmount>0) do
        local oItem = loaditem.ExtCreate(iSid)
        local iAddAmount = math.min(oItem:GetMaxAmount(),iAmount)
        iAmount = iAmount - iAddAmount
        oItem:SetAmount(iAddAmount)
        if iBind ~= 0 then
            oItem:Bind(oPlayer:GetPid())
        end
        oPlayer:RewardItem(oItem,"任务道具", {cancel_tip=1})
    end
    self.m_mGiveTaskItem[4] = true
    self:Dirty()
end

function CTask:SetTimer(iMin)
    self:Dirty()
    self:SetData("Time",iMin)
end

function CTask:StartCountDownTime()
    if self:GetData("Time",0) == 0 then
        return
    else
        local iTime = self:GetData("Time") *60
        local iNowTime = get_time()
        self:SetData("StartTime",iNowTime)
        self:DelTimeCb("timeout")
        self:AddTimeCb("timeout",iTime*1000,function () self:TimeOut() end)
        self:RefreshTaskInfo()
    end
end

function CTask:StopCountDown()
    self:DelTimeCb("timeout")
end

function CTask:Timer()
    local iLastTime = self:GetData("Time",0)
    local iStartTime = self:GetData("StartTime",0)
    if iStartTime == 0 then
        return 0
    end
    local iEndTime = iStartTime + iLastTime*60
    local iNowTime = get_time()
    if iEndTime and iEndTime > iNowTime then
        return iEndTime - iNowTime
    end
    return 0
end

function CTask:Setup()
    local iTime = self:Timer()
    if iTime > 0 then
        self:DelTimeCb("timeout")
       self:AddTimeCb("timeout",iTime * 1000, function()  self:TimeOut()  end)
    end
end

function CTask:TimeOut()
    if extend.Table.find({gamedefines.TASK_TYPE.TASK_ESCORT},self:TaskType()) then
        local iNpcType = self.m_mTraceInfo.npctype
        local oNpcObj self:GetClientObj(iNpcType)
        self:RemoveClientNpc(oNpcObj)
    elseif self:TaskType() == gamedefines.TASK_TYPE.TASK_CHANGESHAPE then
        self:Dirty()
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
        local mModelInfo = oPlayer:GetModelInfo()
        local iTaskShape = mModelInfo.shape
        oPlayer.m_oBaseCtrl:ChangeShape(self.m_mChangeShapeInfo.shape)
        self.m_mChangeShapeInfo.shape = iTaskShape
    end
    self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_CANACCEPT,"TimeOut")
    self:Refresh()
    --self:Remove()
end

function CTask:TimeoutRemove()
    return false
end

function CTask:IsTimeOut()
    if not (self:GetStatus() == gamedefines.TASK_STATUS.TASK_HASACCEPT) then
        return false
    end
    local iEndTime = self:GetData("Time")
    if iEndTime and iEndTime <= get_time() then
        return true
    end
    return false
end

function CTask:GetStatus()
    return self.m_mStatusInfo.status
end

--设置玩家所处任务状态：1单人任务中，0非单人任务中
function CTask:SetPlayerTaskStatus(iStatus)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if not oPlayer then
        return
    end
    local mCurStatus = oPlayer:GetData("TaskStatus",{})
    if iStatus == 0 then
        if #mCurStatus > 0 then
            local i = 1
            for index=1,#mCurStatus do
                if mCurStatus[i].taskid == self.m_ID then
                    table.remove(mCurStatus,i)
                else
                    i = i+1
                end
            end
        end
    else
        table.insert(mCurStatus,{taskid = self.m_ID,status = iStatus})
    end
    oPlayer:SetData("TaskStatus",mCurStatus)
end

function CTask:SetTaskStatus(iStatus,sNote)
    self:Dirty()
    local iOldStatus = self.m_mStatusInfo.status or 0
    if iOldStatus == iStatus then
        return
    end
    self.m_mStatusInfo = {status = iStatus,note = sNote}

    if iStatus == gamedefines.TASK_STATUS.TASK_CANACCEPT then
        local iTargetType = self:GetData("acceptnpc",0)
        self:SetTarget(iTargetType)
        if sNote == "createtask" then
        end
        if extend.Table.find({gamedefines.TASK_TYPE.TASK_ESCORT},self:TaskType()) then
            local iNpcType = self.m_mTraceInfo.npctype
            local bHasCreate = false
            for _,npcobj in pairs(self.m_mClientNpc) do
                if npcobj:Type() == iNpcType then
                    bHasCreate = true
                    break
                end
            end
            if not bHasCreate then
                self:CreateClientNpc(iNpcType)
            end
        end
    else

        local iTargetType = self:GetData("submitnpc",0)
        self:SetTarget(iTargetType)
    end

    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    assert(oPlayer,string.format("set task status failed,pid:%s,%s,%s",self.m_Owner,self.m_ID,iStatus))
    record.user("task","statuschange_task",{pid = self.m_Owner,name = oPlayer:GetName(),grade = oPlayer:GetGrade(),taskid = self.m_ID,tasktype = self:TaskType(),old_status = iOldStatus,new_status = iStatus,reason = sNote})
end

function CTask:CheckCanCommit(pid,npcobj)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if extend.Table.find({gamedefines.TASK_TYPE.TASK_TRACE,gamedefines.TASK_TYPE.TASK_ESCORT,gamedefines.TASK_TYPE.TASK_CHANGESHAPE},self:TaskType()) then
        if self.m_mStatusInfo.status == gamedefines.TASK_STATUS.TASK_FAILED then
            oNotifyMgr:Notify(self.m_Owner,"任务目标不存在请注意任务时间")
            return false
        else
            if not npcobj then
                return
            end
            local iEvent = self:GetEvent(npcobj.m_ID)
            if not iEvent then
                return
            end
            local mEvent = self:GetEventData(iEvent)
            if not mEvent then
                return
            end
            self:DoScript(pid,npcobj,mEvent["win"])

        end
    end
end

function CTask:Save()
    local mData = {}
    local mNeedItem = {}
    for sid,iAmount in pairs(self.m_mNeedItem) do
        mNeedItem[db_key(sid)] = iAmount
    end
    mData["needitem"] = mNeedItem
    local mClientNpc = {}
    for _,oClientNpc in ipairs(self.m_mClientNpc) do
        table.insert(mClientNpc,oClientNpc:Save())
    end
    mData["clientnpc"] = mClientNpc
    local mEvent = {}
    for npctype,iEvent in pairs(self.m_mEvent) do
        mEvent[db_key(npctype)] = iEvent
    end
    mData["event"] = mEvent

    mData["taskitem"] = self.m_mTaskItem
    mData["placeinfo"] = self.m_mPlaceData
    mData["achieveinfo"] = self.m_mAchieveInfo
    mData["shapeinfo"] = self.m_mChangeShapeInfo
    mData["traceinfo"] = self.m_mTraceInfo
    mData["statusinfo"] = self.m_mStatusInfo
    mData["givetaskitem"] = self.m_mGiveTaskItem
    mData["pickiteminfo"] = self.m_mPickiteminfo
    mData["owner"] = self.m_Owner
    mData["data"] = self.m_mData
    mData["patrolinfo"] = self.m_mPatrolInfo
    mData["guidedesc"]  = self.m_iGuideDesc
    return mData
end

function CTask:Load(mData)
    mData = mData or {}
    local mClient = mData["clientnpc"] or {}
    for _,data in ipairs(mClient) do
        data["sys_name"] = self.m_sName
        local oClientNpc = clientnpc.NewClientNpc(data)
        table.insert(self.m_mClientNpc,oClientNpc)
    end
    local mNeedItem = mData["needitem"] or {}
    for sid,iAmount in pairs(mNeedItem) do
        sid = tonumber(sid)
        self.m_mNeedItem[sid] = iAmount
    end
    self.m_Owner = mData["owner"] or 0
    self.m_mData = mData["data"] or {}
    self.m_mTaskItem = mData["taskitem"] or {}
    self.m_mPlaceData = mData["placeinfo"] or {}
    self.m_mAchieveInfo = mData["achieveinfo"] or {}
    self.m_mChangeShapeInfo = mData["shapeinfo"] or {}
    self.m_mTraceInfo = mData["traceinfo"] or {}
    self.m_mStatusInfo = mData["statusinfo"] or {}
    self.m_mGiveTaskItem = mData["givetaskitem"] or {}
    self.m_mPickiteminfo = mData["pickiteminfo"] or {}
    local mEvent = mData["event"] or {}
    for npctype,iEvent in pairs(mEvent) do
        self.m_mEvent[tonumber(npctype)] = iEvent
    end
    local mAnlei = self:GetData("anlei",{})
    for sMapId,data in pairs(mAnlei) do
        mAnlei[tonumber(sMapId)] = data
    end
    self:SetData("anlei",mAnlei)
    self.m_mLilianInfo = mData["lilianinfo"] or {}
    self.m_mPatrolInfo = mData["patrolinfo"] or {}
    self.m_iGuideDesc = mData["guidedesc"] or 1
end

--[[
function CTask:Remove(sReason)
    local iCurStatus = self.m_mStatusInfo.status or 0
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    assert(oPlayer,string.format("remove task failed,pid:%s",self.m_Owner))
    record.user("task","remove_task",{pid = self.m_Owner,name = oPlayer:GetName(),grade = oPlayer:GetGrade(),taskid = self.m_ID,tasktype = self:TaskType(),status = iCurStatus,reason = sReason})
    local iOwner = self.m_Owner
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iOwner)
    if oPlayer then
        oPlayer.m_oTaskCtrl:RemoveTask(self)
    end
end
]]

function CTask:Release()
    self.m_mNeedItem = {}
    local oNpcMgr = global.oNpcMgr
    self.m_mClientNpc = self.m_mClientNpc or {}
    for _,oClientNpc in pairs(self.m_mClientNpc) do
        oNpcMgr:RemoveObject(oClientNpc:ID())
        baseobj_safe_release(oClientNpc)
    end
    self.m_mClientNpc = {}
    if self.m_oAnLeiCtrl then
        baseobj_safe_release(self.m_oAnLeiCtrl)
    end
    super(CTask).Release(self)
end

function CTask:Abandon()
    local iType = self:TaskType()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if oPlayer.m_oTaskCtrl:ValidAbandon(self.m_sName) then
        return
    end
    if oPlayer then
        if extend.Table.find({gamedefines.TASK_TYPE.TASK_CHANGESHAPE},iType) then
            local mModelInfo = oPlayer:GetModelInfo()
            local iTaskShape = mModelInfo.shape
            oPlayer.m_oBaseCtrl:ChangeShape(self.m_mChangeShapeInfo.shape)
            self:Dirty()
            self.m_mChangeShapeInfo.shape = iTaskShape
        elseif extend.Table.find({gamedefines.TASK_TYPE.TASK_USE_ITEM},iType) then
            local iSid,iAmount,iBind = table.unpack(self.m_mGiveTaskItem)
            oPlayer:RemoveItemAmount(iSid,iAmount,"放弃任务消耗物品")
        end
    end
    self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_CANACCEPT,"Abandon Task")
    self:StopCountDown()
end

--[[
function CTask:MissionDone(pid,npcobj)
    self:OnMissionDone(pid)

    local mRewardArgs = self:GetRewardArgs()
    self:RewardMissionDone(pid, npcobj, mRewardArgs)
    local mData = self:GetTaskData()
    self:DoScript(pid,npcobj,mData["missiondone"])
    self:AfterMissionDone(pid)
    self:Remove("任务完成")
end
]]

function CTask:RewardMissionDone(pid, npcobj, mRewardArgs)
    self:DoScript(pid,npcobj,self:RewardInfo(), mRewardArgs)
end

function CTask:GetRewardArgs()
    return nil
end

function CTask:OnMissionDone(pid,sReason)
    local iCurStatus = self.m_mStatusInfo.status or 0
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    assert(oPlayer,string.format("remove task failed,pid:%s",self.m_Owner))
    record.user("task","remove_task",{pid = self.m_Owner,name = oPlayer:GetName(),grade = oPlayer:GetGrade(),taskid = self.m_ID,tasktype = self:TaskType(),status = iCurStatus,reason = sReason})

    local iType = self:TaskType()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if oPlayer then
        if extend.Table.find({gamedefines.TASK_TYPE.TASK_CHANGESHAPE},iType) then
            oPlayer.m_oBaseCtrl:ChangeShape(self.m_mChangeShapeInfo.shape)
        end
    end
end

function CTask:AfterMissionDone(pid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if loadtask.GetDir(self.m_ID) == "story" then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["main_step_id"] = self.m_ID
        mLog["main_step_type"] = "story"
        mLog["operation"] = 2
        mLog["consume_time"] = get_time() - self:GetData("accepttime",0)
        mLog["consume_detail"] = ""
        for sid,iAmount in pairs(self.m_mNeedItem) do
            if mLog["consume_detail"] == "" then
                mLog["consume_detail"] =  string.format("%d+%d",sid,iAmount)
            else
                mLog["consume_detail"] =  string.format("%s&%d+%d",mLog["consume_detail"],sid,iAmount)
            end
        end
        local mKeepItem = self:GetKeep(oPlayer:GetPid(), "item", {})
        mLog["reward"] = ""
        for sid,mInfo in pairs(mKeepItem) do
            for _, iAmount in pairs(mInfo) do
                if sid > 10000 then
                    if mLog["reward"] == "" then
                        mLog["reward"] =  string.format("%d+%d",sid,iAmount)
                    else
                        mLog["reward"] =  string.format("%s&%d+%d",mLog["reward"],sid,iAmount)
                    end
                end
            end
        end
        analy.log_data("mainStep",mLog)
    end
end

function CTask:IsDone()
    return self:GetData("Done",0)
end

function CTask:SetDone()
    return self:SetData("Done",1)
end

function CTask:CreateClientNpc(iTempNpc,iMapId)
    local res = require "base.res"
    local oSceneMgr = global.oSceneMgr
    local mData = self:GetTempNpcData(iTempNpc)
    local iNameType = mData["nameType"]
    local sName
    if iNameType == 2 then
        sName = self:GetNpcName(iTempNpc)
    else
        sName = mData["name"]
    end
    local mModel = {
        shape = mData["modelId"],
        scale = mData["scale"],
        adorn = mData["ornamentId"],
        weapon = mData["wpmodel"],
        color = mData["mutateColor"],
        mutate_texture = mData["mutateTexture"],
    }
    local x,y
    local iMId = mData["sceneId"]
    if mData["x"] == 0 then
        iMId = iMapId or mData["sceneId"]
        if self.m_sName == "lilian" then
            local mP = oSceneMgr:RandomMonsterPos(iMapId)
            x, y = table.unpack(mP[1] )
        else
            x, y = oSceneMgr:RandomPos(iMId)
        end
    else
        x = mData["x"]
        y = mData["y"]
    end
    local mPosInfo = {
        x = x,
        y = y,
        z = mData["z"] or 0,
        face_x = mData["face_x"] or 0,
        face_y = mData["face_y"] or 0,
        face_z = mData["face_z"] or 0,
    }
    local mArgs = {
        type = mData["id"],
        map_id = iMId,
        model_info = mModel,
        pos_info = mPosInfo,
        event = mData["event"] or 0,
        reuse = mData["reuse"] or 0,
        dialogId = mData["dialogId"],
        taskid = self.m_ID,
        sys_name = self.m_sName,
    }
    local oClientNpc = clientnpc.NewClientNpc(mArgs)
    table.insert(self.m_mClientNpc,oClientNpc)
    self:Dirty()
    return oClientNpc
end

function CTask:RemoveClientNpc(npcobj)
    if not npcobj then
        return
    end
    local bFlag
    local npcid = npcobj.m_ID
    for _,oClientNpc in ipairs(self.m_mClientNpc) do
        if oClientNpc.m_ID == npcid then
            bFlag = true
        end
    end
    if not bFlag then
        return
    end
    self:Dirty()
    local iTarget = 0
    local iType = self:Target()
    if iType then
        local oTargetNpc = self:GetNpcObjByType(iType)
        iTarget = oTargetNpc:Type()
    end
    extend.Array.remove(self.m_mClientNpc,npcobj)
    local npcid = npcobj:ID()
    local oNpcMgr = global.oNpcMgr
    oNpcMgr:RemoveObject(npcid)
    baseobj_delay_release(npcobj)
    local mNet = {}
    mNet["taskid"] = self.m_ID
    mNet["npcid"] = npcid
    mNet["target"] = iTarget
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CRemoveTaskNpc",mNet)
end

function CTask:GetClientObj(npcid)
    for _,oClientNpc in pairs(self.m_mClientNpc) do
        if oClientNpc.m_ID == npcid then
            return oClientNpc
        end
    end
end

function CTask:GetNpcName(iTempNpc)
    return ""
end

--前置条件
function CTask:PreCondition(oPlayer)
    local iAcceptGrade = self:GetData("acceptgrade",0)
    if oPlayer.m_oBaseCtrl:GetData("grade",0) < iAcceptGrade then
        return false,1
    end
    local mData = self:GetTaskData()
    local mCondition = mData["acceptConditionStr"]
    if not mCondition then
        return
    end
    for _,mArgs in pairs(mCondition) do
        local sKey,iValue = string.match(mArgs,"(.-):(.+)")
        if sKey == "AI" then
            local iItemid,s = string.match(iValue,"(.-):(.+)")
            local iCount,iBind = string.match(s,"(.-):(.+)")
            if not oPlayer.m_oItemCtrl:ValidGive({{tonumber(iItemid),tonumber(iCount),tonumber(iBind)}},{cancel_tip = 1}) then
                return false,2
            else
                self:SetGiveTaskItem({tonumber(iItemid),tonumber(iCount),tonumber(iBind)})
            end
        end
    end
    return true
end

function CTask:GetItemGroup(iGroup)
    local res = require "base.res"
    local mData = res["daobiao"]["itemgroup"]
    mData = mData[iGroup]
    assert(mData,string.format("CTask:GetItemGroup err:%d",iGroup))
    return mData["itemgroup"]
end

function CTask:SetGiveTaskItem(mItem)
    self.m_mGiveTaskItem = mItem
    self:Dirty()
end

function CTask:SetNeedItem(itemid,iAmount)
    self:Dirty()
    --取道具组
    if itemid < 1000 then
        local mItemGroup = self:GetItemGroup(itemid)
        local sid = mItemGroup[math.random(#mItemGroup)]
        self.m_mNeedItem[sid] = iAmount
    else
        self.m_mNeedItem[itemid] = iAmount
    end
end

function CTask:NeedItem()
    return self.m_mNeedItem
end

function CTask:SetTaskItem(mArgs)
    local itemid,itemcount,bind = table.unpack(mArgs)
    self:Dirty()
    local mData = {
        itemid = tonumber(itemid),
        count = tonumber(itemcount),
        bind = tonumber(bind),
    }
    self.m_mTaskItem = mData
end

function CTask:SetPickInfo(iMapId,iPosx,iPosy,iPickId)
    self:Dirty()
    self.m_mPickiteminfo = {pickid = iPickId,map_id = iMapId,pos_x = iPosx,pos_y = iPosy}
end

function CTask:SetPlace(iMapId,iPosx,iPosy)
    self:Dirty()
    self.m_mPlaceData = {mapid = tonumber(iMapId),pos_x = tonumber(iPosx),pos_y = tonumber(iPosy)}
end

function CTask:SetAchieveInfo(iType,iNeed)
    self:Dirty()
    self.m_mAchieveInfo = {type = iType,value_need = iNeed,value_done = 0}
end

function CTask:SetShapeInfo(iShape)
    self:Dirty()
    self.m_mChangeShapeInfo.shape = iShape
end

function CTask:SetTraceInfo(iTraceId,iMapId,iPosx,iPosy)
    self:Dirty()
    self.m_mTraceInfo = {npctype = iTraceId,mapid = iMapId,pos_x = iPosx*1000,pos_y = iPosy*1000}
end

function CTask:SetAttr(mArgs)
    for _,sArgs in pairs(mArgs) do
        local key,value = string.match(sArgs,"(.+)=(.+)")
        if tonumber(value) then
            value = tonumber(value)
        end
        self:SetData(key,value)
    end
end

function CTask:DoScript(pid,npcobj,s,mArgs)
    local oWorldMgr = global.oWorldMgr
    local iPid = self.m_Owner
    assert(iPid == pid,string.format("task DoScript err:%s %s",iPid,pid))
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    oPlayer.m_oTaskCtrl:DoScript(self,iPid,npcobj,s,mArgs)
end

function CTask:CheckRewardMonitor(oPlayer, iReward, iCnt, mArgs)
    local oRewardMonitor = global.oTaskMgr:GetTaskRewardMonitor()
    if oRewardMonitor and not oRewardMonitor:CheckRewardGroup(oPlayer, self.m_sName, iReward, iCnt, mArgs) then
        return false
    end
    return true
end

function CTask:Reward(iPid, sIdx, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    assert(oPlayer,string.format("reward task failed,pid:%s",self.m_Owner))
    record.user("task","reward",{pid = iPid,name = oPlayer:GetName(),grade = oPlayer:GetGrade(),taskid = self.m_ID,tasktype = self:TaskType(),owner = self.m_Owner or 0,reward = sIdx})
    super(CTask).Reward(self,iPid, sIdx, mArgs)
end

function CTask:RewardPartnerExp(oPlayer,sPartnerExp,mArgs)
    local mPartner
    if mArgs and mArgs.win_side and mArgs.win_side == 1 then
        mPartner = self:GetFightPartner(oPlayer,mArgs)
    else
        mPartner = oPlayer.m_oPartnerCtrl:PackFightPartnerInfo()
    end
    local mExp = {}
    if mPartner then
        for iParId,mInfo in pairs(mPartner) do
            local iPartnerExp = self:TransReward(oPlayer,sPartnerExp, {level = mInfo.grade})
            iPartnerExp = math.floor(iPartnerExp)
            assert(iPartnerExp, string.format("schedule reward exp err: %s", sPartnerExp))
            if oPlayer.m_oPartnerCtrl:ValidUpgradePartner(mInfo.effect_type) then
                mExp[mInfo.parid] = iPartnerExp
            end
        end
    end
    oPlayer.m_oPartnerCtrl:AddPartnerListExp(table_deep_copy(mExp), self.m_sName, mArgs)
    self:AddKeep(oPlayer:GetPid(),"partner_exp",mExp)
end

function CTask:DoScript2(pid,npcobj,s,mArgs)
    super(CTask).DoScript2(self,pid,npcobj,s,mArgs)
    if string.sub(s,1,5) == "TIMER" then
        local iTime = string.sub(s,6,-1)
        iTime =tonumber(iTime)
        self:SetTimer(iTime)
    elseif string.sub(s,1,2) == "TI" then
        local sArgs = string.sub(s,4,-1)
        local mArgs = split_string(sArgs,":")
        self:SetTaskItem(mArgs)
   elseif string.sub(s,1,3) == "SET" then
        local sArgs = string.sub(s,5,-2)
        local mArgs = split_string(sArgs,"|")
        self:SetAttr(mArgs)
    elseif string.sub(s,1,4) == "ITEM" then
        --
    elseif string.sub(s,1,2) == "NC" then
        local npctype = string.sub(s,3,-1)
        npctype = tonumber(npctype)
        self:CreateClientNpc(npctype)
    elseif string.sub(s,1,1) == "E" then
        local sArgs = string.sub(s,2,-1)
        local npctype,iEvent = string.match(sArgs,"(.+):(.+)")
        npctype = tonumber(npctype)
        iEvent = tonumber(iEvent)
        self:SetEvent(npctype,iEvent)
    elseif string.sub(s,1,1) == "I" then
        local sArgs = string.sub(s,2,-1)
        local itemid,iAmount = string.match(sArgs,"(.+):(.+)")
        itemid = tonumber(itemid)
        iAmount = tonumber(iAmount)
        self:SetNeedItem(itemid,iAmount)
    elseif string.sub(s,1,8) == "TAKEITEM" then
        self:TakeNeedItem(pid,npcobj)
    elseif string.sub(s,1,6) == "TARGET" then
        local iTarget = string.sub(s,7,-1)
        iTarget = tonumber(iTarget)
        self:SetTarget(iTarget)
    elseif string.sub(s,1,2) == "DI" then
        local iDialog = string.sub(s,3,-1)
        iDialog = tonumber(iDialog)
        self:Dialog(pid,npcobj,iDialog)
    elseif string.sub(s,1,1) == "D" then
        local iText = string.sub(s,2,-1)
        iText = tonumber(iText)
        if not iText then
            return
        end
        local sText = self:GetTextData(iText)
        if sText then
            self:SayText(pid,npcobj,sText)
        end
    elseif string.sub(s,1,2) == "RN" then
        self:RemoveClientNpc(npcobj)
    elseif string.sub(s,1,5) == "ANLEI" then
        local sArgs = string.sub(s,7,-2)
        local mArgs = split_string(sArgs,":")
        local sMap,iTollgate,iCnt = table.unpack(mArgs)
        local lMap = split_string(sMap,"|")
        local iMap = lMap[math.random(#lMap)]
        self:SetAnlei(iMap,iTollgate,iCnt)
    elseif string.sub(s,1,4) == "PICK" then
        local sArgs = string.sub(s,5,-1)
        local mArgs = split_string(sArgs,":")
        local iMapId,iPosx,iPosy,iPickId = table.unpack(mArgs)
        self:SetPlace(iMapId,iPosx,iPosy)
        self:SetPickInfo(tonumber(iMapId),tonumber(iPosx),tonumber(iPosy),tonumber(iPickId))
    elseif string.sub(s,1,5) == "PLACE" then
        local sArgs = string.sub(s,6,-1)
        local mArgs = split_string(sArgs,":")
        local iMapId,iPosx,iPosy = table.unpack(mArgs)
        self:SetPlace(iMapId,iPosx,iPosy)
    elseif string.sub(s,1,3) == "_FP" or string.sub(s,1,9) == "STARTPICK" then
        self:FindPlace(pid,self.m_mPlaceData.mapid,self.m_mPlaceData.pos_x,self.m_mPlaceData.pos_y,self:TaskType())
    elseif string.sub(s,1,2) == "AT" then
        local sArgs = string.sub(s,4,-1)
        local mArgs = split_string(sArgs,":")
        local iType,iNeed = table.unpack(mArgs)
        self:SetAchieveInfo(tonumber(iType),tonumber(iNeed))
    elseif string.sub(s,1,5) == "SHAPE" then
        local sShape = string.sub(s,7,-1)
        self:SetShapeInfo(tonumber(sShape))
    elseif string.sub(s,1,6) == "TTRACE" then
        local sArgs = string.sub(s,7,-1)
        local mArgs = split_string(sArgs,":")
        local iTraceId,iMapId,iPosx,iPosy = table.unpack(mArgs)
        self:SetTraceInfo(tonumber(iTraceId),tonumber(iMapId),tonumber(iPosx),tonumber(iPosy))
    elseif string.sub(s,1,5) == "CHECK" then
        self:CheckCanCommit(pid,npcobj)
    elseif string.sub(s,1,5) == "GRADE" then
        local iAcceptGrade = tonumber(string.sub(s,6,-1))
        self:SetData("acceptgrade",iAcceptGrade)
    elseif string.sub(s,1,6) == "COMMIT" then
        self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_HASCOMMIT,"提交任务")
    elseif string.sub(s,1,6) == "PATROL" then
        local sArgs = string.sub(s,7,-1)
        local mArgs = split_string(sArgs,":")
        local iMap,iFight = table.unpack(mArgs)
        self:SetPatrolInfo(tonumber(iMap),tonumber(iFight))
    elseif string.sub(s,1,7) == "_PATROL" then
        self:StarPatrol()
    elseif string.sub(s,1,5) == "_DESC" then
        local sIndex = string.sub(s,6,-1)
        self:SetGuideDesc(tonumber(sIndex))
    elseif string.sub(s,1,7) == "_SUBMIT" then
        self:SubmitTask()
    elseif string.sub(s,1,10) == "STARTTRACE" then
        self:StartTrace()
    elseif string.sub(s,1,12) =="_STARTESCORT" then
        self:StarEscort(pid)
    elseif string.sub(s,1,7) == "USEITEM" then
        self:UseTaskItem()
    end
    self:OtherScript(pid,npcobj,s,mArgs)
end

function CTask:OtherScript(pid,npcobj,s,mArgs)
    -- body
end

function CTask:RewardInfo()
    local mData = self:GetTaskData()
    return mData["submitRewardStr"]
end

function CTask:NextTask(taskid,npcobj)
    local iOwner = self.m_Owner
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iOwner)
    if not oPlayer then
        return
    end
    local taskobj = loadtask.CreateTask(taskid)
    if not taskobj then
        return
    end
    oPlayer:AddTask(taskobj,npcobj)
end

function CTask:ValidFight(pid,npcobj,iFight)
    local mData = self:GetTaskData()
    local iTeamWork = mData["teamwork"]
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return false
    end
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        return false
    end
    if oPlayer:HasTeam() and iTeamWork == 0 then
        return false,gamedefines.FIGHTFAIL_CODE.HASTEAM
    end
    return true
end

function CTask:ValidTakeItem(pid,npcobj)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return false
    end
    for sid,iAmount in pairs(self.m_mNeedItem) do
        if oPlayer:GetItemAmount(sid) < iAmount then
            return false
        end
    end
    return true
end

--自动提交，以后需要根据规则修改
function CTask:TakeNeedItem(pid,npcobj)
    if not self:ValidTakeItem(pid,npcobj) then
        self:Click(pid)
        return
    end
    if not npcobj then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    local iTaskid = self.m_ID
    local lItem = {}
    for iShape,iAmount in pairs(self.m_mNeedItem) do
        table.insert(lItem,{iShape,iAmount})
    end
    local iNpcID = npcobj.m_ID
    local mArgs = {}
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
            if oTask then
                oTask:TrueTakeNeedItem(pid,iNpcID,mData)
            end
        end
    end
    oPlayer.m_oItemCtrl:RemoveItemList(lItem,"提交任务消耗物品",mArgs,fCallback)
end

function CTask:TrueTakeNeedItem(iPid,iNpcID,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    local iEvent = self:GetEvent(iNpcID)
    if not iEvent then
        return
    end
    local mEvent = self:GetEventData(iEvent)
    if not mEvent then
        return
    end
    local npcobj = self:GetNpcObj(iNpcID)
    self:DoScript(iPid,npcobj,mEvent["win"])
end

function CTask:UseTaskItem()
    if not self.m_mTaskItem.itemid then
        return
    end
    local iTaskid = self.m_ID
    local oCbMgr = global.oCbMgr
    if not self.m_mPlaceData.mapid then
        local func  =function(oPlayer,mData1)
            local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
            oTask:_FindPlaceScript2(oPlayer,mData1,oTask:TaskType())
        end
        oCbMgr:SetCallBack(self.m_Owner,"GS2CShowOpenBtn",{taskid = self.m_ID},nil,func)
    else
        self:FindPlace(self.m_Owner,self.m_mPlaceData.mapid,self.m_mPlaceData.pos_x,self.m_mPlaceData.pos_y,self:TaskType())
    end
end

function CTask:_TrueUseTaskItem(iPid)
    local iSid,iAmount = self.m_mTaskItem.itemid,self.m_mTaskItem.count
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    if oPlayer:GetItemAmount(iSid) < iAmount then
        return
    end
    local iTaskid = self.m_ID
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
            if oTask then
                oTask:_TrueUseTaskItem2(iPid,mData)
            end
        end
    end
    oPlayer:RemoveItemAmount(iSid,iAmount,"提交任务消耗物品",{},fCallback)
end

function CTask:_TrueUseTaskItem2(iPid,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    self:AfterFindPlace(iPid)
end

function CTask:AfterFindPlace(iPid)
    local iOldStatus = self:GetStatus()
    self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_HASCOMMIT,"提交任务")
    local oNpc = self:GetNpcObjByType(self:GetData("acceptnpc",0))
    local iEvent = self:GetEvent(oNpc.m_ID)
    if not iEvent then
        return
    end
    local mEvent = self:GetEventData(iEvent)
    if not mEvent then
        return
    end
    if iOldStatus == gamedefines.TASK_STATUS.TASK_HASCOMMIT and extend.Table.find({gamedefines.TASK_TYPE.TASK_NPC_FIGHT},self:TaskType()) then
        self:DoScript(iPid,oNpc,mEvent["after_win"])
    else
        self:DoScript(iPid,oNpc,mEvent["win"])
    end
end

function CTask:ValidTakeSummon()
    -- body
end

function CTask:TakeNeedSummon()
    -- body
end

function CTask:IsAnlei()
    if self:TaskType() ~= gamedefines.TASK_TYPE.TASK_ANLEI then
        return false
    end
    local mData = self:GetData("anlei",{})
    if table_count(mData) <= 0 then
        return false
    end
    if not self.m_oAnLeiCtrl then
        return false
    end
    return true
end

function CTask:SetAnlei(iMap,iEvent,iCnt)
    local mData = self:GetData("anlei",{})
    if mData[iMap] then
        return
    end
    self:Dirty()
    iMap = tonumber(iMap)
    iEvent = tonumber(iEvent)
    iCnt = tonumber(iCnt)
    mData[iMap] = {iEvent,0,iCnt}
    self:SetData("anlei",mData)

end

function CTask:ValidTriggerAnlei(iMap)
    local mData = self:GetData("anlei",{})
    if not mData[iMap] then
        return false
    end
    return true
end

--触发暗雷
function CTask:TriggerAnLei(iMap)
    local mData = self:GetData("anlei",{})
    local mAnlei = mData[iMap] or {}
    if not mAnlei then
        return
    end
    local iPid = self.m_Owner
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iEvent,iDoneCnt,iCnt = table.unpack(mAnlei)
    if iDoneCnt >= iCnt then
        oPlayer.m_oTaskCtrl:MissionDone(self,iPid)
        --self:MissionDone()
        return
    end

    local mEvent = self:GetEventData(iEvent)
    if not mEvent then
        return
    end
    self:DoScript(pid,nil,mEvent["look"])

    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        oNowWar.m_iEvent = iEvent
    end
end

function CTask:WarFightEnd(oWar,iPid,oNpc,mArgs)
    super(CTask).WarFightEnd(self,oWar,iPid,oNpc,mArgs)
    local win_side = mArgs.win_side
    if win_side == 1 then
        self:AfterWarWin(oWar, iPid, oNpc, mArgs)
    end
end

--策划需要战斗结束和任务结束的奖励区分，所以需要将结算弹框调整到具体的win和fail接口，否则战斗结束后任务直接完成的话任务奖励会覆盖掉战斗奖励，导致结算界面显示错误
function CTask:OnWarWin(oWar, pid, npcobj, mArgs)
    super(CTask).OnWarWin(self,oWar,pid,npcobj,mArgs)
    local iWarid = oWar:GetWarId()
    self:PopWarRewardUI(iWarid,mArgs)
end

function CTask:OnWarFail(oWar,pid,npcobj,mArgs)
    super(CTask).OnWarFail(self,oWar,pid,npcobj,mArgs)
    local iWarid = oWar:GetWarId()
    self:PopWarRewardUI(iWarid,mArgs)
end

function CTask:AfterWarWin(oWar,iPid,oNpc,mArgs)
    --除了每日修行，其他戰鬥任務戰鬥結束後任務完成
    if self.m_ID ~= 500 and self.m_ID ~= 502 then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            --oPlayer.m_oTaskCtrl:MissionDone(self,iPid)
            --self:MissionDone(iPid)
            local iEvent = self:GetEvent(oNpc.m_ID)
            if not iEvent then
                return
            end
            local mEvent = self:GetEventData(iEvent)
            if not mEvent then
                return
            end
            self:DoScript(iPid,oNpc,mEvent["after_win"])
        end
    end
end

function CTask:AfterCommit(pid)
    local npctype = self:Target()
    local oNpc = self:GetNpcObjByType(npctype)
    self:DoNpcEvent(pid,oNpc.m_ID,"after_commit")
end

--点击任务
function CTask:Click(pid)
    local iCurStatus = self:GetStatus()
    if iCurStatus == gamedefines.TASK_STATUS.TASK_HASCOMMIT then
        self:AfterCommit(pid)
        return
    end
    local iType = self:TaskType()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)

    local npctype
    if extend.Table.find({gamedefines.TASK_TYPE.TASK_FIND_NPC,gamedefines.TASK_TYPE.TASK_NPC_FIGHT,gamedefines.TASK_TYPE.TASK_SOCIAL},iType) then
        npctype = self:Target()
    --暂时测试，以后更改
    elseif extend.Table.find({gamedefines.TASK_TYPE.TASK_FIND_ITEM},iType) then
        if not self:ValidTakeItem(pid) then
            npctype = 5002
        else
            npctype = self:Target()
        end
    elseif extend.Table.find({gamedefines.TASK_TYPE.TASK_FIND_PLACE,gamedefines.TASK_TYPE.TASK_PICK,gamedefines.TASK_TYPE.TASK_SLIP},iType) then
        self:FindPlace(pid,self.m_mPlaceData.mapid,self.m_mPlaceData.pos_x,self.m_mPlaceData.pos_y,iType)
        return
    elseif extend.Table.find({gamedefines.TASK_TYPE.TASK_USE_ITEM},iType) then
        self:UseTaskItem()
        return
    elseif extend.Table.find({gamedefines.TASK_TYPE.TASK_ANLEI},iType) then
        local mData = self:GetData("anlei",{})
        for iMap,_ in pairs(mData) do
            local oSceneMgr = global.oSceneMgr
            iMap = tonumber(iMap)
            assert(iMap,string.format("anlei err:%d %d",self.m_Owner,self.m_ID))
            oSceneMgr:ChangeMap(oPlayer,iMap)
            oPlayer:Send("GS2CXunLuo",{type=1})
            return
        end
    elseif extend.Table.find({gamedefines.TASK_TYPE.TASK_ACHIEVE},iType) then
        self:CommitAchieveTask()
        return
    elseif extend.Table.find({gamedefines.TASK_TYPE.TASK_CHANGESHAPE,gamedefines.TASK_TYPE.TASK_TRACE,gamedefines.TASK_TYPE.TASK_ESCORT},iType) then
        npctype = self:Target()
        --self:CommitChangeShapeTask()
    elseif extend.Table.find({gamedefines.TASK_TYPE.TASK_PATROL},iType) then
        self:StarPatrol()
        return
    end
    if npctype then
        local oNpc = self:GetNpcObjByType(npctype)
        if not oNpc then
            return
        end
        local iMap = oNpc:MapId()
        local iX = oNpc.m_mPosInfo["x"]
        local iY = oNpc.m_mPosInfo["y"]
        local iNpcID = oNpc.m_ID
        local iTaskid = self.m_ID
        local func = function(oPlayer,mData)
            local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
            if not oTask then
                return
            end
            oTask:DoNpcEvent(oTask.m_Owner,iNpcID)
        end

        local mData = {["iMapId"] = iMap,["iPosx"] = iX,["iPosy"] = iY,["iAutoType"] = 1}
        self:FindTaskPath(mData,func)
    end
end

function CTask:GetNpcObj(npcid)
    for _,oClientNpc in pairs(self.m_mClientNpc) do
        if oClientNpc.m_ID == npcid then
            return oClientNpc
        end
    end
    local oNpcMgr = global.oNpcMgr
    local oNpc = oNpcMgr:GetObject(npcid)
    return oNpc
end

function CTask:GetNpcObjByType(npctype)
    for _,oClientNpc in pairs(self.m_mClientNpc) do
        if oClientNpc:Type() == npctype then
            return oClientNpc
        end
    end
    local oNpcMgr = global.oNpcMgr
    local oGlobalNpc = oNpcMgr:GetGlobalNpc(npctype)
    return oGlobalNpc
end

function CTask:SetEvent(npctype,iEvent)
    self:Dirty()
    for _,oClientNpc in pairs(self.m_mClientNpc) do
        if oClientNpc:Type() == npctype then
            oClientNpc:SetEvent(iEvent)
            return
        end
    end

    --SubmitNpc or AcceptNpc's event
    local mData = self:GetTaskData()
    local iTmp = mData["acceptNpcId"]
    local iAcceptNpc = self:GetData("acceptnpc",0)
    if npctype == tonumber(iTmp) then
        self.m_mEvent[iAcceptNpc] = iEvent
    end
    iTmp = mData["submitNpcId"]
    local iSubmitNpc = self:GetData("submitnpc",0)
    if npctype == tonumber(iTmp) then
        self.m_mEvent[iSubmitNpc] = iEvent
    end
end

function CTask:GetEvent(npcid)
    local oNpc = self:GetClientObj(npcid)
    local iEvent
    if oNpc then
        iEvent = oNpc.m_iEvent
    else
        local oNpcMgr = global.oNpcMgr
        oNpc = oNpcMgr:GetObject(npcid)
        if not oNpc then
            return
        end
        local npctype = oNpc:Type()
        iEvent = self.m_mEvent[npctype]
    end
    return iEvent
end

function CTask:DoNpcEvent(pid,npcid,sEvent)
    local oNpc = self:GetNpcObj(npcid)
    local iEvent = self:GetEvent(npcid)
    if not iEvent then
        return
    end
    local mEvent = self:GetEventData(iEvent)
    if not mEvent then
        return
    end
    if sEvent then
        self:DoScript(pid,oNpc,mEvent[sEvent])
    else
        self:DoScript(pid,oNpc,mEvent["look"])
    end
end

function CTask:Dialog(pid,npcobj,iDialog)
    local mData = self:GetDialogData(iDialog)
    if not mData then
        return
    end
    local Content = {}
    local iCurStatus = self:GetStatus()
    for i = 1,#mData do
        local mDialog  = mData[i]
        if mDialog["status"] == iCurStatus then
            mDialog["content"] = self:TransString(pid,npcobj,mDialog["content"])
            table.insert(Content,mDialog)
        end
    end
    local mNet = {}
    mNet["dialog"] = Content
    mNet["dialog_id"] = iDialog
    if not npcobj then
        self:GS2CDialog(pid,mNet)
        return
    end
    local npcid = npcobj.m_ID
    mNet["npc_id"] = npcid
    local iEvent = self:GetEvent(npcid)
    if not iEvent then
        self:GS2CDialog(pid,mNet)
        return
    end
    if self:TaskType() == gamedefines.TASK_TYPE.TASK_CHANGESHAPE then
        if iCurStatus == gamedefines.TASK_STATUS.TASK_CANCOMMIT  and npcobj.m_iType == self:GetData("submitnpc",0) then
            self:StopCountDown()
        end
    end
    local taskid = self.m_ID
    local func = function (oPlayer,mArgs)
        local oTask = oPlayer.m_oTaskCtrl:GetTask(taskid)
        if not oTask then
            return
        end
        oTask:AfterDialog(pid,iDialog,npcid,iCurStatus,mArgs)
    end

    mNet["dialog"] = Content
    mNet["npc_name"] = npcobj:Name()
    mNet["shape"] = npcobj:Shape()
    mNet["task_big_type"] = self:Type()
    mNet["task_small_type"] = self:TaskType()
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(pid,"GS2CDialog",mNet,nil,func)
end

function CTask:AfterDialog(pid,iDialog,npcid,iCurStatus,mArgs)
    local oNpc = self:GetNpcObj(npcid)
    if not oNpc then
        return
    end
    local iEvent = self:GetEvent(npcid)
    local mData = self:GetDialogData(iDialog)
    if not mData then
        return
    end
    local Content = {}
    local iChoiceIndex = 0
    local iFinishEventIndex = 0
    for i = 1,#mData do
        local mDialog  = mData[i]
        if mDialog["status"] == iCurStatus then
            if #mDialog["last_action"] > 0 and iChoiceIndex == 0 then
                iChoiceIndex = i
            end
            if mDialog["finish_event"] ~="" and iFinishEventIndex == 0 then
                iFinishEventIndex = i
            end
        end
    end
    if mArgs.answer and mArgs.answer ~= 0 then
        local Choice = mArgs.answer
        local event = mData[iChoiceIndex]["last_action"][Choice] and mData[iChoiceIndex]["last_action"][Choice]["event"]
        if event then
            self:DoScript(self.m_Owner,oNpc,{event})
        else
            local mEvent = self:GetEventData(iEvent)
            self:DoScript(pid,oNpc,mEvent["answer"])
        end
    else
        local iStatus = self:GetStatus()
        if iCurStatus ~= gamedefines.TASK_STATUS.TASK_CANACCEPT then
            if iCurStatus ~= gamedefines.TASK_STATUS.TASK_HASCOMMIT then
                local mEvent = self:GetEventData(iEvent)
                self:DoScript(pid,oNpc,mEvent["answer"])
            end
        else
            self:StartCountDownTime()
            if self:TaskType() == gamedefines.TASK_TYPE.TASK_CHANGESHAPE then--对话完毕才变身
                self:ChangeShape()
            end
        end
    end
    if iFinishEventIndex ~= 0 then
        local sE = mData[iFinishEventIndex]["finish_event"]
        local mE = split_string(sE,",")
        self:DoScript(pid,oNpc,mE)
    end
end

function CTask:SayText(pid,npcobj,sText)
    if not npcobj then
        local mNet = {}
        mNet["text"] = sText
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            oPlayer:Send("GS2CNpcSay",mNet)
        end
        return
    end

    local npcid = npcobj.m_ID
    local iEvent = self:GetEvent(npcid)
    if not iEvent then
        npcobj:Say(pid, sText)
        return
    end
    local mEvent = self:GetEventData(iEvent)
    local mAnswer = mEvent["answer"] or {}
    if table_count(mAnswer) == 0 then
        npcobj:Say(pid, sText)
        return
    end
    self:SayRespondText(pid,npcobj,sText)
end

function CTask:SayRespondText(pid,npcobj,sText)
    if not npcobj then
        return
    end
    local taskid = self.m_ID
    local npcid = npcobj.m_ID
    local resfunc = function (oPlayer,mData)
        local oTask = oPlayer.m_oTaskCtrl:GetTask(taskid)
        if not oTask then
            return false
        end
        local pid = oPlayer.m_iPid
        local oTeam = oPlayer:HasTeam()
        if oTeam and not oTeam:IsLeader(pid) and oTeam:IsTeamMember(pid) then
            return false
        end
        local oNpc = oTask:GetNpcObj(npcid)
        if not oNpc then
            return false
        end
        return true
    end
    local func = function(oPlayer,mData)
        local oTask = oPlayer.m_oTaskCtrl:GetTask(taskid)
        if not oTask then
            return
        end
        oTask:SayRespond2(npcid,mData)
    end
    npcobj:SayRespond(pid,sText,resfunc,func)
end

function CTask:SayRespond2(npcid,mData)
    local oNpc = oTask:GetNpcObj(npcid)
    local iEvent = oTask:GetEvent(npcid)
    if not iEvent then
        return
    end
    local mEvent = oTask:GetEventData(iEvent)
    if not mEvent then
        return
    end
    local iAnswer = mData["answer"]
    local mAnswer = mEvent["answer"]
    local s = mAnswer[iAnswer] or ""
    oTask:DoScript2(pid,oNpc,s)
end

function CTask:TransString(pid,npcobj,s)
    if not s then
        return
    end
    if string.find(s,"$owner") then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
             s=gsub(s,"$owner",oPlayer:GetName())
        end
    end
    if string.find(s,"{submitscene}") then
        local iType = self:Target()
        local oNpc = self:GetNpcObjByType(iType)
        if oNpc then
            local iMap = oNpc.m_iMapid
            local oSceneMgr = global.oSceneMgr
            local sSceneName = oSceneMgr:GetSceneName(iMap)
            s=gsub(s,"{submitscene}",sSceneName)
        else
            assert(oNpc,string.format("CTask:TransString %s %s %s",pid,self.m_ID,iType))
        end
    end
    if string.find(s,"{submitnpc}") then
        local iType = self:GetData("submitnpc",0)
        local oNpc = self:GetNpcObjByType(iType)
        if oNpc then
            s = gsub(s,"{submitnpc}",oNpc:Name())
        else
            assert(oNpc,string.format("TransString submitnpc err:%s %s %s",pid,self.m_ID,iType))
        end
    end
    if string.find(s,"{placescene}") then
        local iSceneId = self.m_mPlaceData.mapid
        local iPosx = self.m_mPlaceData.pos_x
        local iPosy = self.m_mPlaceData.pos_y
        if iSceneId then
            local oSceneMgr = global.oSceneMgr
            local sSceneName = oSceneMgr:GetSceneName(iSceneId) or ""
            s = gsub(s,"{placescene}",sSceneName)
            s = gsub(s,"{posx,posy}",string.format("%d,%d",iPosx,iPosy))
        end
    end
    if string.find(s,"value_done") then
        local iDone = self.m_mAchieveInfo.value_done or 0
        local iNeed = self.m_mAchieveInfo.value_need
        s = gsub(s,"value_done",iDone)
        s = gsub(s,"value_need",iNeed)
    end
    if string.find(s,"{item}") then
        for itemid,iAmount in pairs(self.m_mNeedItem) do
            local itemobj = loaditem.GetItem(itemid)
            s = gsub(s,"{item}",itemobj:Name())
            break
        end
    end
    if string.find(s,"{count}") then
        for itemid,iAmount in pairs(self.m_mNeedItem) do
            s = gsub(s,"{count}",iAmount)
            break
        end
    end
    if string.find(s,"{liliantime}") then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
        local iLeftTime = 10
        if oPlayer then
            iLeftTime = oPlayer.m_oTaskCtrl:GetLilianTimes()
        end
        s = gsub(s,"{liliantime}",iLeftTime)
    end
    return s
end

function CTask:Refresh(mNet)
    local mNet = {}
    mNet["taskid"] = self.m_ID
    mNet["target"] = self:Target()
    mNet["name"] = self:Name()
    mNet["statusinfo"] = self.m_mStatusInfo
    mNet["accepttime"] = self:GetData("accepttime",0)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if oPlayer then
        oPlayer:Send("GS2CRefreshTask",mNet)
    end
end

function CTask:GS2CDialog(pid,mNet)
    mNet = mNet or {}
    mNet["task_type"] = self:Type()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        oPlayer:Send("GS2CDialog",mNet)
    end
end

function CTask:PackTaskInfo()
    local mNet = {}
    mNet["taskid"] = self.m_ID
    mNet["tasktype"] = self:TaskType()
    mNet["type"] = self:Type()
    mNet["name"] = self:Name()
    mNet["targetdesc"] = self:TargetDesc()
    mNet["detaildesc"] = self:DetailDesc()
    mNet["acceptnpc"] = self:GetData("acceptnpc")
    mNet["submitnpc"] = self:GetData("submitnpc")
    mNet["target"] = self:Target()
    mNet["isdone"] = self:IsDone()
    mNet["accepttime"] = self:GetData("accepttime",0)
    local mData = {}
    local mNeedItem = self:NeedItem()
    for itemid,amount in pairs(mNeedItem) do
        table.insert(mData,{itemid=itemid,amount=amount})
    end
    mNet["needitem"] = mData
    mNet["rewardinfo"] = self:RewardInfo()
    mNet["time"] = self:Timer()
    local mClientData = {}
    for _,oClientNpc in pairs(self.m_mClientNpc) do
        table.insert(mClientData,oClientNpc:PackInfo())
    end
    mNet["clientnpc"] = mClientData
    mNet["taskitem"] = self.m_mTaskItem
    mNet["placeinfo"] = self.m_mPlaceData
    mNet["shapeinfo"] = self.m_mChangeShapeInfo
    mNet["traceinfo"] = self.m_mTraceInfo
    mNet["statusinfo"] = self.m_mStatusInfo
    mNet["pickiteminfo"] = self.m_mPickiteminfo
    mNet["acceptgrade"] = self:GetData("acceptgrade",0)
    mNet["playid"] = self:PlayID()
    mNet["patrolinfo"] = self:PackPatrolInfo()
    return mNet
end

function CTask:FindPlace(iPid,iMapId,iPosx,iPosy,iTaskType)

    if not iMapId then
        return
    end
    local iTaskid = self.m_ID
    local func = function(oPlayer,mData)
        local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
        if not oTask then
            return
        end
        oTask:_FindPlaceScript1(iPid,iMapId,iPosx,iPosy,iTaskType)
    end
    local mData = {["iMapId"] = iMapId,["iPosx"] = iPosx,["iPosy"] = iPosy,["iAutoType"] = 1}
    self:FindTaskPath(mData,func)
end

function CTask:_FindPlaceScript1(iPid,iMapId,iPosx,iPosy,iTaskType)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local iTaskid = self.m_ID
    if extend.Table.find({gamedefines.TASK_TYPE.TASK_USE_ITEM,gamedefines.TASK_TYPE.TASK_FIND_PLACE,gamedefines.TASK_TYPE.TASK_PICK,gamedefines.TASK_TYPE.TASK_SLIP},iTaskType) then
        local oCbMgr = global.oCbMgr
        local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
        local mPosInfo = oPlayer.m_oActiveCtrl:GetNowPos()
        local iMap = oNowScene:MapId()
        local iCPosx,iCPosy = mPosInfo.x,mPosInfo.y

        if iMap == iMapId and gamedefines.OverPosRange(iCPosx,iCPosy,iPosx,iPosy) then
            local func  =function(oPlayer,mData1)
                local oWorldMgr = global.oWorldMgr
                local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
                local oTask = oP.m_oTaskCtrl:GetTask(iTaskid)
                if oTask then
                    oTask:_FindPlaceScript2(oP,mData1,iTaskType)
                else
                    record.warning(string.format("taskobj err, task id:%s", iTaskid))
                end
            end
            oCbMgr:SetCallBack(iPid,"GS2CShowOpenBtn",{taskid = self.m_ID},nil,func)
        end
    else
        self:_FindPlaceScript2(oPlayer,nil,iTaskType)
    end
end

function CTask:_FindPlaceScript2(oPlayer,mData,iTaskType)
    if extend.Table.find({gamedefines.TASK_TYPE.TASK_USE_ITEM},iTaskType) then
        self:_TrueUseTaskItem(oPlayer.m_iPid)
    else
        self:AfterFindPlace(oPlayer.m_iPid)
    end
end

function CTask:OnAchieveTaskChange(iAchieveTaskType,iValue)
    if not self.m_mAchieveInfo or not self.m_mAchieveInfo.type or not self.m_mAchieveInfo.type == iAchieveTaskType then
        return
    end
    self:Dirty()
    self.m_mAchieveInfo.value_done = self.m_mAchieveInfo.value_done + iValue
    if self.m_mAchieveInfo.value_done == self.m_mAchieveInfo.value_need then
        self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_CANCOMMIT,"任务完成")
    end
    self:RefreshTaskInfo()
end

function CTask:RefreshTaskInfo()
    local mNet = {}
    local mData = self:PackTaskInfo()
    mNet["taskdata"] = mData
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if oPlayer then
         oPlayer:Send("GS2CRefreshTaskInfo",mNet)
    end
end

function CTask:CommitAchieveTask()
    if not self.m_mAchieveInfo or not self.m_mAchieveInfo.type or not (self.m_mAchieveInfo.value_need <= self.m_mAchieveInfo.value_done) then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    oPlayer.m_oTaskCtrl:DelAchieveTask(self.m_mAchieveInfo.type,self.m_iTaskid)
    --self:MissionDone(self.m_Owner)
    oPlayer.m_oTaskCtrl:MissionDone(self,self.m_Owner)
end

function CTask:CommitChangeShapeTask()
    if not self.m_mChangeShapeInfo.shape then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    local mModelInfo = oPlayer:GetModelInfo()
    if mModelInfo.shape == self.m_mChangeShapeInfo.shape then
        oPlayer.m_oTaskCtrl:MissionDone(self,self.m_Owner)
    else
        oNotifyMgr:Notify(self.m_Owner,"伪装目标错误")
        return
    end
end

function CTask:TaskItemChange(sid)
    local iNewStatus = nil
    if self:ValidTakeItem(self.m_Owner) then
        iNewStatus = gamedefines.TASK_STATUS.TASK_CANCOMMIT
    else
        iNewStatus = gamedefines.TASK_STATUS.TASK_HASACCEPT
    end
    local iOldStatus = self.m_mStatusInfo.status
    if iNewStatus ~= iOldStatus then
        self:SetTaskStatus(iNewStatus,"任务物品数量改变")
    end
end

function CTask:GetSelfCallback()
    local iPid = self.m_Owner
    local iTaskid = self.m_ID
    return function()
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oPlayer then
            return
        end
        return oPlayer.m_oTaskCtrl:GetTask(iTaskid)
    end
end

function CTask:GetAcceptTime()
    return self:GetData("accepttime",0)
end

function CTask:SyncTraceInfo(iTaskid,iCurMap,iCurPosX,iCurPosY)
    self.m_mTraceInfo = self.m_mTraceInfo or {}
    self.m_mTraceInfo.cur_mapid = iCurMap
    self.m_mTraceInfo.cur_posx = iCurPosX
    self.m_mTraceInfo.cur_posy = iCurPosY
end

function CTask:SetPatrolInfo(iMap,iFight)
    self:Dirty()
    self.m_mPatrolInfo = {mapid = iMap,fightid = iFight}
end

function CTask:PackPatrolInfo()
    local iMap = self.m_mPatrolInfo and self.m_mPatrolInfo["mapid"] or nil
    return {mapid = iMap}
end

function CTask:TriggerPatrolFight()
    local iFight = self.m_mPatrolInfo and self.m_mPatrolInfo["fightid"] or nil
    if not iFight then
        return
    end
    local iType = self:Target()
    local oTargetNpc = self:GetNpcObjByType(iType)
    self:Fight(self.m_Owner,oTargetNpc,iFight)
end

function CTask:StarPatrol()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if oPlayer then
        oPlayer:Send("GS2CStarPatrol",{taskid = self.m_ID})
    end
end

function CTask:SetGuideDesc(iIndex)
    self:Dirty()
    self.m_iGuideDesc = iIndex
    self:RefreshTaskInfo()
end

function CTask:SubmitTask()
    local npctype = self:Target()
    local oNpc = self:GetNpcObjByType(npctype)
        if not oNpc then
            return
        end
        local iMap = oNpc:MapId()
        local iX = oNpc.m_mPosInfo["x"]
        local iY = oNpc.m_mPosInfo["y"]
        local iNpcID = oNpc.m_ID
        local iTaskid = self.m_ID
        local func = function(oPlayer,mData)
            local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
            if not oTask then
                return
            end
            oTask:DoNpcEvent(self.m_Owner,oNpc.m_ID,"look")
        end
        local mData = {["iMapId"] = iMap,["iPosx"] = iX,["iPosy"] = iY,["iAutoType"] = 1}
        self:FindTaskPath(mData,func)
end

function CTask:StartTrace()
    if not self.m_mTraceInfo then
        return
    end
    self:Dirty()
    if extend.Table.find({gamedefines.TASK_TYPE.TASK_ESCORT},self:TaskType()) then
        local iNpcType = self.m_mTraceInfo.npctype
        for _,npcobj in pairs(self.m_mClientNpc) do
            if npcobj:Type() == iNpcType then
                self:RemoveClientNpc(npcobj)
                break
            end
        end
    end
    self.m_mTraceInfo["status"] = 1
    self:RefreshTaskInfo()
end

function CTask:StarEscort(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CStartEscort",{taskid = self.m_ID})
    end
end

function CTask:FindTaskPath(mData,func)
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(self.m_Owner,"AutoFindTaskPath",mData,nil,func)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    oPlayer:Send("GS2CFindTaskPath",{taskid = self.m_ID})
end
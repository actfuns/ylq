--import module

local global = require "global"
local extend = require "base.extend"
local taskobj = import(service_path("task/taskobj"))
local clientnpc = import(service_path("task/clientnpc"))
local gamedefines = import(lualib_path("public.gamedefines"))
local record = require "public.record"

local LILIAN_MONSTER_EVENT = 501

CTask = {}
CTask.__index = CTask
CTask.m_sName = "lilian"
CTask.m_sTempName = "历练任务"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self,taskid)
    o.m_Reward = {}
    return o
end

function CTask:CheckGrade(iGrade)
    local iDoneGrade = self:GetData("grade")
    if not iDoneGrade then
        return
    end
    local oWorldMgr = global.oWorldMgr
    if iGrade < iDoneGrade then
        return
    end
    local iPid = self.m_Owner
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    oPlayer.m_oTaskCtrl:MissionDone(self,iPid)
end

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end

function CTask:OnWarFail(oWar,pid,npcobj,mArgs)
    super(CTask).OnWarFail(self,oWar,pid,npcobj,mArgs)
end

function CTask:DoScript2(pid,npcobj,s,mArgs)
    super(CTask).DoScript2(self,pid,npcobj,s,mArgs)
    if string.sub(s,1,6) == "LILIAN" then
        self:StartLilian()
    elseif string.sub(s,1,7) == "LLFIGHT" then
        --通过NPC对话进入战斗
        self:StartLilianFight()
    end
end

function CTask:AssignToPlayer(iPid)
    if self:GetStatus() ~= gamedefines.TASK_STATUS.TASK_CANACCEPT then
        return
    end
    self:SetData("accepttime",get_time())
    self.m_Owner = iPid
    self:SetData("owner",iPid)
    self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_HASACCEPT,"达到20级获得历练任务")
    self:AfterAssign()
end

function CTask:RefreshLilianTimes(iNowTimes,mRewardTime)
    self:Dirty()
    local temp = self.m_mLilianInfo and self.m_mLilianInfo.rewardtime
    self.m_mLilianInfo = {["lefttime"] = iNowTimes,["max_time"] = 30,rewardtime=mRewardTime and mRewardTime or temp}
    self:RefreshTaskInfo()
end

function CTask:GetLilianInfo()
    return self.m_mLilianInfo or {}
end

function CTask:OnLogin()
    self:Dirty()
    self.m_mClientNpc = {}
end

function CTask:ClearMonsterNpc()
    self:Dirty()
    if self.m_mClientNpc and #self.m_mClientNpc > 0 then
        for _,oNpc in pairs(self.m_mClientNpc) do
            self:RemoveClientNpc(oNpc)
            self:RefreshTaskInfo()
        end
    end
end

function CTask:ConfigWar(oWar,pid,npcobj,iFight)
    oWar:SetData("LLV",self.m_iMonsterGrade)
    oWar:SetData("open_auto_skill",true)
end
--
function CTask:TransMonsterAble(oWar,sAttr,mArgs)
    mArgs = mArgs or {}
    local sValue = mArgs.value
    local mEnv = mArgs.env
    mEnv.LLV = oWar:GetData("LLV",25)
    local iValue = formula_string(sValue,mEnv)
    return iValue
end

function CTask:RefreshMonster(iMapId,iFight,iMonsterGrade)
    self:ClearMonsterNpc()
    local iMainMonster
    local mFightData = self:GetTollGateData(iFight)
    local iMainMonster = mFightData["monster"][1]["monsterid"]
    self.m_iFight = iFight
    self.m_iMonsterGrade = iMonsterGrade
    local oClientNpc = self:CreateClientNpc(iMainMonster,iMapId)
    oClientNpc:SetEvent(LILIAN_MONSTER_EVENT)
    self:RefreshTaskInfo()
end

function CTask:AutoFindLilianPath()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    local oTarget = self.m_mClientNpc[1]
    if not oTarget then
        return
    end
    local iTeamID = oPlayer:TeamID()
    local func = function(oPlayer,mData)
        if oPlayer:TeamID() and oPlayer:TeamID() == iTeamID then
            local oTask = oPlayer.m_oTaskCtrl:GetTask(500)
            local oNowTeam = oPlayer:TeamID()
            oTask:StartLilianFight()
        end
    end
    local oCbMgr = global.oCbMgr
    local mData = {["iMapId"] = oTarget.m_iMapid,["iPosx"] = oTarget.m_mPosInfo.x,["iPosy"] = oTarget.m_mPosInfo.y,["iAutoType"] = 1}
    oCbMgr:SetCallBack(self.m_Owner,"AutoFindTaskPath",mData,nil,func)
end

function CTask:GetFight()
    return {fight = self.m_iFight,monstergrade = self.m_iMonsterGrade}
end

function CTask:SynFightInfo(mFightInfo)
    self.m_iFight = mFightInfo.fight
    self.m_iMonsterGrade = mFightInfo.monstergrade
end

--同步队友的NPC到自己客户端
function CTask:SynClientNpc(oNpc)
    self:Dirty()
    local mArgs = {
        type = oNpc.m_iType,
        map_id = oNpc.m_iMapid,
        model_info = oNpc.m_mModel,
        pos_info = oNpc.m_mPosInfo,
        event = oNpc.m_iEvent,
        reuse = oNpc.m_iReUse,
        dialogId = oNpc.m_iDialog,
        sys_name = self.m_sName,
    }
    local oClientNpc = clientnpc.NewClientNpc(mArgs)
    table.insert(self.m_mClientNpc,oClientNpc)
    self:RefreshTaskInfo()
end

function CTask:GetLilianNpc()
    return self.m_mClientNpc[1]
end

function CTask:Save()
    local mData =  super(CTask).Save(self)
    mData["lilianinfo"] = self.m_mLilianInfo
    return mData
end

function CTask:PackTaskInfo()
    local mNet = super(CTask).PackTaskInfo(self)
    self.m_mLilianInfo = self.m_mLilianInfo or {}
    local mLilianInfo = {left_time = self.m_mLilianInfo.lefttime,max_time = self.m_mLilianInfo.max_time,reward_info = self.m_Reward}
    mNet["lilianinfo"] = mLilianInfo
    return mNet
end

function CTask:StartLilian()
    local oWorldMgr = global.oWorldMgr
    local oCbMgr = global.oCbMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if not oPlayer then
        return
    end
    local mDialog = self:GetDialogData(500)
    mDialog = mDialog[1]
    local sContent = self:TransString(self.m_Owner,nil,mDialog["content"])
    local mNet = {
        sContent = sContent,
        sConfirm = "开始修行",
        sCancle = "取消",
        default = 0,
        time = 0,
        uitype = 2,
    }
    mNet = oCbMgr:PackConfirmData(nil, mNet)
    local func = function(oPlayer,mData)
        if mData.answer and mData.answer == 1 then
            local oTask = oPlayer.m_oTaskCtrl:GetTask(500)
            oTask:_TrueStartLilian()
        end
    end
    oCbMgr:SetCallBack(self.m_Owner,"GS2CConfirmUI",mNet,nil,func)
end

function CTask:_TrueStartLilian()
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    local res = require "base.res"
    local mControlData = res["daobiao"]["global_control"]["lilian"]
    local iOpenSys = mControlData["is_open"] or "y"
    if iOpenSys ~= "y" then
        oNotifyMgr:Notify(self.m_Owner,"该功能正在维护，已临时关闭。请您留意官网相关信息。")
        return false
    end
    local iLeftTime = self.m_mLilianInfo.lefttime or 0
    if iLeftTime <= 0 then
        oNotifyMgr:Notify(self.m_Owner,"次数已用完，下次再来吧")
        return
    end
    if oPlayer:HasTeam() then
        oNotifyMgr:Notify(self.m_Owner,"请先退出组队")
        return
    elseif oPlayer.m_oActiveCtrl:GetNowWar() then
        return
    end
    local oTeamMgr = global.oTeamMgr
    oTeamMgr:AddLilianPlayer(self.m_Owner)
end

function CTask:StopLilian()
    self:ClearMonsterNpc()
    self.m_Reward = {}
    self:SyncRewardInfo()
end

function CTask:StartLilianFight()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    self.m_iTeamID = oPlayer:TeamID()
    local oTeam = nil
    if self.m_iTeamID then
        local oTeamMgr = global.oTeamMgr
        oTeam = oTeamMgr:GetTeam(self.m_iTeamID)
    end
    local sMem = oPlayer.m_iPid
    local iAveGrade = oPlayer:GetGrade()
    if oTeam then
        sMem = ConvertTblToStr(oTeam.m_lMember)
        iAveGrade = oTeam:GetTeamAveGrade()
        iAveGrade = (math.floor(iAveGrade/5) * 5) -10
    end
    self.m_iMonsterGrade = iAveGrade
    self:Fight(self.m_Owner,self.m_mClientNpc[1],self.m_iFight)
    record.user("lilian","enter_fight",{teammem=sMem,mem_grade=iAveGrade,monster_grade=self.m_iMonsterGrade or 0,fightid=self.m_iFight})
end

function CTask:Abandon()
    self:ClearMonsterNpc()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    local oTeam = oPlayer:HasTeam()
    oTeam:Leave(oPlayer.m_iPid)
end

function CTask:OnWarWin(oWar, iPid, npcobj, mArgs)
    local mFightData = self:GetTollGateData(self.m_iFight)
    local mReward = mFightData["rewardtbl"]
    for i = 1,#mReward do
        self:TeamReward(iPid,mReward[i]["rewardid"],mArgs)
    end
    self:PopWarRewardUI(oWar:GetWarId(),mArgs)
end

function CTask:TeamReward(iPid, sIdx, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local lPlayers = self:GetFightList(oPlayer,mArgs)
    for _,pid in ipairs(lPlayers) do
        self:Reward(pid, sIdx, mArgs)
        local oMem = oWorldMgr:GetOnlinePlayerByPid(pid)
        oMem.m_oTaskCtrl:DelLilianTimes(1,"战斗胜利消耗次数")
        global.oAchieveMgr:PushAchieve(pid,"每日修行次数",{value=1})
        oMem.m_oTaskCtrl:AddTeachTaskProgress(30014,1)
        local mReward = self:GetWarWinRewardUIData(oMem, mArgs)
        oMem.m_oTaskCtrl:AddLilianReward(mReward)
        oMem:AddSchedule("lilian")
        self:LogAnalyGame("lilian",oPlayer)
    end
end

function CTask:GetCreateWarArg(mArg)
    local mArg2 = table_copy(mArg)
    mArg2.war_type = gamedefines.WAR_TYPE.LILIAN_TYPE
    mArg2.remote_war_type = "lilian"
    return mArg2
end

function CTask:WarFightEnd(oWar,iPid,oNpc,mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local sMem = oPlayer.m_iPid
    local iAveGrade = oPlayer:GetGrade()
    local oTeamMgr = global.oTeamMgr
    local oTeam = nil
    if self.m_iTeamID then
        oTeam = oTeamMgr:GetTeam(self.m_iTeamID)
    end
    local iMonsterGrade = self.m_iMonsterGrade
    local iFight  = self.m_iFight
    if oTeam then
        oTeam:RemoveMemMonster()
        sMem = ConvertTblToStr(oTeam.m_lMember)
        iAveGrade = oTeam:GetTeamAveGrade()
    end
    super(CTask).WarFightEnd(self,oWar,iPid,oNpc,mArgs)
    if oTeam then
        oTeam:LilianFightEnd()
    end
    local win_side = mArgs.win_side
    record.user("lilian","fight_end",{teammem=sMem or "",mem_grade=iAveGrade,monster_grade=iMonsterGrade or 0,fightid=iFight or 0,result=(win_side == 1 and "胜利" or "失败")})
end

function CTask:Click(pid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    local oTeam = oPlayer:HasTeam()
    if oTeam and not (oTeam:IsLeader(pid) or oTeam:IsShortLeave(pid)) then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(pid,"您在队伍中，不能进行任务")
        return
    end
    local npctype = self:Target()
    local oNpc = self:GetNpcObjByType(npctype)
    if not oNpc then
        return
    end
    self:DoNpcEvent(self.m_Owner,oNpc.m_ID)
end

function CTask:AddLilianReward(mReward)
    if not self.m_Reward then
        self.m_Reward = {}
    end
    if not mReward or table_count(mReward) == 0 then
        return
    end
    local mItem = self.m_Reward["item"] or {}

    for _,info in pairs(mReward["player_item"]) do
        local bHasCombine = false
        for _,m in pairs(mItem) do
            if info["sid"] ==m["sid"] and info["virtual"] == m["virtual"] then
                m["amount"] = (m["amount"] or 0) + (info["amount"] or 0)
                bHasCombine = true
                break
            end
        end
        if not bHasCombine then
            table.insert(mItem,info)
        end
    end
    self.m_Reward["item"] = mItem

    local iExp = mReward["player_exp"] and mReward["player_exp"]["gain_exp"] or 0
    self.m_Reward["exp"] = (self.m_Reward["exp"] or 0) + iExp
    self:SyncRewardInfo()
end

function CTask:SyncRewardInfo()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if not oPlayer then
        return
    end
    if not self.m_Reward then
        self.m_Reward = {}
    end
    self:RefreshTaskInfo()
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
    local oTeam = oPlayer:HasTeam()
    if oTeam and oTeam.m_Type ~= gamedefines.TEAM_CREATE_TYPE.LILIAN and iTeamWork == 0 then
        return false,gamedefines.FIGHTFAIL_CODE.HASTEAM
    end
    return true
end

CLilianNpc = {}
CLilianNpc.__index = CLilianNpc
inherit(CLilianNpc, clientnpc.CClientNpc)

function NewLilianNpc(mArgs)
    local o = CLilianNpc:New(mArgs)
    return o
end

function CLilianNpc:New(mArgs)
    local o = super(CLilianNpc).New(self)
    o:Init(mArgs)
    return o
end

function CLilianNpc:SetEvent(iEvent)
    self.m_iEvent = iEvent
end

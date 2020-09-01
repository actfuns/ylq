--import module

local global = require "global"
local extend = require "base.extend"
local taskobj = import(service_path("task/teamtaskobj"))
local clientnpc = import(service_path("task/clientnpc"))
local gamedefines = import(lualib_path("public.gamedefines"))
local record = require "public.record"
local warobj = import(service_path("warobj"))

local TRAIN_TASK_ID = 502
local COMMON_REWARD = 1001
local TEAM_MEMCNT_LIMIT = 3

CTask = {}
CTask.__index = CTask
CTask.m_sName = "dailytrain"
CTask.m_sTempName = "每日修行"
inherit(CTask,taskobj.CTask)


function NewTask(mArgs)
    local o = CTask:New(mArgs)
    return o
end

function CTask:New( ... )
    local o = super(CTask).New(self)
    o.m_ID = TRAIN_TASK_ID
    o.m_mPlayer2Reward = {}
    o.m_iProgress = 0
    o.m_mCloseReward = {}
    o.m_mClientNpc = {}
    o.m_iRing = 0
    o.m_mAutoSkill = {}
    return o
end

--1：新增  2：归队   
function CTask:EnterTeam(iPid,iType)
    super(CTask).EnterTeam(self,iPid,iType)
    if self.m_mPlayer2Reward[iPid] then
        return
    end
    
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iGrade = global.oWorldMgr:QueryControl("dailytrain","open_grade")
    if oPlayer:GetGrade() < iGrade then
        return
    end
    self.m_mPlayer2Reward[iPid] = {}
    local mTrainInfo = oPlayer.m_oHuodongCtrl:PackTrainInfo()
    local iTrainRewardTime = mTrainInfo["reward_times"] or 0
    if iTrainRewardTime <= 0 then
        self.m_mCloseReward[iPid] = true
    end
    self:BrocastTaskInfo(iPid)
    if table_count(self.m_mClientNpc) > 0 then
        self:AutoFindPath()
    end
end

--1：离队  2：暂离
function CTask:LeaveTeam(iPid,iType)
    super(CTask).LeaveTeam(self,iPid,iType)
    if self.m_mAutoSkill and self.m_mAutoSkill[iPid] then
        self.m_mAutoSkill[iPid] = nil
    end
    if self.m_mPlayer2Reward[iPid] then
        self.m_mPlayer2Reward[iPid] = nil
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oPlayer then
            return
        end
        local oNpc = self.m_mClientNpc[1]
        if oNpc then
            local mNet = {}
            mNet["taskid"] = self.m_ID
            mNet["npcid"] = oNpc:ID()
            mNet["target"] = oNpc:Type()
            oPlayer:Send("GS2CRemoveTeamNpc",mNet)
        end
    end
end

function CTask:BrocastTaskInfo(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local mInfo = oPlayer.m_oHuodongCtrl:PackTrainInfo()
    mInfo["reward_info"] = self.m_mPlayer2Reward[iPid] or {}
    mInfo["clientnpc"] = self:PackMonsterInfo() or {}
    mInfo["ring"] = self.m_iRing
    mInfo["reward_siwtch"] = self.m_mCloseReward[iPid] and 1 or 0
    oPlayer:Send("GS2CTrainInfo",mInfo)
end

function CTask:StartTraning()
    local oTeam
    for iPid,_ in pairs(self.m_mPlayer2Reward) do
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        oTeam = oPlayer:HasTeam()
        break
    end
    if not oTeam then
        return
    end
    local iAveGrade = oTeam:GetTeamAveGrade()
    local iMonsterGrade = (math.floor(iAveGrade/5) * 5)
    if iMonsterGrade == 0 then
        iMonsterGrade = 25
    end
    local mFightData = self:GetTrainFgihtData()
    assert(mFightData[iMonsterGrade],string.format("RefreshMonster failed,MonsterGrade:%d",iMonsterGrade))
    local mGrade2Fight = mFightData[iMonsterGrade]["fightid"]
    assert(mGrade2Fight,string.format("RefreshMonster failed,MonsterGrade:%d",iMonsterGrade))
    local iFight = mGrade2Fight[math.random(#mGrade2Fight)]
    local res = require "base.res"
    local iGroupId = tonumber(res["daobiao"]["global"]["dailytrain_scene_group"]["value"])
    local iMapId = self:RamdomSceneId(iGroupId)
    self:RefreshMonster(iMapId,iFight,iMonsterGrade)
    self:AutoFindPath()
end

function CTask:RamdomSceneId(iGroupId)
    local res = require "base.res"
    local mMapList = {}
    if res["daobiao"]["scenegroup"][iGroupId] then
        mMapList = res["daobiao"]["scenegroup"][iGroupId]
    else
        return 101000
    end
    mMapList = mMapList["maplist"]
    return mMapList[math.random(#mMapList)]
end

function CTask:GetTrainFgihtData()
    local res = require "base.res"
    local mData = res["daobiao"]["task"]["dailytrain"]["fight"] or {}
    return mData
end

function CTask:PackMonsterInfo()
    local mClientData = {}
    for _,oClientNpc in pairs(self.m_mClientNpc) do
        table.insert(mClientData,oClientNpc:PackInfo())
    end
    return mClientData
end

function CTask:ClearMonsterNpc()
    self:Dirty()
    if self.m_mClientNpc and #self.m_mClientNpc > 0 then
        for _,oNpc in pairs(self.m_mClientNpc) do
            self:RemoveClientNpc(oNpc)
        end
    end
end

function CTask:RefreshMonster(iMapId,iFight,iMonsterGrade)
    self:ClearMonsterNpc()
    local iMainMonster
    local mFightData = self:GetTollGateData(iFight)
    local iMainMonster = mFightData["monster"][1]["monsterid"]
    self.m_iFight = iFight
    
    self.m_iMonsterGrade = iMonsterGrade
    local oClientNpc = self:CreateClientNpc(iMainMonster,iMapId)
    self:RefreshMonsterInfo()
end

function CTask:RefreshMonsterInfo()
    for iPid,_ in pairs(self.m_mTeamMem) do
        self:BrocastTaskInfo(iPid)
    end
end

function CTask:CheckCondition(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if not oTeam or not oTeam:IsLeader(oPlayer.m_iPid) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"请让队长来找我")
        return
    end
    if oTeam:MemberSize() < TEAM_MEMCNT_LIMIT then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"队伍人数不足，无法修行")
        return
    end
    local lMem = oTeam:GetTeamMember()
    local iGrade = global.oWorldMgr:QueryControl("dailytrain","open_grade")
    for _,pid in pairs(lMem) do
        local oMem = global.oWorldMgr:GetOnlinePlayerByPid(pid)
        if oMem:GetGrade() < iGrade then
            global.oNotifyMgr:Notify(oPlayer.m_iPid,string.format("%s等级不足",oMem:GetName()))
            return false
        end
    end
    return true
end

function CTask:AutoFindPath()
    local iTeam = self.m_iTeamId
    local oTeam = global.oTeamMgr:GetTeam(self.m_iTeamId)
    if not oTeam or oTeam:GetTargetID() ~= 1201 then
        return
    end
    local oTarget = self.m_mClientNpc[1]
    if not oTarget then
        return
    end
    local iLeader = oTeam:Leader()
    local oLeader = global.oWorldMgr:GetOnlinePlayerByPid(iLeader)
    local oNowScene = oLeader.m_oActiveCtrl:GetNowScene()
    if oNowScene:IsVirtual() then
        return
    end
    local func = function(oPlayer,mData)
        if oPlayer:TeamID() and oPlayer:TeamID() == iTeam then
            local oTeam = oPlayer:HasTeam()
            local oTask = oTeam:GetTeamTask(TRAIN_TASK_ID)
            if not oTask then
                return
            end
            if not oTask:CheckCondition(oPlayer) then
                return
            end
            oTask:StartFight(oPlayer.m_iPid)
        end
    end
    local oCbMgr = global.oCbMgr
    local mData = {["iMapId"] = oTarget.m_iMapid,["iPosx"] = oTarget.m_mPosInfo.x,["iPosy"] = oTarget.m_mPosInfo.y,["iAutoType"] = 1,["system"] = 1}
    oCbMgr:SetCallBack(iLeader,"AutoFindTaskPath",mData,nil,func)
end

function CTask:StartFight(iPid)
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(self.m_iTeamId)
    local iAveGrade = oTeam:GetTeamAveGrade()
    iAveGrade = (math.floor(iAveGrade/5) * 5)
    self.m_iMonsterGrade = iAveGrade
    self:Fight(iPid,self.m_mClientNpc[1],self.m_iFight)
    local sMem = ConvertTblToStr(oTeam.m_lMember)
    record.user("lilian","enter_fight",{teammem=sMem,mem_grade=iAveGrade,monster_grade=self.m_iMonsterGrade or 0,fightid=self.m_iFight})
end

function CTask:ContinueTraining()
    
    local oTeam = global.oTeamMgr:GetTeam(self.m_iTeamId)
    local iAveGrade = oTeam:GetTeamAveGrade()
    local iMonsterGrade = (math.floor(iAveGrade/5) * 5)
    if iMonsterGrade == 0 then
        iMonsterGrade = 25
    end
    local mFightData = self:GetTrainFgihtData()
    assert(mFightData[iMonsterGrade],string.format("RefreshMonster failed,MonsterGrade:%d",iMonsterGrade))
    local mGrade2Fight = mFightData[iMonsterGrade]["fightid"]
    assert(mGrade2Fight,string.format("RefreshMonster failed,MonsterGrade:%d",iMonsterGrade))
    local iFight = mGrade2Fight[math.random(#mGrade2Fight)]
    local res = require "base.res"
    local iGroupId = tonumber(res["daobiao"]["global"]["dailytrain_scene_group"]["value"])
    local iMapId = self:RamdomSceneId(iGroupId)
    self:RefreshMonster(iMapId,iFight,iMonsterGrade)
    if self:MemAmount() < TEAM_MEMCNT_LIMIT then
        self:BracastInfo("GS2CNotify",{cmd="队伍人数不足，无法修行"})
        return
    end
    local lMem = oTeam:GetTeamMember()
    local iGrade = global.oWorldMgr:QueryControl("dailytrain","open_grade")
    for _,pid in pairs(lMem) do
        local oMem = global.oWorldMgr:GetOnlinePlayerByPid(pid)
        if oMem:GetGrade() < iGrade then
            global.oNotifyMgr:Notify(iPid,string.format("%s等级不足",oMem:GetName()))
            return
        end
    end
    self:AutoFindPath()
end

function CTask:GetEventData()
    return {}
end

function CTask:DoScript(pid,npcobj,s,mArgs)
    
end

function CTask:OnWarWin(oWar, iPid, npcobj, mArgs)
    local mFightData = self:GetTollGateData(self.m_iFight)
    local mReward = mFightData["rewardtbl"]
    for i = 1,#mReward do
        self:TeamReward(iPid,mReward[i]["rewardid"],mArgs)
    end
    self:PopWarRewardUI(oWar:GetWarId(),mArgs)
    self.m_iRing = (self.m_iRing >= 10 and 0 or self.m_iRing) + 1
end

function CTask:TeamReward(iLeader, sIdx, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iLeader)
    if not oPlayer then
        return
    end
    local lPlayers = self:GetFightList(oPlayer,mArgs)
    mArgs["fight_amount"] = table_count(lPlayers)
    for _,pid in ipairs(lPlayers) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(pid)
        local iTrainRewardTime = oMem.m_oHuodongCtrl:GetTrainRewardTime()
        if iTrainRewardTime > 0 and not self.m_mCloseReward[pid] then
            oMem.m_oHuodongCtrl:DelTrainRewardTime(1,"战斗胜利")
            self:Reward(pid, sIdx, mArgs)
        else
            self:Reward(pid,COMMON_REWARD,mArgs)
        end
        self:LogAnalyGame("lilian",oPlayer)
        global.oAchieveMgr:PushAchieve(pid,"每日修行次数",{value=1})
        oMem:AddSchedule("lilian")
        local mReward = self:GetWarWinRewardUIData(oMem, mArgs)
        self:RecordReward(pid,mReward)

    end
end

function CTask:GetFightPartner(oPlayer,mArgs)
    return oPlayer.m_oPartnerCtrl:PackFightPartnerInfo()
end

function CTask:RecordReward(iPid,mReward)
    if not self.m_mPlayer2Reward[iPid] then
        self.m_mPlayer2Reward[iPid] = {}
    end
    if not mReward or table_count(mReward) == 0 then
        return
    end
    local mItem = self.m_mPlayer2Reward[iPid]["item"] or {}

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
    self.m_mPlayer2Reward[iPid]["item"] = mItem

    local iExp = mReward["player_exp"] and mReward["player_exp"]["gain_exp"] or 0
    self.m_mPlayer2Reward[iPid]["exp"] = (self.m_mPlayer2Reward[iPid]["exp"] or 0) + iExp
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

function CTask:WarFightEnd(oWar,iPid,oNpc,mArgs)
    super(CTask).WarFightEnd(self,oWar,iPid,oNpc,mArgs)
    local lPlayers = self:GetFightList(oPlayer,mArgs)
    for _,pid in ipairs(lPlayers) do
        local oMem = global.oWorldMgr:GetOnlinePlayerByPid(pid)
        local iTrainRewardTime = oMem.m_oHuodongCtrl:GetTrainRewardTime()
        if iTrainRewardTime <= 0 and not self.m_mCloseReward[pid] then
            self:SetSwitch(oMem,1)
        end
    end
    local oTeam = global.oTeamMgr:GetTeam(self.m_iTeamId)
    local sMem = oTeam and ConvertTblToStr(oTeam.m_lMember) or tostring(iPid)
    local win_side = mArgs.win_side
    local iAveGrade = oTeam:GetTeamAveGrade()
    local iMonsterGrade = self.m_iMonsterGrade
    local iFight  = self.m_iFight
    record.user("lilian","fight_end",{teammem=sMem or "",mem_grade=iAveGrade,monster_grade=iMonsterGrade or 0,fightid=iFight or 0,result=(win_side == 1 and "胜利" or "失败")})
    self:ContinueTraining()
end

function CTask:GetSelfCallback()
    local iTeamId = self.m_iTeamId
    local iTaskid = TRAIN_TASK_ID
    return function()
        local oTeam = global.oTeamMgr:GetTeam(iTeamId)
        if not oTeam then
            return
        end
        return oTeam:GetTeamTask(iTaskid)
    end
end

function CTask:TransReward(oRewardObj,sReward, mArgs)
    local oTeam = global.oTeamMgr:GetTeam(self.m_iTeamId)
    local iLeader = oTeam:Leader()
    local iIsCaptain = 0
    if oRewardObj and oRewardObj.m_iPid == iLeader and not self.m_mCloseReward[oRewardObj.m_iPid] and (mArgs["fight_amount"] and mArgs["fight_amount"] == 4 )then
        iIsCaptain = 1
    end
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local iServerGrade = oWorldMgr:GetServerGrade()
    local iLevel = oRewardObj and oRewardObj:GetGrade()
    if not iLevel then
        iLevel = mArgs.level
    end
    local mEnv = {
        lv = iLevel,
        SLV = iServerGrade,
        ring = self.m_iRing,
        iscaptain = iIsCaptain,
    }
    local iValue = formula_string(sReward,mEnv)
    return iValue
end


function CTask:ConfigWar(oWar,pid,npcobj,iFight)
    oWar:SetData("open_auto_skill",true)
end

function CTask:GetCreateWarArg(mArg)
    local mArg2 = table_copy(mArg)
    mArg2.war_type = gamedefines.WAR_TYPE.TRAIN_TYPE
    mArg2.remote_war_type = "dailytrain"
    return mArg2
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
        local mP = oSceneMgr:RandomMonsterPos(iMapId)
        x, y = table.unpack(mP[1] )
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
        team = self.m_iTeamId,
    }
    local oClientNpc = NewTrainNpc(mArgs)
    table.insert(self.m_mClientNpc,oClientNpc)
    self:Dirty()
    return oClientNpc
end

------iClose: 1-close    0-open
function CTask:SetSwitch(oPlayer,iClose)
    self.m_mCloseReward[oPlayer.m_iPid] = (iClose ==1)
    oPlayer:Send("GS2CTrainRewardSwitch",{close = iClose})
end

function CTask:OnLogin(oPlayer)
    if self.m_mTeamMem[oPlayer.m_iPid] then
        self:BrocastTaskInfo(oPlayer.m_iPid)
    end
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
    extend.Array.remove(self.m_mClientNpc,npcobj)
    local npcid = npcobj:ID()
    local oNpcMgr = global.oNpcMgr
    oNpcMgr:RemoveObject(npcid)
    baseobj_delay_release(npcobj)
end

function CTask:Release()
    self:ClearMonsterNpc()
    self:RefreshMonsterInfo()
    local oNpc = self.m_mClientNpc[1]
    if oNpc then
        local mNet = {}
        mNet["taskid"] = self.m_ID
        mNet["npcid"] = oNpc:ID()
        mNet["target"] = oNpc:Type()
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer:Send("GS2CRemoveTeamNpc",mNet)
    end
    self:BracastInfo("GS2CQuitTrain",{})
    super(CTask).Release(self)
end

function CTask:NewWar(mArgs)
    local oWarMgr = global.oWarMgr
    local id = oWarMgr:DispatchSceneId()
    local oWar = CMyWar:New(id, mArgs)
    oWar:ConfirmRemote()
    oWarMgr.m_mWars[id] = oWar
    return oWar
end

function CTask:SetAutoSkill(oPlayer,iSkill)
    self.m_mAutoSkill = self.m_mAutoSkill or {}
    self.m_mAutoSkill[oPlayer.m_iPid] = iSkill
end

function CTask:GetAutoSkill(oPlayer)
    return self.m_mAutoSkill and self.m_mAutoSkill[oPlayer.m_iPid]
end
-----------------------------------------
CTrainNpc = {}
CTrainNpc.__index = CTrainNpc
inherit(CTrainNpc, clientnpc.CClientNpc)

function NewTrainNpc(mArgs)
    local o = CTrainNpc:New(mArgs)
    o.m_iTeamId = mArgs["team"]
    return o
end

function CTrainNpc:New(mArgs)
    local o = super(CTrainNpc).New(self)
    o:Init(mArgs)
    return o
end

function CTrainNpc:do_look(oPlayer)
    
    local oTeam = oPlayer:HasTeam()
    if not oTeam or not (oTeam.m_ID == self.m_iTeamId) or not oTeam:IsLeader(oPlayer.m_iPid) then
        return
    end
    if self:InWar() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"正在战斗中")
        return
    end
    local oTask = oTeam:GetTeamTask(TRAIN_TASK_ID)
    if not oTask then
        return
    end
    if not oTask:CheckCondition(oPlayer) then
        return
    end
    oTask:StartFight(oPlayer.m_iPid)
end

CMyWar = {}
CMyWar.__index = CMyWar
inherit(CMyWar, warobj.CWar)

function CMyWar:PackPlayerWarInfo(oPlayer)
    local mRet = oPlayer:PackWarInfo()
    local oHuodong = global.oHuodongMgr:GetHuodong("dailytrain")
    if oHuodong then
        local oTeam = oPlayer:HasTeam()
        if not oTeam then
            return
        end
        local oTask = oTeam:GetTeamTask(TRAIN_TASK_ID)
        if not oTask then
            return
        end
        mRet.auto_skill = oTask:GetAutoSkill(oPlayer) or oHuodong:GetAutoSkill(oPlayer)
    end
    return mRet
end
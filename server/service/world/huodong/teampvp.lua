--import module
local skynet = require "skynet"
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"
local playersend = require "base.playersend"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local datactrl = import(lualib_path("public.datactrl"))

GAME_READY = 1
GAME_START = 2
GAME_OVER = 3
GAME_RELEASE = 4

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "协同战斗"
inherit(CHuodong, huodongbase.CHuodong)


function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_Status = GAME_RELEASE
    o.m_GameReadyStart = 0
    o.m_GameReadyEnd = 0
    o.m_PlayerUnit = {}
    o.m_Team = {}
    o.m_TeamIdx = 0
    o.m_HDSceneList = {}
    o.m_iScheduleID = 1021
    o.m_SceneLimit = 500
    o.m_GameReadyTimeOut = 50*60 * 1000
    o.m_GamePlayTimeOut = 60*60 * 1000
    o.m_GameReleaseTimeOut = 30*60*1000
    o.m_GameStartTimeOut = 10 * 60 * 1000
    return o
end


function CHuodong:InHuodongTime()
    return self.m_Status == GAME_START
end

function CHuodong:GetUnit(pid)
    return self.m_PlayerUnit[pid] or {}
end

function CHuodong:Score(pid)
    return self:GetUnit(pid)["score"] or 0
end

function CHuodong:SetUnit(pid,mData)
    self.m_PlayerUnit[pid] = mData
end

function CHuodong:RewardScore(oPlayer,iScore)
    local mData = self:GetUnit(oPlayer:GetPid())
    mData["score"] = (mData["score"] or 0) + iScore
    self:SetUnit(oPlayer:GetPid(),mData)
    return mData["score"]
end

function CHuodong:SetTeamUnit(oPlayer,key,val)
    local plist = self:PlayMember(oPlayer:GetPid())
    for _,pid in ipairs(plist) do
        local m = self:GetUnit(pid)
        m[key] = val
        self:SetUnit(pid,m)
    end
end

function CHuodong:GetMatchScore(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local plist = self:PlayMember(oPlayer:GetPid())
    local iMax = 0
    for _,pid in ipairs(plist) do
        local iScore = self:Score(pid)
        if iScore > iMax then
            iMax = iScore
        end
    end
    return iMax
end


function CHuodong:OnLogout(oPlayer)
    if not self:InHuodongTime() then
        return
    end
    if self:GetUnit(oPlayer:GetPid())["match_status"] then
        self:_CheckInMatch(oPlayer,1)
    end
end

function CHuodong:OnLogin(oPlayer,reenter)
    if self:InHDScene(oPlayer) then
        self:RefreshSceneInfo(self:PlayMember(oPlayer:GetPid()))
        if self:GetUnit(oPlayer:GetPid())["match_status"] then
            self:_CheckInMatch(oPlayer,1)
        end
        if not oPlayer:GetNowWar() then
            self:OpenMainRank(oPlayer)
        end
    end
    self:RefreshLeftTime(oPlayer)
end


function CHuodong:NewHour(iWeekDay, iHour)
    local mOpenDay = self:GetConfigValue("open_day")
    if table_in_list(mOpenDay,iWeekDay) then
        local iOpenHour = self:GetConfigValue("open_hour")
        if iOpenHour == iHour and self.m_Status == GAME_RELEASE then
            record.info("teampvp.TimeReady")
            self:DelTimeCb("GameCallOut")
            self:AddTimeCb("GameCallOut",self.m_GameReadyTimeOut,function()
                self:GameReady()
                end)
            self:CreateGateNpc()
        end
    end
end


function CHuodong:GameReady()
    if self.m_Status ~= GAME_RELEASE then
        return
    end
    self:DelTimeCb("GameCallOut")
    self:AddTimeCb("GameCallOut",self.m_GameStartTimeOut,function()
        self:GameStart()
        end)
    self.m_PlayerUnit = {}
    self.m_Team = {}
    self.m_Status = GAME_READY
    self.m_GameReadyStart = get_time() + 10*60
    self.m_GameReadyEnd = self.m_GameReadyStart + 3600


    interactive.Send(".rank","rank","CleanAllData",{rank_name="teampvp"})
    interactive.Send(".recommend","teampvp","ClearAllCache",{})
    self:RefreshLeftTime()
    record.info("teampvp.GameReady")
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(2001)
    oNotifyMgr:SendPrioritySysChat("teampvp_ready",sMsg,1)
    self:CreateRes()
end



function CHuodong:GameStart()
    if self.m_Status ~= GAME_READY then
        return
    end
    record.info("teampvp.GameStart")
    self:DelTimeCb("GameCallOut")
    self:AddTimeCb("GameCallOut",self.m_GamePlayTimeOut,function()
        self:GameOver()
        end)
    self.m_Status = GAME_START
    self:SendMatch("CleanCach",{})
    self:SendMatch("StartMatch",{data={time=500,limit=25}})
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(2002)
    oNotifyMgr:SendPrioritySysChat("teampvp_start",sMsg,1)
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_START)
end

function CHuodong:GameOver()
    if self.m_Status ~= GAME_START then
        return
    end
    record.info("teampvp.GameOver")
    self.m_Status = GAME_OVER
    self:DelTimeCb("GameCallOut")
    self:AddTimeCb("GameCallOut",self.m_GameReleaseTimeOut,function()
        self:GameRelease()
        end)
    self:SendMatch("CleanCach",{})
    self:SendMatch("StopMatch",{})
    self:RewardTopRank()
    self:CleanPlayer()
    local sMsg = self:GetTextData(2003)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    oNotifyMgr:SendPrioritySysChat("teampvp_end",sMsg,1)
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_OVER)
    for pid,m in pairs(self.m_PlayerUnit) do
        if m["match_status"] then
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
            if oPlayer then
                self:ClientStartMath(oPlayer,0)
                self:SetTeamUnit(oPlayer,"match_status",nil)
            end
        end
    end
    self:RemoveGateNpc()
end

function CHuodong:GameRelease()
    self.m_Status = GAME_RELEASE
    record.info("teampvp.GameRelease")
    self:CleanRes()
end


function CHuodong:CreateRes()
    local oWorldMgr = global.oWorldMgr
    self.m_HDSceneList = {}
    local fscene = function ()
        local oScene= self:CreateVirtualScene(1001)
        oScene.m_NoTransfer = 1
        oScene.m_HuoDong = self.m_sTempName
        oScene:SetLimitRule("transfer",1)
        oScene:SetLimitRule("team",1)
        table.insert(self.m_HDSceneList,oScene:GetSceneId())
        local fproxy = function (sName)
                local f = function(...)
                    local hf = self[sName]
                    assert(type(hf)=="function")
                    return hf(self,...)
                end
            return f
        end
        oScene.m_OnLeave = fproxy("OnLeaveScene")
        oScene.m_OnEnter = fproxy("OnEnerScene")
        local npcobj = self:CreateTempNpc(1001)
        local mPosInfo = npcobj:PosInfo()
        self:Npc_Enter_Scene(npcobj,oScene:GetSceneId(),mPosInfo)
    end

    local iCnt = math.max(1,table_count(oWorldMgr:GetOnlinePlayerList())/self.m_SceneLimit)
    for i=1,iCnt do
        fscene()
    end
end



function CHuodong:CleanRes()
    for _,iSc in ipairs(self.m_HDSceneList) do
        self:RemoveSceneById(iSc)
    end
    self.m_HDSceneList = {}
    self:RemoveTempNpcByType(1001)
    self.m_PlayerUnit = {}
    self.m_Team = {}
    self.m_RewardPlist = nil
    self.m_ExculeList = nil
    interactive.Send(".recommend","teampvp","ClearAllCache",{})
end

function CHuodong:InHDScene(oPlayer)
    local iScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    return table_in_list(self.m_HDSceneList,iScene)
end

function CHuodong:RewardTopRank()
    local mRequest = {
        data = {pid=0,limit=50},
        rank_name = "teampvp",
        respond = 1,
        }
    interactive.Request(".rank","rank","GetExtraRankData",mRequest,function(mRecord,mData)
            self:RewardTop50(mData.data)
        end)
end

function CHuodong:RewardTop50(mData)
    local mRank = mData.rank
    local iLastRank = 0
    local iLastScore = 0
    local mExcludeList = {}
    for _,m in ipairs(mRank) do
        if m.score ~= iLastScore then
            iLastRank = m.rank
            iLastScore = m.score
        end
        mExcludeList[m.pid] = iLastRank
        self:RewardRank(m.pid,iLastRank)
    end
    self.m_ExculeList = mExcludeList
    self.m_RewardPlist = table_key_list(self.m_PlayerUnit)
    self:AddTimeCb("reward_rank",500,function ()
        self:RewardOnlinePlayer()
        end)
end

function CHuodong:RewardRank(pid,iRank)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["rank"]
    local oMailMgr = global.oMailMgr
    local mRewardList
    local iReward = 999
    if iRank <= 50 then
        for idx,m in pairs(mData) do
            local mR = m["range"]
            if mR["min"] <= iRank and iRank <=mR["max"] then
                iReward = idx
                break
            end
        end
    end
    local mLog = {
            pid = pid,
            rank = iRank,
            score = self:Score(pid),
        }
    record.user("teampvp","reward_rank",mLog)

    local mRewardList = mData[iReward]["reward_list"]
    local info
    if iReward == 999 then
        info = oMailMgr:GetMailInfo(58)
    else
        info = table_deep_copy(oMailMgr:GetMailInfo(57))
        info.context = string.gsub(info.context,"$rank",iRank)
    end
    self:RewardListByMail(pid,mRewardList,{mailinfo=info})

end

function CHuodong:RewardOnlinePlayer()
    self:DelTimeCb("reward_rank")
    if not self.m_RewardPlist or #self.m_RewardPlist == 0 then
        return
    end
    self:AddTimeCb("reward_rank",1000,function ()
        self:RewardOnlinePlayer()
        end)
    for i=1,100 do
        local pid = table.remove(self.m_RewardPlist,1)
        if not pid then
            return
        end
        if not self.m_ExculeList[pid] then
            local m = self:GetUnit(pid)
            if m["join"] then
                self:RewardRank(pid,999)
            end
        end
    end
end

function CHuodong:CleanPlayer()
    local oWorldMgr = global.oWorldMgr
    local fClean = function (iSc)
        local oScene = self:GetHDScene(iSc)
        if not oScene then
            return
        end
        local plist = oScene:GetPlayers()

        for _,pid in ipairs(plist) do
            local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
            if pobj and pobj.m_oActiveCtrl:GetNowSceneID() == iSc then
                if not pobj:GetNowWar() then
                    self:_CheckInMatch(pobj,1)
                    self:LeaveScene(pobj)
                end
            end
        end
    end
    for _,iSc in ipairs(self.m_HDSceneList) do
        fClean(iSc)
    end

end

function CHuodong:NewTeam()
    self.m_TeamIdx = self.m_TeamIdx + 1
    local o = NewTeam(self.m_TeamIdx)
    self.m_Team[o.m_ID] = o
    return o
end

function CHuodong:RemoveTeam(iTeam)
    local oTeam = self.m_Team[iTeam]
    if oTeam then
        baseobj_safe_release(oTeam)
    end
end

function CHuodong:GetTeam(oPlayer)
    local iTeam = self:GetUnit(oPlayer:GetPid())["team"]
    if not iTeam then
        return
    end
    return self.m_Team[iTeam]
end

function CHuodong:IsTeamLeader(oPlayer)
    local oTeam = self:GetTeam(oPlayer)
    if not oTeam then
        return true
    end
    return oTeam:Leader() == oPlayer:GetPid()
end

function CHuodong:BuildTeam(pid1,pid2)
    local oTeam = self:NewTeam()
    oTeam:Add(pid1)
    oTeam:Add(pid2)
    local oPlayer1 = global.oWorldMgr:GetOnlinePlayerByPid(pid1)
    local oPlayer2 = global.oWorldMgr:GetOnlinePlayerByPid(pid2)
    self:RegisterChannel(oPlayer1,oTeam.m_ID)
    self:RegisterChannel(oPlayer2,oTeam.m_ID)
    self:RefreshSceneInfo(oTeam:Member())
    self:RemoveCollection(pid1)
    self:RemoveCollection(pid2)
end

function CHuodong:PlayMember(pid)
    local m = self:GetUnit(pid)
    local iTeam = m["team"]
    if not iTeam then
        return {pid,}
    end
    local oTeam = self.m_Team[iTeam]
    if not oTeam then
        record.warning(string.format("teampvp has null team %s ",pid))
        return {pid,}
    end
    return oTeam:Member()
end

function CHuodong:RemoveCollection(pid)
    interactive.Send(".recommend","teampvp","UpdateRoleInfo",{pid=pid,info={rm=1}})
end

function CHuodong:AddCollection(oPlayer)
    local iPid = oPlayer:GetPid()
    local m = {
        name = oPlayer:GetName(),
        score = self:Score(iPid),
        shape=oPlayer:GetModelInfo().shape,
        grade = oPlayer:GetGrade(),
        pid = iPid,
        org = oPlayer:GetOrgID(),
        fight = 0,
            }
    interactive.Send(".recommend","teampvp","UpdateRoleInfo",{pid=iPid,info={data=m}})

end

function CHuodong:SetLeader(oPlayer,iTarget)
    local oTeam = self:GetTeam(oPlayer)
    if not oTeam or oTeam:Leader() ~= oPlayer:GetPid() then
        return
    end
    if not oTeam:InTeam(iTarget) then
        return
    end
    oTeam:SetLeader(iTarget)
    self:RefreshSceneInfo(oTeam:Member())
end

function CHuodong:LeaveTeam(oPlayer)
    local oTeam = self:GetTeam(oPlayer)
    if not oTeam then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local plist = self:PlayMember(oPlayer:GetPid())
    local iTeamId = oTeam.m_ID
    oTeam:Remove(oPlayer:GetPid())
    self:RemoveTeam(oTeam.m_ID)
    for _,pid in ipairs(plist) do
        self:RefreshSceneInfo({pid})
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        self:UnRegisterChannel(pobj,iTeamId)
        if pobj then
            self:AddCollection(pobj)
        end
    end
end

function CHuodong:KickoutTeam(oPlayer,iTarget)
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        return
    end
    local oT1 = self:GetTeam(oPlayer)
    local oT2 = self:GetTeam(oTarget)
    if not ( oT1 and oT2 ) then
        return
    end
    if oT1.m_ID ~= oT2.m_ID then
        return
    end
    if not self:IsTeamLeader(oPlayer) then
        return
    end
    self:LeaveTeam(oTarget)
end



function CHuodong:RefreshLeftTime(oPlayer)
    if not table_in_list({GAME_READY,GAME_START},self.m_Status) then
        return
    end
    local mNet = {start_time=self.m_GameReadyStart,end_time=self.m_GameReadyEnd}
    if oPlayer then
        oPlayer:Send("GS2CRefreshTeamArenaLeftTime",mNet)
    else
        local mData = {
            message = "GS2CRefreshTeamArenaLeftTime",
            type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
            id = 1,
            data = mNet,
            exclude = {}
        }
        interactive.Send(".broadcast","channel","SendChannel",mData)
    end
end

function CHuodong:LookNpc(oPlayer,npcobj)
    local sErr = self:ValidEnterScene(oPlayer)
    if sErr then
        if npcobj then
            npcobj:Say(oPlayer:GetPid(),sErr)
        else
            global.oNotifyMgr:Notify(oPlayer:GetPid(),sErr)
        end
        return
    end
    self:GS2CDialog(oPlayer:GetPid(),npcobj,100,function (oPlayer,mArgs)
                local sErr = self:ValidEnterScene(oPlayer)
                if not sErr then
                    self:EnterScene(oPlayer)
                end
        end)
end

function CHuodong:GetDialogInfo(iDialog)
    local mData = self:GetDialogBaseData()
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CHuodong:GetDialogBaseData()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["dialog"]
    assert(mData,string.format("Not Dialog Config:%s",self.m_sName))
    return mData
end


function CHuodong:GS2CDialog(iPid,oNpc,iDialog,func)
    local mDialogInfo = self:GetDialogInfo(iDialog)
    if not mDialogInfo then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local m = {}
    m["dialog"] = {{
        ["type"] = mDialogInfo["type"],
        ["pre_id_list"] = mDialogInfo["pre_id_list"],
        ["content"] = mDialogInfo["content"],
        ["voice"] = mDialogInfo["voice"],
        ["last_action"] = mDialogInfo["last_action"],
        ["next"] = mDialogInfo["next"],
        ["ui_mode"] = mDialogInfo["ui_mode"],
        ["status"] = mDialogInfo["status"],
    }}
    m["dialog_id"] = iDialog
    m["npc_id"] = oNpc.m_ID
    m["npc_name"] = oNpc:Name()
    m["shape"] = oNpc:Shape()

    local func = function(oPlayer,mArgs)
        if mArgs.answer and mArgs.answer == 1 then
                func(oPlayer,mArgs)
        end
    end
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(iPid,"GS2CDialog",m,nil,func)
end

function CHuodong:do_look(oPlayer, npcobj)
    if npcobj:Type() == 1002 then
        self:LookNpc(oPlayer,npcobj)
        return
    end
    self:GS2CDialog(oPlayer:GetPid(),npcobj,101,function (oPlayer,mArgs)
                self:LeaveScene(oPlayer)
        end)
end

function CHuodong:CreateGateNpc()
    local oGate = self:CreateTempNpc(1002)
    self:Npc_Enter_Map(oGate,101000,oGate:PosInfo())
end

function CHuodong:RemoveGateNpc()
    for iNpcId,npc in pairs(self.m_mNpcList) do
        if npc:Type() == 1002 then
            self.m_mNpcList[iNpcId] = nil
            global.oNpcMgr:RemoveSceneNpc(iNpcId)
        end
    end
end

function CHuodong:EnterScene(oPlayer)
    if table_in_list({GAME_RELEASE,GAME_OVER,},self.m_Status) then
        return
    end
    local iSc = extend.Random.random_choice(self.m_HDSceneList)
    local oSceneMgr = global.oSceneMgr
    local mScene = self:GetHDScene(iSc)
    local iMapId = mScene:MapId()
    local mPos = oSceneMgr:RandomMonsterPos(iMapId,1)[1]
    self:TransferPlayerBySceneID(oPlayer:GetPid(),iSc,mPos[1],mPos[2])
end

function CHuodong:FindLeavePath(oPlayer)
    if not self:InHDScene(oPlayer) then
        return
    end
    local npcid = 0
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    for nid,_ in pairs(oScene:NpcList()) do
        npcid = nid
        break
    end
    local npcobj = self:GetNpcObj(npcid)
    if not npcobj then
        return
    end

    local oSceneMgr = global.oSceneMgr
    local mPos = npcobj:PosInfo()
    oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),npcobj.m_iMapid,mPos.x,mPos.y,npcobj.m_ID,1,1)
end

function CHuodong:LeaveScene(oPlayer)
    local iScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    if self:InHDScene(oPlayer) then
        self:GobackRealScene(oPlayer:GetPid())
    end
end

function CHuodong:ValidEnterScene(oPlayer)
    local oWorldMgr = global.oWorldMgr
    if not table_in_list({GAME_READY,GAME_START},self.m_Status) then
        return self:GetTextData(1005)
    end

    local oTeam = oPlayer:HasTeam()
    local iLimitGrade  = oWorldMgr:QueryControl("teampvp","open_grade")
    local plist = oPlayer:AllMember()
    if oTeam then
        if oTeam:MemberSize() > 2 then
            return self:GetTextData(1008)
        end
        if oTeam:HasShortLeave() then
            return "有队员暂离,不能进入"
        end
    end
    for _,pid in ipairs(plist) do
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        if pobj then
            if pobj:GetGrade() <iLimitGrade then
                return string.gsub(self:GetTextData(1009),"username",pobj:GetName())
            end
            if pobj.m_oToday:Query("teampvp_fail",0) >= self:GetConfigValue("fail_limit") then
                return string.gsub(self:GetTextData(1011),"username", pobj:GetName())
            end
        end
    end
end

function CHuodong:ClientStartMath(oPlayer,iResult)
    local oWorldMgr = global.oWorldMgr
    local plist = self:PlayMember(oPlayer:GetPid())
    for _,pid in ipairs(plist) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            oPlayer:Send("GS2CTeamPVPStartMath",{result=iResult,start_time=get_time()})
        end
    end
end

--Match Game

function CHuodong:SendMatch(sFun,mData,backfunc)
    mData.name = "teampvp"
    if not backfunc then
        interactive.Send(".recommend","match",sFun,mData)
    else
        mData.respond = 1
        interactive.Request(".recommend","match",sFun,mData,backfunc)
    end
end


function CHuodong:LeaveMatch(oPlayer)
    self:_CheckInMatch(oPlayer,1)
end

function CHuodong:EnterMatch(oPlayer)
    if not self:ValidEnterMatch(oPlayer) then
        self:ClientStartMath(oPlayer,0)
        return
    end
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local iScore = self:GetMatchScore(oPlayer)
    local mMember = self:PlayMember(pid)
    self:SetTeamUnit(oPlayer,"match_status",get_second())
    self:SendMatch("EnterMatch",{id=oPlayer:GetPid(),data={score =iScore,mem = mMember,size=table_count(mMember)}})
    self:ClientStartMath(oPlayer,1)
end


function CHuodong:_CheckInMatch(oPlayer,iLeave,sNotify)
    local oNotify = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local plist = self:PlayMember(oPlayer:GetPid())
    local oTeam = self:GetTeam(oPlayer)
    if iLeave == 1 then
        for _,pid in ipairs(plist) do
            self:SendMatch("LeaveMatch",{id=pid})
        end
        self:ClientStartMath(oPlayer,0)
        self:SetTeamUnit(oPlayer,"match_status",nil)
    end
    if sNotify and sNotify~="" then
        for _,pid in ipairs(plist) do
            oNotify:Notify(pid,sNotify)
        end
    end
end

function  CHuodong:RegisterChannel(oPlayer,iTeamId)
    local mRole = {
        pid = oPlayer:GetPid(),
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.TEAMPVP_TYPE, iTeamId, true},
        },
        info = mRole,
    })
end

function CHuodong:UnRegisterChannel(oPlayer,iTeamId)
    local mRole = {
        pid = oPlayer:GetPid(),
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.TEAMPVP_TYPE, iTeamId, false},
        },
        info = mRole,
    })
end

function CHuodong:ValidEnterMatch(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iGrade = oWorldMgr:QueryControl("teampvp","open_grade")
    local iPid = oPlayer:GetPid()
    local mUnit = self:GetUnit(iPid)

    if not self:InHuodongTime() then
        oNotifyMgr:Notify(iPid,self:GetTextData(1030))
        return false
    elseif oWorldMgr:IsClose("teampvp") then
        oNotifyMgr:Notify(iPid,self:GetTextData(1019))
        return false
    elseif oPlayer:GetGrade()< iGrade then
        oNotifyMgr:Notify(iPid,self:GetTextData(1002))
        return false
    elseif mUnit["match_status"] then
        return false
    elseif not self:InHDScene(oPlayer) then
        oNotifyMgr:Notify(iPid,self:GetTextData(1022))
        return false
    elseif table_count(oPlayer.m_oPartnerCtrl:GetFightPartner()) < 2 then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1031))
        return false
    end
    if not self:IsTeamLeader(oPlayer) then
        oNotifyMgr:Notify(iPid,self:GetTextData(1029))
        return false
    end
    local plist = self:PlayMember(oPlayer:GetPid())
    if #plist > 2 then
        return false
    end
    for _,pid in ipairs(plist) do
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        if not pobj then
            return false
        end
        if pobj:GetNowWar() then
            oNotifyMgr:Notify(iPid,self:GetTextData(1028))
            return false
        elseif table_count(pobj.m_oPartnerCtrl:GetFightPartner()) < 2 then
            local sText = self:GetTextData(1032)
            sText = string.gsub(sText,"username",pobj:GetName())
            oNotifyMgr:Notify(iPid,sText)
            return false
        end

    end
    return true
end



function CHuodong:MatchResult(fightlist,mInfo)
    local oWorldMgr = global.oWorldMgr
    local oNotify = global.oNotifyMgr
    local oWarMgr = global.oWarMgr
    local f = function (plist)
        for _,pid in ipairs(plist) do
            local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
            if pobj then
                self:_CheckInMatch(pobj,1)
                oNotify:Notify(pid,"匹配错误,请重新进入匹配")
            end
        end
    end

    for _,mFight in pairs(fightlist) do
        local plist1= mFight[1]
        local plist2 = mFight[2]
        self:ReadyPVPWar(plist1,plist2)
    end

end




function CHuodong:ReadyPVPWar(plist1,plist2)
    local oWorldMgr = global.oWorldMgr
    local oNotify = global.oNotifyMgr
    local oWarMgr = global.oWarMgr

    local bStartFight = self:ValidEnterWar(plist1,plist2)
    local iTarget1 = plist1[1]
    local oTarget1 = oWorldMgr:GetOnlinePlayerByPid(iTarget1)
    local iTarget2 = plist2[1]
    local oTarget2 = oWorldMgr:GetOnlinePlayerByPid(iTarget2)
    if not bStartFight then
        if oTarget1 then self:ClientStartMath(oTarget1,0) end
        if oTarget2 then self:ClientStartMath(oTarget2,0) end
        return
    end

    for _,pid in ipairs(plist1) do
        local m = self:GetUnit(pid)
        m["match_status"] = nil
        m["join"] = (m["join"] or 0) + 1
        self:SetUnit(pid,m)
    end

    for _,pid in ipairs(plist2) do
        local m = self:GetUnit(pid)
        m["match_status"] = nil
        m["join"] = (m["join"] or 0) + 1
        self:SetUnit(pid,m)
    end

    self:_CheckInMatch(oTarget1,0)
    self:_CheckInMatch(oTarget2,0)

    local fPack = function (plist)
        local mPack = {}
        for _,pid in ipairs(plist) do
            local obj = oWorldMgr:GetOnlinePlayerByPid(pid)
            if obj then
                local m ={
                pid = obj:GetPid(),
                name = obj:GetName(),
                score = self:Score(pid),
                shape = obj:GetModelInfo().shape,
                grade = obj:GetGrade(),
                }
                table.insert(mPack,m)
            end
        end
        return mPack
    end

    local mNet = {
        info1 = fPack(plist1),
        info2 = fPack(plist2),
        }
    local sPack  = playersend.PackData("GS2CTeamPVPMatch",mNet)
    self:SetTeamUnit(oTarget1,"game_status",{target=plist2,pack=sPack})
    self:SetTeamUnit(oTarget2,"game_status",{target=plist2,pack=sPack})
    self:DelTimeCb(sKey)
    local sKey = string.format("ReadyStartWar_%d_%d",plist1[1],plist2[1])
    self:AddTimeCb(sKey,3*1000,function()
        self:TimeOutStartWar(plist1,plist2)
        end)
    local l = {}
    list_combine(l,plist1)
    list_combine(l,plist2)
    for _,pid in ipairs(l) do
        local obj = oWorldMgr:GetOnlinePlayerByPid(pid)
        if obj then
            obj:SendRaw(sPack)
        end
    end
end

function CHuodong:TimeOutStartWar(plist1,plist2)
    local sKey = string.format("ReadyStartWar_%d_%d",plist1[1],plist2[1])
    self:DelTimeCb(sKey)
    if not self:InHuodongTime() then
        return
    end
    if not self:ValidEnterWar(plist1,plist2) then
        return false
    end
    self:StartPVPWar(plist1,plist2)
end

function CHuodong:ValidEnterWar(plist1,plist2)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iPid = plist1[1]
    local iTarget = plist2[2]
    if not self:InHuodongTime() then
        return false
    elseif oWorldMgr:IsClose("teampvp") then
        local msg = self:GetTextData(1019)
        oNotifyMgr:Notify(iPid,msg)
        oNotifyMgr:Notify(iTarget,msg)
        return false
    end

    local fwar = function (plist)
        for _,pid in ipairs(plist) do
            local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
            if not pobj then
                return false
            end
            if pobj:GetNowWar() then
                return false
            end
        end
        return true
    end

    if not fwar(plist1) then
         oNotifyMgr:Notify(iTarget,self:GetTextData(1023))
         return false
    end

    if not fwar(plist2) then
         oNotifyMgr:Notify(iPid,self:GetTextData(1023))
         return false
    end

    return true
end



function CHuodong:StartPVPWar(plist1,plist2)
    local oWorldMgr = global.oWorldMgr
    local oNotify = global.oNotifyMgr
    local oWarMgr = global.oWarMgr
    local iPid = plist1[1]
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iTarget = plist2[1]
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    local mArg = {
        remote_war_type="teampvp",
        war_type = gamedefines.WAR_TYPE.TEAM_PVP,
        remote_args = { },
        pvpflag = 1,
        }


    local mConfig = {}
    local plist = {}
    list_combine(plist,plist1)
    list_combine(plist,plist2)
    local mLog = {}

    for i,pid in ipairs(plist) do
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        local k1 = string.format("pid%d",i)
        local k2 = string.format("info%d",i)
        if pobj then
            mLog[string.format("pid%d",i)] = pid
            mLog[string.format("info%d",i)] = ConvertTblToStr({
                score = self:Score(pid),
                name=oPlayer:GetName(),
                win= oPlayer.m_oToday:Query("teampvp_win",0),
                fail = oPlayer.m_oToday:Query("teampvp_fail",0),
                combo = oPlayer.m_oToday:Query("teampvp_combo",0),
                count = oPlayer.m_oToday:Query("teampvp_join",0),
                day_medal = oPlayer.m_oToday:Query("tampvp_medal",0),
                })
            pobj:AddSchedule("teampvp")
        end
        mConfig[pid] = {score=self:Score(pid)}
    end

    record.user("teampvp","start_pvp",mLog)


    local oWar = oWarMgr:CreateWar(mArg)
    local iWarID = oWar:GetWarId()
    oWar:SetData("close_auto_skill",true)
    oWar.m_fPackFightPartner = function (oWar,oPlayer,mPlayer)
        local mData = {}
        for _,oMemPlayer in ipairs(mPlayer) do
            local mFightPartner = oMemPlayer:GetFightPartner()
            for iPos=2,4 do
                local oPartner = mFightPartner[iPos]
                if oPartner then
                    local mPartnerList = {}
                    local mPartnerData = {
                        partnerdata = oPartner:PackWarInfo(),
                    }
                    table.insert(mPartnerList,mPartnerData)
                    table.insert(mData,{id=oMemPlayer:GetPid(),data=mPartnerList})
                    break
                end
            end
        end
        return mData
    end

    oWarMgr:TeamEnterWar(oPlayer,oWar:GetWarId(),{camp_id=1,team_list=plist1,},true)
    oWarMgr:TeamEnterWar(oTarget,oWar:GetWarId(),{camp_id=2,team_list=plist2,},true)

    oWarMgr:SetEscapeCallBack(iWarID,function (mInfo)
            self:OnEscape(plist1,plist2,mConfig,mInfo)
        end)
    oWarMgr:SetWarEndCallback(oWar:GetWarId(),function (mArg)
            local oWar = oWarMgr:GetWar(iWarID)
            self:OnPVPWarEnd(oWar,plist1,plist2,mConfig,mArg)
        end)

    oWarMgr:StartWarConfig(iWarID,{})
end


function CHuodong:OnPVPWarEnd(oWar,plist1,plist2,mConfig,mArg)
    local oWorldMgr = global.oWorldMgr
    local winlist = plist1
    local loserlist = plist2
    if mArg.win_side == 2 then
        winlist = plist2
        loserlist = plist1
    end
    local iWin = winlist[1]
    local iLoser = loserlist[1]
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iWin)
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iLoser)
    if oPlayer and oTarget then
        local iCombo = oTarget.m_oToday:Query("teampvp_combo",0)
        if iCombo >= 5 then
            local sMsg = self:GetTextData(1025)
            sMsg = string.gsub(sMsg,"username",oPlayer:GetName())
            sMsg = string.gsub(sMsg,"targetname",oTarget:GetName())
            sMsg = string.gsub(sMsg,"wincnt",iCombo)
            global.oNotifyMgr:SendPrioritySysChat("huodong_char",sMsg,1)
        end
    end
    self:RewardEndWar(oWar,winlist,loserlist,true,mConfig,mArg)
    self:RewardEndWar(oWar,loserlist,winlist,false,mConfig,mArg)

    local plist = {}
    list_combine(plist,plist1)
    list_combine(plist,plist2)
    for _,pid in ipairs(plist) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer and self:InHDScene(oPlayer) then
            if not self:InHuodongTime() then
                self:LeaveScene(oPlayer)
            else
                self:OpenMainRank(oPlayer)
            end
        end
    end
end

function CHuodong:OnEscape(plist1,plist2,mConfig,mInfo)
    local pid = mInfo.pid
    local oWarMgr = global.oWarMgr
    local oWorldMgr = global.oWorldMgr
    local oWar = oWarMgr:GetWar(mInfo.war_id)
    local winlist = table_in_list(plist1,pid) and plist1 or plist2
    if oWar then
        global.oNotifyMgr:Notify(pid,self:GetTextData(1026))
        self:RewardEndWar(oWar,{pid,},winlist,false,mConfig,{escape=1,no_show = 1,show_end=mInfo["show_end"],win_side=mInfo["win_side"]})
    end
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        self:OpenMainRank(oPlayer)
    end
end

function CHuodong:RewardEndWar(oWar,plist,targetlist,bwin,mConfig,mArg)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local res = require "base.res"
    local mScore = self:GetConfigValue("reward_score")
    local iLeader = plist[1]
    local mWarArg = mArg["show_end"] or {}
    local iWinSide = mArg["win_side"]
    local mEscapeList = {}

    for iCamp ,elist in pairs(mArg["escape_list"] or {}) do
        extend.Array.append(mEscapeList,elist)
    end
    for _,pid in pairs(plist) do
        local mLog = {}
        mLog["pid"] = pid
        mLog["medal"] = 0
        mLog["cur_score"]  = self:Score(pid)
        mLog["win"] = 0
        mLog["add_score"] = 0
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer and not table_in_list(mEscapeList,pid)  then
            self:SetTeamUnit(oPlayer,"match_status",nil)
            oPlayer:AddSchedule("teampvp")
            oPlayer.m_oToday:Add("teampvp_join",1)
            local iScore = 0
            local iCur = self:Score(pid)
            mLog["medal"]  = self:RewardArenaMedal(oPlayer,bwin)
            mLog["name"] = oPlayer:GetName()
            if bwin then
                oPlayer.m_oToday:Add("teampvp_win",1)
                oPlayer.m_oToday:Add("teampvp_combo",1)
                global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"协同比武场胜利场数",{value=1})
                mLog["win"] = 1
                local iCombo = oPlayer.m_oToday:Query("teampvp_combo",0)
                local mReward = self:GetRewardConfig(oPlayer,true)
                local iMaxCombo = oPlayer.m_oToday:Query("tpvp_combo_max",0)
                oPlayer.m_oToday:Set("tpvp_combo_max",math.max(iMaxCombo,iCombo))
                for _,iReward in ipairs(mReward["reward"]) do
                    if iLeader == pid and #mReward["chat"] > 0  and table_in_list({3001,3002,3003},iReward) then
                        local iText = extend.Random.random_choice(mReward["chat"])
                        if iText then
                            local sMsg = self:GetTextData(iText)
                            sMsg = string.gsub(sMsg,"username",oPlayer:GetName())
                            self:Reward(pid,iReward,{chuanwen=sMsg,priority="teampvp_ready"})
                        end
                    else
                        self:Reward(pid,iReward)
                    end
                end
                local iSc1 = mConfig[targetlist[1]]["score"]
                local iSc2 = mConfig[targetlist[2]]["score"]
                iScore = self:ScoreCalculator(iCur,iSc1,iSc2,bwin and 1 or 0)
                self:RewardScore(oPlayer,iScore)
                self:RecordRank(oPlayer)
                if not self:GetTeam(oPlayer) then
                    self:AddCollection(oPlayer)
                end
            else
                if mArg["escape"] then
                    mLog["win"] = 2
                else
                    mLog["win"] = 0
                end
                oPlayer.m_oToday:Set("teampvp_combo",0)
                oPlayer.m_oToday:Add("teampvp_fail",1)
            end
            mLog["add_score"] = iScore
            record.user("teampvp","end_pvp",mLog)
            if self:InHDScene(oPlayer) and not mArg["no_show"] then
                local mNet = {point=iScore,currentpoint=iCur,result=iWinSide,info1=mWarArg[1],info2=mWarArg[2]}
                oPlayer:Send("GS2CTeamPVPFightResult",mNet)
            end
            if oPlayer.m_oToday:Query("teampvp_fail",0) >= self:GetConfigValue("fail_limit") then
                oNotifyMgr:Notify(pid,self:GetTextData(1027))
                self:LeaveScene(oPlayer)
            else
                self:RefreshSceneInfoByTeam(oPlayer)
            end
        end
    end
end

function CHuodong:RewardArenaMedal(oPlayer,bwin)
    local iLimit = self:GetConfigValue("reward_limit")
    if oPlayer.m_oToday:Query("tampvp_medal",0) >=  iLimit then
        return 0
    end
    local iReward = bwin and 150 or 75
    local sReason = bwin and "协同战斗胜利" or "失败"
    if iReward + oPlayer.m_oToday:Query("tampvp_medal",0) > iLimit then
        iReward =  iLimit - oPlayer.m_oToday:Query("tampvp_medal",0)
    end
    oPlayer.m_oToday:Add("tampvp_medal",iReward)
    oPlayer:RewardArenaMedal(iReward,sReason)
    return iReward
end


--Round((1000*(if(a取胜?1;0)-1/(1+10^((Tc-Ta)/400))+1000*(if(a取胜?1;0)-1/(1+10^((Td-Ta)/400)))/2,0)
function CHuodong:ScoreCalculator(iTa,iTc,iTd,iWin)
    local func = function (iTa,iTb,iWin)
        local iPara = 100
        local fY=1/(1+10^((iTb-iTa)/400))
        if iWin == 1 then
            fY = 1 - fY
        end
        -- 目前双方增减积分相同
        local fA = iPara*fY
        if fA%1 > 0.5 then
            fA = fA +1
        end
        local iA = math.max(math.floor(fA),0)
        return iA
        end
    return math.floor((func(iTa,iTc,iWin) + func(iTa,iTd,iWin))/2)
end


function CHuodong:GetRewardConfig(oPlayer,bwin)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["winreward"]
    local iWin = oPlayer.m_oToday:Query("teampvp_win",0)
    local iCombo = oPlayer.m_oToday:Query("teampvp_combo",0)
    local iMaxCombo = oPlayer.m_oToday:Query("tpvp_combo_max",0)
    if iCombo <= iMaxCombo then
        iCombo = nil
    end

    local mReward = {
    chat = {},
    reward = {},
    }
    local mCombo = {[3]=2001,[5]=2002,[10]=2003}
    local mWn = {[1]=1001,[3]=1002,[5]=1003,[10]=1004}
    local fpack = function (m)
        extend.Array.append(mReward["chat"],m["chat"])
        extend.Array.append(mReward["reward"],m["reward"])
    end

    if bwin then
        fpack(mData[1])
        if iCombo then
            local idx = mCombo[iCombo]
            if idx then
                fpack(mData[idx])
            end
        end
        local idx = mWn[iWin]
        if idx then
            fpack(mData[idx])
        end
    else
        fpack(mData[2])
    end
    return mReward
end

function CHuodong:RefreshSceneInfoByTeam(oPlayer)
    local plist = self:PlayMember(oPlayer:GetPid())
    self:RefreshSceneInfo(plist)
end

function CHuodong:RefreshSceneInfo(plist)
    local oWorldMgr = global.oWorldMgr
    local fPack = function (pobj)
        local iPid = pobj:GetPid()
        local mPartnerList = {}
        local mFight = pobj:GetFightPartner()
        for iPos=1,4 do
            local oPartner = mFight[iPos]
            if oPartner then
                table.insert(mPartnerList,oPartner:PackPartnerBase())
            end
            if #mPartnerList == 2 then
                break
            end
        end
        local iLeader = 0
        if self:IsTeamLeader(pobj) then
            iLeader = 1
        end
        local   mPack = {
            pid = iPid,
            score = self:Score(iPid),
            name = pobj:GetName(),
            partner = mPartnerList,
            leader = iLeader,
            shape = pobj:GetModelInfo().shape,
            grade = pobj:GetGrade(),
            }
        return mPack
    end
    local mPlayer = {}
    for _,pid in ipairs(plist) do
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        if pobj then
            table.insert(mPlayer,fPack(pobj))
        end
    end
    local sData = playersend.PackData("GS2CTeamPVPSceneInfo",{player=mPlayer})
    for _,pid in ipairs(plist) do
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        if pobj then
            pobj:SendRaw(sData)
        end
    end
end

function CHuodong:OpenMainRank(oPlayer)
    local mRequest = {
        data = {pid=oPlayer:GetPid(),limit=50,fail=oPlayer.m_oToday:Query("teampvp_fail",0)},
        rank_name = "teampvp",
        }
    interactive.Send(".rank","rank","GetExtraRankData",mRequest)
end

function CHuodong:RecordRank(oPlayer)
    local mUnit = self:GetUnit(oPlayer:GetPid())
    local mInfo = {
    point = self:Score(oPlayer:GetPid()),
    pid = oPlayer:GetPid(),
    name= oPlayer:GetName(),
    win = oPlayer.m_oToday:Query("teampvp_win",0),
    fail = oPlayer.m_oToday:Query("teampvp_fail",0),
    }
    local mRank = {}
    mRank.rank_name = "teampvp"
    mRank.rank_data = mInfo
    interactive.Send(".rank","rank","PushDataToRank",mRank)
end


function CHuodong:GetInviteList(oPlayer)
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    if oPlayer.m_oThisTemp:Query("teampvp_invite") then
        global.oNotifyMgr:Notify(oPlayer:GetPid(),"请求太频繁")
        return
    end
    oPlayer.m_oThisTemp:Set("teampvp_invite",1,3)
    interactive.Request(".recommend","teampvp","GetCollecttion",{pid=oPlayer:GetPid(),cnt=10,exl={}},function(mRecord,mData)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer:Send("GS2CShowTeamPVPInvite",{plist=mData["data"]})
            end
    end)
end


function CHuodong:ValidInvite(oPlayer,oTiper)
    local bSelf = false
    if oPlayer:GetPid() == oTiper:GetPid() then
        bSelf = true
    end
    if oPlayer:GetNowWar() then
        if bSelf then
            oTiper:NotifyMessage("你正在战斗中")
        else
            oTiper:NotifyMessage("对方正在战斗中")
        end
        return false
    end
    if self:GetTeam(oPlayer) then
        if bSelf then
            oTiper:NotifyMessage("你队伍已满")
        else
            oTiper:NotifyMessage("对方队伍已满")
        end
        return false
    end
    if not self:InHDScene(oPlayer) then
        if bSelf then
            oTiper:NotifyMessage("你不在活动场景内")
        else
            oTiper:NotifyMessage("对方不在活动场景内")
        end
        return false
    end
    if self:GetUnit(oPlayer:GetPid())["match_status"] then
        if bSelf then
            oTiper:NotifyMessage("你正在匹配中")
        else
            oTiper:NotifyMessage("对方正在匹配中")
        end
        return false
    end
    return true
end


function CHuodong:InvitePlayer(oPlayer,plist)
    local oWorldMgr = global.oWorldMgr
    if not self:ValidInvite(oPlayer,oPlayer) then
        return
    end

    for _,pid in ipairs(plist) do
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        if pobj then
            self:InvitePlayer2(oPlayer,pobj)
        end
    end
end


function CHuodong:InvitePlayer2(oPlayer,oTarget)
    local iPid = oPlayer:GetPid()
    local iTarget = oTarget:GetPid()
    local oWorldMgr = global.oWorldMgr
    if not (self:ValidInvite(oPlayer,oPlayer) and self:ValidInvite(oTarget,oPlayer)) then
        return
    end
    local oCbMgr = global.oCbMgr
    local sContent = string.format("%s 想邀请你参加协同比武\n是否同意？",oPlayer:GetName())
    local mNet = {
        sContent = sContent,
        uitype = 4,
        simplerole = oPlayer:PackSimpleRoleInfo(),
        sConfirm = "同意",
        sCancle = "拒绝",
        default = 0,
        time = 30,
        confirmtype = gamedefines.CONFIRM_WND_TYPE.TEAM_INVITE,
        relation = 0,
    }
    mNet = oCbMgr:PackConfirmData(nil, mNet)
    local func = function (oResponse,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        if oPlayer and oTarget then
            self:RespondInvite(oPlayer,oTarget,mData)
        end
    end
    oCbMgr:SetCallBack(oTarget:GetPid(),"GS2CConfirmUI",mNet,nil,func)
end

function CHuodong:RespondInvite(oPlayer,oTarget,mData)
    local oNotifyMgr = global.oNotifyMgr
    if mData["answer"] == 0 then
        local sMsg = oTarget:GetName() .."拒绝了你的邀请".."，并表示：".."\n[ff7200]"..mData["message"]
        oNotifyMgr:Notify(oPlayer:GetPid(),sMsg)
        return
    end
    if not (self:ValidInvite(oPlayer,oTarget) and self:ValidInvite(oTarget,oTarget)) then
        return
    end
    self:BuildTeam(oPlayer:GetPid(),oTarget:GetPid())
end


-- 只有玩家离场才清理资源
function CHuodong:OnLeaveScene(oScene,oPlayer)
    self:_CheckInMatch(oPlayer,1)
    self:LeaveTeam(oPlayer)
    self:RemoveCollection(oPlayer:GetPid())
    oPlayer:Send("GS2CLeaveTeamPVPScene",{})
end

function CHuodong:OnEnerScene(oScene,oPlayer)
    local iPid = oPlayer:GetPid()
    local oTeam = oPlayer:HasTeam()
    local plist = oPlayer:AllMember()

    if oTeam and self:InHDScene(oPlayer) then
        oTeam:Leave(oPlayer:GetPid(),"")
        global.oTeamMgr:OnLeaveTeam(oTeam:TeamID(),oPlayer:GetPid())
    end


    if #plist==2 then
        self:BuildTeam(plist[1],plist[2])
    elseif not self:GetTeam(oPlayer) then
        self:RefreshSceneInfo(self:PlayMember(iPid))
        self:AddCollection(oPlayer)
    end
    self:OpenMainRank(oPlayer)
end

function CHuodong:OnSyncFightPartner(oPlayer)
    if self:InHDScene(oPlayer) then
        local plist = self:PlayMember(oPlayer:GetPid())
        self:RefreshSceneInfo(plist)
    end
end

function CHuodong:FindNpcPath(oPlayer,iType)
    local bHasNpc = false
    for iNpcId,npc in pairs(self.m_mNpcList) do
        if npc:Type() == 1002 then
            bHasNpc = true
            break
        end
    end
    if bHasNpc then
        super(CHuodong).FindNpcPath(self,oPlayer,iType)
    else
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"每周六、周日21:00~22:00开启协同比武")
    end
end

function CHuodong:TestOP(oPlayer,iFlag,...)
    local args={...}
    local oNotifyMgr = global.oNotifyMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    local oWorldMgr = global.oWorldMgr
    if iFlag == 100 then
        local sNotify = [[

            101 - 活动准备阶段
            102 - 活动开始阶段
            103 - 活动结束阶段
            104 - 活动清理场景阶段
            ]]
        oChatMgr:HandleMsgChat(oPlayer,sNotify)
    elseif iFlag == 101 then
        if self.m_Status ~= GAME_RELEASE then
            oNotifyMgr:Notify(pid,string.format("请先清理场景--当前状态%d",self.m_Status))
            return
        end
        self:GameReady()
        self:CreateGateNpc()
    elseif iFlag == 102 then
        if self.m_Status ~= GAME_READY then
            oNotifyMgr:Notify(pid,string.format("请先准备--当前状态%d",self.m_Status))
            return
        end
        self:GameStart()
    elseif iFlag == 103 then
        if self.m_Status ~= GAME_START then
            oNotifyMgr:Notify(pid,string.format("请先开始--当前状态%d",self.m_Status))
            return
        end
        self:GameOver()
    elseif iFlag == 104 then
        if self.m_Status ~= GAME_OVER then
            oNotifyMgr:Notify(pid,string.format("请先关闭活动--当前状态%d",self.m_Status))
            return
        end
        self:GameRelease()
    elseif iFlag == 105 then
        self:EnterScene(oPlayer,nil)
    elseif iFlag == 106 then
        self:LeaveScene(oPlayer)
    elseif iFlag == 107 then
        local iCnt = tonumber(args[1])
        oPlayer.m_oToday:Set("teampvp_win",iCnt)
        oPlayer.m_oToday:Set("teampvp_combo",iCnt)
        self:RecordRank(oPlayer)
        if not self:GetTeam(oPlayer) then
                self:AddCollection(oPlayer)
        end
        self:OpenMainRank(oPlayer)
        oNotifyMgr:Notify(oPlayer:GetPid(),string.format("设定胜利%d",iCnt))
    elseif iFlag == 108 then
        local iCnt = tonumber(args[1])
        oPlayer.m_oToday:Set("teampvp_fail",iCnt)
        self:RecordRank(oPlayer)
        if not self:GetTeam(oPlayer) then
                self:AddCollection(oPlayer)
        end
        self:OpenMainRank(oPlayer)
        oNotifyMgr:Notify(oPlayer:GetPid(),string.format("设定失败%d",iCnt))
    elseif iFlag == 109 then
        local iA = tonumber(args[1])
        local iC = tonumber(args[2])
        local iD = tonumber(args[3])
        local iWin = tonumber(args[4])
        local iAdd = self:ScoreCalculator(iA,iC,iD,iWin)
        oNotifyMgr:Notify(oPlayer:GetPid(),string.format("a-%d c-%d d-%d win-%d score = %s",iA,iC,iD,iWin,iAdd))
    elseif iFlag == 110 then
        local iLimit = tonumber(args[1])
        oNotifyMgr:Notify(pid,string.format("设定每个场景人数 %d -> %d",self.m_SceneLimit,iLimit))
        self.m_SceneLimit = iLimit
    elseif iFlag == 111 then
        local iScore = tonumber(args[2])
        local pid = tonumber(args[1])
        local oWorldMgr = global.oWorldMgr
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        if not pobj then
            oNotifyMgr:Notify(oPlayer:GetPid(),"没有该玩家")
        end
        self:RewardScore(oPlayer,iScore)
        self:RecordRank(oPlayer)
        self:OpenMainRank(oPlayer)
    elseif iFlag == 114 then
        for i=1,100 do
                local mInfo = {
                point = i,
                pid = i,
                name= string.format("Faker%d",i),
                win = i,
                fail = i,
                }
            local mRank = {}
            mRank.rank_name = "teampvp"
            mRank.rank_data = mInfo
            interactive.Send(".rank","rank","PushDataToRank",mRank)
        end
    elseif iFlag == 115 then
        local mRequest = {
        data = {pid=oPlayer:GetPid(),},
        rank_name = "teampvp",
        }
        interactive.Send(".rank","rank","GetExtraRankData",mRequest)
    elseif iFlag == 115 then
        for i=1,100 do
            local m = {
            name = string.format("faker%s",i),
            score = i,
            shape=301,
            grade = i,
            pid = i,
            org = 0,
            fight = 0,
            }
            interactive.Send(".recommend","teampvp","UpdateRoleInfo",{pid=i,info={data=m}})
        end
    elseif iFlag == 120 then
        self:RewardRank(oPlayer:GetPid(),tonumber(args[1]))
    elseif iFlag == 121 then
        local random = math.random
        local func = function (pid)
            local mInfo = {
            point = random(10),
            pid = pid,
            name= string.format("faker%s",pid),
            win = random(10),
            fail = random(10),
            }
            local mRank = {}
            mRank.rank_name = "teampvp"
            mRank.rank_data = mInfo
            interactive.Send(".rank","rank","PushDataToRank",mRank)
        end
        for i=1,100 do
            func(i)
        end
    elseif iFlag == 122 then
        self:RewardTopRank()
    elseif iFlag == 123 then
        local iText = 1014
        if iText then
            local sMsg = self:GetTextData(iText)
            sMsg = string.gsub(sMsg,"username",oPlayer:GetName())
            self:Reward(pid,3002,{chuanwen=sMsg,priority="teampvp_ready"})
        end
    elseif iFlag == 12306 then
        self:EnterScene(oPlayer)
    elseif iFlag == 12307 then
        local oWorldMgr = global.oWorldMgr
        for _,iSc in ipairs(self.m_HDSceneList) do
            local oScene = self:GetHDScene(iSc)
            if not oScene then
                return
            end
            local plist = oScene:GetPlayers()
            for _,pid in ipairs(plist) do
                local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
                if pobj then
                    self:EnterMatch(pobj)
                end
            end
        end
    elseif iFlag == 12308 then
        local iScore = 0
        local oWorldMgr = global.oWorldMgr
        for _,iSc in ipairs(self.m_HDSceneList) do
            local oScene = self:GetHDScene(iSc)
            if not oScene then
                return
            end
            local plist = oScene:GetPlayers()
            for _,pid in ipairs(plist) do
                iScore = iScore + 10
                local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
                if pobj then
                    local mUnit = self:GetUnit(pid)
                    mUnit["score"] = iScore
                    self:SetUnit(pid,mUnit)
                    self:RecordRank(pobj)
                end
            end
        end
        self:OpenMainRank(oPlayer)
    elseif iFlag == 9998 then
        self:FindLeavePath(oPlayer)
    elseif iFlag == 9999 then
        oNotifyMgr:SendPrioritySysChat("huodong_char","这是测试传闻",1,{},{grade=50})
    end
end



function NewTeam(gid)
    return CTeam:New(gid)
end



CTeam = {}
CTeam.__index = CTeam
inherit(CTeam, datactrl.CDataCtrl)

function CTeam:New(gid)
    local o = super(CTeam).New(self)
    o.m_ID = gid
    o.m_List = {}
    return o
end

function CTeam:Huodong()
    return global.oHuodongMgr:GetHuodong("teampvp")
end

function CTeam:Size()
    return #self.m_List
end

function CTeam:InTeam(pid)
    return table_in_list(self.m_List,pid)
end

function CTeam:Add(pid)
    assert(#self.m_List < 2)
    table.insert(self.m_List,pid)
    local o = self:Huodong()
    local m = o:GetUnit(pid)
    m["team"] = self.m_ID
    o:SetUnit(pid,m)
end

function CTeam:Remove(pid)
    assert(self:InTeam(pid))
    extend.Array.remove(self.m_List,pid)
    local o = self:Huodong()
    local m = o:GetUnit(pid)
    m["team"] = nil
    o:SetUnit(pid,m)
end

function CTeam:Member()
    return table_copy(self.m_List)
end


function CTeam:Leader()
    return self.m_List[1]
end

function CTeam:SetLeader(pid)
    assert(self:InTeam(pid))
    extend.Array.remove(self.m_List,pid)
    table.insert(self.m_List,1,pid)
end


function CTeam:Release()
    local o = self:Huodong()
    for _,pid in ipairs(self.m_List) do
        self:Remove(pid)
    end
    super(CTeam).Release(self)
end







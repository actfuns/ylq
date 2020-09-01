--import module
local global = require "global"
local teaminfo = import(service_path("team/teaminfo"))
local teamobj = import(service_path("team/teamobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
function NewTeam(...)
    return CTeam:New(...)
end

CTeam = {}
CTeam.__index = CTeam
inherit(CTeam,teamobj.CTeam)

function CTeam:New(pid, teamid)
    local o = super(CTeam).New(self,pid,teamid)
    o.m_Type = gamedefines.TEAM_CREATE_TYPE.LILIAN
    o:InitTeamTask(pid)
    return o
end

function CTeam:InitTeamTask(pid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    local oTask = oPlayer.m_oTaskCtrl:GetLilianTask()
    self.m_oLilianTask = oTask
end

function CTeam:Release()
    super(CTeam).Release(self)
end

function CTeam:CheckLlianDull(oPlayer)
    if not self.m_iLeader or self.m_iLeader~=oPlayer.m_iPid then
        return
    end
    if not oPlayer or oPlayer:GetNowWar() then
        return
    end
    if oPlayer:IsDull(80) then
        self:Leave(self.m_iLeader)
    end
end

function CTeam:AddMember(oMem)
    local oWorldMgr = global.oWorldMgr
    local iTeamID = self.m_ID
    local iLeader = self:Leader()
    local iPid = oMem.m_ID
    if iPid == iLeader then
        self:_TrueAddMember(oMem)
        return
    end
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(iLeader)
    local oSceneMgr = global.oSceneMgr
    local oScene = oLeader.m_oActiveCtrl:GetNowScene()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local func = function (m)
        local iRemoteScene = m.scene_id
        local iRemotePid = m.pid
        local mRemotePos = m.pos_info
        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oP then
            return
        end
        oSceneMgr:EnterScene(oP,iRemoteScene, {pos = {x = mRemotePos.x, y = mRemotePos.y, z = mRemotePos.z, face_x = mRemotePos.face_x, face_y = mRemotePos.face_y, face_z = mRemotePos.face_z}},true)
        local oTeamMgr = global.oTeamMgr
        local oTeam = oTeamMgr:GetTeam(iTeamID)
        if not oTeam then
            return
        end
        oTeam:_TrueAddMember(oMem)
    end
    oSceneMgr:QueryPos(iLeader,func)
end

function CTeam:_TrueAddMember(oMem)
    super(CTeam).AddMember(self,oMem)
    if oMem.m_ID == self:Leader() then
        return
    end
    self:SynClientNpc(oMem.m_ID)
end

function CTeam:SynClientNpc(iPid)
    local bSyncSuccess = false
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    for _,oMem in pairs(self.m_lMember) do
        if oMem.m_ID ~= iPid then
            local oMem = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
            local oMemTask = oMem.m_oTaskCtrl:GetLilianTask()
            local oPlayerTask = oPlayer.m_oTaskCtrl:GetLilianTask()
            local oLilianNpc = oMemTask:GetLilianNpc()
            if oLilianNpc then
                oPlayerTask:SynClientNpc(oLilianNpc)
                oPlayerTask:SynFightInfo(oMemTask:GetFight())
                bSyncSuccess = true
                break
            end
        end
    end
    if bSyncSuccess then
        return
    else
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("lilian")
        local oLeader = oWorldMgr:GetOnlinePlayerByPid(self:Leader())
        oHuodong:RefreshMonster(oLeader)
    end
end

function CTeam:LilianFightEnd(mArgs)
    local oWorldMgr = global.oWorldMgr
    for _,oMem in pairs(self.m_lMember) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
        if oPlayer then
            local iTimes = oPlayer.m_oTaskCtrl:GetLilianTimes()
            if iTimes <= 0 then
                self:Leave(oMem.m_ID,"修行次数用完，自动结束修行")
            end
        end
    end
    if self and self.m_lMember and #self.m_lMember > 0 then
        if #self.m_lMember < 3 then
            local oTeamMgr = global.oTeamMgr
            oTeamMgr:ReOrganizeLilianTeam(self)
        else
            local oHuodongMgr = global.oHuodongMgr
            local oHuodong = oHuodongMgr:GetHuodong("lilian")
            local oLeader = oWorldMgr:GetOnlinePlayerByPid(self:Leader())
            oHuodong:RefreshMonster(oLeader)
            if #self.m_lMember > 1 then
                for i = 2,#self.m_lMember do
                    self:SynClientNpc(self.m_lMember[i].m_ID)
                end
            end
            self:ContinueLilian()
        end
    end
end

function CTeam:Leave(pid,sLeaveMsg)
    for iPos,oMem in ipairs(self.m_lMember) do
        if oMem.m_ID == pid then
            table.remove(self.m_lMember,iPos)
            break
        end
    end
    self:RecyclePos(pid)
    self.m_mShortLeave[pid] = nil
    self.m_mOffline[pid] = nil
    
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        oPlayer.m_oActiveCtrl:SetInfo("TeamID",nil)
    end
    self:GS2CDelTeam(pid)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(pid, sLeaveMsg or "修行结束")
    self:OnLeave(pid,sLeaveMsg or "leave")
    local oTeamMgr = global.oTeamMgr
    oTeamMgr:ClearPid2TeamID(pid)
    local oTask = oPlayer.m_oTaskCtrl:GetLilianTask()
    oTask:StopLilian()
end

function CTeam:OnLeave(pid,sTeamOp)
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        self:UnRegisterTeamChannel(oPlayer,sTeamOp)
    end
    if not self:IsLeader(pid) then
        local mMem = self:OnlineMember()
        for pid,_ in pairs(mMem) do
            self:RefreshTeamStatus(pid)
        end
        local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
        if oLeader then
            oSceneMgr:SyncSceneTeam(oLeader)
        end
        if self.m_oVoteBox then
            self.m_oVoteBox:OnLeaveTeam(pid, 1)
        end
        return
    end
    local bRelease = false
    if self:TeamSize() < 1 then
        bRelease = true
    end
    if bRelease then
        self:ReleaseTeam()
        return
    end
    if table_count(self.m_lMember) > 0 then
        self.m_iLeader = self.m_lMember[1].m_ID
    else
        bRelease = true
    end
    if bRelease then
        self:ReleaseTeam()
        return
    end
    self:ChangePos(self.m_iLeader,1)
    
    local oOldLeader = oWorldMgr:GetOnlinePlayerByPid(pid)
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
    local mMem = self:OnlineMember()
    for pid,_ in pairs(mMem) do
        self:RefreshTeamStatus(pid)
    end
    
    local oSceneMgr = global.oSceneMgr
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
    if oLeader then
        oSceneMgr:SyncSceneTeam(oLeader)
    end
    if self.m_oVoteBox then
        self.m_oVoteBox:OnLeaveTeam(pid, 1)
    end
    self:OnLeaderChange()
end

function CTeam:OnLeaderChange()
    self:ContinueLilian()
end

function CTeam:ContinueLilian()
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local res = require "base.res"
    local mControlData = res["daobiao"]["global_control"]["lilian"]
    local iOpenSys = mControlData["is_open"] or "y"
    if iOpenSys ~= "y" then
        for _,oMem in pairs(self.m_lMember) do
            oNotifyMgr:Notify(oMem.m_ID,"该功能正在维护，已临时关闭。请您留意官网相关信息。")
        end
        self:ReleaseTeam()
        return
    end
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:Leader())
    local oTask = oPlayer.m_oTaskCtrl:GetLilianTask()
    oTask:AutoFindLilianPath()
end

function CTeam:RemoveMemMonster()
    local oWorldMgr = global.oWorldMgr
    for _,oMem in pairs(self.m_lMember) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
        local oLilianTask = oPlayer.m_oTaskCtrl:GetLilianTask()
        oLilianTask:RemoveClientNpc(oLilianTask.m_mClientNpc[1])
    end
end

function CTeam:WarFightEnd(mArgs)
    super(CTeam).WarFightEnd(self,mArgs)
    if not mArgs then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local bLeaveObserver = mArgs.bLeaveObserver
    local iPid = mArgs.pid
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self:Leader())
    local oWar = oLeader.m_oActiveCtrl:GetNowWar()
    if bLeaveObserver and iPid and oWar then
        self:Leave(iPid,"退出观战，自动离开修行小队")
    end
end

function CTeam:EscapeWar(iPid)
        self:Leave(iPid,"退出战斗离开修行")
end

function CTeam:OnLogin(oPlayer)
    super(CTeam).OnLogin(self,oPlayer)
    local oWorldMgr = global.oWorldMgr
    self:SynClientNpc(oPlayer.m_iPid)
    local iLeader = self:Leader()
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(iLeader)
    local oWar = oLeader.m_oActiveCtrl:GetNowWar()
    if not oWar then
        self:ContinueLilian()
    end
end

function CTeam:OnLogout(oPlayer)
    self:Leave(oPlayer.m_iPid,"Logout")
end
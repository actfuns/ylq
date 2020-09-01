--import module
local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local res = require "base.res"
local tprint = require('base.extend').Table.print
local colorstring = require "public.colorstring"

local handleteam = import(service_path("team.handleteam"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item.loaditem"))
local teaminfo = import(service_path("team/teaminfo"))

function NewTeam(...)
    return CTeam:New(...)
end

CTeam = {}
CTeam.__index = CTeam
inherit(CTeam,logic_base_cls())

function CTeam:New(pid, teamid)
    local o = super(CTeam).New(self)
    o.m_ID = teamid
    o.m_iLeader = pid
    o.m_lMember = {}
    o.m_mShortLeave = {}
    o.m_mOffline = {}
    o.m_mTask = {}
    o.m_mBlackList = {}
    o.m_oApplyMgr = teaminfo.NewApplyInfoMgr(teamid)
    o.m_mPosInfo = {}
    o.m_Type = gamedefines.TEAM_CREATE_TYPE.NORMAL
    o.m_WarBattleCmd = {}
    o.m_OnLeaveFunc = {}
    o.m_OnAddFunc = {}
    o.m_OnShortLeaveFunc = {}
    return o
end

function CTeam:ReleaseTeam()
    local oTeamMgr = global.oTeamMgr
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr

    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
    if oLeader then
        oSceneMgr:RemoveSceneTeam(oLeader, self.m_ID)
    end
    for _,oMem in pairs(self.m_lMember) do
        self:Leave(oMem.m_ID)
    end
    for pid,_ in pairs(self.m_mShortLeave) do
        self:Leave(pid)
    end
    if self:AutoMatching() then
        local iTargetID = self:GetTargetID()
        interactive.Send(".autoteam", "team", "TeamCancle", {targetid = iTargetID, teamid = self.m_ID})
    end
    self.m_lMember = {}
    self.m_mShortLeave = {}
    self.m_mOffline = {}
    self.m_mTask = {}
    self.m_OnLeaveFunc = {}
    self.m_OnAddFunc = {}
    self.m_OnShortLeaveFunc = {}
    oTeamMgr:RemoveTeam(self.m_ID)
end



function CTeam:Release()
    for _,oTask in pairs(self.m_mTask) do
        baseobj_safe_release(oTask)
    end
    if self.m_oVoteBox then
        baseobj_safe_release(self.m_oVoteBox)
    end
    super(CTeam).Release(self)
end


function CTeam:RegisterFunc(op,name,func)
    local funclist
    if op == "leave" then
        funclist = self.m_OnLeaveFunc
    elseif op == "add" then
        funclist = self.m_OnAddFunc
    elseif op == "shortleave" then
        funclist = self.m_OnShortLeaveFunc
    end
    funclist[name] = func
end

function CTeam:CancelRegisterFunc(op,name)
    local funclist
    if op == "leave" then
        funclist = self.m_OnLeaveFunc
    elseif op == "add" then
        funclist = self.m_OnAddFunc
    elseif op == "shortleave" then
        funclist = self.m_OnShortLeaveFunc
    end
    funclist[name] = nil
end


function CTeam:TeamID()
    return self.m_ID
end

function CTeam:DispatchPos(iPid)
    for i=1,4 do
        if not self.m_mPosInfo[i] then
            self.m_mPosInfo[i] = iPid
            return i
        end
    end
end

function CTeam:RecyclePos(iPid)
    for i=1,4  do
        if self.m_mPosInfo[i] and self.m_mPosInfo[i] == iPid then
            self.m_mPosInfo[i] = nil
            return
        end
    end
end

function CTeam:ChangePos(iPid,iPos)
    local iSrcPid = self.m_mPosInfo[1]
    for i = 1,4 do
        if self.m_mPosInfo[i] and self.m_mPosInfo[i] == iPid then
            self.m_mPosInfo[i] = iSrcPid
            self.m_mPosInfo[1] = iPid
            break
        end
    end
end

function CTeam:GetTeamLeader()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:Leader())
    return oPlayer
end

function CTeam:Leader()
    return self.m_iLeader
end

function CTeam:IsLeader(pid)
    if self.m_iLeader == pid then
        return true
    end
    return false
end

function CTeam:IsShortLeave(pid)
    if self.m_mShortLeave[pid] then
        return true
    end
    return false
end

function CTeam:HasShortLeave()
    if table_count(self.m_mShortLeave) > 0 then
        return true
    end
    return false
end

function CTeam:HasOffline()
    if table_count(self.m_mOffline) > 0 then
        return true
    end
    return false
end

function CTeam:GetShortLeaveList()
    local mShort = {}
    for _,oMem in ipairs(self.m_mShortLeave) do
        table.insert(mShort,oMem.m_ID)
    end
    return mShort
end

function CTeam:GetShortLeave(pid)
    return self.m_mShortLeave
end

function CTeam:IsTeamMember(pid)
    for _,oMem in pairs(self.m_lMember) do
        if oMem.m_ID == pid then
            return true
        end
    end
    return false
end

function CTeam:OnlineMember()
    local mMem = {}
    for _,oMem in ipairs(self.m_lMember) do
        mMem[oMem.m_ID] = 1
    end
    for pid,oMem in pairs(self.m_mShortLeave) do
        mMem[pid] = 1
    end
    return mMem
end

function CTeam:GetTeamMember()
    local mMem = {}
    for _,oMem in ipairs(self.m_lMember) do
        table.insert(mMem,oMem.m_ID)
    end
    return mMem
end

function CTeam:GetTeamShort()
    local mMem = {}
    for _,oMem in pairs(self.m_mShortLeave) do
        table.insert(mMem,oMem.m_ID)
    end
    return mMem
end

function CTeam:MemberSize()
    return table_count(self.m_lMember)
end

function CTeam:OnlineMemberSize()
    local iSize = 0
    iSize = iSize + table_count(self.m_lMember)
    iSize = iSize + table_count(self.m_mShortLeave)
    return iSize
end

function CTeam:TeamSize()
    local iSize = 0
    iSize = iSize + table_count(self.m_lMember)
    iSize = iSize + table_count(self.m_mShortLeave)
    iSize = iSize + table_count(self.m_mOffline)
    return iSize
end

function CTeam:GetMember(pid)
    for _,oMem in ipairs(self.m_lMember) do
        if oMem.m_ID == pid then
            return oMem
        end
    end
    local oMem = self.m_mShortLeave[pid]
    if oMem then
        return oMem
    end
    local oMem = self.m_mOffline[pid]
    return oMem
end

function CTeam:InTeamStatus(pid)
    if self.m_iLeader == pid then
        return 1
    end
    for _,oMem in ipairs(self.m_lMember) do
        if oMem.m_ID == pid then
            return 2
        end
    end
    if self.m_mShortLeave[pid] then
        return 3
    end
    if self.m_mOffline[pid] then
        return 4
    end
end

function CTeam:AddMember(oMem,bReEnter)
    local pid = oMem.m_ID
    self.m_mShortLeave[pid] = nil
    self.m_mOffline[pid] = nil

    if not bReEnter then
        self:DispatchPos(pid)
    end
    table.insert(self.m_lMember,oMem)
    self:GS2CAddTeam(pid)
    local oTeamMgr = global.oTeamMgr
    oTeamMgr:AddPid2TeamID(pid,self.m_ID)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        oPlayer.m_oActiveCtrl:SetInfo("TeamID",self.m_ID)
        local iTargetID = oPlayer.m_oActiveCtrl:GetInfo("auto_targetid")
        if iTargetID then
            interactive.Send(".autoteam", "team", "CanclePlayerAutoMatch", {targetid = iTargetID, pid = pid})
            oPlayer:SetAutoMatching(nil)
        end
        oPlayer:CancelSocailDisplay()
    end

    for _,oTask in pairs(self.m_mTask) do
        oTask:EnterTeam(pid,1)
    end
    local plist = self:OnlineMember()
    for memid,_ in pairs(plist) do
        if memid ~= pid then
            if not bReEnter then
                self:GS2CAddTeamMember(oMem,memid)
            end
            self:RefreshTeamStatus(memid)
        end
    end
    --刷场景
    if oPlayer:GetNowWar() then
        self:ShortLeave(pid)
    elseif not self:CheckOb(pid) then
        local oLeader = oWorldMgr:GetOnlinePlayerByPid(self:Leader())
        local oSceneMgr = global.oSceneMgr
        local oScene = oLeader.m_oActiveCtrl:GetNowScene()
        if pid~=self.m_iLeader and oScene and oScene:VaildEnter(oPlayer,oLeader) then
            oSceneMgr:SyncSceneTeam(oPlayer)
        end
    end
    if self:TeamSize() >= gamedefines.TEAM_MAX_SIZE and self:AutoMatching() then
        self:SetUnAutoMatching()
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(self:Leader(), "队伍人数已满，停止自动匹配")
        interactive.Send(".autoteam", "team", "CancleTeamAutoMatch", {targetid = self.m_AutoTarget, teamid = self:TeamID()})
    end

    if self:GetTargetID() == 1101 then
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("minglei")
        if oHuodong then
            oHuodong:EnterMingleiTeam(oPlayer)
        end
    end
    oPlayer:SyncTosOrg({team=true})
    for name,func in pairs(self.m_OnAddFunc) do
        func(self,pid)
    end
end

function CTeam:CheckOb(iPid)
    local oWorldMgr = global.oWorldMgr
    local iLeader = self:Leader()
    if iLeader == iPid then
        return
    end
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(iLeader)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oLeader or not oPlayer then
        return false
    end
    local oWar = oLeader.m_oActiveCtrl:GetNowWar()
    if oWar then
        local iCamp = oWar:GetCampId(iLeader)
        if not iCamp then
            iCamp = oWar:GetObserverCamp(iLeader)
        end
        local oWarMgr = global.oWarMgr
        oWarMgr:ObserverEnterWar(oPlayer,oWar:GetWarId(),{observer_view = iCamp})
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"观战结束后回归队伍")
        local iTeamID = self.m_ID
        local fCallback = function(mArgs)
            local bLeaveObserver = mArgs and mArgs.bLeaveObserver

            local oTeamMgr = global.oTeamMgr
            local oTeam = oTeamMgr:GetTeam(iTeamID)
            if not oTeam then
                return
            end

            oTeam:BackTeam(iPid,bLeaveObserver)
        end
        self:AddWarEndFunc(fCallback)
        return true
    end
    return false
end

function CTeam:SetLeader(pid)
    local srcpos
    for iPos,oMem in ipairs(self.m_lMember) do
        if oMem.m_ID == pid then
            srcpos = iPos
            break
        end
    end
    if not srcpos then
        return
    end
    local oOldLeader = self:GetTeamLeader()
    self.m_iLeader = pid
    local oLeader = self.m_lMember[1]
    local oMem = self:GetMember(pid)
    self.m_lMember[1] = oMem
    self.m_lMember[srcpos] = oLeader
    self:ChangePos(pid,1)
    self:OnLeaderChange()
    local mMem = self:OnlineMember()
    for pid,_ in pairs(mMem) do
        self:RefreshTeamStatus(pid)
    end
     --刷场景
     local oWorldMgr = global.oWorldMgr
     local oSceneMgr = global.oSceneMgr
     local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
     if oPlayer then
        oSceneMgr:SyncSceneTeam(oPlayer)
    end
    local oTeamMgr = global.oTeamMgr
    oTeamMgr:AdjustTrapmineLeader(oOldLeader, self)
end

function CTeam:OnLeaderChange()
    self:CancleAutoMatch()
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
    -- 在聊天频道注销
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        oPlayer.m_oActiveCtrl:SetInfo("TeamID",nil)
        self:GS2CDelTeam(pid)
        local oNotifyMgr = global.oNotifyMgr
        if sLeaveMsg ~= "" then
            oNotifyMgr:Notify(oPlayer.m_iPid, sLeaveMsg or "成功离开队伍")
        end
    end


    for _,taskobj in pairs(self.m_mTask) do
        taskobj:LeaveTeam(pid,1)
    end

    self:AddMem2BlackList(pid)
    if self:AutoMatching() then
        local mData = {
            targetid = self:GetTargetID(),
            teamid = self:TeamID(),
            pid = pid,
            timestamp = self.m_mBlackList[pid],
        }
        interactive.Send(".autoteam", "team", "AddMem2TeamBlackList", mData)
    end

    for name,func in pairs(self.m_OnLeaveFunc) do
        func(self,pid)
    end

    self:OnLeave(pid,sLeaveMsg or "leave")
    if oPlayer then
        oPlayer:SyncTosOrg({team=true})

    end

    local oTeamMgr = global.oTeamMgr
    oTeamMgr:ClearPid2TeamID(pid)

    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
    if not oLeader then
        return
    end
    local mTargetTeamSetting  = oLeader.m_oBaseCtrl:GetSystemSetting("teamsetting")
    if mTargetTeamSetting.autostart_teammatch and mTargetTeamSetting.autostart_teammatch == 1 then
        local mTarget = self:PackTargetInfo()
        if mTarget .auto_target ~= 0 then
            self.m_AutoTarget.team_match = 1
            self:StartAutoMatch(self.m_iLeader, self:PackTargetInfo())
            local memlist = self:OnlineMember()
            local mNet = {}
            mNet["target_info"] = self:PackTargetInfo()
            self:BroadCast(memlist,"GS2CTargetInfo",mNet)
        end
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("trapmine")
    if oHuodong then
        oHuodong:LeaveTeam(pid)
    end
end

function CTeam:OnLeave(pid,sTeamOp)
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        if not sTeamOp or sTeamOp ~= "shortleave" then
            self:UnRegisterTeamChannel(oPlayer,sTeamOp)
        end
        if sTeamOp ~= "shortleave" then
            local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
            if oScene and oScene.m_OnLeaveTeam then
                oScene.m_OnLeaveTeam(oScene,oPlayer)
            end
        end
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
    if self:TeamSize() < 2 then
        bRelease = true
    end
    if bRelease then
        self:ReleaseTeam()
        return
    end

    if table_count(self.m_lMember) > 1 then
        self.m_iLeader = self.m_lMember[1].m_ID
        bRelease = false
    else
        bRelease = true
    end
    if bRelease then
        self:ReleaseTeam()
        return
    end
    self:ChangePos(self.m_iLeader,1)
    self:OnLeaderChange()
    local oOldLeader = oWorldMgr:GetOnlinePlayerByPid(pid)
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
    local mMem = self:OnlineMember()
    for pid,_ in pairs(mMem) do
        self:RefreshTeamStatus(pid)
        local sMsg = ""
        local mArgs = {}
        if iPid == self.m_iLeader then
            sMsg = colorstring.GetTextData(1099 , {"team"})
            mArgs = {
                role = oOldLeader:GetName()
            }
            --sMsg = colorstring.FormatColorString(colorstring.GetTextData(1099 , {"team"}),{role = oOldLeader:GetName()})
        else
            sMsg = colorstring.GetTextData(1100 , {"team"})
            mArgs = {
                role = {oOldLeader:GetName(),oLeader:GetName()}
            }
            --sMsg = colorstring.FormatColorString(colorstring.GetTextData(1100 , {"team"}) ,{role = {oOldLeader:GetName(),oLeader:GetName()}})
        end
        oNotifyMgr:BroadCastNotify(pid,{"GS2CNotify"},sMsg,mArgs)
        --oNotifyMgr:Notify(pid, sMsg)
    end

    local oSceneMgr = global.oSceneMgr
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
    if oLeader then
        oSceneMgr:SyncSceneTeam(oLeader)
    end
    if self.m_oVoteBox then
        self.m_oVoteBox:OnLeaveTeam(pid, 1)
    end
end

--
function CTeam:ShortLeave(iPid)
    if self.m_mShortLeave[iPid] then
        return
    end
    if self:IsLeader(iPid) then
        if #self.m_lMember == 1 then
            return
        elseif #self.m_lMember > 1 then
            local oWorldMgr = global.oWorldMgr
            local oNotifyMgr = global.oNotifyMgr
            local iNewLeaderId = nil
            for i = 2,#self.m_lMember do
                local oMem = self.m_lMember[i]
                local oMemObj = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
                if oMemObj then
                    if oMemObj.m_oActiveCtrl:GetInfo("auto_targetid") ~= 1 then
                        iNewLeaderId = oMem.m_ID
                        break
                    end
                end
            end
            if not iNewLeaderId then
                return
            end
            local oOldLeader = oWorldMgr:GetOnlinePlayerByPid(iPid)
            local oNewLeader = oWorldMgr:GetOnlinePlayerByPid(iNewLeaderId)
            if oOldLeader then
                oNotifyMgr:Notify(iPid,string.format("你已暂离队伍，%s成为了本队队长",oNewLeader:GetName()))
            end
            oNotifyMgr:Notify(iNewLeaderId,string.format("%s暂离了队伍，你成为了本队队长",oOldLeader:GetName()))
            for _,oMem in pairs(self.m_lMember) do
                if oMem.m_ID ~= iPid and oMem.m_ID ~= iNewLeaderId then
                    oNotifyMgr:Notify(oMem.m_ID,string.format("%s已暂离队伍，%s成为了本队队长",oOldLeader:GetName(),oNewLeader:GetName()))
                end
            end
            for _,oMem in pairs(self.m_mShortLeave) do
                if oMem.m_ID ~= iPid and oMem.m_ID ~= iNewLeaderId then
                    oNotifyMgr:Notify(oMem.m_ID,string.format("%s已暂离队伍，%s成为了本队队长",oOldLeader:GetName(),oNewLeader:GetName()))
                end
            end
            self:SetLeader(iNewLeaderId)
        end
    end
    local oMem
    for iPos,oTeamMem in ipairs(self.m_lMember) do
        if oTeamMem.m_ID == iPid then
            oMem = oTeamMem
            table.remove(self.m_lMember,iPos)
            break
        end
    end
    if oMem then
        self.m_mShortLeave[iPid]  = oMem
        oMem:SetStatus(gamedefines.TEAM_MEMBER_STATUS.SHORTLEAVE)
    end
    for _,taskobj in pairs(self.m_mTask) do
        taskobj:LeaveTeam(iPid,2)
    end

    local mMem = self:OnlineMember()
    for memid,_ in pairs(mMem) do
        self:RefreshTeamStatus(memid)
    end
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
    if oLeader then
        oSceneMgr:SyncSceneTeam(oLeader)
    end
    if self.m_oVoteBox then
        self.m_oVoteBox:OnLeaveTeam(iPid, 2)
    end
    self:OnLeave(iPid,"shortleave")
    for name,func in pairs(self.m_OnShortLeaveFunc) do
        func(self,iPid)
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("trapmine")
    if oHuodong then
        oHuodong:LeaveTeam(iPid)
    end
end

--//TODO优化接口
function CTeam:BackTeam(iPid,bLeaveObserver)
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oScene = oLeader.m_oActiveCtrl:GetNowScene()
    if oScene and not oScene:VaildEnter(oPlayer,oLeader) then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(iPid,"队长正在神秘之地，暂时不可回归队伍")
        return false
    end

    if not bLeaveObserver and self:CheckOb(iPid) then
        return false
    end
    if oLeader and oPlayer then
        oSceneMgr:TransToLeader(oPlayer,self.m_iLeader)
    end
    local oMem = self.m_mShortLeave[iPid]
    if oMem then
        self.m_mShortLeave[iPid] = nil
        oMem:SetStatus(gamedefines.TEAM_MEMBER_STATUS.MEMBER)
        table.insert(self.m_lMember,oMem)
    end
     for _,oTask in pairs(self.m_mTask) do
        oTask:EnterTeam(iPid,2)
    end

    local mMem = self:OnlineMember()
    for iPid,_ in pairs(mMem) do
        self:RefreshTeamStatus(iPid)
    end
    if oLeader then
        oSceneMgr:SyncSceneTeam(oLeader)
    end
    if oPlayer then
        oPlayer:CancelSocailDisplay()
    end
    return true
end

function CTeam:OnLogin(oPlayer)
    local pid = oPlayer.m_iPid
    local oTeamMgr = global.oTeamMgr
    local oInviteMgr = oTeamMgr:GetInviteMgr(pid)
    oInviteMgr:ClearCurInviteInfo()
    self:LoginTask(oPlayer)
    local oApplyMgr = self.m_oApplyMgr
    local memlist = self:OnlineMember()
    if memlist[pid] then
        self:GS2CAddTeam(pid)
        if self:IsLeader(pid) then
            oApplyMgr:SendApplyInfo(pid)
        end
        return
    end
    local oTeamMgr = global.oTeamMgr
    local oMem = self.m_mOffline[pid]
    if not oMem then
        return
    end
    self.m_mOffline[pid] = nil

    local iStatus = oMem:Status()
    if iStatus == 1 then
        oTeamMgr:AddTeamMember(self.m_ID,pid,true)
    elseif iStatus == 2 then
        self.m_mShortLeave[pid] = oMem
        oMem:SetStatus(gamedefines.TEAM_MEMBER_STATUS.SHORTLEAVE)
        self:GS2CAddTeam(pid)
        local mMem = self:OnlineMember()
        for memid,_ in pairs(mMem) do
            self:RefreshTeamStatus(memid)
        end
        oPlayer.m_oActiveCtrl:SetInfo("TeamID",self.m_ID)
    end

    oApplyMgr:SendApplyInfo(pid)
end

function CTeam:LoginTask(oPlayer)
    for _,oTask in pairs(self.m_mTask) do
        oTask:OnLogin(oPlayer)
    end
end

function CTeam:UnRegisterTeamChannel(oPlayer,sReason)
    local mRole = {
        pid = oPlayer:GetPid(),
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.TEAM_TYPE, self:TeamID(), false},
        },
        info = mRole,
    })
    if sReason ~= "Logout" then
        interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = oPlayer:GetPid(),
            channel_list = {
                {gamedefines.BROADCAST_TYPE.TEAM_TYPE, 1, true},
            },
            info = mRole,
        })
    end
end

function CTeam:OnLogout(oPlayer)
    local oMem
    local pid = oPlayer.m_iPid
    self:UnRegisterTeamChannel(oPlayer,"Logout")
    if self:IsLeader(pid) then
        if #self.m_lMember == 1 then
            self:Leave(pid,"Logout")
            return
        elseif #self.m_lMember > 1 then
            local iNewLeaderId = self.m_lMember[2].m_ID
            self:SetLeader(iNewLeaderId)
            local oApplyMgr = self.m_oApplyMgr
            oApplyMgr:SendApplyInfo(iNewLeaderId)
        end
    end
    local memlist = self:OnlineMember()
    for iPos,oTeamMem in ipairs(self.m_lMember) do
        if oTeamMem.m_ID == pid then
            table.remove(self.m_lMember,iPos)
            oMem = oTeamMem
            oMem:SetStatus(gamedefines.TEAM_MEMBER_STATUS.MEMBER)
            break
        end
    end
    if self.m_mShortLeave[pid] then
        oMem = self.m_mShortLeave[pid]
        self.m_mShortLeave[pid] = nil
        oMem:SetStatus(gamedefines.TEAM_MEMBER_STATUS.SHORTLEAVE)
    end
    if not oMem then
        return
    end
    self.m_mOffline[pid] = oMem

    if oMem:Status() == gamedefines.TEAM_MEMBER_STATUS.MEMBER then
        self:OnLeave(pid,"Logout")
    else
        local mMem = self:OnlineMember()
        for memid,_ in pairs(mMem) do
            self:RefreshTeamStatus(memid)
        end
    end
end

function CTeam:BroadCast(plist,sMessage,mData)
    local oWorldMgr = global.oWorldMgr
    for pid,_ in pairs(plist) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            oPlayer:Send(sMessage,mData)
        end
    end
end

function CTeam:PackPosInfo()
    local mData = {}
    for i = 1,4 do
        if self.m_mPosInfo[i] then
            table.insert(mData,{pos = i,pid = self.m_mPosInfo[i]})
        end
    end
    return mData
end

function CTeam:PackTeamInfo()
    local mNet = {}
    mNet["teamid"] = self.m_ID
    mNet["leader"] = self.m_iLeader
    local mMem = {}
    for iPos,iPid in pairs(self.m_mPosInfo) do
        local oMem = self:GetMember(iPid)
        local mData = oMem:PackInfo()
        if self.m_mOffline and self.m_mOffline[iPid] then
            mData["status_info"]["status"] = 3
        end
        table.insert(mMem,mData)
    end

    mNet["target_info"] = self:PackTargetInfo()
    mNet["member"] = mMem
    mNet["posinfo"] = self:PackPosInfo()
    mNet["type"] = self.m_Type
    mNet["auto_match"] = self:AutoMatching() and 1 or 0
    return mNet
end

function CTeam:GS2CAddTeam(pid)
    local mNet = self:PackTeamInfo()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        oPlayer:Send("GS2CAddTeam",mNet)
    end
end

function CTeam:GS2CDelTeam(pid)
    local mNet = {}
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CDelTeam",mNet)
end

function CTeam:RefreshTeamStatus(pid)
    local mNet = {}
    local mStatus = {}
    for _,oMem in ipairs(self.m_lMember) do
        table.insert(mStatus,{pid=oMem.m_ID,status=1})
    end
    for _,oMem in pairs(self.m_mShortLeave) do
        table.insert(mStatus,{pid=oMem.m_ID,status=2})
    end
    for _,oMem in pairs(self.m_mOffline) do
        table.insert(mStatus,{pid=oMem.m_ID,status=3})
    end
    mNet["team_status"] = mStatus
    mNet["posinfo"] = self:PackPosInfo()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        oPlayer:Send("GS2CRefreshTeamStatus",mNet)
    end
end

function CTeam:GS2CAddTeamMember(oMem,target)
    local oWorldMgr = global.oWorldMgr
    local mNet = {}
    mNet["mem_info"] = oMem:PackInfo()
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(target)
    if oTarget then
        oTarget:Send("GS2CAddTeamMember",mNet)
    end
end

function CTeam:GetApplyMgr()
    return self.m_oApplyMgr
end

function CTeam:PackAutoTeamInfo()
    local mMem = {}
    for _,oMem in ipairs(self.m_lMember) do
        table.insert(mMem,oMem:PackAutoTeamInfo())
    end
    for _,oMem in pairs(self.m_mShortLeave) do
        table.insert(mMem,oMem:PackAutoTeamInfo())
    end
    for _,oMem in pairs(self.m_mOffline) do
        table.insert(mMem,oMem:PackAutoTeamInfo())
    end
    local mArgs = {
        leader = self.m_iLeader,
        target_info = self.m_AutoTarget or {},
        mem = mMem,
        black_list = self.m_mBlackList,
    }
    return mArgs
end

function CTeam:SetAutoMatchTarget(mData)
    local oWorldMgr = global.oWorldMgr
    self.m_AutoTarget = {}
    self.m_AutoTarget.auto_target = mData.auto_target or 0
    local res = require "base.res"
    local mInfo = res["daobiao"]["autoteam"][self.m_AutoTarget.auto_target]
    self.m_AutoTarget.min_grade = mData.min_grade or mInfo.unlock_level
    self.m_AutoTarget.max_grade = mData.max_grade or math.min(100,(oWorldMgr:GetServerGrade() + 5))
    self.m_AutoTarget.team_match = mData.team_match or 0
    local mNet = {}
    mNet["target_info"] = self:PackTargetInfo()
    local memlist = self:OnlineMember()
    self:BroadCast(memlist,"GS2CTargetInfo",mNet)
end

function CTeam:SetTeamTarget(iTargetID)
    self.m_AutoTarget = self:PackTargetInfo()
    if self.m_AutoTarget.auto_target == iTargetID then
        return
    end
    self.m_AutoTarget.auto_target = iTargetID or 0
    local mNet = {}
    mNet["target_info"] = self.m_AutoTarget
    local memlist = self:OnlineMember()
    self:BroadCast(memlist,"GS2CTargetInfo",mNet)
end

function CTeam:ResetAutoTeam()
    self.m_AutoTarget = nil
end

function CTeam:AddMem2BlackList(pid, iEndTimeStamp)
    self.m_mBlackList[pid] = iEndTimeStamp or (get_time() + (5 * 60))
end

function CTeam:CheckBlackList()
    local iNow = get_time()
    for pid, iTime in pairs(self.m_mBlackList) do
        if iTime <= iNow then
            self.m_mBlackList[pid] = nil
        end
    end
end

function CTeam:GetLeaderGrade()
    local oWorldMgr = global.oWorldMgr
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self.m_iLeader)
    if oLeader then
        return oLeader:GetGrade()
    end
end

function CTeam:GetTeamAveGrade()
    local oWorldMgr = global.oWorldMgr
    local iGrade = 0
    local iCnt = 0
    for _,oMem in pairs(self.m_lMember) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
        if oPlayer then
            iGrade = iGrade + oPlayer:GetGrade()
            iCnt = iCnt + 1
        end
    end
    local iALV = math.floor(iGrade/iCnt)
    return iALV
end

function CTeam:GetTeamAVG()
    local oWorldMgr = global.oWorldMgr
    local lAVG = {}
    for _,oMem in pairs(self.m_lMember) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
        if oPlayer then
            table.insert(lAVG, oPlayer:GetAveGrade())
        end
    end
    if next(lAVG) then
        return math.max(table.unpack(lAVG))
    end
    return 0
end

function CTeam:GetTeamMaxGrade()
    local oWorldMgr = global.oWorldMgr
    local iGrade = 0
    for _,oMem in pairs(self.m_lMember) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
        if oPlayer then
            if iGrade < oPlayer:GetGrade() then
                iGrade = oPlayer:GetGrade()
            end
        end
    end
    return iGrade
end

function CTeam:GetTeamMinGrade()
    local oWorldMgr = global.oWorldMgr
    local iGrade = 150
    for _,oMem in pairs(self.m_lMember) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
        if oPlayer then
            if iGrade > oPlayer:GetGrade() then
                iGrade = oPlayer:GetGrade()
            end
        end
    end
    return iGrade
end

function CTeam:GetTargetID()
    local mTarget = self.m_AutoTarget
    if mTarget then
        return mTarget["auto_target"]
    end
end

function CTeam:SetAutoMatching()
    local mTarget = self.m_AutoTarget
    if mTarget then
        mTarget.team_match = 1
    end
end

function CTeam:SetUnAutoMatching()
    local mTarget = self.m_AutoTarget
    if mTarget then
        mTarget.team_match = 0
    end
    local oWorldMgr = global.oWorldMgr
    local oLeader =oWorldMgr:GetOnlinePlayerByPid(self:Leader())
    oLeader:Send("GS2CCancelTeamAutoMatch",{})
end

function CTeam:AutoMatching()
    local mTarget = self.m_AutoTarget or {}
    if mTarget and mTarget.team_match and mTarget.team_match == 1 then
        return true
    else
        return false
    end
end

function CTeam:ValidAutoMatchMem(oPlayer)
    if not self:AutoMatching() then
        return false
    end
    local iGrade = oPlayer:GetGrade()
    local iMinGrade = self.m_AutoTarget.min_grade or 0
    local iMaxGrade = self.m_AutoTarget.max_grade or 150
    local mData = res["daobiao"]["autoteam"][self.m_AutoTarget.auto_target or 1001]
    if self:MemberSize() >= mData["match_count"] or iGrade<iMinGrade or iMaxGrade<iGrade then
        return false
    end
    return true
end

function CTeam:AutoMatchEnough()
    local iTargetID = self:GetTargetID()
    if iTargetID then
        local res = require "base.res"
        local mTarget = res["daobiao"]["autoteam"][iTargetID]
        if mTarget then
            if self:OnlineMemberSize() >= mTarget.match_count then
                return true
            end
        end
    end
    return false
end

function CTeam:ValidAutoMatch(pid,mTarget)
    local res = require "base.res"
    local iTargetID = mTarget["auto_target"]
    local mData = res["daobiao"]["autoteam"][iTargetID]
    local oNotifyMgr = global.oNotifyMgr
    if not mData then
        oNotifyMgr:Notify(pid,"活动不存在")
        return false
    end
    if not self:IsLeader(pid) then
        oNotifyMgr:Notify(pid,"只有队长才可以设置哦")
        return false
    end
    local iMaxCnt = mData["match_count"]
    if self:TeamSize() >= iMaxCnt then
        oNotifyMgr:Notify(pid,"队伍人数已满，无法自动匹配")
        return false
    end
    return true
end

function CTeam:StartAutoMatch(pid, mTarget)
    local iTargetID = mTarget["auto_target"]
    self:SetAutoMatchTarget(mTarget)
    local mArgs = self:PackAutoTeamInfo()
    interactive.Send(".autoteam","team","TeamStartAutoMatch",{targetid = iTargetID, teamid = self.m_ID, team_info = mArgs})
end

function CTeam:CancleAutoMatch(pid)
    local iTargetID = self:GetTargetID()
    if iTargetID and self:AutoMatching() then
        self:SetUnAutoMatching()
        interactive.Send(".autoteam","team","CancleTeamAutoMatch", {targetid = iTargetID, teamid = self.m_ID})
        local mNet = {}
        mNet["target_info"] = self:PackTargetInfo()
        local memlist = self:OnlineMember()
        self:BroadCast(memlist, "GS2CTargetInfo", mNet)
    end
end

function CTeam:PackTargetInfo()
    local mTarget = self.m_AutoTarget
    if not mTarget then
        mTarget = self:DefaultTargetInfo()
    end
    return mTarget
end

function CTeam:GetLevelTarget()
    if self.m_AutoTarget then
        return self.m_AutoTarget.min_grade,self.m_AutoTarget.max_grade
    else
        local res = require "base.res"
        local mData = res["daobiao"]["autoteam"][0]
        local oWorldMgr = global.oWorldMgr
        return mData.unlock_level or 0,oWorldMgr:GetServerGrade() + 8
    end
end

function CTeam:DefaultTargetInfo()
    local oWorldMgr = global.oWorldMgr
    local iTargetID = 0
    local res = require "base.res"
    local mData = res["daobiao"]["autoteam"][iTargetID]
    local mTarget = {}
    mTarget.auto_target = iTargetID
    mTarget.min_grade = mData.unlock_level
    mTarget.max_grade = oWorldMgr:GetServerGrade() + 8
    mTarget.team_match = 0

    return mTarget
end

function CTeam:NotActive(pid)
    local mArgs = {}
    mArgs["active"] = 0
    for _, oMem in pairs(self.m_lMember) do
        oMem:Update(mArgs)
    end
end

function CTeam:OnUpGrade(oPlayer)
    if self.m_iLeader == oPlayer.m_iPid then
        self:OnLeaderChange()
    end
end

function CTeam:LeaderSleep(oPlayer,iStatus,bForce)
    if not self:IsLeader(oPlayer:GetPid()) then
        return
    end
    if iStatus == 1 then
        self:ShowTakeLeaderWnd(bForce)
    elseif iStatus == 2 then
        self:CloseTakeLeaderWnd()
    end
end

function CTeam:ShowTakeLeaderWnd(bForce)
    if self:MemberSize() < 2 then
        return
    end
    if self.m_iLastCheckTime and (get_time() - self.m_iLastCheckTime) < 30 then
        return
    end
    self.m_iLastCheckTime = get_time()
    local oWorldMgr = global.oWorldMgr
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(self:Leader())
    local oSceneMgr = global.oSceneMgr
    local oScene = oLeader.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("bantakeleader") then
        return
    end

    local oCbMgr = global.oCbMgr
    local mNet = {
        sContent = "队长当前无反应，是否接管队长？",
        sConfirm = "接管",
        sCancle = "取消",
    }
    local iTeamID = self.m_ID
    local mNet1 = oCbMgr:PackConfirmData(nil, mNet)
    local func = function(oResponser,mData)
            local oTeamMgr = global.oTeamMgr
            local oTeam = oTeamMgr:GetTeam(iTeamID)
            if not oTeam then
                return
            end
            oTeam:_TakeLeaderScript1(oResponser,mData,bForce)
        end
    self.m_mSessionIdx = {}
    for _,oMem in pairs(self.m_lMember) do
        if not self:IsLeader(oMem.m_ID) then
            local iSessionIdx = oCbMgr:SetCallBack(oMem.m_ID,"GS2CConfirmUI",mNet1,nil,func)
            self.m_ConfirmTakeLeader = true
            self.m_mSessionIdx[oMem.m_ID] = iSessionIdx
        end
    end
end

function CTeam:_TakeLeaderScript1(oPlayer,mData,bForce)
    if not self.m_ConfirmTakeLeader then
        return
    end

    local iAnswer = mData.answer
    if iAnswer == 1 then
        self:CloseTakeLeaderWnd()
        local oLeader = global.oWorldMgr:GetOnlinePlayerByPid(self:Leader())
        if (not oLeader or not oLeader:IsDull(80) ) and not bForce then
            return
        end
        handleteam.TrueTakeOverLeader(oPlayer)
    else
        local mSessionIdx = self.m_mSessionIdx or {}
        mSessionIdx[oPlayer.m_iPid] = nil
    end
end

function CTeam:CloseTakeLeaderWnd()
    if not self.m_ConfirmTakeLeader then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oUIMgr = global.oUIMgr
    self.m_ConfirmTakeLeader = false
    local mSessionIdx = self.m_mSessionIdx or {}
    for iMemId,iSessionIdx in pairs(mSessionIdx) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(iMemId)
        if oMem then
            oUIMgr:GS2CCloseConfirmUI(oMem, iSessionIdx)
        end
    end
    self.m_mSessionIdx = nil
end

function CTeam:EscapeWar(iPid)
    if #self.m_lMember > 1 then
        local oWorldMgr = global.oWorldMgr
        for i = 2,#self.m_lMember do
            local oMem = self.m_lMember[i]
            local oMemObj = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
            if oMemObj then
                if oMemObj.m_oActiveCtrl:GetInfo("auto_targetid") == 1 then
                    self:Leave(oMem.m_ID)
                end
            end
        end
        self:ShortLeave(iPid)
    end
end

function CTeam:AddWarEndFunc(func)
    if not self.m_mWarEndFunc then
        self.m_mWarEndFunc = {}
    end
    table.insert(self.m_mWarEndFunc,{func})
end

function CTeam:WarFightEnd(mArgs)
    if self.m_mWarEndFunc and #self.m_mWarEndFunc > 0 then
        for i = 1,#self.m_mWarEndFunc do
            local func = table.unpack(self.m_mWarEndFunc[1])
            func(mArgs)
            table.remove(self.m_mWarEndFunc,1)
        end
    end
end

function CTeam:HasMemInWarResultWnd()
    local oInterfaceMgr = global.oInterfaceMgr
    local iType = gamedefines.INTERFACE_TYPE.WAR_RESULT
    local mPlayers = oInterfaceMgr:GetFacePlayers(iType)
    if table_count(mPlayers) >= 1 then
        for _,oMem in pairs(self.m_lMember) do
            if mPlayers[oMem.m_ID] then
                return true,oMem.m_ID
            end
        end
    end
    return false
end

function CTeam:WarBattleCmd(pid,iOp)
    local obj = self:GetMember(pid)
    if not obj then
        return
    end
    if iOp == 1 then
        obj:SetBattleCommand(1)
    else
        obj:SetBattleCommand(0)
    end
end

function CTeam:InWarBattleCmd(pid)
    local obj = self:GetMember(pid)
    if not obj then
        return 0
    end
    return obj:InBattleCommand()
end

function CTeam:AddTeamTask(oTask)
    self.m_mTask = self.m_mTask or {}
    self.m_mTask[oTask.m_ID] = oTask
    local lMem = self:GetTeamMember()
    for _,iPid in pairs(lMem) do
        oTask:EnterTeam(iPid,1)
    end
end

function CTeam:RemoveTeamTask(oTask)
    if self.m_mTask and self.m_mTask[oTask.m_ID] then
        self.m_mTask[oTask.m_ID] = nil
    end
end

function CTeam:GetTeamTask(iTaskId)
    if self.m_mTask and self.m_mTask[iTaskId] then
        return self.m_mTask[iTaskId]
    end
    return
end

function CTeam:NotifyAllMem(sMsg)
    local oWorldMgr = global.oWorldMgr
    for _,oMem in ipairs(self.m_lMember) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(oMem.m_ID)
        if oPlayer then
            oPlayer:NotifyMessage(sMsg)
        end
    end
end
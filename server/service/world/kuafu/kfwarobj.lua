--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local warobj = import(service_path("warobj"))

function NewWarMgr(...)
    local o = CWarMgr:New(...)
    return o
end

function NewWar(...)
    local o = CWar:New(...)
    return o
end


CWarMgr = {}
CWarMgr.__index = CWarMgr
inherit(CWarMgr, warobj.CWarMgr)

function CWarMgr:New(lWarRemote)
    local o = super(CWarMgr).New(self,lWarRemote)
    return o
end

function CWarMgr:Release()
    super(CWarMgr).Release(self)
end

function CWarMgr:GetPlayerObject(iPid)
    return global.oKFMgr:GetObject(iPid)
end




function CWarMgr:OnLogin(oPlayer, bReEnter)
    if bReEnter then
        self:ReEnterWar(oPlayer)
    end
end

function CWarMgr:CreateWar(mInfo)
    local id = self:DispatchSceneId()
    local oWar = NewWar(id, mInfo)
    oWar:ConfirmRemote()
    self.m_mWars[id] = oWar
    return oWar
end

function CWarMgr:ReEnterWar(oPlayer)
    local oNowWar = oPlayer:GetNowWar()
    if not oNowWar then
        return {errcode = gamedefines.ERRCODE.ok}
    end
    oNowWar:ReEnterPlayer(oPlayer)
    return {errcode = gamedefines.ERRCODE.ok}
end

function CWarMgr:LeaveWar(oPlayer, bForce)
    local oNowWar = oPlayer:GetNowWar()
    if not oNowWar then
        return {errcode = gamedefines.ERRCODE.ok}
    end
    if not bForce then
        if not oNowWar:VaildLeave(oPlayer) then
            return {errcode = gamedefines.ERRCODE.common}
        end
    end
    oNowWar:LeavePlayer(oPlayer)
    return {errcode = gamedefines.ERRCODE.ok}
end

function CWarMgr:EnterWar(oPlayer, iWarId, mInfo, bForce)
    local oNewWar = self:GetWar(iWarId)
    assert(oNewWar, string.format("EnterWar error %d", iWarId))
    local mCode = self:CheckLeaveWar(oPlayer,bForce)
    if mCode then
        return mCode
    end

    oNewWar:EnterPlayer(oPlayer, mInfo)
    local mData = oNewWar:PackPartnerFightData(oPlayer,mInfo)
    if #mData > 0 then
        self:PreparePartner(iWarId,{data = mData, camp_id = mInfo.camp_id,owner_id = oPlayer:GetPid()})
    end

    return {errcode = gamedefines.ERRCODE.ok}
end

function CWarMgr:RemoteEvent(sEvent, mData)
    local oKFMgr = global.oKFMgr
    local mPlayers = {}
    if sEvent == "remote_leave_player" then
        self:RemoteLeavePlayer(mData)
    elseif sEvent == "remote_war_end" then
        self:RemoteWarEnd(mData)
    end
    return true
end

function CWarMgr:Send2RemoteEvent(mPlayers,sEvent,mData)
    local oKFMgr = global.oKFMgr
    for _,iPid in pairs(mPlayers) do
        oKFMgr:Send2GSWorld(iPid,"RemoteEvent",{event=sEvent,data=mData,pid=iPid})
    end
end

function CWarMgr:RemoteWarEnd(mData)
    local iWarId = mData.war_id
    local mArgs = mData.war_info
    local oWar = self:GetWar(iWarId)
    local mPlayers = {}
    if oWar then
        mPlayers = oWar:GetPlayers()
        oWar:CalWarDuration()
        oWar:WarEndCallback(mArgs)
    end
    self:RemoveWar(iWarId)
    self:Send2RemoteEvent(mPlayers,"remote_war_end",mData)
end

function CWarMgr:RemoteLeavePlayer(mData)
    super(CWarMgr).RemoteLeavePlayer(self,mData)
    local iPid = mData.pid
    self:Send2RemoteEvent({iPid,},"remote_leave_player",mData)
end

function CWarMgr:OnLeaveWar(oPlayer,mData)
end

function CWarMgr:RecordWarFilm(oWar,mFileData)
end


CWar = {}
CWar.__index = CWar
inherit(CWar, warobj.CWar)

function CWar:New(id, mInfo)
    local o = super(CWar).New(self, id, mInfo)
    local mRemoteArgs = o.m_mRemoteArgs or {}
    mRemoteArgs.worldaddr = MY_ADDR
    o.m_mRemoteArgs = mRemoteArgs
    o.m_mJoinPlayers = {}
    return o
end

function CWar:OnRelease()
    self.m_mJoinPlayers = {}
    super(CWar).OnRelease(self)
end

function CWar:VaildLeave(oPlayer)
    return true
end

function CWar:VaildEnter(oPlayer)
    return true
end

function CWar:GetPlayers()
    return table_key_list(self.m_mJoinPlayers)
end

function CWar:RemoteLeavePlayer(oPlayer)
    local iPid = oPlayer:GetPid()
    if self.m_mPlayers[iPid] then
        self.m_mPlayers[iPid] = nil
        self.m_mCampPlayers[iPid] = nil
    end
    return true
end

function CWar:LeavePlayer(oPlayer)
    local iPid = oPlayer:GetPid()
    if self.m_mPlayers[iPid] then
        self.m_mPlayers[iPid] = nil
        self.m_mCampPlayers[iPid] = nil
        interactive.Send(self.m_iRemoteAddr, "war", "LeavePlayer", {war_id = self.m_iWarId, pid = iPid})
    elseif self.m_mObservers[iPid] then
        self.m_mObservers[iPid] = nil
        interactive.Send(self.m_iRemoteAddr, "war", "LeaveObserver", {war_id = self.m_iWarId, pid = iPid})
    else
        return false
    end
    return true
end

function CWar:OnLeaveWarTrim(oPlayer,mData)
end

function CWar:EnterPlayer(oPlayer, mInfo)
    oPlayer:SetNowWarInfo({
        now_war = self.m_iWarId,
    })
    local iPid = oPlayer:GetPid()
    local mData = self:PackPlayerWarInfo(oPlayer)

    if not self:GetData("ignore_partner") then
        local mWarData =  self:PackCurrentPartner(oPlayer,mInfo)
        if mWarData then
            local mPartnerData = {
                partnerdata = mWarData,
            }
            mData.partner = mPartnerData
            self.m_mEnterPartner[oPlayer:GetPid()] = mWarData["parid"]
        end
    end


    mData["serverkey"] = oPlayer.m_Where
    if self:IsPVEWar() then
        mData["auto_skill_switch"] = 1
    end
    if self:GetData("close_auto_skill") then
        mData["auto_skill_switch"] = nil
    elseif self:GetData("open_auto_skill") then
        mData["auto_skill_switch"] = 1
    end

    local iCamp = mInfo.camp_id
    self.m_mPlayers[iPid] = true
    self.m_mJoinPlayers[iPid] = true
    self.m_mCampPlayers[iPid] = iCamp
    local iEnemyCamp = self:EnemyCamp(iCamp)
    self:GS2CShowWar(oPlayer)

    interactive.Send(self.m_iRemoteAddr, "war", "EnterPlayer",
        {war_id = self.m_iWarId, pid = iPid, data = mData, camp_id = mInfo.camp_id})
    return true
end

function CWar:ReEnterPlayer(oPlayer)
    local iPid = oPlayer:GetPid()
    local iCamp = self.m_mCampPlayers[iPid] or 1
    local iEnemyCamp = self:EnemyCamp(iCamp)
    local mInfo = self:GetData("remote_args",{})
    local mArgs = mInfo[iPid] or {}
    self:GS2CShowWar(oPlayer,mArgs)
    interactive.Send(self.m_iRemoteAddr, "war", "ReEnterPlayer", {war_id = self.m_iWarId, pid = iPid})
    return true
end


function CWar:CalTeamWLV()
    local mFightCnt = self:GetData("TeamFightCnt",{})
    local iFightCnt = 0
    local iFightGrade = 0
    local oKFMgr = global.oKFMgr
    for iPid,iCnt  in pairs(mFightCnt) do
        local oPlayer = oKFMgr:GetObject(iPid)
        if oPlayer then
            local iGrade = oPlayer:GetGrade()
            iFightCnt = iFightCnt + iCnt
            iFightGrade = iFightGrade + iGrade * iCnt
        end
    end
    if iFightCnt > 0 then
        return math.floor(iFightGrade/iFightCnt)
    else
        return 0
    end
end


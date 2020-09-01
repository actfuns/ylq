--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local colorstring = require "public.colorstring"



local gamedefines = import(lualib_path("public.gamedefines"))

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
inherit(CWarMgr, logic_base_cls())

function CWarMgr:New(lWarRemote)
    local o = super(CWarMgr).New(self)
    o.m_iDispatchId = 0
    o.m_mWars = {}
    o.m_iSelectHash = 1
    o.m_lWarRemote = lWarRemote
    return o
end

function CWarMgr:Release()
    for _, v in pairs(self.m_mWars) do
        baseobj_safe_release(v)
    end
    self.m_mWars = {}
    super(CWarMgr).Release(self)
end

function CWarMgr:DispatchSceneId()
    self.m_iDispatchId = self.m_iDispatchId + 1
    return self.m_iDispatchId
end

function CWarMgr:GetPlayerObject(iPid)
    return global.oWorldMgr:GetOnlinePlayerByPid(iPid)
end


function CWarMgr:SelectRemoteWar()
    local iSel = self.m_iSelectHash
    if iSel >= #self.m_lWarRemote then
        self.m_iSelectHash = 1
    else
        self.m_iSelectHash = iSel + 1
    end
    return self.m_lWarRemote[iSel]
end

function CWarMgr:GetRemoteAddr()
    return self.m_lWarRemote
end

function CWarMgr:NewWar(id,mInfo)
    return NewWar(id, mInfo)
end

function CWarMgr:CreateWar(mInfo)
    local id = self:DispatchSceneId()
    local oWar = self:NewWar(id, mInfo)
    oWar:ConfirmRemote()
    self:SetWar(id,oWar)
    return oWar
end

function CWarMgr:SetWar(id,oWar)
    self.m_mWars[id] = oWar
end

function CWarMgr:GetWar(id)
    return self.m_mWars[id]
end

function CWarMgr:RemoveWar(id)
    local oWar = self.m_mWars[id]
    if oWar then
        self.m_mWars[id] = nil
        baseobj_delay_release(oWar)
    end
end

function CWarMgr:OnDisconnected(oPlayer)
    local oNowWar = oPlayer:GetNowWar()
    if oNowWar then
        oNowWar:NotifyDisconnected(oPlayer)
    end
end

function CWarMgr:OnLogout(oPlayer)
    self:LeaveWar(oPlayer, true)
end

function CWarMgr:OnLogin(oPlayer, bReEnter)
    if bReEnter then
        self:ReEnterWar(oPlayer)
    end
end

function CWarMgr:ReEnterWar(oPlayer)
    local oNowWar = oPlayer:GetNowWar()
    if oNowWar then
        local iPid = oPlayer:GetPid()
        if not oNowWar:IsObserver(iPid) then
            oNowWar:ReEnterPlayer(oPlayer)
        elseif oNowWar.m_IsWarFilm then
            self:LeaveWar(oPlayer,false)
        else
            local mArgs = {
                observer_view = oNowWar:GetObserverCamp(iPid)
            }
            if oNowWar:GetData("war_film_id") then
                mArgs.war_id = oNowWar:GetData("war_film_id")
                mArgs.war_film = true
            end
            oNowWar:EnterObserver(oPlayer,mArgs)
        end
    end
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

function CWarMgr:CheckLeaveWar(oPlayer,bForce)
    local oNowWar = oPlayer:GetNowWar()
    if not bForce then
        if oNowWar and not oNowWar:VaildLeave(oPlayer) then
            return {errcode = gamedefines.ERRCODE.common}
        end
        if not oNewWar:VaildEnter(oPlayer) then
            return {errcode = gamedefines.ERRCODE.common}
        end
    end
    if oNowWar then
        oNowWar:LeavePlayer(oPlayer)
    end
end

function CWarMgr:ObserverEnterWar(oPlayer, iWarId,mArgs)
    mArgs = mArgs or {}
    local oNewWar = self:GetWar(iWarId)
    assert(oNewWar, string.format("ObserverEnterWar err %d", iWarId))
    local oNowWar = oPlayer:GetNowWar()
    if oNowWar then
        return {errcode = gamedefines.ERRCODE.common}
    end

    if oNewWar then
        oNewWar:EnterObserver(oPlayer,mArgs)
    end
    return {errcode = gamedefines.ERRCODE.ok}
end

function CWarMgr:PrepareWar(iWarId, mInfo)
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar:WarPrepare(mInfo)
    end
end

function CWarMgr:PrepareRomWar(iWarId,mInfo)
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar:PrepareRomWar(mInfo)
    end
end

function CWarMgr:PreparePartner(iWarId,mInfo)
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar:PreparePartner(mInfo)
    end
end

function CWarMgr:StartWar(iWarId, mInfo)
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar:RecordStartTime()
        oWar:WarStart(mInfo)
    end
end

function CWarMgr:StartWarConfig(iWarId,mInfo)
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar:RecordStartTime()
        oWar:StartWarConfig(mInfo)
    end
end

function CWarMgr:RemoteEvent(sEvent, mData)
    if sEvent == "remote_leave_player" then
        self:RemoteLeavePlayer(mData)
    elseif sEvent == "remote_war_end" then
        self:RemoteWarEnd(mData)
    elseif sEvent == "remote_end_warfilm" then
        self:RemoteEndWarFilm(mData)
    elseif sEvent == "remote_serial_war" then
        self:RemoteSerialWar(mData)
    elseif sEvent == "remote_leave_observer" then
        self:RemoteLeaveObserver(mData)
    elseif sEvent == "remote_config_partner" then
        --
    elseif sEvent == "remote_outfight_partner" then
        self:RemoteOutFightPartner(mData)
    end
    return true
end


function CWarMgr:RemoteLeavePlayer(mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local oPlayer = self:GetPlayerObject(iPid)
    if oPlayer then
        local oNowWar = oPlayer:GetNowWar()
        if oNowWar and oNowWar:GetWarId() == iWarId then
            local iCamp = oNowWar:GetCampId(oPlayer:GetPid())
            oNowWar:RemoteLeavePlayer(oPlayer)
            if mData.escape then
                oNowWar:EscapeCallBack(mData)
                oNowWar:AddEscapeCnt(iCamp)
            end
            oNowWar:OnLeaveWarTrim(oPlayer,mData)
        end
        self:OnLeaveWar(oPlayer,mData)
    end
end

function CWarMgr:RemoteWarEnd(mData)
    local iWarId = mData.war_id
    local mArgs = mData.war_info
    local mFileData = mArgs.war_film_data or {}
    local oWar = self:GetWar(iWarId)
    if table_count(mFileData) > 0 then
        local oFilm = self:RecordWarFilm(oWar,mFileData)
        if oFilm then
            mArgs.war_film_id = oFilm:GetFilmId()
        end
    end
    if oWar then
        oWar:AddFriendDegree(mArgs)
        oWar:CalWarDuration()
        oWar:WarEndCallback(mArgs)
    end
    self:RemoveWar(iWarId)
end

function CWarMgr:RecordWarFilm(oWar,mFileData)
    local iWarType
    local iLineUp
    if oWar then
        iWarType = oWar.m_iWarType
        iLineUp = oWar.m_iLineUp
    end
    local oWarFilmMgr = global.oWarFilmMgr
    return oWarFilmMgr:AddWarFilm(mFileData,{war_type =iWarType,lineup = iLineUp})
end



function CWarMgr:RemoteEndWarFilm(mData)
    local iWarId = mData.war_id
    local mArgs = mData.war_info
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar:WarEndCallback(mArgs)
    end
    self:RemoveWar(iWarId)
end

function CWarMgr:RemoteSerialWar(mData)
        local iWarId = mData.war_id
        local oWar = self:GetWar(iWarId)
        if oWar then
            oWar:SerialWarCallback(mData)
        end
end

function CWarMgr:RemoteLeaveObserver(mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local oPlayer = self:GetPlayerObject(iPid)
    if oPlayer then
        local oNowWar = oPlayer:GetNowWar()
        if oNowWar and oNowWar:GetWarId() == iWarId then
            oNowWar:RemoteLeaveObserver(oPlayer)
        end
        local oTeam = oPlayer:HasTeam()
        if oTeam then
            oTeam:WarFightEnd({bLeaveObserver = true,pid = iPid})
        end
    end
end

function CWarMgr:RemoteOutFightPartner(mData)
    local iPid = mData.pid
    local iWarId = mData.war_id
    local lPartnerId = mData.partner_list
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar.m_OutFightPartner = oWar.m_OutFightPartner or {}
        oWar.m_OutFightPartner[iPid] = lPartnerId
    end
end

function CWarMgr:OnLeaveWar(oPlayer,mData)
end

function CWarMgr:SetWarEndCallback(iWarId,fCallback)
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar:SetWarEndCallback(fCallback)
    end
end

function CWarMgr:SetSerialWarCallback(iWarId,fCallback)
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar:SetSerialWarCallback(fCallback)
    end
end

function CWarMgr:SetEscapeCallBack(iWarId, fCallback)
    local oWar = self:GetWar(iWarId)
    if oWar then
        oWar:SetEscapeCallBack(fCallback)
    end
end


CWar = {}
CWar.__index = CWar
inherit(CWar, logic_base_cls())

function CWar:New(id, mInfo)
    local o = super(CWar).New(self)
    o.m_iWarId = id
    o.m_sRemoteWarType = mInfo.remote_war_type or ""
    o.m_iRemoteAddr = nil
    o.m_mPlayers = {}
    o.m_mObservers = {}
    o.m_mEnterPartner = {}
    o.m_fWarEndCallback = nil
    o.m_fSerialWarCallback = nil
    o.m_iWarType = mInfo.war_type or gamedefines.WAR_TYPE.NPC_TYPE
    o.m_iLineUp = mInfo.lineup or 0
    o.m_IsWarFilm = mInfo.war_film
    o.m_bIsPVPWar = mInfo.pvpflag
    o.m_mCampPlayers = {}
    o.m_mRemoteArgs = mInfo.remote_args or {}
    o.m_mData = {}
    return o
end

function CWar:InitAttr()
end


function CWar:IsPVPWar()
    return self.m_bIsPVPWar or self.m_iWarId == gamedefines.WAR_TYPE.PVP_TYPE
end

function CWar:IsPVEWar()
    return not self:IsPVPWar()
end

function CWar:OnRelease()
    interactive.Send(self.m_iRemoteAddr, "war", "RemoveRemote", {war_id = self.m_iWarId})
end

function CWar:Release()
    self:OnRelease()
    super(CWar).Release(self)
end

function CWar:GetWarId()
    return self.m_iWarId
end

function CWar:ConfirmRemote()
    local oWarMgr = global.oWarMgr
    local iRemoteAddr = oWarMgr:SelectRemoteWar()
    self.m_iRemoteAddr = iRemoteAddr
    local mRemote = self.m_mRemoteArgs
    interactive.Send(iRemoteAddr, "war", "ConfirmRemote", {war_id = self.m_iWarId,
        war_type = self.m_sRemoteWarType,
        remote_args = {
            remote = self.m_mRemoteArgs,
            extra_arg = {pvpflag = self.m_bIsPVPWar,}
        },
        })
end

function CWar:VaildLeave(oPlayer)
    return true
end

function CWar:VaildEnter(oPlayer)
    return true
end

function CWar:RemoteLeavePlayer(oPlayer)
    local iPid = oPlayer:GetPid()
    self:OnLeavePlayer(oPlayer)
    if self.m_mPlayers[iPid] then
        self.m_mPlayers[iPid] = nil
        self.m_mCampPlayers[iPid] = nil
    end
    return true
end

function CWar:OnLeaveWarTrim(oPlayer,mData)
    local iAutoSkill = mData.auto_skill or 0
    local iAutoSkillSwitch = mData.auto_skill_switch or 0
    oPlayer.m_oActiveCtrl:SetAutoSkill(iAutoSkill)
    oPlayer.m_oActiveCtrl:SetAutoSkillSwitch(iAutoSkillSwitch)
    local mPartnerInfo = mData.partner_info or {}
    oPlayer.m_oPartnerCtrl:SetAutoSkill(mPartnerInfo)
    if mData.escape and oPlayer:HasTeam() then
        local oTeam = oPlayer:HasTeam()
        oTeam:EscapeWar(oPlayer.m_iPid)
    end
end


function CWar:LeavePlayer(oPlayer)
    self:OnLeavePlayer(oPlayer)
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

function CWar:OnLeavePlayer(oPlayer)
end

function CWar:EnterPlayer(oPlayer, mInfo)
    self:OnEnterPlayer(oPlayer,mInfo,"common")
    oPlayer:SetNowWarInfo({
        now_war = self.m_iWarId,
    })
    local mData = self:PackPlayerWarInfo(oPlayer)
    if not self:GetData("ignore_partner") then
        local mWarData =  self:PackCurrentPartner(oPlayer,mInfo)
        if mWarData then
            local mPartnerData = {
                partnerdata = mWarData,
            }
            mData.partner = mPartnerData
            self.m_mEnterPartner[oPlayer:GetPid()] = mWarData["parid"]
            self:AddFightCnt(oPlayer:GetPid())
        end
    end

    if self:IsPVEWar() and oPlayer:GetGrade() >= 4 then
        mData["auto_skill_switch"] = 1
    end
    if self:GetData("close_auto_skill") then
        mData["auto_skill_switch"] = nil
    elseif self:GetData("open_auto_skill") then
        mData["auto_skill_switch"] = 1
    end
    mData["skill_ratio"] = mInfo["skill_ratio"]
    local iCamp = mInfo.camp_id
    self.m_mPlayers[oPlayer:GetPid()] = true
    self.m_mCampPlayers[oPlayer:GetPid()] = iCamp
    local iEnemyCamp = self:EnemyCamp(iCamp)

    interactive.Send(self.m_iRemoteAddr, "war", "EnterPlayer", {war_id = self.m_iWarId, pid = oPlayer:GetPid(), data = mData, camp_id = mInfo.camp_id})
    self:GS2CShowWar(oPlayer,mInfo)
    self:AddFightCnt(oPlayer:GetPid())
    return true
end

function CWar:AddFightCnt(iPid)
    local mFightCnt = self:GetData("TeamFightCnt",{})
    if not mFightCnt[iPid] then
        mFightCnt[iPid] = 0
    end
    mFightCnt[iPid] = mFightCnt[iPid] + 1
    self:SetData("TeamFightCnt",mFightCnt)
end

function CWar:CalTeamWLV()
    local mFightCnt = self:GetData("TeamFightCnt",{})
    local iFightCnt = 0
    local iFightGrade = 0
    local oWorldMgr = global.oWorldMgr
    for iPid,iCnt  in pairs(mFightCnt) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
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

function CWar:OnEnterPlayer(oPlayer,mInfo,sFlag)
end

function CWar:PackCurrentPartner(oPlayer,mInfo)
    return {}
end

function CWar:PackPlayerWarInfo(oPlayer)
    return oPlayer:PackWarInfo()
end

function CWar:ReEnterPlayer(oPlayer)
    self:OnReEnterPlayer(oPlayer)
    local iCamp = self.m_mCampPlayers[oPlayer:GetPid()] or 1
    local iEnemyCamp = self:EnemyCamp(iCamp)
    local mInfo = self:GetData("remote_args",{})
    local mArgs = mInfo[oPlayer:GetPid()] or {}
    self:GS2CShowWar(oPlayer,mArgs)
    interactive.Send(self.m_iRemoteAddr, "war", "ReEnterPlayer", {war_id = self.m_iWarId, pid = oPlayer:GetPid()})
    return true
end

function CWar:OnReEnterPlayer(oPlayer)
end

function CWar:EnterObserver(oPlayer,mArgs)
    self:OnEnterObserver(oPlayer)
    oPlayer:SetNowWarInfo({
        now_war = self.m_iWarId,
    })
    local iCamp = mArgs.observer_view or 1
    local lExtraInfo = mArgs.extra_info or {}
    local lEscape = self:GetEscapeList(iCamp)
    for _,mData in pairs(lEscape) do
        table.insert(lExtraInfo,mData)
    end
    mArgs.extra_info = lExtraInfo
    self.m_mObservers[oPlayer:GetPid()] = mArgs.observer_view or 1
    self:GS2CShowWar(oPlayer,mArgs)
    interactive.Send(self.m_iRemoteAddr, "war", "EnterObserver", {war_id = self.m_iWarId, pid = oPlayer:GetPid()})
    return true
end

function CWar:OnEnterObserver(oPlayer)
end


function CWar:GS2CShowWar(oPlayer,mArgs)
    mArgs = mArgs or {}
    local mWarInfo = {
        war_id = mArgs.war_id or self.m_iWarId,
        war_type = mArgs.war_type or self.m_iWarType,
        observer_view = mArgs.observer_view,
        war_flim = mArgs.war_film,
        extra_info = mArgs.extra_info,
        flim_ver = mArgs.flim_ver,
        lineup = mArgs.lineup or self.m_iLineUp,
    }
    local mRecordInfo = self:GetData("remote_args",{})
    mRecordInfo[oPlayer:GetPid()] = mWarInfo
    self:SetData("remote_args",mRecordInfo)
    oPlayer:Send("GS2CShowWar", mWarInfo)
end

function CWar:IsObserver(iPid)
    return self.m_mObservers[iPid]
end

function CWar:GetObserverCamp(iPid)
    return self.m_mObservers[iPid]
end

function CWar:RemoteLeaveObserver(oPlayer)
end

function CWar:EnemyCamp(iCamp)
    local iEnemyCamp = 3 - iCamp
    return iEnemyCamp
end

function CWar:GetCampId(iPid)
    return self.m_mCampPlayers[iPid]
end

function CWar:WarPrepare(mInfo)
    interactive.Send(self.m_iRemoteAddr, "war", "WarPrepare", {war_id = self.m_iWarId, info = mInfo})
    return true
end

function CWar:PrepareRomWar(mInfo)
    interactive.Send(self.m_iRemoteAddr,"war","PrepareRomWar",{war_id = self.m_iWarId,info = mInfo})
end

function CWar:PreparePartner(mInfo)
    interactive.Send(self.m_iRemoteAddr, "war", "PreparePartner",{war_id = self.m_iWarId, info = mInfo})
end

function CWar:WarStart(mInfo)
    interactive.Send(self.m_iRemoteAddr, "war", "WarStart", {war_id = self.m_iWarId, info = mInfo})
    return true
end

function CWar:SendCurrentChat(oPlayer, mData)
    interactive.Send(self.m_iRemoteAddr, "war", "WarChat", {war_id = self.m_iWarId, net = mData})
    return true
end

function CWar:StartWarConfig(mInfo)
    interactive.Send(self.m_iRemoteAddr, "war", "WarStartConfig", {war_id = self.m_iWarId, info = mInfo})
    return true
end

function CWar:NotifyDisconnected(oPlayer)
    interactive.Send(self.m_iRemoteAddr, "war", "NotifyDisconnected", {war_id = self.m_iWarId, pid = oPlayer:GetPid()})
    return true
end

function CWar:Forward(sCmd, iPid, mData)
    if self.m_NetRirectFunc and self.m_NetRirectFunc[sCmd] then
        local f = self.m_NetRirectFunc[sCmd]
        return f(self,iPid,mData)
    else
        interactive.Send(self.m_iRemoteAddr, "war", "Forward", {pid = iPid, war_id = self.m_iWarId, cmd = sCmd, data = mData})
        return true
    end
end

function CWar:TestCmd(sCmd, iPid, mData)
    interactive.Send(self.m_iRemoteAddr, "war", "TestCmd", {pid = iPid, war_id = self.m_iWarId, cmd = sCmd, data = mData})
    return true
end

function CWar:ForceRemoveWar(iWarResult)
    iWarResult = iWarResult or 2
    interactive.Send(self.m_iRemoteAddr, "war", "ForceRemoveWar", {war_id = self.m_iWarId, war_result = iWarResult})
end

function CWar:RemoteSerialWar(mInfo)
    interactive.Send(self.m_iRemoteAddr, "war", "RemoteSerialWar", {war_id = self.m_iWarId, info = mInfo})
end

function CWar:RecordStartTime()
    self.m_WarStartTime = get_time()
end

function CWar:CalWarDuration()
    self.m_WarDuration = get_time() - self.m_WarStartTime
end

function CWar:GetWarDuration()
    return self.m_WarDuration
end

function CWar:SetWarEndCallback(fCallback)
    self.m_fWarEndCallback = fCallback
end

function CWar:WarEndCallback(mInfo)
    if not self.m_fWarEndCallback then
        return
    end
    self.m_fWarEndCallback(mInfo)
end

function CWar:SetSerialWarCallback(fCallback)
    self.m_fSerialWarCallback = fCallback
end

function CWar:SerialWarCallback(mInfo)
    if not self.m_fSerialWarCallback then
        return
    end
    self.m_fSerialWarCallback(mInfo)
end

function CWar:SetEscapeCallBack(fCallback)
    self.m_fEscapeCallBack = fCallback
end

function CWar:EscapeCallBack(mInfo)
    if self.m_fEscapeCallBack then
        self.m_fEscapeCallBack(mInfo)
    end
    self:SolveKajiCallBack(mInfo)
end

function CWar:SolveKajiCallBack(mInfo)
    if self.m_fSolveKaji then
        self.m_fSolveKaji(mInfo)
    end
end


function CWar:GetTeamLeaderGrade()
    return self:GetData("TeamLeaderGrade",0)
end

function CWar:GetTeamWLV()
    return self:GetData("TeamWLV",0)
end

function CWar:GetTeamAveGrade()
    return self:GetData("TeamAveGrade",0)
end

function CWar:GetTeamMaxGrade()
    return self:GetData("TeamMaxGrade",0)
end

function CWar:GetTeamMinGrade()
    return self:GetData("TeamMinGrade",0)
end

function CWar:GetTeamPlayerAVG()
    return self:GetData("TeamPlayerAVG",0)
end

function CWar:GetRemoteAddr()
    return self.m_iRemoteAddr
end

function CWar:SetData(k, v)
    self.m_mData[k] = v
end

function CWar:GetData(k, rDefault)
    return self.m_mData[k] or rDefault
end

function CWar:AddEscapeCnt(iCamp)
    local mEscape = self:GetData("escape_info",{})
    if not mEscape[iCamp] then
        mEscape[iCamp] = 0
    end
    mEscape[iCamp] = mEscape[iCamp] + 1
    self:SetData("escape_info",mEscape)
end

function CWar:GetEscapeList(iCamp)
    local lEscapeInfo = {}
    local mEscape = self:GetData("escape_info",{})
    local iCnt = mEscape[iCamp] or 0
    table.insert(lEscapeInfo,{key = "escape_cnt",value = iCnt})
    local iEnemyCamp = self:EnemyCamp(iCamp)
    local iEnemyCnt = mEscape[iEnemyCamp] or 0
    table.insert(lEscapeInfo,{key = "enemy_escape_cnt",value=iEnemyCnt})
    return lEscapeInfo
end


function CWar:GetPlayerObject(iPid)
    return global.oWarMgr:GetPlayerObject(iPid)
end

function CWar:PackPartnerFightData(oPlayer,mInfo)
end



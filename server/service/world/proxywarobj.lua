--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local colorstring = require "public.colorstring"
local router = require "base.router"

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

function CWarMgr:DispatchSceneId()
    return global.oWarMgr:DispatchSceneId()
end

function CWarMgr:SelectRemoteWar()
end

function CWarMgr:GetRemoteAddr()
    return self.m_lWarRemote
end

function CWarMgr:CreateWar(mInfo,iRemoteWarId,iRemoteAddr,sRemoteWorldAddr)
    local oWarMgr = global.oWarMgr
    local id = self:DispatchSceneId()
    local oWar = NewWar(id, mInfo)
    oWar:ConfirmRemote(iRemoteWarId,iRemoteAddr,sRemoteWorldAddr)
    self:SetWar(id,oWar)
    return oWar
end

function CWarMgr:OnDisconnected(oPlayer)
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
        oNowWar:ReEnterPlayer(oPlayer)
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
    local oNowWar = oPlayer:GetNowWar()
    local mCode = self:CheckLeaveWar(oPlayer,bForce)
    if mCode then
        return mCode
    end

    oNewWar:EnterPlayer(oPlayer, mInfo)
    return {errcode = gamedefines.ERRCODE.ok}
end

function CWarMgr:RemoteLeavePlayer(mData)
        local iWarId = mData.war_id
        local oWorldMgr = global.oWorldMgr
        local oPlayer = self:GetPlayerObject(iPid)
        if oPlayer then
            local oNowWar = oPlayer:GetNowWar()
            if oNowWar and oNowWar:GetRemoteWarId() == iWarId then
                oNowWar:RemoteLeavePlayer(oPlayer)
            end
            oNowWar:OnLeaveWarTrim(oPlayer,mData)
            self:OnLeaveWar(oPlayer,mData)
        end
end

function CWarMgr:RemoteWarEnd(mData)
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local oNowWar = oPlayer:GetNowWar()
            if oNowWar then
                local iWarId = oNowWar:GetWarId()
                self:RemoveWar(iWarId)
            end
        end
end


CWar = {}
CWar.__index = CWar
inherit(CWar, warobj.CWar)

function CWar:New(id, mInfo)
    local o = super(CWar).New(self,id,mInfo)
    o.m_iKFRemoteWarId = nil
    o.m_iKFRemoteAddr = nil
    o.m_sKFRemoteWorldAddr = nil
    o.m_sPlay = mInfo["play"]
    return o
end

function CWar:OnRelease()
end

function CWar:ConfirmRemote(iRemoteWarId,iRemoteAddr,sRemoteWorldAddr)
    self.m_iKFRemoteWarId = iRemoteWarId
    self.m_iKFRemoteAddr = iRemoteAddr
    self.m_sKFRemoteWorldAddr = sRemoteWorldAddr
end

function CWar:GetRemoteWarId()
    return self.m_iKFRemoteWarId
end

function CWar:VaildLeave(oPlayer)
    return true
end

function CWar:VaildEnter(oPlayer)
    return true
end


function CWar:LeavePlayer(oPlayer)
    router.Send("ks", self.m_iKFRemoteAddr, "kuafu", "LeavePlayer",
        {war_id = self.m_iKFRemoteWarId, pid = iPid})
    
    self:OnLeavePlayer(oPlayer)
    return true
end

function CWar:EnterPlayer(oPlayer, mInfo)
    oPlayer:SetNowWarInfo({
        now_war = self.m_iWarId,
    })
    self:OnEnterPlayer(oPlayer,mInfo,"kuafu")
    return true
end

function CWar:ReEnterPlayer(oPlayer)
    global.oKFMgr:Send2KSWorld(self.m_sKFRemoteWorldAddr,"ReEnterWar",{pid=oPlayer:GetPid()})
    self:OnReEnterPlayer(oPlayer)
    return true
end

function CWar:Forward(sCmd, iPid, mData)
    router.Send("ks", self.m_iKFRemoteAddr, "kuafu", "Forward",
        {pid = iPid, war_id = self.m_iKFRemoteWarId, cmd = sCmd, data = mData})
end

function CWar:TestCmd(sCmd, iPid, mData)
    router.Send("ks", self.m_iKFRemoteAddr, "kuafu", "TestCmd",
        {pid = iPid, war_id = self.m_iKFRemoteWarId, cmd = sCmd, data = mData})
    return true
end

function CWar:ForceRemoveWar(iWarResult)
    iWarResult = iWarResult or 2
    router.Send("ks", self.m_iKFRemoteAddr, "kuafu", "ForceRemoveWar",
        {war_id = self.m_iKFRemoteWarId, war_result = iWarResult})
end
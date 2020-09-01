local global = require "global"
local extend = require "base.extend"
local gamedefines = import(lualib_path("public.gamedefines"))
local router = require "base.router"

function NewKuaFuMgr()
    return CKuaFuMgr:New()
end

CKuaFuMgr = {}
CKuaFuMgr.__index = CKuaFuMgr
inherit(CKuaFuMgr, logic_base_cls())

function CKuaFuMgr:New()
    local o = super(CKuaFuMgr).New(self)
    o.m_mPid2WarAddr = {}
    return o
end

function CKuaFuMgr:SetPlayerWarAddr(iPid,iAddr)
    self.m_mPid2WarAddr[iPid] = iAddr
end

function CKuaFuMgr:GetPlayerWarAddr(iPid)
    return self.m_mPid2WarAddr[iPid]
end

function CKuaFuMgr:Send2KSWorld(sService,sFunName,mArgs)
    mArgs = mArgs or {}
    mArgs.serverkey = get_server_key()
    router.Send("ks", sService, "kuafu", "GS2KSForward", {func=sFunName,args=mArgs})
end

function CKuaFuMgr:GetServiceAddr(sGameName)
    if sGameName == "kfequalarena" then
        return ".world1"
    elseif sGameName == "kfarenagame" then
        return ".world2"
    end
end

function CKuaFuMgr:ApplyEnterGame(oPlayer,sGameName)
    local iPid = oPlayer:GetPid()
    local sService = self:GetServiceAddr(sGameName)
    local mWarInfo = {}
    local mPlayerWarInfo = oPlayer:PackWarInfo()
    mPlayerWarInfo.serverkey = get_server_key()
    mWarInfo.playerwarinfo = mPlayerWarInfo

    local mPartnerInfo = {}
    local mFightPartner = oPlayer.m_oPartnerCtrl:GetFightPartner()
    for iPos=1,4 do
        local oPartner = mFightPartner[iPos]
        if oPartner then
            table.insert(mPartnerInfo,{partnerdata = oPartner:PackWarInfo(),})
        end
    end
    mWarInfo.partnerinfo = mPartnerInfo

    self:Send2KSWorld(sService,"ApplyEnterGame",{pid=iPid,name=sGameName,warinfo=mWarInfo})
end

function CKuaFuMgr:EnsureEnterWar(iPid,sGameName,iRemoteWarId,sRemoteaddr)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local sService = self:GetServiceAddr(sGameName)
    local oProxyWarMgr = global.oProxyWarMgr
    local mInfo = {
        war_type = gamedefines.WAR_TYPE.NPC_TYPE,
        remote_war_type = "common",
    }
    local oWar = oProxyWarMgr:CreateWar(mInfo,iRemoteWarId,sRemoteaddr,sService)
    oProxyWarMgr:EnterWar(oPlayer,oWar:GetWarId(),nil,true)
end

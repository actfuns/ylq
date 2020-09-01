--[[
运行gs的跨服管理器
]]

local global = require "global"
local extend = require "base.extend"
local router = require "base.router"

local gamedefines = import(lualib_path("public.gamedefines"))
local proxyobj = import(service_path("kuafuproxy.proxyobj"))


function NewKuaFuMgr()
    return CKuaFuMgr:New()
end

CKuaFuMgr = {}
CKuaFuMgr.__index = CKuaFuMgr
inherit(CKuaFuMgr, logic_base_cls())

function CKuaFuMgr:New()
    local o = super(CKuaFuMgr).New(self)
    o.m_ProxyList = {}
    o.m_DebugSetCnt = 0
    o.m_DebugDelCnt = 0
    return o
end

function CKuaFuMgr:SetProxy(obj)
    self.m_ProxyList[obj:GetPid()] = obj
    self.m_DebugSetCnt = self.m_DebugSetCnt + 1
end

function CKuaFuMgr:GetProxy(iPid)
    return self.m_ProxyList[iPid]
end

function CKuaFuMgr:DeleteProxy(iPid)
    local obj = self.m_ProxyList[iPid]
    if obj then
        self:Send2KSWorld(obj:GetKFService(),"QuitKFGames",{play=obj.m_sMode,pid=iPid})
        self.m_ProxyList[iPid] = nil
        baseobj_safe_release(obj)
        self.m_DebugDelCnt = self.m_DebugDelCnt + 1
    end
end

function CKuaFuMgr:Send2KSWorld(sService,sFunName,mArgs,fRespond)
    mArgs = mArgs or {}
    mArgs.serverkey = get_server_key()
    local mPack = {func=sFunName,args=mArgs}
    if fRespond then
        router.Request("ks", sService, "kuafu", "GS2KSForward", mPack,fRespond)
    else
        router.Send("ks", sService, "kuafu", "GS2KSForward", mPack)
    end
end

function CKuaFuMgr:Send2KFWorldByPid(iPid,sFunName,mArg,fRespond)
    local obj = self:GetProxy(iPid)
    if not obj then
        return
    end
    local m ={
        arg = mArg,
        pid = iPid,
        play = obj.m_sMode,
    }
    self:Send2KSWorld(obj:GetKFService(),sFunName,m)
end

function CKuaFuMgr:ProxyEvent(iPid,cmd,mData)
    local oProxy = self:GetProxy(iPid)
    if oProxy then
        oProxy:KuaFuCmd(cmd,mData)
    end
end



function CKuaFuMgr:JoinKFGame(oPlayer,sPlay,mArg,config)
    assert(not self:GetProxy(oPlayer:GetPid()),string.format("JoinKFGame %s %s %s",oPlayer:GetPid(),oPlayer:GetName(),sPlay))
    mArg = mArg or {}
    config = config or {}
    mArg["play"] = sPlay
    if not mArg["basedata"] then
        mArg["basedata"] = oPlayer:PackKuFuInfo()
    end
    local obj = proxyobj.NewProxy(oPlayer:GetPid(),sPlay)
    self:SetProxy(obj)
    if config["obj"] then
        obj:SetPlayObject(config["obj"])
    end
    obj:OnJoin()
    local iPid = obj:GetPid()
    local func = function(mRecord,mData)
        self:RespondJoinPlayer(iPid,mRecord,mData)
    end
    self:Send2KSWorld(obj:GetKFService(),"JoinKFGames",mArg,func)
end


function  CKuaFuMgr:RespondJoinPlayer(iPid,mRecord,mData)
    local obj = self:GetProxy(iPid)
    if obj then
        obj:KuaFuCmd("OnJoinResult",mData)
    end
end


function CKuaFuMgr:EnsureEnterWar(iPid,sGameName,iRemoteWarId,sRemoteaddr)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local obj = self:GetProxy(iPid)
    assert(oPlayer)
    if not obj then
        return
    end

    local sService = obj:GetKFService()
    local oProxyWarMgr = global.oProxyWarMgr
    local mInfo = {
        war_type = gamedefines.WAR_TYPE.NPC_TYPE,
        remote_war_type = "common",
    }
    local oWar = oProxyWarMgr:CreateWar(mInfo,iRemoteWarId,sRemoteaddr,sService)
    oProxyWarMgr:RegisterRemoteWar(iRemoteWarId,oWar:GetWarId())
    oWar:RecordStartTime()
    obj:OnEnterWar(oWar)
    oProxyWarMgr:EnterWar(oPlayer,oWar:GetWarId(),nil,true)
end

function CKuaFuMgr:OnLogin(oPlayer,bReEnter)
    self:Send2KFWorldByPid(oPlayer:GetPid(),"OnLogin",{reenter = bReEnter})
end

function CKuaFuMgr:OnDisconnected(oPlayer)
    self:Send2KFWorldByPid(oPlayer:GetPid(),"OnDisconnected",{})
end




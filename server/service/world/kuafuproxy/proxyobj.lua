--import module
local skynet = require "skynet"
local global = require "global"

local record = require "public.record"

function NewProxy(...)
    return CProxyObject:New(...)
end

CProxyObject = {}
CProxyObject.__index = CProxyObject
inherit(CProxyObject, logic_base_cls())

local STATUS_WAIT = 1
local STATUS_ERR = 2
local STATUS_OK = 3

function CProxyObject:New(pid,sPlay)
    local o = super(CProxyObject).New(self)
    o.m_iPid = pid
    o.m_sMode = sPlay
    return o
end

function CProxyObject:Release()
    self.m_PlayObject = nil
    super(CProxyObject).Release(self)
end


function CProxyObject:RemoveMe()
    self:CallPlayFun("OnRemoveMe",{pid=self:GetPid()})
    local oKFMgr = global.oKFMgr
    oKFMgr:DeleteProxy(self:GetPid())
end

function CProxyObject:GetMode()
    return self.m_sMode
end

function CProxyObject:GetPid()
    return self.m_iPid
end

function CProxyObject:GetPlayer()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
end

function CProxyObject:SetStatus(i)
    self.m_iStatus = i
end

function CProxyObject:GetStatus()
    return self.m_iStatus
end

function CProxyObject:SetPlayObject(obj)
    self.m_PlayObject = obj
end

function CProxyObject:GetKFService()
    local obj = self.m_PlayObject
    if obj then
        return obj:GetKFService()
    end
    return ".world1"
end

function CProxyObject:CallPlayFun(cmd,data)
    if not self.m_PlayObject then
        return
    end
    local f = self.m_PlayObject.KuafuProxyCmd
    if not f then
        return
    end
    local ok,r = safe_call(f,self.m_PlayObject,self,cmd,data)
    return r
end

function CProxyObject:OnJoin()
    self:SetStatus(STATUS_WAIT)
    local iPid = self:GetPid()
    self:AddTimeCb("JoinGame",60*1000,function ()
        local oKFMgr = global.oKFMgr
        local obj = oKFMgr:GetProxy(iPid)
        if obj and obj:GetStatus() == STATUS_WAIT then
            obj:OnJoinResult(1,{reason="timeout"})
        end
    end)
end

function CProxyObject:OnJoinResult(iCode,mData)
    local oKFMgr = global.oKFMgr
    mData["proxy_code"] = iCode
    if iCode ~= 0 then
        self:SetStatus(STATUS_ERR)
        record.warning(string.format("proxyobj join err %d %d %s",self:GetPid(),iCode,mData["reason"] or ""))
        self:CallPlayFun("JoinResult",mData)
        self:RemoveMe()
        return
    end
    self:SetStatus(STATUS_OK)
    self:CallPlayFun("JoinResult",mData)
end

function CProxyObject:KuaFuCmd(cmd,mData)
    local data= mData["data"]
    local sPlay = mData["play"]
    if sPlay ~= self.m_sMode then
        record.warning(string.format("kuafu proxyobj err mode %d %s %s",self:GetPid(),self.m_sMode,sPlay))
        return
    end
    if cmd == "OnJoinResult" then
        self:OnJoinResult(mData["code"],data)
    elseif cmd == "RequestToDelete" then
        self:RequestToDelete(data)
    elseif cmd == "HBPushCondition" then
        self:HBPushCondition(data)
    else
        self:CallPlayFun(cmd,data)
    end
end

function CProxyObject:HBPushCondition(mData)
    global.oHandBookMgr:PushCondition(self:GetPid(),mData.key,mData.info)
end

function CProxyObject:RequestToDelete(mData)
    local bRm = true
    if self.m_PlayObject and self.m_PlayObject.KuafuProxyCmd then
        bRm = self:CallPlayFun("RequestToDelete",mData)
    end
    if bRm then
        self:RemoveMe()
    end
end

function CProxyObject:OnEnterWar(oWar)
    local m = {war=oWar}
    self:CallPlayFun("EnterWar",m)
end

function CProxyObject:Send2KSPlay(mArg,fRespond,addr)
    local oKFMgr = global.oKFMgr
    local sAddr = addr or self:GetKFService()
    oKFMgr:Send2KSWorld(sAddr,"GS2CKuaFuCmd",mArg,fRespond)
end




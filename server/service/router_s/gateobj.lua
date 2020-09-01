--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local router = require "base.router"
local extype = require "base.extype"
local res = require "base.res"
local record = require "public.record"

function NewGateMgr(...)
    local o = CGateMgr:New(...)
    return o
end

function NewGate(...)
    local o = CGate:New(...)
    return o
end

function NewConnection(...)
    local o = CConnection:New(...)
    return o
end

CConnection = {}
CConnection.__index = CConnection
inherit(CConnection, logic_base_cls())

function CConnection:New(source, handle, ip, port)
    local o = super(CConnection).New(self)
    o.m_iGateAddr = source
    o.m_iHandle = handle
    o.m_sIP = ip
    o.m_iPort = port
    o.m_sServerKey = nil
    o.m_iLastHeartBeatTime = get_time()
    return o
end

function CConnection:GetNetHandle()
    return self.m_iHandle
end

function CConnection:HandleHeartBeat(sServerKey)
    local oGateMgr = global.oGateMgr
    self.m_sServerKey = sServerKey
    oGateMgr:BindConnection2Server(self.m_iHandle, sServerKey)
    self.m_iLastHeartBeatTime = get_time()
    self:SendR2P(router.PROTO_R2P.R2PHeartBeat, {})
end

function CConnection:GetServerKey()
    return self.m_sServerKey
end

function CConnection:GetLastHeartBeatTime()
    return self.m_iLastHeartBeatTime
end

function CConnection:SendR2P(iCmd, mData)
        local l = {
            string.char(iCmd%256),
            skynet.packstring(mData or {}),
        }
        local s = string.pack(">s2", table.concat(l, ""))

        l = {s,}
        local iPow = 0
        for i = 1, 4 do
            table.insert(l, string.char((self.m_iHandle//(2^iPow))%256))
            iPow = iPow + 8
        end
        s = table.concat(l, "")

        skynet.send(self.m_iGateAddr, "zinc" , s)
end


CGate = {}
CGate.__index = CGate
inherit(CGate, logic_base_cls())

function CGate:New(iPort)
    local o = super(CGate).New(self)
    local iAddr = skynet.launch("zinc_gate", "S", skynet.address(MY_ADDR), iPort, extype.ZINC_CLIENT, 10000,0)
    o.m_iAddr = iAddr
    o.m_iPort = iPort
    o.m_mConnections = {}
    return o
end

function CGate:Release()
    for _, v in pairs(self.m_mConnections) do
        baseobj_safe_release(v)
    end
    self.m_mConnections = {}
    super(CGate).Release(self)
end

function CGate:GetConnection(fd)
    return self.m_mConnections[fd]
end

function CGate:AddConnection(oConn)
    self.m_mConnections[oConn.m_iHandle] = oConn
    local oGateMgr = global.oGateMgr
    oGateMgr:SetConnection(oConn.m_iHandle, oConn)

    skynet.send(self.m_iAddr, "text", "forward", oConn.m_iHandle, skynet.address(MY_ADDR), skynet.address(self.m_iAddr))
    skynet.send(self.m_iAddr, "text", "start", oConn.m_iHandle)
end

function CGate:DelConnection(iHandle)
    local oConn = self.m_mConnections[iHandle]
    if oConn then
        self.m_mConnections[iHandle] = nil
        local oGateMgr = global.oGateMgr
        if oConn:GetServerKey() then
            oGateMgr:UnBindConnection2Server(oConn:GetServerKey())
        end
        oGateMgr:SetConnection(iHandle, nil)
        baseobj_delay_release(oConn)
    end
end


CGateMgr = {}
CGateMgr.__index = CGateMgr
inherit(CGateMgr, logic_base_cls())

function CGateMgr:New()
    local o = super(CGateMgr).New(self)
    o.m_mGates = {}
    o.m_mNoteConnections = {}
    o.m_mSk2Handle = {}
    return o
end

function CGateMgr:Release()
    for _, v in pairs(self.m_mGates) do
        baseobj_safe_release(v)
    end
    self.m_mGates = {}
    super(CGateMgr).Release(self)
end

function CGateMgr:Init()
    local f1
    f1 = function ()
            self:DelTimeCb("_CheckHeartBeat")
            self:AddTimeCb("_CheckHeartBeat", 10*1000, f1)
            self:_CheckHeartBeat()
    end
    f1()
end

function CGateMgr:AddGate(oGate)
    self.m_mGates[oGate.m_iAddr] = oGate
end

function CGateMgr:GetGate(iAddr)
    return self.m_mGates[iAddr]
end

function CGateMgr:GetConnection(iHandle)
    return self.m_mNoteConnections[iHandle]
end

function CGateMgr:SetConnection(iHandle, oConn)
    self.m_mNoteConnections[iHandle] = oConn
end

function CGateMgr:KickConnection(iHandle)
    local oConnection = self:GetConnection(iHandle)
    if oConnection then
        skynet.send(oConnection.m_iGateAddr, "text", "kick", oConnection.m_iHandle)
        local oGate = self:GetGate(oConnection.m_iGateAddr)
        if oGate and oGate:GetConnection(iHandle) then
            oGate:DelConnection(iHandle)
        end
    end
end

function CGateMgr:SendR2P(sServerKey, iCmd, mData)
    local iHandle = self.m_mSk2Handle[sServerKey]
    if iHandle then
        local oConnection = self:GetConnection(iHandle)
        if oConnection then
            oConnection:SendR2P(iCmd, mData)
        end
    end
end

function CGateMgr:BindConnection2Server(iHandle, sServerKey)
    self.m_mSk2Handle[sServerKey] = iHandle
end

function CGateMgr:UnBindConnection2Server(sServerKey)
    self.m_mSk2Handle[sServerKey] = nil
end

function CGateMgr:_CheckHeartBeat()
    local iCurrTime = get_time()
    local lv = table_value_list(self.m_mNoteConnections)
    for _, oConnection in ipairs(lv) do
        if iCurrTime - oConnection:GetLastHeartBeatTime() >= 2*60 then
            record.warning(string.format("router_s CGateMgr _CheckHeartBeat ill connection %s %s", oConnection:GetServerKey(), oConnection:GetNetHandle()))
            self:KickConnection(oConnection:GetNetHandle())
        end
    end
end

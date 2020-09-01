--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local extype = require "base.extype"
local res = require "base.res"
local record = require "public.record"

local version = import(lualib_path("public.version"))
local status = import(lualib_path("base.status"))
local gamedefines = import(lualib_path("public.gamedefines"))


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
    return o
end

function CConnection:Release()
    super(CConnection).Release(self)
end

function CConnection:GetHandle()
    return self.m_iHandle
end

function CConnection:Send(sMessage, mData)
    net.Send({gate = self.m_iGateAddr, fd = self.m_iHandle}, sMessage, mData)
end


CGate = {}
CGate.__index = CGate
inherit(CGate, logic_base_cls())

function CGate:New(iPort)
    local o = super(CGate).New(self)
    local iAddr = skynet.launch("zinc_gate", "S", skynet.address(MY_ADDR), iPort, extype.ZINC_CLIENT, 10000, version.XOR_KEY)
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

    local oQRCodeMgr = global.oQRCodeMgr
    oQRCodeMgr:SendCodeToken(oConn)
end

function CGate:DelConnection(iHandle)
    local oConn = self.m_mConnections[iHandle]
    if oConn then
        self.m_mConnections[iHandle] = nil
        baseobj_delay_release(oConn)
        local oGateMgr = global.oGateMgr
        oGateMgr:SetConnection(iHandle, nil)
    end
end


CGateMgr = {}
CGateMgr.__index = CGateMgr
inherit(CGateMgr, logic_base_cls())

function CGateMgr:New()
    local o = super(CGateMgr).New(self)
    o.m_mGates = {}
    o.m_mNoteConnections = {}
    return o
end

function CGateMgr:Release()
    for _, v in pairs(self.m_mGates) do
        baseobj_safe_release(v)
    end
    self.m_mGates = {}
    super(CGateMgr).Release(self)
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
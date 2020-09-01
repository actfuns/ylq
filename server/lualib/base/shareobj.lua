--import module

local skynet = require "skynet"
local stm = require "stm"

local mypack = skynet.pack
local myunpack = skynet.unpack


CShareWriter = {}
CShareWriter.__index = CShareWriter

function CShareWriter:New()
    local o = setmetatable({}, self)
    o.m_oStm = nil
    o.m_bIsDirty = false
    return o
end

function CShareWriter:Init()
    self.m_oStm = stm.new(mypack(self:Pack()))
end

function CShareWriter:Release()
    self.m_oStm = nil
end

function CShareWriter:Pack()
end

function CShareWriter:GenReaderCopy()
    assert(self.m_oStm, "CShareWriter GenReaderCopy fail")
    return stm.copy(self.m_oStm)
end

function CShareWriter:Update()
    assert(self.m_oStm, "CShareWriter Update fail")
    self.m_oStm(mypack(self:Pack()))
end

function CShareWriter:PrepareUpdate()
    self.m_bIsDirty = true
end

function CShareWriter:IsUpdate()
    return self.m_bIsDirty
end

function CShareWriter:CheckUpdate()
    if not self.m_bIsDirty then
        return
    end
    self.m_bIsDirty = false
    self:Update()
end

CShareReader = {}
CShareReader.__index = CShareReader

function CShareReader:New()
    local o = setmetatable({}, self)
    o.m_oStmShadow = nil
    return o
end

function CShareReader:Init(o)
    self.m_oStmShadow = stm.newcopy(o)
    self:Update()
end

function CShareReader:Release()
    self.m_oStmShadow = nil
end

function CShareReader:Update()
    assert(self.m_oStmShadow, "CShareReader Update fail")
    local b, m = self.m_oStmShadow(myunpack)
    if b then
        self:Unpack(m)
    end
end

function CShareReader:Unpack(m)
end

--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))

function NewPartnerMgr(...)
    local o = CPartnerMgr:New(...)
    return o
end

function NewPartnerCtrl(...)
    local o = CPartnerCtrl:New(...)
    return o
end

function NewPartner(...)
    local o = CPartner:New(...)
    return o
end

CPartnerMgr = {}
CPartnerMgr.__index = CPartnerMgr
inherit(CPartnerMgr, logic_base_cls())

function CPartnerMgr:New(lPartnerRemote)
    local o = super(CPartnerMgr).New(self)
    o.m_lPartnerRemote = lPartnerRemote
    return o
end

function CPartnerMgr:Release()
    super(CPartnerMgr).Release(self)
end

function CPartnerMgr:SelectRemotePartner(iPid)
    local l = self.m_lPartnerRemote
    local n = #l
    local i = (iPid % n)
    if i == 0 then
        i = n
    end
    return l[i]
end

function CPartnerMgr:CloseGS()
    for _, iAddr in ipairs(self.m_lPartnerRemote) do
        interactive.Send(iAddr, "partner", "CloseGS", {})
    end
end
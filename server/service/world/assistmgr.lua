--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))

function NewAssistMgr(...)
    local o = CAssistMgr:New(...)
    return o
end

CAssistMgr = {}
CAssistMgr.__index = CAssistMgr
inherit(CAssistMgr, logic_base_cls())

function CAssistMgr:New(lAssistRemote)
    local o = super(CAssistMgr).New(self)
    o.m_lAssistRemote = lAssistRemote
    return o
end

function CAssistMgr:SelectRemoteAssist(iPid)
    local l = self.m_lAssistRemote
    local n = #l
    local i = (iPid % n)
    if i == 0 then
        i = n
    end
    return l[i]
end

function CAssistMgr:GetRemoteAddr()
    return self.m_lAssistRemote
end

function CAssistMgr:CloseGS()
    for _, iAddr in ipairs(self.m_lAssistRemote) do
        interactive.Send(iAddr, "assist", "CloseGS", {})
    end
end
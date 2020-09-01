--import module
local global = require "global"

local uiobj = import(lualib_path("public.uiobj"))

function NewUIMgr()
    local o = CUIMgr:New()
    return o
end

CUIMgr = {}
CUIMgr.__index = CUIMgr
inherit(CUIMgr, uiobj.CUIMgr)

function CUIMgr:New()
    local o = super(CUIMgr).New(self)
    o.m_mRemoteKeep = {}
    return o
end

function CUIMgr:GetSendObj(iPid)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CUIMgr:AddRemoteKeep(iPid,mShow)
    local mKeep = self.m_mRemoteKeep[iPid] or {}
    table.insert(mKeep, mShow)
    self.m_mRemoteKeep[iPid] = mKeep
end

function CUIMgr:GetRemoteKeep(iPid)
    return self.m_mRemoteKeep[iPid] or {}
end

function CUIMgr:ClearRemoteKeep(iPid)
    self.m_mRemoteKeep[iPid] = {}
end
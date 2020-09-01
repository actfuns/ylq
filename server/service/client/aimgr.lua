--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local trapmine = import(service_path("ai/trapmine"))

function NewAIMgr(...)
    local o = CAIMgr:New(...)
    return o
end

CAIMgr = {}
CAIMgr.__index = CAIMgr
inherit(CAIMgr, logic_base_cls())

function CAIMgr:New()
    local o = super(CAIMgr).New(self)
    o.m_mPlayer = {}
    return o
end

function CAIMgr:GetOfflineTrapMineAI(iPid)
    return self.m_mPlayer[iPid]
end

function CAIMgr:StartOfflineTrapmine(iPid,mData)
    local oAI = trapmine.NewTrapmineAI(iPid,mData)
    self.m_mPlayer[iPid] = oAI
    oAI:AIStart()
end

function CAIMgr:StopOfflineTrapmine(iPid)
    local oAI = self.m_mPlayer[iPid]
    if oAI then
        self.m_mPlayer[iPid] = nil
        oAI:AIStop()
        baseobj_delay_release(oAI)
    end
end

function CAIMgr:NotifyEnterWar(iPid)
    local oAI = self.m_mPlayer[iPid]
    if oAI then
        oAI:EnterWar()
    end
end

function CAIMgr:NotifyLeaveWar(iPid)
    local oAI = self.m_mPlayer[iPid]
    if oAI then
        oAI:LeaveWar()
    end
end
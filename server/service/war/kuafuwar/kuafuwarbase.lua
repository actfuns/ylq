--import module
local global = require "global"
local interactive = require "base.interactive"
local record = require "public.record"
local playersend = require "base.playersend"

local basewar = import(service_path("warobj"))

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)


function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "kuafuwarbase"
    return o
end

function CWar:Init(mInfo,mExtra)
    super(CWar).Init(self,mInfo,mExtra)
    self.m_RemoteWorldAddr = mInfo.worldaddr
end

function CWar:Send(iPid,iWid,sMessage,mData)
    local oPlayer = self:GetPlayerWarrior(iPid)
    local sServerKey = oPlayer:GetData("serverkey")
    if sServerKey then
        playersend.KFSend(sServerKey,iPid,sMessage,mData)
    end
end

function CWar:SendRaw(iPid,iWid,sData)
    local oPlayer = self:GetPlayerWarrior(iPid)
    local sServerKey = oPlayer:GetData("serverkey")
    if sServerKey then
        playersend.KFSendRaw(sServerKey,iPid,sData)
    end
end

function CWar:RemoteWorldEvent(sEvent,mData)
    if self.m_RemoteWorldAddr then
        interactive.Send(self.m_RemoteWorldAddr, "war", "RemoteEvent", {event = sEvent, data = mData})
    end
end
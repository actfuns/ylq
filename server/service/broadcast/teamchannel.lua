--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CBaseChannel = import(service_path("basechannel")).CBaseChannel


function NewTeamChannel(...)
    local o = CTeamChannel:New(...)
    return o
end


CTeamChannel = {}
CTeamChannel.__index = CTeamChannel
inherit(CTeamChannel, CBaseChannel)

function CTeamChannel:New()
    local o = super(CTeamChannel).New(self)
    self.m_lTeam = {}
    o.m_iType = gamedefines.BROADCAST_TYPE.TEAM_TYPE
    return o
end
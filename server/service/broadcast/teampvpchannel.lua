--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CBaseChannel = import(service_path("basechannel")).CBaseChannel


function NewTeamPVPChannel(...)
    local o = CTeamPVPChannel:New(...)
    return o
end


CTeamPVPChannel = {}
CTeamPVPChannel.__index = CTeamPVPChannel
inherit(CTeamPVPChannel, CBaseChannel)

function CTeamPVPChannel:New()
    local o = super(CTeamPVPChannel).New(self)
    self.m_lTeam = {}
    o.m_iType = gamedefines.BROADCAST_TYPE.TEAMPVP_TYPE
    return o
end
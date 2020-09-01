--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CBaseChannel = import(service_path("basechannel")).CBaseChannel


function NewWorldChannel(...)
    local o = CWorldChannel:New(...)
    return o
end


CWorldChannel = {}
CWorldChannel.__index = CWorldChannel
inherit(CWorldChannel, CBaseChannel)

function CWorldChannel:New()
    local o = super(CWorldChannel).New(self)
    o.m_iType = gamedefines.BROADCAST_TYPE.WORLD_TYPE
    return o
end

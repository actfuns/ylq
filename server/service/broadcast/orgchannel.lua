--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CBaseChannel = import(service_path("basechannel")).CBaseChannel


function NewOrgChannel(...)
    local o = COrgChannel:New(...)
    return o
end


COrgChannel = {}
COrgChannel.__index = COrgChannel
inherit(COrgChannel, CBaseChannel)

function COrgChannel:New()
    local o = super(COrgChannel).New(self)
    o.m_iType = gamedefines.BROADCAST_TYPE.ORG_TYPE
    return o
end


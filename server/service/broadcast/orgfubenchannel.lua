--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CBaseChannel = import(service_path("basechannel")).CBaseChannel


function NewOrgFuBenChannel(...)
    local o = COrgFuBenChannel:New(...)
    return o
end


COrgFuBenChannel = {}
COrgFuBenChannel.__index = COrgFuBenChannel
inherit(COrgFuBenChannel, CBaseChannel)

function COrgFuBenChannel:New()
    local o = super(COrgFuBenChannel).New(self)
    o.m_iType = gamedefines.BROADCAST_TYPE.ORG_FUBEN
    return o
end


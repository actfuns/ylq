--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CBaseChannel = import(service_path("basechannel")).CBaseChannel


function NewInterfaceChannel(...)
    local o = CInterfaceChannel:New(...)
    return o
end


CInterfaceChannel = {}
CInterfaceChannel.__index = CInterfaceChannel
inherit(CInterfaceChannel, CBaseChannel)

function CInterfaceChannel:New()
    local o = super(CInterfaceChannel).New(self)
    o.m_iType = gamedefines.BROADCAST_TYPE.INTERFACE_TYPE
    return o
end
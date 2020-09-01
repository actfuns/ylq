--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CBaseChannel = import(service_path("basechannel")).CBaseChannel


function NewFieldBossChannel(...)
    local o = CFieldBossChannel:New(...)
    return o
end


CFieldBossChannel = {}
CFieldBossChannel.__index = CFieldBossChannel
inherit(CFieldBossChannel, CBaseChannel)

function CFieldBossChannel:New()
    local o = super(CFieldBossChannel).New(self)
    o.m_iType = gamedefines.BROADCAST_TYPE.FIELD_BOSS
    return o
end


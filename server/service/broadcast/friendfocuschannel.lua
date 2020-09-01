--好友信息广播

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
 
local gamedefines = import(lualib_path("public.gamedefines"))
local CBaseChannel = import(service_path("basechannel")).CBaseChannel


function NewFriendFocusChannel(...)
    local o = CFriendFocusChannel:New(...)
    return o
end


CFriendFocusChannel = {}
CFriendFocusChannel.__index = CFriendFocusChannel
inherit(CFriendFocusChannel, CBaseChannel)

function CFriendFocusChannel:New()
    local o = super(CFriendFocusChannel).New(self)
    o.m_iType = gamedefines.BROADCAST_TYPE.FRIEND_FOCUS_TYPE
    return o
end

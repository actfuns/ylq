--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"
local extend = require "base/extend"

local gamedefines = import(lualib_path("public.gamedefines"))

function NewBaseChannel(...)
    local o = CBaseChannel:New(...)
    return o
end

function NewBaseChannelMember(...)
    local o = CBaseChannelMember:New(...)
    return o
end


CBaseChannel = {}
CBaseChannel.__index = CBaseChannel
inherit(CBaseChannel, logic_base_cls())

function CBaseChannel:New()
    local o = super(CBaseChannel).New(self)
    o.m_iType = gamedefines.BROADCAST_TYPE.BASE_TYPE
    o.m_mMembers = {}
    return o
end

function CBaseChannel:Add(iPid, mInfo)
    local o = self.m_mMembers[iPid]
    if o then
        o:Update(mInfo)
    else
        self.m_mMembers[iPid] = NewBaseChannelMember(mInfo)
    end
end

function CBaseChannel:Del(iPid)
    self.m_mMembers[iPid] = nil
end

function CBaseChannel:Get(iPid)
    return self.m_mMembers[iPid]
end

function CBaseChannel:GetAll()
    return self.m_mMembers
end

function CBaseChannel:GetAmount()
    return table_count(self.m_mMembers)
end

function CBaseChannel:SendRaw(sData, mExclude)
    mExclude = mExclude or {}

    for k, o in pairs(self.m_mMembers) do
        if not mExclude[k] then
            o:SendRaw(sData)
        end
    end
end

function CBaseChannel:Send(sMessage, mData, mExclude)
    local sData = playersend.PackData(sMessage,mData)
    mExclude = mExclude or {}

    for k, o in pairs(self.m_mMembers) do
        if not mExclude[k] then
            o:SendRaw(sData)
        end
    end
end

function CBaseChannel:SendWith(func, mExclude)
    mExclude = mExclude or {}

    for k, o in pairs(self.m_mMembers) do
        if not mExclude[k] then
            local sData = func(o)
            if sData then
                o:SendRaw(sData)
            end
        end
    end
end


CBaseChannelMember = {}
CBaseChannelMember.__index = CBaseChannelMember
inherit(CBaseChannelMember, logic_base_cls())

function CBaseChannelMember:New(mInfo)
    local o = super(CBaseChannelMember).New(self)
    o.m_iPid = mInfo.pid
    return o
end

function CBaseChannelMember:Update(mInfo)
end

function CBaseChannelMember:Send(sMessage, mData)
    playersend.Send(self.m_iPid,sMessage,mData)
end

function CBaseChannelMember:SendRaw(sData)
    playersend.SendRaw(self.m_iPid,sData)
end

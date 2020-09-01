--import module

local global = require "global"
local skynet = require "skynet"

local buffbase = import(service_path("buff/buffbase"))

function NewBuff(...)
    local o = CBuff:New(...)
    return o
end

CBuff = {}
CBuff.__index = CBuff
inherit(CBuff, buffbase.CBuff)


function CBuff:AttrTempAddValue()
    local iRatio  = self.m_mArgs["master_attack"] or 0
    return string.format("{attack=%s}",iRatio)
end



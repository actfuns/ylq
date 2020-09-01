--import module
local global = require "global"
local interactive = require "base.interactive"

local basewar = import(service_path("warobj"))

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)

function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "yjfuben"
    return o
end


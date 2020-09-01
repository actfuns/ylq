--import module
local global = require "global"
local interactive = require "base.interactive"

local basewar = import(service_path("warobj"))

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)

function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "pefuben"
    return o
end

function CWar:ExtendWarEndArg(mArg)
    mArg.m_HasDead = 0
    local mWinWarrior = self:GetWarriorList(1)
    for _,oAction in pairs(mWinWarrior) do
        if oAction:IsDead() then
            mArg.m_HasDead = mArg.m_HasDead + 1
        end
    end
    return mArg
end
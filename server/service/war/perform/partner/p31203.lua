local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))

function NewCPerform(...)
    local o = CPerform:New(...)
    return o
end

CPerform = {}
CPerform.__index = CPerform
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local mArgs = self:GetSkillArgsEnv()
    local iBuffHpRatio = mArgs["hp_ratio"] or 5000
    local iDamageRatio = mArgs["damage_ratio"] or 5000
    oAction:Set("buff_hp_ratio",iBuffHpRatio)
    oAction:Set("buff_damage_ratio",iDamageRatio)
end
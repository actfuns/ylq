local skynet = require "skynet"

local global = require "global"
local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))

function NewCPerform(...)
    local o = CPerform:New(...)
    return o
end

CPerform = {}
CPerform.__index = CPerform
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:DamageRatio()
    local mTarget = self:GetData("PerformTarget",{})
    local iAttackCnt = math.max(#mTarget,1)
    local mArg = self:GetSkillArgsEnv()
    local iRatio = mArg["damage_ratio"] or 1500
    local iDamageRatio = math.floor(iRatio / iAttackCnt)
    return iDamageRatio
end
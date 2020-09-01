--import module

local global = require "global"
local skynet = require "skynet"

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

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnCalDamageRatio(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnCalDamageRatio",self.m_ID,fCallback)
end


function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
    if self:Type() ~= oPerform:Type() then
        return 0
    end
    local mArgs = self:GetSkillArgsEnv()
    local iHPRatio = mArgs["hp_ratio"] or 30
    local iLeftRatio = oVictim:GetHpRatio()
    if iLeftRatio > iHPRatio then
        return 0
    end
    return mArgs["damage_ratio"] or 5000
end

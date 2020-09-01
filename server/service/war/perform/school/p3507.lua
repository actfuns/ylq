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
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local func = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
    end
    oPerformMgr:AddFunction("OnAttack",self.m_ID,func)
end

function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["curse_ratio"]
    if in_random(iRatio,10000) then
        self:ShowPerfrom(oAttack)
        self:Effect_Condition_For_Victim(oVictim,oAttack)
    end
end
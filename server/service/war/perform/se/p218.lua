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
    local fCallback = function (oAttack,oVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamageRatio(oAttack,oVictim,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnCalDamageRatio",self.m_ID,fCallback)

    local fCallback = function (oAction)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnActionEnd(oAction)
        end
        return 0
    end
    oAction:AddFunction("OnActionEnd",self.m_ID,fCallback)

    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnAttack",self.m_ID,fCallback)

end

function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
   return self:GetSkillArgsEnv()["damage_ratio"] or 2000
end


function CPerform:OnActionEnd(oAction)
    local iDamage = oAction:QueryBoutArgs("p218_damage")
    if not iDamage or oAction:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iHit = iDamage * (mArgs["rebound_ratio"] or 2500) / 10000
    self:ShowPerfrom(oAction)
    self:ModifyHp(oAction,oAction,-iHit)
end

function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    oAttack:AddBoutArgs("p218_damage",iDamage)
end




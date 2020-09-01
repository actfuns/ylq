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
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnCalDamage(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnCalDamage",self.m_ID,fCallback)

    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnAttack",self.m_ID,fCallback)

end

function CPerform:OnCalDamage(oAttack,oVictim,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 3000
    if oAttack:QueryBoutArgs("IsCrit") and in_random(iRatio,10000) then
        oAttack:SetBoutArgs("p219_trigger",1)
    end
    return 0
end

function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    if oAttack:IsDead() or oVictim:IsDead() or not oAttack:QueryBoutArgs("p219_trigger") then
        return
    end
    oAttack:SetBoutArgs("p219_trigger",nil)
    local mArgs = self:GetSkillArgsEnv()
    self:ShowPerfrom(oAttack)
    local iHit = ((mArgs["damage_ratio"] or 1500) * oAttack:QueryAttr("attack"))/10000
    self:ModifyHp(oVictim,oAttack,-iHit)
end

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
            return oSkill:OnCalDamage(oAttack,oVictim,iDamage)
        end
        return 0
    end
    oPerformMgr:AddFunction("OnCalDamage",self.m_ID,func)
end

function CPerform:OnCalDamage(oAttack,oVictim,iDamage)
    local mEnv = self:GetSkillArgsEnv()
    local iBiShaRatio = mEnv["bisha_ratio"] or 0
    local iHPRatio = mEnv["hp_ratio"] or 10
    local iAddDamage = 0
    if oVictim:GetHpRatio() < iHPRatio and in_random(iBiShaRatio,10000) and not  oVictim:IsBoss() and not oVictim:GetPerform(1007) then
        iAddDamage = oVictim:GetHp() - iDamage
    end
    if iAddDamage > 0 then
        self:ShowPerfrom(oAttack)
    end
    return iAddDamage
end

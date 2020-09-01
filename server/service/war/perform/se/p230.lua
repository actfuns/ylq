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
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAttacked(oVictim,oAttack,oPerform,iDamage)
        end
    end
    oAction:AddFunction("OnAttacked",self.m_ID,fCallback)
end

function CPerform:OnAttacked(oVictim,oAttack,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 3000
    if not in_random(iRatio,10000) then
        return
    end
    local oWar = oVictim:GetWar()
    if not oWar.m_oRecord:IsAttacked(oVictim,oAttack) then
        return
    end
    self:ShowPerfrom(oVictim)
    local iDamageRatio = mArgs["damage_ratio"] or 10000
    local iAttackedDamage = math.floor(iDamage * iDamageRatio / 10000)
    self:ModifyHp(oAttack,oAttack,-iAttackedDamage)
end
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
            return oSkill:OnCalDamaged(oVictim,oAttack,oPerform,iDamage)
        end
    end
    oAction:AddFunction("OnCalDamaged",self.m_ID,fCallback)
end

function CPerform:OnCalDamaged(oVictim,oAttack,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["damage_ratio"]
    local iDelDamage = math.floor(iDamage * iRatio / 10000)
    self:ShowPerfrom(oVictim,{perform=oPerform})
    return -iDelDamage
end
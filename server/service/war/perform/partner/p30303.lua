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
end

function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
    if oPerform:Type() ~= 30301 then
        return 0
    end
    local iLostHp = oAttack:GetMaxHp() - oAttack:GetHp()
    local iHpRatio = math.floor(iLostHp * 100 / oAttack:GetMaxHp())
    local mArgs = self:GetSkillArgsEnv()
    local iDamageRatio = mArgs["ratio"] or 200
    iDamageRatio = iDamageRatio * iHpRatio
    if iDamageRatio > 0 then
            self:ShowPerfrom(oAttack)
    end
    return iDamageRatio
end
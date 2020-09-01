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
    local fCallback = function (oAttack,oVitim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnReceiveDamage(oAttack,oVitim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnReceiveDamage",self.m_ID,fCallback)

end

function CPerform:OnReceiveDamage(oAttack,oVictim,oPerform,iDamage)
    if iDamage < 1 then
        return 0
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["abnormal_ratio"] or 1000
    local iMaxRatio = mArgs["max_ratio"] or 5000
    local iMinRatio = mArgs["min_ratio"] or 1000
    local iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
    if in_random(iRatio,10000) then
        self:ShowPerfrom(oAttack)
        self:Effect_Condition_For_Victim(oVictim,oAttack)
    end
    return 0
end




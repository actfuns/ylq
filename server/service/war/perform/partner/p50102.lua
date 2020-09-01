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


function CPerform:TruePerform(oAttack,oVictim)
    local oActionMgr = global.oActionMgr
    self.m_CriticalRatio = 0
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,100,3)
    self.m_CriticalRatio = nil
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVictim)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:CallCritRatio(oAttack,oVictim)
        end
        return 0
    end
    oAction:AddFunction("CallCritRatio",self.m_ID,fCallback)

    local fCallback = function (oAttack,oVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamageRatio(oAttack,oVictim,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnCalDamageRatio",self.m_ID,fCallback)
end


function CPerform:CallCritRatio(oAttack,oVictim)
    local iRatio = self.m_CriticalRatio or 0
    self.m_CriticalRatio = 0
    return iRatio
end

function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
    if  oAttack:QueryBoutArgs("IsCrit") and self.m_CriticalRatio then
        local mArgs = self:GetSkillArgsEnv()
        self.m_CriticalRatio = self.m_CriticalRatio + (mArgs["crit_ratio"] or 0 )
    end
    return 0
end



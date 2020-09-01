local skynet = require "skynet"
local global = require "global"
local extend = require "base/extend"

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
            return oSkill:OnCalDamage(oAttack,oVictim,oPerform,iDamage)
        end
    end
    oAction:AddFunction("OnCalDamage",self.m_ID,fCallback)
end


function CPerform:OnCalDamage(oAttack,oVictim,oPerform,iDamage)
    local oWar = oAttack:GetWar()
    local iBout = oWar.m_iBout 
    if iBout <= 1 then
        return 0
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = iBout * mArgs["bout_damage"]
    return iDamage * iRatio/100
end

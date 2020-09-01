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
end

--暴击是加暴击伤害
function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
    if oAttack:QueryBoutArgs("IsCrit") then
        local mArgs = self:GetSkillArgsEnv()
        local iRatio = mArgs["critical_damage"] or 50
        local iLostHp = oAttack:GetMaxHp() - oAttack:GetHp()
        local iLostRatio = math.floor(iLostHp * 100 / oAttack:GetMaxHp())
        local iRate = iLostRatio * iRatio
        if iRate > 0 then
            oAttack:AddBoutArgs("critical_damage",iRate)
        end
    end
    return 0
end
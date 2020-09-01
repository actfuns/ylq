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
    local iRatio = math.floor(oVictim:GetHp() * 10000 / oVictim:GetMaxHp())
    local iHpRatio = mArgs["hp_ratio"] or 2000
    local iAbnormalRatio = mArgs["abnormal_ratio"] or 2000
    if iRatio <= iHpRatio then
        oVictim:Set("abnormal_attr_ratio",iAbnormalRatio)
    end
end
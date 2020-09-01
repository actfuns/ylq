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
    local func = function (oVictim,oAttack,iDamage)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnKilled(oVictim,oAttack,iDamage)
        end
    end
    oPerformMgr:AddFunction("OnKilled",self.m_ID,func)
end

function CPerform:OnKilled(oVictim,oAttack,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["revive_ratio"]
    local iHpRatio = mArgs["hp_ratio"]
    if in_random(iRatio,10000) then
        local iMaxHp = oVictim:GetMaxHp()
        local iHp = math.floor(iMaxHp*iHpRatio/10000)
        if iHp > 0 then
            self:ShowPerfrom(oVictim)
            self:ModifyHp(oVictim,oAttack,iHp)
        end
    end
end
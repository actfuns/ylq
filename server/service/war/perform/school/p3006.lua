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

function CPerform:CanPerform()
    return false
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local func = function (oAttack,oVictim,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnKill(oAttack,oVictim,iDamage)
        end
    end
    oPerformMgr:AddFunction("OnKill",self.m_ID,func)
end

function CPerform:OnKill(oAttack,oVictim,iDamage)
    local mSkillArgs = self:GetSkillArgsEnv()
    local iTargetRatio = mSkillArgs["target_ratio"]
    local iRatio = mSkillArgs["ratio"]
    local iAddHp = oVictim:GetMaxHp() * iTargetRatio/10000
    iAddHp = math.min(iAddHp,oAttack:GetMaxHp() * iRatio/10000)
    iAddHp = math.floor(iAddHp)
    local mArgs = {
        attack_wid = oAttack:GetWid()
    }
    self:ShowPerfrom(oAttack)
    self:ModifyHp(oAttack,oAttack,iAddHp,mArgs)
end
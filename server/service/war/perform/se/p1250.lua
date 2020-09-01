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
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
    end
    oPerformMgr:AddFunction("OnAttack",self.m_ID,fCallback)
end

function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    local mSkillArgs = self:GetSkillArgsEnv()
    local iHpRatio = mSkillArgs["hp_ratio"] or 1000
    local iAddHp = math.floor(iHpRatio * iDamage / 10000)
    local mArgs = {
        attack_wid = oAttack:GetWid()
    }
    self:ModifyHp(oAttack,oAttack,iAddHp,mArgs)
end
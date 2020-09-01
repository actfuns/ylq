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
    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnKill(oAttack,oVictim,iDamage)
        end
    end
    oAction:AddFunction("OnKill",self.m_ID,fCallback)
end

function CPerform:OnKill(oAttack,oVictim,iDamage)
    local mEnemey = oAttack:GetEnemyList()
    if #mEnemey <= 0 then
        return
    end
    local oEnemy = mEnemey[math.random(#mEnemey)]
    local iNormalAttack = oAttack:GetNormalAttackSkillId()
    local oPerform = oAttack:GetPerform(iNormalAttack)
    if not oPerform then
        return
    end
    oPerform:Perform(oAttack,{oEnemy,})
end
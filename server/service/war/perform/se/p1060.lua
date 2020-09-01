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
    local fCallback = function (oAttack,oVictim,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            CPerform:OnKill(oAttack,oVictim,iDamage)
        end
    end
    oPerformMgr:AddFunction("OnKill",self.m_ID,fCallback)
end

function CPerform:OnKill(oAttack,oVictim,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 4000
    if not in_random(iRatio,10000) then
        return
    end
    if oAttack:QueryBoutArgs("se1060") then
        return
    end
    oAttack:SetBoutArgs("se1060",true)
    local iNormalAttackId = oAttack:GetNormalAttackSkillId()
    local oPerform = oAttack:GetPerform(iNormalAttackId)
    if not oPerform then
        return
    end
    local mEnemy = oAttack:GetEnemyList()
    if #mEnemy <= 0 then
        return
    end
    oPerform:Perform(oAttack,mEnemy)
end
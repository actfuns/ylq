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
    local iSkill =self:Type()
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAttacked(oVictim,oAttack,iDamage)
        end
    end
    oPerformMgr:AddFunction("OnAttacked",self.m_ID,fCallback)
    local fCallback = function (oVictim,oAttack,oPerform)
        AttackBack(oVictim,oAttack,oPerform)
    end
    oPerformMgr:AddFunction("AttackBack",self.m_ID,fCallback)
end

function CPerform:OnAttacked(oVictim,oAttack,iDamage)
    local mSkillArgs = self:GetSkillArgsEnv()
    local iRatio = mSkillArgs["ratio"] or 1000
    if not oVictim or oVictim:IsDead() then
        return
    end
    if in_random(iRatio,10000) then
        oVictim:SetBoutArgs("attack_back",true)
    end
end

function AttackBack(oVictim,oAttack,oPerform)
    if not oAttack:IsCurrentAction() or not oVictim:IsAttackBack() then
        return
    end
    oVictim:OnAttackBack(oAttack)
    local oActionMgr = global.oActionMgr
    local iPerform = oVictim:GetNormalAttackSkillId()
    local oPerform = oVictim:GetPerform(iPerform)
    if not oPerform then
        return
    end
    oPerform:Perform(oVictim,{oAttack},oPerform,100,2)
    oVictim:SetBoutArgs("attack_back",nil)
end
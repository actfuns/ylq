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
    oAction:SetData("awake",true)
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
    end
    oAction:AddFunction("OnAttack",self.m_ID,fCallback)
end

function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    if oAttack:GetNormalAttackSkillId() ~= oPerform:Type() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iHelp = oAttack:GetMaxHp() * mArgs["hp_ratio"] // 10000
    local mWarriorList = oAttack:GetFriendList()
    local oTarget = oAttack
    local iHPRatio = oAttack:GetHpRatio()
    for _,mWarrior in ipairs(mWarriorList) do
        local iLeft = mWarrior:GetHpRatio()
        if iHPRatio > iLeft then
            iHPRatio = iLeft
            oTarget = mWarrior
        end
    end
    self:ModifyHp(oTarget,oAttack,iHelp)
end 



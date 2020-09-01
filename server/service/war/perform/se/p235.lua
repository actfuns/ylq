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
    self.m_SumDamage = 0
    local iSkill = self:Type()
    local fCallback = function (oAction)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnActionEnd(oAction)
        end
        return 0
    end
    oAction:AddFunction("OnActionEnd",self.m_ID,fCallback)

    local fCallback = function (oAction,iSub)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnSubHp(oAction,iSub)
        end
        return 0
    end
    oAction:AddFunction("OnSubHp",self.m_ID,fCallback)
end


function CPerform:OnSubHp(oAction,iSub)
    self.m_SumDamage = self.m_SumDamage + iSub
end

function CPerform:OnActionEnd(oAction)
    local iDamage = self.m_SumDamage
    self.m_SumDamage = 0
    if iDamage < 0 or oAction:IsDead() then
        return
    end

    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 3000
    if in_random(iRatio,10000) then
        self:ShowPerfrom(oAction)
        local iHPRatio = mArgs["hp_ratio"] or 50
        local iHP = iDamage * iHPRatio // 100
        self:ModifyHp(oAction,oAction,iHP)
    end
end


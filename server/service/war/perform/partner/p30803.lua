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
    oPerformMgr:AddFunction("OnAttacked",self.m_ID,fCallback)
    local fCallback = function (oAttack,iHP)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAddHp(oAction,iHP)
        end
    end
    oPerformMgr:AddFunction("OnAddHp",self.m_ID,fCallback)
end

function CPerform:OnAttacked(oVictim,oAttack,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["defense_ratio"] or 200
    local iAddRatio = oVictim:Query("defense_add",0)
    local iLostRatio = mArgs["hp_ratio"] or 10
    local iLostHP = oVictim:GetMaxHp() - oVictim:GetHp()
    local iRate = math.floor(iLostHP * 10 / oVictim:GetMaxHp())
    local iCurRatio = iRate * iRatio
    if iCurRatio > iAddRatio then
        self:ShowPerfrom(oVictim)
        oVictim:Set("defense_add",iCurRatio)
        oVictim.m_oPerformMgr:SetAttrBaseRatio("defense",self.m_ID,iCurRatio)
    end
end

function CPerform:OnAddHp(oAction,iHP)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["defense_ratio"] or 200
    local iAddRatio = oAction:Query("defense_add",0)
    local iLostHP = oAction:GetMaxHp() - oAction:GetHp()
    local iRate = math.floor(iLostHP * 10 / oAction:GetMaxHp())
    local iCurRatio = iRate * iRatio
    if iCurRatio < iAddRatio then
        self:ShowPerfrom(oAction)
        oAction:Set("defense_add",iCurRatio)
        oAction.m_oPerformMgr:SetAttrBaseRatio("defense",self.m_ID,iCurRatio)
    end
end
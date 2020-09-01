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
            oSkill:OnActionBeforeStart(oAttack)
        end
    end
    oPerformMgr:AddFunction("OnActionBeforeStart",self.m_ID,fCallback)

    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamaged(oVictim,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oPerformMgr:AddFunction("OnCalDamaged",self.m_ID,fCallback)
end

function CPerform:OnActionBeforeStart(oAttack)
    if oAttack:IsDead() then
        return
    end
    
    local mArgs = self:GetSkillArgsEnv()
    local oWar = oAttack:GetWar()
    local iState = oAttack:GetData("p41803_state",0)
    self:ShowPerfrom(oAttack)
    if iState == 0 then
        local iRatio = mArgs["add_attack"] or 0
        local iAttack = math.floor(iRatio*oAttack:GetBaseAttr("attack")/10000)
        oAttack:AddBoutArgs("attack",iAttack)
        oAttack:SetData("p41803_state",1)
    else
        local iRatio = mArgs["del_attack"] or 0
        local iAttack = math.floor(iRatio*oAttack:GetBaseAttr("attack")/10000)
        oAttack:AddBoutArgs("attack",-iAttack)
        oAttack:SetData("p41803_state",0)
    end
end

function CPerform:OnCalDamaged(oVictim,oAttack,oPerform,iDamage)
    local oWar = oAttack:GetWar()
    local iBout = oWar.m_iBout
    local iState = oVictim:GetData("p41803_state")
    if iState == 1 then
        local mArgs = self:GetSkillArgsEnv()
        local iRatio = mArgs["add_ratio"] or 5000
        local iAddDamage = math.floor(iRatio*iDamage/10000)
        return iAddDamage
    elseif iState == 0 then
        local mArgs = self:GetSkillArgsEnv()
        local iRatio = mArgs["del_ratio"] or 5000
        local iDelDamage = math.floor(iRatio*iDamage/10000)
        return -iDelDamage
    end
    return 0
end
local skynet = require "skynet"

local global = require "global"
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


function CPerform:ValidUse(oAttack,oVictim)
    if not oVictim:ValidRevive({}) then
        return false
    end
    return super(CPerform).ValidUse(self,oAttack,oVictim)
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local func = function (oVictim)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:BeforeDie(oVictim)
        end
    end
    oAction:AddFunction("BeforeDie",self.m_ID,func)
    local fCallback = function (oVictim)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnRevive(oVictim)
        end
    end
    oAction:AddFunction("OnRevive",self.m_ID,fCallback)
end

function CPerform:BeforeDie(oAction)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["revive_ratio"] or 2000
    if not oAction:ValidRevive() then
        return
    end
    if not in_random(iRatio,10000) then
        return
    end
    local  bBuff= oAction:Query("50303buff")
    if bBuff then
        return
    end
    if oAction:HasKey("die_sure") then
        return
    end
    self:ShowPerfrom(oAction)
    oAction:Set("50303buff",true)
    self:Effect_Condition_For_Attack(oAction)
    self:ModifyHp(oAction,oAction,1)
end

function CPerform:OnRevive(oAction)
    oAction:Set("50303buff",nil)
    oAction:Set("die_sure",nil)
end
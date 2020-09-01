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
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnAttack",self.m_ID,fCallback)
end

function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    local iMinRatio = mArgs["min_ratio"] or 1000
    local iMaxRatio = mArgs["max_ratio"] or 5000
    if self:GetData("PerformAttackCnt",0) == 1 then
        iRatio = iRatio + 1000
    end
    iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMinRatio,iMaxRatio)
    if oAttack:Random(iRatio) then
        oVictim:SetBoutArgs("p41402",1)
        self:Effect_Condition_For_Victim(oVictim,oAttack)
    end

end


function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    if not oVictim:QueryBoutArgs("p41402") then
        return
    end
    oVictim:SetBoutArgs("p41402",nil)
    super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)

end
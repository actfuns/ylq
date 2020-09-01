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

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local func = function (oAttack,oVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDefense(oAttack,oVictim,oPerform)
        end
    end
    oAction:AddFunction("OnCalDefense",self.m_ID,func)
end

function CPerform:OnCalDefense(oAttack,oVictim,oPerform)
    local mArgs = self:GetSkillArgsEnv()
    if oAttack:QueryBoutArgs("IsCrit") then
        local iDefense = oVictim:QueryAttr("defense")
        local iRatio = mArgs["defense"] or 2000
        iDefense = math.floor(iDefense*iRatio/10000)
        self:ShowPerfrom(oAttack)
        return -iDefense
    end
    return 0
end
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
             return  oSkill:OnActionEnd(oAttack)
        end
        return 0
    end
    oAction:AddFunction("OnActionEnd",self.m_ID,fCallback)
end

function CPerform:OnActionEnd(oAction)
    if oAction:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if oAction:Random(iRatio) then
        self:ShowPerfrom(oAction)
        self:Effect_Condition_For_Attack(oAction)
    end
end





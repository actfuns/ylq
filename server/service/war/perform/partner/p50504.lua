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
    local fCallback = function (oAction)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnBoutStart(oAction)
        end
    end
    oAction:AddFunction("OnBoutStart",self.m_ID,fCallback)
end

function CPerform:OnBoutStart(oAction)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 2000
    local oWar = oAction:GetWar()
    local iBout = oWar.m_iBout
    if iBout > 1 then
        return
    end
    if in_random(iRatio,10000) then
        self:Effect_Condition_For_Attack(oAction,oAction)
    end
end
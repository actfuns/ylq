--import module

local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/equip/epfobj"))

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

function CPerform:CalWarrior(oWarrior,oPerformMgr)
    self:InitTeamReceiveDamage(oWarrior)
end

function CPerform:OnTeamAttacked(oAction,oVictim,oAttack,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if oAction:Random(iRatio) then
        self:ShowPerfrom(oAction)
        self:Effect_Condition_For_Attack(oAction)
        self:Effect_Condition_For_Attack(oVictim)
    end
end




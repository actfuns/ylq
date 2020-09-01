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
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["no_sp_ratio"] or 1000
    local oWar = oAction:GetWar()
    local iCamp = oAction:GetCampId()
    local oCamp = oWar:GetCamp(iCamp)
    if oCamp then
        oCamp:Add("no_sp_ratio",iRatio)
        oCamp:Set("no_sp_attack",oAction:GetWid())
    end
end
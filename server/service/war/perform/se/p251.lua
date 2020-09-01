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
    oAction:AddFunction("OnActionBeforeStart",self.m_ID,fCallback)
end

function CPerform:OnActionBeforeStart(oAction)
    if oAction:IsDead() then
        return
    end
    local oCamp = oAction:GetCamp()
    local sFlag = "bout_addsp"
    if oCamp:QueryBoutArgs(sFlag) then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 5000
    if not in_random(iRatio,10000) then
        return
    end
    self:ShowPerfrom(oAction)
    local iSP = 20
    local iCamp = oAction:GetCampId()
    local oWar = oAction:GetWar()
    oWar:AddSP(iCamp,iSP,{skiller=oAction:GetWid()})
    oCamp:SetBoutArgs(sFlag,true)
end
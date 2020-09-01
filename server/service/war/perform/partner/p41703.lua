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
    local func = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnWarStart(oAttack)
        end
    end
    oAction:AddFunction("OnWarStart",self.m_ID,func)
end

function CPerform:OnWarStart(oAction)
    local oCamp = oAction:GetCamp()
    if oCamp:QueryBoutArgs("p41703_trigger") then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 2500
    local iAddSp = mArgs["add_sp"]/100
    if oAction:Random(iRatio) then
        self:ShowPerfrom(oAction)
        oCamp:SetBoutArgs("p41703_trigger",1)
        local oWar = oAction:GetWar()
        local iCamp = oAction:GetCampId()
        oWar:AddSP(iCamp,iAddSp,{skiller=oAction:GetWid()})
    end
end







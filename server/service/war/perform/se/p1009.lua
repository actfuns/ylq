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
            oSkill:OnWarStart(oAttack)
        end
    end
    oAction:AddFunction("OnWarStart",self.m_ID,fCallback)
end

function CPerform:OnWarStart(oAction)
    local sFlag = "war_start_addsp"
    local oCamp = oAction:GetCamp()
    local oWar = oAction:GetWar()
    if oCamp:QueryBoutArgs(sFlag) then
        return
    end
    local iEnemyCamp = oAction:GetEnemyCampId()
    local iSP = 80
    oWar:AddSP(iEnemyCamp,iSP,{skiller=oAction:GetWid()})
    oCamp:SetBoutArgs(sFlag,true)
end
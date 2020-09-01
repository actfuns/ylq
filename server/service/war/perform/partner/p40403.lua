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
    local fCallback = function (oVictim,args)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnDead(oVictim)
        end
    end
    oAction:AddFunction("OnDead",self.m_ID,fCallback)
end

function CPerform:OnDead(oAction)
    local oWar = oAction:GetWar()
    if not oWar then
        return
    end
    local iCamp = oAction:GetCampId()
    oWar:AddSP(iCamp,100,{skiller=oAction:GetWid()})
    self:ShowPerfrom(oAction)
end
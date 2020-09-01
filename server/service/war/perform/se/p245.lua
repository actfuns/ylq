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
    local fCallback = function (oVictim,oAttack,oPerform)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnPerformed(oVictim,oAttack,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnPerformed",self.m_ID,fCallback)
end

function CPerform:OnPerformed(oVictim,oAttack,oPerform)
    local mData = oPerform:GetPerformData()
    local iSP = mData["sp"] or 0
    if iSP < 1 or oAttack:QueryBoutArgs("p245_trigger")  then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1500
    
    if in_random(iRatio,10000) then
        oAttack:SetBoutArgs("p245_trigger",1)
        self:ShowPerfrom(oVictim)
        local iCampID = oAttack:GetCampId()
        local oWar = oVictim:GetWar()
        oWar:AddSP(iCampID,- (mArgs["sp"] or 10))
        local oCamp = oWar.m_lCamps[iCampID]
    end
end




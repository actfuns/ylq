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

    local fCallback = function (oVictim,iHp,mArgs)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnModifyHp(oVictim,iHp,mArgs)
        end
    end
    oAction:AddFunction("OnModifyHp",self.m_ID,fCallback)
end

function CPerform:OnModifyHp(oVictim,iHp,mArgs)
    if iHp >= 0 then
        return
    end
    if not mArgs["attack_wid"] then
        return
    end
    if mArgs["BuffID"]  and not mArgs["attack_buff"] then
        return
    end
    if oVictim:QueryBoutArgs("p323_target") ==mArgs["attack_wid"] then
        return
    end

    local oWar = oVictim:GetWar()
    local mEnv = self:GetSkillArgsEnv()
    local iRatio = mEnv["ratio"] or 2000
    if not in_random(iRatio,10000) then
        return
    end
    oVictim:SetBoutArgs("p323_target",mArgs["attack_wid"])
    local oWar = oVictim:GetWar()
    local iSP = 20
    local iCamp = oVictim:GetCampId()
    self:ShowPerfrom(oVictim)
    oWar:AddSP(iCamp,iSP,{skiller=oVictim:GetWid()})
end










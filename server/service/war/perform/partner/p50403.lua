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
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
    end
    oAction:AddFunction("OnAttack",self.m_ID,fCallback)
    local fCallback = function (oAttack,oVictim,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnKill(oAttack,oVictim,iDamage)
        end
    end
    oAction:AddFunction("OnKill",self.m_ID,fCallback)
end

function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    self:MakeSP(oAttack,oVictim,iDamage)
end

function CPerform:OnKill(oAttack,oVictim,iDamage)
    self:MakeSP(oAttack,oVictim,iDamage)
end

function CPerform:MakeSP(oAttack,oVictim,iDamage)
    local iSkill = oAttack:GetBoutCmdSkill()
    if not iSkill or iSkill ~= 50401 then
        return
    end
    local oWar = oAttack:GetWar()
    local iCamp = oVictim:GetCampId()
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    local iExtraLevel = mArgs["extra_level"] or 3
    local iBuff = 1026
    if in_random(iRatio,10000) and oVictim.m_oBuffMgr:HasBuff(iBuff) then
        self:ShowPerfrom(oAttack)
        local iSP = mArgs["sp"] or 20
        if self:Level() >= iExtraLevel then
            local oSP = oVictim:GetSPSkill()
            if oSP then
                iSP = oSP:GetResumeSP()
            end
        end
        oWar:AddSP(iCamp,-iSP)
    end
end
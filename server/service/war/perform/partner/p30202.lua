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
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    if not oVictim or oVictim:IsDead() then
        return
    end
    local oWar = oAttack:GetWar()
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["abnormal_ratio"] or 1000
    local iMaxRatio = mArgs["max_ratio"] or 5000
    local iMinRatio = mArgs["min_ratio"] or 1000
    local iSpecialRatio = oAttack:SpecialRatio(self.m_ID)
    local iRatio = (oWar.m_iBout == 1 and iSpecialRatio ~= 0 and iSpecialRatio) or oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
    if in_random(iRatio,10000) then
        super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)
    end
end

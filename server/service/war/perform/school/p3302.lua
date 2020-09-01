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

function CPerform:Perform(oAttack,lVictim)
    self:MultiPerform(oAttack,lVictim)
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 4000
    local iAttackCnt = self:GetData("PerformAttackCnt",1)
    if iAttackCnt == 1 then
        iRatio = iRatio + 1000
    end
    local iMinRatio = mArgs["min_ratio"] or 2500
    local iMaxRatio = mArgs["max_ratio"] or 7000
    local iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
    if math.random(10000) <= iRatio then
        super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)
    end
end
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

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    local iCnt = 3
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,iCnt)
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 0
    local iMinRatio = mArgs["min_ratio"] or 0
    local iMaxRatio = mArgs["max_ratio"] or 0
    iRatio = math.min(math.max(iMinRatio,iRatio),iMaxRatio)
    if in_random(iRatio,10000) then
        super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)
    end
end
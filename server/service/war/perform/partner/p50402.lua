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
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,3)
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"]
    local iMinRatio = mArgs["min_ratio"]
    local iMaxRatio = mArgs["max_ratio"]
    local iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
    if in_random(iRatio,10000) then
        super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)
    end
end


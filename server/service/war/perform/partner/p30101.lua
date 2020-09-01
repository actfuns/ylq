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

function CPerform:Effect_Condition_For_Attack(oAttack)
    if not oAttack then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 3000
    local iCriticalRatio = mArgs["critical_ratio"] or 5000
    local iCnt = mArgs["cnt"] or 5
    if in_random(iRatio,10000) and oAttack:Query("AddCritCnt",0) < iCnt then
        oAttack:Add("AddCritCnt",1)
        super(CPerform).Effect_Condition_For_Attack(self,oAttack)
    end
end
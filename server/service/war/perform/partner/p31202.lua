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
    if oAttack:IsFriend(oVictim) then
        self:Effect_Condition_For_Victim(oVictim,oAttack)
    else
        local mArgs = self:GetSkillArgsEnv()
        local iRatio = mArgs["ratio"] or 2000
        local iMinRatio = mArgs["min_ratio"] or 1000
        local iMaxRatio = mArgs["max_ratio"] or 5000
        local iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
        if in_random(iRatio,10000) then
            self:Effect_Condition_For_Victim(oVictim,oAttack)
        end
    end
end

function CPerform:ChooseAITarget(oAttack)
    local mEnemy = oAttack:GetEnemyList()
    if #mEnemy > 0 then
        local w = mEnemy[math.random(#mEnemy)]
        return w:GetWid()
    else
        return super(CPerform).ChooseAITarget(self,oAttack)
    end
end
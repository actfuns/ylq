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

function CPerform:SpeedRatio()
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["speed_ratio"] or 12000
    iRatio = math.floor(iRatio/100)
    return iRatio
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    if not oVictim or oVictim:IsDead() then
        return
    end
    self:Effect_Condition_For_Victim(oVictim,oAttack)
end

function CPerform:ChooseAITarget(oAttack)
    local mEnemy = oAttack:GetEnemyList()
    for _,w in pairs(mEnemy) do
        if not w:HasKey("disable") then
            return w:GetWid()
        end
    end
    local w = mEnemy[math.random(#mEnemy)]
    return w:GetWid()
end
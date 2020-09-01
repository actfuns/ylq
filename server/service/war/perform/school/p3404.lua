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
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 2000
    local iMinRatio = mArgs["min_ratio"] or 2500
    local iMaxRatio = mArgs["max_ratio"] or 7500
    iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
    if in_random(iRatio,10000) then
        local oBuffMgr = oVictim.m_oBuffMgr
        oBuffMgr:AddBuff(111,2,{
            level = self:Level(),
            attack = oAttack:GetWid(),
        })
    end
end

function CPerform:ChooseAITarget(oAttack)
    local iBuffID = 111
    local mEnemy = oAttack:GetEnemyList()
    if #mEnemy < 0 then
        return 0
    end
    for _,w in pairs(mEnemy) do
        local oBuff = w.m_oBuffMgr:HasBuff(iBuffID)
        if not oBuff then
            return w:GetWid()
        end
    end
    local w = mEnemy[math.random(#mEnemy)]
    return w:GetWid()
end
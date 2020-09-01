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
    local fCallback = function (oVictim)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnDead(oVictim)
        end
    end
    oAction:AddFunction("OnDead",self.m_ID,fCallback)
end

function CPerform:OnDead(oAction)
    local mEnemy = oAction:GetEnemyList()
    if #mEnemy <= 0 then
        return
    end
    self:ShowPerfrom(oAction)
    local mArgs = self:GetSkillArgsEnv()
    local iHpRatio = mArgs["hp_ratio"] or 2000
    local iDamageRatio = mArgs["damage_ratio"] or 12000
    local oVictim = mEnemy[math.random(#mEnemy)]
    self:Effect_Condition_For_Victim(oVictim,oAction)
    for _,oVictim in pairs(mEnemy) do
        local iRatio = math.floor(oVictim:GetHp() * 10000 / oVictim:GetMaxHp())
        if iRatio <= iHpRatio and not oVictim:IsDead()  then
            local iDamage = math.floor(oAction:QueryAttr("attack") * iDamageRatio / 10000)
            self:ModifyHp(oVictim,oAction,-iDamage)
        end
    end
end
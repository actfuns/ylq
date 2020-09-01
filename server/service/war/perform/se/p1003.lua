local skynet = require "skynet"
local global = require "global"
local extend = require "base/extend"

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
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
    end
    oAction:AddFunction("OnAttack",self.m_ID,fCallback)
    local fCallback = function (oAttack,lVictim,oPerform)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnPerform(oAttack,lVictim,oPerform)
        end
    end
    oAction:AddFunction("OnPerform",self.m_ID,fCallback)
end


function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    if oAttack:IsDead() then
        return
    end
    local iTarget = oPerform:GetData("PerformTarget",{})[1]
    if iTarget == oVictim:GetWid() then
        oPerform:SetData("p1003_damage",iDamage)
    end
end

function CPerform:OnPerform(oAttack,lVictim,oPerform)
    local iBuff = 1067
    local EnemyList = oAttack:GetEnemyList()
    local mArgs = self:GetSkillArgsEnv()
    local iDamageRatio = mArgs["damage_ratio"] or 1000
    local iDamage = oPerform:GetData("p1003_damage",0) * iDamageRatio /10000
    if iDamage < 1 then
        return
    end
    local oWar = oAttack:GetWar()
    local iWarBout = oWar.m_iBout
    for _,o in ipairs(EnemyList) do
        local oBuff = o.m_oBuffMgr:HasBuff(iBuff)
        if oBuff and iWarBout ~= oBuff:GetBuffStartBout() then
            local iLevel = oBuff:BuffLevel()
            local iHP = iDamage * iLevel
            o:ModifyHp(-iHP,{attack_wid = oAttack:GetWid()})
        end
    end
end


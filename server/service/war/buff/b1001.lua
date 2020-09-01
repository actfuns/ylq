--import module

local global = require "global"
local skynet = require "skynet"

local buffbase = import(service_path("buff/buffbase"))

function NewBuff(...)
    local o = CBuff:New(...)
    return o
end

CBuff = {}
CBuff.__index = CBuff
inherit(CBuff, buffbase.CBuff)

function CBuff:CalInit(oWarrior,oBuffMgr)
    local iShield = self.m_mArgs["shield"] or 0
    oWarrior:Set("shield",iShield)
    local iBuffID = self.m_ID
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:AfterReceiveDamage(oVictim,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oBuffMgr:AddFunction("AfterReceiveDamage",self.m_ID,fCallback)
    local iAttack = self.m_mArgs["attack"] or 0
    local oWar = oWarrior:GetWar()
    local oAttack = oWar:GetWarrior(iAttack)
    local iAttackDamage = 0
    if oAttack:IsAwake() then
        local mBuffArg = self:GetBuffArgsEnv()
        iAttackDamage = oAttack:QueryAttr("attack")
    end
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:OnAttacked(oVictim,oAttack,oPerform,iAttackDamage)
        end
    end
    oWarrior:AddFunction("OnAttacked",self.m_ID,fCallback)
end

function CBuff:AfterReceiveDamage(oVictim,oAttack,oPerform,iDamage)
    local iShield = oVictim:Query("shield",0)
    iShield = iShield - iDamage
    if  iShield<= 0 then
        oVictim:SetBoutArgs("break_shield",1)
        return -iDamage
    else
        oVictim:Set("shield",iShield)
        return -iDamage
    end
end

function CBuff:OnAttacked(oVictim,oAttack,oPerform,iDamage)
    if not oVictim or oVictim:IsDead() then
        return
    end
    if not oVictim:HasKey("break_shield") then
        return
    end
    oVictim:SetBoutArgs("break_shield",nil)
    oVictim.m_oBuffMgr:RemoveBuff(self)
    if iDamage > 0 then
        local mArg = self:GetBuffArgsEnv()
        local iDamageRatio = mArg["shield_hp_ratio"] or 2500
        local iHit = iDamage*iDamageRatio/10000
        self:ModifyHp(oAttack,-iHit)
    end
end


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
    local iBuffID = self.m_ID
    oWarrior:Set("shield",iShield)
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:AfterReceiveDamage(oVictim,oAttack,oPerform,iDamage)
        end
    end
    oBuffMgr:AddFunction("AfterReceiveDamage",self.m_ID,fCallback)
end

function CBuff:AfterReceiveDamage(oVictim,oAttack,oPerform,iDamage)
    local iShield = oVictim:Query("shield",0)
    if iDamage >= iShield then
        oVictim.m_oBuffMgr:RemoveBuff(self)
        return -iDamage
    else
        iShield = iShield - iDamage
        oVictim:Set("shield",iShield)
        return -iDamage
    end
end

function CBuff:OnRemove(oAction,oBuffMgr)
    oAction:SetBoutArgs("break_shield",1)
end
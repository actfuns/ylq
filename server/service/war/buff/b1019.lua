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
    local iBuffID = self.m_ID
    local fCallback = function (oVictim,oAttack,oPerform)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:OnPerformed(oVictim,oAttack,oPerform,iAttackDamage)
        end
    end
    oBuffMgr:AddFunction("OnPerformed",self.m_ID,fCallback)
end

function CBuff:OnPerformed(oVictim,oAttack,oPerform,iAttackDamage)
    if not oVictim then
        return
    end
    local oWar = oVictim:GetWar()
    if oWar.m_iBout == self:GetBuffStartBout() and self:GetAttack() == oAttack:GetWid() then
        return
    end
    if oAttack:Query("Sleep_Attack") then
        return
    end
    
    if not in_random(50) then
        return
    end
    oVictim.m_oBuffMgr:RemoveBuff(self)
end
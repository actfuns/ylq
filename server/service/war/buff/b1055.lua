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
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnReceiveDamage(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oBuffMgr:AddFunction("OnReceiveDamage",self.m_ID,fCallback)

end

function CBuff:OnReceiveDamage(oAttack,oVictim,oPerform,iDamage)
    if oPerform:GroupAttackType() == 1 then
        local mArgs = self:GetBuffArgsEnv()
        local iRatio = mArgs["damage_ratio"] or 2000
        return iDamage * iRatio / 10000
    end
    return 0
end

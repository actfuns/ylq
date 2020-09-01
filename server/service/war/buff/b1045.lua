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
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:ReceiveDamage(oVictim,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oBuffMgr:AddFunction("OnReceivedDamage",self.m_ID,fCallback)
end

function CBuff:ReceiveDamage(oVictim,oAttack,oPerform,iDamage)
    return -iDamage*0.1
end




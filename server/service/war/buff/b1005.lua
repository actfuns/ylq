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
            return oBuff:OnCalDamaged(oVictim,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oBuffMgr:AddFunction("OnCalDamaged",self.m_ID,fCallback)

    local fCallback = function (oAction,iSpeed)
        local oBuff = oAction.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnCallSpeed(oAction,iSpeed)
        end
        return 0
    end
    oBuffMgr:AddFunction("OnCallSpeed",self.m_ID,fCallback)


end

function CBuff:OnCalDamaged(oVictim,oAttack,oPerform,iDamage)
    return iDamage*0.5
end

function CBuff:OnCallSpeed(oAction,iSpeed)
    return 0
end




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

function CBuff:CalInit(oAction,oBuffMgr)
    local iBuffID = self.m_ID
    local fCallback = function (oVictim)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:ReviveHandle(oVictim)
        end
        return false
    end
    oBuffMgr:AddFunction("ReviveHandle",self.m_ID,fCallback)

    local mArgs = self:GetArgs()
    if mArgs["level"] >= 5 then
        local fCallback = function (oVictim)
            local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
            if oBuff then
                return oBuff:AfterReceiveDamage(oVictim)
            end
            return 0
        end
        oBuffMgr:AddFunction("AfterReceiveDamage",self.m_ID,fCallback)
    end
end

function CBuff:ReviveHandle(oVictim)
    local mArgs = self:GetBuffArgsEnv()
    local iReviveRatio = mArgs["ratio"] or 5000
    if in_random(iReviveRatio,10000) and oVictim:QueryBoutArgs("revived_cnt",0) < 100 then
        self:ShowPerfrom(oVictim)
        self:AddBuff(oVictim)
        return true
    end
    return false
end


function CBuff:AddBuff(oVictim)
    local oSkill = oVictim:GetPerform(30603)
    if oSkill then 
        oSkill:AddBuff(oVictim)
    end
end

function CBuff:AfterReceiveDamage(oVictim,oAttack,oPerform,iDamage)
    local mArgs = self:GetBuffArgsEnv()
    local iReviveRatio = mArgs["ratio"] or 5000
    if in_random(iReviveRatio,10000) and oVictim:QueryBoutArgs("revived_cnt",0) < 100 then
        self:AddBuff(oVictim)
    end
    return 0
end






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
    local fCallback = function (oAttack,lVictim,oPerform)
        local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:OnPerform(oAttack,lVictim,oPerform)
        end
    end
    oBuffMgr:AddFunction("OnPerform",self.m_ID,fCallback)
end

function CBuff:OnPerform(oAttack,lVictim,oPerform)
    if not oPerform:IsSp() then
        return
    end
    
    local mArgs = self:GetBuffArgsEnv()
    local iRatio = mArgs["attack"] or 15000
    local iDamage = math.floor(oAttack:QueryAttr("attack") * iRatio / 10000)
    if iDamage > 0 then
        self:ModifyHp(oAttack,-iDamage)
    end
end


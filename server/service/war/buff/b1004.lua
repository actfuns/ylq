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
    local fCallback = function (oAction)
        local oBuff = oAction.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:OnActionEnd(oAction)
        end
    end
    oBuffMgr:AddFunction("OnActionEnd",self.m_ID,fCallback)
end

function CBuff:OnActionEnd(oAction)
    local mArgs = self:GetBuffArgsEnv()
    local iDamageRatio = mArgs["damage_ratio"] or 3
    local iDamage = math.floor(oAction:GetMaxHp() * iDamageRatio / 100)
    if iDamage > 0 then
        self:ModifyHp(oAction,-iDamage)
    end
end
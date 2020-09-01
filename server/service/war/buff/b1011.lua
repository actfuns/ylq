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
    local fCallback = function (oVictim)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:BeforeDie(oVictim)
        end
    end
    oBuffMgr:AddFunction("BeforeDie",self.m_ID,fCallback)
    oBuffMgr:SetAttr("critical_sure",1)
end

function CBuff:BeforeDie(oAction)
    local bSure = oAction:Query("die_sure")
    if bSure then
        return
    end
    local iAddHp = 1
    oAction:AddHp(iAddHp)
end

function CBuff:OnRemove(oAction,oBuffMgr)
    if not oAction or oAction:IsDead() then
        return
    end
    oAction:Set("die_sure",true)
    local iDamage = oAction:GetHp()
    self:ModifyHp(oAction,-iDamage)
    
end
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


function CBuff:OnRemove(oAction,oBuffMgr)
    if oAction:IsDead() then
        return
    end
    local iHit  = self.m_mArgs["master_attack"] or 0
    local oWar = oAction:GetWar()
    local oEnemyList = oAction:GetEnemyList()
    if iHit > 0 then
        for _,o in ipairs(oEnemyList) do
            o:FixedDamage(oAction,iHit)
        end
    end
    oAction:SetData("hp",0)
    oAction:SetDeadStatus()
end




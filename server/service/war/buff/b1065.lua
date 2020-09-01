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
    local mArgs = self:GetBuffArgsEnv()
    local oWar = oAction:GetWar()
    local iBuff = mArgs["buffid"] or 1019
    local iBout = mArgs["bout"] or 1
    local mArgs = {
        level = 1,
        attack = self:GetAttack(),
        buff_bout = oWar.m_iBout,
    }
    local oNew = oAction.m_oBuffMgr:AddBuff(iBuff,iBout,mArgs)
    if oNew then
        oNew.m_NoSubNowWar = 1
    end
end
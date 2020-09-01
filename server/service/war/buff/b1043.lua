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
    local oSkill = oAction:GetPerform(1005)
    if oSkill then
        oSkill.m_Servent = nil
        for iSkill = 5001,5018 do
            if oAction:GetPerform(iSkill) then
               oAction.m_TempPerform = iSkill
            end
        end
    end
end



--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"

local buffbase = import(service_path("buff/buffbase"))

function NewBuff(...)
    local o = CBuff:New(...)
    return o
end

CBuff = {}
CBuff.__index = CBuff
inherit(CBuff, buffbase.CBuff)


function CBuff:CalInit(oWarrior,oBuffMgr)
    local War = oWarrior:GetWar()
    local iBout = War.m_iBout
    local iBuffID = self.m_ID
    local oCamp = oWarrior:GetEnemyCamp()
    local iWid = oWarrior:GetWid()
    local fCallback = function (oAction,oPerform,iTarget)
        local oWar = oAction:GetWar()
        local oTarget = oWar:GetWarrior(iWid)
        if not oTarget then
            return iTarget
        end
        local oBuff = oTarget.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnChooseAITarget(oAction,oPerform,iTarget,iWid)
        end
        return iTarget
    end
    oCamp:AddFunction("OnChooseAITarget",self.m_ID*100+iWid,fCallback)
end

function CBuff:OnChooseAITarget(oAction,oPerform,iTarget,iWid)
     if oPerform:ActionType() == 1 and not oPerform:IsGroupAttack() then
        return iWid
    end
    return iTarget
end


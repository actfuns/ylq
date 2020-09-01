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
    local fCallback = function (oAction,args)
        local oBuff = oAction.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:OnDead(oAction,args)
        end
    end
    oBuffMgr:AddFunction("OnDead",self.m_ID,fCallback)

end

function CBuff:OnDead(oAction,args)
    local oWar = oAction:GetWar()
    local oAttack = oWar:GetWarrior(args["attack"])
    if not oAttack or oAttack:IsDead() then
        return
    end
    local mArg = self:GetBuffArgsEnv()
    local iBuff = mArg["buffid"] or 1019
    local iBout = mArg["bout"] or 3
    local oWar = oAction:GetWar()
    local mArgs = {
        level = 1,
        attack = oAction:GetWid(),
        buff_bout = oWar.m_iBout,
    }
    local oNewBuff = oAttack.m_oBuffMgr:AddBuff(iBuff,iBout,mArgs)
    if oNewBuff then
        oNewBuff.m_NoSubNowWar = 1
    end
end
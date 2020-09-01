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
    local fCallback = function (oAction,iHp,mArgs)
        local oBuff = oAction.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnModifyHp(oAction,iHp,mArgs)
        end
        return 0
    end

    oWarrior:AddFunction("OnModifyHp",self.m_ID,fCallback)
end

function CBuff:OnModifyHp(oAction,iHp,mArgs)
    if iHp >= 0 then
        return
    end
    local iAttack = mArgs["attack"] or mArgs["attack_wid"]
    if not iAttack then
        return
    end
    local oWar = oAction:GetWar()
    local oVictim = oWar:GetWarrior(iAttack)
    if not oVictim then
        return
    end
    if oAction:IsFriend(oVictim) then
        return
    end
    local mArgs = self:GetBuffArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    local iBuff = mArgs["buff"] or 1017
    local iBout = mArgs["bout"] or 1
    if oAction:Random(iRatio) then
        local mArgs = {
            level = 1,
            attack = oAction:GetWid(),
            buff_bout = oWar.m_iBout,
            }
        oVictim.m_oBuffMgr:AddBuff(iBuff,iBout,mArgs)
    end
end


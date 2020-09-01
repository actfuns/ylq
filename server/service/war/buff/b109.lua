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
    local War = oWarrior:GetWar()
    local iBout = War.m_iBout
    local iBuffID = self.m_ID
    local func = function (oAction)
        local oBuff = oAction.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnActionEnd(oAction)
        end
    end
    oBuffMgr:AddFunction("OnActionEnd",self.m_ID,func)
end


function CBuff:OnActionEnd(oAction)
    local iAttackWid = self.m_mArgs["attack"]
    local oWar = oAction:GetWar()
    local oAttack = oWar:GetWarrior(iAttackWid)
    if not oAttack then
        return
    end
    local iWid = oAction:GetWid()
    local iAttack = oAttack:QueryAttr("attack")
    local iDamage = math.floor(iAttack/10)
    self:ModifyHp(oAction,-iDamage)
    local oCurrentAction = oWar:GetWarrior(iWid)
    if not oCurrentAction then
        return
    end
    local mArgs = self:GetBuffArgsEnv()
    local iRatio = mArgs["ratio"]
    local iMinRatio = mArgs["min_ratio"]
    local iMaxRatio = mArgs["max_ratio"]
    if in_random(iRatio,10000) then
        local oBuffMgr = oAction.m_oBuffMgr
        oBuffMgr:AddBuff(105,1,{
            level = self:PerformLevel(),
            attack = iAttackWid,
            buff_bout = oWar.m_iBout,
        })
    end
end

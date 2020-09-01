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
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
        end
    end
    oBuffMgr:AddFunction("OnReceivedDamage",self.m_ID,fCallback)
end

function CBuff:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
    local oWar = oAttack:GetWar()
    local mArgs = self:GetBuffArgsEnv()
    local iShareWid = self.m_mArgs["attack"]
    local iRatio = mArgs["share_ratio"] or 1000
    local iShareDamage = math.floor(iDamage*iRatio/10000)
    iShareDamage = math.max(iShareDamage,1)
    local oShareAction = oWar:GetWarrior(iShareWid)
    if oShareAction and oShareAction:IsAlive() then
        oShareAction:SubHp(iShareDamage)
        oShareAction:SendAll("GS2CWarDamage", {
            war_id = oShareAction:GetWarId(),
            wid = oShareAction:GetWid(),
            damage = -iShareDamage,
        })
        return -iShareDamage
    else
        return 0
    end
end
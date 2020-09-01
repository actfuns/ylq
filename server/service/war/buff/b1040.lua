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
        return 0
    end
    oBuffMgr:AddFunction("OnReceivedDamage",self.m_ID,fCallback)
end

function CBuff:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
    local iLv = self:BuffLevel()
    local iHp = iLv * 0.1 * iDamage
    iLv = iLv - 1
    if iLv <= 0 then
        oVictim.m_oBuffMgr:RemoveBuff(self)
    else 
        self:SetBuffLevel(iLv)
        oVictim:SendAll("GS2CWarBuffBout",{
            war_id = oVictim:GetWarId(),
            wid = oVictim:GetWid(),
            buff_id = self.m_ID,
            bout = self:Bout(),
            level = self:BuffLevel(),
        })
    end
    return -iHp
end

function CBuff:Overlying(oAction,oNewBuff)
    if self:BuffLevel() >= 5 then
        return
    end
    super(CBuff).Overlying(self,oAction,oNewBuff)
end



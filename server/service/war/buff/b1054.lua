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

    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnPerformed(oVictim,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oBuffMgr:AddFunction("OnPerformed",self.m_ID,fCallback)


end



function CBuff:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
    if iDamage <  1 and not oVictim:IsAlive() then
        return 0
    end
    
    if iDamage > 0 then
            local iLastAttack = oVictim:QueryBoutArgs("b1054_pf_attack")
            oVictim:SetBoutArgs("b1054_pf_attack",oAttack:GetWid())
            oAttack:SetBoutArgs("Shield_WarDamage",1)
        self:ModifyHp(oVictim,iDamage,{attack_wid = oVictim:GetWid()})
    end
    return -iDamage
end

function CBuff:OnPerformed(oVictim,oAttack,oPerform)
    local iLv = self.m_iBuffLevel - 1
    if iLv < 1 then
        oVictim.m_oBuffMgr:RemoveBuff(self)
    else
        self.m_iBuffLevel = iLv
        self:RefreshBuff(oVictim)
    end
end






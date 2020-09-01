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
    local func = function (oAttack,oVictim,oPerform)
        local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:OnPerform(oAttack,oVictim,oPerform)
        end
    end
    oBuffMgr:AddFunction("OnPerform",self.m_ID,func)
    local func = function (oVictim,oAttack,oPerform,iDamage)
        local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnCalDamaged(oVictim,oAttack,oPerform,iDamage)
        end
    end
    oBuffMgr:AddFunction("OnCalDamaged",self.m_ID,func)
end

function CBuff:OnPerform(oAttack,oVictim,oPerform)
    local iHP = self.m_mArgs["hp"]
    if not iHP then
        return
    end
    iHP = math.floor(iHP)
    local iAttack = self.m_mArgs["attack"]
    local mArgs = {
        attack_wid = iAttack
    }
    self:ModifyHp(oAttack,iHP,mArgs)
end

function CBuff:OnCalDamaged(oVictim,oAttack,oPerform,iDamage)
    local oWar = oAttack:GetWar()
    local mData = self:GetBuffEffectData()
    local sArgs = mData["args"]
    local mEnv = {
        attack = oAttack:QueryAttr("attack"),
    }
    local mArgs= formula_string(sArgs,mEnv)
    local mSkillArgs = mArgs["skill_args"]
    local iRatio = mArgs["damage2hp_ratio"] or 3000
    local iDelDamage = math.floor(iDamage*iRatio/10000)
    return -iDelDamage
end
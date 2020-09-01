--import module

local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))

function NewCPerform(...)
    local o = CPerform:New(...)
    return o
end

CPerform = {}
CPerform.__index = CPerform
inherit(CPerform, pfobj.CPerform)


function CPerform:ValidCast(oAttack,oVictim)
    if oAttack:GetHp() < 1 then
        return false
    end
    return super(CPerform).ValidCast(self,oAttack,oVictim)
end


function CPerform:ValidResume(oAttack,oVictim)
    if oAttack:GetHp() < 1 then
        return false
    end
    return super(CPerform).ValidResume(self,oAttack,oVictim)
end

function CPerform:Perform(oAttack,lVictim)
    local mData = self:GetSkillData()
    local mArgs = self:GetSkillArgsEnv()
    local oWar = oAttack:GetWar()
    local iWid = oAttack:GetWid()
    if not oWar.m_ShareHit  then
        oWar.m_ShareHit = {}
    end
    if not oWar.m_ShareHit[iWid] then
        oWar.m_ShareHit[iWid] = {}
    end
    local iHpRatio = mArgs["hp_ratio"]
    local iSumHPRatio = mArgs["shield_ratio"] or 10000
    local iNeedHP = iHpRatio * oAttack:GetMaxHp() /10000


    if iNeedHP >= oAttack:GetHp() then
        iNeedHP = math.max(oAttack:GetHp() - 1,0)
    end
    if iNeedHP > 0 then
        self:ModifyHp(oAttack,oAttack,-iNeedHP)
    end
    iNeedHP = math.floor((iNeedHP * iSumHPRatio/10000) / #lVictim)
    iNeedHP = math.max(1,iNeedHP)
    self.m_Shield = iNeedHP
    super(CPerform).Perform(self,oAttack,lVictim)
    self.m_Shield = nil

end


function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local iShield = self.m_Shield
    local mData = self:GetSkillData()
    local mBuff = mData["victimBuff"] or {}
    for _,mData in pairs(mBuff) do
        local iBuffID = mData["buffid"]
        local iBout = mData["bout"]
        oVictim.m_oBuffMgr:AddBuff(iBuffID,iBout,{
            level = self:Level(),
            attack = oAttack:GetWid(),
            shield = iShield,
        })
    end
end




function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
end
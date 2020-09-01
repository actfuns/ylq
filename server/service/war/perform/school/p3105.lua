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

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:Perform(oAttack,lVictim)
    local oWar = oAttack:GetWar()
    local mDamage = {}
    local mArgs = self:GetSkillArgsEnv()
    local iBout = mArgs["bout"] or 2
    if oWar then
        local iCurBout = oWar.m_iBout
        local iStartBout = math.max(iCurBout-iBout,0)
        local iReceiveDamage = oWar.m_oRecord:GetReceiveDamage(oAttack,iStartBout)
        local iDamage = math.floor(math.random(100)*iReceiveDamage/100)
        table.insert(mDamage,math.max(iDamage,0))
        table.insert(mDamage,math.max(iReceiveDamage-iDamage,0))
        self:SetData("FixDamage",mDamage)
    end
    super(CPerform).Perform(self,oAttack,lVictim)
    if oAttack then
        oAttack:SetData("FixDamage",nil)
    end
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local mDamage = self:GetData("FixDamage",{})
    local iAttackCnt = self:GetData("PerformAttackCnt")
    local iDamage = mDamage[iAttackCnt] or 0
    if iDamage > 0 then
        oAttack:AddBoutArgs("FixDamage",iDamage)
    end
    super(CPerform).TruePerform(self,oAttack,oVictim,iDamageRatio)
    if oAttack and iDamage > 0 then
        oAttack:AddBoutArgs("FixDamage",-iDamage)
    end
end
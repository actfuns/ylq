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

function CPerform:TargetList(oAttack)
    local oCamp = oAttack:GetCamp()
    if oCamp:IsFullSP() then
        return {}
    else
        return super(CPerform).TargetList(self,oAttack)
    end
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local mArgs = self:GetSkillArgsEnv()
    local iHpRatio = mArgs["hp_ratio"] or 3000
    local iSP = mArgs["sp"] or 20
    local oWar = oAttack:GetWar()
    if not oWar then
        return
    end
    local iCamp = oAttack:GetCampId()
    local iDamage = math.floor(oAttack:GetHp() * iHpRatio / 10000)
    if iDamage > 0 then
        oAttack:SetBoutArgs("no_add_sp",true)
        self:ModifyHp(oAttack,oAttack,-iDamage)
        oAttack:SetBoutArgs("no_add_sp",nil)
    end
    oWar:AddSP(iCamp,iSP,{skiller=oAttack:GetWid(),})
end
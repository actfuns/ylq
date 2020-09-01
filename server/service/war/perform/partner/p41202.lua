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

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local mSkillArgsEnv = self:GetSkillArgsEnv()
    local iRatio = mSkillArgsEnv["ratio"] or 5000
    if in_random(iRatio,10000) then
        oAttack:SetBoutArgs("ignore_effect",true)
        super(CPerform).TruePerform(self,oAttack,oVictim,iDamageRatio)
    else
        local iRatio = mSkillArgsEnv["hp_ratio"] or 15000
        local iAddHp = math.floor(oAttack:QueryAttr("attack") * iRatio / 10000)
        local mArgs = {
            attack_wid = oAttack:GetWid()
        }
        self:ModifyHp(oVictim,oAttack,iAddHp,mArgs)
    end
end

function CPerform:Effect_Condition_For_Attack(oAttack)
    if oAttack:HasKey("ignore_effect") then
        return
    end
    if oAttack:BanPassiveSkill() == 2 then
        return
    end
    if oAttack:IsPartner() and oAttack:IsAwake() then
        self:ShowPerfrom(oAttack,{skill = 41203 })
        super(CPerform).Effect_Condition_For_Attack(self,oAttack)
    end
end
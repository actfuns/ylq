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
    local iHp = oAttack:GetHp()
    local iDamage = math.floor(iHp / 5)
    if iDamage > 0 then
        self:ModifyHp(oAttack,oAttack,-iDamage)
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["damage_add_ratio"] or 3000
    local iAddDamage = oAttack:GetMaxHp() - iHp
    iAddDamage = math.floor(iAddDamage*iRatio/10000)
    oAttack:AddBoutArgs("FixDamage",iAddDamage)
    super(CPerform).Perform(self,oAttack,lVictim)
    oAttack:AddBoutArgs("FixDamage",-iAddDamage)
end
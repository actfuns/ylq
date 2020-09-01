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
    local mArgs = self:GetSkillArgsEnv()
    local iExtDamage = mArgs["damage_ratio"]
    local iRatio = mArgs["ratio"]
    local iFixDamage
    if math.random(10000) <= iRatio then
        local iDefenese = oAttack:QueryAttr("defense")
        iFixDamage = math.floor(iDefenese * iExtDamage / 10000)
        oAttack:AddBoutArgs("FixDamage",iFixDamage)
    end
    super(CPerform).TruePerform(self,oAttack,oVictim,iDamageRatio)
    if iFixDamage then
        oAttack:AddBoutArgs("FixDamage",-iFixDamage)
    end
end
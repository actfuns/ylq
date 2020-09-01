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
     if oAttack and not oAttack:IsDead() and iHp > 10 then
        local mArgs = self:GetSkillArgsEnv()
        local fRatio = (mArgs["hp_ratio"] or 1000)/10000
        local iDamage = math.floor(oAttack:GetHp() *fRatio)
        if iDamage > 0 then
            self:ModifyHp(oAttack,oAttack,-iDamage)
        end
    end
    super(CPerform).Perform(self,oAttack,lVictim)
end





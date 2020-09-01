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
    self:Effect_Condition_For_Victim(oVictim,oAttack)
end

function CPerform:Perform(oAttack,lVictim)
    super(CPerform).Perform(self,oAttack,lVictim)
    local iSkill = self:Type()
    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnSubHp(oAttack)
        end
    end
    oAttack:AddFunction("OnSubHp",self.m_ID,fCallback)
    local iDamage = oAttack:GetHp()
    self:ModifyHp(oAttack,oAttack,-iDamage)
end

function CPerform:OnSubHp(oAction)
    oAction:Set("is_sacrifice",true)
end
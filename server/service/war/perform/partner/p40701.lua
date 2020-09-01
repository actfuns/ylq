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
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
    end
    oAttack:AddFunction("OnAttack",self.m_ID,fCallback)
    super(CPerform).TruePerform(self,oAttack,oVictim,iDamageRatio)
    if oAttack then
        oAttack:RemoveFunction("OnAttack",self.m_ID)
    end
end

function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["hp_ratio"] or 2000
    local iAddHp = math.floor(iDamage * iRatio / 10000)
    iAddHp = math.max(iAddHp,1)
    local mArgs = {
        attack_wid = oAttack:GetWid()
    }
    self:ModifyHp(oAttack,oAttack,iAddHp,mArgs)
end


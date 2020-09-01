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
    local fCallback = function (oAttack,oVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamageRatio(oAttack,oVictim,oPerform)
        end
    end
    oAttack:AddFunction("OnCalDamageRatio",self.m_ID,fCallback)
    super(CPerform).TruePerform(self,oAttack,oVictim,iDamageRatio)
    if oAttack then
        oAttack:RemoveFunction("OnCalDamageRatio",self.m_ID)
    end
end

function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
    local iHpRatio = math.floor(oVictim:GetHp() / oVictim:GetMaxHp())
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 3000
    if iHpRatio <= iRatio then
        local iDamageRatio = mArgs["damage_ratio"] or 5000
        return iDamageRatio
    end
    return 0
end
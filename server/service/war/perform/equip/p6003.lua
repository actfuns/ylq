--import module

local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/equip/epfobj"))

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

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamageRatio(oAttack,oVictim,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnCalDamageRatio",self.m_ID,fCallback)

    local fCallback = function (oAttack,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:PerformStart(oAttack,oPerform)
    end
        return 0
    end
    oAction:AddFunction("PerformStart",self.m_ID,fCallback)

end

function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
    local iDamageRatio = oAttack:QueryBoutArgs("p6003_Damage")
    if not iDamageRatio then
        return 0
    end
    return iDamageRatio
end


function CPerform:PerformStart(oAttack,oPerform)
    local lSelectWid =  oAttack:QueryBoutArgs("perform_target",{})
    local  mArg = self:GetSkillArgsEnv()
    local iRatio = mArg["ratio"] or 1000
    if in_random(iRatio,10000) and #lSelectWid > 0 then
        self:ShowPerfrom(oAttack)
        local iDamageRatio = #lSelectWid * (mArg["damage_ratio"] or 200)
        oAttack:SetBoutArgs("p6003_Damage",iDamageRatio)
    end
end




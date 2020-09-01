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
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local func = function (oAttack,oVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamageRatio(oAttack,oVictim,oPerform)
        end
        return 0
    end
    oPerformMgr:AddFunction("OnCalDamageRatio",self.m_ID,func)


    local func = function (oAction,oVictim,oPerform,iDamag)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnReceiveDamage(oAction,oVictim,oPerform,iDamag)
        end
        return 0
    end
    oPerformMgr:AddFunction("OnReceiveDamage",self.m_ID,func)


    local func = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnActionEnd(oAttack)
        end
    end
    oPerformMgr:AddFunction("OnActionEnd",self.m_ID,func)
end

function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
    local iRatio = oAttack:QueryBoutArgs("p31403_ratio",0)
    if iRatio > 0 then
        self:ShowPerfrom(oAttack,{bout=1})
    end
    return iRatio
end

function CPerform:OnReceiveDamage(oAction,oVictim,oPerform,iDamag)
    local mData = oPerform:GetPerformData()
     if mData["skillGroupType"] ~= 1 then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    oAction:AddBoutArgs("p31403_ratio",mArgs["damage_ratio"])
end

function CPerform:OnActionEnd(oAction)
    oAction:SetBoutArgs("p31403_ratio",nil)
end


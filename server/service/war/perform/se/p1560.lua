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
    local fCallback = function (oAttack,iHP,oVictim)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCure(oAttack,iHP,oVictim)
        end
        return 0
    end
    oAction:AddFunction("OnCure",self.m_ID,fCallback)
end

function CPerform:OnCure(oAttack,iHP,oVictim)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    local iAddHp = math.floor(iHP * iRatio / 10000)
    return iAddHp
end
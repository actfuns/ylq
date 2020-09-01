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
    local fCallback = function (oAttack,oVictim,oBuff)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnGiveBuff(oAttack,oVictim,oBuff)  
        end
    end
    oPerformMgr:AddFunction("OnGiveBuff",self.m_ID,fCallback)
end

function CPerform:OnGiveBuff(oAttack,oVictim,oBuff)
    local iGroupType = oBuff:GroupType()
    if iGroupType ~= 102 then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1500
    if not in_random(iRatio,10000) then
        return
    end
    oBuff:AddBout(1)
    oVictim.m_oBuffMgr:GS2CWarBuffBout(oBuff)
end
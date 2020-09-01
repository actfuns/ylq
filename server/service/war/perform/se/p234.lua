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
    local fCallback = function (oVictim)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            return oSkill:ReviveHandle(oVictim)
        end
        return false
    end
    oAction:AddFunction("ReviveHandle",self.m_ID,fCallback)

end


function CPerform:ReviveHandle(oVictim)
    local mSkillArgs = self:GetSkillArgsEnv()
    local iReviveRatio = mSkillArgs["revive_ratio"]
    local iReviveCnt = mSkillArgs["revive_cnt"]
    if in_random(iReviveRatio,10000) and oVictim:QueryBoutArgs("revived_cnt",0) < iReviveCnt then
        self:ShowPerfrom(oVictim)
        return true
    end
    return false
end


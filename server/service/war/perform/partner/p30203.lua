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
    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnActionBeforeStart(oAttack)
        end
    end
    oAction:AddFunction("OnActionBeforeStart",self.m_ID,fCallback)
end

function CPerform:OnActionBeforeStart(oAction)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if not in_random(iRatio,10000) then
        return
    end

    local iType = gamedefines.BUFF_TYPE.CLASS_ABNORMAL
    if oAction.m_oBuffMgr:RemoveRandomBuff(iType) then
        self:ShowPerfrom(oAction)
    end
end
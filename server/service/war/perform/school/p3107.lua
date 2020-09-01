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
    local func = function (oAction)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnActionBeforeStart(oAction)
        end
    end
    oPerformMgr:AddFunction("OnActionBeforeStart",self.m_ID,func)
end

function CPerform:OnActionBeforeStart(oAction)
    if oAction:IsDead() then
        return
    end
    local mSkillArgs = self:GetSkillArgsEnv()
    local iRatio = mSkillArgs["cancle_abnormal_ratio"]
    if in_random(iRatio,10000) then
        self:ShowPerfrom(oAction)
        local oBuffMgr = oAction.m_oBuffMgr
        oBuffMgr:RemoveRandomBuff(gamedefines.BUFF_TYPE.CLASS_ABNORMAL)
    end
end
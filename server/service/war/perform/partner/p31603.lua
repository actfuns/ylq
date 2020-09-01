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
    local fCallback = function (oAction)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnActionEnd(oAction)
        end
        return 0
    end
    oAction:AddFunction("OnActionEnd",self.m_ID,fCallback)
end


function CPerform:OnActionEnd(oAction)
    local iBuffID = 1005
    if oAction.m_oBuffMgr:HasBuff(iBuffID)  or oAction:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 2000
    local iMaxRatio = mArgs["min_ratio"] or 1000
    local iMinRatio = mArgs["max_ratio"] or 5000
    local iRatio = oAction:AbnormalRatio(oAction,iRatio,iMaxRatio,iMinRatio)
    if in_random(iRatio,10000) then
        self:ShowPerfrom(oAction)
        oAction.m_oBuffMgr:AddBuff(iBuffID,2,{
            level = self:Level(),
            attack = oAction:GetWid(),
            })
    end

end















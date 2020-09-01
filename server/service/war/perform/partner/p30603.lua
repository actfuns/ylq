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
            oSkill:OnActionEnd(oAttack)
        end
    end
    oAction:AddFunction("OnActionEnd",self.m_ID,fCallback)
end

function CPerform:OnActionEnd(oAction)
    if oAction:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"]
    if in_random(iRatio,10000) then
        self:AddBuff(oAction)
        self:ShowPerfrom(oAction)
    end
end


function CPerform:AddBuff(oAction)
    local iBuffID = 1003
    local iBout = 3
    local oBuffMgr = oAction.m_oBuffMgr
    if oBuffMgr:HasBuff(iBuffID) then
        return
    end
    local oWar = oAction:GetWar()
    local mArgs = {
        level = self:Level(),
        attack = oAction:GetWid(),
        buff_bout = oWar.m_iBout,
    }
    if oAction:IsAwake() then
        iBout = 255
        mArgs["sub_type"] ={3}
    end
    oBuffMgr:AddBuff(iBuffID,iBout,mArgs)
end

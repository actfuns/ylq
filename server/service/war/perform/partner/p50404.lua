local skynet = require "skynet"

local global = require "global"
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
            oSkill:OnActionEnd(oAction)
        end
    end
    oAction:AddFunction("OnActionEnd",self.m_ID,fCallback)
end

function CPerform:OnActionEnd(oAction)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["attack"] or 5000
    local mEnemy = oAction:GetEnemyList()
    local iBuff = 1026
    local iDamage = math.floor(oAction:QueryAttr("attack") * iRatio / 10000)
    for _,w in pairs(mEnemy) do
        local oBuff = w.m_oBuffMgr:HasBuff(iBuff)
        if oBuff then
            self:ModifyHp(w,oAction,-iDamage)
        end
    end
end
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
    local func = function (oVictim,oAttack,oBuff)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAddedBuff(oVictim,oAttack,oBuff)
        end
    end
    oAction:AddFunction("OnAddedBuff",self.m_ID,func)
end

function CPerform:OnAddedBuff(oVictim,oAttack,oBuff)
    if oBuff:GroupType() ~= 102 then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["target_ratio"] or 450
    local iBuffID = oBuff.m_ID
    local iBout = oBuff:Bout()
    local oWar = oAttack:GetWar()
    if oBuff:IsAttackSub() then
        iBout = iBout + 1
    end
    local mBuffArgs = oBuff:GetArgs()
    if in_random(iRatio,10000) then
        self:ShowPerfrom(oVictim)
        local mNewArgs = {
            level = mBuffArgs["level"] or 1,
            attack = oVictim:GetWid(),
            buff_bout = oWar.m_iBout ,
        }
        local oBuffMgr = oAttack.m_oBuffMgr
        oBuffMgr:AddBuff(iBuffID,iBout,mNewArgs)
    end
end
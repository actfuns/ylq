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
    local fCallback = function (oVictim)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnSubHp(oVictim)
        end
        return 0
    end
    oPerformMgr:AddFunction("OnSubHp",self.m_ID,fCallback)
end

function CPerform:OnSubHp(oVictim)
    if oVictim:GetData("hp") <= 0  or  oVictim:GetData("Trigger_51103")  then
        return
    end
    local mData = self:GetSkillArgsEnv()
    local iRatio = mData["ratio"] or 5000
    local iHp = (mData["hp_ratio"] or 1000) // 100
    if in_random(iRatio,10000) and oVictim:GetHpRatio() <= iHp then
        self:ShowPerfrom(oVictim)
        oVictim:SetData("Trigger_51103",1)
        local iBuffID = 1054
        local oWar = oVictim:GetWar()
        local oBuffMgr = oVictim.m_oBuffMgr
        local oBuff = oBuffMgr:AddBuff(iBuffID,255,{level=4,attack=oVictim:GetWid(),buff_bout = oWar.m_iBout})
        if oBuff then
            oBuff:SetBuffLevel(5)
            oBuff:RefreshBuff(oVictim)
        end
    end
end



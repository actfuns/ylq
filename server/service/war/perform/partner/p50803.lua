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
    local oCamp = oAction:GetCamp()
    local iWid = oAction:GetWid()
    local iSkill = self:Type()
    local fCallback = function (oVictim)
        OnDead(oVictim,iWid,iSkill)
    end
    local iFuncNo = self.m_ID * 100 + iWid
    oCamp:AddFunction("OnDead",iFuncNo,fCallback)
end

function CPerform:OnDead(oAction,iWid)
    if not oAction:IsCallNpc() then
        return
    end
    if oAction:GetData("partner_call",0) ~= iWid then
        return
    end
    local oWar = oAction:GetWar()
    local oOwner = oWar:GetWarrior(iWid)
    if not oOwner or oOwner:IsDead() then
        return
    end
    self:ShowPerfrom(oAction)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["hp_ratio"]
    local iAddHp = math.floor(oOwner:GetMaxHp() * iRatio / 10000)
    self:ModifyHp(oOwner,oAction,iAddHp)
end

function OnDead(oVictim,iWid,iSkill)
    local oWar = oVictim:GetWar()
    if not oWar then
        return
    end
    local oOwner = oWar:GetWarrior(iWid)
    if not oOwner then
        return
    end
    local oSkill = oOwner:GetPerform(iSkill)
    if not oSkill then
        return
    end
    oSkill:OnDead(oVictim,iWid)
end
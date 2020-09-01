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
    local oCamp = oAction:GetCamp()
    local iWid = oAction:GetWid()
    local iSkill = self:Type()
    local fCallback = function (oAttack,lVictim,oPerform)
        OnPerform(oAttack,lVictim,oPerform,iWid,iSkill)
    end
    local iFuncNo = self.m_ID * 100 + iWid
    oCamp:AddFunction("OnPerform",iFuncNo,fCallback)
end

function CPerform:OnPerform(oAttack,lVictim,oPerform,iWid)
    local oWar = oAttack:GetWar()
    local oWarrior = oWar:GetWarrior(iWid)
    local mArgs = self:GetSkillArgsEnv()
    local iBuffID = 1038
    local iHpRatio = mArgs["hp_ratio"]
    if oWarrior:BanPassiveSkill() == 2 then
        return
    end
    if oWarrior.m_oBuffMgr:HasBuff(iBuffID) then
        local iAddHp = math.floor(iHpRatio*oWarrior:QueryAttr("attack")/10000)
        self:ModifyHp(oAttack,oWarrior,iAddHp)
    end
    if oAttack:GetWid() == iWid then    
        local iRatio = mArgs["ratio"] or 3000
        if in_random(iRatio,10000) then
            self:Effect_Condition_For_Victim(oWarrior,oAttack)
        end
    end
end

function OnPerform(oAttack,lVictim,oPerform,iWid,iSkill)
    local oWar = oAttack:GetWar()
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
    oSkill:OnPerform(oAttack,lVictim,oPerform,iWid)
end
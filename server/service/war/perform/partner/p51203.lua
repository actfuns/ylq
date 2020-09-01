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
    local iWid = oAction:GetWid()
    local oWar = oAction:GetWar()
    local iSkill = self:Type()
    local oCamp = oAction:GetCamp()
    local fCallback = function (oVictim,iHp,mArgs)
        OnModifyHp(oVictim,iWid,iHp,iSkill,mArgs)
    end
    local iFuncNo = self:CampFuncNo(iWid)
    oCamp:AddFunction("OnModifyHp",iFuncNo,fCallback)

end

function CPerform:OnModifyHp(oAttack,oVictim,oAction,iDamage)
    local oWar = oAttack:GetWar()
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    local iWid = oAction:GetWid()
    if oVictim:GetWid() ~= iWid then
        iRatio = mArgs["friend_ratio"] or 500
    end
    local mData = oAttack:QueryBoutArgs("target_p51203",{})
    if table_count(mData) > 0  then
        return
    end
    if not in_random(iRatio,10000) then
        return
    end
    mData[iWid] = true
    oAttack:SetBoutArgs("target_p51203",mData)
    local iBuff  = 1009
    local oBuff = oAction.m_oBuffMgr:HasBuff(iBuff)
    if not oBuff or oBuff:BuffLevel() < 5 then
        self:ShowPerfrom(oAction)
        self:Effect_Condition_For_Victim(oAction,oAttack)
    end

end


function OnModifyHp(oVictim,iWid,iHp,iSkill,mArgs)
    if iHp > 0 then
        return
    end
    local oWar = oVictim:GetWar()
    if not oWar then
        return
    end
    local iAttack = mArgs["attack"] or mArgs["attack_wid"]
    if not iAttack then
        return
    end
    local oAttack = oWar:GetWarrior(iAttack)
    if not oAttack or oAttack:IsDead() then
        return
    end
    local oOwner = oWar:GetWarrior(iWid)
    if not oOwner or oOwner:IsDead() or  oOwner:IsCallNpc() then
        return
    end
    local oSkill = oOwner:GetPerform(iSkill)
    if not oSkill then
        return
    end
    oSkill:OnModifyHp(oAttack,oVictim,oOwner,iHp)
end

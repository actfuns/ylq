--import module

local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/equip/epfobj"))

function NewCPerform(...)
    local o = CPerform:New(...)
    return o
end

CPerform = {}
CPerform.__index = CPerform
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local iWid = oAction:GetWid()
    local iFuncNo = self:CampFuncNo(oAction:GetWid())
    local oCamp = oAction:GetCamp()
    local oEnemyCamp = oAction:GetEnemyCamp()

    local fCallback = function (oAttack,iHP,mArgs)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnModifyHp(oAction,oAttack,iHP,mArgs)
        end
    end
    oCamp:AddFunction("OnModifyHp",iFuncNo,fCallback)
    oEnemyCamp:AddFunction("OnModifyHp",iFuncNo,fCallback)


    local fCallback = function (oAttack,lVictim,oPerform)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnPerform(oAction,oAttack,lVictim,oPerform)
        end
    end
    oCamp:AddFunction("OnPerform",iFuncNo,fCallback)
    oEnemyCamp:AddFunction("OnPerform",iFuncNo,fCallback)

end

function CPerform:OnModifyHp(oOwner,oAction,iHP,mData)
    if iHP < 1 or ( mData["type"] == "perform" and mData["PID"] == self:Type() ) then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 3000
    if not oOwner:Random(iRatio) then
        return
    end
    local oWar = oAction:GetWar()
    local iAttack = mData["attack_wid"] or 0
    local oAttack = oWar:GetWarrior(iAttack)
    if oAttack then
        if oAttack:QueryBoutArgs("p6006_trigger") then
            return
        end
        oAttack:SetBoutArgs("p6006_trigger",1)
    end
    local iCurHpRatio = mArgs["hp_ratio"] or 3000
    local iCurHP = (iCurHpRatio * oOwner:QueryAttr("attack"))//10000
    if iCurHP > 0 then
        local oTarget = oOwner
        local mFriend = oOwner:GetFriendList()
        for _,o in ipairs(mFriend) do
            if o:GetHpRatio() < oTarget:GetHpRatio() then
                oTarget = o
            end
        end
        if oTarget then
            self:ShowPerfrom(oOwner)
            self:ModifyHp(oTarget,oOwner,iCurHP,{attack_wid=oOwner:GetWid()})
        end
    end

end

function CPerform:OnPerform(oAction,oAttack,lVictim,oPerform)
    if oAttack:QueryBoutArgs("p6006_trigger") then
        oAttack:SetBoutArgs("p6006_trigger",nil)
    end
end


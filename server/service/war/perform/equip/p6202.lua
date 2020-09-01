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
    local oCamp = oAction:GetEnemyCamp()
    local fCallback = function (oAttack,iHP,oVictim)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return 0
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCure(oAction,oAttack,iHP,oVictim)
        end
        return 0
    end
    oCamp:AddFunction("OnCure",iFuncNo,fCallback)

    local fCallback = function (oAttack,oPerform)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return 0
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:PerformStart(oAction,oAttack,oPerform)
        end
        return 0
    end
    oCamp:AddFunction("PerformStart",iFuncNo,fCallback)

    local fCallback = function (oAttack,lVictim,oPerform)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return 0
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnPerform(oAction,oAttack,lVictim,oPerform)
        end
        return 0
    end
    oCamp:AddFunction("OnPerform",iFuncNo,fCallback)


end

function CPerform:OnCure(oAction,oAttack,iHP,oVictim)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio =mArgs["ratio"] or 1000
    
    if iHP <= 0 then
        return 0
    end

    if  oAction:Random(iRatio) then
        if oAction:QueryBoutArgs("p6202") then
            if oAction:QueryBoutArgs("p6202") > 0 then
                return 0
            else
                oAction:SetBoutArgs("p6202",1)
            end
        end
        self:ShowPerfrom(oAction)
        local iCur = iHP
        if oVictim:GetData("hp") <1 then
            iCur = iCur - 1
        end
        local mFriend = oAction:GetFriendList()
        local oTarget = oAction
        for _,o in ipairs(mFriend) do
            if oTarget:GetHpRatio() > o:GetHpRatio() then
                oTarget = o
            end
        end
        oTarget:ModifyHp(iHP,{attack_wid = oAction:GetWid(),steal = oAction:GetWid() })
        return -iCur
    end

    return 0
end

function CPerform:PerformStart(oAction,oAttack,oPerform)
    if not oAction:QueryBoutArgs("p6202") then
        oAction:SetBoutArgs("p6202",0)
    end
end

function CPerform:OnPerform(oAction,oAttack,lVictim,oPerform)
    if oAction:QueryBoutArgs("p6202") then
        oAction:SetBoutArgs("p6202",nil)
    end
end




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
    local fCallback = function (oAttack,oBuff)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAddBuffHandle(oAction,oAttack,oBuff)
        end
    end
    oCamp:AddFunction("OnAddBuffHandle",iFuncNo,fCallback)

end

function CPerform:OnAddBuffHandle(oAction,oAttack,oBuff)
    if oBuff:Type() ~= gamedefines.BUFF_TYPE.CLASS_ABNORMAL then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if not in_random(iRatio,10000) then
        return
    end
    local oWar = oAction:GetWar()
    local oWarrior = oWar:GetWarrior(oBuff:GetAttack())
    if oWarrior then
        if oWarrior:QueryBoutArgs("p6206_attr") then
            return
        end
        oWarrior:SetBoutArgs("p6206_attr",1)
    end
    self:ShowPerfrom(oAction)
    local iCnt = mArgs["cnt"] or 1
    local oBuffMgr = oAttack.m_oBuffMgr
    for i=1,iCnt do
        oBuff:SubBout(1)
        if oBuff:Bout() <1 then
            oBuffMgr:RemoveBuff(oBuff)
            break
        else
            oBuff:RefreshBuff(oAttack)
        end
    end

end







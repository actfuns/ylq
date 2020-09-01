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
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:Perform(oAttack,lVictim)
    super(CPerform).Perform(self,oAttack,lVictim)
    local oActionMgr = global.oActionMgr
    if not oAttack or oAttack:IsDead() then
        return
    end
    local oWar = oAttack:GetWar()
    local iTarget = self.m_Target
    local oTarget = oWar:GetWarrior(iTarget)
    if not oTarget or oTarget:IsDead() then
        return
    end
    self:SetData("PerformAttackCnt",4)
    oActionMgr:DoAttack(oAttack,oTarget,self,100)
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,3)
end
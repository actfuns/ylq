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
    local mFriend = oAction:GetFriendList()
    local iWid = oAction:GetWid()
    local iSkill = self:Type()
    local fCallback = function (oWarrior)
        OnDead(oWarrior,iWid,iSkill)
    end
    local iFuncNo = self.m_ID * 100 + iWid
    oCamp:AddFunction("OnDead",iFuncNo,fCallback)
end

function CPerform:OnDead(oAction,iWid)
    if oAction:IsCallNpc() then
        return
    end
    if not oAction:IsDead() then
        return
    end
    local oWar = oAction:GetWar()
    local oUse = oWar:GetWarrior(iWid)
    if not oUse then
        return
    end
    if oUse:IsDead() then
        return
    end
    if oAction:GetWid() == iWid then
        return
    end
    local iCnt = self:GetData("attack_add_cnt",0)
    if iCnt >= 5 then
        return
    end
    iCnt = iCnt + 1
    self:SetData("attack_add_cnt",iCnt)
    self:ShowPerfrom(oUse)
    self:Effect_Condition_For_Attack(oUse)
end

function OnDead(oAction,iWid,iSkill)
    local oWar = oAction:GetWar()
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
    oSkill:OnDead(oAction,iWid)
end
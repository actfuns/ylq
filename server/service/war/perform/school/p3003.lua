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

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    self:Effect_Condition_For_Victim(oVictim,oAttack)
end

function CPerform:ChooseAITarget(oAttack)
    local iBuffID = 101
    local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
    if not oBuff then
        return oAttack:GetWid()
    end
    local mFriend = oAttack:GetFriendList()
    for _,w in pairs(mFriend) do
        if not w:IsNpc() then
            return w:GetWid()
        end
    end
    return oAttack:GetWid()
end
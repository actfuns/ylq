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
    local oWar = oAttack:GetWar()
    if not oAttack:IsFriend(oVictim) then
        return
    end
    if not oVictim:IsAction() then
        oVictim:SetBoutArgs("speed",100000)
    end
end

function CPerform:Perform(oAttack,lVictim)
    super(CPerform).Perform(self,oAttack,lVictim)
    local mFriend = oAttack:GetFriendList()
    for _,w in pairs(mFriend) do
        self:Effect_Condition_For_Victim(w,oAttack)
    end
end

function CPerform:ChooseAITarget(oAttack)
    local mFriend = oAttack:GetFriendList()
    local mSpeed = {}
    for _,w in pairs(mFriend) do
        if not w:IsDead() and w:GetWid() ~= oAttack:GetWid() and w:GetSpeed() < oAttack:GetSpeed()  then
            table.insert(mSpeed,w)
        end
    end
    if #mSpeed > 0 then
        local w = mSpeed[math.random(#mSpeed)]
        return w:GetWid()
    else
        return super(CPerform).ChooseAITarget(self,oAttack)
    end
end
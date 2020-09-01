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
    if not oVictim or oVictim:IsDead() then
        return
    end
    self:Effect_Condition_For_Victim(oVictim,oAttack)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["hp_ratio"]
    local iDamage = math.floor(oAttack:GetHp() * iRatio / 10000)
    if iDamage > 0 then
        self:ModifyHp(oAttack,oAttack,-iDamage)
    end
end

function CPerform:ChooseAITarget(oAttack)
    local iBuffID = 110
    local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
    if not oBuff then
        return oAttack:GetWid()
    end
    local mFriend = oAttack:GetFriendList()
    for _,w in pairs(mFriend) do
        local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
        if not oBuff and not w:IsNpc() then
            return w:GetWid()
        end
    end
    return oAttack:GetWid()
end
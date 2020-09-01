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
    super(CPerform).TruePerform(self,oAttack,oVictim,iDamageRatio)
    if not oVictim:IsDead() or oAttack:IsDead()  or not oAttack:IsAwake() then
        return
    end
    local iBuffID = 1005
    oAttack.m_oBuffMgr:AddBuff(iBuffID,2,{
            level = self:Level(),
            attack = oAttack:GetWid(),
    })
end


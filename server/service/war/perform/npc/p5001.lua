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


function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    if not oVictim or oVictim:IsDead() then
        return
    end
    if self:CheckEffectRatio(oAttack,oVictim) then
        super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)
    end
end


function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnReceivedDamage",self.m_ID,fCallback)
    local fCallback = function (oVictim)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnDead(oVictim)
        end
        return 0
    end
    oAction:AddFunction("OnDead",self.m_ID,fCallback)
end


function CPerform:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
    local oWarrioList = {}
    local mWarriro = {}
    list_combine(mWarriro,oVictim:GetFriendList())
    list_combine(mWarriro,oVictim:GetEnemyList())
    local iRatio
    for _,oWarrior in ipairs(mWarriro) do
        local oBuff = oWarrior.m_oBuffMgr:HasBuff(1049)
        if oBuff and oWarrior:GetWid() ~=  oVictim:GetWid() then
            if  not iRatio then
                local mBuff = oBuff:GetSetAttr()
                iRatio = mBuff["share_damage"]
            end
            table.insert(oWarrioList,oWarrior)
        end
    end
    if #oWarrioList > 0  and iRatio then
        local iShareDamage =  iDamage*iRatio/100
        local iHit  = iShareDamage/#oWarrioList
        if iHit < 1 then
            iHit = 1
        end
        for _,oWarrior  in  ipairs(oWarrioList) do
            self:ModifyHp(oWarrior,oAttack,-iHit)
        end
        return -iShareDamage
    else
        return 0
    end
end

function CPerform:OnDead(oAction)
    local iWid = oAction:GetWid()
    local mEnemyList = oAction:GetEnemyList()
    for _,o in ipairs(mEnemyList) do
        local oBuff = o.m_oBuffMgr:HasBuff(1049)
        if oBuff and oBuff:GetAttack() == iWid then
            o.m_oBuffMgr:RemoveBuff(oBuff)
        end
    end
end


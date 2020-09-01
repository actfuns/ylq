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
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oVictim,args)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnDead(oVictim,args)
        end
    end
    oAction:AddFunction("OnDead",self.m_ID,fCallback)
end

function CPerform:OnDead(oAction)
    if self:FinalDead(oAction) then
        return
    end
    local mEnemy = oAction:GetEnemyList()
    local iBuffID = 1012
    local bShow = false
    for _,w in pairs(mEnemy) do
        local oBuff = w.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            bShow = true
            local iLevel = oBuff:BuffLevel()
            local iDamage = math.floor(oAction:QueryAttr("attack") * iLevel / 2)
            w.m_oBuffMgr:RemoveBuff(oBuff)
            self:ModifyHp(w,oAction,-iDamage)
        end
    end
    if bShow then
        self:ShowPerfrom(oAction)
    end
end

function CPerform:FinalDead(oAction)
    local mFriend = oAction:GetFriendList()
    local iCnt = 0
    for _,w in pairs(mFriend) do
        if w and not w:IsDead() then
            iCnt = iCnt + 1
        end
    end
    if iCnt <= 0 then
        return true
    end
    return false
end

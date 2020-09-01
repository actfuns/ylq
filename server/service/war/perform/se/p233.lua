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
    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnWarStart(oAttack)
        end
    end
    oAction:AddFunction("OnWarStart",self.m_ID,fCallback)
end

function CPerform:OnWarStart(oAction)
    self:ShowPerfrom(oAction)
    local mArgs = self:GetSkillArgsEnv()
    local iHpRatio = mArgs["hp_ratio"] or 1000
    local iShield = math.floor(oAction:GetMaxHp() * iHpRatio / 10000)
    local mData = self:GetSkillData()
    local mBuff = mData["victimBuff"] or {}
    local mFriend = oAction:GetFriendList()
    for _,w in pairs(mFriend) do
        for _,mData in pairs(mBuff) do
            local iBuffID = mData["buffid"]
            local iBout = mData["bout"]
            w.m_oBuffMgr:AddBuff(iBuffID,iBout,{
                level = self:Level(),
                attack = oAction:GetWid(),
                shield = iShield,
            })
        end
    end
end
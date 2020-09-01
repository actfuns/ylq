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
    if not oAction:IsAwake() then
        return
    end
    local iSkill = self:Type()
    local iWid = oAction:GetWid()
    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnDead(oAttack)
        end
    end
    oAction:AddFunction("OnDead",self.m_ID,fCallback)

end

function CPerform:OnDead(oAction)
    if self:FinalDead(oAction) then
        return
    end
    self:ShowPerfrom(oAction)
    local mArgs = self:GetSkillArgsEnv()
    local mSkillData = self:GetSkillData()
    local mRatio = formula_string(mSkillData["damage_ratio"],{})
    local iRatio = mRatio[1]
    local iBuffCnt = 0
    local oBuff = oAction.m_oBuffMgr:HasBuff(1053)
    if oBuff then
        iBuffCnt = oBuff:BuffLevel()
        iRatio = iRatio + (oBuff:BuffLevel() * (mArgs["damage_ratio"] or 20)) * 100
    end
    local iAttack = oAction:QueryAttr("attack")
    local iHP = math.floor(iRatio * iAttack / 10000)
    local mEnemyList = oAction:GetEnemyList()
    local lSelectWid = {}
    for _,o in ipairs(mEnemyList) do
        table.insert(lSelectWid,o:GetWid())
    end
    if #lSelectWid == 0 then
        return
    end
    oAction:SendAll("GS2CWarSkill", {
        war_id = oAction:GetWarId(),
        action_wlist = {oAction:GetWid(),},
        select_wlist = lSelectWid,
        skill_id = 51303,
        magic_id = 1,
    })
    for _,oWarrior in ipairs(mEnemyList) do
        self:ModifyHp(oWarrior,oAction,-iHP,{attack_wid=oAction:GetWid()})
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

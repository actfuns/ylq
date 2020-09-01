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
    if not oAttack or oAttack:IsDead() then
        return
    end
    if not oAttack:QueryBoutArgs("victim_dead") then
        return
    end
    local oActionMgr = global.oActionMgr
    local mArgs = self:GetSkillArgsEnv()
    local iMaxCnt = mArgs["enemy_max_cnt"] or 2
    local iCnt = iMaxCnt - 1
    for i = 1,iCnt do
        local mVictim = oAttack:GetEnemyList()
        if #mVictim < 1 then
            return
        end
        local oVictim = mVictim[1]
        oAttack:SendAll("GS2CWarSkill", {
            war_id = oAttack:GetWarId(),
            action_wlist = {oAttack:GetWid(),},
            select_wlist = {oVictim:GetWid()},
            skill_id = self.m_ID,
            magic_id = 2,
        })
        local iAttackCnt = mArgs["attack_cnt"] or 4
        oActionMgr:DoMultiAttack(oAttack,oVictim,self,100,iAttackCnt)
        if not oAttack or oAttack:IsDead() then
            return
        end
    end
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    local mArgs = self:GetSkillArgsEnv()
    local iAttackCnt = mArgs["attack_cnt"] or 4
    local iMaxCnt = mArgs["enemy_max_cnt"] or 2
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,iAttackCnt)
    if not oVictim or oVictim:IsDead() then
        oAttack:SetBoutArgs("victim_dead",true)
    end
end
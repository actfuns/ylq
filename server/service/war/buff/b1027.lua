--import module

local global = require "global"
local skynet = require "skynet"

local buffbase = import(service_path("buff/buffbase"))

function NewBuff(...)
    local o = CBuff:New(...)
    return o
end

CBuff = {}
CBuff.__index = CBuff
inherit(CBuff, buffbase.CBuff)

function CBuff:CalInit(oWarrior,oBuffMgr)
    local War = oWarrior:GetWar()
    local iBout = War.m_iBout
    local iBuffID = self.m_ID
    local fCallback = function (oAction)
        local oBuff = oAction.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnCommand(oAction)
        end
    end
    oBuffMgr:AddFunction("OnCommand",self.m_ID,fCallback)
end

function CBuff:OnCommand(oAction)
    local oWar = oAction:GetWar()
    local mCmds = oWar:GetBoutCmd(oAction:GetWid())
    if not mCmds then
        return
    end
    local cmd = mCmds.cmd
    local mSkillData = mCmds.data
    local iAction = mSkillData["action_wlist"]
    if not iAction then
        iAction = oAction:GetWid()
    end
    local lVictim = mSkillData["select_wlist"]
    if not lVictim then
        local mEnemy = oAction:GetEnemyList()
        if #mEnemy <= 0 then
            return
        end
        lVictim = {mEnemy[1]}
    end
    local mCmds = {
        cmd = "skill",
        data = {
            action_wlist = {iAction},
            select_wlist = lVictim,
            skill_id = oAction:GetNormalAttackSkillId(),
        }
    }
    return mCmds
end

function CBuff:OnRemove(oAction,oBuffMgr)
    local iAttack = self.m_mArgs["attack"]
    local oWar = oAction:GetWar()
    local oAttack = oWar:GetWarrior(iAttack)
    if not oAttack then
        return
    end
    if not oAttack:IsAwake() or oAttack:BanPassiveSkill() == 2 then
        return
    end
    local iAttack = oAttack:QueryAttr("attack")
    local oSkill = oAttack:GetPerform(31203)
    if oSkill then
        oSkill:ShowPerfrom(oAttack)
    end
    if oAttack:IsFriend(oAction) then
        local iRatio = oAttack:Query("buff_hp_ratio",5000)

        local iAddHp = math.floor(iAttack * iRatio / 10000)
        self:ModifyHp(oAction,iAddHp)
    else
        local iRatio = oAttack:Query("buff_damage_ratio",5000)
        local iDamage = math.floor(iAttack * iRatio / 10000)
        self:ModifyHp(oAction,-iDamage)
    end
end
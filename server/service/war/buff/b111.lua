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
    local func = function (oAction)
        local oBuff = oAction.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnCommand(oAction)
        end
    end
    oBuffMgr:AddFunction("OnCommand",self.m_ID,func)
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
--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"

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
    local cmd = mCmds.cmd
    local mSkillData = mCmds.data
    if not self.m_mArgs["parg"] or not self.m_mArgs["parg"]["target"] then
        return mCmds
    end
    local iTarget = self.m_mArgs["parg"]["target"]
    local oTarget = oWar:GetWarrior(iTarget)
    if not oTarget or oTarget:IsDead() then
        return mCmds 
    end
    local mCmds = {
        cmd = "skill",
        data = {
            action_wlist = {oAction:GetWid()},
            select_wlist = {iTarget,},
            skill_id = oAction:GetNormalAttackSkillId(),
        }
    }
    return mCmds
end
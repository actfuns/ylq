--import module
local skynet = require "skynet"
local global = require "global"
local record = require "public.record"
local interactive = require "base.interactive"

local datactrl = import(lualib_path("public.datactrl"))
local loadskill = import(service_path("skill/loadskill"))

local max = math.max
local min = math.min

CSkillCtrl = {}
CSkillCtrl.__index = CSkillCtrl
inherit(CSkillCtrl, datactrl.CDataCtrl)

function CSkillCtrl:New(iPid)
    local o = super(CSkillCtrl).New(self, {pid = iPid})
    o.m_iPid = iPid
    o:ConfirmRemote()
    return o
end

function CSkillCtrl:GetPid()
    return self.m_iPid
end

function CSkillCtrl:ConfirmRemote()
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local iRemoteAddr = oAssistMgr:SelectRemoteAssist(iPid)
    self.m_iRemoteAddr = iRemoteAddr
end

function CSkillCtrl:GetSchoolNormalAttackId(oPlayer)
    local iSchool = oPlayer:GetSchool()
    local iSchoolBranch = oPlayer:GetSchoolBranch()
    local mSkill = loadskill.GetSchoolSkill(iSchool,iSchoolBranch)
    for _,iSk in ipairs(mSkill) do
        if iSk % 10 == 1 then
            return iSk
        end
    end
end

function CSkillCtrl:WashSchoolSkill(iShape,iAmount,sReason,mArgs,fCallback)
    local iPid = self:GetPid()
    mArgs = mArgs or {}

    interactive.Request(self.m_iRemoteAddr, "skill", "WashSchoolSkill", {
        pid = iPid,
        shape = iShape,
        amount = iAmount,
        reason = sReason,
        args = mArgs
    }, fCallback)
end

function CSkillCtrl:LearnSchoolSkill(iSkill,iNewLevel,sReason,fCallback)
    local iPid = self:GetPid()
    interactive.Request(self.m_iRemoteAddr, "skill", "LearnSchoolSkill", {
        pid = iPid,
        skill = iSkill,
        level = iNewLevel,
        reason = sReason,
    }, fCallback)
end


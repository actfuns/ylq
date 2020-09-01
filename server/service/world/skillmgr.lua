--import module

local global = require "global"
local skynet = require "skynet"

local attrmgr = import(lualib_path("public.attrmgr"))
local shareobj = import(lualib_path("base.shareobj"))

function NewSkillMgr(pid)
    local o = CSkillMgr:New(pid)
    return o
end

CSkillMgr = {}
CSkillMgr.__index =CSkillMgr
inherit(CSkillMgr,attrmgr.CAttrMgr)

function CSkillMgr:New(iPid)
    local o = super(CSkillMgr).New(self,iPid)
    o.m_oSkillMgrShareObj = CSkillMgrShareObj:New()
    return o
end

function CSkillMgr:Release()
    baseobj_safe_release(self.m_oSkillMgrShareObj)
    super(CSkillMgr).Release(self)
end

function CSkillMgr:InitShareObj(oRemoteShare)
    self.m_oSkillMgrShareObj:Init(oRemoteShare)
end

function CSkillMgr:ShareUpdate()
    self.m_oSkillMgrShareObj:Update()
end

function CSkillMgr:GetApply(sApply)
    local mApply = self.m_oSkillMgrShareObj:GetApply(sApply)
    local iValue = 0
    for _,v in pairs(mApply) do
        iValue = iValue + v
    end
    return iValue
end

function CSkillMgr:GetRatioApply(sApply)
    local mRatioApply = self.m_oSkillMgrShareObj:GetRatioApply(sApply)
    local iValue = 0
    for _,v in pairs(mRatioApply) do
        iValue = iValue + v
    end
    return iValue
end

function CSkillMgr:GetSkillLevel(iSkill)
    return self.m_oSkillMgrShareObj:GetSkillLevel(iSkill)
end

CSkillMgrShareObj = {}
CSkillMgrShareObj.__index = CSkillMgrShareObj
inherit(CSkillMgrShareObj, shareobj.CShareReader)

function CSkillMgrShareObj:New()
    local o = super(CSkillMgrShareObj).New(self)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    o.m_mSkillLevel = {}
    return o
end

function CSkillMgrShareObj:Unpack(m)
    self.m_mApply = m.apply or self.m_mApply
    self.m_mRatioApply = m.ratio_apply or self.m_mRatioApply
    self.m_iEquipPower = m.power or self.m_iEquipPower
    self.m_mSkillLevel = m.skill_level or self.m_mSkillLevel
end

function CSkillMgrShareObj:GetApply(sApply)
    return self.m_mApply[sApply] or {}
end

function CSkillMgrShareObj:GetRatioApply()
    return self.m_mRatioApply[sApply] or {}
end

function CSkillMgrShareObj:GetSkillLevel(iSkill)
    return self.m_mSkillLevel[iSkill]
end
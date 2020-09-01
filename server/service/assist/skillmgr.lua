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
    o.m_iPid = iPid
    o.m_mLevel = {}
    o.m_oSkillMgrShareObj = CSkillMgrShareObj:New()
    o.m_oSkillMgrShareObj:Init()
    return o
end

function CSkillMgr:Release()
    baseobj_safe_release(self.m_oSkillMgrShareObj)
    super(CSkillMgr).Release(self)
end

function CSkillMgr:PackRemoteData()
    return {
        apply = self.m_mApply,
        ratio_apply = self.m_mRatioApply,
        skill_level = self.m_mLevel
    }
end

function CSkillMgr:UpdateSkillLevel(mLevel)
    self.m_mLevel = mLevel or self.m_mLevel
end

function CSkillMgr:GetSkillMgrReaderCopy()
    return self.m_oSkillMgrShareObj:GenReaderCopy()
end

function CSkillMgr:ShareUpdate()
    self:UnDirty()
    local mData = self:PackRemoteData()
    self.m_oSkillMgrShareObj:UpdateData(mData)
end

CSkillMgrShareObj = {}
CSkillMgrShareObj.__index = CSkillMgrShareObj
inherit(CSkillMgrShareObj, shareobj.CShareWriter)

function CSkillMgrShareObj:New()
    local o = super(CSkillMgrShareObj).New(self)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    o.m_mLevel = {}
    return o
end

function CSkillMgrShareObj:UpdateData(mData)
    self.m_mApply = mData.apply or self.m_mApply
    self.m_mRatioApply = mData.ratio_apply or self.m_mRatioApply
    self.m_mLevel= mData.skill_level or self.m_mLevel
    self:Update()
end

function CSkillMgrShareObj:Pack()
    local m = {}
    m.apply = self.m_mApply
    m.ratio_apply = self.m_mRatioApply
    m.skill_level = self.m_mLevel
    return m
end
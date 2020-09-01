--import module

local global = require "global"

local datactrl = import(lualib_path("public.datactrl"))

CSkill = {}
CSkill.__index =CSkill
CSkill.m_sType = "base"
inherit(CSkill,datactrl.CDataCtrl)

function CSkill:New(iSk)
    local o = super(CSkill).New(self)
    o.m_ID = iSk
    o:Init()
    return o
end

function CSkill:Init()
    self:SetData("level", 0)
    self.m_mApply = {}
    self.m_mRatioApply = {}
end

function CSkill:Save()
    local mData = {}
    mData["level"] = self:GetData("level")
    return mData
end

function CSkill:Load(mData)
    mData = mData or {}
    self:SetData("level", mData.level)
end

function CSkill:GetSkillData()
    local res = require "base.res"
    local mData = res["daobiao"]["skill"]
    return mData[self.m_ID]
end

function CSkill:ID()
    return self.m_ID
end

function CSkill:Name()
    return self:GetSkillData()["name"]
end

function CSkill:Level()
    return self:GetData("level")
end

function CSkill:SetLevel(iLevel)
    self:SetData("level", iLevel)
    self:Dirty()
end

function CSkill:Type()
    return self.m_sType
end

function CSkill:LimitLevel()
    return 10
end

function CSkill:AddApply(sApply,iValue)
    local iApply = self.m_mApply[sApply] or 0
    self.m_mApply[sApply] = iApply + iValue
end

function CSkill:GetApply(sApply,rDefault)
    rDefault = rDefault or 0
    return self.m_mApply[sApply] or rDefault
end

function CSkill:AddRatioApply(sApply, iValue)
    local iApply = self.m_mRatioApply[sApply] or 0
    self.m_mRatioApply[sApply] = iApply + iValue
end

function CSkill:GetRatioApply(sApply, rDefault)
    rDefault = rDefault or 0
    return self.m_mRatioApply[sApply] or rDefault
end

function CSkill:SkillEffect(oPlayer)
    --
end

function CSkill:SkillUnEffect(oPlayer)
    --
end

function CSkill:LearnNeedCost(iLevel)
end

function CSkill:PackNetInfo()
    return {}
end
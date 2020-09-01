--import module

local global = require "global"
local skilobj = import(service_path("skill/skillobj"))

CSchoolSkill = {}
CSchoolSkill.__index = CSchoolSkill
CSchoolSkill.m_sType = "school"
inherit(CSchoolSkill,skilobj.CSkill)

function CSchoolSkill:New(iSk)
    local o = super(CSchoolSkill).New(self,iSk)
    return o
end

function CSchoolSkill:GetSkillData()
    local res = require "base.res"
    local mData = res["daobiao"]["skill"][self.m_ID]
    assert(mData,string.format("GetSkillData err:%s",self.m_ID))
    return mData
end

function CSchoolSkill:GetInitSkillData()
    local res = require "base.res"
    local mData = res["daobiao"]["init_skill"][self.m_ID]
    assert(mData,string.format("init_skill err",self.m_ID))
    return mData
end

function CSchoolSkill:UnLockGrade()
    local mData = self:GetInitSkillData()
    local iGrade = mData["unlock_grade"]
    return iGrade
end

function CSchoolSkill:Name()
    local mData = self:GetInitSkillData()
    local sName = mData["skill_name"]
    return sName
end

function CSchoolSkill:LearnNeedCost(iLevel)
    iLevel = iLevel or self:Level() + 1
    local mData = self:GetSkillData()
    mData = mData[iLevel]
    if mData then
        return mData["skill_point"]
    else
        return 10000
    end
end

function CSchoolSkill:LimitGrade(iLevel)
    local mData = self:GetSkillData()
    iLevel = iLevel or self:Level() + 1
    mData = mData[iLevel]
    if mData then
        return mData["player_level"]
    end
    return 100
end

function CSchoolSkill:PackNetInfo()
    local mNet = {}
    mNet["sk"] = self.m_ID
    mNet["level"] = self:Level()
    mNet["type"] = 1
    mNet["needcost"] = self:LearnNeedCost()
    return mNet
end

function CSchoolSkill:SkillEffect(oPlayer)
end

function CSchoolSkill:SkillUnEffect(oPlayer)
end

function CSchoolSkill:LimitLevel(oPlayer)
    return 100
end

function NewSkill(iSk)
    local o = CSchoolSkill:New(iSk)
    return o
end
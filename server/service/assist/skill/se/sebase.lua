--import module

local global = require "global"
local skillobj = import(lualib_path("public.skillobj"))

function NewSkill(iSk)
    local o = CSESkill:New(iSk)
    return o
end

CSESkill = {}
CSESkill.__index = CSESkill
CSESkill.m_sType = "se"
inherit(CSESkill,skillobj.CSkill)

function CSESkill:New(iSk)
    local o = super(CSESkill).New(self,iSk)
    return o
end

function CSESkill:Save()
    local mData = {}
    mData["skill_id"] = self.m_ID
    mData["level"] = self:GetData("level")
    return mData
end

function CSESkill:Load(mData)
    mData = mData or {}
    self:SetData("level",mData["level"] or 1)
end

function CSESkill:Level()
    return self:GetData("level", 1)
end

function CSESkill:GetSkillData()
    local res = require "base.res"
    local mData = res["daobiao"]["skill"][self.m_ID]
    assert(mData,string.format("GetSkillData err:%s",self.m_ID))
    return mData
end

function CSESkill:Name()
    local mData = self:GetSkillData()
    local iLevel = self:Level()
    mData = mData[iLevel]
    return mData["name"]
end

function CSESkill:SkillEffect(oPlayer)
    local mData = self:GetSkillData()
    local iLevel = self:Level()
    mData = mData[iLevel]
    local mEnv = {}
    local sArgs = mData["attr_ratio_list"]
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs, mEnv)
        for sApply,iValue in pairs(mArgs) do
            oPlayer.m_oSkillMgr:AddRatioApply(sApply, self:ID(), iValue)
            self:AddRatioApply(sApply, iValue)
        end
    end
    local sArgs = mData["attr_value_list"]
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs, mEnv)
        for sApply,iValue in pairs(mArgs) do
            oPlayer.m_oSkillMgr:AddApply(sApply, self:ID(), iValue)
            self:AddApply(sApply, iValue)
        end
    end
end

function CSESkill:SkillUnEffect(oPlayer)
    for sApply,iValue in pairs(self.m_mApply) do
        oPlayer.m_oSkillMgr:AddApply(sApply,self:ID(), -iValue)
    end
    self.m_mApply = {}

    for sApply, iValue in pairs(self.m_mRatioApply) do
        oPlayer.m_oSkillMgr:AddRatioApply(sApply, self:ID(), -iValue)
    end
    self.m_mRatioApply = {}
end

function CSESkill:IsEffect()
    local mData = self:GetSkillData()
    local iLevel = self:Level()
    mData = mData[iLevel]
    if mData["effect_type"] == 1 then
        return true
    end
    return false
end
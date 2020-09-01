--import module

local global = require "global"
local skillobj = import(service_path("skill/skillobj"))


function NewSkill(iSk)
    local o = CCultivateSkill:New(iSk)
    return o
end

CCultivateSkill = {}
CCultivateSkill.__index = CCultivateSkill
CCultivateSkill.m_sType = "cultivate"
inherit(CCultivateSkill, skillobj.CSkill)

function CCultivateSkill:New(iSk)
    local o = super(CCultivateSkill).New(self,iSk)
    o:Init()
    return o
end

function CCultivateSkill:Init()
    super(CCultivateSkill).Init(self)
    self:SetData("exp", 0)
end

function CCultivateSkill:Save()
    local mData = {}
    mData["level"] = self:Level()
    mData["exp"] = self:GetData("exp")
    return mData
end

function CCultivateSkill:Load(mData)
    super(CCultivateSkill).Load(self, mData)
    self:SetData("exp", mData.exp or 0)
end

function CCultivateSkill:Exp()
    return self:GetData("exp", 0)
end

function CCultivateSkill:GetSkillData()
    local res = require "base.res"
    local mData = res["daobiao"]["cultivate_skill"][self:ID()]
    assert(mData,string.format("GetSkillData err:%s",self:ID()))
    return mData
end

function CCultivateSkill:GetUpGradeExp()
    local mData = self:GetSkillData()
    local iLevel = self:GetData("level") + 1
    return mData[iLevel]["upgrade_total_exp"]
end

function CCultivateSkill:GetUpGradeGainExp()
    local mData = self:GetSkillData()
    local iLevel = self:GetData("level")
    iLevel = math.max(iLevel, 1)
    return mData[iLevel]["upgrade_gain_exp"]
end

function CCultivateSkill:LearnNeedCostCoin()
    local iLevel = self:GetData("level") + 1
    local mData = self:GetSkillData()
    mData = mData[iLevel]
    assert(mData, string.format("LearnNeedCostCoin err %s, %s", self:ID(), iLevel))
    return mData.cost_coin
end

function CCultivateSkill:LearnNeedCostItem()
    local iLevel = self:GetData("level") + 1
    local mData = self:GetSkillData()
    mData = mData[iLevel]
    assert(mData, string.format("LearnNeedCostItem err %s, %s", self:ID(), iLevel))
    local mCost = mData.cost_item
    return mCost.itemid, mCost.cost_amount
end

function CCultivateSkill:GetExpCriticalRatio()
    local iLevel = self:GetData("level") + 1
    local mData = self:GetSkillData()
    mData = mData[iLevel]
    assert(mData, string.format("GetExpCriticalRatio err %s, %s", self:ID(), iLevel))
    return mData.exp_critical_ratio
end

function CCultivateSkill:LimitLevel()
    return 30
end

function CCultivateSkill:IsMaxLevel()
    return self:Level() >= self:LimitLevel()
end

function CCultivateSkill:SkillEffect(oPlayer)
    local iLevel = self:Level()
    if iLevel <= 0 then
        return
    end
    local mData = self:GetSkillData()
    mData = mData[iLevel]
    local mEffect = mData["skill_effect"] or {}
    for _,sEffect in ipairs(mEffect) do
        local sApply,sFormula = string.match(sEffect,"(.+)=(.+)")
        if sApply and sFormula then
            local iValue = formula_string(sFormula, {level=self:Level()})
            iValue = math.floor(iValue)
            oPlayer.m_oSkillMgr:AddApply(sApply, self:ID(), iValue)
            oPlayer.m_oPartnerCtrl:AddApply(sApply, iValue)
            self:AddApply(sApply,iValue)
        end
    end

    local mEnv = {}
    local sArgs = mData["attr_ratio_list"]
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs, mEnv)
        for sApply,iValue in pairs(mArgs) do
            oPlayer.m_oSkillMgr:AddRatioApply(sApply, self:ID(), iValue)
            oPlayer.m_oPartnerCtrl:AddRatioApply(sApply, iValue)
            self:AddRatioApply(sApply, iValue)
        end
    end
end

function CCultivateSkill:SkillUnEffect(oPlayer)
    for sApply,iValue in pairs(self.m_mApply) do
        oPlayer.m_oSkillMgr:AddApply(sApply,self:ID(), -iValue)
        oPlayer.m_oPartnerCtrl:AddApply(sApply, -iValue)
    end
    self.m_mApply = {}

    for sApply, iValue in pairs(self.m_mRatioApply) do
        oPlayer.m_oSkillMgr:AddRatioApply(sApply, self:ID(), -iValue)
        oPlayer.m_oPartnerCtrl:AddRatioApply(sApply, -iValue)
    end
    self.m_mRatioApply = {}
end

function CCultivateSkill:AddExp(oPlayer, iAddExp, sReason)
    local iPid = oPlayer:GetPid()
    assert(iAddExp > 0, string.format("cultivate skill err: %s,%s,%s",iPid, self:ID(), iAddExp))
    assert(not self:IsMaxLevel(), string.format("cultivate skill err: %s,%s",iPid, self:ID()))
    
    self:Dirty()
    local iMaxExp = self:GetUpGradeExp()
    local iExp = self:GetData("exp")
    iExp = iExp + iAddExp
    local bUpGrade = false
    while (iExp >= iMaxExp) do
        iExp = iExp - iMaxExp
        self:SkillUnEffect(oPlayer)
        local iLevel = self:GetData("level")
        self:SetLevel(iLevel + 1)
        self:SkillEffect(oPlayer)
        bUpGrade = true
        if self:IsMaxLevel() then
            iExp = 0
            break
        end
        iMaxExp = self:GetUpGradeExp()
    end
    self:SetData("exp", iExp)
    return bUpGrade
end

function CCultivateSkill:PackNetInfo()
    local mNet = {}
    mNet["sk"] = self:ID()
    mNet["level"] = self:GetData("level")
    mNet["exp"] = self:GetData("exp")
    return mNet
end

function CCultivateSkill:GS2CRefresh(oPlayer)
    if oPlayer then
        oPlayer:Send("GS2CRefreshCultivateSKill", {
            skill_info = self:PackNetInfo(),
            })
    end
end
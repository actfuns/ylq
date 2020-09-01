local global = require "global"

local datactrl = import(lualib_path("public.datactrl"))

function NewChapter(iChapterID)
    local o =CChapter:New(iChapterID)
    return o
end

CChapter = {}
CChapter.__index = CChapter
inherit(CChapter, datactrl.CDataCtrl)

function CChapter:New(iChapterID)
    local o = super(CChapter).New(self)
    o.m_iID = iChapterID
    o:Init()
    return o
end

function CChapter:Init()
    self.m_iRead = 0
    self.m_iUnlock = 0
    self.m_iCondition = 0
    self.m_mCondition = {}
end

function CChapter:Load(mData)
    mData = mData or {}
    self.m_iRead = mData["read"] or 0
     self.m_iUnlock = mData["unlock"] or 0
    local mCondition = mData["condition"] or {}
    for sConditionID, _ in pairs(mCondition) do
        local iConditionID = tonumber(sConditionID)
        self.m_mCondition[iConditionID] = 1
    end
    self:ReachCondition()
end

function CChapter:Save()
    local mData = {}
    local mCondition = {}
    for iConditionID, _ in pairs(self.m_mCondition) do
        mCondition[db_key(iConditionID)] = 1
    end
    mData["condition"] = mCondition
    mData["unlock"] = self.m_iUnlock
    mData["read"] = self.m_iRead
    return mData
end

function CChapter:PreCheck()
    self:ReachCondition()
    -- self:CheckUnlock()
end

function CChapter:ID()
    return self.m_iID
end

function CChapter:GetBaseData()
    local res = require "base.res"
    local mData = res["daobiao"]["handbook"]["chapter"][self:ID()]
    assert(mData, string.format("handbook chapter err:%s", self:ID()))
    return mData
end

function CChapter:Name()
    return self:GetBaseData()["name"]
end

function CChapter:CheckUnlock()
    if not self:NeedUnlock() then
        self:SetUnlock()
    end
end

function CChapter:GetUnlockKeys()
    return self:GetBaseData()["unlock_keys"] or 0
end

function CChapter:NeedUnlock()
    if self:GetUnlockKeys() > 0 then
        return true
    end
    return false
end

function CChapter:GetUnlock()
    return self.m_iUnlock
end

function CChapter:SetUnlock()
    if self:IsUnlock() then
        return
    end
    self:Dirty()
    self.m_iUnlock = 1
end

function CChapter:IsUnlock()
    return self.m_iUnlock ~= 0
end

function CChapter:SetRead()
    if self:IsRead() then
        return
    end
    self:Dirty()
    self.m_iRead = 1
end

function CChapter:GetRead()
    return self.m_iRead
end

function CChapter:IsRead()
    return self.m_iRead ~= 0
end

function CChapter:ConditionData()
    return self:GetBaseData()["condition"] or {}
end

function CChapter:ReachCondition()
    if self:IsConditionDone() then
        return
    end
    local lCondition = self:ConditionData()
    for _, iConditionID in ipairs(lCondition) do
        if not self.m_mCondition[iConditionID] then
            return
        end
    end
    self:Dirty()
    self.m_iCondition = 1
    self:CheckUnlock()
end

function CChapter:AddCondition(iConditionID)
    self:Dirty()
    self.m_mCondition[iConditionID] = 1
    self:ReachCondition()
end

function CChapter:ConditionList()
    return self.m_mCondition
end

function CChapter:IsConditionDone()
    return self.m_iCondition ~= 0
end

function CChapter:GetCondition()
    return self.m_iCondition
end

function CChapter:HasCondition(iConditionID)
    return self.m_mCondition[iConditionID]
end

function CChapter:ReadRewardKeys()
    return self:GetBaseData()["read_reward_keys"] or 0
end

function CChapter:ReadReward()
    return self:GetBaseData()["reward"] or {}
end

function CChapter:PackNetInfo()
    return {
        id = self:ID(),
        unlock = self:GetUnlock(),
        read = self:GetRead(),
        condition = table_key_list(self.m_mCondition),
    }
end
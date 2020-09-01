local global = require "global"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))

function NewBook(iBookID)
    local o = CBook:New(iBookID)
    return o
end

CBook = {}
CBook.__index = CBook
inherit(CBook, datactrl.CDataCtrl)

function CBook:New(iBookID)
    local o = super(CBook).New(self)
    o.m_iID = iBookID
    o:Init()
    return o
end

function CBook:Init()
    self.m_iShow = 0
    self.m_iName = 0
    self.m_iRepair = 0
    self.m_iUnlock = 0
    self.m_iCondition = 0
    self.m_iProgress = 0
    self.m_iRedPoint = 0
    self.m_mCondition = {}
    self.m_mChapter = {}
    -- self:CheckBookType()
end

function CBook:Load(mData)
    mData = mData or {}
    self.m_iShow = mData["show"] or 0
    self.m_iName = mData["name"] or 0
    self.m_iRepair = mData["repair"] or 0
    self.m_iUnlock = mData["unlock"] or 0
    self.m_iRedPoint = mData["red_point"] or 0

    local mCondition = mData["condition"] or {}
    for sConditionID, _ in pairs(mCondition) do
        local iConditionID = tonumber(sConditionID)
        self.m_mCondition[iConditionID] = 1
    end
    self:ReachCondition()
end

function CBook:Save()
    local mData = {}
    local mCondition = {}
    for iConditionID, _ in pairs(self.m_mCondition) do
        mCondition[db_key(iConditionID)] = 1
    end
    local mChapter = {}
    for iChapterID, _ in ipairs(self.m_mChapter) do
        mChapter[db_key(iChapterID)] = 1
    end
    mData["condition"] = mCondition
    mData["chapter"] = mChapter
    mData["show"] = self.m_iShow
    mData["name"] = self.m_iName
    mData["repair"] = self.m_iRepair
    mData["unlock"] = self.m_iUnlock
    mData["red_point"] = self.m_iRedPoint

    return mData
end

function CBook:PreCheck()
    self:ReachCondition()
    self:CheckBookType()
    self:CheckUnlock()
end

function CBook:ID()
    return self.m_iID
end

function CBook:GetBaseData()
    local res = require "base.res"
    local mData = res["daobiao"]["handbook"]["book"][self:ID()]
    assert(mData, string.format("handbook config book err:%s", self:ID()))
    return mData
end

function CBook:Type()
    return self:GetBaseData()["book_type"]
end

function CBook:Name()
    return self:GetBaseData()["name"]
end

function CBook:CheckBookType()
    local iType = self:Type()
    if iType == gamedefines.HANDBOOK_TYPE.PARTNER
      or iType == gamedefines.HANDBOOK_TYPE.PERSON then
        self:SetName()
        self:SetShow()
        self:SetRepair()
    end
end

function CBook:CheckUnlock()
    if not self:NeedUnlock() then
        self:SetUnlock()
    end
end

function CBook:GetUnlockKeys()
    return self:GetBaseData()["unlock_cost_key"]
end

function CBook:NeedUnlock()
    if self:GetUnlockKeys() > 0 then
        return true
    end
    if not self:IsConditionDone() then
        return true
    end
    return false
end

function CBook:GetEnterNameKeys()
    return self:GetBaseData()["name_cost"]
end

function CBook:GetRepairKeys()
    return self:GetBaseData()["draw_repair_cost"]
end

function CBook:GetUnlock()
    return self.m_iUnlock
end

function CBook:SetUnlock()
    if self:IsUnlock() then
        return
    end
    self:Dirty()
    self.m_iUnlock = 1
end

function CBook:IsUnlock()
    return self.m_iUnlock ~= 0
end

function CBook:GetShow()
    return self.m_iShow
end

function CBook:SetShow()
    if self:IsShow() then
        return
    end
     self:Dirty()
     self.m_iShow = 1
end

function CBook:IsShow()
    return self.m_iShow ~= 0
end

function CBook:GetRepair()
    return self.m_iRepair
end

function CBook:SetRepair()
    if self:IsRepair() then
        return
    end
    self:Dirty()
    self.m_iRepair = 1
end

function CBook:IsRepair()
    return self.m_iRepair ~= 0
end

function CBook:GetName()
    return self.m_iName
end

function CBook:SetName()
    if self:IsName() then
        return
    end
    self:Dirty()
    self.m_iName = 1
end

function CBook:IsName()
    return self.m_iName ~= 0
end

function CBook:GetCondition()
    return self.m_iCondition
end

function CBook:ConditionList()
    return self.m_mCondition
end

function CBook:IsConditionDone()
    return self.m_iCondition ~= 0
end

function CBook:GetCondition()
    return self.m_iCondition
end

function CBook:ConditionData()
    return self:GetBaseData()["condition_list"] or {}
end

function CBook:ReachCondition()
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
end

function CBook:AddCondition(iConditionID)
    self:Dirty()
    self.m_mCondition[iConditionID] = 1
    self:ReachCondition()
end

function CBook:ChapterData()
    return self:GetBaseData()["chapter_list"] or {}
end

function CBook:AddChapter(iChapterID)
    if self.m_mChapter[iChapterID] then
        return
    end
    self:Dirty()
    self.m_mChapter[iChapterID] = 1
end

function CBook:HasCondition(iConditionID)
    return self.m_mCondition[iConditionID]
end

function CBook:HasChapter(iChapterID)
    return self.m_mChapter[iChapterID]
end

function CBook:IsRedPoint(iRed)
    local iBit = 1 << (iRed - 1)
    return (self.m_iRedPoint & iBit) ~= 0
end

function CBook:SetRedPoint(iRed)
    if self:IsRedPoint(iRed) then
        return
    end
    self:Dirty()
    local iBit = 1 << (iRed - 1)
    self.m_iRedPoint = self.m_iRedPoint | iBit
end

function CBook:UnSetRedPoint(iRed)
    if not self:IsRedPoint(iRed) then
        return
    end
    self:Dirty()
    local iBit = 1 << (iRed - 1)
    self.m_iRedPoint = self.m_iRedPoint ~ iBit
end

function CBook:PackNetInfo()
    local mNet = {}
    mNet["id"] = self:ID()
    mNet["entry_name"] = self.m_iName
    mNet["show"] = self.m_iShow
    mNet["repair"] = self.m_iRepair
    mNet["unlock"] = self.m_iUnlock
    mNet["progress"] = self.m_iProgress
    mNet["red_point"] = self.m_iRedPoint
    mNet["condition"] = table_key_list(self.m_mCondition)
    return mNet
    -- mNet["chapter_list"] = table_key_list(self.m_mChapter)
end
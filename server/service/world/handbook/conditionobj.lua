local global = require "global"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))

local max = math.max
local min = math.min

function NewCondition(iCndID)
    local o = CCondition:New(iCndID)
    return o
end

CCondition = {}
CCondition.__index = CCondition
inherit(CCondition, datactrl.CDataCtrl)

function CCondition:New(iCndID)
    local o = super(CCondition).New(self)
    o.m_iID = iCndID
    o:Init()
    return o
end

function CCondition:Init()
    self.m_iProgress = 0
    self.m_iDone = 0
end

function CCondition:Load(mData)
    mData = mData or {}
    self.m_iProgress = mData["progress"] or 0
    self.m_iDone = mData["done"] or 0
end

function CCondition:Save()
    local mData = {}
    mData.progress = self.m_iProgress
    mData.done = self.m_iDone
    return mData
end

function CCondition:ID()
    return self.m_iID
end

function CCondition:GetBaseData()
    local res = require "base.res"
    local mData = res["daobiao"]["handbook"]["condition"][self:ID()]
    assert(mData, string.format("handbook condition err: %s", self:ID()))
    return mData
end

function CCondition:Name()
    return self:GetBaseData()["name"]
end

function CCondition:DegreeType()
    return self:GetBaseData()["degreetype"]
end

function CCondition:SubType()
    return self:GetBaseData()["sub_type"]
end

function CCondition:Desc()
    return self:GetBaseData()["desc"]
end

function CCondition:GetKey()
    local sConditon = self:GetBaseData()["condition"]
    local lValue = split_string(sConditon, "=")
    return lValue[1]
end

function CCondition:ReachProgress()
    local sConditon = self:GetBaseData()["condition"]
    local lValue = split_string(sConditon, "=")
    return tonumber(lValue[2]) or 10000000
end 

function CCondition:GetProgress()
    return self.m_iProgress
end

function CCondition:GetDone()
    return self.m_iDone
end

function CCondition:AddProgress(iAdd)
    if self.m_iDone ~= 0 then
        return
    end
    local iReach= self:ReachProgress()
    self.m_iProgress = self.m_iProgress + iAdd
    self.m_iProgress = min(self.m_iProgress, iReach)
    self:Dirty()
    self:ReachCondition()
end

function CCondition:SetProgress(iProgress)
    if self.m_iDone ~= 0 then
        return 
    end
    local iReach= self:ReachProgress()
    self.m_iProgress = iProgress
    self.m_iProgress = min(self.m_iProgress, iReach)
    self:Dirty()
    self:ReachCondition()
end

function CCondition:ClearProgress()
    if self.m_iDone ~= 0 then
        return
    end
    self.m_iProgress = 0
    self:Dirty()
end

function CCondition:ReachCondition()
    local iType = self:DegreeType()
    if table_in_list({1,2}, iType) and self.m_iProgress >= self:ReachProgress() then
        self:Dirty()
        self.m_iDone = 1
    end
end

function CCondition:IsDone()
    return self.m_iDone ~= 0
end

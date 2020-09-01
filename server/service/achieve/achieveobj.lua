local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local extend = require "base.extend"
local record = require "public.record"
local interactive = require "base.interactive"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))

local max = math.max
local min = math.min

function NewAchieve(iAchieveID)
    local o = CAchieve:New(iAchieveID)
    return o
end

CAchieve = {}
CAchieve.__index =CAchieve
inherit(CAchieve,datactrl.CDataCtrl)

function CAchieve:New(iAchieveID)
    local o = super(CAchieve).New(self)
    o.m_ID = iAchieveID
    o:Init()
    return o
end

function CAchieve:Init()
    self.m_Degree = 0
    self.m_Done = 0
end

function CAchieve:Save()
    local mData = {}
    mData["degree"] = self.m_Degree or 0
    mData["done"] = self.m_Done or 0
    return mData
end

function CAchieve:Load(mData)
    mData = mData or {}
    self.m_Degree = mData["degree"] or 0
    self.m_Done = mData["done"] or 0
end

function CAchieve:FixDegree()
    if self.m_Done == 1 and  self.m_Degree < self:ReachDegree() then
        self:Dirty()
        self.m_Done = 0
    end
    if self.m_Done == 0 and self.m_Degree >= self:ReachDegree() then
        self:Dirty()
        self.m_Done = 1
    end
end

function CAchieve:ID()
    return self.m_ID
end

function CAchieve:Name()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][self:ID()]["name"]
end

function CAchieve:Direction()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][self:ID()]["direction"]
end

function CAchieve:SubDirection()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][self:ID()]["sub_direction"]
end

function CAchieve:GetBelong()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][self:ID()]["belong"]
end

function CAchieve:Desc()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][self:ID()]["desc"]
end

function CAchieve:Point()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][self:ID()]["point"]
end

function CAchieve:GetKey()
    local res = require "base.res"
    local sCondition = res["daobiao"]["achieve"]["configure"][self:ID()]["condition"]
    local value = split_string(sCondition,"=")
    return value[1]
end

function CAchieve:ReachDegree()
    local res = require "base.res"
    local sCondition = res["daobiao"]["achieve"]["configure"][self:ID()]["condition"]
    local value = split_string(sCondition,"=")
    return tonumber(value[2]) or 1000000
end

function CAchieve:GetDeGree()
    return self.m_Degree
end

function CAchieve:AddDegree(iAdd)
    if self.m_Done ~= 0 then
        return
    end
    local iReachDegree = self:ReachDegree()
    self.m_Degree = self.m_Degree + iAdd
    self:Dirty()
    self:ReachAchieve()
end

function CAchieve:SetAchDegree(iDegree)
    if self.m_Done ~= 0 then
        return
    end
    local iReachDegree = self:ReachDegree()
    self.m_Degree = iDegree
    self:Dirty()
    self:ReachAchieve()
end

function CAchieve:ClearDegree()
    if self.m_Done ~= 0 then
        return
    end
    self.m_Degree = 0
    self:Dirty()
end

function CAchieve:GetAchieveDegreeType()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][self:ID()]["degreetype"]
end

function CAchieve:ReachAchieve()
    local iType = self:GetAchieveDegreeType()
    if table_in_list({1,2},iType) and self.m_Degree >= self:ReachDegree() then
        self:Dirty()
        self.m_Done = 1
    end
    if table_in_list({3},iType) and self.m_Degree == self:ReachDegree() then
        self:Dirty()
        self.m_Done = 1
    end
end

function CAchieve:SignReward()
    if self.m_Done == 1 then
        self:Dirty()
        self.m_Done = 2
        return true
    end
    return false
end

function CAchieve:IsDone()
    return self.m_Done ~= 0
end

function CAchieve:GetDone()
    return self.m_Done
end
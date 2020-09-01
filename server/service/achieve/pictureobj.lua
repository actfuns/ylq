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

function NewPicture(iPictureID)
    local o = CPicture:New(iPictureID)
    return o
end

CPicture = {}
CPicture.__index =CPicture
inherit(CPicture,datactrl.CDataCtrl)

function CPicture:New(iPictureID)
    local o = super(CPicture).New(self)
    o.m_ID = iPictureID
    o:Init()
    return o
end

function CPicture:Init()
    self.m_Degree = {}
    self.m_Done = 0
end

function CPicture:Save()
    local mData = {}
    mData["degree"] = self.m_Degree or {}
    mData["done"] = self.m_Done or 0
    return mData
end

function CPicture:Load(mData)
    mData = mData or {}
    self.m_Degree = mData["degree"] or {}
    self.m_Done = mData["done"] or 0
end

function CPicture:ID()
    return self.m_ID
end

function CPicture:ReachDegree(sKey,iTargetID)
    local res = require "base.res"
    local mCondition = res["daobiao"]["achieve"]["picture"][self:ID()]["condition"]
    for _,info in pairs(mCondition) do
        local mArgs = split_string(info,":")
        local sCondition,iTarget,iValue = table.unpack(mArgs)
        if sCondition == sKey and tonumber(iTarget) == iTargetID then
            return tonumber(iValue) or 10000
        end
    end
    record.warning(string.format("not degree config about picture_key:%s picture_id:%d",sKey,self.m_ID))
end

function CPicture:GetDeGree()
    return self.m_Degree
end

function CPicture:PackDegreeInfo()
    local mNet = {}
    for sKey,info in pairs(self.m_Degree) do
        for iTargetID,iValue in pairs(info) do
            table.insert(mNet,{key=sKey,targetid=iTargetID,value=iValue})
        end
    end
    return mNet
end

function CPicture:SetDegree(iPid,sKey,iTarget,iValue)
    if self.m_Done ~= 0 then
        return
    end
    local iReachDegree = self:ReachDegree(sKey,iTarget)
    self.m_Degree[sKey] = self.m_Degree[sKey] or {}
    self.m_Degree[sKey][iTarget] = (self.m_Degree[sKey][iTarget] or 0)
    local iOldDegree = self.m_Degree[sKey][iTarget]
    if self.m_Degree[sKey][iTarget] < iValue then
        self.m_Degree[sKey][iTarget] = iValue
    else
        return
    end
    local iNewDegree = self.m_Degree[sKey][iTarget]
    self.m_Degree[sKey][iTarget] = min(tonumber(self.m_Degree[sKey][iTarget]),iReachDegree)
    self:Dirty()
    self:ReachPitcure()
    record.user("picture","degree_change",{pid = iPid,id=self:ID(),old_degree=iOldDegree,new_degree=iNewDegree,target=iTarget,key=sKey})
end

function CPicture:ReachPitcure()
    local unDone = false
    local res = require "base.res"
    local mCondition = res["daobiao"]["achieve"]["picture"][self:ID()]["condition"]
    for _,info in pairs(mCondition) do
        local mArgs = split_string(info,":")
        local sCondition,iTarget,iValue = table.unpack(mArgs)
        iTarget = tonumber(iTarget)
        if not (self.m_Degree[sCondition] and self.m_Degree[sCondition][iTarget] and self.m_Degree[sCondition][iTarget] >= tonumber(iValue)) then
            return false
        end
    end
    self:Dirty()
    self.m_Done = 1
end

function CPicture:SignReward()
    if  self.m_Done == 1 then
        self:Dirty()
        self.m_Done = 2
        return true
    end
    return false
end

function CPicture:IsDone()
    return self.m_Done ~= 0
end

function CPicture:GetDone()
    return self.m_Done
end
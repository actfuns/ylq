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
local gsub = string.gsub

function NewAchieveTask(iTaskID)
    local o = CAchieveTask:New(iTaskID)
    return o
end

CAchieveTask = {}
CAchieveTask.__index =CAchieveTask
inherit(CAchieveTask,datactrl.CDataCtrl)

function CAchieveTask:New(iTaskID)
    local o = super(CAchieveTask).New(self)
    o.m_ID = iTaskID
    o.m_iOpen = 0
    o.m_iHasInit = 0
    o:InitCondition()
    return o
end

function CAchieveTask:SetOwner(iPid)
    self.m_iOwner = iPid
    self:Dirty()
end

function CAchieveTask:InitCondition()
    self:Dirty()
    self.m_iHasInit = 1
    local mData = self:GetBaseData()
    local mPreCondition = {}
    local mCondition = {}
    local mTrigger = mData["pre_condition"]
    for _,sTrigger in pairs(mTrigger) do
        local mValue = split_string(sTrigger,"=")
        mPreCondition[mValue[1]] = {degree = 0,target = tonumber(mValue[2])}
    end
    local sCondition = mData["condition"]
    local mValue = split_string(sCondition,"=")
    mCondition[mValue[1]] = {degree = 0,target=tonumber(mValue[2])}
    self.m_mPreCondition = mPreCondition
    self.m_mCondition = mCondition
end

function CAchieveTask:IsOpen()
    return self.m_iOpen == 1
end

function CAchieveTask:GetBaseData()
    local res = require "base.res"
    local mData = res["daobiao"]["achieve"]["achievetask"]
    assert(mData[self.m_ID],"Get achievetask data failed:"..self.m_ID)
    return mData[self.m_ID]
end

function CAchieveTask:Name()
    local mData = self:GetBaseData()
    return mData["name"]
end

function CAchieveTask:TranString(sString)
    if not sString then
        return ""
    end
    if string.find(sString,"$current") then
        local iCurDegree,iTarget
        for sKey,mInfo in pairs(self.m_mCondition) do
            iCurDegree = mInfo["degree"] or 0
            iTarget = mInfo["target"] or 0
            iCurDegree = math.min(iCurDegree,iTarget)
        end
        sString=gsub(sString,"$current",iCurDegree)
    end
    if string.find(sString,"$target") then
        local iValue
        for sKey,mInfo in pairs(self.m_mCondition) do
            iValue = mInfo["target"] or 0
        end
        sString=gsub(sString,"$target",iValue)
    end
    return sString
end

function CAchieveTask:Describe()
    local mData = self:GetBaseData()
    local sDescribe = mData["describe"]
    sDescribe = self:TranString(sDescribe)
    return sDescribe
end

function CAchieveTask:DegreeType()
    local mData = self:GetBaseData()
    return mData["degreetype"]
end

function CAchieveTask:TaskType()
    local mData = self:GetBaseData()
    return mData["tasktype"]
end

function CAchieveTask:AchieveType()
    local mData = self:GetBaseData()
    return mData["achievetype"]
end

function CAchieveTask:Save()
    local mData = {}
    mData["owner"] = self.m_iOwner or 0
    mData["hasinit"] = self.m_iHasInit or 0
    mData["open"] = self.m_iOpen or 0
    mData["precondition"] = self.m_mPreCondition or {}
    mData["condition"] = self.m_mCondition or {}
    return mData
end

function CAchieveTask:Load(mData)
    mData = mData or {}
    self.m_iOwner = mData["owner"] or 0
    self.m_iHasInit = mData["hasinit"] or 0
    self.m_iOpen = mData["open"] or 0
    self.m_mPreCondition = mData["precondition"] or {}
    self.m_mCondition = mData["condition"] or {}
    if self.m_iHasInit == 0 then
        self:InitCondition()
    end
end

function CAchieveTask:PushPreCondition(sKey,mData)
    if self.m_iOpen == 1 then
        return
    end
    if not self.m_mPreCondition[sKey] then
        return
    end
    if sKey == "完成成就任务" then
        local iAchieveId = mData.value
        local oAchieveMgr = global.oAchieveMgr
        local oPlayer = oAchieveMgr:GetPlayer(self.m_iOwner)
        
        local mAchieveInfo = oPlayer.m_oTaskCtrl:GetAchieveTaskInfo(iAchieveId)
        if mAchieveInfo["achievetype"] ~= self:AchieveType() then
            return
        end
        if self.m_mPreCondition[sKey]["degree"] == self.m_mPreCondition[sKey]["target"] then
            return
        end
    end
    self:Dirty()
    local iDegree = mData.value
    self.m_mPreCondition[sKey]["degree"] = iDegree
    if self.m_mPreCondition[sKey]["target"] == iDegree then
        self:CheckOpen()
    end
end

function CAchieveTask:CheckOpen()
    local bCanOpen = true
    for sKey,info in pairs(self.m_mPreCondition) do
        if sKey == "完成成就任务" and info.target ~= info.degree then
            bCanOpen = false
            break
        elseif info.target > info.degree then
            bCanOpen = false
            break
        end
    end
    if bCanOpen then
        self:TaskOpen()
    end
end

function CAchieveTask:TaskOpen()
    self:Dirty()
    self.m_iOpen = 1
    local oAchieveMgr = global.oAchieveMgr
    local oPlayer = oAchieveMgr:GetPlayer(self.m_iOwner)
    oPlayer.m_oTaskCtrl:TaskOpen(self.m_ID)
end

function CAchieveTask:Degree(sKey)
    if sKey then
        return self.m_mCondition[sKey] and (self.m_mCondition[sKey]["degree"] or 0) or 0
    end
    for _,info in pairs(self.m_mCondition) do
        return info["degree"] or 0
    end
    -- body
end

function CAchieveTask:Target(sKey)
    if sKey then
        return self.m_mCondition[sKey] and (self.m_mCondition[sKey]["degree"] or 0) or 0
    end
    for _,info in pairs(self.m_mCondition) do
        return info["target"] or 0
    end
end

function CAchieveTask:PackTaskInfo()
    local mNet = {}
    mNet["taskid"] = self.m_ID
    mNet["name"] = self:Name()
    mNet["describe"] = self:Describe()
    mNet["degree"] = self:Degree()
    mNet["target"] = self:Target()
    mNet["achievetype"] = self:AchieveType()
    return mNet
end

function CAchieveTask:PackLogInfo()
    local m = {degree = self.m_mCondition,predegree = self.m_mPreCondition}
    return ConvertTblToStr(m)
end

function CAchieveTask:PushCondition(sKey,mData)
    if not self.m_mCondition[sKey] then
        return
    end
    if self.m_iOpen == 0 and self:TaskType() == 2 then
        return
    end
    self:Dirty()
    local iDegree = mData.value
    local iDegreeType = self:DegreeType()
    local bRefresh = false
    if iDegreeType == 1 then
        local iOldDegree = self.m_mCondition[sKey]["degree"] or 0
        self.m_mCondition[sKey]["degree"] = iDegree
        bRefresh = (iOldDegree ~= iDegree)
    elseif iDegreeType == 2 then
        local iOldDegree = self.m_mCondition[sKey]["degree"] or 0
        bRefresh = iOldDegree < self.m_mCondition[sKey]["target"]
        if not bRefresh then
            return
        end
        self.m_mCondition[sKey]["degree"] = (self.m_mCondition[sKey]["degree"] or 0) + iDegree
    end
    self:RefreshTask()
end

function CAchieveTask:CheckCanReward()
    local bReach = true
    for sKey,mInfo in pairs(self.m_mCondition) do
        if mInfo["degree"] < mInfo["target"] then
            bReach = false
            break
        end
    end
    return bReach
end

function CAchieveTask:RefreshTask()
    local oAchieveMgr = global.oAchieveMgr
    local oPlayer = oAchieveMgr:GetPlayer(self.m_iOwner)
    oPlayer.m_oTaskCtrl:RefreshTask(self.m_ID)
end

function CAchieveTask:Dirty()
    local oAchieveMgr = global.oAchieveMgr
    local oPlayer = oAchieveMgr:GetPlayer(self.m_iOwner)
    if oPlayer then
        oPlayer.m_oTaskCtrl:Dirty()
    end
    super(CAchieveTask).Dirty(self)
end
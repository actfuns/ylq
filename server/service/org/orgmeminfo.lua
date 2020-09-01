--import module
local skynet = require "skynet"
local global = require "global"

local datactrl = import(lualib_path("public.datactrl"))

function NewMemberInfo(...)
    return CMemberInfo:New(...)
end

CMemberInfo = {}
CMemberInfo.__index = CMemberInfo
inherit(CMemberInfo, datactrl.CDataCtrl)

function CMemberInfo:New()
    local o = super(CMemberInfo).New(self)
    return o
end

function CMemberInfo:Create(pid, tArgs)
    self:SetData("pid", pid)
    self:SetData("name", tArgs["name"])
    self:SetData("grade", tArgs["grade"])
    self:SetData("school", tArgs["school"])
    self:SetData("school_branch", tArgs["school_branch"])
    self:SetData("org_offer", tArgs["org_offer"])
    self:SetData("shape",tArgs["shape"])
    self:SetData("power",tArgs["power"])
    self:SetData("apply_type", 0)
    self:SetData("logout_time", tArgs["logout_time"] or get_time())
    self:SetData("create_time", get_time())
    self:SetData("offer", tArgs["offer"] or 0)
end

function CMemberInfo:Load(mData)
    if not mData then
        return
    end
    self:SetData("pid", mData.pid)
    self:SetData("name", mData.name)
    self:SetData("grade", mData.grade)
    self:SetData("school", mData.school)
    self:SetData("school_branch", mData.school_branch)
    self:SetData("org_offer", mData.org_offer)
    self:SetData("offer", mData.offer or 0)
    self:SetData("apply_type", mData.apply_type)
    self:SetData("logout_time", mData.logout_time or get_time())
    self:SetData("create_time", mData.create_time or get_time())
    self:SetData("shape",mData.shape)
    self:SetData("power",mData.power)
end

function CMemberInfo:Save()
    local mData = {}
    mData.pid = self:GetData("pid")
    mData.name = self:GetData("name")
    mData.grade = self:GetData("grade")
    mData.school = self:GetData("school")
    mData.school_branch = self:GetData("school_branch")
    mData.org_offer = self:GetData("org_offer")
    mData.offer = self:GetData("offer")
    mData.apply_type = self:GetData("apply_type")
    mData.logout_time = self:GetData("logout_time")
    mData.create_time = self:GetData("create_time")
    mData.shape = self:GetData("shape")
    mData.power = self:GetData("power")
    return mData
end



function CMemberInfo:SetApplyType(iType)
    self:SetData("apply_type", iType)
end

function CMemberInfo:GetPower()
    return self:GetData("power")
end

function CMemberInfo:GetShape()
    return self:GetData("shape")
end

function CMemberInfo:GetName()
    return self:GetData("name")
end

function CMemberInfo:GetSchool()
    return self:GetData("school")
end

function CMemberInfo:GetSchoolBranch()
    return self:GetData("school_branch")
end

function CMemberInfo:GetGrade()
    return self:GetData("grade")
end

function CMemberInfo:GetPid()
    return self:GetData("pid")
end

function CMemberInfo:GetCreateTime()
    return self:GetData("create_time")
end


function CMemberInfo:PackOrgApplyInfo()
    local mNet = {}
    mNet.pid = self:GetPid()
    mNet.name = self:GetName()
    mNet.grade = self:GetGrade()
    mNet.school = self:GetSchool()
    mNet.power = self:GetPower()
    mNet.apply_time = self:GetCreateTime()
    return mNet
end

function CMemberInfo:SyncData(mData)
    for k,v in pairs(mData) do
        if self:GetData(k) then
            self:SetData(k, v)
        end
    end
end

function CMemberInfo:VaildApplyTime()
    local iTime = 3600
    local iLeftTime = self:GetCreateTime() + iTime - get_time()
    if iLeftTime <= 0 then
        return false
    end
    return true
end

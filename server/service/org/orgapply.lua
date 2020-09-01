--import module
local skynet = require "skynet"
local global = require "global"

local datactrl = import(lualib_path("public.datactrl"))
local orgmeminfo = import(service_path("orgmeminfo"))

function NewApplyMgr(...)
    return COrgApplyMgr:New(...)
end

COrgApplyMgr = {}
COrgApplyMgr.__index = COrgApplyMgr
inherit(COrgApplyMgr, datactrl.CDataCtrl)

function COrgApplyMgr:New(orgid)
    local o = super(COrgApplyMgr).New(self, {orgid = orgid})
    o.m_mApplyInfo = {}
    return o
end

function COrgApplyMgr:Release()
    for _, oMem in pairs(self.m_mApplyInfo) do
        baseobj_safe_release(oMem)
    end
    super(COrgApplyMgr).Release(self)
end

function COrgApplyMgr:GetOrg()
    local orgid = self:GetInfo("orgid")
    local oOrgMgr = global.oOrgMgr
    return oOrgMgr:GetNormalOrg(orgid)
end

function COrgApplyMgr:Load(mData)
    mData = mData or {}
    if mData.apply then
        local mApplyInfo = {}
        for pid, data in pairs(mData.apply) do
            pid = tonumber(pid)
            local oMem = orgmeminfo.NewMemberInfo()
            oMem:Load(data)
            mApplyInfo[pid] = oMem
        end
        self.m_mApplyInfo = mApplyInfo
    end
end

function COrgApplyMgr:Save()
    local mData = {}
    local mApplyInfo = {}
    for pid, meminfo in pairs(self.m_mApplyInfo) do
        pid = db_key(pid)
        mApplyInfo[pid] = meminfo:Save()
    end
    mData.apply = mApplyInfo
    return mData
end

function COrgApplyMgr:AddApply(oPlayer, iType)
    self:Dirty()
    local pid = oPlayer:GetPid()
    local tArgs = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        offer = oPlayer:GetOffer(),
        shape = oPlayer:GetShape(),
        power = oPlayer:GetPower(),
        school_branch = oPlayer:GetSchoolBranch(),
    }

    local oMember = orgmeminfo.NewMemberInfo()
    oMember:Create(pid, tArgs)
    oMember:SetApplyType(iType)
    self.m_mApplyInfo[pid] = oMember
end

function COrgApplyMgr:RemoveApply(pid)
    self:Dirty()
    local oApply = self.m_mApplyInfo[pid]
    if oApply then
        baseobj_delay_release(oApply)
    end
    self.m_mApplyInfo[pid] = nil
end

function COrgApplyMgr:RemoveAllApply()
    local rmlist = {}
    for pid,_ in pairs(self.m_mApplyInfo) do
        table.insert(rmlist,pid)
    end
    for _,pid in pairs(rmlist) do
        self:RemoveApply(pid)
    end
end

function COrgApplyMgr:CheckApplyOverDue()
    local rmlist = {}
    for pid,oMem in pairs(self.m_mApplyInfo) do
        if not oMem:VaildApplyTime() then
            table.insert(rmlist,pid)
        end
    end
    for _,pid in pairs(rmlist) do
        self:RemoveApply(pid)
    end
    if #rmlist > 0 then
        local oOrg = self:GetOrg()
        if oOrg then
            oOrg:UpdateOrgInfo({apply_count=true})
        end
    end
end

function COrgApplyMgr:GetApplyInfo(pid)
    return self.m_mApplyInfo[pid]
end

function COrgApplyMgr:GetApplyCnt()
    return table_count(self.m_mApplyInfo)
end

function COrgApplyMgr:GetApplyListInfo()
    return self.m_mApplyInfo
end

function COrgApplyMgr:PackApplyInfo()
    local mNet = {}
    for pid,oMem in pairs(self.m_mApplyInfo) do
        table.insert(mNet, oMem:PackOrgApplyInfo())
    end
    return mNet
end

function COrgApplyMgr:SyncApplyData(iPid, mData)
    local oMem = self:GetApplyInfo(iPid)
    if oMem then
        oMem:SyncData(mData)
        self:Dirty()
    end
end

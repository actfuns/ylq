--import module
local skynet = require "skynet"
local global = require "global"
local res = require "base.res"

local datactrl = import(lualib_path("public.datactrl"))

function NewLogMgr(...)
    return COrgLogMgr:New(...)
end

COrgLogMgr = {}
COrgLogMgr.__index = COrgLogMgr
inherit(COrgLogMgr, datactrl.CDataCtrl)

function COrgLogMgr:New(orgid)
    local o = super(COrgLogMgr).New(self, {orgid = orgid})
    o.m_mHistory = {}
    o.m_iHistoryID = 0
    return o
end

function COrgLogMgr:GetOrg()
    local orgid = self:GetInfo("orgid")
    local oOrgMgr = global.oOrgMgr
    return oOrgMgr:GetNormalOrg(orgid)
end

function COrgLogMgr:Load(mData)
    mData = mData or {}
    self.m_iHistoryID = mData.historyid or 0
    if mData.history then
        local mHistory = {}
        for k, v in pairs(mData.history) do
            k = tonumber(k)
            mHistory[k] = v
        end
        self.m_mHistory = mHistory
    end
end

function COrgLogMgr:Save()
    local mData = {}
    mData.historyid = self.m_iHistoryID
    local mHistory = {}
    for k, v in pairs(self.m_mHistory) do
        k = db_key(k)
        mHistory[k] = v
    end
    mData.history = mHistory
    return mData
end

function COrgLogMgr:DispatchID()
    self:Dirty()
    self.m_iHistoryID = self.m_iHistoryID + 1
    return self.m_iHistoryID
end

function COrgLogMgr:AddHistory(iPid,iPosition,msg)
    self:Dirty()
    local id = self:DispatchID()
    local iTime = get_time()
    self.m_mHistory[id] = {iPid, iPosition, iTime, msg}
    self:CheckHistory()
end

function COrgLogMgr:RemoveHistory(id)
    self:Dirty()
    self.m_mHistory[id] = nil
end

function COrgLogMgr:CheckHistory()
    local mHistory = self.m_mHistory or {}
    local mDel,iLen = {},0
    local iFirstID
    local iNowTime = get_time()
    for id,tHis in pairs(mHistory) do
        local iTime = tHis[3]
        if iNowTime - iTime >= 7 * 24 * 3600 then
            table.insert(mDel,id)
        else
            if not iFirstID or iTime < mHistory[iFirstID][3] then
                iFirstID = id
            end
            iLen = iLen + 1
        end
    end
    if iLen > 200 then
        table.insert(mDel,iFirstID)
    end
    for _,id in ipairs(mDel) do
        self:RemoveHistory(id)
    end
end

function COrgLogMgr:PackHistoryListInfo()
    if table_count(self.m_mHistory) <= 0 then
        return {}
    end
    local mHistory = {}
    for _,mData in pairs(self.m_mHistory) do
        table.insert(mHistory,mData)
    end
    table.sort(mHistory, function (h1, h2)
        if h1[3] ~= h2[3] then
            return h1[3] > h2[3]
        else
            return h1[1] < h2[1]
        end
    end)
    local mNet = {}
    for _,tHistory in pairs(mHistory) do
        table.insert(mNet, {time=tHistory[3], text=tHistory[4],position = tHistory[2]})
    end
    return mNet
end



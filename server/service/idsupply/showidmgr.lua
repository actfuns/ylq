local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"
local router = require "base.router"
local cjson = require "cjson"

local gamedb = import(lualib_path("public.gamedb"))
local serverinfo = import(lualib_path("public.serverinfo"))
local datactrl = import(lualib_path("public.datactrl"))

local STATUS_FREE = 0
local STATUS_PREDISPATCH = 1
local STATUS_USED = 2

function NewShowIdMgr(...)
    local o = CShowIdMgr:New(...)
    return o
end


CShowIdMgr = {}
CShowIdMgr.__index = CShowIdMgr
inherit(CShowIdMgr, datactrl.CDataCtrl)

function CShowIdMgr:New(...)
    local o = super(CShowIdMgr).New(self)
    o.m_bLoading = true
    o.m_mAllShowId = {}
    o.m_mPid2ShowId = {}
    o.m_mOccupyShowId = {}
    return o
end

function CShowIdMgr:Load(m)
    assert(m, "show id haven't init")
    for _, mInfo in ipairs(m) do
        local iShowId = mInfo.show_id
        local mData = mInfo.data
        self.m_mAllShowId[iShowId] = mData
        self:BuildIndex(iShowId)
    end
end

function CShowIdMgr:BuildIndex(iShowId)
    local mData = self.m_mAllShowId[iShowId]
    if not mData then return end
    if mData.pid then
        self.m_mPid2ShowId[mData.pid] = iShowId
    end
    if mData.occupy and mData.occupy > 0 then
        if not self.m_mOccupyShowId[mData.occupy] then
            self.m_mOccupyShowId[mData.occupy] = {}
        end
        table.insert(self.m_mOccupyShowId[mData.occupy], iShowId)
    end
end

function CShowIdMgr:GetShowIdByPid(iPid, iSet)
    local iShowId = self.m_mPid2ShowId[iPid]
    if not iShowId then return end

    self:_CheckTimeOut({[iPid] = iShowId})
    local mData = self.m_mAllShowId[iShowId]
    if mData then
        if iSet then
            mData.active_time = get_time()
            self:SaveShowIdByIdx(iShowId)
        end
    else
        iShowId = nil
    end
    return iShowId
end

function CShowIdMgr:GetPidByShowId(iShowId)
    local mData = self.m_mAllShowId[iShowId]
    if not mData or mData.status == 0 then return end

    local iPid = mData.pid
    self:_CheckTimeOut({[iPid] = iShowId})
    if self.m_mAllShowId[iShowId] then
        return iPid
    end
end

function CShowIdMgr:SetShowIdByPid(iPid, iShowId)
    local mData = self.m_mAllShowId[iShowId]
    if not mData then return end
    if mData.pid then return end

    mData.pid = iPid
    mData.status = STATUS_USED
    mData.active_time = get_time()
    self:SaveShowIdByIdx(iShowId)
    self.m_mPid2ShowId[iPid] = iShowId
end

function CShowIdMgr:RemoveShowIdByPid(iPid, iShowId)
    local mData = self.m_mAllShowId[iShowId]
    if not mData then return end

    if mData.pid ~= iPid then return end

    self.m_mPid2ShowId[iPid] = nil
    mData.pid = nil
    mData.status = STATUS_FREE
    mData.active_time = nil
    self:SaveShowIdByIdx(iShowId)
    self.m_mPid2ShowId[iPid] = nil
end

function CShowIdMgr:IsShowId(id)
    return self.m_mAllShowId[id] and true or false
end

function CShowIdMgr:IsCoupleId(id)
    if id < 10000 then return false end
    if id > 9999999 then return false end
    local sId = tostring(id)
    return string.find(sId, "^1314") or string.find(sId, "^520")
end

function CShowIdMgr:IsExcellentId(id)
    local mExcellent = res["daobiao"]["showid"]["excellent"]
    return id >= 1100 and id < 10000 or mExcellent[id]
end

function CShowIdMgr:IsLoading()
    return self.m_bLoading
end

function CShowIdMgr:LoadFinish()
    self.m_bLoading = false
end

function CShowIdMgr:LoadDb()
    local mInfo = {
        module = "showid",
        cmd = "LoadAllShowId",
    }
    gamedb.LoadDb("showid","common", "LoadDb", mInfo,
    function(mRecord, mData)
        if not is_release(self) and self:IsLoading() then
            self:Load(mData.data)
        end
        self:LoadFinish()
        self:Schedule()
    end)
end

function CShowIdMgr:SaveShowIdByIdx(iShowId)
    local mInfo = {
        module = "showid",
        cmd = "SaveShowIdByIdx",
        cond = {show_id = iShowId},
        data = {data = self.m_mAllShowId[iShowId]},
    }
    gamedb.SaveDb("showid","common", "SaveDb", mInfo)
end

function CShowIdMgr:Schedule()
    local f
    f = function()
        self:DelTimeCb("_CheckTimeOut")
        self:AddTimeCb("_CheckTimeOut", 60*1000, f)
        self:_CheckTimeOut()
    end
    f()
end

function CShowIdMgr:_CheckTimeOut(mInfo)
    local iTimeOut = 180*24*3600
    local iCurr = get_time()
    mInfo = mInfo or self.m_mPid2ShowId
    for iPid, iShowId in pairs(mInfo) do
        local mData = self.m_mAllShowId[iShowId]
        if mData and mData.active_time + iTimeOut < iCurr then
            self:GS2GSRemoveShowId(iShowId, iPid)
            self.m_mPid2ShowId[iPid] = nil
            mData.pid = nil
            mData.active_time = nil
            mData.status = STATUS_FREE
            self:SaveShowIdByIdx(iShowId)
        end
    end
end

function CShowIdMgr:GS2GSRemoveShowId(iShowId, iPid)
    interactive.Request(".datacenter", "common", "QueryRoleNowServer", {pid=iPid},
    function(mRecord, mData)
        if not mData then
            record.error("GS2GSRemoveShowId error QueryRoleNowServer no return: pid %d showid %d", iPid, iShowId)
            return
        end
        if mData.errcode ~= 0 then
            record.error("GS2GSRemoveShowId error QueryRoleNowServer error %d: pid %d showid %d", mData.errcode, iPid, iShowId)
            return
        end
        self:_GS2GSRemoveShowId1(mData.server, iShowId, iPid)
    end)
end

function CShowIdMgr:_GS2GSRemoveShowId1(sServerKeyTag, iShowId, iPid)
    record.info("try remove showid %d", iShowId)
    router.Request(sServerKeyTag, ".world", "idsupply", "RemoveShowId", {
        pid = iPid,
        show_id=iShowId
    }, function (mRecord, mData)
        local iErrCode = mData.errcode
        if iErrCode ~= 0 then
            record.error("GS2GSRemoveShowId error RemoveShowId error %d: pid %d showid %d", iErrCode, iPid, iShowId)
        end
    end)
end

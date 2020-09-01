--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"
local cjson = require "cjson"
local router = require "base.router"
local mongoop = require "base.mongoop"

local datactrl = import(lualib_path("public.datactrl"))


function NewNoticeMgr(...)
    local o = CNoticeMgr:New(...)
    return o
end

local sLoopNoticeTable = "loopnotice"

CNoticeMgr = {}
CNoticeMgr.__index = CNoticeMgr

function CNoticeMgr:New()
    local o = setmetatable({}, self)
    return o
end

function CNoticeMgr:Init()
    self.m_mLoopNotice = {}
    -- self.m_iNoticeId = 0
    local lRet = self:GetLoopNoticeList({publishedStr="已发布"})
    for _,mData in pairs(lRet) do
        self:AddLoopNotice(mData)
    end
end

function CNoticeMgr:DispatchLoopNoticeId()
    local oBackendObj = global.oBackendObj
    return oBackendObj:GenID("loopnotice")
end

function CNoticeMgr:GetLoopNoticeList(mSearch)
    local oBackendDb = global.oBackendObj.m_oBackendDb
    local ret = oBackendDb:Find(sLoopNoticeTable, mSearch or {})
    local lRet = {}
    while ret:hasNext() do
        local mRet = ret:next()
        mongoop.ChangeAfterLoad(mRet)
        table.insert(lRet, mRet)
    end
    return lRet
end

function CNoticeMgr:SaveOrUpdateLoopNotice(mData)
    local id = mData["id"]
    local oBackendDb = global.oBackendObj.m_oBackendDb
    if not id or id <= 0 then
        mData["id"] = self:DispatchLoopNoticeId()
        mongoop.ChangeBeforeSave(mData)
        oBackendDb:InsertLowPriority(sLoopNoticeTable, mData)
    else
        mongoop.ChangeBeforeSave(mData)
        oBackendDb:Update(sLoopNoticeTable, {id = id}, {["$set"]=mData})
        self:RemoveLoopNotice(id)
    end
end

function CNoticeMgr:DeleteLoopNotice(mCon, lId)
    local oBackendDb = global.oBackendObj.m_oBackendDb
    oBackendDb:Delete(sLoopNoticeTable, mCon)
    for _,id in pairs(lId or {}) do
        self:RemoveLoopNotice(id)
    end
end

function CNoticeMgr:PublishLoopNotice(mCon)
    local oBackendDb = global.oBackendObj.m_oBackendDb
    oBackendDb:Update(sLoopNoticeTable, mCon, {["$set"]={publishedStr="已发布"}}, false, true)
    local lRet = self:GetLoopNoticeList(mCon)
    for _, m in pairs(lRet) do
        self:AddLoopNotice(m)
    end
end

function CNoticeMgr:AddLoopNotice(mData)
    local oNotice = NewLoopNoticeObj()
    oNotice:Create(mData)
    if oNotice:CheckValid() then
        self.m_mLoopNotice[oNotice:NoticeId()] = oNotice
        oNotice:Schedule()
    else
        baseobj_delay_release(oNotice)
    end
end

function CNoticeMgr:GetLoopNotice(id)
    return self.m_mLoopNotice[id]
end

function CNoticeMgr:RemoveLoopNotice(id)
    local oNotice = self.m_mLoopNotice[id]
    if oNotice then
        self.m_mLoopNotice[id] = nil
        baseobj_delay_release(oNotice)
    end
end


-- 循环公告
function NewLoopNoticeObj(...)
    local o = CLoopNotice:New(...)
    return o
end

CLoopNotice = {}
CLoopNotice.__index = CLoopNotice
inherit(CLoopNotice, datactrl.CDataCtrl)

function CLoopNotice:New()
    local o = super(CLoopNotice).New(self)
    o:Init()
    return o
end

function CLoopNotice:Init()
    self.m_id = 0
    self.m_iStartTime = 0
    self.m_iEndTime = 0
    self.m_iSleepTime = 0
    self.m_sTitle = ""
    self.m_sContent = ""
    self.m_lServer = {}
    self.m_bAllServer = false
end

function CLoopNotice:Create(mData)
    self.m_id = mData["id"]
    self.m_iStartTime = mData["startTime"]
    self.m_iEndTime = mData["endTime"]
    self.m_iSleepTime = mData["intervals"]
    self.m_sTitle = mData["title"]
    self.m_sContent = mData["content"]

    local sServerStr = mData["servers"]
    if "0" == sServerStr then
        self.m_bAllServer = true
    else
        self.m_lServer = split_string(sServerStr, ",")
    end
end

function CLoopNotice:NoticeId()
    return self.m_id
end

function CLoopNotice:CheckValid()
    return self:NoticeId() > 0 and self.m_iEndTime > get_time()
end

function CLoopNotice:Schedule()
    local f1
    local iNotice = self:NoticeId()
    f1 = function ()
        local oNoticeMgr = global.oNoticeMgr
        local oNotice = oNoticeMgr:GetLoopNotice(iNotice)
        if oNotice then
            oNotice:DelTimeCb("_DoLoopNotice")
            oNotice:AddTimeCb("_DoLoopNotice", oNotice.m_iSleepTime*1000, f1)
            oNotice:_DoLoopNotice()
        end
    end
    local iNoticeTime = self.m_iStartTime - get_time()
    if iNoticeTime > 0 then
        self:AddTimeCb("_DoLoopNotice", iNoticeTime*1000, f1)
    else
        f1()
    end
end

function CLoopNotice:GetServerList()
    local oBackendObj = global.oBackendObj
    if self.m_bAllServer then
        return oBackendObj:GetServerList()
    end
    local lServer = {}
    for _,serverId in pairs(self.m_lServer) do
        local oServer = oBackendObj:GetServer(serverId)
        if oServer then
            table.insert(lServer, oServer)
        end
    end
    return lServer
end

function CLoopNotice:_DoLoopNotice()
    if not self:CheckValid() then
        self:DelTimeCb("_DoLoopNotice")
        local oNoticeMgr = global.oNoticeMgr
        oNoticeMgr:RemoveLoopNotice(self:NoticeId())
        return
    end

    local mData = {}
    mData["cmd"] = "SendSysChat"
    mData["data"] = {content=self.m_sContent, type=1}
    for _, oServer in pairs(self:GetServerList()) do
        local sServerKey = oServer:ServerID()
        router.Request(get_server_tag(sServerKey), ".world", "backend", "gmbackend", mData, function(mRecord, mRes)
            if mRes.errcode then
                record.error("server:%s, errCode:%s, errMsg:%s", sServerKey, mRes.errcode, mRes.errmsg)
            end
        end)
    end
end

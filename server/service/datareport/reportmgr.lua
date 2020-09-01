--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"
local httpuse = require "public.httpuse"

local kaopureport = import(lualib_path("public.kaopureport"))
local urldefines = import(lualib_path("public.urldefines"))

local tinsert = table.insert

function NewReportMgr(...)
    local o = CReportMgr:New(...)
    return o
end

CReportMgr = {}
CReportMgr.__index = CReportMgr
inherit(CReportMgr, kaopureport.CKpReportMgr)

function CReportMgr:New()
    local o = super(CReportMgr).New(self)
    o.m_mIOSCaChe = {}
    o.m_mADCaChe = {}
    return o
end

function CReportMgr:Init()
    local f1
    f1 = function ()
        self:DelTimeCb("DoPromote")
        self:AddTimeCb("DoPromote", 30 * 60 * 1000, f1)
        self:DoPromote()
    end
    f1()
    -- local f2
    -- f2 = function ()
    --     self:DelTimeCb("CheckDoPromote")
    --     self:AddTimeCb("CheckDoPromote", 10 * 1000, f2)
    --     self:CheckDoPromote()
    -- end
    -- f2()
end

function CReportMgr:PushIOSData(sKey,mData)
    local mCaChe = self.m_mIOSCaChe
    mCaChe[sKey] = mCaChe[sKey] or {}
    tinsert(mCaChe[sKey],mData)
end

function CReportMgr:PushADData(sKey,mData)
    local mCaChe = self.m_mADCaChe
    mCaChe[sKey] = mCaChe[sKey] or {}
    tinsert(mCaChe[sKey],mData)
end

function CReportMgr:PushIOSLData(sKey,mlData)
    local mCaChe = self.m_mIOSCaChe
    mCaChe[sKey] = mCaChe[sKey] or {}
    for _,mData in pairs(mlData) do
        tinsert(mCaChe[sKey],mData)
    end
end

function CReportMgr:PushADLData(sKey,mlData)
    local mCaChe = self.m_mADCaChe
    mCaChe[sKey] = mCaChe[sKey] or {}
    for _,mData in pairs(mlData) do
        tinsert(mCaChe[sKey],mData)
    end
end

function CReportMgr:CheckDoPromote()
    local mCaChe = self.m_mIOSCaChe or {}
    local mCaChe2 = self.m_mADCaChe or {}
    local iCnt = 0
    for _,mList in pairs(mCaChe) do
        iCnt = iCnt + #mList
    end
    for _,mList in pairs(mCaChe2) do
        iCnt = iCnt + #mList
    end
    if iCnt >= 100 then
        self:DoPromote()
    end
end

function CReportMgr:DoPromote()
    local sHost = urldefines.get_out_host()
    local mCaChe = self.m_mIOSCaChe
    self.m_mIOSCaChe = {}
    local mHeader = {["Content-type"]="application/x-www-form-urlencoded"}
    for sKey,mData in pairs(mCaChe) do
        local sUrl = urldefines.get_kaopu_url("ios",sKey)
        local sParam = self:MakeParam(mData,"ios")
        if sUrl then
            httpuse.post(sHost, sUrl, sParam, function(body, header)
                if body and body.code == 0 then
                    record.warning("datareport error msg: "..body.msg)
                end
            end, mHeader)
        else
            record.warning("datareport key error "..sKey.."  param "..sParam)
        end
    end
    local mCaChe = self.m_mADCaChe
    self.m_mADCaChe = {}
    for sKey,mData in pairs(mCaChe) do
        local sUrl = urldefines.get_kaopu_url("android",sKey)
        local sParam = self:MakeParam(mData,"android")

        if sUrl then
            httpuse.post(sHost, sUrl, sParam, function(body, header)
                if body and body.code == 0 then
                    record.warning("datareport error msg: "..body.msg)
                end
            end, mHeader)
        else
            record.warning("datareport key error "..sKey.."  param "..sParam)
        end
    end
end
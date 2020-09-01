-- import file
local httpuse = require "public.httpuse"
local interactive = require "base.interactive"
local serverdefines = require "public.serverdefines"
local router = require "base.router"

local cjson = require "cjson"

local gamedefines = import(lualib_path("public.gamedefines"))
local urldefines = import(lualib_path("public.urldefines"))
local serverinfo = import(lualib_path("public.serverinfo"))

function NewKpReportMgr(...)
    return CKpReportMgr:New(...)
end

CKpReportMgr = {}
CKpReportMgr.__index = CKpReportMgr
inherit(CKpReportMgr, logic_base_cls())

function CKpReportMgr:New()
    local o = super(CKpReportMgr).New(self)
    return o
end

function CKpReportMgr:GetIOSAppId()
    return serverinfo.KAOPU_REPORT.ios_app_id
end

function CKpReportMgr:GetAndroidAppId()
    return serverinfo.KAOPU_REPORT.android_app_id
end

function CKpReportMgr:MakeParam(mData,sPlatform)
    local sData = cjson.encode(mData)
    local mParam = {
        data = sData,
        timestamp = get_time(),
    }
    if sPlatform == "ios" then
        mParam.appid = self:GetIOSAppId()
    elseif sPlatform == "android" then
        mParam.appid = self:GetAndroidAppId()
    end
    return httpuse.mkcontent_kv(mParam)
end

function PushData(iPlatform,sKey,mData)
    local sPlatform = gamedefines.PLATFORM_DESC[iPlatform]
    local sService = ".datareport"..math.random(DATAREPORT_SERVICE_COUNT)
    if table_in_list({"ROOTIOS","IOS"},sPlatform) then
        router.Send("bs", sService, "common", "PushIOSData", {key = sKey, data = mData})
    elseif table_in_list({"ANDROID","PC"},sPlatform) then
        router.Send("bs", sService, "common", "PushADData", {key = sKey, data = mData})
    end
end

function PushLData(iPlatform,sKey,mData)
    local sPlatform = gamedefines.PLATFORM_DESC[iPlatform]
    local sService = ".datareport"..math.random(DATAREPORT_SERVICE_COUNT)
    if table_in_list({"ROOTIOS","IOS"},sPlatform) then
        router.Send("bs", sService, "common", "PushIOSLData", {key = sKey, ldata = mData})
    elseif table_in_list({"ANDROID","PC"},sPlatform) then
        router.Send("bs", sService, "common", "PushADLData", {key = sKey, ldata = mData})
    end
end
local global = require "global"
local skynet = require "skynet"
local bson = require "bson"
local cjson = require "cjson"
local interactive = require "base.interactive"

local analy = import(lualib_path("public.dataanaly"))
local defines = import(service_path("defines"))

function NewLogFileObj(...)
    local o = CLogFileObj:New(...)
    return o
end

CLogFileObj = {}
CLogFileObj.__index = CLogFileObj
inherit(CLogFileObj, logic_base_cls())

function CLogFileObj:New()
    local o = super(CLogFileObj).New(self)
    return o
end

function CLogFileObj:Init()
    local f1
    f1 = function ()
        local iTime = get_time()
        local tbl = get_hourtime({factor=1,hour=1})
        local iSecs = tbl.time - iTime
        local mDate = os.date("*t",iTime)
        if iSecs <= 0 then
            iSecs = 3600
        end
        self:DelTimeCb("NewHour")
        self:AddTimeCb("NewHour", iSecs * 1000, f1)
        self:NewHour(mDate.day,mDate.hour)
    end
    local tbl = get_hourtime({factor=1,hour=1})
    local iSecs = tbl.time - get_time()
    if iSecs <= 0 then
        f1()
    else
        self:DelTimeCb("NewHour")
        self:AddTimeCb("NewHour", iSecs * 1000, f1)
    end
end

function CLogFileObj:NewHour(iDay,iHour)
    if iHour == 0 then
        local mRet = defines.GetNeedRefresh()
        for _,sName in pairs(mRet) do
            analy.write_data(sName,"")
        end
    end
end

function CLogFileObj:WriteData(sName, mData)
    mData.time = get_time_format_str(get_time(),"%Y-%m-%d %H:%M:%S")
    mData = cjson.encode(mData)
    analy.write_data(sName,mData)
end

function CLogFileObj:FixWriteData(sName, mData)
    mData = cjson.encode(mData)
    analy.write_data(sName,mData)
end
local global = require "global"
local c = require "skynet.core"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"

local shareobj = import(lualib_path("base.shareobj"))
local datactrl = import(lualib_path("public.datactrl"))
local fixbug = import(service_path("fixbug"))

function NewDictatorObj(...)
    local o = CDictatorObj:New(...)
    return o
end

CDictatorObj = {}
CDictatorObj.__index = CDictatorObj
inherit(CDictatorObj, datactrl.CDataCtrl)

function CDictatorObj:New()
    local o = super(CDictatorObj).New(self)

    if is_gs_server() then
        o.m_mBootedFinish = {
            launcher = false,
            world = false,
        }
    else
        o.m_mBootedFinish = {
            launcher = false,
        }
    end

    o.m_iCheckHeartBeat = nil
    o.m_mCheckEndless = {}
    o.m_oMeasureFile = nil
    o.m_oMemFile = nil
    o.m_oMemCheckGlobalFile = nil
    o.m_oTrackFile = nil
    o.m_oMemCurrentFile = nil
    o.m_bOpenMeasure = false
    o.m_mDebugMessage ={}
    o.m_mTestMerge = {
        time = nil,
        total = nil,
    }

    o.m_oTestShareObj = nil

    return o
end

function CDictatorObj:Init(mInit)
    local f1
    f1 = function ()
        self:DelTimeCb("_CheckEndless")
        self:AddTimeCb("_CheckEndless", 1*1000, f1)
        self:_CheckEndless()
    end
    f1()
end

function CDictatorObj:AllServiceBooted(sType)
    self.m_mBootedFinish[sType] = true
    for k, v in pairs(self.m_mBootedFinish) do
        if not v then
            return
        end
    end

    if is_auto_open_measure() then
        self:CtrlMeasure(true)

        local f1
        f1 = function ()
            self:DelTimeCb("_DumpTestMeasure")
            self:AddTimeCb("_DumpTestMeasure", 30*60*1000, f1)
            self:_DumpTestMeasure()
        end
        f1()
    end

    if is_auto_monitor() then
        self:CtrlMonitor(true)
    end
end

function CDictatorObj:_DumpTestMeasure()
    self:DumpMeasure()
end

function CDictatorObj:WriteMeasureInfo(mInfo, lWaste)
    if self.m_oMeasureFile then
        self.m_oMeasureFile:close()
        self.m_oMeasureFile = nil
    end

    local TIMESTAMP_KEY = 3
    local CALLNAME_KEY = 4
    local SINGLE_TIME_KEY = 5
    table.sort(lWaste, function (a, b)
        return a[TIMESTAMP_KEY] < b[TIMESTAMP_KEY]
    end)
    local l = {}
    for _, v in ipairs(lWaste) do
        table.insert(l, {time=os.date("%c", math.floor(v[TIMESTAMP_KEY]/1000)), callname=v[CALLNAME_KEY], waste=v[SINGLE_TIME_KEY]})
    end

    local lProfile = {}
    for k, v in pairs(mInfo) do
        table.insert(lProfile, {
            TOTAL_TIME = v.total_time,
            TOTAL_COUNT = v.total_count,
            AVG_TIME = v.total_time/v.total_count,
            FUNC_NAME = k,
        })
    end
    table.sort(lProfile, function (a, b)
        if a["AVG_TIME"] > b["AVG_TIME"] then
            return true
        elseif a["AVG_TIME"] == b["AVG_TIME"] then
            if a["TOTAL_TIME"] > b["TOTAL_TIME"] then
                return true
            elseif a["TOTAL_TIME"] == b["TOTAL_TIME"] then
                if a["TOTAL_COUNT"] < b["TOTAL_COUNT"] then
                    return true
                elseif a["TOTAL_COUNT"] == b["TOTAL_COUNT"] then
                    return a["FUNC_NAME"] < b["FUNC_NAME"]
                else
                    return false
                end
            else
                return false
            end
        else
            return false
        end
    end)

    local f = io.open("log/lua_measure.log", "wb")
    self.m_oMeasureFile = f
    f:write(string.format("%s\n", os.date("%c", get_time())))

    local s = require("base.extend").Table.pretty_serialize(lProfile)
    f:write("TIME PROFILE:\n")
    f:write(string.format("%s\n", s))
    s = require("base.extend").Table.pretty_serialize(l)
    f:write("WASTE PROFILE:\n")
    f:write(string.format("%s\n", s))

    self.m_oMeasureFile:close()
    self.m_oMeasureFile = nil
end

function CDictatorObj:GetServiceCount()
    local iTotal = 0
    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            iTotal = iTotal + 1
        end
    end
    return iTotal
end

function CDictatorObj:ReloadRes()
    interactive.Send(".res", "common", "ReloadRes", {})
end

function CDictatorObj:ClientRes()
    local sCmd = [[
        reload(lualib_path("public.version"))
    ]]
    reload(lualib_path("public.version"))

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    interactive.Send(".clientupdate", "common", "ResUpdate", {})

    return true
end

function CDictatorObj:ClientCode()
    local sCmd = [[
        reload("cs_common/code/src/clientupdatecode")
        reload(lualib_path("public.version"))
    ]]
    reload("cs_common/code/src/clientupdatecode")
    reload(lualib_path("public.version"))

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    interactive.Send(".clientupdate", "common", "CodeUpdate", {})

    return true
end

function CDictatorObj:MemCheckGlobal()
    local sCmd = [[
        local global = require "global"

        local r = setmetatable({}, {__mode="kv"})
        local m = {}
        local recu
        recu = function (mg, prefix)
            for k, v in pairs(mg) do
                if type(v) == "table" then
                    if not r[v] then
                        r[v] = true
                        local iLen = table_count(v)
                        local sKey = prefix.."."..k
                        if iLen >= 100 then
                            m[sKey] = iLen
                        end
                        recu(v, sKey)
                    end
                end
            end
        end

        recu(global, "")

        return m
    ]]

    local mCbInfo = {
        total = self:GetServiceCount(),
        result = {},
    }
    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            local sKey = string.format("[%s.%08x]", k, tonumber(v2))
            interactive.Request(v2, "default", "ExecuteString", {cmd = sCmd}, function (mRecord, mData)
                if not is_release(self) then
                    self:_MemCheckGlobal(sKey, mCbInfo, mData.data)
                end
            end)
        end
    end

    return true
end

function CDictatorObj:_MemCheckGlobal(sKey, mCbInfo, mData)
    local iTotal = mCbInfo.total
    local m = mCbInfo.result

    if iTotal <= 0 then
        return
    end

    iTotal = iTotal - 1
    m[sKey] = mData

    mCbInfo.total = iTotal
    mCbInfo.result = m

    if iTotal <= 0 then
        self:WriteMemCheckGlobal(m)
    end
end

function CDictatorObj:MemCurrent()
    local sCmd = [[
        local skynet = require "skynet"
        local memcmp = require "base.memcmp"
        local m = memcmp.current()
        return m
    ]]

    local mCbInfo = {
        total = self:GetServiceCount(),
        result = {},
    }
    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            local sKey = string.format("[%s.%08x]", k, tonumber(v2))
            interactive.Request(v2, "default", "ExecuteString", {cmd = sCmd}, function (mRecord, mData)
                if not is_release(self) then
                    self:_MemCurrent(sKey, mCbInfo, mData.data)
                end
            end)
        end
    end

    return true
end

function CDictatorObj:_MemCurrent(sKey, mCbInfo, mData)
    local iTotal = mCbInfo.total
    local m = mCbInfo.result

    if iTotal <= 0 then
        return
    end

    iTotal = iTotal - 1
    m[sKey] = mData

    mCbInfo.total = iTotal
    mCbInfo.result = m

    if iTotal <= 0 then
        self:WriteMemCurrentInfo(m)
    end
end

function CDictatorObj:MemShowTrack()
    local sCmd = [[
        local skynet = require "skynet"
        local memcmp = require "base.memcmp"
        local m = memcmp.showtrack()
        return m
    ]]

    local mCbInfo = {
        total = self:GetServiceCount(),
        result = {},
    }
    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            local sKey = string.format("[%s.%08x]", k, tonumber(v2))
            interactive.Request(v2, "default", "ExecuteString", {cmd = sCmd}, function (mRecord, mData)
                if not is_release(self) then
                    self:_MemShowTrack(sKey, mCbInfo, mData.data)
                end
            end)
        end
    end

    return true
end

function CDictatorObj:_MemShowTrack(sKey, mCbInfo, mData)
    local iTotal = mCbInfo.total
    local m = mCbInfo.result

    if iTotal <= 0 then
        return
    end

    iTotal = iTotal - 1
    m[sKey] = mData

    mCbInfo.total = iTotal
    mCbInfo.result = m

    if iTotal <= 0 then
        self:WriteTrackInfo(m)
    end
end

function CDictatorObj:MemSnapshot()
    local sCmd = [[
        local skynet = require "skynet"
        local memcmp = require "base.memcmp"
        memcmp.shot()
    ]]

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    return true
end

function CDictatorObj:MemDiff()
    local sCmd = [[
        local skynet = require "skynet"
        local memcmp = require "base.memcmp"
        local m = memcmp.diff()
        return m
    ]]

    local mCbInfo = {
        total = self:GetServiceCount(),
        result = {},
    }
    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            local sKey = string.format("[%s.%08x]", k, tonumber(v2))
            interactive.Request(v2, "default", "ExecuteString", {cmd = sCmd}, function (mRecord, mData)
                if not is_release(self) then
                    self:_MemDiff(sKey, mCbInfo, mData.data)
                end
            end)
        end
    end

    return true
end

function CDictatorObj:_MemDiff(sKey, mCbInfo, mData)
    local iTotal = mCbInfo.total
    local m = mCbInfo.result

    if iTotal <= 0 then
        return
    end

    iTotal = iTotal - 1
    m[sKey] = mData

    mCbInfo.total = iTotal
    mCbInfo.result = m

    if iTotal <= 0 then
        self:WriteMemInfo(m)
    end
end

function CDictatorObj:WriteMemCheckGlobal(mInfo)
    if self.m_oMemCheckGlobalFile then
        self.m_oMemCheckGlobalFile:close()
        self.m_oMemCheckGlobalFile = nil
    end

    local f = io.open("log/lua_memcheckglobal.log", "wb")
    self.m_oMemCheckGlobalFile = f
    f:write(string.format("%s\n", os.date("%c", get_time())))

    for k, v in pairs(mInfo) do
        f:write(string.format("\n%s {%s}:\n", k, table_count(v)))

        local lv = {}
        for k2, v2 in pairs(v) do
            table.insert(lv, {k2, v2})
        end
        table.sort(lv, function (a, b)
            return a[2] > b[2]
        end)

        for _, ite in ipairs(lv) do
            local k2, v2 = ite[1], ite[2]
            f:write(string.format("%s : (%s)\n", k2, v2))
        end
    end

    self.m_oMemCheckGlobalFile:close()
    self.m_oMemCheckGlobalFile = nil
end

function CDictatorObj:WriteMemCurrentInfo(mInfo)
    if self.m_oMemCurrentFile then
        self.m_oMemCurrentFile:close()
        self.m_oMemCurrentFile = nil
    end

    local f = io.open("log/lua_memcurrent.log", "wb")
    self.m_oMemCurrentFile = f
    f:write(string.format("%s\n", os.date("%c", get_time())))

    for k, v in pairs(mInfo) do
        f:write(string.format("\n%s {%s}:\n", k, table_count(v)))
        for k2, v2 in pairs(v) do
            f:write(string.format("%s : (%s)\n", k2, v2))
        end
    end

    self.m_oMemCurrentFile:close()
    self.m_oMemCurrentFile = nil
end

function CDictatorObj:WriteTrackInfo(mInfo)
    if self.m_oTrackFile then
        self.m_oTrackFile:close()
        self.m_oTrackFile = nil
    end

    local f = io.open("log/lua_memtrack.log", "wb")
    self.m_oTrackFile = f
    f:write(string.format("%s\n", os.date("%c", get_time())))

    for k, v in pairs(mInfo) do
        f:write(string.format("\n%s {%s}:\n", k, table_count(v)))
        for _, item in ipairs(v) do
            local k2, v2 = item[1], item[2]
            f:write(string.format("%s : (%s)\n", v2, k2))
        end
    end

    self.m_oTrackFile:close()
    self.m_oTrackFile = nil
end

function CDictatorObj:WriteMemInfo(mInfo)
    if self.m_oMemFile then
        self.m_oMemFile:close()
        self.m_oMemFile = nil
    end

    local f = io.open("log/lua_snapshot.log", "wb")
    self.m_oMemFile = f
    f:write(string.format("%s\n", os.date("%c", get_time())))

    for k, v in pairs(mInfo) do
        f:write(string.format("\n%s {%s}:\n", k, table_count(v)))
        for k2, v2 in pairs(v) do
            f:write(string.format("%s (%s)\n", k2, v2))
        end
    end

    self.m_oMemFile:close()
    self.m_oMemFile = nil
end

function CDictatorObj:DumpMeasure()
    local sCmd = [[
        local skynet = require "skynet"
        local a, b = skynet.measure_info()
        local m = {
            time = a,
            waste = b,
        }
        return m
    ]]

    local mCbInfo = {
        total = self:GetServiceCount(),
        result = {},
        waste = {},
    }
    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Request(v2, "default", "ExecuteString", {cmd = sCmd}, function (mRecord, mData)
                if not is_release(self) then
                    self:_DumpMeasure1(mCbInfo, mData.data)
                end
            end)
        end
    end

    return true
end

function CDictatorObj:_DumpMeasure1(mCbInfo, mData)
    local iTotal = mCbInfo.total
    local m = mCbInfo.result
    local l = mCbInfo.waste

    if iTotal <= 0 then
        return
    end

    local mTime = mData.time
    local lWaste = mData.waste

    local COUNT_KEY = 1
    local TIME_KEY = 2
    iTotal = iTotal - 1
    for k, v in pairs(mTime) do
        if not m[k] then
            m[k] = {total_count = 0, total_time = 0}
        end
        m[k].total_count = m[k].total_count + v[COUNT_KEY]
        m[k].total_time = m[k].total_time + v[TIME_KEY]
    end
    for _, v in ipairs(lWaste) do
        table.insert(l, v)
    end
    mCbInfo.total = iTotal
    mCbInfo.result = m
    mCbInfo.waste = l

    if iTotal <= 0 then
        self:WriteMeasureInfo(m, l)
    end
end

function CDictatorObj:IsOpenMeasure()
    return self.m_bOpenMeasure
end

function CDictatorObj:CtrlMonitor(bOpen)
    local sCmd
    if bOpen then
        sCmd = [[
            local rt_monitor = require "base.rt_monitor"
            if not rt_monitor.is_open_monitor() then
                rt_monitor.change_monitor(true)
            end
        ]]
    else
        sCmd = [[
            local rt_monitor = require "base.rt_monitor"
            if rt_monitor.is_open_monitor() then
                rt_monitor.change_monitor(false)
            end
        ]]
    end

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    return true
end

function CDictatorObj:CtrlMeasure(bOpen)
    local sCmd
    if bOpen then
        sCmd = [[
            local skynet = require "skynet"
            if not skynet.is_open_measure() then
                skynet.open_measure()
            end
        ]]
    else
        sCmd = [[
            local skynet = require "skynet"
            if skynet.is_open_measure() then
                skynet.close_measure()
            end
        ]]
    end

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    return true
end


function CDictatorObj:StartMemMonitor()
    skynet.send(".mem_monitor", "lua", "Start")

    local sCmd = [[
        local mem_monitor = require "base.mem_monitor"
        mem_monitor.Start()
    ]]

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    return true
end

function CDictatorObj:StopMemMonitor()
    local sCmd = [[
        local mem_monitor = require "base.mem_monitor"
        mem_monitor.Stop()
    ]]

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    skynet.send(".mem_monitor", "lua", "Dump")
    skynet.send(".mem_monitor", "lua", "Stop")

    return true
end

function CDictatorObj:DumpMemMonitor()
    skynet.send(".mem_monitor", "lua", "Dump")
end

function CDictatorObj:ClearMemMonitor()
    skynet.send(".mem_monitor", "lua", "Clear")
end

function CDictatorObj:UpdateCode(sModuleList, bUpdateProto)
    --first check update files exist
    local lLackFiles = {}
    for _, v in ipairs(split_string(sModuleList, ",")) do
        if string.find(v, "/") then
            v = v..".lua"
        elseif string.find(v, "%.") then
            v = string.gsub(v, "%.", "/")..".lua"
        end
        if not exist_file(v) then
            table.insert(lLackFiles, v)
        end
    end
    if next(lLackFiles) then
        local sErr = "files not find:"
        for _, v in ipairs(lLackFiles) do
            sErr = sErr .. "\n" .. v
        end
        return false, sErr
    end

    local sCmd = string.format([[
        if %s == true then
            local netproto = require "base.netproto"
            netproto.Update()
        end

        local lst = split_string('%s', ",")
        for _, v in ipairs(lst) do
            reload(v)
        end

        local global = require "global"
        local oDerivedFileMgr = global.oDerivedFileMgr
        if oDerivedFileMgr then
            oDerivedFileMgr:Reload()
        end
    ]], bUpdateProto, sModuleList)

    local f, sErr = load(sCmd)
    if not f then
        record.warning(sErr)
        print_back(sErr)
        return
    else
        safe_call(f)
    end

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    return true
end

function CDictatorObj:UpdateFix(sFunc,...)
    reload(service_path("fixbug"))
    safe_call(fixbug[sFunc],...)
    return true
end

function CDictatorObj:CloseGS()
    local mCloseService = {
        [".world"]  =1,
    }
    for sService, iIdx in pairs(mCloseService) do
        local iAddress = global.mServiceNote[sService][iIdx]
        interactive.Send(iAddress, "dictator", "CloseGS")
    end
end

function CDictatorObj:CloseCS()
    os.exit()
end

function CDictatorObj:CloseBS()
    os.exit()
end

function CDictatorObj:CloseKS()
    os.exit()
end


function CDictatorObj:OpenGate(iStatus)
    interactive.Send(".login", "login", "SetGateOpenStatus", {status = iStatus})
end

function CDictatorObj:SetEndlessCheck(sAddr, bOpen)
    if not bOpen then
        self.m_mCheckEndless[sAddr] = nil
    else
        self.m_mCheckEndless[sAddr] = get_time()
    end
end

function CDictatorObj:_CheckEndless()
    assert(not is_release(self), "_CheckEndless fail")
    local iNowTime = get_time()
    if not self.m_iCheckHeartBeat or self.m_iCheckHeartBeat + 4 <= iNowTime then
        self.m_iCheckHeartBeat = iNowTime
        for k, v in pairs(self.m_mCheckEndless) do
            local sCmd = string.format([[
                local interactive = require "base.interactive"
                interactive.Send(".dictator", "common", "ResponseCheckEndless", {addr = %d})
            ]], k)
            interactive.Send(k, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    for k, v in pairs(self.m_mCheckEndless) do
        local iDiff = iNowTime - v
        if iDiff >= 20 then
            record.warning(string.format("CheckEndless check delay(%s sec) %s", iDiff, k))
        end
        if iDiff >= 180 then
            record.warning(string.format("CheckEndless delete delay(%s sec) %s", iDiff, k))
            c.command("SIGNAL", skynet.address(k))
            self.m_mCheckEndless[k] = iNowTime
            break
        end
    end
end

function CDictatorObj:UpdateCheckEndless(sAddr)
    if self.m_mCheckEndless[sAddr] then
        self.m_mCheckEndless[sAddr] = get_time()
    end
end

function CDictatorObj:ChangeServiceGCMode(sServiceName,iMode,iTime,iSize)
    sServiceName = "." .. sServiceName
    local sCmd = [[
        local servicegc = require "base.servicegc"
        ]]
    local sCmd2 = "servicegc.SetGCConfig("..iMode
    iTime = tonumber(iTime) or "nil"
    iSize = tonumber(iSize) or "nil"
    sCmd2 = sCmd2 .. "," .. iTime
    sCmd2 = sCmd2 .. "," .. iSize
    sCmd2 = sCmd2 .. ")"
    sCmd = sCmd .. sCmd2
    for _, v2 in ipairs(global.mServiceNote[sServiceName]) do
        interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
    end
    return true
end

function CDictatorObj:LookServiceGCMode(sServiceName,print_back)
    sServiceName = "." .. sServiceName
    local sCmd = [[
        local servicegc = require "base.servicegc"
        return servicegc.TipGCInfo()
    ]]
    for _, v2 in ipairs(global.mServiceNote[sServiceName]) do
        interactive.Request(v2, "default", "ExecuteString", {cmd = sCmd},function (r,d)
            print_back(d.data)
        end)
    end
    return true
end

function CDictatorObj:CheckGC()
    local sCmd = [[
        local interactive = require "base.interactive"
        local record = require "public.record"
        interactive.Send(".dictator", "common", "SetEndlessCheck", {
            addr = MY_ADDR,
            is_open = false,
        })
        local c1 = collectgarbage("count")
        collectgarbage("collect")
        local c2 = collectgarbage("count")
        interactive.Send(".dictator", "common", "SetEndlessCheck", {
            addr = MY_ADDR,
            is_open = true,
        })
        record.info(string.format("GC: %s %s before:%s after:%s", MY_SERVICE_NAME, MY_ADDR, c1, c2))
    ]]

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end
end

function CDictatorObj:AddDebugMessage(sKey)
    if not self.m_mDebugMessage[sKey] then
        self.m_mDebugMessage[sKey] = 0
    end
    self.m_mDebugMessage[sKey] = self.m_mDebugMessage[sKey] + 1
end

function CDictatorObj:DeleteDebugMessage(sKey)
    if not self.m_mDebugMessage[sKey] then
        self.m_mDebugMessage[sKey] = 0
    end
    self.m_mDebugMessage[sKey] = self.m_mDebugMessage[sKey] - 1
end

function CDictatorObj:TestMerge(iTotal, iIndex, iCount, lData)
    if iIndex == 1 then
        print("testmerge begin")
        self.m_mTestMerge = {
            time = get_time(true),
            total = iTotal,
        }
    end
    for _, v in ipairs(lData) do
        local a, b, c, d, e, f = v.a, v.b, v.c, v.d, v.e, v.f
        for i = 1, 100 do
            local r = (a + b - c) *d / e
            local br = r >= f
        end
    end

    self.m_mTestMerge.total = self.m_mTestMerge.total - iCount
    if self.m_mTestMerge.total == 0 then
        print("testmerge result:", iTotal, iIndex, get_time(true) - self.m_mTestMerge.time)
        self.m_mTestMerge.total = nil
        self.m_mTestMerge.time = nil
    end
end

function CDictatorObj:TestShareObj()
    self.m_oTestShareObj = CTestShareObj:New(0, {a = 1, b = 2, c = 3}, "1")
    self.m_oTestShareObj:Init()
    self:DelTimeCb("_TestShareObj")

    local iCount = 0
    local f1
    f1 = function ()
        iCount = iCount + 1
        self:DelTimeCb("_TestShareObj")

        if iCount > 10 then
            self.m_oTestShareObj = nil
            return
        end

        self:AddTimeCb("_TestShareObj", 5*1000, f1)
        self:_TestShareObj()
    end
    f1()

    return self.m_oTestShareObj:GenReaderCopy()
end

function CDictatorObj:_TestShareObj()
    local o = self.m_oTestShareObj
    o.m_iTestInt = o.m_iTestInt + 1
    o.m_sTestStr = tostring(tonumber(o.m_sTestStr) + 1)
    local m = o.m_mTestMap
    m.a = m.a + 1
    m.b = m.b + 1
    m.c = m.c + 1
    o:Update()
end

function CDictatorObj:UpdateAchievekey()
    interactive.Send(".achieve", "common", "UpdateAchievekey", {})

    return true
end

function CDictatorObj:UpdateHandBookKey()
    interactive.Send(".world", "common", "UpdateHandBookKey", {})

    return true
end

function CDictatorObj:StartRtMemMonitor()
    interactive.Send(".mem_rt_monitor", "common", "Start",{})

    local sCmd = [[
        local mem_rt_monitor = require "base.mem_rt_monitor"
        mem_rt_monitor.Start()
    ]]

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    return true
end

function CDictatorObj:StopRtMemMonitor()
    local sCmd = [[
        local mem_rt_monitor = require "base.mem_rt_monitor"
        mem_rt_monitor.Stop()
    ]]

    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end

    interactive.Send(".mem_rt_monitor", "common", "Dump",{})
    interactive.Send(".mem_rt_monitor", "common", "Stop",{})

    return true
end

function CDictatorObj:DumpRtMemMonitor()
    interactive.Send(".mem_rt_monitor", "common", "Dump",{})
end

function CDictatorObj:ClearRtMemMonitor()
    interactive.Send(".mem_rt_monitor", "common", "Clear",{})
end

function CDictatorObj:StartMerger(iMergeTimes)
    if is_cs_server() then
        interactive.Send(".merger", "common", "StartCSMerger", {merger_times = iMergeTimes})
    else
        interactive.Send(".merger", "common", "StartGSMerger", {merger_times = iMergeTimes})
    end
end

function CDictatorObj:ChangeGCSize()
    local sCmd = [[
        local skynet = require "skynet"
        local iSize = skynet.change_gc_size(256)
        print("change_gc_size",MY_ADDR,iSize)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
    for _, v in ipairs(global.mServiceNote[".assist"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
    return true
end

CTestShareObj = {}
CTestShareObj.__index = CTestShareObj
inherit(CTestShareObj, shareobj.CShareWriter)

function CTestShareObj:New(iTestInt, mTestMap, sTestStr)
    local o = super(CTestShareObj).New(self)
    o.m_iTestInt = iTestInt
    o.m_mTestMap = mTestMap
    o.m_sTestStr = sTestStr
    return o
end

function CTestShareObj:Pack()
    local m = {}
    m.testint = self.m_iTestInt
    m.teststr = self.m_sTestStr
    m.testmap = self.m_mTestMap
    return m
end

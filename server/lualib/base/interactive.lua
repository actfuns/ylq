
local skynet = require "skynet"
local extype = require "base.extype"
local rt_monitor = require "base.rt_monitor"

local M = {}

local bOpenMerge = false

local tinsert = table.insert

local SEND_TYPE = 1
local REQUEST_TYPE = 2
local RESPONSE_TYPE = 3

local mNote = {}
local mDebug = {}
local mQueue = {}
local iSessionIdx = 0

local function HandleSingleCmd(moduleLogic, mRecord, mData)
    local iType = mRecord.type
    if iType == RESPONSE_TYPE then
        local iNo = mRecord.session
        local f = mNote[iNo]
        local md = mDebug[iNo]
        if f then
            mNote[iNo] = nil
            if md then
                safe_call(function ()
                    rt_monitor.mo_call({"interactive", iType, md.module, md.cmd}, f, mRecord, mData)
                end)
            else
                safe_call(function ()
                    rt_monitor.mo_call({"interactive", iType, "None", "None"}, f, mRecord, mData)
                end)
            end
        end
        mDebug[iNo] = nil
    else
        local sModule = mRecord.module
        local sCmd = mRecord.cmd

        if sModule ~= "default" then
            if moduleLogic then
                safe_call(function ()
                    rt_monitor.mo_call({"interactive", iType, sModule, sCmd}, moduleLogic.Invoke, sModule, sCmd, mRecord, mData)
                end)
            end
        else
            local rr, br
            if sCmd == "ExecuteString" then
                local f, sErr = load(mData.cmd)
                if not f then
                    print(sErr)
                else
                    br, rr = safe_call(function ()
                        return rt_monitor.mo_call({"interactive", iType, sModule, sCmd}, f)
                    end)
                end
            end
            if iType == REQUEST_TYPE then
                M.Response(mRecord.source, mRecord.session, {data = rr})
            end
        end
    end
end

function M.Init(bOpen)
    if bOpen then
        bOpenMerge = true
    else
        bOpenMerge = false
    end
end

function M.PushQueue(sAddr, mArgs, mData)
    local iAddr = skynet.servicekey(sAddr)
    if iAddr then
        local m = mQueue[iAddr]
        if not m then
            m = {}
            mQueue[iAddr] = m
        end
        tinsert(m, {mArgs, mData})
    else
        print(string.format("lxldebug interactive PushQueue error %s", sAddr))
    end
end

function M.PopQueueAll()
    for k, v in pairs(mQueue) do
        skynet.send(k, "logic", v)
    end
    mQueue = {}
end

function M.GetSession()
    iSessionIdx = iSessionIdx + 1
    if iSessionIdx >= 100000000 then
        iSessionIdx = 1
    end
    return iSessionIdx
end

function M.Send(iAddr, sModule, sCmd, mData)
    mData = mData or {}
    if bOpenMerge then
        M.PushQueue(iAddr, {source = MY_ADDR, module = sModule, cmd = sCmd, session = 0, type =SEND_TYPE}, mData)
    else
        skynet.send(iAddr, "logic", {source = MY_ADDR, module = sModule, cmd = sCmd, session = 0, type =SEND_TYPE}, mData)
    end
end

function M.Request(iAddr, sModule, sCmd, mData, fCallback)
    mData = mData or {}
    local iNo  = M.GetSession()
    mNote[iNo] = fCallback
    mDebug[iNo] = {
        time = get_time(),
        addr = iAddr,
        module = sModule,
        cmd = sCmd,
    }
    if bOpenMerge then
        M.PushQueue(iAddr, {source = MY_ADDR, module = sModule, cmd = sCmd, session = iNo, type = REQUEST_TYPE}, mData)
    else
        skynet.send(iAddr, "logic", {source = MY_ADDR, module = sModule, cmd = sCmd, session = iNo, type = REQUEST_TYPE}, mData)
    end
end

function M.Response(iAddr, iNo, mData)
    mData = mData or {}
    if bOpenMerge then
        M.PushQueue(iAddr, {source = MY_ADDR, session = iNo, type = RESPONSE_TYPE}, mData)
    else
        skynet.send(iAddr, "logic", {source = MY_ADDR, session = iNo, type = RESPONSE_TYPE}, mData)
    end
end

function M.Dispatch(logiccmd)
    skynet.register_protocol {
        name = "logic",
        id = extype.LOGIC_TYPE,
        pack = skynet.pack,
        unpack = skynet.unpack,
    }

    if bOpenMerge then
        skynet.dispatch("logic", function(session, address, lQueue)
            for _, oq in ipairs(lQueue) do
                local mRecord = oq[1]
                local mData = oq[2]
                HandleSingleCmd(logiccmd, mRecord, mData)
            end
        end)

        local funcPopQueue
        funcPopQueue = function ()
            M.PopQueueAll()
            skynet.timeout(1, funcPopQueue)
        end
        funcPopQueue()
    else
        skynet.dispatch("logic", function(session, address, mRecord, mData)
            HandleSingleCmd(logiccmd, mRecord, mData)
        end)
    end

    local funcCheckSession
    funcCheckSession = function ()
        local iTime = get_time()
        local lDel = {}
        for k, v in pairs(mDebug) do
            local iDiff = iTime - v.time
            if iDiff >= 10 then
                print(string.format("warning: interactive check delay(%s sec) session:%d time:%d addr:%s module:%s cmd:%s",
                    iDiff, k, v.time, v.addr, v.module, v.cmd)
                )
            end
            if iDiff >= 180 then
                print(string.format("warning: interactive delete delay(%s sec) session:%d time:%d addr:%s module:%s cmd:%s",
                    iDiff, k, v.time, v.addr, v.module, v.cmd)
                )
                tinsert(lDel, k)
            end
        end
        for _, k in ipairs(lDel) do
            local v = mDebug[k]
            mNote[k] = nil
            mDebug[k] = nil
        end
        skynet.timeout(2*100, funcCheckSession)
    end
    funcCheckSession()
end

return M

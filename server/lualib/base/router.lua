
local skynet = require "skynet"
local netpack = require "netpack"
local extype = require "base.extype"
local interactive = require "base.interactive"
local rt_monitor = require "base.rt_monitor"

local M = {}

M.PROTO_R2P = {
    R2PRouter = 101,
    R2PHeartBeat = 102,
    R2PRouterBig = 103,
}

M.PROTO_P2R = {
    P2RRouter = 101,
    P2RHeartBeat = 102,
    P2RRouterBig = 103,
}

M.SEND_TYPE = 1
M.REQUEST_TYPE = 2
M.RESPONSE_TYPE = 3

local mNote = {}
local mDebug = {}
local iSessionIdx = 0

function M.GetSession()
    iSessionIdx = iSessionIdx + 1
    if iSessionIdx >= 100000000 then
        iSessionIdx = 1
    end
    return iSessionIdx
end

function M.Send(sServerKey, iAddr, sModule, sCmd, mData)
    mData = mData or {}
    interactive.Send(".router_c", "common", "ApplySendP2P", {
        record = {srcsk = get_server_tag(), dessk = sServerKey, src = MY_ADDR, des = iAddr, module = sModule, cmd = sCmd, type = M.SEND_TYPE},
        data = mData,
    })
end

function M.Request(sServerKey, iAddr, sModule, sCmd, mData, fCallback)
    mData = mData or {}
    local iNo  = M.GetSession()
    mNote[iNo] = fCallback
    mDebug[iNo] = {
        time = get_time(),
        sk = sServerKey,
        addr = iAddr,
        module = sModule,
        cmd = sCmd,
    }
    interactive.Send(".router_c", "common", "ApplySendP2P", {
        record = {srcsk = get_server_tag(), dessk = sServerKey, src = MY_ADDR, des = iAddr, module = sModule, cmd = sCmd, type = M.REQUEST_TYPE, session = iNo},
        data = mData,
    })
end

function M.Response(sServerKey, iAddr, iNo, mData)
    mData = mData or {}
    interactive.Send(".router_c", "common", "ApplySendP2P", {
        record = {srcsk = get_server_tag(), dessk = sServerKey, src = MY_ADDR, des = iAddr, type = M.RESPONSE_TYPE, session = iNo},
        data = mData,
    })
end

function M.DispatchR(netcmd)
    skynet.register_protocol {
        name = "zinc",
        id = extype.ZINC,
        pack = function ( ... )
            return ...
        end,
    }

    skynet.register_protocol {
        name = "zinc_client",
        id = extype.ZINC_CLIENT,
        unpack = function (...) return ... end,
        dispatch = function (session, source, msg, sz)
            if netcmd then
                local sData = netpack.tostring2(msg, sz)
                assert(#sData >= 5, "zinc_client unpack error")
                local fd = sData:byte(1)*(2^24) + sData:byte(2)*(2^16) + sData:byte(3)*(2^8) + sData:byte(4)
                local iP2RCmd = sData:byte(5)
                local sCmdData = string.sub(sData, 6)
                local mCmdData
                if #sCmdData > 0 then
                    mCmdData = skynet.unpack(sCmdData)
                else
                    mCmdData = {}
                end
                netcmd.Invoke(iP2RCmd, fd, mCmdData)
            end
        end,
    }
end

function M.DispatchC(routercmd)
    skynet.register_protocol {
        name = "router",
        id = extype.ROUTER_TYPE,
        pack = skynet.pack,
        unpack = skynet.unpack,
    }

    skynet.dispatch("router", function(session, address, mRecord, mData)
        local iType = mRecord.type
        if iType == M.RESPONSE_TYPE then
            local iNo = mRecord.session
            local f = mNote[iNo]
            local md = mDebug[iNo]
            if f then
                mNote[iNo] = nil
                if md then
                    safe_call(function ()
                        rt_monitor.mo_call({"router", iType, md.module, md.cmd}, f, mRecord, mData)
                    end)
                else
                    safe_call(function ()
                        rt_monitor.mo_call({"router", iType, "None", "None"}, f, mRecord, mData)
                    end)
                end
            end
            mDebug[iNo] = nil
        else
            local sModule = mRecord.module
            local sCmd = mRecord.cmd

            if sModule ~= "default" then
                if routercmd then
                    safe_call(function ()
                        rt_monitor.mo_call({"router", iType, sModule, sCmd}, routercmd.Invoke, sModule, sCmd, mRecord, mData)
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
                            return rt_monitor.mo_call({"router", iType, sModule, sCmd}, f)
                        end)
                    end
                end
                if iType == M.REQUEST_TYPE then
                    M.Response(mRecord.srcsk, mRecord.src, mRecord.session, {data = rr})
                end
            end
        end
    end)

    local funcCheckSession
    funcCheckSession = function ()
        local iTime = get_time()
        local lDel = {}
        for k, v in pairs(mDebug) do
            local iDiff = iTime - v.time
            if iDiff >= 10 then
                print(string.format("warning: router check delay(%s sec) session:%d time:%d sk:%s addr:%s module:%s cmd:%s",
                    iDiff, k, v.time, v.sk, v.addr, v.module, v.cmd)
                )
            end
            if iDiff >= 180 then
                print(string.format("warning: router delete delay(%s sec) session:%d time:%d sk:%s addr:%s module:%s cmd:%s",
                    iDiff, k, v.time, v.sk, v.addr, v.module, v.cmd)
                )
                table.insert(lDel, k)
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

 -- module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"
local router = require "base.router"

local bkdefines = import(service_path("bkdefines"))

function QueryLimitHuodong(mData, fCallback)
    local res =require "base.res"
    local mDaoBiao = res["daobiao"]["open_limit"]
    local lRet = {}
    for idx, m in pairs(mDaoBiao) do
        local lPlan = {}
        for _, mPlan in ipairs(m.plan or {}) do
            table.insert(lPlan, {plan_id = mPlan.id, plan_name=mPlan.name})
        end
        table.insert(lRet, {idx = idx, name = m.name, plans=lPlan})
    end
    fCallback({errcode = 0, data = lRet})
end

function SetHuodongOpen(mData, fCallback)
    local mRemote = {}
    mRemote.idx = tonumber(mData.idx)
    mRemote.plan = tonumber(mData.plan)
    mRemote.starttime = bkdefines.AnalyTimeStamp2(mData.starttime)
    mRemote.endtime = bkdefines.AnalyTimeStamp2(mData.endtime)
    if mRemote.endtime <= get_time() then
        fCallback({errcode =1, errmgs = "endtime error", data = {}})
        return
    end
    local sServer = mData.servers
    local lServer = {}
    local oBackendObj = global.oBackendObj
    if mData["allserver"] then
        lServer = oBackendObj:GetAllServers()
    else
        local lServerId = split_string(sServer, ",")
        for _,s in pairs(lServerId) do
            local oServer = oBackendObj:GetServerObj(s)
            if oServer then
                table.insert(lServer, oServer)
            end
        end
    end
    local mHandle = {
            count = #lServer,
            all_send = false,
            err_list = {},
            server = {},
            time = get_time(),
    }
    if #lServer > 0 then
        for _, oServer in ipairs(lServer) do
            mHandle.server[oServer:ServerID()] = "开启活动超时"
            SetRemoteHuodong(oServer:ServerID(),mHandle,mRemote, fCallback)
        end
    else
        fCallback({errcode = 2, errmgs = "no server keys"})
    end
end

function SetRemoteHuodong(sServer, mHandle, mRemote, fCallback)
    router.Request(get_server_tag(sServer), ".world", "backend", "SetHuodongOpen", mRemote, function (mRecord, mData)
        if mData.errmgs then
            table.insert(mHandle.err_list, {server = sServer, errmgs = mData.errmgs})
        end
        mData = mData or {}
        mHandle.count = mHandle.count - 1
        mHandle.server[sServer] = nil
        JudgeSetHuodongFinish(mHandle, fCallback)
    end)
end

function JudgeSetHuodongFinish(mHandle, fCallback)
    if not mHandle.all_send and (mHandle.count <= 0 or (get_time() - mHandle.time >= 30)) then
        mHandle.all_send = true
        for sServer, errmgs in pairs(mHandle.server or {}) do
            table.insert(mHandle.err_list, {server = sServer, errmgs = errmgs})
        end
        if #mHandle.err_list > 0 then
            fCallback({errcode = 3, data = mHandle.err_list})
        else
            fCallback({errcode = 0, data = {}})
        end
    end
end

function QueryOpenHuodong(mData, fCallback)
    local mRemote = {}
    if mData.idx then
        mRemote.idx = tonumber(mData.idx)
    end
    if mData.starttime then
        mRemote.starttime = bkdefines.AnalyTimeStamp2(mData.starttime)
    end
    if mData.endtime then
        mRemote.endtime = bkdefines.AnalyTimeStamp2(mData.endtime)
    end
    local sServer = mData.servers
    local lServer = {}
    local oBackendObj = global.oBackendObj
    if mData["allserver"] then
        lServer = oBackendObj:GetAllServers()
    else
        local lServerId = split_string(sServer, ",")
        for _,s in pairs(lServerId) do
            local oServer = oBackendObj:GetServerObj(s)
            if oServer then
                table.insert(lServer, oServer)
            end
        end
    end
    local mHandle = {
            count = #lServer,
            all_send = false,
            err_list = {},
            data = {},
            server = {},
            time = get_time(),
    }
    if #lServer > 0 then
        for _, oServer in ipairs(lServer) do
            mHandle.server[oServer:ServerID()] = "请求活动超时"
            QueryRemoteOpenHuodong(oServer:ServerID(),mHandle, mRemote, fCallback)
        end
    else
        fCallback({errcode = 2, errmgs = "no server keys"})
    end
end

function QueryRemoteOpenHuodong(sServer, mHandle, mRemote, fCallback)
    router.Request(get_server_tag(sServer), ".world", "backend", "QueryOpenHuodong", mRemote, function (mRecord, mData)
        if mData.errmgs then
            table.insert(mHandle.err_list, {server = sServer, errmgs = mData.errmgs})
        else
            for _, m in ipairs(mData.data or {}) do
                m.server = sServer
                table.insert(mHandle.data, m)
            end
        end
        mData = mData or {}
        mHandle.count = mHandle.count - 1
        mHandle.server[sServer] = nil
        JudgeQueryHuodongFinish(mHandle, fCallback)
    end)
end

function JudgeQueryHuodongFinish(mHandle, fCallback)
    if not mHandle.all_send and (mHandle.count <= 0 or (get_time() - mHandle.time >= 30)) then
        mHandle.all_send = true
        for sServer, errmgs in pairs(mHandle.server or {}) do
            table.insert(mHandle.err_list, {server = sServer, errmgs = errmgs})
        end
        fCallback({errcode = 0, data = mHandle.data, errlist = mHandle.err_list})
    end
end
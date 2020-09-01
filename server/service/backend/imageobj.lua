 -- module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local router = require "base.router"

local min = math.min

function GetNoPassImages(mData, fCallback)
    local oBackendObj = global.oBackendObj
    local sServer = mData["servers"]

    local lServer = {}
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
    local iCount = #lServer
    local mHandle = {
        is_send = false,
        count = iCount,
        list = {},
    }
    if iCount > 0 then
        for _, oServer in ipairs(lServer) do
            RemoteNoPassImages(oServer:ServerID(), mHandle, fCallback)
        end
    else
        JudgeSendNoPassImages(mHandle, fCallback)
    end
end

function RemoteNoPassImages(sServer, mHandle, fCallback)
    local mData = {cmd="GetNoPassImages", data={}}
    router.Request(get_server_tag(sServer), ".image", "backend", "Forward", mData, function (mRecord, mData)
        mData = mData or {}
        mHandle.count = mHandle.count - 1
        for _, m in ipairs(mData.data or {}) do
            m.server = sServer
            table.insert(mHandle.list, m)
        end
        list_combine(mHandle.list, mData.data or {})
        JudgeSendNoPassImages(mHandle, fCallback)
    end)
end

function JudgeSendNoPassImages(mHandle, fCallback)
    if mHandle.count <= 0 and not mHandle.is_send then
        mHandle.is_send = true
        table.sort(mHandle.list, function(v1, v2)
            return v1.createtime > v2.createtime
        end)
        local iLen = min(100, #mHandle.list)
        local lImages = {}
        for i=1, iLen do
            table.insert(lImages, mHandle.list[i])
        end
        local mRet = {
            errcode = 0,
            data = lImages,
        }
        fCallback(mRet)
    end
end

function CheckImagePass(mData, fCallback)
    local mServerImage = {}
    local lImages = mData.data or {}
    for _, m in ipairs(lImages) do
        local sServer = m.server
        m.server = nil
        if not mServerImage[sServer] then
            mServerImage[sServer] = {}
        end
        table.insert(mServerImage[sServer], m.key)
    end
    local mHandle = {
        is_send = false,
        count = table_count(mServerImage),
    }
    if next(mServerImage) then
        for sServer, m in pairs(mServerImage) do
            RemoteCheckImagePass(sServer, m, mHandle, fCallback)
        end
    else
        JudgeSendCheckImagePass(mHandle, fCallback)
    end
end

function RemoteCheckImagePass(sServer, lCheck, mHandle, fCallback)
    local mData = {cmd="CheckImagePass", data=lCheck}
    router.Request(get_server_tag(sServer), ".image", "backend", "Forward", mData, function (mRecord, mData)
        mData = mData or {}
        if mData.errcode ~= 0 then
            mHandle.is_send = true
            fCallback(mData)
        end
        mHandle.count = mHandle.count - 1
        JudgeSendCheckImagePass(mHandle, fCallback)
    end)
end

function JudgeSendCheckImagePass(mHandle, fCallback)
    if mHandle.count <= 0 and not mHandle.is_send then
        fCallback({errcode = 0})
    end
end
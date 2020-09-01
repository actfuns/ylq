local interactive = require "base.interactive"
local router = require "base.router"
local serverdefines = require "public.serverdefines"
local netproto = require "base.netproto"
local record = require "public.record"
local net = require "base.net"

local bigpacket = import(lualib_path("public.bigpacket"))
local unpack = table.unpack

local M = {}
local mPlayerMail = {}
local mSecPlayerMail = {}
local mNeedSec = false

function M.SetNeedSec()
    mNeedSec = true
end

function M.UpdatePlayerMail(iPid, mail)
    if mNeedSec then
        mSecPlayerMail[iPid] = mail
    else
        mPlayerMail[iPid] = mail
    end
end

function M.ReplacePlayerMail(iPid)
    if mSecPlayerMail[iPid] then
        mPlayerMail[iPid] = mSecPlayerMail[iPid]
        mSecPlayerMail[iPid] = nil
    end
end

function M.GetPlayerMail(iPid)
    return mPlayerMail[iPid]
end

function M.Send(iPid, sMessage, mData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.Send(mMail,sMessage,mData)
end

function M.SendList(iPid,lData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    local lData2 = {}
    for _,info in pairs(lData) do
        if info.message and info.data then
            M.Send(mMail,info.message,info.data)
        end
    end
end

function M.PackData(sMessage,mData)
    return net.PackData(sMessage,mData)
end

function M.SendRaw(iPid, sData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.SendRaw(mMail,sData)
end

function M.SendRawList(iPid,lData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.SendRawList(mMail,lData)
end

function M.SendMergePacket(iPid,lMessage)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.SendMergePacket(mMail,lMessage)
end

function M.SendMergePacketRaw(iPid,lPacketsData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.SendMergePacketRaw(mMail,lPacketsData)
end

function M.KFSend(sServerKey,iPid,sMessage,mData)
    local iSendAddr = ".player_send_proxy"..(iPid%PLAYER_SEND_COUNT+1)
    router.Send(get_server_tag(sServerKey), iSendAddr, "kuafu", "KFDoAddSend",
        { pid = iPid , message = sMessage , data = mData })
end

function M.KFSendRaw(sServerKey,iPid,sData)
    local iSendAddr = ".player_send_proxy"..(iPid%PLAYER_SEND_COUNT+1)
    router.Send(get_server_tag(sServerKey), iSendAddr, "kuafu", "KFSendRaw",
        { pid = iPid , sdata = sData })
end

return M

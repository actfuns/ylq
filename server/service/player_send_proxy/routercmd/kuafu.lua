--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"
local playersend = require "base.playersend"

function KFDoAddSend(mRecord, mData)
    playersend.Send(mData.pid,mData.message, mData.data)
end

function KFSendRaw(mRecord, mData)
    playersend.SendRaw(mData.pid, mData.sdata)
end
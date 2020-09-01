--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function Start(mRecord,mData)
    local oMonitor = global.oMonitor
    oMonitor:Start()
end

function Stop(mRecord,mData)
    local oMonitor = global.oMonitor
    oMonitor:Stop()
end

function Dump(mRecord,mData)
    local oMonitor = global.oMonitor
    oMonitor:WriteRtMonitor()
end

function Clear(mRecord,mData)
    local oMonitor = global.oMonitor
    oMonitor:Clear()
end

function AddRtMonitor(mRecord,mData)
    local oMonitor = global.oMonitor
    oMonitor:AddRtMonitor(mData)
end
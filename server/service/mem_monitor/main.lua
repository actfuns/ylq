local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"

local monitor = import(service_path("monitor"))

skynet.start(function()
    local oMonitor = monitor.NewMonitor()
    oMonitor:Init()
    global.oMonitor = oMonitor

    skynet.dispatch("lua", function(session, address, cmd, ...)
        if cmd == "Record" then
            oMonitor:Record(...)
        elseif cmd == "Start" then
            oMonitor:Start()
        elseif cmd == "Stop" then
            oMonitor:Stop()
        elseif cmd == "Dump" then
            oMonitor:Dump()
        elseif cmd == "Clear" then
            oMonitor:Clear()
        end
    end)

    skynet.fork(function ()
        while true do
            skynet.sleep(600 * 100) -- sleep 10 min
            collectgarbage("collect")
        end
    end)

    skynet.register ".mem_monitor"

    record.info("mem_monitor service booted")
end)

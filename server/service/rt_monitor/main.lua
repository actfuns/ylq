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
        elseif cmd == "DayCommandMonitor" then
            oMonitor:OnTime()
        elseif cmd == "Dump" then
            oMonitor:WriteMonitorInfo()
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

    skynet.register ".rt_monitor"

    record.info("rt_monitor service booted")
end)

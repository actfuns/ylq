local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local record = require "public.record"
local interactive = require "base.interactive"

require "skynet.manager"

local monitor = import(service_path("monitor"))
local logiccmd = import(service_path("logiccmd.init"))


skynet.start(function()
    interactive.Dispatch(logiccmd)
    local oMonitor = monitor.NewMonitor()
    oMonitor:Init()
    global.oMonitor = oMonitor

    skynet.fork(function ()
        while true do
            skynet.sleep(600 * 100) -- sleep 10 min
            collectgarbage("collect")
        end
    end)

    skynet.register ".mem_rt_monitor"

    record.info("mem_rt_monitor service booted")
end)
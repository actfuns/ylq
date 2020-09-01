local skynet = require "skynet"
require "skynet.manager"
local serverdefines = require "public.serverdefines"

local interactive = require "base.interactive"
local record = require "public.record"

skynet.start(function()
    record.info("ks start")

    local iConsolePort = assert(serverdefines.get_gm_console_port())
    skynet.newservice("debug_console", iConsolePort)
    skynet.newservice("res")
    skynet.newservice("rt_monitor")
    skynet.newservice("mem_monitor")
    skynet.newservice("dictator")
    skynet.newservice("router_c")

    skynet.newservice("webrouter")
    skynet.newservice("logdb")

    skynet.newservice("logmonitor")
    for iNo=1,KS_WORLD_SERVICE_COUNT do
        skynet.newservice("world",iNo)
    end

    record.info("ks all service booted")
    interactive.Dispatch()
    interactive.Send(".dictator", "common", "AllServiceBooted", {type = "launcher"})
    skynet.exit()
end)

local skynet = require "skynet"
require "skynet.manager"
local serverdefines = require "public.serverdefines"

local interactive = require "base.interactive"
local record = require "public.record"

skynet.start(function()
    record.info("gs start")

    local iConsolePort = assert(serverdefines.get_gm_console_port())
    skynet.newservice("debug_console", iConsolePort)
    skynet.newservice("res")
    skynet.newservice("rt_monitor")
    skynet.newservice("mem_monitor")
    skynet.newservice("mem_rt_monitor")
    skynet.newservice("dictator")
    skynet.newservice("router_c")

    skynet.newservice("webrouter")
    skynet.newservice("logdb")
    for iNo=1,GAMEDB_SERVICE_COUNT do
        skynet.newservice("gamedb",iNo)
    end
    skynet.newservice("login")
    skynet.newservice("broadcast")
    skynet.newservice("clientupdate")
    skynet.newservice("logfile")
    skynet.newservice("achieve")
    skynet.newservice("logmonitor")
    skynet.newservice("image")
    skynet.newservice("client")
    skynet.newservice("gamepush")
    skynet.newservice("world")
    skynet.newservice("merger")

    record.info("gs all service booted")
    interactive.Dispatch()
    interactive.Send(".dictator", "common", "AllServiceBooted", {type = "launcher"})
    interactive.Send(".clientupdate", "common", "CheckRes", {})
    skynet.exit()
end)

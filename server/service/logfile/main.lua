local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local logfileobj = import(service_path("logfileobj"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oLogFileObj = logfileobj.NewLogFileObj()
    global.oLogFileObj:Init()

    skynet.register ".logfile"
    interactive.Send(".dictator", "common", "Register", {
        type = ".logfile",
        addr = MY_ADDR,
    })

    record.info("logfile service booted")
end)

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))

skynet.start(function()
    interactive.Dispatch(logiccmd)

    interactive.Send(".dictator", "common", "Register", {
        type = ".webhandler",
        addr = MY_ADDR,
    })

    record.info("webhandler service booted")
end)

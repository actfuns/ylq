local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"

local gamedefines = import(lualib_path("public.gamedefines"))
local logiccmd = import(service_path("logiccmd.init"))
local merger_gs = import(service_path("merger_gs"))
local merger_cs = import(service_path("merger_cs"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oGSMerger = merger_gs.NewMerger()
    global.oCSMerger = merger_cs.NewMerger()

    skynet.register ".merger"
    interactive.Send(".dictator", "common", "Register", {
        type = ".merger",
        addr = MY_ADDR,
    })

    record.info("merger service booted")
end)

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local basehook = require "base.basehook"
local res = require "base.res"
local record = require "public.record"
local router = require "base.router"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local imagemgr = import(service_path("imagemgr"))
local routercmd = import(service_path("routercmd.init"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    router.DispatchC(routercmd)
    net.Dispatch()

    global.oImageMgr = imagemgr.NewImageMgr()

    skynet.register ".image"
    interactive.Send(".dictator", "common", "Register", {
        type = ".image",
        addr = MY_ADDR,
    })

    record.info("image service booted")
end)
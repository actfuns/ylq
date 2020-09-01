local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local targetmgr = import(service_path("targetobj"))


skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oTargetMgr = targetmgr.NewTargetMgr()
    
    skynet.register ".autoteam"
    interactive.Send(".dictator", "common", "Register", {
        type = ".autoteam",
        addr = MY_ADDR,
    })
    record.info("autoteam service booted")
end)
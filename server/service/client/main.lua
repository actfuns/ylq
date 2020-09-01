local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"

local gamedefines = import(lualib_path("public.gamedefines"))
local logiccmd = import(service_path("logiccmd.init"))
local aimgr = import(service_path("aimgr"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oAIMgr = aimgr.NewAIMgr()

    skynet.register ".client"
    interactive.Send(".dictator", "common", "Register", {
        type = ".client",
        addr = MY_ADDR,
    })
    
    record.info("client service booted")
end)

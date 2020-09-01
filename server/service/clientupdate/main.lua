local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"

local gamedefines = import(lualib_path("public.gamedefines"))
local logiccmd = import(service_path("logiccmd.init"))
local updatemgr = import(service_path("updatemgr"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oUpdateMgr = updatemgr.NewUpdateMgr()
    global.oUpdateMgr:Init()

    skynet.register ".clientupdate"
    interactive.Send(".dictator", "common", "Register", {
        type = ".clientupdate",
        addr = MY_ADDR,
    })
    
    record.info("clientupdate service booted")
end)

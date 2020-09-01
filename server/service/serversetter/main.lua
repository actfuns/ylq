local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local router = require "base.router"
local record = require "public.record"
local res = require "base.res"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local routercmd = import(service_path("routercmd.init"))
local setterobj = import(service_path("setterobj"))
local fuliobj = import(service_path("fuliobj"))
local punishobj = import(service_path("punishobj"))


skynet.start(function()
    interactive.Dispatch(logiccmd)
    router.DispatchC(routercmd)

    global.oSetterMgr = setterobj.NewSetterMgr()
    global.oSetterMgr:Init()

    global.oFuliMgr = fuliobj.NewFuliMgr()
    global.oFuliMgr:Init()

    global.oPunishMgr = punishobj.NewPunishMgr()
    global.oPunishMgr:Init()

    skynet.register(".serversetter")
    interactive.Send(".dictator", "common", "Register", {
        type = ".serversetter",
        addr = MY_ADDR,
    })

    record.info("serversetter service booted")
end)
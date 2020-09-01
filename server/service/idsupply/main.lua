local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"
local router = require "base.router"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local playeridmgr = import(service_path("playeridmgr"))
local orgidmgr = import(service_path("orgidmgr"))
local routercmd = import(service_path("routercmd.init"))
local showidmgr = import(service_path("showidmgr"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    router.DispatchC(routercmd)

    global.oPlayerIdMgr = playeridmgr.NewPlayerIdMgr()
    global.oPlayerIdMgr:LoadDb()

    global.oShowIdMgr = showidmgr:NewShowIdMgr()
    global.oShowIdMgr:LoadDb()

    global.oOrgIdMgr = orgidmgr.NewOrgIdMgr()
    global.oOrgIdMgr:LoadDb()

    skynet.register ".idsupply"
    interactive.Send(".dictator", "common", "Register", {
        type = ".idsupply",
        addr = MY_ADDR,
    })
    record.info("idsupply service booted")
end)

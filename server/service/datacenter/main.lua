local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local router = require "base.router"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local routercmd = import(service_path("routercmd.init"))
local datacenterobj = import(service_path("datacenterobj"))
local serverinfo = import(lualib_path("public.serverinfo"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    router.DispatchC(routercmd)

    global.oDataCenter = datacenterobj.NewDataCenter()
    global.oDataCenter:Init()
    
   local m = serverinfo.get_local_dbs()

    global.oDataCenter:InitDataCenterDb({
        host = m.datacenter.host,
        port = m.datacenter.port,
        username = m.datacenter.username,
        password = m.datacenter.password,
        name = "game",
    })

    skynet.register ".datacenter"
    interactive.Send(".dictator", "common", "Register", {
        type = ".datacenter",
        addr = MY_ADDR,
    })

    record.info("datacenter service booted")
end)
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local router = require "base.router"
local record = require "public.record"
require "skynet.manager"

local serverinfo = import(lualib_path("public.serverinfo"))
local logiccmd = import(service_path("logiccmd.init"))
local routercmd = import(service_path("routercmd.init"))
local redeemcodemgr = import(service_path("redeemcodemgr"))


skynet.start(function()
    interactive.Dispatch(logiccmd)
    router.DispatchC(routercmd)

    local m = serverinfo.get_local_dbs()
    global.oRedeemCodeMgr = redeemcodemgr.NewRedeemCodeMgr()
    global.oRedeemCodeMgr:InitDB({
        host = m.game.host,
        port = m.game.port,
        username = m.game.username,
        password = m.game.password,
        name = "game"
    })

    skynet.register ".redeemcode"
    interactive.Send(".dictator", "common", "Register", {
        type = ".redeemcode",
        addr = MY_ADDR,
    })
    
    record.info("redeemcode service booted")
end)

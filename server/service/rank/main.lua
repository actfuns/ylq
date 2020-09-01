local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local rankmgr = import(service_path("rankmgr"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oRankMgr = rankmgr.NewRankMgr()
    global.oRankMgr:LoadAllRank()
    
    skynet.register ".rank"
    interactive.Send(".dictator", "common", "Register", {
        type = ".rank",
        addr = MY_ADDR,
    })

    record.info("rank service booted")
end)

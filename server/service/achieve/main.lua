local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local basehook = require "base.basehook"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local achievemgr = import(service_path("achievemgr"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oAchieveMgr = achievemgr.NewAchieveMgr()
    global.oAchieveMgr:InitData()

    skynet.register ".achieve"
    interactive.Send(".dictator", "common", "Register", {
        type = ".achieve",
        addr = MY_ADDR,
    })

    record.info("achieve service booted")
end)
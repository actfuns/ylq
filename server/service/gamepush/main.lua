local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"

local gamedefines = import(lualib_path("public.gamedefines"))
local logiccmd = import(service_path("logiccmd.init"))
local gamepush = import(service_path("gamepush"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oGamePushMgr = gamepush.NewGamePushMgr()
    global.oGamePushMgr:Init()

    skynet.register ".gamepush"
    interactive.Send(".dictator", "common", "Register", {
        type = ".gamepush",
        addr = MY_ADDR,
    })
    
    record.info("gamepush service booted")
end)
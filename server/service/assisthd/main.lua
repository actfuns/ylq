-- 辅助活动的用途
local global = require "global"
local skynet = require "skynet"

local record = require "public.record"
local interactive = require "base.interactive"
local res = require "base.res"
local serverdefines = require "public.serverdefines"


require "skynet.manager"
local logiccmd = import(service_path("logiccmd.init"))

local assisthdmgr = import(service_path("assisthdmgr"))



skynet.start(function()
    interactive.Dispatch(logiccmd)

    global.oAssistDHMgr = assisthdmgr.NewAssistHDMgr()
    global.oAssistDHMgr:InitData()
    skynet.register ".assisthd"
    interactive.Send(".dictator", "common", "Register", {
        type = ".assisthd",
        addr = MY_ADDR,
    })
    record.info("assisthd service booted")
end)

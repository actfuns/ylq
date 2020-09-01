local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local basehook = require "base.basehook"
local res = require "base.res"
local record = require "public.record"
local playersend = require "base.playersend"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local scenemgrobj = import(service_path("scenemgrobj"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()
    playersend.SetNeedSec()

    global.oSceneMgr = scenemgrobj.NewSceneMgr()

    basehook.set_logic(function ()
        local oSceneMgr = global.oSceneMgr
        oSceneMgr:SceneDispatchFinishHook()
    end)

    interactive.Send(".dictator", "common", "Register", {
        type = ".scene",
        addr = MY_ADDR,
    })

    record.info("scene service booted")
end)

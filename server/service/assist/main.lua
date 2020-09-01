local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local basehook = require "base.basehook"
local res = require "base.res"
local record = require "public.record"
local router = require "base.router"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local cbobj = import(service_path("cbobj"))
local assistmgr = import(service_path("assistmgr"))
local notifymgr = import(service_path("notifymgr"))
local chatmgr = import(service_path("chat"))
local sceneobj = import(service_path("sceneobj"))
local uiobj = import(service_path("uiobj"))
local derivedfilemgr = import(lualib_path("public.derivedfile"))

local args = {...}

skynet.start(function()
    skynet.change_gc_size(256)

    interactive.Dispatch(logiccmd)
    net.Dispatch()
    router.DispatchC()

    global.oCbMgr = cbobj.NewCBMgr()
    global.oAssistMgr = assistmgr.NewAssistMgr()
    global.oAssistMgr:InitData()
    global.oNotifyMgr = notifymgr.NewNotifyMgr()
    global.oChatMgr = chatmgr.NewChatMgr()
    global.oSceneMgr = sceneobj.NewSceneMgr()
    global.oUIMgr = uiobj.NewUIMgr()

    basehook.set_logic(function ()
        local oAssistMgr = global.oAssistMgr
        oAssistMgr:DispatchFinishHook()
    end)

    skynet.register ".assist"
    interactive.Send(".dictator", "common", "Register", {
        type = ".assist",
        addr = MY_ADDR,
    })

    global.oDerivedFileMgr = derivedfilemgr.NewDerivedFileMgr()
    record.info("assist service booted")
end)
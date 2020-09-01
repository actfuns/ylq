local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"
local playersend = require "base.playersend"
local router = require "base.router"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local routercmd = import(service_path("routercmd.init"))
local warmgrobj = import(service_path("warmgrobj"))
local actionmgrobj = import(service_path("actionmgrobj"))
local worldboss = import(service_path("playwar.worldboss"))
local cbobj = import(service_path("cbobj"))
local derivedfilemgr = import(lualib_path("public.derivedfile"))
local fieldboss = import(service_path("playwar.fieldboss"))
local msattack = import(service_path("playwar.msattack"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()
    playersend.SetNeedSec()
    router.DispatchC(routercmd)

    global.oWarMgr = warmgrobj.NewWarMgr()
    global.oActionMgr = actionmgrobj.NewActionMgr()
    global.oWorldBoss = worldboss.CNewWorldBoss()
    global.oCbMgr = cbobj.NewCBMgr()
    global.oFieldBossMgr = fieldboss.NewFieldBossMgr()
    global.oMsattackObj = msattack.CNewMsattackMgr()

    interactive.Send(".dictator", "common", "Register", {
        type = ".war",
        addr = MY_ADDR,
    })

    global.oDerivedFileMgr = derivedfilemgr.NewDerivedFileMgr()
    record.info("war service booted")
end)

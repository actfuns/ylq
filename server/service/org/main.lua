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
local orgmgr = import(service_path("orgmgr"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()
    router.DispatchC()

    global.oOrgMgr = orgmgr.NewOrgMgr()
    global.oOrgMgr:LoadAllOrg()

    basehook.set_logic(function ()
        local oOrgMgr = global.oOrgMgr
        oOrgMgr:OrgDispatchFinishHook()
    end)

    skynet.register ".org"
    interactive.Send(".dictator", "common", "Register", {
        type = ".org",
        addr = MY_ADDR,
    })

    record.info("org service booted")
end)
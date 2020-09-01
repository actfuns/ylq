local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local basehook = require "base.basehook"
local servicetimer = require "base.servicetimer"
local texthandle = require "base.texthandle"
local router = require "base.router"
local res = require "base.res"
local record = require "public.record"
local serverdefines = require "public.serverdefines"

require "skynet.manager"

local kfmgr = import(service_path("kuafu.kfmgr"))
local kfwarobj = import(service_path("kuafu.kfwarobj"))
local kfhuodong = import(service_path("kuafu.kfhuodong"))

function KuaFuWorldStart(iNo)
    global.oKFMgr = kfmgr.NewKuaFuMgr()
    local lWarRemote = {}
    for i = 1, WAR_SERVICE_COUNT do
        local iAddr = skynet.newservice("war")
        table.insert(lWarRemote, iAddr)
    end
    global.oWarMgr = kfwarobj.NewWarMgr(lWarRemote)

    global.oHuodongMgr = kfhuodong.NewHuodongMgr()
    global.oHuodongMgr:InitData(iNo)
    skynet.newservice("recommend")
    skynet.register(".world"..iNo)
    interactive.Send(".dictator", "common", "Register", {
        type = ".world",
        addr = MY_ADDR,
    })

    record.info("world service booted")
end

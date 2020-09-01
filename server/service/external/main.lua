local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"
local router = require "base.router"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local routercmd = import(service_path("routercmd.init"))
local yybaoobj = import(service_path("yybaoobj"))
local yybaosdk = import(lualib_path("public.yybaosdk"))

local iNo = ...

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()
    router.DispatchC(routercmd)

    global.oYYBaoSdk = yybaosdk.NewYYBaoSdk()
    global.oYYBaoSdk:Init()
    global.oYYBaoObj = yybaoobj.NewYYBaoObj()
    global.oYYBaoObj:Init()

    skynet.register(".external"..iNo)

    interactive.Send(".dictator", "common", "Register", {
        type = ".external",
        addr = MY_ADDR,
    })

    record.info("external service booted")
end)

local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"

require "skynet.manager"

local netcmd = import(service_path("netcmd.init"))
local proxy = import(service_path("proxy"))

local sHostAddr, sHostCb = ...

skynet.start(function()
    interactive.Dispatch()
    net.DispatchProxy(netcmd)

    global.oProxy = proxy.NewProxy(sHostAddr, sHostCb)
    global.oProxy:Init()

    interactive.Send(".dictator", "common", "Register", {
        type = ".net_recv_proxy",
        addr = MY_ADDR,
    })

    record.info("net_recv_proxy service booted")
end)

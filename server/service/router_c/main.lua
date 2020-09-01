local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local interactive = require "base.interactive"
local router = require "base.router"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local clientmgr = import(service_path("clientmgr"))
local routerclient = import(service_path("routerclient"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    router.DispatchC()

    global.oClientMgr = clientmgr.NewClientMgr()

    local ports = split_string(ROUTER_S_PORTS,",")
    local num = #ports
    for iNo=1,ROUTER_CLIENT_COUNT do
        local iPort = tonumber(ports[iNo%num+1])
        if iPort then
            local oClient = routerclient.NewRouterClient(iPort)
            oClient:Init()
            global.oClientMgr:AddClient(oClient)
        end
    end

    skynet.register ".router_c"
    interactive.Send(".dictator", "common", "Register", {
        type = ".router_c",
        addr = MY_ADDR,
    })

    record.info("router_c service booted")
end)

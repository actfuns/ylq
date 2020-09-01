local global = require "global"
local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local interactive = require "base.interactive"
local record = require "public.record"
local serverdefines = require "public.serverdefines"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))

skynet.start(function()
    interactive.Dispatch(logiccmd)

    local iCount = WEB_SERVICE_COUNT
    local m = {}
    for i = 1, iCount do
        m[i] = skynet.newservice("webhandler")
    end

    local iWebPort = tonumber(serverdefines.get_web_port())
    local id = socket.listen("0.0.0.0", iWebPort)
    record.info(string.format("webrouter listen web port %d", iWebPort))

    local iBalance = 1
    socket.start(id , function(id, addr)
        interactive.Send(m[iBalance], "common", "HandleRequest", {socket_id = id, socket_addr = addr})
        iBalance = iBalance + 1
        if iBalance > #m then
            iBalance = 1
        end
    end)

    skynet.register ".webrouter"
    interactive.Send(".dictator", "common", "Register", {
        type = ".webrouter",
        addr = MY_ADDR,
    })

    record.info("webrouter service booted")
end)

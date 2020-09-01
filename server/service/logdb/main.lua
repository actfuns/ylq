local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local logobj = import(service_path("logobj"))
local serverinfo = import(lualib_path("public.serverinfo"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    local m = serverinfo.get_local_dbs()
    
    global.oLogObj = logobj.NewLogObj()
    global.oLogObj:Init({
        host = m.gamelog.host,
        port = m.gamelog.port,
        username = m.gamelog.username,
        password = m.gamelog.password,
        basename = "gamelog"
    })
    global.oLogObj:InitUnmoveLogDb({
        host = m.unmovelog.host,
        port = m.unmovelog.port, 
        username = m.unmovelog.username,
        password = m.unmovelog.password,
        basename = "unmovelog"
    })
    global.oLogObj:InitChatLogDb({
        host = m.chatlog.host,
        port = m.chatlog.port, 
        username = m.chatlog.username,
        password = m.chatlog.password,
        basename = "chatlog"
    })

    skynet.register ".logdb"
    interactive.Send(".dictator", "common", "Register", {
        type = ".logdb",
        addr = MY_ADDR,
    })
    
    record.info("logdb service booted")
end)

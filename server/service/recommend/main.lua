local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"
local res = require "base.res"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local relationmgr = import(service_path("relationobj"))
local matchmgr = import(service_path("matchmgr"))
local teampvp = import(service_path("teampvp"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oRelationMgr = relationmgr.NewCRelationMgr()
    
    local oMatchMgr = matchmgr.NewMatchMgr()
    
    global.oMatchMgr = oMatchMgr

    global.oTeamPVP = teampvp.NewCollection()

    skynet.register ".recommend"
    interactive.Send(".dictator", "common", "Register", {
        type = ".recommend",
        addr = MY_ADDR,
    })

    record.info("recommend service booted")
end)

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"
local res = require "base.res"

require "skynet.manager"

local gamedefines = import(lualib_path("public.gamedefines"))
local logiccmd = import(service_path("logiccmd.init"))
local gonggao = import(service_path("gonggao"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.mChannels[gamedefines.BROADCAST_TYPE.WORLD_TYPE] = {}
    global.mChannels[gamedefines.BROADCAST_TYPE.TEAM_TYPE] = {}
    global.mChannels[gamedefines.BROADCAST_TYPE.INTERFACE_TYPE] = {}
    global.mChannels[gamedefines.BROADCAST_TYPE.FRIEND_FOCUS_TYPE] = {}
    global.mChannels[gamedefines.BROADCAST_TYPE.ORG_TYPE] = {}
    global.mChannels[gamedefines.BROADCAST_TYPE.ORG_FUBEN] = {}
    global.mChannels[gamedefines.BROADCAST_TYPE.FIELD_BOSS] = {}
    global.mChannels[gamedefines.BROADCAST_TYPE.TEAMPVP_TYPE] = {}
    
    global.oGonggaoMgr = gonggao.NewGonggaoMgr()
    skynet.register ".broadcast"
    interactive.Send(".dictator", "common", "Register", {
        type = ".broadcast",
        addr = MY_ADDR,
    })
    record.info("broadcast service booted")
end)

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"
local res = require "base.res"
local router = require "base.router"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local backendobj = import(service_path("backendobj"))
local playerstat = import(service_path("playerstat"))
local costobj = import(service_path("costobj"))
local overviewobj = import(service_path("overviewobj"))
local queryobj = import(service_path("queryobj"))
local backendinfomgr = import(service_path("backendinfomgr"))
local noticemgr = import(service_path("noticemgr"))
local serverinfo = import(lualib_path("public.serverinfo"))
local gmtoolsobj = import(service_path("gmtoolsobj"))
local businessobj = import(service_path("businessobj"))
local routercmd = import(service_path("routercmd.init"))
local reportobj = import(service_path("reportobj"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    router.DispatchC(routercmd)

    global.oBackendObj = backendobj.NewBackendObj()
    global.oBackendObj:Init()

    local m = serverinfo.get_local_dbs()

    global.oBackendObj:InitBackendDb({
        host = m.backend.host,
        port = m.backend.port,
        username = m.backend.username,
        password = m.backend.password,
        name = "backend"
    })

    local mSlaveDb = serverinfo.get_slave_dbs()
    for k, v in pairs(mSlaveDb) do
        global.oBackendObj:AddNewServer(k, v.game, v.gamelog, v.gameumlog, v.chatlog)
    end

    global.oBackendObj:AfterAddServer()

    global.oCostObj = costobj.NewCostObj()
    global.oCostObj:Init()
    global.oPlayerStatObj = playerstat.NewPlayerStatObj()
    global.oPlayerStatObj:Init()
    global.oOverViewObj = overviewobj.NewOverViewObj()
    global.oOverViewObj:Init()
    global.oQueryObj = queryobj.NewQueryObj()
    global.oQueryObj:Init()
    global.oBackendInfoMgr = backendinfomgr.NewBackendInfoMgr()
    global.oNoticeMgr = noticemgr.NewNoticeMgr()
    global.oNoticeMgr:Init()
    global.oGmToolsObj = gmtoolsobj.NewGmToolsObj()
    global.oBusinessObj = businessobj.NewBusinessObj()
    global.oBusinessObj:Init()
    global.oReportObj = reportobj.NewReportObj()
    global.oReportObj:LoadDb()
    global.oReportObj:Schedule()

    skynet.register ".backend"
    interactive.Send(".dictator", "common", "Register", {
        type = ".backend",
        addr = MY_ADDR,
    })

    record.info("backend service booted")
end)

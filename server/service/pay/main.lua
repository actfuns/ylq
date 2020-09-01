local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local basehook = require "base.basehook"
local res = require "base.res"
local record = require "public.record"
local mongoop = require "base.mongoop"
local router = require "base.router"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local routercmd = import(service_path("routercmd.init"))
local paymgr = import(service_path("paymgr"))
local demisdk = import(lualib_path("public.demisdk"))
local serverinfo = import(lualib_path("public.serverinfo"))
local serverdefines = require "public.serverdefines"

local no = ...

skynet.start(function()
    interactive.Dispatch(logiccmd)
    router.DispatchC(routercmd)

    local m = serverinfo.get_local_dbs()
    local oClient = mongoop.NewMongoClient({
        host = m.game.host,
        port = m.game.port,
        username = m.game.username,
        password = m.game.password,
    })
    global.oGameDb = mongoop.NewMongoObj()
    global.oGameDb:Init(oClient, "game")

    local sRequestTableName = "requestpay"
    global.oGameDb:CreateIndex(sRequestTableName,{orderId = 1},{unique=true,name="pay_orderid_index"})
    global.oGameDb:CreateIndex(sRequestTableName,{roleId = 1},{name="pay_pid_index"})
    global.oGameDb:CreateIndex(sRequestTableName,{create_time = 1},{expireAfterSeconds=1209600,name="request_expire_index"})

    local sPayTableName = "pay"
    global.oGameDb:CreateIndex(sPayTableName,{orderid = 1},{unique=true,name="pay_orderid_index"})
    global.oGameDb:CreateIndex(sPayTableName,{pid = 1},{name="pay_pid_index"})


    global.oDemiSdk = demisdk.NewDemiSdk(true, no)
    global.oPayMgr = paymgr.NewPayMgr()

    skynet.register(string.format(".pay%d", no))
    interactive.Send(".dictator", "common", "Register", {
        type = ".pay",
        addr = MY_ADDR,
    })

    record.info("pay service booted")
end)

local skynet = require "skynet"

MY_ADDR = skynet.self()
MY_SERVER_KEY = skynet.getenv("server_key")
MY_SERVICE_NAME = ...
IS_PRODUCTION_ENV = tonumber(skynet.getenv("PRODUCTION_ENV"))
IS_AUTO_OPEN_MEASURE = tonumber(skynet.getenv("AUTO_OPEN_MEASURE"))
IS_AUTO_TRACK_BASEOBJECT = tonumber(skynet.getenv("AUTO_TRACK_BASEOBJECT"))
IS_AUTO_MONITOR = tonumber(skynet.getenv("AUTO_MONITOR"))
DATAANALYPATH = skynet.getenv("data_analy_path")

require "base.commonop"

local tbpool = require "base.tbpool"
tbpool.Init()

local servicetimer = require "base.servicetimer"
servicetimer.Init()

require "base.reload"
require "base.timeop"
require "base.fileop"
require "base.stringop"
require "base.tableop"
require "base.vector3"

local basehook = require "base.basehook"
local baserecycle = require "base.baserecycle"
local interactive = require "base.interactive"
local servicesave = require "base.servicesave"
local netproto = require "base.netproto"
--local servicegc = require "base.servicegc"

skynet.dispatch_finish_hook(basehook.hook)
basehook.set_base(function ()
    baserecycle.recycle()
end)

interactive.Init()
netproto.Init()
servicesave.Init()
--servicegc.Init()

create_folder(DATAANALYPATH..MY_SERVER_KEY)
--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

Cmds = {}

Cmds.login = import(service_path("logiccmd.login"))
Cmds.scene = import(service_path("logiccmd.scene"))
Cmds.war = import(service_path("logiccmd.war"))
Cmds.team = import(service_path("logiccmd.team"))
Cmds.dictator = import(service_path("logiccmd.dictator"))
Cmds.notify = import(service_path("logiccmd.notify"))
Cmds.friend = import(service_path("logiccmd.friend"))
huodongmodule = import(service_path("logiccmd.huodong"))
Cmds.arenagame = huodongmodule.arenagame
Cmds.worldboss = huodongmodule.worldboss
Cmds.pata = huodongmodule.pata
Cmds.orgfuben = huodongmodule.orgfuben
Cmds.terrawars = huodongmodule.terrawars
Cmds.yjfuben = huodongmodule.yjfuben
Cmds.fieldboss = huodongmodule.fieldboss
Cmds.msattack = huodongmodule.msattack
Cmds.clubarena = huodongmodule.clubarena
Cmds.upcard = huodongmodule.upcard
Cmds.rank = import(service_path("logiccmd.rank"))
Cmds.title = import(service_path("logiccmd.title"))
Cmds.partner = import(service_path("logiccmd.partner"))
Cmds.achieve = import(service_path("logiccmd.achieve"))
Cmds.item = import(service_path("logiccmd.item"))
Cmds.org = import(service_path("logiccmd.org"))
Cmds.common = import(service_path("logiccmd.common"))
Cmds.client = import(service_path("logiccmd.client"))
Cmds.merger = import(service_path("logiccmd.merger"))
Cmds.dailytrain = huodongmodule.dailytrain

function Invoke(sModule, sCmd, mRecord, mData)
    local m = Cmds[sModule]
    if m then
        local f = m[sCmd]
        if f then
            return f(mRecord, mData)
        end
    end
    record.error(string.format("Invoke fail %s %s %s %s", MY_SERVICE_NAME, MY_ADDR, sModule, sCmd))
end

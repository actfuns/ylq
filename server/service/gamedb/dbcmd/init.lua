--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

Cmds = {}

Cmds.playerdb = import(service_path("dbcmd.playerdb"))
Cmds.offlinedb = import(service_path("dbcmd.offlinedb"))
Cmds.worlddb = import(service_path("dbcmd.worlddb"))
Cmds.idcounter = import(service_path("dbcmd.idcounter"))
Cmds.namecounter = import(service_path("dbcmd.namecounter"))
Cmds.orgdb = import(service_path("dbcmd.orgdb"))
Cmds.global = import(service_path("dbcmd.global"))
Cmds.house = import(service_path("dbcmd.house"))
Cmds.rankdb = import(service_path("dbcmd.rankdb"))
Cmds.warfilmdb = import(service_path("dbcmd.warfilmdb"))
Cmds.partnerdb = import(service_path("dbcmd.partnerdb"))
Cmds.invitecodedb = import(service_path("dbcmd.invitecodedb"))
Cmds.achievedb = import(service_path("dbcmd.achievedb"))
Cmds.imagedb = import(service_path("dbcmd.imagedb"))
Cmds.fulidb = import(service_path("dbcmd.fulidb"))
Cmds.showid = import(service_path("dbcmd.showid"))
Cmds.playerinfodb = import(service_path("dbcmd.playerinfodb"))
Cmds.gamepush = import(service_path("dbcmd.gamepush"))

function Invoke(sModule, sCmd, mCond, mData)
    local m = Cmds[sModule]
    if m then
        local f = m[sCmd]
        if f then
            return f(mCond, mData)
        end
    end
    record.error(string.format("Invoke fail %s %s %s %s", MY_SERVICE_NAME, MY_ADDR, sModule, sCmd))
end
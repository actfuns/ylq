--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

Cmds = {}

Cmds.login = import(service_path("netcmd.login"))
Cmds.scene = import(service_path("netcmd.scene"))
Cmds.other = import(service_path("netcmd.other"))
Cmds.item = import(service_path("netcmd.item"))
Cmds.war = import(service_path("netcmd.war"))
Cmds.player = import(service_path("netcmd.player"))
Cmds.npc = import(service_path("netcmd.npc"))
Cmds.openui = import(service_path("netcmd.openui"))
Cmds.team = import(service_path("netcmd/team"))
Cmds.chat = import(service_path("netcmd/chat"))
Cmds.task = import(service_path("netcmd/task"))
Cmds.skill = import(service_path("netcmd/skill"))
Cmds.store = import(service_path("netcmd.store"))
Cmds.mail = import(service_path("netcmd.mail"))
Cmds.partner = import(service_path("netcmd.partner"))
Cmds.org = import(service_path("netcmd.org"))
Cmds.house = import(service_path("netcmd.house"))
Cmds.friend = import(service_path("netcmd.friend"))
Cmds.test = import(service_path("netcmd.test"))
Cmds.link = import(service_path("netcmd.link"))
Cmds.huodong = import(service_path("netcmd.huodong"))
Cmds.rank = import(service_path("netcmd.rank"))
Cmds.arena = import(service_path("netcmd.arena"))
Cmds.title = import(service_path("netcmd.title"))
Cmds.teach = import(service_path("netcmd/task"))
Cmds.achieve = import(service_path("netcmd/achieve"))
Cmds.handbook = import(service_path("netcmd/handbook"))
Cmds.image = import(service_path("netcmd/image"))
Cmds.travel = import(service_path("netcmd/travel"))
Cmds.minigame = import(service_path("netcmd/minigame"))
Cmds.fuli = import(service_path("netcmd/fuli"))

function Invoke(sModule, sCmd, fd, mData)
    local m = Cmds[sModule]
    if m then
        local f = m[sCmd]
        if f then
            local oWorldMgr = global.oWorldMgr
            local oPlayer = oWorldMgr:GetOnlinePlayerByFd(fd)
            if oPlayer then
                return f(oPlayer, mData)
            end
        else
            record.error(string.format("Invoke fail %s %s %s %s", MY_SERVICE_NAME, MY_ADDR, sModule, sCmd))
        end
    else
        record.error(string.format("Invoke fail %s %s %s %s", MY_SERVICE_NAME, MY_ADDR, sModule, sCmd))
    end
end

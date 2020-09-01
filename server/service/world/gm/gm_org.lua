--import module
local global = require "global"
local interactive = require "base.interactive"

Commands = {}
Helpers = {}
Opens = {}  --是否对外开放

Helpers.help = {
    "GM指令帮助",
    "help 指令名",
    "help 'clearall'",
}
function Commands.help(oMaster, sCmd)
    if sCmd then
        local o = Helpers[sCmd]
        if o then
            local sMsg = string.format("%s:\n指令说明:%s\n参数说明:%s\n示例:%s\n", sCmd, o[1], o[2], o[3])
            oMaster:Send("GS2CGMMessage", {
                msg = sMsg,
            })
        else
            oMaster:Send("GS2CGMMessage", {
                msg = "没查到这个指令"
            })
        end
    end
end

function Commands.giveorgwish(oMaster,iTarget)
    interactive.Send(".org", "common", "GiveOrgWish", {
        pid = oMaster:GetPid(),
        data = {target = iTarget},
    })
end

Helpers.org = {
    "公会指令",
    "org 指令编号 参数",
    "org 100"
}
function Commands.org(oMaster,iCmd,...)
    local mArgs = {...}
    interactive.Send(".org", "common", "TestOP", {
        pid = oMaster:GetPid(),
        cmd = iCmd,
        data = mArgs,
    })
end

function Commands.orgsetinfo(oMaster,sKey,value)
    interactive.Send(".org", "common", "SetPlayerInfo", {
        pid = oMaster:GetPid(),
        key = sKey,
        val = value,
    })
end

function Commands.orgactive(oMaster,value)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:RewardActivePoint(oMaster:GetPid(),value,"gm指令")
end

function Commands.clearorgleave(oMaster)
    interactive.Send(".org", "common", "ClearOrgLeave", {
        pid = oMaster:GetPid(),
    })
end
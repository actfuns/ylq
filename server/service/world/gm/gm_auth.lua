local global = require "global"

local mCommandAuth = {
    --
    [99] = {
    },
    [66] = {
        "daobiao",
        "onlinestat",
        "getserverinfo",
        "showscenestat",
        "showwarstat",
        "get",
        "looktime",
        "mingleiinfo",
        "SendBrocast",
        "checkplayer",
        "help"
    },
}

mGMAuthor = {
    [99] = {
    },
    [66] = {
    }
}

function IsGM(iPid)
    for iAuth,lPid in pairs(mGMAuthor) do
        if table_in_list(lPid,iPid) then
            return true
        end
    end
    return false
end

function GetAuthority(oPlayer)
    local iPid = oPlayer:GetPid()
     for iAuthority,lPid in pairs(mGMAuthor) do
        if table_in_list(lPid,iPid) then
            return iAuthority
        end
    end
    return 0
end

function IsSuper(iPid)
    local iAuthority = GetAuthority(oPlayer)
    if iAuthority >= 99 then
        return true
    end
    return false
end

function ValidUseCommand(oPlayer,sCmd)
    if not is_production_env() then
        return true
    end
    local oNotifyMgr = global.oNotifyMgr
    local iAuthority = GetAuthority(oPlayer)
    local iPid = oPlayer:GetPid()
    if iAuthority <= 0 then
        oNotifyMgr:Notify(iPid,"您不是gm，无法执行指令")
        return false
    end
    if iAuthority < 99 then
        local lCmd = mCommandAuth[iAuthority]
        if not lCmd or not table_in_list(lCmd,sCmd) then
            oNotifyMgr:Notify(iPid,"你的权限过低，无法执行该指令")
            return false
        end
    end
    return true
end

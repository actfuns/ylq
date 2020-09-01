--import module

local global = require "global"
local skynet = require "skynet"

local skyunpack = skynet.unpack

function Invoke(sParam)
    local m = skyunpack(sParam)
    local sCmd = m.cmd

    if sCmd == "badboy" then
        local iFd = m.fd
        local sDebug = m.debug
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByFd(iFd)
        if oPlayer then
            oPlayer:HandleBadBoy(sDebug)
        end
    end
end

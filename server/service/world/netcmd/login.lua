--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

function C2GSLogoutByOneKey(oConn,mData)
    local iPid = oConn.m_iPid
    if not iPid then
        print("C2GSLogoutByOneKey error:not iPid")
    else
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Disconnect()
        end
    end
end

function C2GSChangeAccount( oConn,mData)
    local iPid = oConn.m_iPid
    if not iPid then
        print("C2GSChangeAccount error:not iPid")
    else
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Disconnect()
        end
        --oWorldMgr:Logout(iPid)
    end
end
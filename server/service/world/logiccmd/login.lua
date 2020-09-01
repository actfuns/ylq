--import module
local global = require "global"
local skynet = require "skynet"

function DelConnection(mRecord, mData)
    local oWorldMgr = global.oWorldMgr
    local oConnection = oWorldMgr:GetConnection(mData.handle)
    if oConnection then
        oWorldMgr:DelConnection(mData.handle)
    end
end

function LoginPlayer(mRecord, mData)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:Login(mRecord, mData.conn, mData.role)
end

local global = require "global"

function C2GSMiniGameOp(oPlayer,mData)
    local name = mData.name
    local cmds = mData.cmds
    local oMiniGameMgr = global.oMiniGameMgr
    oMiniGameMgr:GameOp(oPlayer,name,cmds)
end

function C2GSGameCardEnd(oPlayer,mData)
    local name = mData.name
    local oMiniGameMgr = global.oMiniGameMgr
    oMiniGameMgr:GameEnd(oPlayer:GetPid(),name)
end
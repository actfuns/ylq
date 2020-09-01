local global = require "global"

function SendCallBack(mRecord,mData)
    local oCbMgr = global.oCbMgr
    local iPid = mData["pid"]
    local iWarId = mData["war_id"]
    if not iWarId then
        return
    end
    local iSessionIdx = mData["sessionidx"]
    local iTrueSessionIdx = iSessionIdx // 1000
    local oWarMgr = global.oWarMgr
    local oCbMgr = global.oCbMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        local oPlayer = oWar:GetPlayerWarrior(iPid)
        if oPlayer then
            oCbMgr:TrueCallback(oPlayer,iTrueSessionIdx,mData)
        end
    end
end
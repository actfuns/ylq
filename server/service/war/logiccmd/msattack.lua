--import module
local global = require "global"
local skynet = require "skynet"
local record = require "public.record"


function BossDie(mRecord, mData)
    -- local oMsattackObj = global.oMsattackObj
    -- oMsattackObj:SetDead()
    -- oMsattackObj:OnBossDie(mData.win)
end

function StartBossWar(mRecord,mData)
    local oMsattackObj = global.oMsattackObj
    oMsattackObj:SyncBossStatus()
end

function StopAllWar(mRecord,mData)
    local oMsattackObj = global.oMsattackObj
    oMsattackObj:StopAllWar(mData.win)
end
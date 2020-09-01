--import module
local global = require "global"
local skynet = require "skynet"
local record = require "public.record"


function BossDie(mRecord, mData)
    local oBoss = global.oWorldBoss
    oBoss:SetDead()
    local oWorldBoss = global.oWorldBoss
    oWorldBoss:OnBossDie(mData.win)
end

function StartBossWar(mRecord,mData)
    local oBoss = global.oWorldBoss
    oBoss:ReBirth(mData.arg)
    oBoss:SyncBossStatus()
end

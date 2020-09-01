--import module
local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

function NewFieldBoss(mRecord,mData)
    local iBossId = mData["bossid"]
    local mBossInfo = mData["bossinfo"]
    global.oFieldBossMgr:NewFieldBoss(iBossId,mBossInfo)
    local oBoss = global.oFieldBossMgr:GetBoss(iBossId)
    oBoss:SyncBossStatus()
end

function BossDie(mRecord,mData)
    local oBoss = global.oFieldBossMgr:GetBoss(mData.bossid)
    if oBoss then
        oBoss:SetDead()
        oBoss:OnBossDie()
    end
end

function RemoveFieldBoss(mRecord,mData)
    local iBossId = mData["bossid"]
    global.oFieldBossMgr:RemoveFieldBoss(iBossId)
end
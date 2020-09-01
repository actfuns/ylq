--import module
local global = require "global"
local skynet = require "skynet"
local record = require "public.record"


function BossDie(mRecord, mData)
    local oWarMgr = global.oWarMgr
    for _,oWar in pairs(oWarMgr.m_mWars) do
        if oWar.m_sWarType and oWar.m_sWarType == "orgfuben" then
            oWar:OnBossDie(mData.org,mData.boss)
        end
    end
end

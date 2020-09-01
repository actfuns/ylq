--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function C2GSSyncPosQueue(mRecord,mData)
    local iPid = mData.pid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene and oScene:GetSceneId() == mData.scene_id then
        local poslist = mData["poslist"]
        if #poslist < 1 then
            return
        end
        oScene:Forward("C2GSSyncPosQueue", iPid, mData)
    end
end
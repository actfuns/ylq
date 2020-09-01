--import module
local global = require "global"
local skynet = require "skynet"

local interactive = require "base.interactive"

function GetFriendInfo(mRecord, mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:LoadProfileAndFriend(mData.pid, function (oProfile,oFriend)
        if not oFriend or not  oProfile then
            interactive.Response(mRecord.source, mRecord.session, {
                pid = mData.pid,
            })
        else
	local mRelation = oFriendMgr:MakeRelation(oProfile,oFriend)
	interactive.Response(mRecord.source, mRecord.session, {
                pid = mData.pid,
                data = mRelation,
            })
        end
    end)
end


function UpdateFriendEquip(mRecord, mData)
    local iPid = mData.pid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oFriend = oPlayer:GetFriend()
        local equips = mData.equips or {}
        for iPos, mEquip in pairs(equips) do
            oFriend:SetEquip(iPos,mEquip)
        end
    end
end
--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function UpdateRoleInfo(mRecord,mData)
    local oTeamPVP = global.oTeamPVP
    oTeamPVP:UpdateInfo(mData.pid,mData.info)
end

function GetCollecttion(mRecord,mData)
    local oTeamPVP = global.oTeamPVP
    local mResult = oTeamPVP:GetCollecttion(mData.pid,mData.cnt,mData.exl)
    interactive.Response(mRecord.source, mRecord.session, { success = true , data = mResult ,})


end

function ClearAllCache(mRecord, mData)
    local oTeamPVP = global.oTeamPVP
    oTeamPVP:ClearAllCache()
end




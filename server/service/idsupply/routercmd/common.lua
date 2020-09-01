--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"

function GenOrgId(mRecord, mData)
    local oOrgIdMgr = global.oOrgIdMgr
    local id = oOrgIdMgr:GenOrgId()
    router.Response(mRecord.srcsk,mRecord.src,mRecord.session,{
        id = id,
    })
end

function GetShowIdByPid(mRecord, mData)
    local oShowIdMgr = global.oShowIdMgr
    local iPid = mData.pid
    local iSet = mData.set
    local iShowId = oShowIdMgr:GetShowIdByPid(iPid, iSet)
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {show_id = iShowId})
end

function GetPidByShowId(mRecord, mData)
    local oShowIdMgr = global.oShowIdMgr
    local iShowId = mData.show_id
    local iPid = oShowIdMgr:GetPidByShowId(iShowId)
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {pid = iPid})
end

function RemoveShowIdByPid(mRecord, mData)
    local oShowIdMgr = global.oShowIdMgr
    local iShowId = mData.show_id
    local iPid = mData.pid
    oShowIdMgr:RemoveShowIdByPid(iPid, iShowId)
end

function SetShowIdByPid(mRecord, mData)
    local oShowIdMgr = global.oShowIdMgr
    local iShowId = mData.show_id
    local iPid = mData.pid
    oShowIdMgr:SetShowIdByPid(iPid, iShowId)
end

function CheckShowId(mRecord, mData)
    local oShowIdMgr = global.oShowIdMgr
    local iShowId = mData.show_id
    local iPid = mData.pid
   
    local mResult = {}
    if not oShowIdMgr:IsShowId(iShowId) then
        mResult.ret = 1
    else
        local iOldShowId = oShowIdMgr:GetShowIdByPid(iPid)
        if iOldShowId then
            if iOldShowId == iShowId then
                mResult.ret = 2
            else
                mResult.ret = 3
            end
        end
        local iOldPid = oShowIdMgr:GetPidByShowId(iShowId)
        if iOldPid then
            mResult.ret = 4
        end
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mResult)
end
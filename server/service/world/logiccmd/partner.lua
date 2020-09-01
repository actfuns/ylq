--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function RemoteFightPartner(mRecord, mData)
    local iPid = mData.pid
    local iPos = mData.pos
    local iParid = mData.parid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:SyncFightPartner(iPos, iParid, mData.data)
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("teampvp")
        if oHuodong then
            oHuodong:OnSyncFightPartner(oPlayer)
        end
    end
end

function UpdatePartnerAmount(mRecord, mData)
    local iPid = mData.pid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:SetHaveAmount(mData.amount)
    end
end

function UpdateRemoteFightPartner(mRecord, mData)
    local iPid = mData.pid
    local iPos = mData.pos
    local iParid = mData.parid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:UpdateFightPartner(iPos, iParid, mData.data)
    end
end

function UpdateTop10PowerPartner(mRecord, mData)
    local iPid = mData.pid
    local oWorldMgr = global.oWorldMgr
    local o = oWorldMgr:GetOfflinePartner(iPid)
    if o then
        o:UpdateTop10Partner(mData.data)
    end
end

function UpdateTop4GradePartner(mRecord, mData)
    local iPid = mData.pid
    local oWorldMgr = global.oWorldMgr
    local o = oWorldMgr:GetOfflinePartner(iPid)
    if o then
        o:UpdateTop4GradePartner(mData.data)
    end
end

function RefreshShowPartner(mRecord, mData)
    local iPid = mData.pid
    local oWorldMgr = global.oWorldMgr
    local  oFriendMgr = global.oFriendMgr
    local o = oWorldMgr:GetOfflinePartner(iPid)
    if o then
        o:RefreshPartner(mData.data)
    end
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oThisTemp:Delete("ShowPartnerLimit")
        if mData.refresh  == 1 then
            oFriendMgr:TakeDocunment(oPlayer,oPlayer:GetPid())
        end
    end
end

function SyncFollowInfo(mRecord, mData)
    local iPid = mData.pid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    oPlayer:SetFollowerPartner(mData.data)
end

function SyncTravelPartner(mRecord, mData)
    local iPid = mData.pid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oTravel = oPlayer:GetTravel()
        oTravel:SyncTravelPartner(mData.data)
    end
end

function AddTravelPartner2Frd(mRecord, m)
    local oWorldMgr = global.oWorldMgr
    local iPid = m.pid
    local iFrdPid = m.frd_pid
    local mData = m.data
    oWorldMgr:LoadTravel(iFrdPid, function(oFrdTravel)
        _AddTravelPartner2Frd(mRecord, oFrdTravel, iPid, mData)
    end)
end

function _AddTravelPartner2Frd(mRecord, oFrdTravel, iPid, mData)
    local oWorldMgr = global.oWorldMgr

    local iFrdPid = oFrdTravel:GetPid()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        interactive.Response(mRecord.source, mRecord.session, {
            success = false,
        })
        return
    end
    local oTravel = oPlayer:GetTravel()
    local bSucc = false
    if not oTravel:HasMineTravel() and not oFrdTravel:HasFrdTravel() and oFrdTravel:IsTravel() then
        bSucc = true
        local iNow  = get_time()
        local iEndTime = oFrdTravel:EndTime()
        oTravel:AddMineTravel(iFrdPid, {
            frd_pid = iFrdPid,
            parid = mData.parid,
            name = mData.par_name,
            grade = mData.par_grade,
            start_time = iNow,
            end_time = iEndTime,
            recieve_status = 0,
            par_star = mData.par_star,
            par_model = mData.par_model,
            par_awake = mData.par_awake
            })
        oTravel:GS2CMineTravelPartnerInfo()
        oFrdTravel:AddFrdTravel(iPid, {
            frd_pid = iPid,
            frd_name = oPlayer:GetName(),
            parid = mData.parid,
            start_time = iNow,
            end_time = iEndTime,
            par_name = mData.par_name,
            par_grade = mData.par_grade,
            par_model = mData.par_model,
            par_star = mData.par_star,
            par_awake = mData.par_awake
            })
        oFrdTravel:GS2CFrdTravelPartnerInfo()
        oFrdTravel:SendFrdTravelInfo(oPlayer)
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSucc,
    })
end

function UpdateTravelPartner(mRecord, mData)
    local iPid = mData.pid
    local iPos = mData.pos
    local mData = mData.data or {}
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oTravel = oPlayer:GetTravel()
        oTravel:UpdateTravelPartner(iPos, mData)
    end
end

function AddHousePartner(mRecord, mData)
    local oHouseMgr = global.oHouseMgr
    local iPid = mData.pid
    local sReason = mData.reason
    oHouseMgr:RemoteAddHousePartner(iPid, mData.data, sReason)
end

function UpdateTerraWarsInfo(mRecord,mData)
    local iPid = mData.pid
    local iParid = mData.parid
    local mInfo = mData.data
    local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
    oHuodong:UpdateTerraWarsInfo(iPid,iParid,mInfo)
end

function UpdateParPowerRank(mRecord, mData)
    local list = mData["list"] or {}
    for _, m in ipairs(list) do
        local iPid = m.pid
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer.m_oPartnerCtrl:UpdatePowerRank(m)
        end
    end
end
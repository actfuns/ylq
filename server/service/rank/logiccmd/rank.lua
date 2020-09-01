--import module
local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local netproto = require "base.netproto"
local playersend = require "base.playersend"


ForwardNetcmds = {}

function ForwardNetcmds.C2GSGetRankInfo(iPid, mData)
    local idx = mData.idx
    local iPage = mData.page
    local iKey = mData.key
    local iSubType = mData.subtype or 0
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObj(idx)
    if oRankObj then
        local mNet = oRankObj:PackShowRankData(iPid, iPage, iKey, iSubType == 1)
        mNet.subtype = iSubType
        playersend.Send(iPid,"GS2CGetRankInfo",mNet)
    end
end

function ForwardNetcmds.C2GSGetOrgRankInfo(iPid,mData)
    local idx = mData.idx
    local iPage = mData.page
    local iOrgId = mData.orgid
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObj(idx)
    if oRankObj then
        local mNet = oRankObj:PackOrgShowRankData(iOrgId,iPid,iPage)
        if mNet then
            playersend.Send(iPid,"GS2CGetRankInfo",mNet)
        end
    end
end

function ForwardNetcmds.C2GSGetRankTop3(iPid, mData)
    local idx = mData.idx
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObj(idx)
    if oRankObj then
        local mNet = oRankObj:PackTop3RankData(iPid)
        playersend.Send(iPid,"GS2CGetRankTop3",mNet)
    end
end

function ForwardNetcmds.C2GSMyRank(iPid, mData)
    local oRankMgr = global.oRankMgr
    local idx = mData.idx
    local iOrgId = mData.orgid
    local iKey = (mData.key > 0 and mData.key) or iOrgId
    local iSubType = mData.subtype or 0
    local oRankObj = oRankMgr:GetRankObj(idx)
    if oRankObj then
        local mNet =oRankObj:GetMyRank(iPid,iKey, iSubType == 1, mData.rank_info)
        mNet.subtype = iSubType
        playersend.Send(iPid,"GS2CMyRank",mNet)
    else
        local mNet = {
            idx = idx,
            rank_count = 0,
            subtype = iSubType,
        }
        playersend.Send(iPid,"GS2CMyRank",mNet)
    end
end

function ForwardNetcmds.C2GSMyOrgRank(iPid,mData)
    local oRankMgr = global.oRankMgr
    local idx = mData.idx
    local iOrgId = mData.orgid
    local oRankObj = oRankMgr:GetRankObj(idx)
    local oRankUnit = oRankObj:GetOrgUnit(iOrgId)
    if oRankUnit then
        local mNet = oRankUnit:GetMyRank(iPid)
        playersend.Send(iPid,"GS2CMyRank",mNet)
    else
        local mNet = {
            idx = idx,
            rank_count = 0
        }
        playersend.Send(iPid,"GS2CMyRank",mNet)
    end
end

function ForwardNetcmds.C2GSRankUpvoteInfo(iPid, mData)
    local oRankMgr = global.oRankMgr
    local idx = mData.idx
    local iOrgId = mData.orgid
    local oRankObj = oRankMgr:GetRankObj(idx)
    if oRankObj then
        local mNet = oRankObj:PackUpvoteInfo(iPid, mData.page,iOrgId)
        playersend.Send(iPid,"GS2CRankUpvoteInfo",mNet)
    end
end

function ForwardNetcmds.C2GSGetRankParInfo(iPid, mData)
    local oRankMgr= global.oRankMgr
    local idx = mData.idx
    local key1 = mData.partype
    local key2 = mData.owner
    local oRankObj = oRankMgr:GetRankObj(idx)
    if oRankObj and oRankObj.GetRankParInfo then
        local mNet = oRankObj:GetRankParInfo(key1, key2)
        playersend.Send(iPid,"GS2CRankPartnerInfo",mNet)
    end
end

function ForwardNetcmds.C2GSGetRankMsattack(iPid, mData)
    local oRankMgr= global.oRankMgr
    local itype = mData.type
    local istart = mData.istart
    local iend = mData.iend
    local oRankObj = oRankMgr:GetRankObjByName("msattack")
    if oRankObj then
        oRankObj:GetMsAttackRankData(iPid,itype,istart,iend)
    end
end

function ForwardNetcmds.C2GSGetRankFirstInfo(iPid, mData)
    local idx = mData.idx
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObj(idx)
    if oRankObj then
        local mNet = oRankObj:PackRankFristList()
        playersend.Send(iPid,"GS2CRankFirstInfoList",mNet)
    end
end

function ForwardNetcmds.C2GSPartnerRank(iPid, mData)
    local iSubType = mData.subtype
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName("parpower")
    if oRankObj then
        local mNet = oRankObj:PackPartnerRankList(iPid, iSubType == 1)
        mNet.subtype = iSubType
        playersend.Send(iPid, "GS2CPartnerRank", mNet)
    else
        record.warning("parpower rankobj not exist!")
    end
end

function Forward(mRecord, mData)
    local oRankMgr = global.oRankMgr
    assert(oRankMgr, "there not exist rankmgr")

    local sCmd = mData.cmd
    local iPid = mData.pid
    local m = netproto.ProtobufFunc("default", sCmd, mData.data)
    local func = ForwardNetcmds[sCmd]
    if func then
        func(iPid, m)
    end
end

function PushDataToRank(mRecord, mData)
    mData = mData or {}
    local oRankMgr = global.oRankMgr
    local sRankName = mData.rank_name
    local mArgs = mData.arg or {}
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        oRankObj:PushDataToRank(mData.rank_data,mArgs)
    end
end

function NewOrg(mRecord,mData)
    local oRankMgr = global.oRankMgr
    local mRankName = mData.rank_name
    local iOrgId = mData.orgid
    for _,sRankName in pairs(mRankName) do
        local oRankObj = oRankMgr:GetRankObjByName(sRankName)
        if oRankObj then
            oRankObj:NewOrgUnit(iOrgId)
        end
    end
end

function NewOrgMem(mRecord,mData)
    local oRankMgr = global.oRankMgr
    local mRankName = mData.rank_name
    local iOrgId = mData.orgid
    local mRankInfo = mData.rankinfo
    local iPid = mRankInfo.pid
    for _,sRankName in pairs(mRankName) do
        local oRankObj = oRankMgr:GetRankObjByName(sRankName)
        if oRankObj then
            oRankObj:NewOrgMem(iOrgId,iPid,mRankInfo)
        end
    end
end

function NewHour(mRecord, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:NewHour(mData.weekday, mData.hour)
end

function OnUpdateName(mRecord, mData)
    local iPid = mData.pid
    local sName = mData.name
    local oRankMgr = global.oRankMgr
    oRankMgr:OnUpdateName(iPid, sName)
end

function OnUpdateOrgName(mRecord,mData)
    local iOrgId = mData.orgid
    local sName = mData.name
    local oRankMgr = global.oRankMgr
    oRankMgr:OnUpdateName(iOrgId, sName)
end

function OnUpdatePosition(mRecord, mData)
    local iPid = mData.pid
    local iPosition = mData.position
    local oRankMgr = global.oRankMgr
    oRankMgr:OnUpdatePosition(iPid,iPosition)
end

function DeleteOrg(mRecord,mData)
    local iOrgId = mData.orgid
    local oRankMgr = global.oRankMgr
    oRankMgr:DeleteOrg(iOrgId)
end

function OnUpdateOrgInfo(mRecord,mData)
    local iOrgId = mData.orgid
    local mInfo = mData.info
    local oRankMgr = global.oRankMgr
    oRankMgr:OnUpdateOrgInfo(iOrgId,mInfo)
end

function OnUpdatePartner(mRecord, mData)
    local iParType = mData.partype
    local iPid = mData.pid
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName("parpower")
    if oRankObj then
        if mData.name then
            oRankObj:OnUpdateParName(iParType, iPid, mData.name)
        end
        if mData.model_info then
            oRankObj:OnUpdateParModel(iParType, iPid, mData.model_info)
        end
    end
end

function OnLogin(mRecord, mData)
    local iPid = mData.pid
    local bReEnter = mData.reenter
    local oRankMgr = global.oRankMgr
    oRankMgr:OnLogin(iPid, bReEnter)
end

function OnLogout(mRecord, mData)
    local iPid = mData.pid
    local oRankMgr = global.oRankMgr
    oRankMgr:OnLogout(iPid)
end

function RequestRankShowData(mRecord, mData)
    local sRankName = mData.rank_name
    local iLimit = mData.rank_limit
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        local lResult = oRankObj:GetRankShowDataByLimit(iLimit)
        local mData = {data = lResult}
        interactive.Response(mRecord.source, mRecord.session, mData)
    else
        interactive.Response(mRecord.source, mRecord.session, {})
    end
end

function GetExtraRankData(mRecord,mData)
    local sRankName = mData.rank_name
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        local mResult = oRankObj:GetExtraRankData(mData.data)
        if mData.respond and mResult then
            interactive.Response(mRecord.source, mRecord.session, { success = true , data = mResult ,})
        end
    end
end

function CleanRankCache(mRecord,mData)
    local sRankName = mData.rank_name
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        oRankObj:CleanRankCache(mData.data)
    end
end

function GetRankInfo(mRecord, mData)
    local iKey = mData.key
    local sRankName = mData.rank_name
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        local mRankInfo = oRankObj:GetRankInfo(iKey)
        interactive.Response(mRecord.source, mRecord.session, {data = mRankInfo})
    else
        interactive.Response(mRecord.source, mRecord.session, {})
        record.warning(string.format("rank service: %s not exist !"), sRankName)
    end
end

function CleanAllData(mRecord,mData)
    local sRankName = mData.rank_name
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        oRankObj:CleanAllData(mData.data)
    end
end

function TestOP(mRecord,mData)
    local iPid = mData.pid
    local sRankName = mData.rank_name
    local iCmd = mData.cmd
    local mRankData = mData.test_data or {}
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        oRankObj:TestOP(iPid,iCmd,table.unpack(mRankData))
    end
end

function OnTerrPointUpdate(mRecord,mData)
    local iPid = mData.pid
    local mRankData = mData.rank_data
    local iPersonal_points = mRankData.personal_points
    local iOrgId = mRankData.orgid
    local sRankName = mData.rank_name
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        oRankObj:OnTerrPointUpdate(iOrgId,iPid,iPersonal_points)
    end
end

function OnTerrOrgPointUpdate(mRecord,mData)
    local iOrgId = mData.orgid
    local mRankData = mData.rank_data
    local sRankName = mData.rank_name
    local iOrgPoints = mRankData.org_points
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        oRankObj:OnTerrOrgPointUpdate(iOrgId,iOrgPoints)
    end
end

function LeaveOrg(mRecord,mData)
    local mRankName = mData.rank_name
    local iOrgId = mData.orgid
    local iPid = mData.pid
    for _,sName in pairs(mRankName) do
        local oRankObj = global.oRankMgr:GetRankObjByName(sName)
        if oRankObj then
            oRankObj:LeaveOrg(iOrgId,iPid)
        end
    end
end

function OnOrgLeaderChange(mRecord,mData)
    local iOrgId = mData.orgid
    local mLeader = mData.leader_info
    local mRankName = mData.rank_name
    local oRankMgr = global.oRankMgr
    for _,sName in pairs(mRankName) do
        oRankMgr:OnOrgLeaderChange(iOrgId, mLeader)
    end
end

function RewardTerraWars(mRecord,mData)
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName("terrawars_org")
    if oRankObj then
        oRankObj:SendReward()
    end
    oRankObj = oRankMgr:GetRankObjByName("terrawars_server")
    if oRankObj then
        oRankObj:SendReward()
    end
end

function fixterra_reward(mRecord,mData)
    local oRankObj = oRankMgr:GetRankObjByName("terrawars_server")
    if oRankObj then
        oRankObj:SendReward()
    end
end

function ResetTerrawars(mRecord,mData)
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName("terrawars_org")
    if oRankObj then
        oRankObj:ResetRankData()
    end
    oRankObj = oRankMgr:GetRankObjByName("terrawars_server")
    if oRankObj then
        oRankObj:ResetRankData()
    end
end

function SyncMSRanktoAll()
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName("msattack")
    if oRankObj then
        oRankObj:SyncAllPlayerInfo()
    end
end

function RushRankEnd(mRecord, mData)
    local oRankMgr = global.oRankMgr
    local idxs = mData["idxs"] or {}
    oRankMgr:RushRankEnd(idxs)
end

function GetMsattackRewardList(mRecord,mData)
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName("msattack")
    local mRet = {}
    if oRankObj then
        mRet = oRankObj:GetRewardNameList()
    end
    interactive.Response(mRecord.source, mRecord.session, {data = mRet})
end

function RemoveDataFromRank(mRecord, mData)
    mData = mData or {}
    local oRankMgr = global.oRankMgr
    local sRankName = mData.rank_name
    local oRankObj = oRankMgr:GetRankObjByName(sRankName)
    if oRankObj then
        local keys = mData.keys or {}
        oRankObj:RemoveDataFromRank(table.unpack(keys))
    end
end

function CheckRushRankEnd(mRecord, mData)
    mData = mData or {}
    local oRankMgr = global.oRankMgr
    oRankMgr:CheckRushRankEnd(mData.ranks)
end

function CheckTerraRank(mRecord,mData)
    local mOrgData = mData.data
    local oRankMgr = global.oRankMgr
    local oRankObj = oRankMgr:GetRankObjByName("terrawars_org")
    for iOrgId,mInfo in pairs(mOrgData) do
        local oRankUnit = oRankObj:GetOrgUnit(iOrgId)
        local mErrorData = {}
        if oRankUnit then
            for sKey,_ in pairs(oRankUnit.m_mRankData) do
                if not table_in_list(mInfo,tonumber(sKey)) then
                    table.insert(mErrorData,tonumber(sKey))
                end
            end

        end
        for _,iPid in pairs(mErrorData) do
            oRankUnit:RemoveDataFromRank({key = iPid})
        end
    end
end

function QueryRankBack(mRecord, mData)
    local oRankMgr = global.oRankMgr
    local idxs = mData["idxs"] or {}
    oRankMgr:QueryRankBack(idxs)
end
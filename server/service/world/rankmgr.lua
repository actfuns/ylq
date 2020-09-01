local global = require "global"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"
local extend = require "base.extend"

local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item/loaditem"))
local loadpartner = import(service_path("partner/loadpartner"))

local pt = extend.Table.print

function NewRankMgr(...)
    local o = CRankMgr:New(...)
    return o
end

CRankMgr = {}
CRankMgr.__index = CRankMgr
inherit(CRankMgr, logic_base_cls())

function CRankMgr:New()
    local o = super(CRankMgr).New(self)
    o.m_mShowRank = {}
    o.m_mShowData = {}
    o.m_mUnitData = {}
    o.m_mRankIdx = {}
    return o
end

function CRankMgr:PushDataToRank(sName, mData, mArgs)
    local mInfo = {}
    mInfo.rank_name = sName
    mInfo.rank_data = mData
    mInfo.arg = mArgs or {}
    interactive.Send(".rank", "rank", "PushDataToRank", mInfo)
end

function CRankMgr:PushDataToGradeRank(oPlayer)
    local mData = {}
    mData.pid = oPlayer:GetPid()
    mData.grade = oPlayer:GetGrade()
    mData.name = oPlayer:GetName()
    mData.school = oPlayer:GetSchool()
    mData.exp = oPlayer:GetExp()
    mData.shape = oPlayer:GetModelInfo().shape
    mData.time = get_time()
    self:PushDataToRank("grade", mData)
end

function CRankMgr:PushDataToMsAttackRank(oPlayer)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("msattack")
    local mData = {}
    local iPoint = oHuodong:GetPoint(oPlayer)
    if iPoint <= 0 then
        return
    end
    mData.pid = oPlayer:GetPid()
    mData.name = oPlayer:GetName()
    mData.shape = oPlayer:GetModelInfo().shape
    mData.school = oPlayer:GetSchool()
    mData.point = iPoint
    mData.time = get_time()
    mData.orgname = oPlayer:GetOrgName()
    self:PushDataToRank("msattack", mData)
end

function CRankMgr:PushDataToPataRank(oPlayer)
    local mData = {}
    mData.pid = oPlayer:GetPid()
    mData.name = oPlayer:GetName()
    mData.shape = oPlayer:GetModelInfo().shape
    mData.school = oPlayer:GetSchool()
    mData.level = oPlayer.m_oActiveCtrl:GetData("pt_maxlv",1) - 1
    mData.time = get_time()
    self:PushDataToRank("pata", mData)
end

function CRankMgr:PushDataToWarPowerRank(oPlayer)
    local mData = {}
    mData.pid = oPlayer:GetPid()
    mData.grade = oPlayer:GetGrade()
    mData.name = oPlayer:GetName()
    mData.school = oPlayer:GetSchool()
    mData.power = oPlayer:GetWarPower()
    mData.shape = oPlayer:GetModelInfo().shape
    mData.time = get_time()
    self:PushDataToRank("warpower", mData)
    oPlayer:SyncTosOrg({power=true})
end

function CRankMgr:PushDataToConsumeRank(oProfile)
    local mData = {}
    mData.pid = oProfile:GetPid()
    mData.name = oProfile:GetName()
    mData.shape = oProfile:GetShape()
    mData.school = oProfile:GetSchool()
    mData.consume = oProfile:SumGoldCoinConsume()
    mData.time = get_time()
    self:PushDataToRank("consume", mData)
end

function CRankMgr:SetUpvoteShowRank(sRankName, mShowRank)
    self.m_mShowRank[sRankName] = mShowRank
end

function CRankMgr:SetRankSimpleData(iRankIdx, lShowData)
    self.m_mShowData[iRankIdx] = lShowData
    self:SetRankUnitData(iRankIdx, lShowData)
end

function CRankMgr:SetRankUnitData(iRankIdx,lShowData)
    self.m_mUnitData[iRankIdx] = {}
    for iPage,info in pairs(lShowData) do
        for _,info2 in pairs(info) do
            if info2.pid then
                self.m_mUnitData[iRankIdx][info2.pid] = info2
            end
        end
    end
end

function CRankMgr:GetRankIdxByName(sRankName)
    if not self.m_mRankIdx[sRankName] then
        for id, mInfo in pairs(res["daobiao"]["rank"]) do
            self.m_mRankIdx[mInfo.file] = id
        end
    end
    return self.m_mRankIdx[sRankName]
end

function CRankMgr:GetRankUnitData(sRankName,iPid)
    local iRankIdx = self:GetRankIdxByName(sRankName)
    if iRankIdx and self.m_mUnitData[iRankIdx] then
        return self.m_mUnitData[iRankIdx][iPid]
    end
end

function CRankMgr:SendRankReward(sRankName, lRankData,iMailId)
    local mRwdData = self:GetRankRewardData(sRankName)
    if not mRwdData then
        return
    end
    for _, mData in ipairs(lRankData) do
        local iRank = mData.rank
        local iPid = mData.pid
        local iReward = mRwdData[iRank]
        if iReward then
            self:SendReward(iPid, iReward,iMailId,{rank = iRank})
        end
    end
end

function CRankMgr:SendTerraServReward(sRankName,lRankData)
    local mRwdData = self:GetRankRewardData(sRankName)
    if not mRwdData then
        return
    end
    local oOrgMgr = global.oOrgMgr
    local mOrg = {}
    for _, mData in ipairs(lRankData) do
        local iRank = mData.rank
        local iOrgId = mData.orgid
        if mRwdData[iRank] then
            local mOrgReward = mRwdData[iRank]["org_reward"]
            local iMemReward = mRwdData[iRank]["mem_reward"]
            local iOrgCash = 0
            local iOrgprestige = 0
            for _,info in pairs(mOrgReward) do
                local iRewardType,iAmount = info.type,info.amount
                if iRewardType == 1015 then
                    oOrgMgr:RewardOrgCash(iOrgId,iAmount,"据点战奖励")
                    iOrgCash = iOrgCash + iAmount
                elseif iRewardType == 1026 then
                    oOrgMgr:AddPrestige(iOrgId,iAmount,"据点战奖励")
                    iOrgprestige = iOrgprestige + iAmount
                end
            end
            table.insert(mOrg,{orgid=iOrgId,rank=iRank,reward = iMemReward,orgcash=iOrgCash,orgprestige = iOrgprestige})
        end
    end
    local fFunc = function(mData)
        global.oRankMgr:SendOrgMemReward(mData,"terrawars")
    end
    oOrgMgr:GetOrgMemList(mOrg,fFunc)
end

function CRankMgr:SendOrgMemReward(mData,sType)
    for _,info in pairs(mData) do
        if info.memlist then
            local iMemReward = info.reward
            local iRank = info.rank
            for _,pid in pairs(info.memlist) do
                if iRank == 1 and sType == "terrawars" then
                    local oTitleMgr = global.oTitleMgr
                    oTitleMgr:AddTitle(pid, 1012)
                    if global.oOrgMgr:GetPlayerOrgInfo(pid,"orgpos",0) == 1 then
                        oTitleMgr:AddTitle(pid, 1013)
                    end
                end
                self:SendReward(pid,iMemReward,36,info)
            end
        end
    end
end

function CRankMgr:SendReward(iPid, iReward,iMailId,mArgs)
    local mReward = self:GetRewardData(iReward)
    local iRwdCoin = tonumber(mReward.coin)
    local lItemReward = mReward.item
    local lItem = {}
    if #lItemReward > 0 then
        for _,info in pairs(lItemReward) do
            local iItemReward = info.idx
            local mItemReward = self:GetItemRewardData(iItemReward)
            for _, lData in pairs(mItemReward) do
                for _, m in ipairs(lData) do
                    local oItem = loaditem.ExtCreate(m.sid)
                    table.insert(lItem, oItem)
                end
            end
        end
    end
    local oMailMgr = global.oMailMgr
    local mData, sName = oMailMgr:GetMailInfo(iMailId or 1)
    if mArgs then
        mData = self:TranMailString(mData,mArgs)
    end
    oMailMgr:SendMail(0, sName, iPid, mData,{{sid = gamedefines.COIN_FLAG.COIN_COIN,value=iRwdCoin}} , lItem)
end

function CRankMgr:TranMailString(mMailInfo,mArgs)
    if not mArgs then
        return
    end
    if string.find(mMailInfo.context,"$rank") then
        mMailInfo.context = string.gsub(mMailInfo.context,"$rank",mArgs.rank or "")
    end
    if string.find(mMailInfo.context,"$orgcash") then
        mMailInfo.context = string.gsub(mMailInfo.context,"$orgcash",mArgs.orgcash or "")
    end
    if string.find(mMailInfo.context,"$orgprestige") then
        mMailInfo.context = string.gsub(mMailInfo.context,"$orgprestige",mArgs.orgprestige or "")
    end
    return mMailInfo
end

function CRankMgr:GetRankRewardData(sRankName)
    return res["daobiao"]["rank_reward"][sRankName]
end

function CRankMgr:GetRewardData(iReward)
    local mData = res["daobiao"]["reward"]["rank"]["reward"][iReward]
    assert(mData,string.format("CRankMgr:GetRewardData err: rank %s", iReward))
    return mData
end

function CRankMgr:GetItemRewardData(iItemReward)
    local mData = res["daobiao"]["reward"]["rank"]["itemreward"][iItemReward]
    assert(mData,string.format("CRankMgr:GetItemRewardData err:rank %s", iItemReward))
    return mData
end

function CRankMgr:RequestRankShowData(sRankName, iLimit, fCallback)
    local mData = {rank_name = sRankName, rank_limit = iLimit}
    interactive.Request(".rank", "rank", "RequestRankShowData", mData,
    function(mRecord, mData)
        fCallback(mData.data)
    end)
end

function CRankMgr:GetUpvoteShowRank(iPid)
    local mInfo = self.m_mShowRank["upvote"] or {}
    return mInfo[iPid]
end

function CRankMgr:GetRankInfo(iKey, sRankName, fCallback)
    local mData = { rank_name = sRankName, key = iKey}
    interactive.Request(".rank", "rank","GetRankInfo", mData,
        function (mRecord, mData)
            fCallback(mData.data)
        end)
end

function CRankMgr:OnUpdateName(iPid,sName)
    local mData = {
        pid = iPid,
        name = sName,
    }
    interactive.Send(".rank", "rank", "OnUpdateName", mData)
end

function CRankMgr:OnUpdatePosition(iPid,iPosition)
    local mData = {
        position = iPosition,
        pid = iPid,
    }
    interactive.Send(".rank", "rank", "OnUpdatePosition", mData)
end

function CRankMgr:DeleteOrg(iOrgId)
    local mData = {
        orgid = iOrgId,
    }
    interactive.Send(".rank", "rank", "DeleteOrg", mData)
end

function CRankMgr:NewHour(iWeekDay,iHour)
    local mData = {
        weekday = iWeekDay,
        hour = iHour,
    }
    interactive.Send(".rank", "rank", "NewHour", mData)
end

function CRankMgr:OnLogin(oPlayer, bReEnter)
    local mData = {
        pid = oPlayer:GetPid(),
        reenter = bReEnter,
    }
    interactive.Send(".rank", "rank", "OnLogin", mData)
end

function CRankMgr:OnLogout(oPlayer)
    local mData = {
        pid = oPlayer:GetPid(),
    }
    interactive.Send(".rank", "rank", "OnLogout", mData)
end

function CRankMgr:OnDisconnected()
    -- body
end

function CRankMgr:SendRankUpvoteInfo(iPid, iRankIdx, iPage)
    local oWorldMgr = global.oWorldMgr
    local lShowData = self.m_mShowData[iRankIdx] or {}
    local lPageData = lShowData[iPage] or {}
    local mHandle = {
        count = #lPageData,
        rank_idx = iRankIdx,
        page = iPage,
        list = {},
        is_sent = false,
    }

    local func  = function (o)
        if not o then
            mHandle.count = mHandle.count - 1
            self:JudgeSendRankUpvoteInfo(mHandle, iPid)
        else
            self:PackRankUpvoteInfo(o, mHandle, iPid)
        end
    end
    for _, mData in ipairs(lPageData) do
        local o = oWorldMgr:GetOnlinePlayerByPid(mData.pid)
        if o then
            self:PackRankUpvoteInfo(o, mHandle, iPid)
        else
            oWorldMgr:LoadProfile(mData.pid, func)
        end
    end
end

function CRankMgr:PackRankUpvoteInfo(o, mHandle, iPid)
    mHandle.count = mHandle.count - 1
    local mData  = {
        key = o:GetPid(),
        count = o:GetUpvoteAmount(),
        status = (o:IsUpvote(iPid) and 1) or 0,
    }
    table.insert(mHandle.list, mData)
    self:JudgeSendRankUpvoteInfo(mHandle, iPid)
end

function CRankMgr:JudgeSendRankUpvoteInfo(mHandle, iPid)
    if mHandle.count <= 0 and not mHandle.is_sent then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send("GS2CRankUpvoteInfo", {
                idx = mHandle.rank_idx,
                page = mHandle.page,
                upvote_info = mHandle.list,
                })
        end
        mHandle.is_sent = true
    end
end

function CRankMgr:RefreshOnlineWarPowerRankData()
    local oWorldMgr = global.oWorldMgr
    local mOnline = oWorldMgr:GetOnlinePlayerList()
    for iPid, oPlayer in pairs(mOnline) do
        -- oPlayer.m_oPartnerCtrl:ResortTop4Power()
        -- self:PushDataToWarPowerRank(oPlayer)
    end
end

function CRankMgr:SendRushRankReward(mRank)
    for idx, mData in pairs(mRank) do
        if idx == 113 then
            self:DoOrgPrestigeRushRank(idx, mData)
        elseif idx == 115 then
            self:DoParPowerRushRank(idx, mData)
        elseif table_in_list({105,106, 117}, idx) then
            self:DoCommonRushRank(idx, mData)
        else
            record.warning("SendRushRankReward, idx:%s", idx)
        end
    end
end

function CRankMgr:DoOrgPrestigeRushRank(idx, mData)
    local oOrgMgr = global.oOrgMgr
    local lOrgId = {}
    for iRank, mUnit in pairs(mData) do
        table.insert(lOrgId, {orgid = mUnit.orgid})
    end
    local sFunc = function(mOgrInfo)
        local oRankMgr =global.oRankMgr
        oRankMgr:_DoOrgPrestigeRushRank(idx, mData, mOgrInfo)
    end
    oOrgMgr:GetOrgMemList(lOrgId, sFunc)
end

function CRankMgr:_DoOrgPrestigeRushRank(idx, mData, OgrInfos)
    local mOgrInfo = {}
    for _, mInfo in ipairs(OgrInfos) do
        mOgrInfo[mInfo.orgid] = mInfo
    end
    OgrInfos = nil
    for _, mUnit in pairs(mData) do
        local iOrgId = mUnit.orgid
        local mInfo = mOgrInfo[iOrgId]
        local mConf = self:GetRushRankData(idx, 0, mUnit.rank)
        if mInfo and mConf then
            local lMember = mInfo.memlist or {}
            for _, iPid in ipairs(lMember) do
                self:_TrueRushRankReward1(idx, iPid, mConf)
            end
            local iOrgCash = mConf.org_cash
            if iOrgCash > 0 then
                local oOrgMgr = global.oOrgMgr
                oOrgMgr:RewardOrgCash(iOrgId,iOrgCash,"公会冲榜")
            end
        end
    end
end

function CRankMgr:DoParPowerRushRank(idx, mData)
    mData = mData or {}
    for iKey, mRank in pairs(mData) do
        for _, mUnit in pairs(mRank) do
            local mConf = self:GetRushRankData(idx,iKey,mUnit.rank)
            if mConf then
                self:_TrueRushRankReward1(idx, mUnit.pid, mConf, iKey)
            end
        end
    end
end

function CRankMgr:DoCommonRushRank(idx, mData)
    for _, mUnit in pairs(mData) do
        local mConf = self:GetRushRankData(idx,0, mUnit.rank)
        if mConf then
            self:_TrueRushRankReward1(idx, mUnit.pid, mConf)
        end
    end
end

function CRankMgr:_TrueRushRankReward1(idx, iPid, mRush, iKey)
    local oOrgMgr = global.oOrgMgr
    local oTitleMgr = global.oTitleMgr
    local iTitle = 0
    if mRush["org_leader_title"] > 0 and oOrgMgr:IsOrgLeader(iPid) then
        iTitle = mRush["org_leader_title"]
        oTitleMgr:AddTitle(iPid, mRush["org_leader_title"])
    elseif mRush["title"] > 0 then
        iTitle = mRush["org_leader_title"]
        oTitleMgr:AddTitle(iPid, mRush["title"])
    end
    local lItem = {}
    for _, m in ipairs(mRush["reward"] or {}) do
        local oItem = loaditem.ExtCreate(m.sid)
        oItem:SetAmount(m.amount or 1)
        table.insert(lItem, oItem)
    end
    local mLeaderRwd = mRush["org_leader_reward"] or {}
    if next(mLeaderRwd) and oOrgMgr:IsOrgLeader(iPid) then
        for _, m in ipairs(mLeaderRwd) do
            local oItem = loaditem.ExtCreate(m.sid)
            oItem:SetAmount(m.amount or 1)
            table.insert(lItem, oItem)
        end
    end
    if next(lItem) then
        local res = require "base.res"
        local mConf = res["daobiao"]["rushconfig"][idx] or {}
        if mConf.mail then
            local mArgs = self:GetRushRankMailArgs(idx, mRush, iKey)
            self:SendRankMail(mConf.mail, iPid, {}, lItem, mArgs)
        end
    end
    --idx|排行榜id,sub_key|子类,target|目标id,title|称谓,reward|奖励信息
    record.user("rank", "rushrank_reward", {
        idx = idx,
        target = iPid,
        title = iTitle,
        sub_key = iKey or 0,
        rank = mRush.rank,
        reward = ConvertTblToStr(mRush["reward"] or {}),
        })
end

function CRankMgr:GetRushRankMailArgs(idx, mRush, iKey)
    local mArgs ={mRush.rank}
    if idx == 115 then
        local mData = loadpartner.GetPartnerData(tonumber(iKey))
        mArgs = {}
        if mData then
            mArgs = {mData,name, mRush.rank}
        end
    end
    return mArgs
end

function CRankMgr:SendRankMail(iMailId, iPid,mMoney,lItem, mArgs)
    local oMailMgr = global.oMailMgr
    local mData, sName = oMailMgr:GetMailInfo(iMailId or 1)
    mData.context = string.format(mData.context, table.unpack(mArgs))
    oMailMgr:SendMail(0, sName, iPid, mData,{} , lItem)
end

function CRankMgr:GetRushRankData(idx, iKey, iRank)
    iKey = iKey or 0
    local res = require "base.res"
    local mData = res["daobiao"]["rushrank"][idx]
    return mData and mData[iKey] and mData[iKey][iRank]
end

function CRankMgr:DoRushRankReward(Idxs)
    Idxs = Idxs or {}
    if next(Idxs) then
        interactive.Send(".rank", "rank", "RushRankEnd", {idxs = Idxs})
    end
end

function CRankMgr:OpenRankUI(oPlayer, mData)
    mData = mData or {}
    local lQuery = mData["query"] or {}
    local m = {
        idx = mData["idx"],
        page = mData["page"],
        key = mData["key"],
        subtype = mData["subtype"],
    }
    local iLen = #lQuery
    if iLen <=0 or iLen > 3 then
        return
    end
    local QUERY = {
        rank_info = "C2GSGetRankInfo",
        my_rank = "C2GSMyRank",
        upvote_info = "C2GSRankUpvoteInfo",
    }
    for _, sQuery in ipairs(lQuery) do
        local sFunc = QUERY[sQuery]
        local f = self[sFunc]
        if f then
            f(self, oPlayer, m)
        end
    end
end

function CRankMgr:C2GSGetRankInfo(oPlayer,mData)
    self:Forward(oPlayer, "C2GSGetRankInfo", mData)
end

function CRankMgr:C2GSMyRank(oPlayer, mData)
    mData.orgid = oPlayer:GetOrgID()
    mData.rank_info = self:GetMyRankInfo(oPlayer, mData)
    self:Forward(oPlayer, "C2GSMyRank", mData)
end

function CRankMgr:GetMyRankInfo(oPlayer, mData)
    local mInfo = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
    }
    if mData.idx == 102 then
        --worldboss
    elseif mData.idx == 103 then
        --wapower
        mInfo.warpower = oPlayer:GetWarPower()
    elseif mData.idx == 105 then
        --pata
    elseif mData.idx == 106 then
        --arenagame
    elseif mData.idx == 109 then
        --equalarena
    elseif mData.idx == 110 then
        --yjfuben
    elseif mData.idx == 111 then
        --terrawars_org
    elseif mData.idx == 112 then
        --terrawars_server
    elseif mData.idx == 113 then
        --orgprestige
    elseif mData.idx == 114 then
        --teampvp
    elseif mData.idx == 115 then
        --parpower
        mInfo.partner = oPlayer.m_oPartnerCtrl:GetRankInfo(mData.key)
    elseif mData.idx == 116 then
        --msattack
    elseif mData.idx == 117 then
        --consume
        mInfo.consume = oPlayer:GetProfile():SumGoldCoinConsume()
    end
    return mInfo
end

function CRankMgr:C2GSRankUpvoteInfo(oPlayer, mData)
    mData = mData or {}
    local iRankIdx = mData["idx"]
    local iPage = mData["page"]
    self:SendRankUpvoteInfo(oPlayer:GetPid(), iRankIdx, iPage)
end

function CRankMgr:Forward(oPlayer, sProtocol, mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if oWorldMgr:IsClose("rank") then
        oNotifyMgr:Notify(oPlayer:GetPid(), "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return
    end
    local mInfo = {}
    mInfo.cmd = sProtocol
    mInfo.data = mData
    mInfo.pid = oPlayer:GetPid()
    interactive.Send(".rank", "rank", "Forward", mInfo)
end

function CRankMgr:MergeFinish()
    interactive.Send(".rank", "merger", "MergeFinish", {})
end

function CRankMgr:SendRankBack(lRankData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("rankback")
    if oHuodong then
        oHuodong:DoRankBack(lRankData)
    end
end

function CRankMgr:TestOP(oPlayer,sRankName,iCmd,...)
    if iCmd == 1001 then
        if sRankName == "warpower" then
            self:RefreshOnlineWarPowerRankData()
        end
    elseif iCmd == 1002 then
        self:GetRankInfo(oPlayer:GetPid(), sRankName, function(mData)
            table_print(mData)
        end)
    else
        local mRankData = {...}
        local mData = {
            pid = oPlayer:GetPid(),
            rank_name = sRankName,
            cmd = iCmd,
            test_data = mRankData,
        }
        interactive.Send(".rank","rank","TestOP",mData)
    end
end
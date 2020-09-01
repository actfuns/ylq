--import module
local global  = require "global"
local res = require "base.res"
local record = require "public.record"
local extend = require "base.extend"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local partnerdefine = import(service_path("partner.partnerdefine"))

SPECIAL_CHIP = {
    WHITE = 20007,
    BLACK = 20009,
}

SPECIAL_MONSTER = {
    WHITE = 11753,
    BLACK = 11755,
}


function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_mInfo = {}
    o.m_iMaxRing = gamedefines.ENDLESS_PVE_MAX_RING
    return o
end

function CHuodong:Init()
    self:TryStartRewardMonitor()
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
    end
end

function CHuodong:OnLogin(oPlayer, bReEnter)
    if bReEnter then
        self:ReEnterWar(oPlayer)
    end
end

function CHuodong:ReEnterWar(oPlayer)
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if not oNowWar then
        return
    end
    local iPid = oPlayer:GetPid()
    if oNowWar.m_iWarType == gamedefines.WAR_TYPE.ENDLESS_PVE_TYPE then
        local iRing = oNowWar:GetData("ring", 1)
        self:GS2CWarRingInfo({iPid}, {
            ring = iRing,
            end_time = oNowWar:GetData("end_time"),
            })
    end
end

function CHuodong:NewInfo(iPid)
    local oInfo = CEndlessInfo:New(iPid)
    self.m_mInfo[iPid] = oInfo
    return oInfo
end

function CHuodong:RemoveInfo(iPid)
    local oInfo = self.m_mInfo[iPid]
    if oInfo then
        baseobj_safe_release(oInfo)
        self.m_mInfo[iPid] = nil
    end
end

function CHuodong:GetInfoObj(iPid)
    return self.m_mInfo[iPid]
end

function CHuodong:GetCreateWarArg(mArg)
    local mArg2 = table_copy(mArg)
    mArg2.remote_war_type = "serialwar"
    mArg2.war_type = gamedefines.WAR_TYPE.ENDLESS_PVE_TYPE
    return mArg2
end

--发送给战斗服务的信息
function CHuodong:GetRemoteWarArg()
    local mArgs = {
        keep_time = self:GetEndlessPVETime(),
    }
    return mArgs
end

function CHuodong:GetEndlessPVEData(iRing, iMode)
    local mData = res["daobiao"]["endless_pve"]["endless_pve_info"][iRing][iMode]
    assert(mData, string.format("endless pve data err: %s", iRing))
    return mData
end

function CHuodong:GetEndlessPVETime()
    local res = require "base.res"
    local sSec = res["daobiao"]["global"]["endlesspve_time"]["value"]
    return tonumber(sSec) or (5 * 60)
end


function CHuodong:GetMonsterGrade(iRing, iMode)
    local res = require "base.res"
    local mData = res["daobiao"]["endless_pve"]["endless_pve_info"][iRing][iMode]
    return mData.monster_grade
end

function CHuodong:GetRewardId(iRing, iMode)
    local res = require "base.res"
    local mData = res["daobiao"]["endless_pve"]["endless_pve_info"][iRing][iMode]
    return mData.reward
end

function CHuodong:HasFightList(oPlayer)
    local m  = oPlayer.m_oActiveCtrl:GetEndlessPVEInfo()
    if next(m) then
        return true
    end
    return false
end

function CHuodong:RefreshFightList(oPlayer)
    local mFight = {}
    local res = require "base.res"
    local mMode = res["daobiao"]["endless_pve"]["mode_info"]
    for iMode, m in pairs(mMode) do
        local lFight = m.fight_pool
        mFight[iMode] = lFight[math.random(#lFight)]
    end
    self:SetFightList(oPlayer, mFight)
end

function CHuodong:SetFightList(oPlayer, mFightInfo)
    oPlayer.m_oActiveCtrl:SetEndlessPVEInfo(mFightInfo)
end

function CHuodong:ConfigWar(oWar, iPid, oNpc, iFight)
    oWar:SetData("current_figth", iFight)
    oWar:SetData("pid", iPid)
end

function CHuodong:GetAnotherTeamMem(oPlayer)
    local iPid = oPlayer:GetPid()
    if oPlayer:IsSingle() then
        return
    end
    local oTeam = oPlayer:HasTeam()
    local lMems = oTeam:GetTeamMember()
    for _, iMem in ipairs(lMems) do
        if iMem ~= iPid then
            local oMem = oTeam:GetMember(iMem)
            if oMem:Status() == gamedefines.TEAM_MEMBER_STATUS.MEMBER then
                return oMem
            end
        end
    end
end

function CHuodong:MaxJoinAmount()
    local mGlobal = res["daobiao"]["global"]["max_endless_pve"]
    return tonumber(mGlobal.value)
end

function CHuodong:CostItemSid()
    local mGlobal = res["daobiao"]["global"]["endless_pve_cost_item"]
    return tonumber(mGlobal.value)
end

function CHuodong:IsClose(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if oWorldMgr:IsClose("endless_pve") then
        oNotifyMgr:Notify(iPid, "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return true
    end

    return false
end

function CHuodong:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("endless_pve", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CHuodong:ValidTeamInfo(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    if oPlayer:IsSingle() then
        return true
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return true
    end
    local iPid = oPlayer:GetPid()
    if not oPlayer:IsTeamLeader() then
        oNotifyMgr:Notify(iPid, "请先退出队伍")
        return false
    end
    if oTeam:TeamSize() > 2 then
        oNotifyMgr:Notify(iPid, "月见幻境需要进入人数2人以下")
        return false
    end
    local oMem = self:GetAnotherTeamMem(oPlayer)
    if not oMem then
        return true
    end
    local oWorldMgr = global.oWorldMgr
    local iMem = oMem:MemberID()
    local oMemPlayer = oWorldMgr:GetOnlinePlayerByPid(iMem)
    local sMemName = oMemPlayer:GetName()
    if not self:IsOpenGrade(oMemPlayer) then
        oNotifyMgr:Notify(iPid, string.format("玩家名%s未达开启等级", sMemName))
        return false
    end
    local iMaxAmount = self:MaxJoinAmount()
    local oTime = oMemPlayer.m_oTimeCtrl:GetTimeObj("Today")
    local iDaily = oTime:Query("endless_pve", 0)
    if iDaily >= iMaxAmount then
        oNotifyMgr:Notify(iPid, string.format("玩家名%s已达到本日进入次数上限，无法开启", sMemName))
        return false
    end
    if oMemPlayer:GetNowWar() then
        oNotifyMgr:Notify(iPid, string.format("玩家名%s正在战斗,请等待战斗结束", sMemName))
        return false
    end
    return true
end

function CHuodong:ValidStartEndless(oPlayer,iMode)
    if self:IsClose(oPlayer) then
        return false
    end
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if oPlayer:GetNowWar() then
        oNotifyMgr:Notify(iPid, "正在战斗,请等待战斗结束")
        return false
    end
    if not self:ValidTeamInfo(oPlayer) then
        return false
    end
    local mFight = oPlayer.m_oActiveCtrl:GetEndlessPVEInfo()
    if not next(mFight) then
        return false
    end
    local iFight = mFight[iMode]
    if not iFight then
        return false
    end
    return true
end

function CHuodong:StartEndlessPVE(oPlayer, iMode)
    if not self:ValidStartEndless(oPlayer, iMode) then
        return
    end
    self:OnStartEndlessPVE(oPlayer, iMode)
end

function CHuodong:OnStartEndlessPVE(oPlayer, iMode)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    local iCostItem = self:CostItemSid()
    local fCallback = function (mRecord,mData)
        self:_OnStartEndlessPVE(iPid,iMode,mData)
    end
    local mArgs = {}
    oPlayer:RemoveItemAmount(iCostItem, 1, "好友召唤",mArgs,fCallback)
end

function CHuodong:_OnStartEndlessPVE(iPid,iMode,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local bSuccess = mData.success
    if not bSuccess then
        oNotifyMgr:Notify(iPid,"请稍后再试")
        return
    end
    if oPlayer:GetNowWar() then
        return
    end
    if not self:ValidStartEndless(oPlayer, iMode) then
        return
    end
    self:TrueStartEndlessPVE(oPlayer,iMode)
    local oMem = self:GetAnotherTeamMem(oPlayer)
    if oMem then
        local oWorldMgr = global.oWorldMgr
        local oMemPlayer = oWorldMgr:GetOnlinePlayerByPid(oMem:MemberID())
        local oTime = oMemPlayer.m_oTimeCtrl:GetTimeObj("Today")
        oTime:Add("endless_pve", 1)
    end
    self:SetFightList(oPlayer, {})
end

function CHuodong:TrueStartEndlessPVE(oPlayer, iMode)
    local iPid = oPlayer:GetPid()
    local iRing = 1
    local iEndTime = get_time() + self:GetEndlessPVETime()
    local mFight = oPlayer.m_oActiveCtrl:GetEndlessPVEInfo()
    local iFight = mFight[iMode]
    local oWar = self:CreateSerialWar(iPid, nil, iFight)
    oWar:SetData("end_time", iEndTime)

    oWar:SetData("ring", iRing)
    oWar:SetData("mode", iMode)
    self:RemoveInfo(iPid)
    local lPlayer = table_key_list(oWar.m_mPlayers)
    self:GS2CWarRingInfo(lPlayer, {
        ring = iRing,
        end_time = iEndTime,
        })
    -- record.user("endlesspve", "endless_start", {
    --     pid = oPlayer:GetPid(),
    --     name = oPlayer:GetName(),
    --     grade = oPlayer:GetGrade(),
    --     chip_sid = 0,
    --     fight_id = iFight,
    --     })
end

function CHuodong:EscapeCallBack(oWar,iPid,oNpc,mArgs)
    mArgs = mArgs or {}
    local iEscapePid = mArgs.pid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iEscapePid)
    if not oPlayer then
        return
    end
    local iRing = oWar:GetData("ring") - 1
    local iMode = oWar:GetData("mode")
    local lPlayer = {iEscapePid}
    mArgs["win_side"] = 1
    mArgs["win_list"] = lPlayer
    mArgs["fail_list"] = {}
    mArgs["ring"] = iRing
    local iAmount = 0
    if iRing > 0 then
        self:RewardWinners(lPlayer, iEscapePid, iRing, iMode,mArgs)
        -- record.user("endlesspve", "endless_end", {
        --     pid = oPlayer:GetPid(),
        --     name = oPlayer:GetName(),
        --     grade = oPlayer:GetGrade(),
        --     ring = iRing,
        --     reward = iReward,
        --     reward_chip = ConvertTblToStr(lRewardChip),
        --     })
        self:LogAnalyGame("endlesspve",oPlayer)
    end
    self:GS2CEndlessWarEnd(lPlayer,oWar, mArgs)
    self:PopWarRewardUI(oWar:GetWarId(), mArgs)
    self:ClearKeep(iEscapePid)
    self:PushAchieve(iEscapePid, iRing)
    if iRing > 0 then
        oPlayer:AddSchedule("endlesspve")
        global.oHandBookMgr:CheckCondition("endlesspve", iEscapePid, mArgs)
    end
end

function CHuodong:SerialWarCallback(oWar, iPid, oNpc, mArgs)
    local oWorldMgr = global.oWorldMgr

    local iRing = oWar:GetData("ring", 1)
    iRing = iRing + 1
    oWar:SetData("ring", iRing)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer or iRing > self.m_iMaxRing then
        oWar:TestCmd("warend", iPid, {war_result = 1})
        return
    end
    local iMonsterGrade = self:GetMonsterGrade(iRing, oWar:GetData("mode"))
    local mArgs = {
        monster_lv = iMonsterGrade,
    }
    local iFight = oWar:GetData("current_figth")
    local mFightData = self:GetTollGateData(iFight)
    local mMonsterData = mFightData["monster"] or {}
    local mEnemy = {}
    for _, mData in pairs(mMonsterData) do
        local iMonsterIdx = mData["monsterid"]
        local iCnt = mData["count"]
        for i=1,iCnt do
            local oMonster = self:CreateMonster(oWar,iMonsterIdx,npcobj, mArgs)
            table.insert(mEnemy, oMonster:PackAttr())
        end
    end
    local mRemoteMonster = {
        [2] = mEnemy,
    }
    oWar:RemoteSerialWar(mRemoteMonster)
    local lPlayer = table_key_list(oWar.m_mPlayers)
    self:GS2CWarRingInfo(lPlayer, {
        ring = oWar:GetData("ring",1),
        end_time = oWar:GetData("end_time"),
        })
end

function CHuodong:WarFightEnd(oWar, iPid, oNpc, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local lPlayer = mArgs.win_list or {}
    local iRing = oWar:GetData("ring", 1)
    iRing = math.min(iRing, 15)
    iRing = iRing - 1
    local iMode = oWar:GetData("mode")
    if iRing > 0 then
        self:RewardWinners(lPlayer, iPid, iRing, iMode,mArgs)
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30015,1)
        global.oHandBookMgr:CheckCondition("endlesspve", iPid, mArgs)
        self:LogAnalyGame("endlesspve",oPlayer)
    end
    self:GS2CEndlessWarEnd(lPlayer,oWar, mArgs)
    self:PopWarRewardUI(oWar:GetWarId(), mArgs)
    for _,iWinner in ipairs(lPlayer) do
        local oWinner = global.oWorldMgr:GetOnlinePlayerByPid(iWinner)
        if oWinner then
            oWinner:AddSchedule("endlesspve")
        end
        self:ClearKeep(iWinner)
        self:PushAchieve(iWinner, iRing)
    end
end

function CHuodong:RewardWinners(lWinner, iPid, iRing, iMode,mArgs)
    if iRing <= 0 then
        return
    end
    mArgs = mArgs or {}
    mArgs.cancel_tip = 1
    for i=1,iRing do
        local iReward = self:GetRewardId(i, iMode)
        for _, iWinner in ipairs(lWinner) do
            mArgs.cancel_exp = 1
            if iWinner == iPid then
                mArgs.cancel_exp = nil
            end
            self:Reward(iWinner, iReward, mArgs)
        end
    end
end

function CHuodong:PushAchieve(iPid, iRing)
    iRing = math.min(iRing, 9)
    for i = 1, iRing do
        local sKey = string.format("通过月见击败第%d波怪物", i)
        global.oAchieveMgr:PushAchieve(iPid, sKey, {value=1})
    end
end

function CHuodong:OnWarEnd(oWar,iPid,oNpc,mArgs,bWin)
end

function CHuodong:GS2CEndlessFightList(oPlayer)
    if not self:HasFightList(oPlayer) then
        self:RefreshFightList(oPlayer)
    end
    local mFight = oPlayer.m_oActiveCtrl:GetEndlessPVEInfo()
    local lNet = {}
    for iMode, iFight in pairs(mFight) do
        local mFightData = self:GetTollGateData(iFight)
        if mFightData then
            table.insert(lNet, {mode = iMode, shape = mFightData.shape})
        end
    end
    oPlayer:Send("GS2CEndlessFightList", {fight_list = lNet})
end

function CHuodong:GS2CWarRingInfo(lPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    for _,iPid in ipairs(lPlayer) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send("GS2CWarRingInfo", mData)
        end
    end
end

function CHuodong:GS2CEndlessWarEnd(lPlayer, oWar, mArgs)
    local oWorldMgr = global.oWorldMgr
    local iRing = oWar:GetData("ring", 1)
    for _, iPid in ipairs(lPlayer) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send("GS2CEndlessWarEnd", {
                pass_ring = iRing - 1,
                })
        end
    end
end

function CHuodong:TestOP(oPlayer, iCmd, ...)
    local oNotifyMgr = global.oNotifyMgr
    local mArgs = {...}
    local iPid = oPlayer:GetPid()
    if iCmd == 101 then
        local oInfo = self:GetInfoObj(iPid)
        if not oInfo then
            oInfo = self:NewInfo(iPid)
        end
        oInfo:RefreshChip(oPlayer)
        oInfo:NotifyChipInfo(oPlayer)
    elseif iCmd == 102 then
        local oInfo = self:GetInfoObj(iPid)
        if not oInfo then
            oInfo = self:NewInfo(iPid)
            oInfo:RefreshChip(oPlayer)
        end
        local iChipSid = table.unpack(mArgs)
        if not iChipSid then
            iChipSid = oInfo:ChooseChipSid()
        end
        if oInfo:HasChip(iChipSid) then
            self:StartEndlessPVE(oPlayer, iChipSid)
            oNotifyMgr:Notify(iPid, string.format("伙伴碎片id:%s", iChipSid))
        else
            oInfo:RefreshChip(oPlayer)
        end
    elseif iCmd == 103 then
        local iMaxRing = mArgs[1] or gamedefines.ENDLESS_PVE_MAX_RING
        self.m_iMaxRing = iMaxRing
        oNotifyMgr:Notify(iPid,string.format("战斗最大波数已设置为：%s 波",iMaxRing))
    elseif iCmd == 104 then
    end
end
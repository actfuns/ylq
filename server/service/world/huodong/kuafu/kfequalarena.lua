--import module
local skynet = require "skynet"
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))
local partnerctrl = import(service_path("playerctrl.partnerctrl"))
local loadskill = import(service_path("skill/loadskill"))
local huodongbase = import(service_path("huodong.kuafu.kfhuodongbase"))
local warobj = import(service_path("warobj"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "公平竞技"
inherit(CHuodong, huodongbase.CHuodong)

GAME_START = 1
GAME_OVER = 2

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_Status = GAME_OVER
    o.m_TopRecord = {}  -- 对战记录
    o.m_OPidx  = 0
    o.m_RewardRankList = {}
    o.m_KFService = ".world1"
    o.m_GameStart = 0
    o.m_GameTime = 2*3600
    return o
end

function CHuodong:LoadFinish()
    local iWeekDay = get_weekday()
    local tbl = get_hourtime({hour=0})
    if table_count(self.m_RewardRankList) > 10 then
        local keylist = table_key_list(self.m_RewardRankList)
        local iKey = extend.Array.min(keylist)
        self.m_RewardRankList[iKey] = nil
        self:Dirty()
    end
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.show = self.m_TopRecord
    mData.rank = self.m_RewardRankList
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    self.m_TopRecord = mData.show or {}
    self.m_RewardRankList = mData.rank or {}
end

function CHuodong:InHuodongTime()
    return self.m_Status == GAME_START
end

function CHuodong:IsClose()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:IsClose("equalarena")
end

function CHuodong:InMatchState(oPlayer)
    local oState = oPlayer.m_oStateCtrl:GetState(1007)
    return  oState and oState:PlayName() == "equalarena"
end

function CHuodong:SetMatchState(oPlayer)
    local oState = oPlayer.m_oStateCtrl:AddState(1007)
    if oState then
        oState:SetData("play","equalarena")
    end
end

function CHuodong:CleanMatchState(oPlayer)
    if self:InMatchState(oPlayer) then
        oPlayer.m_oStateCtrl:RemoveState(1007)
    end
end

function CHuodong:InOperateState(oPlayer)
    local oState = oPlayer.m_oStateCtrl:GetState(1008)
    return  oState and oState:PlayName() == "equalarena"
end

function CHuodong:SetOperateState(oPlayer)
    local oState = oPlayer.m_oStateCtrl:AddState(1008)
    if oState then
        oState:SetData("play","equalarena")
    end
end

function CHuodong:CleanOperateState(oPlayer)
    if self:InMatchState(oPlayer) then
        oPlayer.m_oStateCtrl:RemoveState(1008)
    end
end


function CHuodong:OnLogout(oPlayer)
    if self:InMatchState(oPlayer) then
        self:_CheckInMatch(oPlayer,1)
    end
end

function CHuodong:OnDisconnected(oPlayer)
    if self:InMatchState(oPlayer) then
        self:_CheckInMatch(oPlayer,1)
    end
end


function CHuodong:OnLogin(oPlayer,reenter)
    self:RefreshLeftTime(oPlayer)
    if self:InMatchState(oPlayer) then
        self:_CheckInMatch(oPlayer,1)
    end
    if not reenter then
        self:WeekMaintain(oPlayer)
    end
end

function CHuodong:NewHour(iWeekDay, iHour)
    local oWorld = global.oWorldMgr
    if iHour == 0 then
        self:CheckRewardAndCleanRank()
    end
    self:CleanTopRank()
end

function CHuodong:CleanTopRank()
    local iNow = get_time()
    local iTimeOut = 7*24*3600
    for sStage,mRecordList in pairs(self.m_TopRecord) do
        for key,mUnit in ipairs(mRecordList) do
            if iNow - mUnit.time > iTimeOut then
                table.remove(mRecordList,key)
            end
        end
    end
    self:Dirty()
end


function CHuodong:CheckRewardAndCleanRank()
    local t = os.date("*t",get_time())
    if t["day"] == 1 then
        self:RewardRank()
    end
end


function CHuodong:GameStart()
    if self:InHuodongTime() then
        return
    end
    record.info("equalarena game start")
    self.m_Status = GAME_START
    self.m_GameStart = get_time()
    self:RefreshLeftTime()
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(1013)
    oNotifyMgr:SendPrioritySysChat("equal_start",sMsg,1)
end

function CHuodong:GameOver()
    if not self:InHuodongTime() then
        return
    end
    record.info("equalarena game over")
    local oWorldMgr = global.oWorldMgr
    self.m_Status = GAME_OVER
    for pid,oPlayer in pairs(oWorldMgr:GetOnlinePlayerList()) do
        if self:InMatchState(oPlayer) then
            self:_CheckInMatch(oPlayer,0)
        end
    end

    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(1014)
    oNotifyMgr:SendPrioritySysChat("equal_start",sMsg,1)
end




function CHuodong:RefreshLeftTime(oPlayer)
    if not self:InHuodongTime() then
        return
    end
    local iLeft = math.max(self.m_GameStart + self.m_GameTime - get_time(),1)
    local mNet = {left=iLeft}
    if oPlayer then
        oPlayer:Send("GS2CEqualArenaLeftTime",mNet)
    else
        local mData = {
            message = "GS2CEqualArenaLeftTime",
            type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
            id = 1,
            data = mNet,
            exclude = {}
        }
        interactive.Send(".broadcast","channel","SendChannel",mData)
    end
end


function CHuodong:GetArenaData(oPlayer)
    return oPlayer.m_oHuodongCtrl:GetData("EqualArena",{})
end

function CHuodong:SetArenaData(oPlayer,mData)
    oPlayer.m_oHuodongCtrl:SetData("EqualArena",mData)
end

function CHuodong:ArenaScore(oPlayer)
    local mData = self:GetArenaData(oPlayer)
    return mData["socre"] or self:GetConfigValue("reset_point")
end

function CHuodong:SetArenaScore(oPlayer,iScore)
    local mData = self:GetArenaData(oPlayer)
    mData["socre"] = iScore
    self:SetArenaData(oPlayer,mData)
end

function CHuodong:RewardRank()
    local mRequest = {
    data = {},
    respond = 1,
    rank_name = "equalarena",
    }
    interactive.Request(".rank","rank","GetExtraRankData",mRequest,function(mRecord,mData)
            self:_RewardRank(mData.data)
        end)
end


function CHuodong:_RewardRank(mData)
    local mRewardList = {}
    local res = require "base.res"
    local mRes = res["daobiao"]["huodong"][self.m_sName]["reward_config"]
    local keylist = table_key_list(mRes)
    table.sort(keylist)

    local iLastRank = 0
    local iLastPoint = 0
    local f = function(iRank)
        for _,k in ipairs(keylist) do
            if iRank <=  k then
                return k
            end
        end
        return 51
    end

    for _,mUnit in ipairs(mData.rank) do
        local iRank = f(mUnit.rank)
        mUnit.reward_rank = mRes[iRank]["reward"]
        if iLastRank < mUnit.rank then
            iLastRank = mUnit.rank
            iLastPoint = mUnit["point"]
        end
        table.insert(mRewardList,mUnit)
    end

    local iWeekDay = get_weekno()
    self.m_RewardRankList[iWeekDay - 1] = {point = iLastPoint }
    self:Dirty()
    self:DoSave()
    self:RewardTop500(mRewardList)

end

function CHuodong:RewardTop500(rewardlist)
    if #rewardlist <= 0 then
        return
    end
    local f = function ()
        for i=1,100 do
            if #rewardlist <= 0 then
                break
            end
            local mUnit = table.remove(rewardlist,1)
            self:SendRewardMail(mUnit["pid"],mUnit["reward_rank"],{rank =mUnit["rank"],score = mUnit["point"] })
        end
    end
    safe_call(f)
    self:DelTimeCb("RewardTop500")
    self:AddTimeCb("RewardTop500",1*1000,function ()
        self:RewardTop500(rewardlist)
        end)
    if #rewardlist <= 0 then
        local oWorld = global.oWorldMgr
        local pidlist = table_key_list(oWorld:GetOnlinePlayerList())
        self:RewardOnlinePlayer(pidlist)
    end
end

function CHuodong:RewardOnlinePlayer(pidlist)
    if #pidlist <= 0 then
        return
    end
    local oWorldMgr = global.oWorldMgr
    for i=1,100 do
        if #pidlist <= 0 then
            break
        end
        local pid = table.remove(pidlist,1)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            self:WeekMaintain(oPlayer)
        end
    end

    self:DelTimeCb("RewardOnlinePlayer")
    self:AddTimeCb("RewardOnlinePlayer",10*1000,function ()
        self:RewardOnlinePlayer(pidlist)
        end)

end

function CHuodong:WeekMaintain(oPlayer)
    if not oPlayer.m_oThisWeek:Query("EQArena_Score") then
        local mData = self:GetArenaData(oPlayer)
        mData["oldscore"] = self:ArenaScore(oPlayer)
        self:SetArenaScore(oPlayer,self:GetConfigValue("reset_point"))
        self:SetArenaData(oPlayer,mData)
        oPlayer.m_oThisWeek:Set("EQArena_Score",1)
    end
    if oPlayer.m_oThisWeek:Query("EQArena_Reward") then
        return false
    end
    local mArena = self:GetArenaData(oPlayer)
    if not mArena.time or get_time() - mArena.time > 15*3600*24 then
        oPlayer.m_oThisWeek:Set("EQArena_Reward",1)
        return false
    end

    local iLastWeek = get_weekno(mArena.time)
    local mReward = self.m_RewardRankList[iLastWeek]
    if not mReward then
        return
    end

    if mArena["oldscore"] >= mReward["point"] then
        oPlayer.m_oThisWeek:Set("EQArena_Reward",1)
        return false
    end
    local res = require "base.res"
    local mRes = res["daobiao"]["huodong"][self.m_sName]["reward_config"]
    local mRewardInfo = mRes[51]["reward"]
    oPlayer.m_oThisWeek:Set("EQArena_Reward",1)
    self:SendRewardMail(oPlayer:GetPid(),mRewardInfo,{score = mArena["oldscore"],rank = 501})
    return true
end


function CHuodong:SendRewardMail(pid,mRewardList,mLog)
    if pid == 0 then
        return
    end
    mLog["pid"] = pid
    local iRank = mLog["rank"]
    record.user("equalarena", "week_rank",mLog)
    local oMailMgr = global.oMailMgr
    local info
    if iRank > 500 then
        info = oMailMgr:GetMailInfo(39)
        info.context = string.format(info.context,iRank)
    else
        info = table_deep_copy(oMailMgr:GetMailInfo(26))
        info.context = string.format(info.context,iRank)
    end
    self:RewardListByMail(pid,mRewardList,{mailinfo=info})
end

function CHuodong:AddArenaPlay(oPlayer,iCnt)
    local mArena = self:GetArenaData(oPlayer)
    mArena.play = (mArena.play or 0 ) +iCnt
    mArena.weekno = get_weekno()
    mArena.time = get_time()
    self:SetArenaData(oPlayer,mArena)
    return mArena.play
end



function CHuodong:OpenArenaUI(oPlayer,bSet)
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local bWatch = false
    if table_count(self.m_TopRecord) > 0 then
        bWatch = true
    end
    local parlist = oPlayer.m_oPartnerCtrl:GetData("equalarena",{})
    if not bset and #parlist== 0 then
        local mFight = oPlayer.m_oPartnerCtrl:GetFightPartner()
        if table_count(mFight) >=2 then
            local parlist = {}
            for iPos,oPartner in pairs(mFight) do
                if #parlist == 2 then
                    break
                end
                table.insert(parlist,oPartner:ID())
            end
            local func = function(parlist)
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
                if oPlayer then
                    self:OpenArenaUI(oPlayer,true)
                end
            end
            oPlayer.m_oPartnerCtrl:SetEqualArena(parlist,func)
        end

    end
    local mNet = {
    arena_point = self:ArenaScore(oPlayer),
    weeky_medal =oPlayer.m_oThisWeek:Query("equalarenamedal",0),
    parid = parlist,
    open_watch = bWatch,
    }
    oPlayer:Send("GS2COpenEqualArena",mNet)
end

function CHuodong:SetEqualArenaPartner(oPlayer,parlist)
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local func = function(parlist)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:SetEqualArena2(oPlayer,parlist)
        end
    end
    oPlayer.m_oPartnerCtrl:SetEqualArena(parlist,func)
end

function CHuodong:SetEqualArena2(oPlayer,parlist)
    oPlayer:Send("GS2CSetEqualArenaParner",{partner = parlist})
end

function CHuodong:ClientStartMath(oPlayer,iResult)
    oPlayer:Send("GS2CEqualArenaStartMath",{result=iResult})
end

function CHuodong:KuafuProxyCmd(pobj,cmd,mData)
    local ret = true
    if cmd == "JoinResult" then
        self:OnJoinResult(pobj,mData)
    elseif cmd == "OnRemoveMe" then
        self:OnRemoveMe(pobj,mData)
    elseif cmd == "RequestToDelete" then
        ret = self:OnRequestToDelete(pobj,mData)
    elseif cmd == "WarEndReward" then
        self:OnRewardWarEnd(pobj,mData)

    elseif cmd == "CleanFlag" then
        self:OnCleanFlag(pobj,mData)
    elseif cmd == "EnterWar" then
        self:OnProxyEnterWar(pobj,mData)
    end
    return ret
end

function CHuodong:OnJoinResult(pobj,mData)
    if mData["proxy_code"] ~= 0 then
        record.warning(string.format("join equalarena err %s %s",mData["proxy_code"],pobj:GetPid()))
    end
end

function CHuodong:OnRequestToDelete(pobj,mData)
    return true
end

function CHuodong:OnRemoveMe(pobj,mData)
    local oWorldMgr = global.oWorldMgr
    local iPid = pobj:GetPid()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oWar = oPlayer:GetNowWar()
        if oWar and oWar.m_KFProxy then
            oWar:LeavePlayer(oPlayer)
        end
    end
end


function CHuodong:OnCleanFlag(pobj)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pobj:GetPid())
    if oPlayer then
        self:CleanFlag(oPlayer)
    end
end

function CHuodong:CleanFlag(oPlayer)
    self:CleanMatchState(oPlayer)
end


function CHuodong:OnRewardWarEnd(pobj,mData)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pobj:GetPid())
    local iMedal = mData["medal"]
    local iRewardScore = mData["score"]
    local iScore = self:ArenaScore(oPlayer)
    local iWin = mData["win"]
    local sReason = "公平竞技获胜"
    if iWin ~= 1 then
        sReason = "公平竞技失败"
    end
    if iMedal > 0 then
        oPlayer:RewardArenaMedal(iMedal,sReason)
        oPlayer.m_oMonth:Add("equalarenamedal",iMedal)
    end
    if iWin == 1 then
        self:SetArenaScore(oPlayer,iScore+iRewardScore)
        global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"公平比武场连胜次数",{value=1})
        global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"公平比武场胜利场数",{value=1})
    else
        self:SetArenaScore(oPlayer, math.max(iScore-iRewardScore,0))
    end

    self:AddArenaPlay(oPlayer,1)
    self:RecordRank(oPlayer)
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30027,1)

end


function CHuodong:RecordRank(oPlayer)
    local mInfo = {
        point = self:ArenaScore(oPlayer),
        pid = oPlayer:GetPid(),
        name= oPlayer:GetName(),
        shape = oPlayer:GetModelInfo().shape,
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        segment= self:ArenaStage(self:ArenaScore(oPlayer)),
        time = get_current(),
    }
    local mRank = {}
    mRank.rank_name = "equalarena"
    mRank.rank_data = mInfo
    interactive.Send(".rank","rank","PushDataToRank",mRank)
end



function CHuodong:OnProxyEnterWar(pobj,mData)
    local oWar = mData["war"]
    local oWarMgr = global.oWarMgr
    local iWarId = oWar:GetWarId()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pobj:GetPid())
    self:CleanFlag(oPlayer)
    oWar:SetWarEndCallback(function (mArg)
            end)
end


function CHuodong:EnterMatch(oPlayer)
    if not self:ValidEnterMatch(oPlayer) then
        self:ClientStartMath(oPlayer,0)
        return
    end
    local oWorldMgr = global.oWorldMgr
    local func = function (iPid,mPartnerList)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oPlayer then
            return
        end
        self:EnterMatch2(oPlayer,mPartnerList)
    end
    local mParList1 = oPlayer.m_oPartnerCtrl:GetData("equalarena",{})
    oPlayer.m_oPartnerCtrl:GetPartnerList(mParList1,func)
end

function CHuodong:EnterMatch2(oPlayer,mPartnerList)
    if not self:ValidEnterMatch(oPlayer) then
        self:ClientStartMath(oPlayer,0)
        return
    end

    local oKFMgr = global.oKFMgr

    if oKFMgr:GetProxy(oPlayer:GetPid()) then
        self:ClientStartMath(oPlayer,0)
        return
    end

    local pid = oPlayer:GetPid()
    local iScore = self:ArenaScore(oPlayer)
    local iStage = self:ArenaStage(iScore)
    local mArena = self:GetArenaData(oPlayer)
    self:SetMatchState(oPlayer)
    self:ClientStartMath(oPlayer,1)
    local mWarInfo = {}
    local mPlayerWarInfo = oPlayer:PackWarInfo()
    mPlayerWarInfo.serverkey = get_server_key()
    mWarInfo.playerwarinfo = mPlayerWarInfo
    local mPartnerInfo = {}
    local mFightPartner = oPlayer.m_oPartnerCtrl:GetFightPartner()
    for iPos=1,4 do
        local oPartner = mFightPartner[iPos]
        if oPartner then
            table.insert(mPartnerInfo,{partnerdata = oPartner:PackWarInfo(),})
        end
    end
    mWarInfo.partnerinfo = mPartnerInfo
    local data={
        score =iScore,
        stage =iStage,
        partner = mPartnerList,
        warinfo=mWarInfo,
        week_medel = oPlayer.m_oMonth:Query("equalarenamedal",0),
    }
    oKFMgr:JoinKFGame(oPlayer,"equalarena",{extra = data},{obj=self})
end


function CHuodong:_CheckInMatch(oPlayer,iLeave,sNotify)
    local oNotify = global.oNotifyMgr
    self:CleanMatchState(oPlayer)
    if iLeave == 1 then
        local obj = global.oKFMgr:GetProxy(oPlayer:GetPid())
        if obj then
            obj:RemoveMe()
        end
        self:ClientStartMath(oPlayer,0)
    end
    if sNotify and sNotify~="" then
         oNotify:Notify(oPlayer:GetPid(),sNotify)
    end
end


function CHuodong:LeaveMatch(oPlayer)
    self:_CheckInMatch(oPlayer,1)
    local obj = global.oKFMgr:GetProxy(oPlayer:GetPid())
    if not obj or obj.m_sMode ~= self.m_sName then
        return
    end
    self:_CheckInMatch(oPlayer,1)
end

function CHuodong:ValidEnterMatch(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iGrade = oWorldMgr:QueryControl("equalarena","open_grade")
    if not self:InHuodongTime() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1005))
        return false
    elseif oPlayer:HasTeam() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1008))
        return false
    elseif self:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1007))
        return false
    elseif oPlayer:GetGrade()< iGrade then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1002))
        return false
    elseif self:InOperateState(oPlayer) then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1009))
        return false
    elseif self:InMatchState(oPlayer) then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1009))
        return false
    elseif #oPlayer.m_oPartnerCtrl:GetData("equalarena",{}) ~= 2 then
        oNotifyMgr:Notify(oPlayer:GetPid(),"需要设置两个伙伴参加")
        return false
    end
    return true
end

function CHuodong:ArenaData()
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["arena"]
end


-- ELO - (para[min(La,Lb)]*(if(a取胜?1;0)-1/(1+10^((Tb-Ta)/400)),0)
-- Ta is Winner
function CHuodong:ScoreCalculator(iTa,iTb)
    local mData = self:ArenaData()
    local iLa = self:ArenaStage(iTa)
    local iLb = self:ArenaStage(iTb)
    local iPara = mData[math.min(iLa,iLb)]["para"]
    local fY=1/(1+10^((iTb-iTa)/400))
-- 目前双方增减积分相同
    local iA = math.max(math.floor(iPara*(1-fY)),0)
    return iA,iA
end

function CHuodong:ArenaStage(iScore)
    return 1
end


function CHuodong:SelectOperate(oPlayer,iSelectPart,iItemList)
    local oKFMgr = global.oKFMgr
    local obj = oKFMgr:GetProxy(oPlayer:GetPid())

    if not obj or obj.m_sMode ~= self.m_sName then
        return
    end
    obj:Send2KSPlay({cmd="SelectOperate",pid=oPlayer:GetPid(),args={iSelectPart,iItemList}})
end

function CHuodong:ConfigArena(oPlayer,iSelectPart,iItemList,iType)
    local oKFMgr = global.oKFMgr
    local obj = oKFMgr:GetProxy(oPlayer:GetPid())
    if not obj or obj.m_sMode ~= self.m_sName then
        return
    end
    obj:Send2KSPlay({cmd="ConfigArena",pid=oPlayer:GetPid(),args={iSelectPart,iItemList,iType}})
end

function CHuodong:SyncSelectInfo(oPlayer,mData)
    local oKFMgr = global.oKFMgr
    local obj = oKFMgr:GetProxy(oPlayer:GetPid())
    if not obj or obj.m_sMode ~= self.m_sName then
        return
    end
    obj:Send2KSPlay({cmd="SyncSelectInfo",pid=oPlayer:GetPid(),args={mData}})
end

function CHuodong:OperateFinish(oOperate)
    --
end

function CHuodong:OnKFCmd(sCmd,mData)
    local Ret
    if sCmd == "CmdSyncState" then
        Ret=self:CmdSyncState(mData)
    elseif sCmd == "RecordWarFilm" then
        self:RecordWarFilm(mData)
    else
        record.warning(string.format("invoke kfequalarena : %s",sCmd))
    end
    return Ret
end

function CHuodong:CmdSyncState(mData)
    local iState = mData["status"]
    if iState == GAME_START then
        self:GameStart()
    elseif iState == GAME_OVER then
        self:GameOver()
    else
        return {ok = 0,status=iState}
    end
    return {ok=1,status= iState}
end

function CHuodong:RecordWarFilm(mData)
    --跨服屏蔽录像
    if true then return end
    local mRecord = mData["record"]
    local plist = mData["plist"]
    local mFileData = mData["filmdata"]
    local iWarType = mData["war_type"]
    local iBout = mData["bout"] or 0
    local oWarFilmMgr = global.oWarFilmMgr
    local oFilm = oWarFilmMgr:AddWarFilm(mFileData,{war_type =iWarType,})
    local iFid = oFilm:GetFilmId()
    mRecord.fid = iFid
    if iBout > 3 then
        self:CollectWarRecord(mRecord)
    end
    local oWorldMgr = global.oWorldMgr
    for _,pid in ipairs(plist) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            self:RecordData(oPlayer,mRecord)
        end
    end
end


function CHuodong:RecordData(oPlayer,mRecord)
    local mCopyRecord = table_deep_copy(mRecord)
    mCopyRecord.time = get_time()
    local mUnit = mCopyRecord.fight[oPlayer:GetPid()]
    if mCopyRecord.win == oPlayer:GetPid() then
        mCopyRecord.score = mUnit.score
    else
        mCopyRecord.score = - mUnit.score
    end
    local mArena = self:GetArenaData(oPlayer)
    local mRecordList = mArena.record or {}
    table.insert(mRecordList,mCopyRecord)
    mArena.record = mRecordList
    self:SetArenaData(oPlayer,mArena)
    self:CleanRecord(oPlayer)
    local mShow = mArena.show_record
    local iFid = (mShow and (mShow.fid or 0)) or 0
    if not iFid or iFid == 0 then
        for _,mData in pairs(mRecordList) do
            if tonumber(iFid) < tonumber(mData.fid) then
                iFid  = mData.fid
                mShow = mData
            end
        end
    end
end

function CHuodong:CleanRecord(oPlayer)
    local mArena = self:GetArenaData(oPlayer)
    local mRecordList = mArena.record or {}
    local iNow = get_time()
    local iTimeout = 72*3600
    for i= 1,#mRecordList do
        local mData = mRecordList[1]
        if not mData then
            break
        end
        if iNow - mData.time < iTimeout then
            break
        end
        table.remove(mRecordList,1)
    end
    local iLimit = 10
    if #mRecordList > iLimit then
        table.remove(mRecordList,1)
    end
    mArena.record = mRecordList
    self:SetArenaData(oPlayer,mArena)
    return mRecordList
end




function CHuodong:CollectWarRecord(mRecord)
    local mCopyRecord = table_deep_copy(mRecord)
    mCopyRecord.time = get_time()
    local mFight = mCopyRecord["fight"]
    local iScore = 0
    for pid,mUnit in pairs(mFight) do
        if iScore < mUnit.point then
            iScore = mUnit.point
        end
    end
    mCopyRecord.maxpoint = iScore
    local sStage = db_key(self:ArenaStage(iScore))
    local mRecordList = self.m_TopRecord[sStage] or {}
    local iLen = #mRecordList
    table.insert(mRecordList,mCopyRecord)
    table.sort(mRecordList,function (a1,a2)
            return a1.maxpoint > a2.maxpoint
            end)

    local mMaxTable = {mRecordList[1],mRecordList[2],}
    table.sort(mRecordList,function (a1,a2)
            return a1.time > a2.time
            end)

    local mNewCopyRecord = {}
    for i,mRecord in ipairs(mRecordList) do
        local fid = mRecord.fid
        if fid ~= mMaxTable[1].fid then
            if mMaxTable[2]  and fid ~= mMaxTable[2].fid then
                table.insert(mNewCopyRecord,mRecord)
            end
        end
    end
    if mMaxTable[1] then
        table.insert(mNewCopyRecord,1,mMaxTable[1])
    end

    if mMaxTable[2] then
        table.insert(mNewCopyRecord,2,mMaxTable[2])
    end
    if #mNewCopyRecord>= 10 then
        table.remove(mNewCopyRecord,#mNewCopyRecord)
    end
    self.m_TopRecord[sStage] = mNewCopyRecord
    self.m_TopRecordPack = nil
    self:Dirty()
end

function CHuodong:ShowTopRecord(oPlayer)
    local mNet
    if not self.m_TopRecordPack then
        mNet = {}
        mNet.grade_record_info = {}
        for sStage,mRecordList in pairs(self.m_TopRecord) do
            local mData={}
            mData.stage = tonumber(sStage)
            mData.history_info = {}
            for i=1,5 do
                local mRecord = mRecordList[i]
                if not mRecord then
                    break
                end
                table.insert(mData.history_info,self:PackHistoryInfo(mRecord))
            end
            table.insert(mNet.grade_record_info,mData)
        end
        self.m_TopRecordPack = mNet
    else
        mNet = self.m_TopRecordPack
    end
    oPlayer:Send("GS2CEqualArenaOpenWatch",mNet)
end

function CHuodong:PackHistoryInfo(mData)
    local mFight = mData.fight
    local mRecord = {}
    local mFightList = {}
    local mCamp = mData["camp"]
    if not mCamp then
        mCamp = {}
        for pid,mR in pairs(mFight) do
            pid = tonumber(pid)
            table.insert(mCamp,pid)
        end
    end

    for iCamp,pid in ipairs(mCamp) do
        local mR = mFight[pid]
        local mPartner = {}
        for pid,shape in pairs(mR.partner or {}) do
            table.insert(mPartner,shape)
        end
        local mPlayerInfo = {
                    name = mR.name,
                    partner = table_to_int_key(mPartner),
                    point = mR.point,
                    grade = mR.grade,
                    shape = mR.shape,
                    pid = pid,
                }
        table.insert(mFightList,mPlayerInfo)
        mRecord.playerInfo = mFightList
        mRecord.fid = mData.fid or 0
        mRecord.win = mData.win
        mRecord.score = mData.score
        mRecord.time = mData.time
        end
    return mRecord
end


function CHuodong:OpenArenaHistory(oPlayer)
    self:CleanRecord(oPlayer)
    local mArena = self:GetArenaData(oPlayer)
    local mRecordList = mArena.record or {}
    local mHistory_info = {}
    local iCnt = 0
    for i = #mRecordList,#mRecordList-4,-1 do
        if i <=0 then break end
        local mData = mRecordList[i]
        table.insert(mHistory_info,1,self:PackHistoryInfo(mData))
    end
    local mNet ={
    history_info = mHistory_info,
    history_onshow = {},
    }
    oPlayer:Send("GS2CEqualArenaHistory",mNet)
end



function CHuodong:TestOP(oPlayer,iFlag,...)
    local args = {...}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    local oKFMgr = global.oKFMgr
    local mPack= {
            name = "equalarena",
            args = args,
            flag = iFlag,
        }
    local iPid = oPlayer:GetPid()
    local f = function (mRecord,mData)
    end
    if iFlag == 100 then
        oChatMgr:HandleMsgChat(oPlayer,"101-设置分数,并且增加参战记录")
        oChatMgr:HandleMsgChat(oPlayer,"102-清空活动条件")
        oChatMgr:HandleMsgChat(oPlayer,"103-开关活动")
    elseif iFlag == 101 then
        self:SetArenaScore(oPlayer,tonumber(args[1]))
        self:AddArenaPlay(oPlayer,1)
        self:RecordRank(oPlayer)
    elseif iFlag == 102 then
        self.m_RewardRankList = {}
        self:Dirty()
    elseif iFlag == 103 then
        oKFMgr:Send2KSWorld(self.m_KFService,"HuodongTestOP",mPack,f)
    elseif iFlag == 104 then
        local oWarMgr = global.oProxyWarMgr
        local oKFMgr = global.oKFMgr
        local iCnt = table_count(oWarMgr.m_mWars)
        local plist = global.oWorldMgr:GetOnlinePlayerList()
        local iWarCnt = 0
        local iPCnt = 0
        for pid,pobj in pairs(plist) do
            if pobj:GetNowWar() then
                iWarCnt = iWarCnt + 1
            end
            iPCnt = iPCnt + 1
        end
        local iProxyCnt = 0
        local msg = string.format("战斗对象:%s 参与战斗人数:%s 代理对象:%s,在线:%s",iCnt,iWarCnt,iProxyCnt,iPCnt)
        print(msg)
        oChatMgr:HandleMsgChat(oPlayer,msg)
        print("Film:",table_count(global.oWarFilmMgr.m_mList))
        print("debug:",oKFMgr.m_DebugSetCnt,oKFMgr.m_DebugDelCnt)
    elseif iFlag == 116 then
        self:RewardRank()
    elseif iFlag == 117 then
        self:WeekMaintain(oPlayer)
    elseif iFlag == 118 then
        oKFMgr:Send2KSWorld(self.m_KFService,"HuodongTestOP",mPack,f)
    elseif iFlag == 120 then
        oKFMgr:Send2KSWorld(self.m_KFService,"HuodongTestOP",mPack,f)
    elseif iFlag == 121 then
        self:GameStart()
        oKFMgr:Send2KSWorld(self.m_KFService,"HuodongTestOP",mPack,f)
        local plist = global.oWorldMgr:GetOnlinePlayerList()
        for pid,pobj in pairs(plist) do
            pobj:Send("GS2CWarResult",{})
        end
    elseif iFlag == 100001 then
        self:EnterMatch(oPlayer)
    elseif iFlag == 100002 then
        local plist = oWorldMgr:GetOnlinePlayerList()
        local iCnt = 0
        for pid,_ in pairs(plist) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
            if oPlayer then
                local oWar = oPlayer:GetNowWar()
                if oWar and oWar.m_KFProxy then
                    iCnt = iCnt + 1
                end
            end
        end
        oNotifyMgr:Notify(iPid,string.format("kuafu fight cnt %d",iCnt))
    elseif iFlag == 100003 then
        oKFMgr:Send2KSWorld(self.m_KFService,"HuodongTestOP",mPack,f)
    elseif iFlag == 100004 then
        oKFMgr:Send2KSWorld(self.m_KFService,"HuodongTestOP",mPack,f)
    end
end








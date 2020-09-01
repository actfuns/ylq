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
local huodongbase = import(service_path("huodong.huodongbase"))
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
    o.m_OperateList = {}
    o.m_RewardRankList = {}
    o.m_GameTime = 2*3600
    return o
end

function CHuodong:LoadFinish()
    if table_count(self.m_RewardRankList) > 20 then
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
    mData.rrank = self.m_RewardRankList
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    self.m_TopRecord = mData.show or {}
    self.m_RewardRankList = mData.rrank or {}
end

function CHuodong:MergeFrom(mFromData)
    -- 可抛弃数据
    return true
end


function CHuodong:InHuodongTime()
    return self.m_Status == GAME_START
end

function CHuodong:IsClose()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:IsClose("equalarena")
end

function CHuodong:OnLogout(oPlayer)
    if self:InMatchStateNoTarget(oPlayer) then
        self:_CheckInMatch(oPlayer,1)
    end
end

function CHuodong:OnDisconnected(oPlayer)
    if self:InMatchStateNoTarget(oPlayer) then
        self:_CheckInMatch(oPlayer,1)
    end
end

function CHuodong:OnLogin(oPlayer,reenter)
    if self:InMatchStateNoTarget(oPlayer) then
        self:_CheckInMatch(oPlayer,1)
    end
    self:RefreshLeftTime(oPlayer)
    if not reenter then
        self:WeekMaintain(oPlayer)
    end
    local oOperate = self:GetOperateUIByPlayer(oPlayer)
    if oOperate then
        oOperate:ReEnter(oPlayer)
    end
end

function CHuodong:InMatchStateNoTarget(oPlayer)
   local oState = oPlayer.m_oStateCtrl:GetState(1007)
   if oState and oState:PlayName() == "equalarena" and not oState:GetData("play_arg") then
        return true
   end
   return false
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

function CHuodong:GetReadyStateData(oPlayer)
    local oState = oPlayer.m_oStateCtrl:GetState(1007)
    if not oState then
        return
    end
    if oState:PlayName() ~= "equalarena" then
        return
    end
    return oState:GetData("play_arg")
end


function CHuodong:NewHour(iWeekDay, iHour)
    local oWorld = global.oWorldMgr
    if iHour == 0 then
        self:CheckRewardAndCleanRank()
    end
    self:CleanTopRank()
    self:CheckOpen(iWeekDay,iHour)
end


function CHuodong:CheckOpen(iWeekDay,iHour)
    local mOpenDay = self:GetConfigValue("open_day")
    local iStart = self:GetConfigValue("start_hour")
    if table_in_list(mOpenDay,iWeekDay) then
        if iHour == iStart then
            self:GameStart()
        end
    end
end

function CHuodong:CheckRewardAndCleanRank()
    local t = os.date("*t",get_time())
    if t["day"] == 1 then
        self:RewardRank()
    end
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


function CHuodong:GameStart()
    if self:InHuodongTime() then
        return
    end
    record.info("equalarena game start")
    self.m_Status = GAME_START
    self.m_GameStart = get_time()
    self:SendMatch("CleanCach",{})
    self:SendMatch("StartMatch",{data={time=500,limit=50}})
    self:DelTimeCb("GameOver")
    self:AddTimeCb("GameOver",self.m_GameTime * 1000,function ()
        self:GameOver()
    end)
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
    self:SendMatch("CleanCach",{})
    self:SendMatch("StopMatch",{})
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(1014)
    oNotifyMgr:SendPrioritySysChat("equal_start",sMsg,1)

    for pid,oPlayer in pairs(oWorldMgr:GetOnlinePlayerList()) do
        if self:InMatchState(oPlayer) then
            self:_CheckInMatch(oPlayer,0)
        end
    end
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
    local iLastPid = 0
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
            iLastPid = mUnit.pid
        end
        table.insert(mRewardList,mUnit)
    end

    local iMonth = get_monthno()
    self.m_RewardRankList[iMonth] = {point = iLastPoint,lastrank = iLastRank,last=iLastPid}
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
        record.info("Clean Equalarena Rank")
        local mNet = {
        data = {},
        rank_name = "equalarena",
        }
        interactive.Send(".rank","rank","CleanAllData",mNet)
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
    if not oPlayer.m_oMonth:Query("EQArena_Score") then
        local mData = self:GetArenaData(oPlayer)
        mData["oldscore"] = self:ArenaScore(oPlayer)
        self:SetArenaScore(oPlayer,self:GetConfigValue("reset_point"))
        self:SetArenaData(oPlayer,mData)
        oPlayer.m_oMonth:Set("EQArena_Score",1)
    end
    if oPlayer.m_oMonth:Query("EQArena_Reward") then
        return false
    end
    local mArena = self:GetArenaData(oPlayer)
    if not mArena.time or get_time() - mArena.time > 15*3600*24 then
        oPlayer.m_oMonth:Set("EQArena_Reward",1)
        return false
    end

    local iLastMoth = get_monthno(mArena.time) + 1
    local mReward = self.m_RewardRankList[iLastMoth]
    if not mReward or oPlayer:GetPid() == mReward["last"] then
        oPlayer.m_oMonth:Set("EQArena_Reward",1)
        return false
    end

    if mArena["oldscore"] >= mReward["point"] then
        oPlayer.m_oMonth:Set("EQArena_Reward",1)
        return false
    end
    local res = require "base.res"
    local mRes = res["daobiao"]["huodong"][self.m_sName]["reward_config"]
    local mRewardInfo = mRes[51]["reward"]
    oPlayer.m_oMonth:Set("EQArena_Reward",1)
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



function CHuodong:SendMatch(sFun,mData,backfunc)
    mData.name = "equalarena"
    if not backfunc then
        interactive.Send(".recommend","match",sFun,mData)
    else
        mData.respond = 1
        interactive.Request(".recommend","match",sFun,mData,backfunc)
    end
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
    weeky_medal =oPlayer.m_oMonth:Query("equalarenamedal",0),
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

function CHuodong:GetOperateUIByPlayer(oPlayer)
    if oPlayer.m_EqualArenaOperate then
        return self:GetOperateUI(oPlayer.m_EqualArenaOperate)
    end
end

function CHuodong:GetOperateUI(idx)
    return self.m_OperateList[idx]
end

function CHuodong:CreateOperateUI()
    self.m_OPidx = self.m_OPidx + 1
    local obj = COperateUI:New(self.m_OPidx,{})
    self.m_OperateList[obj.m_ID] = obj
    return obj
end


function CHuodong:DelOperateUI(obj)
    local idx = obj.m_ID
    baseobj_delay_release(obj)
     self.m_OperateList[idx] = nil
end


function CHuodong:EnterMatch(oPlayer)
    if not self:ValidEnterMatch(oPlayer) then
        self:ClientStartMath(oPlayer,0)
        return
    end
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local iScore = self:ArenaScore(oPlayer)
    local iStage = self:ArenaStage(iScore)
    local mArena = self:GetArenaData(oPlayer)
    self:SetMatchState(oPlayer)
    self:SendMatch("EnterMatch",{id=oPlayer:GetPid(),data={score =iScore,stage =iStage,}})
    self:ClientStartMath(oPlayer,1)
end

function CHuodong:_CheckInMatch(oPlayer,iLeave,sNotify)
    local oNotify = global.oNotifyMgr
    self:CleanMatchState(oPlayer)
    if iLeave == 1 then
        self:SendMatch("LeaveMatch",{id=oPlayer:GetPid(),})
        self:ClientStartMath(oPlayer,0)
    end
    if sNotify and sNotify~="" then
         oNotify:Notify(oPlayer:GetPid(),sNotify)
    end
end


function CHuodong:LeaveMatch(oPlayer)
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

function CHuodong:ArenaInfo(iStage)
    local mData = self:ArenaData()
    return mData[iStage]
end


function CHuodong:MatchResult(fightlist,mInfo)
    local oWorldMgr = global.oWorldMgr
    local oNotify = global.oNotifyMgr
    local oWarMgr = global.oWarMgr
    for _,mFight in pairs(fightlist) do
        self:ReadyStartOperate(mFight[1],mFight[2])
    end
end

function CHuodong:ReadyStartOperate(iTarget1,iTarget2)
    local oWorldMgr = global.oWorldMgr
    local oWarMgr = global.oWarMgr

    local oTarget1 = oWorldMgr:GetOnlinePlayerByPid(iTarget1)
    local oTarget2 = oWorldMgr:GetOnlinePlayerByPid(iTarget2)
    local bStartFight = self:CheckGame(iTarget1,iTarget2)

    if not bStartFight then
        if oTarget1 then self:_CheckInMatch(oTarget1,0) end
        if oTarget2 then  self:_CheckInMatch(oTarget2,0) end
        return
    end
    local f = function (oTarget1,oTarget2)
        local oState = oTarget1.m_oStateCtrl:GetState(1007)
        oState:SetData("play_arg",{target = oTarget2:GetPid()})
        self:RefreshReadyUI(oTarget1,oTarget2:GetPid())
    end
    f(oTarget1,oTarget2)
    f(oTarget2,oTarget1)
end

function CHuodong:RefreshReadyUI(oPlayer,iTarget,mPack)
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    oPlayer:DelTimeCb("arena_CheckReady")
    oPlayer:AddTimeCb("arena_CheckReady", 3*1000,function ()
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            self:_CheckReadyStatus(oPlayer)
        end
        end)
    if not mPack then
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        if oTarget then
            local mNet = {
            rankInfo = self:PackRankInfo(oTarget),
            }
            oPlayer:Send("GS2CEqualArenaMatch",mNet)
        end
    else
        oPlayer:Send("GS2CEqualArenaMatch",{rankInfo=mPack})
    end
end

function CHuodong:PackRankInfo(oPlayer)
    return {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        shape = oPlayer:GetModelInfo().shape,
        rank = 0,
        point = self:ArenaScore(oPlayer),
        praise = 0,
        }
end

function CHuodong:CheckGame(iTarget1,iTarget2,bReadyFight)
    local oWorldMgr = global.oWorldMgr
    local oTarget1 = oWorldMgr:GetOnlinePlayerByPid(iTarget1)
    local oTarget2 = oWorldMgr:GetOnlinePlayerByPid(iTarget2)
    local bStartFight = true
    if not self:ValidEnterGame(oTarget1,oTarget2,bReadyFight)  then
        bStartFight = false
    end
    if not self:ValidEnterGame(oTarget2,oTarget1,bReadyFight) then
        bStartFight = false
    end
    if not bStartFight then
        if oTarget1 then
            self:ClientStartMath(oTarget1,0)
        end
        if oTarget2 then
            self:ClientStartMath(oTarget2,0)
        end
    end
    return bStartFight
end

function CHuodong:_CheckReadyStatus(oPlayer)
    oPlayer:DelTimeCb("arena_CheckReady")
    local oWorldMgr = global.oWorldMgr
    local mInfo = self:GetReadyStateData(oPlayer)
    if mInfo then
        local iTarget = mInfo.target or 0
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        if oTarget then
            oTarget:DelTimeCb("arena_CheckReady")
        end
        self:IntoOperate(oPlayer:GetPid(),iTarget)
    end
end

function CHuodong:IntoOperate(iTarget1,iTarget2)
    local oWorldMgr = global.oWorldMgr
    local mParlist = {}
    local oTarget1 = oWorldMgr:GetOnlinePlayerByPid(iTarget1)
    local oTarget2 = oWorldMgr:GetOnlinePlayerByPid(iTarget2)
    local bStartFight = self:CheckGame(iTarget1,iTarget2)
    if not bStartFight then
        return
    end
    local func = function (iPid,mPartnerList)
        mParlist[iPid] = mPartnerList
        if table_count(mParlist) == 2 then
            self:IntoOperate2(iTarget1,iTarget2,mParlist)
        end
    end
    local mParList1 = oTarget1.m_oPartnerCtrl:GetData("equalarena",{})
    oTarget1.m_oPartnerCtrl:GetPartnerList(mParList1,func)

    local mParList2 = oTarget2.m_oPartnerCtrl:GetData("equalarena",{})
    oTarget2.m_oPartnerCtrl:GetPartnerList(mParList2,func)
end


function CHuodong:IntoOperate2(iTarget1,iTarget2,parlist)
    local oWorldMgr = global.oWorldMgr

    local oTarget1 = oWorldMgr:GetOnlinePlayerByPid(iTarget1)
    local oTarget2 = oWorldMgr:GetOnlinePlayerByPid(iTarget2)

    if table_count(parlist[iTarget1]) ~= 2 or table_count(parlist[iTarget2]) ~= 2 then
        if oTarget1 then
            self:CleanOperateState(oTarget1)
            self:ClientStartMath(oTarget1,0)
        end
        if oTarget2 then
            self:CleanOperateState(oTarget2)
            self:ClientStartMath(oTarget2,0)
        end
        return
    end


    local bStartFight = self:CheckGame(iTarget1,iTarget2)
    if not bStartFight then
        return
    end
    local obj = self:CreateOperateUI()
    if in_random(50,100) then
        obj:SetPlayer(oTarget1,parlist[iTarget1])
        obj:SetPlayer(oTarget2,parlist[iTarget2])
    else
        obj:SetPlayer(oTarget2,parlist[iTarget2])
        obj:SetPlayer(oTarget1,parlist[iTarget1])
    end
    obj:CreateData()
    obj:NextOperate()
end

function CHuodong:SelectOperate(oPlayer,iSelectPart,iItemList)
    local oOperate = self:GetOperateUI(oPlayer.m_EqualArenaOperate)
    if oOperate then
        local mPlayer = oOperate.m_Player[oPlayer:GetPid()]
        if mPlayer and mPlayer["operate"] then
            oOperate:SelectOperate()
        end
    end
end

function CHuodong:ConfigArena(oPlayer,iSelectPart,iItemList,iType)
    local oOperate = self:GetOperateUI(oPlayer.m_EqualArenaOperate)
    if oOperate then
        oOperate:ConfigOperate(oPlayer,iSelectPart,iItemList,iType or 1)
    end
end

function CHuodong:SyncSelectInfo(oPlayer,mData)
    local oOperate = self:GetOperateUI(oPlayer.m_EqualArenaOperate)
    if oOperate then
        oOperate:SyncSelectInfo(oPlayer,mData)
    end
end

function CHuodong:OperateFinish(oOperate)
    local mFight = oOperate:GetPartnerWarInfo()
    self:ReadyPVPWar(mFight)
end

function CHuodong:ReadyPVPWar(mFight)
    local oWorldMgr = global.oWorldMgr
    local oNotify = global.oNotifyMgr
    local oWarMgr = global.oWarMgr

    local mTarget1 = mFight[1]
    local mTarget2 = mFight[2]
    local iTarget1 = mTarget1["pid"]
    local iTarget2 = mTarget2["pid"]


    local oTarget1 = oWorldMgr:GetOnlinePlayerByPid(iTarget1)
    local oTarget2 = oWorldMgr:GetOnlinePlayerByPid(iTarget2)
    local bStartFight = self:CheckGame(iTarget1,iTarget2,true)
    if bStartFight then
       self:StartPVPWar(mTarget1,mTarget2)
    end

end

function CHuodong:ValidEnterWar(oPlayer,oTarget)
    return self:ValidEnterGame(oPlayer,oTarget,true)
end

function CHuodong:ValidEnterGame(oPlayer,oTarget,bReadyFight)
    local oNotifyMgr = global.oNotifyMgr
    if not oPlayer then
        return false
    elseif not self:InHuodongTime() and not bReadyFight then
        return false
    elseif self:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1007))
        return false
    elseif not oTarget then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1006))
        return false
    elseif oPlayer:GetNowWar() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1003))
        return false
    elseif oTarget:GetNowWar() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1004))
        return false
    elseif oPlayer:HasTeam() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1008))
        return false
    end
    return true
end


function CHuodong:StartPVPWar(mTarget1,mTarget2)
    local iTarget1 = mTarget1["pid"]
    local iTarget2 = mTarget2["pid"]
    local oWorldMgr = global.oWorldMgr
    local oNotify = global.oNotifyMgr
    local oWarMgr = global.oWarMgr

    local oTarget1 = oWorldMgr:GetOnlinePlayerByPid(iTarget1)
    local oTarget2 = oWorldMgr:GetOnlinePlayerByPid(iTarget2)
    local bStartFight = true
    if bStartFight then
        local mInfo1 = self:GetReadyStateData(oTarget1) or {}
        local mInfo2 = self:GetReadyStateData(oTarget2) or {}
        local iGameTarget1 = mInfo1.target
        local iGameTarget2 = mInfo2.target

        if iGameTarget1 ~= iTarget2 then
           bStartFight =false
        end
        if iGameTarget2 ~= iTarget1 then
            bStartFight =false
        end
    end
    self:_CheckInMatch(oTarget1,0)
    self:_CheckInMatch(oTarget2,0)
    if bStartFight then
        local mArg = {
        remote_war_type="equalarena",
        war_type = gamedefines.WAR_TYPE.EQUAL_ARENA,
        remote_args = { war_record = 1},
        pvpflag = 1,
        }
        local oWar = self:CreateWar(mArg)
        self:ConfigWar(oWar, mTarget1, mTarget2, mArg)
        oWar:SetData("close_auto_skill",true)

        local iScore1 = self:ArenaScore(oTarget1)
        local iScore2 = self:ArenaScore(oTarget2)
        self:CleanMatchState(oTarget1)
        self:CleanMatchState(oTarget2)
        oTarget1:Send("GS2CEqualArenaFight",{})
        oTarget2:Send("GS2CEqualArenaFight",{})

        local mWarRecord = {}
        local mUint1 = {
        name = oTarget1:GetName(),
        point = iScore1,
        partner = {},
        grade = oTarget1:GetGrade(),
        shape = oTarget1:GetModelInfo().shape,
        }
        mWarRecord[oTarget1:GetPid()] = mUint1
        local mUint2 = {
        pid = oTarget2:GetPid(),
        name = oTarget2:GetName(),
        point = iScore2,
        partner = {},
        grade = oTarget2:GetGrade(),
        shape = oTarget2:GetModelInfo().shape,
        }
        mWarRecord[oTarget2:GetPid()] = mUint2

        local mLog = {
        pid1 = oTarget1:GetPid(),
        point1 = iScore1,
        name1 = oTarget1:GetName(),
        count1 = 0,

        pid2 = oTarget2:GetPid(),
        point2 = iScore2,
        name2 = oTarget2:GetName(),
        count2 = 0,
        }
        record.user("equalarena", "start_pvp",mLog)


        local iWarID = oWar:GetWarId()
        local mArg = {camp_id = 1,
        FightPartner = mTarget1["war_partner"],
        CurrentPartner = mTarget1["war_partner"][1],
        }
        oWarMgr:EnterWar(oTarget1, iWarID, mArg, true)

        local mArg = {camp_id = 2,
        FightPartner = mTarget2["war_partner"],
        CurrentPartner = mTarget2["war_partner"][1],
        }
        oWarMgr:EnterWar(oTarget2, iWarID, mArg, true)

        oWarMgr:SetWarEndCallback(oWar:GetWarId(),function (mArg)
            local oWar = oWarMgr:GetWar(iWarID)
            oWar.m_WarRecord = {fight = mWarRecord}
            self:OnPVPWarEnd(oWar,iTarget1,iTarget2,iScore1,iScore2,mArg)
            end)
        oWarMgr:StartWar(iWarID)
    else
        if oTarget1 then
            oTarget1:Send("GS2CEqualArenaStartWarFail",{msg="进入战斗失败"})
        end
        if oTarget2 then
            oTarget2:Send("GS2CEqualArenaStartWarFail",{msg="进入战斗失败"})
        end
    end
end

function CHuodong:ConfigWar(oWar, mTarget1, mTarget2, mArg)
    --
end

function CHuodong:CreateWar(mInfo)
    local oWarMgr = global.oWarMgr
    local id = oWarMgr:DispatchSceneId()
    local oWar = CMyWar:New(id, mInfo)
    oWar:ConfirmRemote()
    oWarMgr.m_mWars[id] = oWar
    return oWar
end


function CHuodong:OnPVPWarEnd(oWar,iTarget1,iTarget2,iScore1,iScore2,mArg)
    local oWorldMgr = global.oWorldMgr
    local oTarget1 = oWorldMgr:GetOnlinePlayerByPid(iTarget1)
    local oTarget2 = oWorldMgr:GetOnlinePlayerByPid(iTarget2)
    local iRewardScore = self:ScoreCalculator(iScore1,iScore2)
    local mRecord = oWar.m_WarRecord
    local iBout = mArg["bout"] or 0
    local mFight = mRecord.fight
    local unit1 = mFight[iTarget1]
    local unit2 = mFight[iTarget2]
    unit1.score = iRewardScore
    unit2.score = iRewardScore

    mRecord.fid = mArg.war_film_id
    local mFightPartner = mArg.arena_partner
    local mPar1 = mFightPartner[iTarget1] or {}
    unit1.partner = mPar1
    local mPar2 = mFightPartner[iTarget2] or {}
    unit2.partner = mPar2

    local iLogScore1
    local iLogScore2
    if mArg.win_side ==1 then
        mRecord.win = iTarget1
        iLogScore1 = iRewardScore
        iLogScore2 = -iRewardScore
    else
        mRecord.win = iTarget2
        iLogScore1 = -iRewardScore
        iLogScore2 = iRewardScore
    end

    local sName1 = ""
    local sName2 = ""
    local iLogPScore1 = -1
    local iLogPScore2 = -1
    if oTarget1 then
        sName1 = oTarget1:GetName()
        iLogPScore1 = oTarget1:ArenaScore() + iLogScore1
        oTarget1:AddSchedule("equalarena")
        self:RecordData(oTarget1,mRecord)
    end

    if oTarget2 then
        sName2 = oTarget2:GetName()
        iLogPScore2 = oTarget2:ArenaScore() + iLogScore2
        oTarget2:AddSchedule("equalarena")
        self:RecordData(oTarget2,mRecord)
    end


    local mLog = {
        pid1= iTarget1,
        addpoint1 = iLogScore1,
        name1 = sName1,
        point1 = iLogPScore1,

        pid2 = iTarget2,
        name2 = sName2,
        addpoint2 = iLogScore2,
        point2 = iLogPScore2,
        win = mRecord.win,
        }

    mRecord["camp"] = {iTarget1,iTarget2}
    record.user("equalarena","end_arena",mLog)
    if iBout > 3 then
        self:CollectWarRecord(mRecord)
    end
    local oWiner,oLoser
    local iWiner,iLoser
    if mArg.win_side ==1 then
        oWiner = oTarget1
        oLoser = oTarget2
        iWiner = iTarget1
        iLoser = iTarget2
    else
        oWiner = oTarget2
        oLoser = oTarget1
        iWiner = iTarget2
        iLoser = iTarget1
    end

    local mResultData = {win=mArg.win_side}
    mResultData["data"] = {}
    table.insert(mResultData["data"],{pid = iTarget1,name =unit1["name"],shape=unit1["shape"],camp=1})
    table.insert(mResultData["data"],{pid = iTarget2,name =unit2["name"],shape=unit2["shape"],camp=2})

    if oWiner then
        self:RewardWin(oWiner,iRewardScore,iLoser,mRecord,mResultData)
    end

    if oLoser then
        local iCamp = mArg.win_side == 1 and 2 or 1
        local iEscapeList = mArg["escape_list"][iCamp] or {}
        local bReward = true
        if table_in_list(iEscapeList,oLoser:GetPid()) and iBout <= 3 then
            bReward = false
        end
        self:RewardFail(oLoser,iRewardScore,iWiner,mRecord,bReward,mResultData)

    end
    global.oHandBookMgr:CheckCondition("arena", nil, mArg)

    self:Dirty()
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


function CHuodong:RewardArenaMedal(oPlayer,bWin)
    local mData = self:ArenaData()
    local iLa = self:ArenaStage(self:ArenaScore(oPlayer))
    local mInfo = mData[iLa]
    local iWeek = mInfo.weeky_limit
    local iRewardPoint = mInfo.award_per_game
    local iNow = oPlayer.m_oMonth:Query("equalarenamedal",0)
    local sReason = "公平竞技获胜"
    if not bWin then
        iRewardPoint = iRewardPoint//2
        sReason = "公平竞技失败"
    end
    if iNow < iWeek then
        local iMin = math.min(iWeek-iNow,iRewardPoint)
        oPlayer:RewardArenaMedal(iMin,sReason)
        oPlayer.m_oMonth:Add("equalarenamedal",iMin)
        return iMin
    end
    return 0
end

function CHuodong:RewardWin(oPlayer,iRewardScore,iTarget,mRecord,mResultData)
    local iMedal  = self:RewardArenaMedal(oPlayer,true)
    self:AddKeep(oPlayer:GetPid(), "reward_honor", iMedal)
    local oNotify = global.oNotifyMgr
    local iScore = self:ArenaScore(oPlayer)
    self:SendWarResult(oPlayer,iRewardScore,iMedal,mResultData)
    self:SetArenaScore(oPlayer,iScore+iRewardScore)
    self:AddArenaPlay(oPlayer,1)
    self:RecordRank(oPlayer)
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30027,1)
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"公平比武场连胜次数",{value=1})
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"公平比武场胜利场数",{value=1})

    if iMedal > 0 then
        local mCurrency = {}
        mCurrency[gamedefines.COIN_FLAG.COIN_ARENA] = iMedal
        oPlayer:LogAnalyGame({}, "equal_arena",{},mCurrency,{},0)
    end
end

function CHuodong:SendWarResult(oPlayer,iScore,iMedal,mResultData)
    local mNet = {
            point = iScore,
            medal = iMedal,
            result = mResultData["win"],
            info = mResultData["data"],
            weeky_medal = oPlayer.m_oMonth:Query("equalarenamedal",0),
            currentpoint = self:ArenaScore(oPlayer),
        }
    oPlayer:Send("GS2CEqualArenaFightResult",mNet)
end


function CHuodong:RewardFail(oPlayer,iSubScore,iTarget,mRecord,bReward,mResultData)
    local oNotify = global.oNotifyMgr
    local iScore = self:ArenaScore(oPlayer)
    local iSetScore = math.max(iScore-iSubScore,0)
    local iMedal = 0
    if bReward then
        iMedal = self:RewardArenaMedal(oPlayer,false)
    end
    self:SendWarResult(oPlayer,iSubScore,iMedal,mResultData)
    self:SetArenaScore(oPlayer,iSetScore)
    self:AddArenaPlay(oPlayer,1)
    self:RecordRank(oPlayer)
    if iMedal > 0 then
        local mCurrency = {}
        mCurrency[gamedefines.COIN_FLAG.COIN_ARENA] = iMedal
        oPlayer:LogAnalyGame({}, "equal_arena",{},mCurrency,{},0)
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

function CHuodong:SetShowRecord(oPlayer,fid)
    local mArena = self:GetArenaData(oPlayer)
    local mRecordList = mArena.record or {}
    local mRecord
    for _,mData in ipairs(mRecordList) do
        if mData.fid == fid then
            mRecord = mData
            break
        end
    end
    if not mRecord then
        return
    end
    local mCopy = table_deep_copy(mRecord)
    local mArena = self:GetArenaData(oPlayer)
    mArena.show_record = mCopy
    self:SetArenaData(oPlayer,mArena)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr.Notify(oPlayer:GetPid(),"设定成功")
    oPlayer:Send("GS2CEqaulArenaSetShowing",{fid=fid})
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



function CHuodong:TestOP(oPlayer,iFlag,...)
    local args = {...}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
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
        if not self:InHuodongTime() then
            self:GameStart()
            oNotifyMgr:Notify(oPlayer:GetPid(),"开启了活动")
        else
            self:GameOver()
            oNotifyMgr:Notify(oPlayer:GetPid(),"关闭了活动")
        end
    elseif iFlag == 105 then
        self:RecordRank(oPlayer)
    elseif iFlag == 106 then
        local iPid = tonumber(args[1])
        self:IntoOperate(oPlayer:GetPid(),iPid)
    elseif iFlag == 107 then
        self:OpenArenaHistory(oPlayer)
    elseif iFlag == 108 then
        self:ShowTopRecord(oPlayer)
    elseif iFlag == 109 then
        self:SetShowRecord(oPlayer,tostring(args[1]))
    elseif iFlag == 110 then
        self:SetArenaScore(oPlayer,tonumber(args[1]))
        oPlayer.m_oMonth:Add("EqualArena_Play",1)
    elseif iFlag == 111 then
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(tonumber(args[1]))
        if oPartner then
            print(oPartner:GetName(),oPartner:GetData("skill"),oPartner:GetData("awake"))
        end
    elseif iFlag == 112 then
        local iRank = tonumber(args[1])
        local plist = {}
        for i=1,iRank-1 do
            local mUnit = {}
            mUnit["point"]  =100
            mUnit["pid"] = 0
            mUnit["rank"] = i
            table.insert(plist,mUnit)
        end
        if not (args[2] and tonumber(args[2]) ~= 0 ) then
            local mUnit = {}
            mUnit["point"]  =100
            mUnit["pid"] = oPlayer:GetPid()
            mUnit["rank"] = iRank
            table.insert(plist,mUnit)
        end
        self:_RewardRank({rank=plist})
    elseif iFlag == 113 then
        self:AddArenaPlay(oPlayer,1)
    elseif iFlag == 114 then
        self:WeekMaintain(oPlayer)
    elseif iFlag == 115 then
        local iRank = tonumber(args[1])
        local res = require "base.res"
        local mRes = res["daobiao"]["huodong"][self.m_sName]["reward_config"]
        local mConfig = res["daobiao"]["huodong"][self.m_sName]["reward_config"]
        local keylist = table_key_list(mConfig)
        table.sort(keylist)
        local f = function(iRank)
            for _,k in ipairs(keylist) do
                if iRank <=  k then
                    return k
                end
            end
            return 51
        end
        local iReward = f(iRank)
        local mRewardInfo = mRes[iReward]["reward"]
        self:SendRewardMail(oPlayer:GetPid(),mRewardInfo,{score = 500,rank = iRank})
    elseif iFlag == 116 then
        self:RewardRank()
    elseif iFlag == 117 then
        self:RewardOnlinePlayer({oPlayer:GetPid()})
    elseif iFlag == 119 then
        self:ShowRank()
    elseif iFlag == 120 then
        if not self:InHuodongTime() then
            self:GameStart()
            oNotifyMgr:Notify(oPlayer:GetPid(),"开启了活动")
        end
    elseif iFlag == 1024  then
        if args[1] ~= "robot" then
            return
        end
        self:SetArenaScore(oPlayer,2000+oPlayer:GetPid()*10)
        self:AddArenaPlay(oPlayer,1)
        self:RecordRank(oPlayer)
    end
end

CMyWar = {}
CMyWar.__index = CMyWar
inherit(CMyWar, warobj.CWar)

function CMyWar:PackPlayerWarInfo(oPlayer)
    local res = require "base.res"
    local mInitSkillData = res["daobiao"]["init_skill"]
    local iSchool = oPlayer:GetSchool()
    local iSchoolBranch = oPlayer:GetSchoolBranch()

    local mRole = res["daobiao"]["huodong"]["equalarena"]["role"]
    local mData
    for _,m in pairs(mRole) do
        if m["role"] == iSchool and m["school_branch"] == iSchoolBranch then
            mData = m
        end
    end

    local mSkill = mData["skill_list"]

    local mRet = {}
    mRet.pid = oPlayer:GetPid()
    mRet.grade = oPlayer:GetGrade()
    mRet.name = oPlayer:GetName()
    mRet.school = oPlayer:GetSchool()
    mRet.school_branch = oPlayer:GetSchoolBranch()
    mRet.model_info = oPlayer:GetModelInfo()
    mRet.is_team_leader = oPlayer:IsTeamLeader()
    mRet.team_size = oPlayer:GetTeamSize()
    mRet.auto_skill = oPlayer.m_oActiveCtrl:GetAutoSkill()
    mRet.auto_skill_switch = oPlayer.m_oActiveCtrl:GetAutoSkillSwitch()
    mRet.protectors = oPlayer:GetProtectors()
    mRet.double_attack_suspend = oPlayer:IsDoubleAttackSuspend()
    mRet.systemsetting = oPlayer:GetSystemSetting()
    mRet.testman = oPlayer:GetData("testman")
    local mPerform = {}
    for _,m in ipairs(mSkill) do
        local iPerform = m["skill"]
        local iLv = m["lv"]
        mPerform[iPerform] = iLv
    end
    mPerform[1008] = 1
    mRet.perform = mPerform

    local attrlist = {"max_hp","attack","defense","critical_ratio","res_critical_ratio","critical_damage",
                            "cure_critical_ratio", "abnormal_attr_ratio","res_abnormal_ratio","speed",}
    for _,sKey in ipairs(attrlist) do
        mRet[sKey] = tonumber(mData[sKey])
    end
    mRet.hp = mRet["max_hp"]

    return mRet
end





COperateUI  = {}
COperateUI.__index = COperateUI
inherit(COperateUI, datactrl.CDataCtrl)

function COperateUI:New(id,mData)
    local o = super(COperateUI).New(self)
    o.m_ID = id
    o:InitUI(mData)
    return o
end


function COperateUI:InitUI(mData)
    self.m_mData = mData
    self.m_Player = {}
    self.m_Step = 0
    self.m_WareHouse = {}
    self.m_ParID = 0
end

function COperateUI:SetPlayer(oPlayer,mPartnerList)
    local iPid = oPlayer:GetPid()
    local oHuodog = global.oHuodongMgr:GetHuodong("equalarena")

    local mData = {
    pid = iPid,
    selectPartner = {},
    selectItem = {},
    config = {},
    info = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        shape = oPlayer:GetModelInfo().shape,
        rank = 0,
        point = oHuodog:ArenaScore(oPlayer),
        praise = 0,
    },
    mypartner = mPartnerList,
    }
    if not self:Opponent(iPid) then
        mData["operate"] = true
    end
    self.m_Player[oPlayer:GetPid()] = mData
    oPlayer.m_EqualArenaOperate = self.m_ID
    oPlayer.m_RefuseTeamOperate = {
        name = "equalarena",
        operate = {
        all = {notify = "正在比武,无法组队"}
        }
        }
    return mData
end

function COperateUI:SendAll(msg,mNet)
    local oWorldMgr = global.oWorldMgr
    for pid,_ in pairs(self.m_Player) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            oPlayer:Send(msg,mNet)
        end
    end
end

function COperateUI:Release()
    local oWorldMgr = global.oWorldMgr
    self:DelTimeCb("NextOperate")
    for pid,mPlayer in pairs(self.m_Player) do
        if mPlayer["config"]  and mPlayer["config"]["partner"] then
            for _,oPartner in ipairs(mPlayer["config"]["partner"]) do
                baseobj_safe_release(oPartner)
            end
        end
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer and oPlayer.m_EqualArenaOperate == self.m_ID then
            oPlayer.m_EqualArenaOperate = nil
            if oPlayer.m_RefuseTeamOperate and oPlayer.m_RefuseTeamOperate["name"] == "equalarena" then
                oPlayer.m_RefuseTeamOperate = nil
            end
        end
    end
    for idx,oPartner in ipairs(self.m_WareHouse["partner"]) do
        baseobj_safe_release(oPartner)
    end
    self.m_Player = {}
    self.m_WareHouse = {}
    super(COperateUI).Release(self)
end

function COperateUI:CreateData()
    local res = require "base.res"
    local mData = table_deep_copy(res["daobiao"]["huodong"]["equalarena"]["ratio_list"])
    local mPartnerRatio  = mData["partner_list"]
    local mEquipRatio = mData["equip_list"]
    self.m_WareHouse["partner"] = {}
    self.m_WareHouse["equip"] = {}
    for i=1,8 do
        local sid =  table_choose_key(mPartnerRatio)
        mPartnerRatio[sid] = nil
        table.insert(self.m_WareHouse["partner"],self:CreatePartner(sid,1))
    end
    for i = 1,8 do
        local sid =  table_choose_key(mEquipRatio)
        table.insert(self.m_WareHouse["equip"],self:CratePartnerEquip(sid))
    end
end

function COperateUI:CreatePartner(iPar,iWake)
    local res = require "base.res"
    local mStandard = res["daobiao"]["partner"]["partner_info"][iPar]
    local mData = res["daobiao"]["huodong"]["equalarena"]["partner"][iPar]
    assert(mData and mStandard,string.format("equalarena.CreatePartner err %s",iPar))
    iWake = iWake or 1
    self.m_ParID = self.m_ParID + 1
    local mPartner = {
    type = iPar,
    name = mStandard["name"],
    grade = 35,
    model_info = {shape=mStandard["shape"],skin=mStandard["skin"]},
    power = 1,
    awake = iWake,
    effect_type =0,
    parid = self.m_ParID
    }
    local iUnlockSK = tonumber(mStandard["awake_effect"])
    local mSkillList = {}
    for k,v in pairs(mData["skilllist"]) do
        local iSk = v["skill"]
        assert(iSk,string.format("skill info %s %s",iPar,iSk))
        table.insert(mSkillList,{iSk,v["lv"]})
    end
    local mWake = mData["awake"]

    if iWake == 1 then
        for k,v in pairs(mWake) do
            table.insert(mSkillList,{v["skill"],v["lv"]})
        end
    end
    table.insert(mSkillList,{1008,1})
    mPartner["skill"] = mSkillList
    local attrlist = {"max_hp","attack","defense","critical_ratio","res_critical_ratio","critical_damage",
                               "cure_critical_ratio", "abnormal_attr_ratio","res_abnormal_ratio","speed",}
    for _,sKey in ipairs(attrlist) do
        mPartner[sKey] = tonumber(mData[sKey])
    end
    local oPartner = partnerctrl.NewPartner(0,mPartner)
    return oPartner

end

function COperateUI:RefreshReady(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local mPartner = {}
    for idx,oPartner in ipairs(self.m_WareHouse["partner"]) do
        table.insert(mPartner,oPartner:PackPartnerBase())
    end
    local mEquip = {}
    for idx,m in ipairs(self.m_WareHouse["equip"]) do
        table.insert(mEquip,m["type"])
    end

    local mLimit = self:NowData()

    local mInfo = {}

    local iOperater = 0
    local iLimit_Partner = 0
    local iLimit_FuWen = 0
    for pid,mData in pairs(self.m_Player) do
        if mData["operate"] then
            iLimit_Partner = mLimit["partner"] - table_count(mData["selectPartner"])
            iLimit_FuWen = mLimit["equip"] - table_count(mData["selectItem"])
            iOperater = pid
        end
        local mSelectPartner = {}
        local mSelectItem = {}
        local mFightPartner = {}
        local mAwakeList = {}
        for _,mPar in pairs(mData["mypartner"]) do
            table.insert(mFightPartner,mPar["model_info"]["shape"])
            table.insert(mAwakeList,mPar["awake"] or 0)
        end

        local mSyncSelect = mData["sync_select"]  or {{},{}}
        local mSyncSelectPartn = {}
        for k,_ in pairs(mSyncSelect[1]) do
            table.insert(mSyncSelectPartn,k)
        end

        local mSyncSelectItem = {}
        for k,_ in pairs(mSyncSelect[2]) do
            table.insert(mSyncSelectItem,k)
        end

        local mPack = {info = mData["info"],
                                    par_list = mFightPartner,
                                    awake_list = mAwakeList,
                                    select_par= mSyncSelectPartn,
                                    select_item= mSyncSelectItem,
                                }

        for _,idx in pairs(mData["SW_Partner"] or {}) do
            table.insert(mSelectPartner,idx)
        end
        for _,idx in pairs(mData["SW_Item"] or {}) do
            table.insert(mSelectItem,idx)
        end
        mPack["selected_partner"] = mSelectPartner
        mPack["selected_fuwen"] = mSelectItem

        table.insert(mInfo,mPack)
    end

    local mNet  = {
    info = mInfo,
    fuwen = mEquip,
    partner = mPartner,
    left_time = mLimit["time"],
    operater = iOperater,
    limit_partner = iLimit_Partner,
    limit_fuwen = iLimit_FuWen,
    }
    if oPlayer then
        oPlayer:Send("GS2CSelectEqualArena",mNet)
    else
        self:SendAll("GS2CSelectEqualArena",mNet)
    end
end

function COperateUI:CratePartnerEquip(sid)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"]["equalarena"]["partner_equip"][sid]
    return {type =mData["type"],args=mData["args"] }
end



function COperateUI:Broken()
    local oHuodong = global.oHuodongMgr:GetHuodong("equalarena")
    self:SendAll("GS2CCloseEqualArenaUI",{})
    oHuodong:DelOperateUI(self)
    self.m_IsEnd = true
    local oWorldMgr = global.oWorldMgr
    for pid,_ in pairs(self.m_Player) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            oHuodong:LeaveMatch(oPlayer)
        end
    end
end

function COperateUI:Finish()
    self.m_Finish = true
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equalarena")
    safe_call(oHuodong.OperateFinish,oHuodong,self)
    oHuodong:DelOperateUI(self)
end


function COperateUI:ReEnter(oPlayer)
    if self.m_Finish then
        return
    end
    if not self:InSelectState() then
        local mConfig = self:NowData()
        local iTime = math.max(mConfig["time"] - get_time() + self.m_StartTime,0)
        oPlayer:Send("GS2CConfigEqualArena",{ pinfo = self:PackConfigNet(oPlayer:GetPid()) ,left_time = iTime})
    else
        self:RefreshReady(oPlayer)
    end

end

function COperateUI:GetPlayerData(pid)
    return self.m_Player[pid]
end

function COperateUI:Opponent(pid)
    for target,mData in pairs(self.m_Player) do
        if pid ~= target then
            return mData
        end
    end
end


function COperateUI:NextOperate()
    if self.m_IsEnd then
        return
    end
    self.m_Step = self.m_Step + 1
    if self.m_Step > 6 then
        return
    end
    local oid = self.m_ID
    self.m_StartTime = get_time()
    self.m_OperateEnd = false
    local mData = self:NowData()
    self:DelTimeCb("NextOperate")
    if self:InSelectState() then
        self:RefreshReady()
    end
    if self.m_Step == 6 then
        self:TrimReadyData()
    end

    local iTime = mData["time"]
    if self:InSelectState() then
        iTime = iTime + 5
    end
    self:AddTimeCb("NextOperate",iTime*1000,function ()
        local oHuodog = global.oHuodongMgr:GetHuodong("equalarena")
        local obj = oHuodog:GetOperateUI(oid)
        if obj  then
            obj:NextOperate2()
        end
        end)
end

function COperateUI:NextOperate2()
    self:DelTimeCb("NextOperate")
    if self.m_Step <=5 and not self.m_OperateEnd then
        self:SelectOperate(1)
    elseif self.m_Step == 6 then
        self:AutoConfig()
    end
    self:NextOperate()
end


function COperateUI:OperateData()
    local res = require "base.res"
    return res["daobiao"]["huodong"]["equalarena"]["operate"]
end

function COperateUI:NowData(iStep)
    local mData = self:OperateData()
    iStep = iStep or self.m_Step
    return mData[self.m_Step]["data"]
end

function COperateUI:InSelectState()
    return self.m_Step < 6
end

function COperateUI:SelectOperate(iTimeOut)
    if not self:InSelectState() then
        return
    end
    local mPlayer
    for _,m in pairs(self.m_Player) do
        m["sync_select"] = nil
    end

    self:AutoSelect()

    for _,m in pairs(self.m_Player) do
        if m["operate"] then
            mPlayer = m
        end
    end
    mPlayer["operate"] = false
    local mTarget = self:Opponent(mPlayer["pid"])
    mTarget["operate"] = true
    self.m_OperateEnd = true
    if not iTimeOut then
        self:NextOperate2()
    end
end


function COperateUI:SetSelectPartner(oPlayer,iSelectPart)
    if not self:InSelectState() then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local iPid  = oPlayer:GetPid()
    local mPlayer  = self:GetPlayerData(iPid)
    assert(mPlayer,string.format("err equalarena SelectOperate %d",iPid))
    if not mPlayer["operate"] then
        return
    end
    local mLimit = self:NowData()
    local mPart = mPlayer["selectPartner"]
    if table_count(mPart) + 1 > mLimit["partner"]  then
        oNotifyMgr:Notify(iPid,"配置信息有误,请重新配置")
        return false
    end
    local oPartner = self.m_WareHouse["partner"][iSelectPart]
    if mPart[iSelectPart] or  not oPartner or oPartner:GetData("arena_lock") then
        oNotifyMgr:Notify(iPid,"配置信息有误,请重新配置")
        return
    end
    oPartner:SetData("arena_lock",true)
    mPart[iSelectPart] = true
    local mSHow = mPlayer["SW_Partner"] or {}
    table.insert(mSHow,iSelectPart)
    mPlayer["SW_Partner"] = mSHow
    return true
end


function COperateUI:CancelSelectPartner(oPlayer,iSelectPart)
    if not self:InSelectState() then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local iPid  = oPlayer:GetPid()
    local mPlayer  = self:GetPlayerData(iPid)
    assert(mPlayer,string.format("err equalarena SelectOperate %d",iPid))
    if not mPlayer["operate"] then
        return
    end
    local mPart = mPlayer["selectPartner"]
    local mSw = mPlayer["SW_Partner"] or {}
    if mPart[iSelectPart] then
        mPart[iSelectPart] = nil
        extend.Array.remove(mSw,iSelectPart)
        local oPartner = self.m_WareHouse["partner"][iSelectPart]
        if oPartner then
            oPartner:SetData("arena_lock",false)
        end
    end
end

function COperateUI:SetSelectItem(oPlayer,iItem)
    if not self:InSelectState() then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local iPid  = oPlayer:GetPid()
    local mPlayer  = self:GetPlayerData(iPid)
    assert(mPlayer,string.format("err equalarena SelectOperate %d",iPid))
    if not mPlayer["operate"] then
        return
    end
    local mLimit = self:NowData()
    local mItem = mPlayer["selectItem"]
    if table_count(mItem) + 1 > mLimit["equip"] then
        oNotifyMgr:Notify(iPid,"配置信息有误,请重新配置")
        return
    end
    local mWareItem = self.m_WareHouse["equip"][iItem]

    if mWareItem["arena_lock"] then
        oNotifyMgr:Notify(iPid,"配置信息有误,请重新配置")
        return
    end
    mWareItem["arena_lock"] = true
    mItem[iItem] = true
    local mSHow = mPlayer["SW_Item"] or {}
    table.insert(mSHow,iItem)
    mPlayer["SW_Item"] = mSHow
end

function COperateUI:CancelSelectItem(oPlayer,iItem)
    if not self:InSelectState() then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local iPid  = oPlayer:GetPid()
    local mPlayer  = self:GetPlayerData(iPid)
    assert(mPlayer,string.format("err equalarena SelectOperate %d",iPid))
    if not mPlayer["operate"] then
        return
    end
    local mItem = mPlayer["selectItem"]
    local mSw = mPlayer["SW_Item"] or {}
    local mWareItem = self.m_WareHouse["equip"][iItem]
    if mItem[iItem] then
        mItem[iItem] = nil
        extend.Array.remove(mSw,iItem)
        if mWareItem then
            mWareItem["arena_lock"] = false
        end
    end
end



function COperateUI:AutoSelect()
    if not self:InSelectState() or self.m_OperateEnd then
        return
    end
    local oWorldMgr = global.oWorldMgr

    local mPlayer
    for pid,m in pairs(self.m_Player) do
        if m["operate"] then
            mPlayer = m
        end
    end
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(mPlayer["pid"])
    if not oPlayer then
        record.warning(string.format("equalarena auto select not online %s",mPlayer["pid"]))
        self:Broken()
        return
    end

    local mPart = mPlayer["selectPartner"]
    local mItem = mPlayer["selectItem"]

    local mLimit = self:NowData()
    local iCntPartner = mLimit["partner"] - table_count(mPart)
    local iCntItem = mLimit["equip"] - table_count(mItem)
    local mPartherList = {}
    for idx,oPartner in ipairs(self.m_WareHouse["partner"]) do
        if not oPartner:GetData("arena_lock") then
            mPartherList[idx] = 1
        end
    end

    local mItemList = {}
    for idx,mItem in ipairs(self.m_WareHouse["equip"]) do
        if not mItem["arena_lock"] then
            mItemList[idx] = 1
        end
    end

    local mSelectPartner = {}
    for i =1,iCntPartner do
        local idx = table_choose_key(mPartherList)
        mPartherList[idx] = nil
        self:SetSelectPartner(oPlayer,idx)
    end

    local mSelectItem = {}
    for i =1,iCntItem do
        local idx = table_choose_key(mItemList)
        mItemList[idx] = nil
        self:SetSelectItem(oPlayer,idx)
    end
end


function COperateUI:TrimReadyData()
    local oWorldMgr = global.oWorldMgr
    local mPartner = self.m_WareHouse["partner"]
    local mEquip = self.m_WareHouse["equip"]
    self.m_WareHouse["partner"] = {}
    self.m_WareHouse["equip"] = {}
    for pid,mData in pairs(self.m_Player) do
        local mConfig = {}
        local mWareHouse = {
        partner = {},
        equip = {},
        }
        for idx,_ in pairs(mData["selectPartner"]) do
            table.insert(mWareHouse["partner"] ,mPartner[idx])
        end
        for idx,_ in pairs(mData["selectItem"]) do
            table.insert(mWareHouse["equip"] ,mEquip[idx])
        end
        local mMyPartner = mData["mypartner"]
        for _,mPar in pairs(mMyPartner) do
            local oPartner = self:CreatePartner(mPar["type"],mPar["awake"])
            table.insert(mWareHouse["partner"] ,oPartner)
        end
        mConfig["cache_setting"]={{1,2,3,4,},{1,2,3,4}}
        mConfig["warehouse"] = mWareHouse
        mData["config"] = mConfig
    end
    local mConfig = self:NowData()
    local iTime = math.max(mConfig["time"] - get_time() + self.m_StartTime,0)
    self:SendAll("GS2CConfigEqualArena",{ pinfo = self:PackConfigNet() ,left_time = iTime})

end




function COperateUI:ConfigOperate(oPlayer,parlist,equiplist,iType)
    if self:InSelectState() then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local iPid  = oPlayer:GetPid()
    local mPlayer  = self:GetPlayerData(iPid)
    assert(mPlayer,string.format("err equalarena ConfigOperate %d",iPid))
    local mConfig = mPlayer["config"]
    local mWareHouse = mConfig["warehouse"]

    if iType == 2 then
        if table_count(parlist) ~=4 or table_count(equiplist) ~=4 then
            oNotifyMgr:Notify(oPlayer:GetPid(),"配置信息有误,请重新配置")
            return
        end
        for idx,iPart in ipairs(parlist) do
            local iEquip = equiplist[idx]
            if not mWareHouse["partner"][iPart] or not mWareHouse["equip"][iEquip] then
                oNotifyMgr:Notify(oPlayer:GetPid(),"配置信息有误,请重新配置")
                return
            end
        end
        mConfig["cache_setting"] = {parlist,equiplist}
        oPlayer:Send("GS2CSyncConfig",{select_par=parlist,select_item=equiplist})
    else
        assert(mConfig["cache_setting"])
        local mSet = {}
        local parlist = mConfig["cache_setting"][1]
        local equiplist = mConfig["cache_setting"][2]
        for idx,iPart in ipairs(parlist) do
            local iEquip = equiplist[idx]
            mSet[iPart] = iEquip
        end
        mConfig["setting"] = mSet
        mConfig["cache_setting"] = nil
        local mTarget = self:Opponent(iPid)
        --StartWar
        self:SendAll("GS2CEqualArenaConfigDone",{pid = iPid})
        if mTarget["config"]["setting"] then
            self:Finish()
        end

    end

end

function COperateUI:AutoConfig()
    local oWorldMgr = global.oWorldMgr
    for pid,mData in pairs(self.m_Player) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        -- assert(oPlayer,string.format("equalarena autoconfig online %s",pid))
        if not oPlayer then
            self:Broken()
            return
        end
        if not mData["config"]["setting"] then
            self:ConfigOperate(oPlayer,{},{},1)
        end
    end
end

function COperateUI:PackConfigNet(iOwner)
    local f = function (pid,mPlayer)
        local mData = {
        info = mPlayer["info"],
        }
        local mConfig = mPlayer["config"]
        local mPartnerList = {}
        for _,oPartner in ipairs(mConfig["warehouse"]["partner"]) do
            table.insert(mPartnerList,oPartner:PackPartnerBase())
        end
        mData["select_partner"] = mPartnerList

        local mItem = {}
        for _,m in ipairs(mConfig["warehouse"]["equip"]) do
            table.insert(mItem,m["type"])
        end
        mData["select_fuwen"] = mItem
        local mSelect = {}
        local mSet = mConfig["cache_setting"] or {}
        for _,v in ipairs(mSet) do
            table.insert(mSelect,{partner=v[1],fuwen=v[2]})
        end
        mData["select"] = mSelect
        return mData
    end

    local mNet = {}
    for iPid,mPlayer in pairs(self.m_Player) do
        table.insert(mNet,f(iPid,mPlayer))
    end
    return mNet
end

function COperateUI:GetPartnerWarInfo()
    assert(not self:InSelectState(),"euqalarena err getanclean")
    local res = require "base.res"
    local mSetData =  res["daobiao"]["partner_item"]["soul_set"]
    local mData = {}

    for pid,mPlayer in pairs(self.m_Player) do
        local m = {pid=pid}
        local mSet = mPlayer["config"]["setting"]
        local mWareHouse = mPlayer["config"]["warehouse"]
        local mWarPartner = {}
        for iPar,iEquip in pairs(mSet) do
            local oPartner = mWareHouse["partner"][iPar]
            local mEquip = mWareHouse["equip"][iEquip]
            local mFuWen = mSetData[mEquip["type"]]
            local iSkill = mFuWen["skill"]
            local mSkill = oPartner:GetData("skill")
            table.insert(mSkill,{iSkill,1})
            oPartner:SetData("skill",mSkill)
            oPartner:SetInfo("pid",pid)
            oPartner:SetData("pos",iPar)
            table.insert(mWarPartner,oPartner)
        end
        m["war_partner"] = mWarPartner
        table.insert(mData,m)
    end
    return mData
end

function COperateUI:SyncSelectInfo(oPlayer,mData)
    local index = mData["index"]
    local mPlayer = self.m_Player[oPlayer:GetPid()]
    if not mPlayer["operate"] then
        return
    end
    if not mPlayer["sync_select"] then
        mPlayer["sync_select"] = {{},{}}
    end
    local mSelect = mPlayer["sync_select"][mData["select_type"]]
    if mData["handle_type"] == 1 and table_count(mSelect) >= 2 then
        return
    end
    local  mAddFunc = self.SetSelectPartner
    local mCancelFunc = self.CancelSelectPartner
    if mData["select_type"] == 2 then
        mAddFunc = self.SetSelectItem
        mCancelFunc = self.CancelSelectItem
    end

    if index>= 1 and index<=8 then
        if mData["handle_type"] == 1 then
            if not mSelect[index] and mAddFunc(self,oPlayer,index) then
                mSelect[index] = true
            end
        else
            mCancelFunc(self,oPlayer,index)
            mSelect[index] = nil
        end
    end

    local mNet = {
        operater = oPlayer:GetPid(),
        select_type = mData["select_type"],
        index = mData["index"],
        handle_type = mData["handle_type"],
        }
        self:SendAll("GS2CSyncSelectInfo",mNet)
end




--import module
local skynet = require "skynet"
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))
local serverinfo = import(lualib_path("public.serverinfo"))

local partnerctrl = import(service_path("playerctrl.partnerctrl"))
local loadskill = import(service_path("skill/loadskill"))
local huodongbase = import(service_path("kuafu.huodong.huodongbase"))
local warobj = import(service_path("kuafu.kfwarobj"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

--1:StartMatch
--2:StartWar
--3:StartOper

GAME_START = 1
GAME_OVER = 2

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "公平竞技"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_Status = GAME_OVER
    o.m_OPidx  = 0
    o.m_OperateList = {}
    o.m_WaitIdx = 0
    o.m_WaitFight = {}
    o.m_Unit = {}
    o.m_CheckList = {}
    o.m_GameTime = 2*3600
    return o
end


function CHuodong:Init()
    if global.oHuodongMgr.m_WarNo == 1 then
        self:DelTimeCb("AutoSyncState")
        local f = function ()
            self:AutoSyncState()
        end
        self:AddTimeCb("AutoSyncState",60*1000,f)
    end
end


function CHuodong:GetServerList()
    return serverinfo.get_gs_list()
end



function CHuodong:AutoSyncState()
    self:DelTimeCb("CheckStateFinish")
    self:DelTimeCb("AutoSyncState")
    local f = function ()
        self:AutoSyncState()
    end
    self:AddTimeCb("AutoSyncState",60*1000,f)
    self.m_CheckList = {}
    self:SyncGameState()
end

function CHuodong:SyncGameState()
    local oHuodongMgr = global.oHuodongMgr
    local m = oHuodongMgr:GetHuodong("equalarena")

    local iState = self.m_Status
    local svrlist = self:GetServerList()
    local oKFMgr = global.oKFMgr

    if table_count(self.m_CheckList) > 0 then
        for k,v in pairs(self.m_CheckList) do
            record.error(string.format("check  game state exist %s %s",k,v))
        end
    end

    local fcallback = function (mRecord,mData)
        local svr = mRecord.srcsk
        if  self.m_CheckList[svr] then
            self.m_CheckList[svr] = nil
        end
    end

    self.m_CheckList = {}
    for _,svr in ipairs(svrlist) do
        self.m_CheckList[svr] = iState
        local fcallback = function (mRecord,mData)
                self.m_CheckList[svr] = nil
        end
        oKFMgr:Send2GSHuoDong(svr,"CmdSyncState","equalarena",{status=iState},fcallback)
    end
    local func = function ()
        self:CheckStateFinish()
    end
    self:DelTimeCb("CheckStateFinish")
    self:AddTimeCb("CheckStateFinish",10*1000,func)
end

function CHuodong:CheckStateFinish()
    self:DelTimeCb("CheckStateFinish")
    if table_count(self.m_CheckList) > 0 then
        for k,v in pairs(self.m_CheckList) do
            record.error(string.format("sync game state %s %s",k,v))
        end
    end
end

function CHuodong:SendMatch(sFun,mData,backfunc)
    if not self:InHuodongTime() then
        return
    end
    mData.name = "equalarena"
    if not backfunc then
        interactive.Send(".recommend","match",sFun,mData)
    else
        mData.respond = 1
        interactive.Request(".recommend","match",sFun,mData,backfunc)
    end
end


function CHuodong:InHuodongTime()
    return self.m_Status == GAME_START
end

function CHuodong:OnLogin(oPlayer,reenter)
    local oOperate = self:GetOperateUIByPlayer(oPlayer)
    if oOperate then
        oOperate:ReEnter(oPlayer)
    end
end

function CHuodong:GameStart()
    if self:InHuodongTime() then
        return
    end
    record.info("master - equalarena game start")
    self.m_Status = GAME_START
    self.m_GameStart = get_time()
    self:SendMatch("CleanCach",{})
    self:SendMatch("StartMatch",{data={time=500,limit=50}})
    self:AutoSyncState()
    self:DelTimeCb("GameOver")
    self:AddTimeCb("GameOver",self.m_GameTime * 1000,function ()
        self:GameOver()
        end)
end

function CHuodong:GameOver()
    if not self:InHuodongTime() then
        return
    end
    record.info("master equalarena game over")
    self.m_Status = GAME_OVER
    self:AutoSyncState()
    self:SendMatch("CleanCach",{})
    self:SendMatch("StopMatch",{})
end


function CHuodong:KFCmd(oKFPlayer,mData)
    local cmd = mData["cmd"]
    local sFunList = {"SelectOperate","ConfigArena","SyncSelectInfo"}
    if cmd == "Delete" then
        self:SendMatch("LeaveMatch",{id=oKFPlayer:GetPid(),})
    elseif table_in_list(sFunList,cmd) then
        self[cmd](self,oKFPlayer,table.unpack(mData["args"]))
    end
end


function CHuodong:KFJoinGame(oKFPlayer)
    local m = oKFPlayer:ExtraData()
    oKFPlayer:Notify("进入匹配")
    self:SendMatch("EnterMatch",{id=oKFPlayer:GetPid(),data={score =m["score"],stage =m["stage"],pid=oKFPlayer:GetPid()}})
    return {}
end


function CHuodong:SelectOperate(oPlayer,iSelectPart,iItemList)
    if not self:InHuodongTime() then
        return
    end
    local oOperate = self:GetOperateUI(oPlayer.m_EqualArenaOperate)
    if oOperate then
        local mPlayer = oOperate.m_Player[oPlayer:GetPid()]
        if mPlayer and mPlayer["operate"] then
            oOperate:SelectOperate()
        end
    end
end


function CHuodong:ConfigArena(oPlayer,iSelectPart,iItemList,iType)
    if not self:InHuodongTime() then
        return
    end
    local oOperate = self:GetOperateUI(oPlayer.m_EqualArenaOperate)
    if oOperate then
        oOperate:ConfigOperate(oPlayer,iSelectPart,iItemList,iType or 1)
    end
end

function CHuodong:SyncSelectInfo(oPlayer,mData)
    if not self:InHuodongTime() then
        return
    end
    local oOperate = self:GetOperateUI(oPlayer.m_EqualArenaOperate)
    if oOperate then
        oOperate:SyncSelectInfo(oPlayer,mData)
    end
end


function CHuodong:GetOperateUIByPlayer(oKFPlayer)
    if oKFPlayer.m_EqualArenaOperate then
        return self:GetOperateUI(oKFPlayer.m_EqualArenaOperate)
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


function CHuodong:_CheckInMatch(oPlayer,iLeave,sNotify)
    local oNotify = global.oNotifyMgr
    if iLeave == 1 then
        self:SendMatch("LeaveMatch",{id=oPlayer:GetPid(),})
        self:ClientStartMath(oPlayer,0)
    end
    if sNotify and sNotify~="" then
         oNotify:Notify(oPlayer:GetPid(),sNotify)
    end
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
    local oNotify = global.oNotifyMgr
    local oWarMgr = global.oWarMgr
    for _,mFight in pairs(fightlist) do
        self:ReadyStartOperate(mFight[1],mFight[2])
    end
end

function CHuodong:ClientStartMath(oPlayer,iResult)
    oPlayer:Send("GS2CEqualArenaStartMath",{result=iResult})
end


function CHuodong:ReadyStartOperate(iTarget1,iTarget2)
    local oKFMgr = global.oKFMgr
    local oWarMgr = global.oWarMgr
    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)
    local bStartFight = self:CheckGame(iTarget1,iTarget2)
    if oTarget1 then
        oTarget1:SendEvent("CleanFlag",{})
        self:_CheckInMatch(oTarget1,0)
    end
    if oTarget2 then
        oTarget2:SendEvent("CleanFlag",{})
        self:_CheckInMatch(oTarget2,0)
    end

    if not bStartFight then
        if oTarget1 then
            self:ErrorQuitGame(oTarget1)
        end
        if oTarget2 then
            self:ErrorQuitGame(oTarget2)
        end
        return
    end

    oTarget1.m_InEqualArenaGame = {target = iTarget2}
    oTarget2.m_InEqualArenaGame = {target = iTarget1}
    self:RefreshReadyUI(oTarget1,iTarget2)
    self:RefreshReadyUI(oTarget2,iTarget1)
end

function CHuodong:RefreshReadyUI(oPlayer,iTarget,mPack)
    local oKFMgr = global.oKFMgr
    local pid = oPlayer:GetPid()
    oPlayer:DelTimeCb("arena_CheckReady")
    oPlayer:AddTimeCb("arena_CheckReady", 3*1000,function ()
    local oPlayer = oKFMgr:GetObject(pid)
    if oPlayer then
        self:_CheckReadyStatus(oPlayer)
    end
    end)
    if not mPack then
        local oTarget = oKFMgr:GetObject(iTarget)
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


function CHuodong:_CheckReadyStatus(oPlayer)
    oPlayer:DelTimeCb("arena_CheckReady")
    local oKFMgr = global.oKFMgr
    if oPlayer.m_InEqualArenaGame then
        local iTarget = oPlayer.m_InEqualArenaGame.target or 0
        local oTarget = oKFMgr:GetObject(iTarget)
        if oTarget then
            oTarget:DelTimeCb("arena_CheckReady")
        end
        self:IntoOperate(oPlayer:GetPid(),iTarget)
    end
end

function CHuodong:ArenaScore(oPlayer)
    local mExtra = oPlayer:ExtraData()
    return mExtra["score"] or 1000
end

function CHuodong:PackRankInfo(oPlayer)
    local mExtra = oPlayer:ExtraData()
    return {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        shape = oPlayer:GetModelInfo().shape,
        rank = 0,
        point = self:ArenaScore(oPlayer),
        praise = 0,
        }
end

function CHuodong:IntoOperate(iTarget1,iTarget2)
    local oKFMgr = global.oKFMgr
    local mParlist = {}
    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)
    local bStartFight = self:CheckGame(iTarget1,iTarget2)
    if not bStartFight then
        return
    end
    local mExtra1 = oTarget1:ExtraData()
    local mExtra2 = oTarget2:ExtraData()
    mParlist[oTarget1:GetPid()] = mExtra1["partner"]
    mParlist[oTarget2:GetPid()] = mExtra2["partner"]
    self:IntoOperate2(iTarget1,iTarget2,mParlist)

end


function CHuodong:IntoOperate2(iTarget1,iTarget2,parlist)
    local oKFMgr = global.oKFMgr

    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)

    if table_count(parlist[iTarget1]) ~= 2 or table_count(parlist[iTarget2]) ~= 2 then
        if oTarget1 then
            oTarget1.m_InEqualArenaGame = nil
            self:ClientStartMath(oTarget1,0)
        end
        if oTarget2 then
            oTarget2.m_InEqualArenaGame = nil
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

function CHuodong:CheckGame(iTarget1,iTarget2)
    return true
end

function CHuodong:OperateFinish(oOperate)
    local oKFMgr = global.oKFMgr
    local oNotify = global.oNotifyMgr
    local oWarMgr = global.oWarMgr

    local mFight = oOperate:GetPartnerWarInfo()
    local mTarget1 = mFight[1]
    local mTarget2 = mFight[2]
    local iTarget1 = mTarget1["pid"]
    local iTarget2 = mTarget2["pid"]


    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)

    local bStartFight = self:CheckGame(iTarget1,iTarget2,true)
    if bStartFight then
        self:_CheckInMatch(oTarget1,0)
        self:_CheckInMatch(oTarget2,0)
        oTarget1.m_InEqualArenaGame = {target = iTarget2}
        oTarget2.m_InEqualArenaGame = {target = iTarget1}
       self:StartPVPWar(mTarget1,mTarget2)
    end

end

function CHuodong:ErrorQuitGame(oKFPlayer)
    oKFPlayer:SendEvent("RequestToDelete",{code=1})
end

function CHuodong:ArenaScore(oKFPlayer)
    local mExtra = oKFPlayer:ExtraData()
    return mExtra["score"] or 1000
end

function CHuodong:StartPVPWar(mTarget1,mTarget2)
    local oKFMgr = global.oKFMgr
    local oWarMgr = global.oWarMgr
    local iTarget1 = mTarget1["pid"]
    local iTarget2 = mTarget2["pid"]
    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)
    if not oTarget1 or not oTarget2 then
        if oTarget1 then
            self:ErrorQuitGame(oTarget1)
        end
        if oTarget2 then
            self:ErrorQuitGame(oTarget2)
        end
    end

    if oTarget1:GetNowWar() or oTarget2:GetNowWar() then
        if not oTarget1:GetNowWar() then
            self:ErrorQuitGame(oTarget1)
        end
        if not oTarget2:GetNowWar() then
            self:ErrorQuitGame(oTarget2)
        end
    end

    local iScore1 = self:ArenaScore(oTarget1)
    local iScore2 = self:ArenaScore(oTarget2)
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

    local mArg = {
        remote_war_type="kfequalarena",
        war_type = gamedefines.WAR_TYPE.EQUAL_ARENA,
        remote_args = self:GetRemoteWarArg(),
        pvpflag = 1,
        }

    local mExtra1 = oTarget1:ExtraData()
    local mExtra2 = oTarget2:ExtraData()

    local mEnterWarArg = mExtra1.warinfo
    local mEnterWarArg2 = mExtra2.warinfo
    local oWar = self:CreateWar(mArg)
    oWar:SetData("close_auto_skill",true)
    local iWarID = oWar:GetWarId()
    oWar.m_WarRecord = {fight = mWarRecord}
    oWarMgr:SetWarEndCallback(iWarID,function (mArgs)
        local oWar = oWarMgr:GetWar(iWarID)
        safe_call(self.OnPVPWarEnd,self,oWar,iTarget1,iTarget2,iScore1,iScore2,mArgs)
        local oTarget1 = oKFMgr:GetObject(iTarget1)
        local oTarget2 = oKFMgr:GetObject(iTarget2)
        if oTarget1 then
            oTarget1:SendEvent("RequestToDelete",{code=0})
        end
        if oTarget2 then
            oTarget2:SendEvent("RequestToDelete",{code=0})
        end
        end)

    mEnterWarArg.camp_id = 1
    mEnterWarArg2.camp_id = 2
    local mArg = {
        camp_id = 1,
        FightPartner = mTarget1["war_partner"],
        CurrentPartner = mTarget1["war_partner"][1],
        }

    oWarMgr:EnterWar(oTarget1, iWarID, mArg, true)
    mArg = {
        camp_id = 2,
        FightPartner = mTarget2["war_partner"],
        CurrentPartner = mTarget2["war_partner"][1],
        }
    oWarMgr:EnterWar(oTarget2,iWarID,mArg, true)
    oWarMgr:StartWar(iWarID)

    global.oKFMgr:Send2GSWorld(iTarget1,"EnsureEnterWar",
        {pid=iTarget1,name="kfequalarena",remotewarid=oWar:GetWarId(),remoteaddr=oWar:GetRemoteAddr()})
    global.oKFMgr:Send2GSWorld(iTarget2,"EnsureEnterWar",
        {pid=iTarget2,name="kfequalarena",remotewarid=oWar:GetWarId(),remoteaddr=oWar:GetRemoteAddr()})
end

--录像table太大，导致GS垃圾内存暴增，屏蔽
function CHuodong:GetRemoteWarArg()
    --return {war_record=1}
    return {}
end


function CHuodong:OnPVPWarEnd(oWar,iTarget1,iTarget2,iScore1,iScore2,mArg)
    local oKFMgr = global.oKFMgr
    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)
    local iRewardScore = self:ScoreCalculator(iScore1,iScore2)
    local mRecord = oWar.m_WarRecord
    local iBout = mArg["bout"] or 0
    local mFight = mRecord.fight
    local unit1 = mFight[iTarget1]
    local unit2 = mFight[iTarget2]
    unit1.score = iRewardScore
    unit2.score = iRewardScore
    --mRecord.fid = mArg.war_film_id
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
        iLogPScore1 = 1 + iLogScore1
    end


    if oTarget2 then
        sName2 = oTarget2:GetName()
        iLogPScore2 = 1 + iLogScore2
    end
    mRecord["camp"] = {iTarget1,iTarget2}

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

    record.user("equalarena","end_arena",mLog)

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

    self:Dirty()
    --录像table太大，导致GS垃圾内存暴增，屏蔽
    --self:SendWarFilm(iTarget1,iTarget2,oWar,mRecord,mArg)
end


function CHuodong:RewardArenaMedal(oKFPlayer,bWin)
    local mData = self:ArenaData()
    local iLa = self:ArenaStage(0)
    local mInfo = mData[iLa]
    local iWeek = mInfo.weeky_limit
    local iRewardPoint = mInfo.award_per_game
    local mExtra = oKFPlayer:ExtraData()
    local iNow = mExtra["week_medel"]
    if not bWin then
        iRewardPoint = iRewardPoint//2
    end
    if iNow < iWeek then
        local iMin = math.min(iWeek-iNow,iRewardPoint)
        return iMin
    end
    return 0
end

function CHuodong:RewardWin(oKFPlayer,iRewardScore,iTarget,mRecord,mResultData)
    local iMedal  = self:RewardArenaMedal(oKFPlayer,true)
    self:SendWarResult(oKFPlayer,iRewardScore,iMedal,mResultData)
    self:SendWarEndReward(oKFPlayer,iRewardScore,iMedal,1,mResultData)
end


function CHuodong:RewardFail(oKFPlayer,iSubScore,iTarget,mRecord,bReward,mResultData)
    local iMedal = 0
    if bReward then
        iMedal = self:RewardArenaMedal(oKFPlayer,false)
    end
    self:SendWarResult(oKFPlayer,iSubScore,iMedal,mResultData)
    self:SendWarEndReward(oKFPlayer,iSubScore,iMedal,0,mResultData)
end


function CHuodong:SendWarResult(oPlayer,iScore,iMedal,mResultData)
    local mExtra = oPlayer:ExtraData()
    local mNet = {
            point = iScore,
            medal = iMedal,
            result = mResultData["win"],
            info = mResultData["data"],
            weeky_medal = mExtra["week_medel"] or 0,
            currentpoint = self:ArenaScore(oPlayer),
        }
    oPlayer:Send("GS2CEqualArenaFightResult",mNet)
end


function CHuodong:SendWarEndReward(oPlayer,iScore,iMedal,iWin,mResultData)
    local m = {
        medal = iMedal,
        score = iScore,
        info = mResultData["data"],
        win = iWin,
    }
    oPlayer:SendEvent("WarEndReward",m)
end

function CHuodong:SendWarFilm(iTarget1,iTarget2,oWar,mRecord,mArg)
    local m = {
        record = mRecord,
        plist = {iTarget1,iTarget2},
        filmdata = mArg["war_film_data"],
        war_type = oWar.m_iWarType,
        bout = mArg["bout"],
        }

    local oKFMgr = global.oKFMgr
    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)
    local svrlist = {}
    if oTarget1 then
        table.insert(svrlist,oTarget1.m_Where)
    end
    if oTarget2 and not table_in_list(svrlist,oTarget2.m_Where) then
        table.insert(svrlist,oTarget2.m_Where)
    end
    local oKFMgr = global.oKFMgr
    for _,svr in ipairs(svrlist) do
        oKFMgr:Send2GSHuoDong(svr,"RecordWarFilm","equalarena",m)
    end
end



function CHuodong:CreateWar(mInfo)
    local oWarMgr = global.oWarMgr
    local id = oWarMgr:DispatchSceneId()
    local oWar = CMyWar:New(id, mInfo)
    oWar:ConfirmRemote()
    oWarMgr.m_mWars[id] = oWar
    return oWar
end


function CHuodong:TestKFOP(iFlag,args)
    local mRe = {ok=1}
    if iFlag == 103 then
        if not self:InHuodongTime() then
            self:GameStart()
        else
            self:GameOver()
        end
    elseif iFlag == 118 then
        local oKFMgr = global.oKFMgr
        local oWarMgr = global.oWarMgr
        local oProxyWarMgr = global.oProxyWarMgr
        local iPCnt  = table_count(self.m_OperateList)
        local iWarCnt = table_count(oProxyWarMgr.m_mWars)
        local iProxyCnt = table_count(oKFMgr.m_ObjectList)
        local msg = string.format("战斗对象:%s 正在操作:%s 代理对象:%s",iWarCnt,iPCnt,iProxyCnt)
        print(msg)
    elseif iFlag == 121 then
        if not self:InHuodongTime() then
            self:GameStart()
        end
    elseif iFlag == 100004 then
        local oWarMgr = global.oWarMgr
        for k,iAddr in pairs(oWarMgr:GetRemoteAddr()) do
            interactive.Send(iAddr, "war", "TestCmd", {pid = 0, war_id = 0, cmd = "ShowWarInfo", data = {}})
        end
    end
    return mRe
end

CMyWar = {}
CMyWar.__index = CMyWar
inherit(CMyWar, warobj.CWar)

function CMyWar:PackPlayerWarInfo(oPlayer)
    local mWar = oPlayer:PackWarInfo()
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
    mRet.is_team_leader = false
    mRet.team_size = 0
    mRet.auto_skill = mWar["auto_skill"]
    mRet.auto_skill_switch = mWar["auto_skill_switch"]
    mRet.protectors = mWar["protectors"]
    mRet.double_attack_suspend = mWar["double_attack_suspend"]
    mRet.systemsetting = mWar["systemsetting"]
    mRet.testman = mWar["testman"]
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
    return mData
end

function COperateUI:SendAll(msg,mNet)
    local oKFMgr = global.oKFMgr
    for pid,_ in pairs(self.m_Player) do
        local oPlayer = oKFMgr:GetObject(pid)
        if oPlayer then
            oPlayer:Send(msg,mNet)
        end
    end
end

function COperateUI:Release()
    local oKFMgr = global.oKFMgr
    self:DelTimeCb("NextOperate")
    for pid,mPlayer in pairs(self.m_Player) do
        if mPlayer["config"]  and mPlayer["config"]["partner"] then
            for _,oPartner in ipairs(mPlayer["config"]["partner"]) do
                baseobj_safe_release(oPartner)
            end
        end
        local oPlayer = oKFMgr:GetObject(pid)
        if oPlayer and oPlayer.m_EqualArenaOperate == self.m_ID then
            oPlayer.m_EqualArenaOperate = nil
        end
    end
    for idx,oPernter in ipairs(self.m_WareHouse["partner"]) do
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
    local oHuodog = global.oHuodongMgr:GetHuodong("equalarena")
    self:SendAll("GS2CCloseEqualArenaUI",{})
    oHuodog:DelOperateUI(self)

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
    local oKFMgr = global.oKFMgr

    local mPlayer
    for pid,m in pairs(self.m_Player) do
        if m["operate"] then
            mPlayer = m
        end
    end
    local oPlayer = oKFMgr:GetObject(mPlayer["pid"])
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
    local oKFMgr = global.oKFMgr
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
    local oKFMgr = global.oKFMgr
    for pid,mData in pairs(self.m_Player) do
        local oPlayer = oKFMgr:GetObject(pid)
        assert(oPlayer,string.format("equalarena autoconfig online %s",pid))
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





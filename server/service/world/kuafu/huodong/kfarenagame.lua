--import module
local skynet = require "skynet"
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("kuafu.huodong.huodongbase"))
local loaditem = import(service_path("item/loaditem"))
local analy = import(lualib_path("public.dataanaly"))
local serverinfo = import(lualib_path("public.serverinfo"))
local warobj = import(service_path("kuafu.kfwarobj"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "比武场"
inherit(CHuodong, huodongbase.CHuodong)

GAME_START = 1
GAME_OVER = 2

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_Status = GAME_OVER
    o.m_TopRecord = {}  -- 对战记录
    o.m_ArenaTime = 1*3600
    return o
end

function CHuodong:Init()
    if global.oHuodongMgr.m_WarNo == 2 then
        self:DelTimeCb("AutoSyncState")
        local f = function ()
            self:AutoSyncState()
        end
        self:AddTimeCb("AutoSyncState",60*1000,f)
    end
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

function CHuodong:GetServerList()
    return serverinfo.get_gs_list()
end

function CHuodong:SyncGameState()
    local iState = self.m_Status
    local lServer = self:GetServerList()
    local oKFMgr = global.oKFMgr

    self.m_CheckList = {}
    for _,sServerKey in ipairs(lServer) do
        self.m_CheckList[sServerKey] = iState
        local fcallback = function (mRecord,mData)
                self.m_CheckList[sServerKey] = nil
        end
        oKFMgr:Send2GSHuoDong(sServerKey,"CmdSyncState","arenagame",{status=iState},fcallback)
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
            record.error(string.format("sync kfarenagame game state %s %s",k,v))
        end
    end
end


function CHuodong:InHuodongTime()
    return self.m_Status == GAME_START
end

function CHuodong:SendMatch(sFun,mData,backfunc)
    if not self:InHuodongTime() then
        return
    end
    mData.name = "arenagame"
    if not backfunc then
        interactive.Send(".recommend","match",sFun,mData)
    else
        mData.respond = 1
        interactive.Request(".recommend","match",sFun,mData,backfunc)
    end
end

function CHuodong:GameStart()
    if self:InHuodongTime() then
        return
    end
    record.info("master - arenagame game start")
    self.m_Status = GAME_START
    self.m_GameStart = get_time()
    self:SendMatch("CleanCach",{})
    self:SendMatch("StartMatch",{data={time=500,limit=50}})
    self:AutoSyncState()
    self:DelTimeCb("GameOver")
    self:AddTimeCb("GameOver",self.m_ArenaTime * 1000,function ()
        self:GameOver()
    end)
end

function CHuodong:GameOver()
    if not self:InHuodongTime() then
        return
    end
    record.info("master arenagame game over")
    self.m_Status = GAME_OVER
    self:AutoSyncState()
    self:SendMatch("CleanCach",{})
    self:SendMatch("StopMatch",{})
end

function CHuodong:KFJoinGame(oKFPlayer)
    local m = oKFPlayer:ExtraData()
    local mArena = m.arena or {}
    local iScore = m.score or 0
    local iPlay = mArena.play or 0

    oKFPlayer:Notify("进入匹配")
    if iPlay < 1 then
        self:ClientStartMath(oKFPlayer,1)
        self:ReadyRobotWar(oKFPlayer)
        return {}
    end

    self:SendMatch("EnterMatch",{id=oKFPlayer:GetPid(),data={score =m["score"],stage =m["stage"],pid=oKFPlayer:GetPid()}})
    return {}
end

function CHuodong:MatchResult(fightlist,mInfo)
    for _,mFight in pairs(fightlist) do
        self:ReadyPVPWar(mFight[1],mFight[2])
    end
end

function CHuodong:ClientStartMath(oPlayer,iResult)
    oPlayer:Send("GS2CArenaStartMath",{result=iResult})
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

function CHuodong:ReadyPVPWar(iTarget1,iTarget2)
    local oKFMgr = global.oKFMgr
    local oNotify = global.oNotifyMgr
    local oWarMgr = global.oWarMgr

    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)
    local bStartFight = true
    if oTarget1 then
        oTarget1:SendEvent("CleanFlag",{})
        self:_CheckInMatch(oTarget1,0)
    end
    if oTarget2 then
        oTarget2:SendEvent("CleanFlag",{})
        self:_CheckInMatch(oTarget2,0)
    end
    if bStartFight then
        oTarget1.m_InArenaGame = {target = iTarget2}
        oTarget2.m_InArenaGame = {target = iTarget1}
        self:RefreshReadyUI(oTarget1,iTarget2)
        self:RefreshReadyUI(oTarget2,iTarget1)
    else
        if oTarget1 then self:ClientStartMath(oTarget1,0) end
        if oTarget2 then self:ClientStartMath(oTarget2,0) end
    end
end

function CHuodong:ArenaScore(oPlayer)
    local mExtra = oPlayer:ExtraData()
    return mExtra["score"] or 1000
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
            oPlayer:Send("GS2CArenaMatch",mNet)
        end
    else
        oPlayer:Send("GS2CArenaMatch",{rankInfo=mPack})
    end
end

function CHuodong:_CheckReadyStatus(oPlayer)
    oPlayer:DelTimeCb("arena_CheckReady")
    local oKFMgr = global.oKFMgr
    if oPlayer.m_InArenaGame then
        local iTarget = oPlayer.m_InArenaGame.target or 0
        local oTarget = oKFMgr:GetObject(iTarget)
        if oTarget then
            oTarget:DelTimeCb("arena_CheckReady")
        end
        if oPlayer.m_InArenaGame.robot then
            self:StartRobotWar(oPlayer)
        else
            self:StartPVPWar(oPlayer:GetPid(),iTarget)
        end
    end
end

function CHuodong:StartPVPWar(iTarget1,iTarget2)
    local oKFMgr = global.oKFMgr
    local oWarMgr = global.oWarMgr

    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)
    local bStartFight = true
    if oTarget1:GetNowWar()  then
        bStartFight = false
    end
    if oTarget2:GetNowWar() then
        bStartFight = false
    end

    if bStartFight then
        local iGameTarget1 = oTarget1.m_InArenaGame.target
        local iGameTarget2 = oTarget2.m_InArenaGame.target
        if iGameTarget1 ~= iTarget2 then
            bStartFight = false
        end
        if iGameTarget2 ~= iTarget1 then
            bStartFight = false
        end
    end
    if bStartFight then
        local mArg = {
            remote_war_type="kfarenagame",
            war_type = gamedefines.WAR_TYPE.ARENA_TYPE,
            -- remote_args = { war_record = 1},
            pvpflag = 1,
        }
        local oWar = oWarMgr:CreateWar(mArg)
        oWar:SetData("close_auto_skill",true)

        local iScore1 = self:ArenaScore(oTarget1)
        local iScore2 = self:ArenaScore(oTarget2)
        oTarget1.m_InArenaGame = nil
        oTarget2.m_InArenaGame = nil

        local mExtra1 = oTarget1:ExtraData()
        local mExtra2 = oTarget2:ExtraData()

        oTarget1:Send("GS2CArenaFight",{})
        oTarget2:Send("GS2CArenaFight",{})

        local mWarRecord = {}
        local mUint1 = {
            name = oTarget1:GetName(),
            point = iScore1,
            partner = {},
            grade = oTarget1:GetGrade(),
            shape = oTarget1:GetModelInfo().shape,
        }
        mWarRecord[db_key(oTarget1:GetPid())] = mUint1
        local mUint2 = {
            pid = oTarget2:GetPid(),
            name = oTarget2:GetName(),
            point = iScore2,
            partner = {},
            grade = oTarget2:GetGrade(),
            shape = oTarget2:GetModelInfo().shape,
        }
        mWarRecord[db_key(oTarget2:GetPid())] = mUint2

        local mArenaData1 = mExtra1.arena
        local mArenaData2 = mExtra2.arena

        local iCnt1 = (mArenaData1.play or 0) + 1
        local iCnt2 = (mArenaData2.play or 0) + 1

        local mLog = {
            pid1 = oTarget1:GetPid(),
            point1 = iScore1,
            name1 = oTarget1:GetName(),
            count1 = iCnt1,

            pid2 = oTarget2:GetPid(),
            point2 = iScore2,
            name2 = oTarget2:GetName(),
            count2 = iCnt2,
        }

        local mPartnerInfo1 = oTarget1:GetPartnerInfo()
        local mPartnerInfo2 = oTarget2:GetPartnerInfo()
        local mArg = {
            camp_id = 1,
            FightPartner = mPartnerInfo1,
            CurrentPartner = mPartnerInfo1[1],
        }
        local iWarID = oWar:GetWarId()
        oWarMgr:EnterWar(oTarget1, iWarID, mArg, true)

        mArg = {
            camp_id = 2,
            FightPartner = mPartnerInfo2,
            CurrentPartner = mPartnerInfo2[1],
        }
        oWarMgr:EnterWar(oTarget2, iWarID, mArg, true)
        oWar.m_WarRecord = {fight = mWarRecord}

        oWarMgr:SetWarEndCallback(iWarID,function (mArg)
            local oWar = oWarMgr:GetWar(iWarID)
            safe_call(self.OnPVPWarEnd,self,oWar,iTarget1,iTarget2,iScore1,iScore2,mArg)
        end)
        oWarMgr:StartWarConfig(iWarID)
        local mOther = {log=mLog}
        oTarget1:SendEvent("OnPvPWarStart")
        oTarget1:Send2Huodong("RecordLog",{name="start_pvp",log=mLog})
        oTarget2:SendEvent("OnPvPWarStart")
        if oTarget1:GetServerKey() ~= oTarget2:GetServerKey() then
            oTarget2:Send2Huodong("RecordLog",{name="start_pvp",log=mLog})
        end

        global.oKFMgr:Send2GSWorld(iTarget1,"EnsureEnterWar",
        {pid=iTarget1,name="kfarenagame",remotewarid=oWar:GetWarId(),remoteaddr=oWar:GetRemoteAddr()})
        global.oKFMgr:Send2GSWorld(iTarget2,"EnsureEnterWar",
        {pid=iTarget2,name="kfarenagame",remotewarid=oWar:GetWarId(),remoteaddr=oWar:GetRemoteAddr()})
    else
        if oTarget1 then
            self:ClientStartMath(oTarget1,0)
            oTarget1.m_InArenaGame = nil
        end
        if oTarget2 then
             self:ClientStartMath(oTarget2,0)
             oTarget2.m_InArenaGame = nil
        end
    end
end

function CHuodong:ArenaData()
    local res = require "base.res"
    return res["daobiao"]["arena"]["arena"]
end

function CHuodong:ArenaStage(iScore)
    local mData = self:ArenaData()
    for i=#mData,1,-1 do
        local mInfo = mData[i]
        if iScore >= mInfo.basescore then
            return mInfo["id"]
        end
    end
    return 1
end

-- ELO - (para[min(La,Lb)]*(if(a取胜?1;0)-1/(1+10^((Tb-Ta)/400)),0)
-- Ta is Winner
function CHuodong:ScoreCalculator(iTa,iTb,iWin)
    local mData = self:ArenaData()
    local iLa = self:ArenaStage(iTa)
    local iLb = self:ArenaStage(iTb)
    local iPara = mData[math.min(iLa,iLb)]["para"]
    local fY=1/(1+10^((iTb-iTa)/400))
    if iWin == 1 then
        fY = 1 - fY
    end
    -- 目前双方增减积分相同
    local fA = iPara*fY
    if fA%1 > 0.5 then
        fA = fA +1
    end
    local iA = math.max(math.floor(fA),0)
    return iA,iA
end

function CHuodong:OnPVPWarEnd(oWar,iTarget1,iTarget2,iScore1,iScore2,mArg)
    local oKFMgr = global.oKFMgr
    local oTarget1 = oKFMgr:GetObject(iTarget1)
    local oTarget2 = oKFMgr:GetObject(iTarget2)

    local iRewardScore,iSubScore = self:ScoreCalculator(iScore1,iScore2,mArg.win_side)

    local mRecord = oWar.m_WarRecord
    local iBout = mArg["bout"] or 0
    local mFight = mRecord.fight
    local unit1 = mFight[db_key(iTarget1)]
    local unit2 = mFight[db_key(iTarget2)]
    unit1.score = iRewardScore
    unit2.score = iSubScore

    -- mRecord.fid = mArg.war_film_id
    local mFightPartner = mArg.arena_partner
    local mPar1 = mFightPartner[iTarget1] or {}
    unit1.partner = mPar1
    local mPar2 = mFightPartner[iTarget2] or {}
    unit2.partner = mPar2

    local iLogScore1
    local iLogScore2

    local mResultData = {win = mArg.win_side}

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

    mRecord["camp"] = {iTarget1,iTarget2}
    if oTarget1 then
        sName1 = oTarget1:GetName()
        iLogPScore1 = self:ArenaScore(oTarget1) + iLogScore1
    end

    if oTarget2 then
        sName2 = oTarget2:GetName()
        iLogPScore2 = self:ArenaScore(oTarget2) + iLogScore2
    end

    mResultData["data"] = {}
    table.insert(mResultData["data"],{pid = iTarget1,name =unit1["name"],shape=unit1["shape"],camp=1})
    table.insert(mResultData["data"],{pid = iTarget2,name =unit2["name"],shape=unit2["shape"],camp=2})

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
    -- if iBout > 3 then
    --     self:CollectWarRecord(mRecord)
    -- end

    if mArg.win_side ==1 then
        if oTarget1 then self:RewardWin(oTarget1,iRewardScore,iTarget2,mResultData) end
        if oTarget2 then self:RewardFail(oTarget2,iSubScore,iTarget1,mResultData) end
    else
        if oTarget2 then self:RewardWin(oTarget2,iRewardScore,iTarget1,mResultData) end
        if oTarget1 then self:RewardFail(oTarget1,iSubScore,iTarget2,mResultData) end
    end
    self:Dirty()

    self:FilterAnalyData(oWar,oTarget1,oTarget2,mRecord.win == oTarget1:GetPid())
    self:FilterAnalyData(oWar,oTarget2,oTarget1,mRecord.win == oTarget2:GetPid())


    if oTarget1 then
        oTarget1:Send2Huodong("RecordLog",{name="end_arena",log=mLog})
    end
    if oTarget1 and oTarget2 and oTarget1:GetServerKey() ~= oTarget2:GetServerKey() then
        oTarget2:Send2Huodong("RecordLog",{name="end_arena",log=mLog})
    end

    self:CheckPVPCondition(mArg)

    if oTarget1 then
        oTarget1:SendEvent("RequestToDelete",{code=0})
    end
    if oTarget2 then
        oTarget2:SendEvent("RequestToDelete",{code=0})
    end
end

function CHuodong:RewardWin(oPlayer,iRewardScore,iTarget,mResultData)
    oPlayer:SendEvent("OnRewardWin",{
            score = iRewardScore,
            target = iTarget,
            result = mResultData
    })
end

function CHuodong:GetPartnerTypeList(oPlayer)
    local mPartnerInfo = oPlayer:GetPartnerInfo()
    local tResult = {}
    for _,info in ipairs(mPartnerInfo) do
        local iType = info.type
        tResult[iType] = tResult[iType] or 0
        tResult[iType] = tResult[iType] + 1
    end
    return tResult
end

function CHuodong:FilterAnalyData(oWar,oTarget1,oTarget2,bWin)
    local mExtra = oTarget1:ExtraData()
    local mArena = mExtra.arena or {}
    local iCnt = mArena.play or 0
    local iPid = oTarget1:GetPid()
    local mPartner,mTargetPartner,sInfo
    mPartner = self:GetPartnerTypeList(oTarget1)
    if oTarget2 then
        mTargetPartner = self:GetPartnerTypeList(oTarget2)
        sInfo = string.format("%d+%d+%d",oTarget2:GetPid(),oTarget2:GetSchool(),oTarget2:GetGrade())
    end
    local timelen = oWar:GetWarDuration()
    oTarget1:SendEvent("OnFilterAnalyData",{
            targetinfo = sInfo or "",
            partner = mPartner,
            tpartner = mTargetPartner or {},
            win = bWin,
            timelen = timelen,
    })
end

function CHuodong:CreateMonster(oWar,iMonsterIdx,npcobj, mArgs)
    local o = super(CHuodong).CreateMonster(self,oWar,iMonsterIdx,npcobj, mArgs)
    if self.m_AIName and string.find(o:GetAttr("name"),"$ainame") then
        o:SetAttr("name",self.m_AIName)
    end
    return o
end

function CHuodong:ChooseRobotWar()
    local res = require "base.res"
    local mData = res["daobiao"]["tollgate"][self.m_sName]
    local keylist = extend.Table.keys(mData)
    return extend.Random.random_choice(keylist)
end

-- PVE
function CHuodong:ReadyRobotWar(oPlayer)
    local oKFMgr = global.oKFMgr
    local iFid = self:ChooseRobotWar()
    local mMonster = self:GetTollGateData(iFid).monster
    local iRobotShape = 1
    local mPartner = {}
    for _,mInfo in pairs(mMonster) do
        local mid = mInfo["monsterid"]
        local mMonster = self:GetMonsterData(mid)
        local name = mMonster.name
        local iShape = mMonster.model_id
        if name == "$ainame" then
            iRobotShape = iShape
        elseif #mPartner < 4 then
            table.insert(mPartner,iShape)
        end
    end
    local mRobot = {
        name = oKFMgr:RandomName() ,
        pid = 0 ,
        shape = iRobotShape,
        rank = 1000,
        point = 974 + math.random(51) ,
        praise = 0 ,
        partner = mPartner,
        fid = iFid,
        grade = oPlayer:GetGrade(),
    }
    local mRecord= {
        name = oPlayer:GetName(),
        point = self:ArenaScore(oPlayer),
        partner = {},
        grade = oPlayer:GetGrade(),
        shape = oPlayer:GetModelInfo().shape,
    }
    oPlayer.m_InArenaGame = {robot = mRobot,myrecord = mRecord}
    local mNet = {
        name = mRobot.name ,
        pid = 0 ,
        shape = mRobot.shape,
        rank = mRobot.rank,
        point = mRobot.point ,
        praise = mRobot.praise ,
    }
    self:RefreshReadyUI(oPlayer,0,mNet)
end

function CHuodong:GetCreateWarArg(mArg)
    mArg.remote_war_type = "kfarenagame"
    mArg.war_type = gamedefines.WAR_TYPE.ARENA_TYPE
    mArg.pvpflag = 1
    return mArg
end

function CHuodong:GetRemoteWarArg()
    return {
        -- war_record = 1,
    }
end


function CHuodong:StartRobotWar(oPlayer)
    if oPlayer:GetNowWar() then
        oPlayer.m_InArenaGame = nil
        self:ClientStartMath(oPlayer,0)
        return
    end
    local iPid = oPlayer:GetPid()
    local mInfo = oPlayer.m_InArenaGame
    if mInfo then
        self.m_AIName = mInfo.robot.name
        local iWar = mInfo.robot.fid
        local oWar = self:CreateWar(oPlayer:GetPid(),nil,iWar)
        self.m_AIName = nil
        local mExtra = oPlayer:ExtraData()
        if oWar then
            oWar.m_InArenaGame = mInfo
            oPlayer.m_InArenaGame = nil
            local mExtra = oPlayer:ExtraData()
            local mArenaData = mExtra.arena
            local iCnt = (mArenaData.play or 0) + 1
            local mLog = {
                pid = oPlayer:GetPid(),
                name = oPlayer:GetName(),
                count = iCnt,
                point = self:ArenaScore(oPlayer),
                robot_name = mInfo.robot.name,
                robot_point = mInfo.robot.point,
            }
            oPlayer:SendEvent("OnStartRobotWar")
            oPlayer:Send2Huodong("RecordLog",{name="start_robot",log=mLog})
        end
        global.oKFMgr:Send2GSWorld(iPid,"EnsureEnterWar",
        {pid=iPid,name="kfarenagame",remotewarid=oWar:GetWarId(),remoteaddr=oWar:GetRemoteAddr()})
    end
end

function CHuodong:CreateWar(pid,npcobj,iFight,mInfo)
    local oPlayer = global.oKFMgr:GetObject(pid)
    mInfo = mInfo or {}
    local oWarMgr = global.oWarMgr
    local mData = self:GetTollGateData(iFight)
    local mRemote = self:GetRemoteWarArg() or {}
    mRemote["sp_start"] = mData["sp_start"] or 0
    local mArgs = self:GetCreateWarArg({
        remote_args = mRemote,
    })
    mArgs["lineup"] = mData["lineup"] or 0

    local oWar = self:NewWar(mArgs)
    oWar:SetData("CreatePid",pid)
    oWar.m_FightIdx = iFight

    local mPartnerInfo = oPlayer:GetPartnerInfo()
    local mArg = {
        camp_id = 1,
        FightPartner = mPartnerInfo,
        CurrentPartner = mPartnerInfo[1],
    }
    local iWarID = oWar:GetWarId()
    local oWarMgr = global.oWarMgr
    oWarMgr:EnterWar(oPlayer, iWarID, mArg, true)

    local iAuto = self:GetWarConfig("close_auto_skill",mData)
    local iAuotOpen = self:GetWarConfig("open_auto_skill",mData)
    if iAuto and iAuto == 1 then
        oWar:SetData("close_auto_skill",true)
    end
    if iAuotOpen ~= 0 then
        oWar:SetData("open_auto_skill",true)
    end
    self:ConfigWar(oWar,pid,npcobj,iFight, mInfo)

    local mEnterWarArg = mInfo.enter_arg or {}
    mEnterWarArg.camp_id = mEnterWarArg.camp_id or 1

    oWar:InitAttr()

    local mMonsterData = self:GetWarMonster(oWar, iFight)
    -- local mEnemy = {}
    local mWaveEnemy = {}
    local mWaveData = {}

    if self:ArrayDepth(mMonsterData) == 2 then
        mWaveData[1] = mMonsterData
    else
        mWaveData = mMonsterData
    end

    for iWave,mMaveMonsterData in pairs(mWaveData) do
        mWaveEnemy[iWave] = {}
        for _,mMonsterData in pairs(mMaveMonsterData) do
            local iMonsterIdx = mMonsterData["monsterid"]
            local iCnt = mMonsterData["count"]
            mArgs.monster_wave = iWave
            for i=1,iCnt do
                local oMonster = self:CreateMonster(oWar,iMonsterIdx,npcobj, mArgs)
                table.insert(mWaveEnemy[iWave], oMonster:PackAttr())
            end
        end
    end

    local mEnemy = self:GetEnemyMonster(oWar,pid,npcobj,mArgs,mWaveEnemy[1])

    local mMonsterData = mData["friend"] or {}
    local mFriend = {}
    for _,mData in pairs(mMonsterData) do
        local iMonsterIdx = mData["monsterid"]
        local iCnt = mData["count"]
        for i=1,iCnt do
            local oMonster = self:CreateMonster(oWar,iMonsterIdx,npcobj, mArgs)
            table.insert(mFriend, oMonster:PackAttr())
            if #mFriend >= 2 then
                break
            end
        end
        if #mFriend >= 2 then
            break
        end
    end

    local mMonster = {
        [1] = mFriend,
        [2] = mEnemy,
    }

    local mMonsterData = {
        monster_data = mMonster,
        wave_enemy = mWaveEnemy,
        monster_servant = self:GetServant(oWar,mArgs),
    }

    oWarMgr:PrepareWar(oWar:GetWarId(),mMonsterData)
    if npcobj then
        oWar.m_iEvent = self:GetEvent(npcobj.m_ID)
    else
        oWar.m_iEvent = self:GetTriggerEvent()
    end
    local npcid
    if npcobj then
        npcid = npcobj.m_ID
    end
    local fSelfCallback = self:GetSelfCallback()
    local sDebug =  self.m_sName or "unknown"
    local fWarEndCallback = function (mArgs)
        local npcobj
        if fSelfCallback then
            local oSelf = fSelfCallback()
            if not oSelf then
                record.error(string.format("nil oSelf %s",sDebug))
            end
            if npcid then
                npcobj = oSelf:GetNpcObj(npcid)
            end
            oSelf:WarFightEnd(oWar,pid,npcobj,mArgs)
        end
    end
    oWarMgr:SetWarEndCallback(oWar:GetWarId(),fWarEndCallback)
    local fEscapeCallBack = function (mArgs)
        if fSelfCallback then
            local oSelf = fSelfCallback()
            oSelf:EscapeCallBack(oWar, pid, npcobj, mArgs)
        end
    end
    oWarMgr:SetEscapeCallBack(oWar:GetWarId(), fEscapeCallBack)
    if oWar.m_NeedConfig or self:GetWarConfig("war_config",mData, oPlayer) ~= 0 then
        oWarMgr:StartWarConfig(oWar:GetWarId())
    else
        oWarMgr:StartWar(oWar:GetWarId())
    end
    return oWar
end

function CHuodong:OnWarWin(oWar, pid, npcobj, mArgs)
    local oKFMgr = global.oKFMgr
    local oPlayer = oKFMgr:GetObject(pid)
    if not oPlayer then
        return
    end
    self:OnRobotWarEnd(oWar,oPlayer,mArgs,true)
end


function CHuodong:OnWarFail(oWar, pid, npcobj, mArgs)
    local oKFMgr = global.oKFMgr
    local oPlayer = oKFMgr:GetObject(pid)
    if not oPlayer then
        return
    end
    self:OnRobotWarEnd(oWar,oPlayer,mArgs,false)
end

function CHuodong:OnRobotWarEnd(oWar,oPlayer,mArg,bWin)
    assert(oWar.m_InArenaGame,string.format("PVE arena warwin %d",oPlayer:GetPid()))
    local mRobot = oWar.m_InArenaGame.robot

    local sWarFilm = mArg.war_film_id
    local iScore2 = self:ArenaScore(oPlayer)
    local iScore1 = mRobot.point
    local iS1,iS2 = self:ScoreCalculator(iScore1,iScore2,mArg.win_side)
    local iSubScore = iS1
    if not bWin then
        iSubScore = iS2
    end
    local mUnit1 = oWar.m_InArenaGame.myrecord
    local mFightPartner = mArg.arena_partner
    local mPar1 = mFightPartner[oPlayer:GetPid()] or {}

    mUnit1.partner = mPar1
    mUnit1.score = iSubScore
    local mUnit2 = {
        name = mRobot.name,
        point = iScore1,
        partner = mRobot.partner,
        grade = mRobot.grade,
        shape = mRobot.shape,
        score = iSubScore,
        }
    local mRecord = {fight={[db_key(oPlayer:GetPid())] = mUnit1, ["0"] = mUnit2}}

    mRecord.fid = sWarFilm
    local iLogScore
    if bWin then
        mRecord.win = oPlayer:GetPid()
        iLogScore = iSubScore
    else
        mRecord.win = 0
        iLogScore = - iSubScore
    end

    local mLog = {
        pid1 = oPlayer:GetPid(),
        addpoint1 = iLogScore,
        point1 = iScore2 + iLogScore,
        name1 = oPlayer:GetName(),

        pid2 = 0,
        addpoint2 = 0,
        point2 = iScore1,
        name2 = mRobot.name,
        win = mRecord.win,
    }

    oPlayer:Send2Huodong("RecordLog",{name="end_arena",log=mLog})

    local mResultData = {win=1}
    if not bWin then
        mResultData["win"] = 2
    end

    mResultData["data"] = {}
    table.insert(mResultData["data"],{pid = oPlayer:GetPid(),name =mUnit1["name"],shape=mUnit1["shape"],camp=1})
    table.insert(mResultData["data"],{pid = 0,name =mUnit2["name"],shape=mUnit2["shape"],camp=2})

    if bWin then
        self:RewardWin(oPlayer,iSubScore,0,mResultData)
    else
         self:RewardFail(oPlayer,iSubScore,0,mResultData)
    end
    self:FilterAnalyData(oWar,oPlayer,nil,bWin)
    if oPlayer then
        oPlayer:SendEvent("RequestToDelete",{code=0})
    end
end

function CHuodong:RewardFail(oPlayer,iSubScore,iTarget,mResultData)
    oPlayer:SendEvent("OnRewardFail",{
            score = iSubScore,
            target = iTarget,
            result = mResultData
    })
end


function CHuodong:TestKFOP(iFlag,args)
    local mRe = {ok=1}
    if iFlag == 101 then
        if not self:InHuodongTime() then
           self:GameStart()
        end
    elseif iFlag == 102 then
        if self:InHuodongTime() then
            self:GameOver()
        end
    end
    return mRe
end
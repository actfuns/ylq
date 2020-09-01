--import module
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

local loaditem = import(service_path("item/loaditem"))
local huodongbase = import(service_path("huodong.huodongbase"))
local monster = import(service_path("monster"))
local analy = import(lualib_path("public.dataanaly"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

GAME_START = 1
GAME_OVER1 = 2
GAME_OVER2 = 3

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "封印之地"
CHuodong.m_SID = 1001
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_PlayerList = {}
    o.m_Status= GAME_OVER2
    o.m_StartTime = 0
    o.m_iScheduleID = 2002
    o.m_Boss = CWorldBoss:New()
    o.m_SceneLimit = 500
    return o
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.boss = self.m_Boss:SaveDb()
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    self.m_Boss:LoadDb(mData.boss or {})
end



function CHuodong:NewHour(iWeekDay, iHour)
    local mOpenDay = self:GetConfigValue("open_day")
    if table_in_list(mOpenDay,iWeekDay) then
        local iOpenHour = self:GetConfigValue("start_time")
        if iOpenHour == iHour then
            self:GameStart()
        end
    end
end

function CHuodong:IsClose()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:IsClose("worldboss")
end


function CHuodong:NotifyRank(sFunc,mRank,callback)
    mRank.rank_name = "worldboss"
    if not callback then
        interactive.Send(".rank","rank",sFunc,mRank)
    else
        mRank.respond = 1
        interactive.Request(".rank","rank",sFunc,mRank,function(mRecord,mData)
            callback(mRecord,mData)
            end)
    end
end

function CHuodong:OnLogin(oPlayer,reenter)
    if self.m_Status ~= GAME_OVER2 then
        local mNet = {
            hd_id = self.m_SID,
            status = 1,
            }
        oPlayer:Send("GS2CHuoDongStatus",mNet)
    end
    self:RefreshLeftTime(oPlayer)
    if self:InHDScene(oPlayer) then
        oPlayer:Send("GS2CInWorldBossScene",{})
        self:HPNotify(oPlayer)
    end
end

function CHuodong:GameStart()
    if self.m_Status~=GAME_OVER2 then
        return
    end
    self.m_StartTime = get_time()
    local oNotifyMgr = global.oNotifyMgr
    record.info("worldboss gamestart")
    self:InitBoss()
    self:CreateRes()
    self:Dirty()
    self.m_Status = GAME_START
    self:BroadcastBossHP()
    local oBoss = self.m_Boss
    local oWarMgr = global.oWarMgr
    local mNet = {arg={maxhp=oBoss.m_HP_MAX},}
    for _,v in pairs(oWarMgr.m_lWarRemote) do
        interactive.Send(v,"worldboss","StartBossWar",mNet)
    end
    self:NotifyRank("CleanRankCache",{})
    local sMsg = self:GetTransText(1001)
    sMsg = string.gsub(sMsg,"{$bossname}",self:GetBoss():Name())
    oNotifyMgr:SendPrioritySysChat("world_boss_start",sMsg,1)
    self:SendHuodongStatus(1)
    self:DelTimeCb("_GameOver1")
    self:AddTimeCb("_GameOver1",3600*1000,function ()
        self:GameOver1()
        end)
    local mLog ={
        grade = oBoss.m_Grade,
        playcnt = oBoss:PlayArg(),
        hp = oBoss.m_HP_MAX,
        exp =oBoss.m_Exp,
        type =  oBoss.m_Type,
        }
    record.user("worldboss","game_start",mLog)
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_START)
    self:RefreshLeftTime()
    global.oWorldMgr:RecordOpen("worldboss")
end




function CHuodong:RefreshLeftTime(oPlayer)
    if self.m_Status ~= GAME_START then
        return
    end
    local iLeft = math.max(self.m_StartTime + 3600 - get_time(),1)
    local mNet = {left=iLeft}
    if oPlayer then
        oPlayer:Send("GS2CWorldBossLeftTime",mNet)
    else
        local mData = {
            message = "GS2CWorldBossLeftTime",
            type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
            id = 1,
            data = mNet,
            exclude = {}
        }
        interactive.Send(".broadcast","channel","SendChannel",mData)
    end
end


function CHuodong:SendHuodongStatus(iState)
    local mNet = {
        hd_id = self.m_SID,
        status = iState,
        }
    local mData = {
        message = "GS2CHuoDongStatus",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = mNet,
        exclude = {}
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end

function CHuodong:SendWorldBossDeath(iNpcType)
    local mNet = {
        boss_npc = iNpcType,
    }
    local mData = {
        message = "GS2CWorldBossDeath",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = mNet,
        exclude = {}
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end

function CHuodong:BroadcastBossHP()
    self:DelTimeCb("_BroadcastBossHP")
    if self.m_Status ~= GAME_START then
        return
    end
    self:AddTimeCb("_BroadcastBossHP",3*1000,function ()
        self:BroadcastBossHP()
        end)
    local oBoss = self:GetBoss()
    local mNet = {
    hp_max = oBoss.m_HP_MAX,
    hp = oBoss.m_HP,
    }
    global.oInterfaceMgr:WorldBossNotify("GS2CBossHPNotify",mNet)
    for iScene,_ in pairs(self.m_mSceneList) do
        local oScene = self:GetHDScene(iScene)
        if oScene then
            oScene:BroadCast("GS2CBossHPNotify",mNet)
        end
    end
end

function CHuodong:GameOver1()
    if self.m_Status==GAME_START then
        self.m_Status = GAME_OVER1
        local oBoss = self:GetBoss()
        local iPlayCnt = table_count(self.m_PlayerList)
        local mLog = {
            kill = oBoss.m_Killer,
            playcnt = iPlayCnt,
        }
        record.user("worldboss","game_over",mLog)
        oBoss:Record(iPlayCnt)
        self:Dirty()
        self:RewardGameEnd()
        local oNotifyMgr = global.oNotifyMgr
        if not oBoss:IsDead() then
            oBoss:Alive()
            local sMsg = self:GetTransText(1005)
            oNotifyMgr:SendPrioritySysChat("world_boss_end",sMsg,1)
            self:KickoutWar(0)
        end
        record.info("worldboss gameover")
        self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_OVER)
        self:DelTimeCb("_GameOver2")
        self:AddTimeCb("_GameOver2",30*60*1000,function ()
            self:GameOver2()
            end)
        self:DelTimeCb("_BroadcastBossHP")
        self:DelTimeCb("BossDie")
        self:CleanPlayer()
    end
end




function CHuodong:RewardGameEnd()
    local oBoss = self:GetBoss()
    if oBoss.m_RewardEnd == 0 then
        oBoss.m_RewardEnd = 1
        self:Dirty()
        self:RewardKill()
        self:RewardRank()
    end
end

function CHuodong:RewardKill()
    local oBoss = self:GetBoss()
    if oBoss.m_Killer == 0 then
        return
    end
    local pid = oBoss.m_Killer
    local mData = self.m_PlayerList[pid]
    if not mData then
        record.error(string.format("worldboss NoneKiller %d",pid))
        return
    end
    local sName = mData.name
    local mLog = {
        pid = oBoss.m_Killer,
        name = sName,
    }
    record.user("worldboss","reward_kill",mLog)
    self:RewardPlayer(pid,oBoss:IsBigBoss(),self:GetConfigValue("kill_reward"),1,{})

end


function CHuodong:RewardRank()
    local mRequest = {
    data = {reward=1},
    }
    self:NotifyRank("GetExtraRankData",mRequest,function(mRecord,mData)
        local mInfo = mData.data
        self:RewardTop500(mInfo.rank)
        end)
end

function CHuodong:RewardTop500(pidlist)
    self:AddTimeCb("RewardRank",5*1000,function ()
        self:TimeRewardOther()
        end)
    local oMailMgr = global.oMailMgr
    local iKill = 0
    local oBoss = self:GetBoss()
    if oBoss.m_Killer ~=0 then
        iKill = 1
    end
    local bBigBoss = oBoss:IsBigBoss()
    for _,mRank  in pairs(pidlist) do
        local iRank = mRank.rank
        local iPid = mRank.pid
        local sKey = ""
        if iRank <= 3 then
            sKey = string.format("top_%d",iRank)
        elseif iRank <=10 then
            sKey = "top_10"
        elseif iRank <= 20 then
            sKey = "top_20"
        elseif iRank <= 50 then
            sKey = "top_50"
        elseif iRank <= 100 then
            sKey = "top_100"
        elseif iRank <= 200 then
            sKey = "top_200"
        else
            sKey = "top_last"
        end
        local mUnit = self.m_PlayerList[iPid] or {}
        local mLog = {
                pid = iPid,
                hit = mUnit.hit or 0,
                rank = iRank,
            }
        record.user("worldboss","reward_end",mLog)
        local iMail = 6
        if sKey == "top_last" then
            iMail = 19
        end
        local info = table_deep_copy(oMailMgr:GetMailInfo(iMail))
        info.context = string.format(info.context,iRank)
        info.context = string.gsub(info.context,"{$bossname}",oBoss:Name())
       self:RewardPlayer(iPid,bBigBoss,self:GetConfigValue(sKey),iKill,{mailinfo = info,func = function (mRewardContent)
            safe_call(self.FilterAnalyRewardData,self,mRewardContent,iPid,iRank)
       end})
        if self.m_PlayerList[iPid] then
            self.m_PlayerList[iPid].reward = 1
        end
    end
end

function CHuodong:FilterAnalyRewardData(mRewardContent,iPid,iRank)
    local mRewardItem = mRewardContent.iteminfo
    local lItemObj = mRewardItem.item or {}
    local mItem = {}
    for _,oItem in pairs(lItemObj) do
        local shape = oItem:SID()
        local amount = oItem:GetAmount()
        if shape > 10000 then
            mItem[shape] = mItem[shape] or 0
            mItem[shape] = mItem[shape] + amount
        end
    end
    self:LogAnalyRewardData(iPid,iRank,mItem)
end

function CHuodong:LogAnalyRewardData(iPid,ranking,mItem)
	local oWorldMgr = global.oWorldMgr
	local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
	if oPlayer then
	    local mLog = oPlayer:GetPubAnalyData()
	    mLog["ranking"] = ranking
	    mLog["reward_detail"] = analy.datajoin(mItem)
	    analy.log_data("acgDemonReward",mLog)
   	else
                oWorldMgr:LoadProfile(iPid, function (oProfile)
                        local mLog = oProfile:GetPubAnalyData()
                        mLog["ranking"] = ranking
                        mLog["reward_detail"] = analy.datajoin(mItem)
                        analy.log_data("acgDemonReward",mLog)
    	end)
   	end
end

function CHuodong:TimeRewardOther()
    self:DelTimeCb("RewardRank")
    self:AddTimeCb("RewardRank",1000,function ()
        self:TimeRewardOther()
        end)
    local iCnt = 0
    local oMailMgr = global.oMailMgr
    local iKill = 0
    local oBoss = self:GetBoss()
    if oBoss.m_Killer ~=0 then
        iKill = 1
    end
    self:Dirty()
    local info = table_deep_copy(oMailMgr:GetMailInfo(19))
    info.context = string.gsub(info.context,"{$bossname}",oBoss:Name())
    local mArg = {mailinfo=info}
    for uid,mUnit in pairs(self.m_PlayerList) do
        if not mUnit.reward then
            iCnt = iCnt +1
            local mLog = {
                pid = uid,
                hit = mUnit.hit,
                rank = 0,
            }
            record.user("worldboss","reward_end",mLog)
            self.m_PlayerList[uid].reward = 1
            self:RewardPlayer(uid, oBoss:IsBigBoss(), self:GetConfigValue("top_last"),iKill,mArg)
            if iCnt >100 then
                break
            end
        end
    end
    if iCnt == 0 then
        self:DelTimeCb("RewardRank")
    end
end



function CHuodong:RewardPlayer(pid,bBigBoss,iReward,iKill,mArg)
    if pid == 0 then
        return
    end
    mArg = mArg or {}
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["boss_reward"]
    local mReward = mData[iReward]
    local mRankReward
    local mExtraReward
    if bBigBoss then
        mRankReward = mReward.server_rank_reward2 or {}
        mExtraReward = mReward.server_extra_reward2 or {}
    else
        mRankReward = mReward.server_rank_reward or {}
        mExtraReward = mReward.server_extra_reward or {}
    end
    if mArg.mailinfo and next(mRankReward) then
        self:RewardListByMail(pid,mRankReward,mArg)
    end
    if iKill~=0 then
        local iMailId = 24
        if not mArg.mailinfo then
            iMailId = 10
        end
        local oBoss = self:GetBoss()
        local oMailMgr = global.oMailMgr
        local info = table_deep_copy(oMailMgr:GetMailInfo(iMailId))
        info.context = string.gsub(info.context,"{$bossname}",oBoss:Name())
        self:RewardListByMail(pid,mExtraReward,{mailinfo = info})
    end
end

function CHuodong:GameOver2()
    self:DelTimeCb("_GameOver2")
    if self.m_Status == GAME_OVER1 then
        self.m_Status = GAME_OVER2
        self.m_PlayerList = {}
        record.info("worldboss realse")
        self:SendHuodongStatus(0)
        self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_CLOSE)
        self:CleanRes()
    end
end

function CHuodong:CreateRes()
    local oWorldMgr = global.oWorldMgr
    local oBoss = self:GetBoss()
    local fscene = function ()
        local oScene= self:CreateVirtualScene(1001)
        oScene.m_HuoDong = self.m_sTempName
        oScene:SetLimitRule("team",1)
        oScene:SetLimitRule("transfer",1)
        local fproxy = function (sName)
                local f = function(...)
                    local hf = self[sName]
                    assert(type(hf)=="function")
                    return hf(self,...)
                end
            return f
        end
        oScene.m_OnLeave = fproxy("OnLeaveScene")
        oScene.m_OnEnter = fproxy("OnEnerScene")

        local iNpc = oBoss.m_Fight
        local npcobj = assert(self:CreateTempNpc(iNpc))
        local mPosInfo = npcobj:PosInfo()
        self:Npc_Enter_Scene(npcobj,oScene:GetSceneId(),mPosInfo)
    end


    local iCnt = math.max(1,table_count(oWorldMgr:GetOnlinePlayerList())/self.m_SceneLimit)
    for i=1,iCnt do
        fscene()
    end
end


-- 只有玩家离场才清理资源
function CHuodong:OnLeaveScene(oScene,oPlayer)
    oPlayer:Send("GS2CLeaveWorldBossScene",{})
end

function CHuodong:OnEnerScene(oScene,oPlayer)
    oPlayer:Send("GS2CInWorldBossScene",{})
end

function CHuodong:EnterScene(oPlayer)
    if self.m_Status~= GAME_START then
        return
    end
    local oSceneMgr = global.oSceneMgr
    local iSc = extend.Random.random_choice(table_key_list(self.m_mSceneList))
    local mScene = self:GetHDScene(iSc)
    local iMapId = mScene:MapId()
    local mPos = oSceneMgr:RandomMonsterPos(iMapId,1)[1]
    self:TransferPlayerBySceneID(oPlayer:GetPid(),iSc,mPos[1],mPos[2])
end


function CHuodong:CleanRes()
    self:CleanPlayer()
    for iSc,_ in pairs(self.m_mSceneList) do
        self:RemoveSceneById(iSc)
    end
end


function CHuodong:CleanPlayer(bOpenUI)
    local oWorldMgr = global.oWorldMgr
    local fClean = function (iSc)
        local oScene = self:GetHDScene(iSc)
        if not oScene then
            return
        end
        local plist = oScene:GetPlayers()
        for _,pid in ipairs(plist) do
            local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
            if pobj then
                    self:LeaveScene(pobj)
                    if bOpenUI then
                        self:OpenMainUI(pobj)
                    end
            end
        end
    end

    for iSc,_ in pairs(self.m_mSceneList) do
        fClean(iSc)
    end

end


function CHuodong:do_look(oPlayer, npcobj)
    self:EnterWar(oPlayer)
end

function CHuodong:LeaveScene(oPlayer)
    if self:InHDScene(oPlayer) then
        self:GobackRealScene(oPlayer:GetPid())
    end
end

function CHuodong:InHDScene(oPlayer)
    local iScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    return self.m_mSceneList[iScene]
end

function CHuodong:FindWorldBoss(oPlayer)
    if not self:InHDScene(oPlayer) then
        return
    end
    local npcid = 0
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    for nid,_ in pairs(oScene:NpcList()) do
        npcid = nid
        break
    end
    local npcobj = self:GetNpcObj(npcid)
    if not npcobj then
        return
    end
    local oSceneMgr = global.oSceneMgr
    local mPos = npcobj:PosInfo()
    oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),npcobj.m_iMapid,mPos.x,mPos.y,npcobj.m_ID,1,1)
end




function CHuodong:EnterWar(oPlayer)
    if self:ValidEnterWar(oPlayer) then
        local pid = oPlayer:GetPid()
        local oState = self:GetAbleState(oPlayer)
        if oState then
            self.m_TeamBuff = oState:GetData("buff")
        end

        --  弄伙伴

        self.m_mPartnerList = {}
        --self.m_mPartnerList[oPlayer:GetPid()]=oPlayer.m_oToday:Query("worldboss_partnerlist",{})
        local oBoss = self:GetBoss()
        local oWar = self:CreateWar(pid,nil,oBoss.m_Fight,mInfo)
        self.m_mPartnerList = nil
        if oWar then
            oPlayer.m_oToday:Add("worldbossCnt",1)
            local PlayInfo  = self.m_PlayerList[pid] or {fighthit=0,hit=0,name=oPlayer:GetName(),inwar=true}
            PlayInfo.inwar = true
            PlayInfo.hit = 0
            self.m_PlayerList[pid] = PlayInfo
            self:RemoveAbleState(oPlayer)
            global.oInterfaceMgr:ClientOpen(oPlayer,gamedefines.INTERFACE_TYPE.WORLD_BOSS)
            local mLog= {
                pid = pid,
                name = oPlayer:GetName(),
                play = oPlayer.m_oToday:Query("worldbossCnt"),
                boss_hp= oBoss.m_HP,
                }
            record.user("worldboss","start_war",mLog)
        end
        self.m_TeamBuff= nil
    end
end



function CHuodong:AddPartner(oPlayer,mFightPartner)

    local mPar1 = mFightPartner[oPlayer:GetPid()] or {}
    local mDayPartnerList = oPlayer.m_oToday:Query("worldboss_partnerlist",{})
    local sPartner = ""
    for parid, mArgs in pairs(mPar1) do
        if not extend.Array.member(mDayPartnerList,parid) then
            table.insert(mDayPartnerList,parid)
            sPartner = sPartner..string.format("[%d,%s,%s],",parid,mArgs.name,mArgs.shape)
        end
    end
    oPlayer.m_oToday:Set("worldboss_partnerlist",mDayPartnerList)
    return sPartner
end

function CHuodong:GetTransText(iText)
    local sText = self:GetTextData(iText)
    return string.gsub(sText,"{$bossname}",self:GetBoss():Name())
end

function CHuodong:ValidEnterWar(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oBoss = self:GetBoss()
    local iGrade = oWorldMgr:QueryControl("worldboss","open_grade")
    if oBoss:IsDead() then
        local sMsg = self:GetTransText(1002)
        oNotifyMgr:Notify(oPlayer:GetPid(),sMsg)
        return false
    end
    if self.m_Status == GAME_OVER1 then
        oNotifyMgr:Notify(oPlayer:GetPid(),"活动已结束")
        return
    end
    if self.m_Status ~=GAME_START then
        local sMsg = self:GetTextData(1007)
        oNotifyMgr:Notify(oPlayer:GetPid(),sMsg)
        return false
    end
    if oPlayer:GetGrade() < iGrade then
        local sMsg = self:GetTextData(1008)
        oNotifyMgr:Notify(oPlayer:GetPid(),sMsg)
        return false
    end
    if oPlayer.m_oStateCtrl:GetState(1005) then
        return false
    end
    if self:IsClose() then
        local sMsg = self:GetTextData(1006)
        oNotifyMgr:Notify(oPlayer:GetPid(),sMsg)
        return false
    end
    if not oPlayer:IsSingle() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1009))
        return false
    end
    if oPlayer.m_oActiveCtrl:GetNowWar() then
        return false
    end
    return true
end


function CHuodong:GetBoss()
    return self.m_Boss
end

function CHuodong:InitBoss()
    --assert(not self.m_Boss,"Boss already exist")
    self.m_PlayerList  = {}
    self.m_Boss:Rebirth()
end


--战斗与Boss交互--

function CHuodong:HPChange(iHp,plist)
    local oBoss = self:GetBoss()
    if not oBoss  or oBoss:IsDead() then
        return
    end
    local oWarMgr = global.oWarMgr
    local oWorldMgr = global.oWorldMgr
    local oNotify = global.oNotifyMgr
    local mRank = {}
    mRank.rank_data = {}
    local pid = 0
    for _,v in pairs(plist) do
        pid = v[1]
        local iHit = v[2]
        local mData = self.m_PlayerList[pid]
        if mData then
            mData.hit = mData.hit +iHit
            mData.fighthit = mData.fighthit + iHit
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
            if oPlayer then --record rank
                local mRecord = {
                    pid = pid,
                    name = mData.name,
                    hit = mData.fighthit,
                    shape = oPlayer:GetModelInfo().shape
                        }
                table.insert(mRank.rank_data,mRecord)
            end
        end
    end
    self:NotifyRank("PushDataToRank",mRank)

    oBoss:HPCHange(iHp)
    oBoss:HPPerChange()
    local iPer = oBoss:HPPerChange()
    local iN = iPer
    if oBoss.m_LastNotifyPercent >= iN and oBoss.m_LastNotifyPercent > 0 then
        oBoss.m_LastNotifyPercent = oBoss.m_LastNotifyPercent - 10
        local mRequest = {
        data = {damage=1},
        }
        self:NotifyRank("GetExtraRankData",mRequest,function(mRecord,mData)
                local mInfo = mData.data
                self:NotfiyDamageNotify(iPer,mInfo.rank)
            end)

    end
    if oBoss:IsDead() then
        self:KickoutWar(1)
        self:BossDie()
        oBoss.m_Killer = pid
        local mData = self.m_PlayerList[pid]
        if mData then
            oBoss.m_KillerName = mData.name
        end
        oBoss:AddExp(1)
        local sMsg = string.gsub(self:GetTransText(1003),"#role",oBoss.m_KillerName or tostring(pid))
        sMsg = string.gsub(sMsg,"{$bossname}",oBoss:Name())
        oNotify:SendPrioritySysChat("world_boss_end",sMsg,1)
        local mLog = {
            killer = oBoss.m_Killer,
            killername = oBoss.m_KillerName,
            exp = oBoss.m_Exp,
            grade = oBoss.m_Grade,
        }
        record.user("worldboss","boss_dead",mLog)
        self:RewardGameEnd()
    end
end

function CHuodong:BossDie()
    self:DelTimeCb("BossDie")
    self:SendWorldBossDeath(self.m_Boss.m_Fight)
    self:AddTimeCb("BossDie", 10*1000, function()
        self:CleanPlayer(true)
    end)
end

function CHuodong:NotfiyDamageNotify(iPer,mRank)
    local mFirst = mRank[1]
    if not mFirst then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local oBoss =self:GetBoss()
    local sName = mFirst.name
    iPer = math.floor(100 - iPer)
    local sMsg = string.gsub(self:GetTransText(1010),"#role",sName)
    sMsg = string.gsub(sMsg,"{$bossname}",oBoss:Name())
    sMsg = string.gsub(sMsg,"{$BossHP}",iPer)
    oNotifyMgr:SendPrioritySysChat("world_boss_end",sMsg,1)
end


function CHuodong:KickoutWar(iWin)
    local oWarMgr = global.oWarMgr
    for _,v in pairs(oWarMgr.m_lWarRemote) do
            interactive.Send(v,"worldboss","BossDie",{win=iWin})
    end
end

function CHuodong:CreateMonster(oWar,iMonsterIdx,npcobj)
    local oMonster
    oMonster = super(CHuodong).CreateMonster(self,oWar,iMonsterIdx,npcobj)
    if iMonsterIdx < 20000 then
        if self.m_TeamBuff then
            local mData = oMonster.m_mData
            mData.extra_data = {teambuff = self.m_TeamBuff}
        end
        local oBoss = self:GetBoss()
        oMonster.m_mData["hp"] = oBoss.m_HP
        oMonster.m_mData["maxhp"] = oBoss.m_HP_MAX
    end
    return oMonster
end

function CHuodong:TransMonsterAble(oWar,sAttr,mArgs)
    mArgs = mArgs or {}
    local sValue = mArgs.value
    local mEnv = mArgs.env
    mEnv.bosslv = self:GetBoss().m_Grade
    mEnv.playcnt = self:GetBoss():PlayArg()
    local iValue = formula_string(sValue,mEnv)
    return iValue
end

function CHuodong:GetTollGateData(iFight)
    local res = require "base.res"
    local mData = res["daobiao"]["tollgate"]["worldboss"][iFight]
    return mData
end

function CHuodong:GetCreateWarArg(mArg)
    local oBoss = self:GetBoss()
    if oBoss:IsBigBoss() then
        mArg.war_type = gamedefines.WAR_TYPE.BOSS_TYPE2
    else
        mArg.war_type = gamedefines.WAR_TYPE.BOSS_TYPE
    end
    mArg.remote_war_type = "worldboss"
    mArg.remote_args = mArg.remote_args or {}
    --mArg.remote_args.use_parlist= self.m_mPartnerList  or {}
    return mArg
end

function CHuodong:GetServant(oWar,mArgs)
    local  mMonsterList = {20001,20002,20003,20004,20005}
    local NewMonsterList = extend.Random.sample_list(mMonsterList,4)
    local mServant = {}
    for _,iMonsterIdx in ipairs(NewMonsterList) do
        local oMonster = self:CreateMonster(oWar,iMonsterIdx,nil, mArgs)
        mServant[iMonsterIdx] = oMonster:PackAttr()
    end
    return mServant
end


function CHuodong:OnWarWin(oWar, pid, npcobj, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        self:OnCommonWarEnd(oWar,oPlayer,mArgs,1)
    end
end

function CHuodong:OnWarFail(oWar, pid, npcobj, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        self:OnCommonWarEnd(oWar,oPlayer,mArgs,0)
    end
end

function CHuodong:OnCommonWarEnd(oWar,oPlayer,mArgs,iWin)
    local mData = self.m_PlayerList[oPlayer:GetPid()] or {}
    local iSumHit = mData.fighthit or 0
    local iHit = mData.hit  or 0
    mData.inwar = false
    local  sPartner = self:AddPartner(oPlayer,mArgs.world)
    local oBoss = self:GetBoss()
    local mLog = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        win = iWin,
        hit = iHit,
        sumhit = iSumHit,
        boss_hp = oBoss.m_HP,
        war_partner = sPartner,
        }
    record.user("worldboss","end_war",mLog)
    local iCoin = math.floor(iHit/self:GetConfigValue("coin_ratio"))
    if iCoin > 0 then
        oPlayer:RewardCoin(iCoin,"worldboss")
    end
    global.oInterfaceMgr:ClientClose(oPlayer,gamedefines.INTERFACE_TYPE.WORLD_BOSS)
    self:SendWarEnd(oPlayer,mData)

    oPlayer:AddSchedule("worldboss")
    oPlayer:RecordPlayCnt("worldboss",1)
    self:LogAnalyWarData(oWar,oPlayer,iHit,oBoss.m_Type,oWar:GetWarDuration())
    self:AddKeep(oPlayer:GetPid(), "coin", iCoin)
    if iWin == 0 then
        oPlayer.m_oStateCtrl:AddState(1005,{time=30})
    end
    self:LogAnalyGame("worldboss",oPlayer)
    self:RefreshWorldBoossRank(oPlayer)

end

function CHuodong:LogAnalyWarData(oWar,oPlayer,damage,bosstype,timelen)
    local mLog = oPlayer:GetPubAnalyData()
    local mPartner = self:GetPartnerTypeList(oWar,oPlayer)
    mLog["partner_detail"] = analy.datajoin(mPartner)
    mLog["damage"] = damage
    mLog["npc_id"] = bosstype
    mLog["consume_time"] = timelen
    analy.log_data("acgDemonBattle",mLog)
end

function CHuodong:GetPartnerTypeList(oWar,oPlayer)
    local iPid = oPlayer:GetPid()
    local mOFPartner = oWar.m_OutFightPartner or {}
    local mPartnerID = mOFPartner[iPid] or {}
    local tResult
    for partID,_ in pairs(mPartnerID) do
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(partID)
        if oPartner then
            local iType = oPartner:SID()
            tResult = tResult or {}
            tResult[iType] = tResult[iType] or 0
            tResult[iType] = tResult[iType] + 1
        end
    end
    return tResult
end

function CHuodong:SendWarEnd(oPlayer,mData)
    local oBoss = self:GetBoss()
    local iHit = mData.hit
    local iSum  = mData.fighthit
    local iPer = math.floor((iSum/oBoss.m_HP_MAX*10000))
    local mNet = {
    hit =iHit,
    all_hit = iSum,
    hit_per = iPer,
    rank = 0,
    }

    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local mRequest = {
    data = {pid=oPlayer:GetPid(),endui=1},
    }
    self:NotifyRank("GetExtraRankData",mRequest,function(mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            self:SendWarEnd2(oPlayer,mData.data,mNet)
        end
        end)
end

function CHuodong:SendWarEnd2(oPlayer,rankdata,mNet)
    local mRank = rankdata.rank or {}
    mNet.rank = mRank.rank or 0
    oPlayer:Send("GS2CBossWarEnd",mNet)
end


function CHuodong:OpenMainUI(oPlayer)
    if self.m_Status ==  GAME_OVER2 then return end

    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local mRequest = {
    data = {pid=oPlayer:GetPid(),endui=1},
    }
    self:NotifyRank("GetExtraRankData",mRequest,function(mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            self:_OpenMainUI(oPlayer,mData.data)
        end
        end)
end

function CHuodong:LeftTime()
    if self.m_Status ~= GAME_START then
        return 0
    end
    return self.m_StartTime + 3600 - get_time()
end

function CHuodong:_OpenMainUI(oPlayer,rankdata)
    local mNet = {}
    local oBoss = self:GetBoss()
    mNet.hp_max = oBoss.m_HP_MAX
    mNet.hp =  oBoss.m_HP
    if oBoss:IsDead() then
        mNet.state = 0
    else
        mNet.state = 1
    end

    mNet.lefttime = self:LeftTime()
    mNet.ranklist = rankdata.top20
    local mRank = rankdata.rank or {}
    mNet.rank = mRank.rank or 0
    if mNet.rank > 500 then
        mNet.rank = 0
    end
    mNet.bosshape = oBoss.m_Shape
    mNet.skill_list = {3106,3107,}
    mNet.myrank = {
        pid=oPlayer:GetPid(),
        name=oPlayer:GetName(),
        hit= mRank.hit or 0,
        shape=oPlayer:GetModelInfo().shape,
    }
    mNet.daycnt = oPlayer.m_oToday:Query("worldbossCnt")
    mNet.killer = oBoss.m_KillerName or ""
    if oBoss:IsBigBoss() then
        mNet.bigboss = 1
    else
        mNet.bigboss = 0
    end
    oPlayer:Send("GS2CBossMain",mNet)
    global.oInterfaceMgr:ClientOpen(oPlayer,gamedefines.INTERFACE_TYPE.WORLD_BOSS)
end


function CHuodong:RefreshWorldBoossRank(oPlayer)
    if self.m_Status ~= GAME_START then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local mRequest = {
    data = {pid=oPlayer:GetPid(),endui=1},
    }
    self:NotifyRank("GetExtraRankData",mRequest,function(mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            self:RefreshWorldBoossRank2(oPlayer,mData.data)
        end
        end)
end

function CHuodong:RefreshWorldBoossRank2(oPlayer,rankdata)
    local mNet = {}
    mNet.ranklist = rankdata.top20
    local mRank = rankdata.rank or {}
    mNet.myrank = {
        pid=oPlayer:GetPid(),
        name=oPlayer:GetName(),
        hit= mRank.hit or 0,
        shape=oPlayer:GetModelInfo().shape,
        rank = mRank.rank or 0,
    }
    if oPlayer.m_oStateCtrl:GetState(1005) then
        mNet["dead_cost"] = self:DeadCost(oPlayer)
    end
    oPlayer:Send("GS2CWorldBossRank",mNet)
end


function CHuodong:CloseBossUI(oPlayer)
    if oPlayer.m_oActiveCtrl:GetNowWar() then
        return
    end
    global.oInterfaceMgr:ClientClose(oPlayer,gamedefines.INTERFACE_TYPE.WORLD_BOSS)
end

function CHuodong:HPNotify(oPlayer)
    local oBoss = self:GetBoss()
    local mNet = {
    hp_max = oBoss.m_HP_MAX,
    hp = oBoss.m_HP,
    }
    oPlayer:Send("GS2CBossHPNotify",mNet)
end

function CHuodong:BossRemoveDeadBuff(oPlayer)
    if not oPlayer.m_oStateCtrl:GetState(1005) then
        return
    end
    local iCostVal = self:DeadCost(oPlayer)
    if not oPlayer:ValidGoldCoin(iCostVal) then
            return
    end

    oPlayer:ResumeGoldCoin(iCostVal , "异空流放锁定")
    oPlayer.m_oStateCtrl:RemoveState(1005)
    oPlayer.m_oToday:Add("wboss_rdead",1)
end


function CHuodong:DeadCost(oPlayer)
    return self:GetConfigValue("dead_cost")  * (oPlayer.m_oToday:Query("wboss_rdead",0) + 1)
end


function CHuodong:GetAbleState(oPlayer)
    return oPlayer.m_oStateCtrl:GetState(1002) or oPlayer.m_oStateCtrl:GetState(1006)
end

function CHuodong:RemoveAbleState(oPlayer)
    oPlayer.m_oStateCtrl:RemoveState(1002)
    oPlayer.m_oStateCtrl:RemoveState(1006)
end

function CHuodong:AddState(oPlayer,iShop)
    local oNotify = global.oNotifyMgr
    if self.m_Status ~=GAME_START then
        oNotify:Notify(oPlayer:GetPid(),"活动尚未开启")
        return
    end
    local oState = self:GetAbleState(oPlayer)
    if oState then
        oNotify:Notify(oPlayer:GetPid(),"你已经购买过BUFF了")
        return
    end
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["buff"]
    local mBuff = mData[iShop]
    if not mBuff then
        return
    end

    local iCostVal = mBuff["cost"]
    if not oPlayer:ValidCoin(iCostVal, {tip = "金币不足"}) then
        return
    end
    oPlayer:ResumeCoin(iCostVal , "封印之地 BUFF ")
    local iState = mBuff["state"]
    local oState = oPlayer.m_oStateCtrl:AddState(iState,{time=2*3600})
    oState:SetData("buff",mBuff["buff"])
    oNotify:Notify(oPlayer:GetPid(),"购买成功")
end

-- GM  Test

function CHuodong:TestOP(oPlayer,iFlag,...)
    local args={...}
    local oNotifyMgr = global.oNotifyMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    if iFlag == 100 then
        oChatMgr:HandleMsgChat(oPlayer,"101-生成BOSS")
        oChatMgr:HandleMsgChat(oPlayer,"103-活动结束")
        oChatMgr:HandleMsgChat(oPlayer,"104-清理资源")
        oChatMgr:HandleMsgChat(oPlayer,"105-调整BOSS等级")
        oChatMgr:HandleMsgChat(oPlayer,"106-給BOSS增加N點經驗")
        oChatMgr:HandleMsgChat(oPlayer,"108-查看BOSS屬性")
        oChatMgr:HandleMsgChat(oPlayer,"109-增加一天參加人數記錄 N")
        oChatMgr:HandleMsgChat(oPlayer,"110-强制设置BOSS最大血气")
        oChatMgr:HandleMsgChat(oPlayer,"111-以X伤害加入排行")
        oChatMgr:HandleMsgChat(oPlayer,"112-发击杀奖励")
        oChatMgr:HandleMsgChat(oPlayer,"113-已第X名获得奖励")
        oChatMgr:HandleMsgChat(oPlayer,"114-增加一次未被击败次数")
    elseif iFlag == 101 then
        local sF = args[1]
        if sF then
            self:DelTimeCb("_GameOver2")
            self:DelTimeCb("_GameOver1")
            self.m_Status = GAME_OVER1
            self:GameOver1()
            self:GameOver2()
        elseif self.m_Status ~= GAME_OVER2 then
            oNotifyMgr:Notify(pid,"活动还未关闭，请执行huodong worldboss 103")
            return
        end
        self:GameStart()
    elseif iFlag == 103 then
        if self.m_Status == GAME_START then
            self:GameOver1()
            self:GameOver2()
        elseif self.m_Status == GAME_OVER1 then
            self:GameOver2()
        else
            oNotifyMgr:Notify(pid,"活动还未开始")
        end
    elseif iFlag == 104 then
        self:GameOver1()
        self:GameOver2()
    elseif iFlag == 105 then
        local iLv = tonumber(args[1])
        if not iLv then
            return
        end
        self:GetBoss().m_Grade = iLv
        oChatMgr:HandleMsgChat(oPlayer,string.format("Boss 等級調整爲 %d",iLv))
    elseif  iFlag == 106 then
        local iExp = tonumber(args[1])
        if not iExp then
            return
        end
        self:GetBoss():AddExp(iExp)
        oChatMgr:HandleMsgChat(oPlayer,string.format("Boss 增加了 %d 點經驗",iExp))
    elseif iFlag == 108 then
        local oBoss = self:GetBoss()
        local playinfo = string.format("玩家參加情況 %s,开启时的在线人数 %d " ,oBoss:PlayArg(),oBoss.m_PlayCnt)
        local msg = string.format("BOSS 等級 %s 存活次数:%s  經驗 %s 下次升级所需经验 %s 血氣 %s 类型 %s 战斗ID %s %s",oBoss.m_Grade,oBoss.m_AliveCnt,oBoss.m_Exp,oBoss:GetNextExp(),oBoss.m_HP_MAX,oBoss.m_Type,oBoss.m_Fight,playinfo)
        oChatMgr:HandleMsgChat(oPlayer,msg)
    elseif iFlag == 109 then
        local iN = tonumber(args[1])
        local oBoss = self:GetBoss()
        oBoss:Record(iN)
        oNotifyMgr:Notify(oPlayer:GetPid(),string.format("參加人數爲 %d",iN))
    elseif iFlag == 110 then
        local iHP = tonumber(args[1])
        local oBoss = self:GetBoss()
        oBoss.m_HP_MAX = iHP
        if oBoss.m_HP > oBoss.m_HP_MAX then
            oBoss.m_HP = iHP
        end
    elseif iFlag == 111 then
        local iHit = tonumber(args[1])
        local pid = oPlayer:GetPid()
        local mData  = {fighthit=iHit,hit=iHit,name=oPlayer:GetName(),inwar=false}
        self.m_PlayerList[pid] = mData
        local mRecord = {
                pid = pid,
                name = mData.name,
                hit = mData.fighthit,
                shape = oPlayer:GetModelInfo().shape
            }
        local mRank = {}
        mRank.rank_data = {mRecord}
        self:NotifyRank("PushDataToRank",mRank)
    elseif iFlag == 112 then
        local oBoss = self:GetBoss()
        local pid = oBoss.m_Killer
        oBoss.m_Killer = oPlayer:GetPid()
        local oldlist = self.m_PlayerList
        self.m_PlayerList = {}
        self.m_PlayerList[oPlayer:GetPid()] = {hit = 1,name=oPlayer:GetName()}
        self:RewardKill()
        oBoss.m_Killer = pid
        self.m_PlayerList = oldlist
    elseif iFlag == 113 then
        local oBoss = self:GetBoss()
        local iN = tonumber(args[1])
        local old = oBoss.m_Killer
        local oldlist = self.m_PlayerList
        self.m_PlayerList = {}
        if args[2] then
            oBoss.m_Killer = oPlayer:GetPid()
        end
        local plist = {}
        for i=1,iN-1 do
            table.insert(plist,{rank=i,pid=0})
            self.m_PlayerList[0] = {hit=1,name=""}
        end
        table.insert(plist,{rank=iN,pid=oPlayer:GetPid()})
        self:RewardTop500(plist)
        oBoss.m_Killer = old
        self.m_PlayerList = oldlist
    elseif iFlag == 114 then
        local oBoss = self:GetBoss()
        oBoss:Alive()
    elseif iFlag == 115 then
        local iHp = tonumber(args[1])
        self:HPChange(iHp,{{oPlayer:GetPid(),iHp}})
    elseif iFlag == 116 then
        self:EnterScene(oPlayer)
    elseif iFlag == 117 then
        oPlayer.m_oStateCtrl:AddState(1005,{time=self:GetConfigValue("dead_time")*10})
    elseif iFlag == 118 then
        self:BossRemoveDeadBuff(oPlayer)
    elseif iFlag == 119 then
        local iCnt = table_count(self.m_mSceneList)
        oChatMgr:HandleMsgChat(oPlayer,string.format("scenen cnt  %s ",iCnt))
    elseif iFlag == 999 then
        self:RefreshWorldBoossRank(oPlayer)
    end
end


--封印之地
CWorldBoss = {}
CWorldBoss.__index = CWorldBoss
inherit(CWorldBoss, logic_base_cls())

function CWorldBoss:New()
    local o = super(CWorldBoss).New(self)
    o.m_Grade=1
    o.m_Exp = 0
    o.m_Percent = 100
    o.m_Dead = 0
    o.m_Killer = 0
    o.m_KillerName = ""
    o.m_Type = 1
    o.m_Fight = 1001
    o.m_PlayCnt = 0
    o.m_AliveCnt = 0
    o.m_CommonCnt = 0
    o.m_BigBossCnt = 0
    o.m_Percent = 100
    o.m_LastNotifyPercent = 90
    return o
end


function CWorldBoss:Rebirth()
    self.m_Dead = 0
    self.m_Killer = 0
    self.m_RewardEnd = 0
    self.m_KillerName = ""
    self.m_LastNotifyPercent = 90
    self.m_Percent = 100
    self:Dirty()
    self:ChooseBoss()
    self:InitAttr()
end

function CWorldBoss:ChooseBoss()
    local res = require "base.res"
    local mFightList = res["daobiao"]["huodong"]["worldboss"]["bossfight"]
    local mCommon = {1,2,3,}
    local mBigBoss = {1001,}
    local iNew = self.m_Type
    local iWeekDay = get_weekday()
    if  iWeekDay ~= 1 then
        local iMax = #mCommon
        iNew = self.m_Type + 1
        if iNew > iMax then
            iNew = 1
        end
        self.m_CommonCnt = self.m_CommonCnt + 1
    else
        self.m_BigBossCnt  = self.m_BigBossCnt + 1
        iNew = 1001
    end
    self.m_Type = iNew
    local mData = mFightList[iNew]
    self.m_Fight = mData.fight
    local mFightData = self:GetFightData()
    self.m_Monster = mFightData["monster"][1]["monsterid"]
    self:Dirty()
end

function CWorldBoss:Name()
    return self.m_Name or "次元妖兽"
end

function CWorldBoss:IsBigBoss()
    return self.m_Type ==1001
end

function CWorldBoss:SaveDb()
    local mData = {}
    mData.grade = self.m_Grade
    mData.exp = self.m_Exp
    mData.dead = self.m_Dead
    mData.hpmax = self.m_HP_MAX
    mData.hp = self.m_HP
    mData.fid = self.m_Fight
    mData.type = self.m_Type
    mData.killer = self.m_Killer
    mData.killername = self.m_KillerName
    mData.alive_cnt = self.m_AliveCnt
    mData.com_cnt = self.m_CommonCnt
    mData.big_cnt = self.m_BigBossCnt
    return mData
end

function CWorldBoss:LoadDb(mData)
    mData = mData or {}
    self.m_Grade = mData.grade or 1
    self.m_Exp = mData.exp or 0
    self.m_Dead = mData.dead or 0
    self.m_HP_MAX = mData.hpmax or 0
    self.m_HP = mData.hp or 0
    self.m_Fight = mData.fid or 0
    self.m_Killer = mData.killer or 0
    self.m_KillerName = mData.killername or ""
    self.m_Type = mData.type or 1
    self.m_AliveCnt = mData.alive_cnt or 0
    self.m_CommonCnt = mData.com_cnt or 0
    self.m_BigBossCnt = mData.big_cnt or 0
end

function CWorldBoss:InitAttr()
    local oWorldMgr = global.oWorldMgr
    local mData = self:GetMonsterData()
    self.m_PlayCnt = table_count(oWorldMgr:GetOnlinePlayerList())
    local mEnv = {
        bosslv = self.m_Grade,
        playcnt = self:PlayArg() ,
    }

    local iHp = formula_string(mData["maxhp"],mEnv)
    local mSkill = mData["activeSkills"]
    local skill_list = {}
    for _,mFData in pairs(mSkill) do
        local iSkill = mFData["pfid"]
        table.insert(skill_list,iSkill)
    end
    self.m_Shape = mData["model_id"]
    self.m_Skill = skill_list
    self.m_HP_MAX = iHp
    self.m_HP = self.m_HP_MAX
    self.m_Name =  mData["name"] or "次元妖兽"
end

function CWorldBoss:GetMonsterData()
    local oHuodong = self:GetHuoDong()
    return oHuodong:GetMonsterData(self.m_Monster)
end

function CWorldBoss:GetFightData()
    local oHuodong = self:GetHuoDong()
    return oHuodong:GetTollGateData(self.m_Fight)
end

function CWorldBoss:IsDead()
    return self.m_Dead ~= 0
end

function CWorldBoss:CheckUpgrade()
    local iNext = self:GetNextExp()
    if self.m_Exp >= iNext then
        self.m_Grade = self.m_Grade + 1
        self.m_Exp = 0
    end
end

function CWorldBoss:GetNextExp()
    local res = require "base.res"
    local mExp = res["daobiao"]["huodong"]["worldboss"]["expconfig"][self.m_Grade]
    if not mExp then
        return 2100000000
    end
    return mExp["exp"]
end

function CWorldBoss:Alive()
    if self.m_Grade <= 1 then
        return
    end
    local res = require "base.res"
    local mExp = res["daobiao"]["huodong"]["worldboss"]["expconfig"][self.m_Grade]
    if not mExp then
        return
    end
    self:Dirty()
    self.m_AliveCnt = self.m_AliveCnt + 1

    if mExp["demote"] < self.m_AliveCnt then
        self.m_Grade = self.m_Grade - 1
        self.m_AliveCnt = 0
        self.m_Exp = 0
    end
end


function CWorldBoss:AddExp(iExp)
    self.m_Exp = self.m_Exp + iExp
    self:CheckUpgrade()
    self:Dirty()
end

function CWorldBoss:GetHuoDong()
    return global.oHuodongMgr:GetHuodong("worldboss")
end

function CWorldBoss:Dirty()
    self:GetHuoDong():Dirty()
end

function CWorldBoss:Record(iCnt)
    self:Dirty()
end

function CWorldBoss:PlayArg()
    local oHuodong = self:GetHuoDong()
    return math.max(self.m_PlayCnt*oHuodong:GetConfigValue("cntratio"),oHuodong:GetConfigValue("playcnt"))
end

function CWorldBoss:HPCHange(iHp)
    self.m_HP = self.m_HP - iHp
    if self.m_HP <= 0 then
        self.m_Dead = 1
        self.m_HP = 0
    end
end

function CWorldBoss:HPPerChange()
    local iPer
    if self.m_HP_MAX <= 0 then
        iPer = 0
    else
        iPer = self.m_HP *100 // self.m_HP_MAX
        if iPer ==0 then
            iPer =1
        end
    end
    self.m_Percent = iPer
    return self.m_Percent
end













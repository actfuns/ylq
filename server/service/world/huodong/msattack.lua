--import module
local skynet = require "skynet"
local global  = require "global"
local extend = require "base.extend"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local loaditem = import(service_path("item/loaditem"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "msattack"
CHuodong.m_sTempName = "怪物攻城"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:Init()
    self.m_MonsterList = {}
    self.m_oBossObj = CMsattackBoss:New()
    self.m_GameState = 0
    self.m_MonsterID = 0
    self.m_CityDefend = 0
    self.m_MaxCityDefend = 0
    self.m_iScheduleID = 1020
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.boss = self.m_oBossObj:SaveDb()
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    self.m_oBossObj:LoadDb(mData.boss or {})
end

function CHuodong:AddCityDefend(iVal)
    local iOld = self.m_CityDefend
    self.m_CityDefend = self.m_CityDefend + iVal
    self.m_CityDefend = math.max(self.m_CityDefend,0)
    local iNew = self.m_CityDefend
    record.user("msattack", "defend", {
        old=iOld,
        new=iNew,
        sub=iVal,
    })
end

function CHuodong:ResetCityDefend()
    local res = require "base.res"
    local iTotal = res["daobiao"]["huodong"]["msattack"]["basecontrol"][1]["total"]
    self.m_CityDefend = iTotal
    self.m_MaxCityDefend = iTotal
end

function CHuodong:GetCityDefend()
    return self.m_CityDefend
end

function CHuodong:GetMaxCityDefend()
    return self.m_MaxCityDefend
end

function CHuodong:DispatchMonsterID()
    return global.oNpcMgr:DispatchId()
end

function CHuodong:IsClose()
    local res = require "base.res"
    local mControlData = res["daobiao"]["global_control"][self.m_sName]
    if not mControlData then
        return true
    end
    local sControl = mControlData["is_open"] or "y"
    if sControl == "n" then
        return true
    end
    return false
end

function CHuodong:NewHour(iWeekDay, iHour)
    if self:IsClose() then
        return
    end
    if table_in_list({3,6},iWeekDay) and iHour == 19 then
        self:AddTimeCb("MSBossTip",45 * 60 * 1000,function ()
            self:DelTimeCb("MSBossTip")
            self:GameStart()
        end)
    elseif table_in_list({3,6},iWeekDay) and iHour == 20 then
        self:GameStart2()
    elseif table_in_list({3,6},iWeekDay) and iHour == 21 then
        self:GameOver()
    else
        self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_CLOSE)
    end
end

function CHuodong:InitTime()
    local tbl = get_hourtime({hour=1})
    self.m_iStartTime = tbl.time
    self.m_iEndTime = tbl.time + 3600
end

function CHuodong:GS2CMSBossTip(oPlayer)
    local mNet = {
        starttime = self.m_iStartTime,
        endtime = self.m_iEndTime,
    }
    if oPlayer then
        oPlayer:Send("GS2CMSBossTip",mNet)
    else
        local mData = {
            message = "GS2CMSBossTip",
            type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
            id = 1,
            data = mNet,
            exclude = {}
        }
        interactive.Send(".broadcast","channel","SendChannel",mData)
    end
end

function CHuodong:OnLogin(oPlayer)
    if self:GetGameState() == 2 then
        local idList = table_key_list(self.m_MonsterList)
        if #idList > 0 then
            oPlayer.m_MsAttackIdList = idList
            self:SyncAttackMosterStep(oPlayer,1)
        end
        self:GS2COpenMsAttackUI(1,oPlayer)
        self:PushDataToMsAttackRank(oPlayer)
    elseif self:GetGameState() == 1 then
        self:GS2CMSBossTip(oPlayer)
    end
end

function CHuodong:SyncAttackMosterStep(oPlayer,idx)
    local iPid = oPlayer:GetPid()
    local sTimeFlag = "SyncAttack"..iPid
    self:DelTimeCb(sTimeFlag)
    local idList = oPlayer.m_MsAttackIdList or {}
    if idx+11 <= #idList then
        self:AddTimeCb(sTimeFlag, 2 * 1000, function ()
            local oWorldMgr = global.oWorldMgr
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                self:SyncAttackMosterStep(oPlayer,idx+11)
            end
        end)
    end
    local mNet = {npclist={}}
    for iNo=idx,idx+10 do
        local id = idList[iNo]
        local oNpc = self:GetMosterNpc(id)
        if oNpc and oNpc:IsAlive() then
            table.insert(mNet.npclist,oNpc:PackInfo())
        end
    end
    if #mNet.npclist > 0 then
        oPlayer:Send("GS2CMultiAttackMoster",mNet)
    end
end

function CHuodong:SetGameState(iState)
    self.m_GameState = iState
end

function CHuodong:IsOpen()
    return self.m_GameState ~= 0
end

function CHuodong:GetGameState()
    return self.m_GameState
end

function CHuodong:GameStart()
    self:SetGameState(1)
    self:InitTime()
    self:GS2CMSBossTip()
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendPrioritySysChat("MonsterAtk_char",self:GetTextData(1008),1)
end

function CHuodong:GameStart2()
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendPrioritySysChat("MonsterAtk_char",self:GetTextData(1001),1)
    local oWarMgr = global.oWarMgr
    for _,v in pairs(oWarMgr.m_lWarRemote) do
        interactive.Send(v,"msattack","StartBossWar",{win=1})
    end
    self:SetGameState(2)
    self:ClearRank()
    self.m_oBossObj:Reset()
    self:ResetCityDefend()
    self:CheckMonsterOver()
    self:RefreshNpc(1)
    self.m_EndTime = get_time() + 3600
    self:GS2COpenMsAttackUI(1)
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_START)
    self:MSBossHPNotify()
    record.info("msattack.gamestart")
    global.oWorldMgr:RecordOpen("msattack")
end

function CHuodong:ClearRank()
    interactive.Send(".rank","rank","CleanAllData",{rank_name="msattack"})
end

function CHuodong:GameOver(bBossDead)
    if not self:IsOpen() then
        return
    end
    local iText = 1002
    if bBossDead then
        iText = 1006
    end
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendPrioritySysChat("MonsterAtk_char",self:GetTextData(iText),1)

    self:SetGameState(0)
    self:GS2COpenMsAttackUI(0)
    self:DelTimeCb("SyncRanktoAll")
    self:DelTimeCb("RefreshNpc")
    self:DelTimeCb("CreateOneByOne")
    self:DelTimeCb("CheckMonsterOver")
    self:DelTimeCb("MSBossHPNotify")
    if bBossDead then
        self:StopAllWar(1)
    else
        self:StopAllWar(0)
    end
    self:ClearAll()
    self:BalanceReward()
    record.info("msattack.gameover")
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_OVER)
end

function CHuodong:StopAllWar(iWin)
    local oWarMgr = global.oWarMgr
    for _,v in pairs(oWarMgr.m_lWarRemote) do
        interactive.Send(v,"msattack","StopAllWar",{win=iWin})
    end
end

function CHuodong:BalanceReward()
    interactive.Request(".rank","rank","GetMsattackRewardList",{},function(mRecord,mData)
        self:BalanceReward2(mData.data)
    end)
end

function CHuodong:BalanceReward2(mResult)
    mResult = mResult or {}
    local mRank = mResult.rank or {}
    local mJoin = mResult.join or {}

    local oMailMgr = global.oMailMgr
    -- local iID = 1
    -- for iRank,info in ipairs(mRank) do
    --     local iPid,iPoint = table.unpack(info)
    --     local mConfig
    --     for iNo=1,10 do
    --         mConfig = self:GetRankRewardList(iID)
    --         if mConfig and mConfig["desc"] >= iRank then
    --             break
    --         end
    --         if not mConfig then
    --             break
    --         end
    --         iID = iID + 1
    --     end
    --     if not mConfig then
    --         break
    --     end
    --     local mMail, sMail = oMailMgr:GetMailInfo(62)
    --     mMail.context = string.gsub(mMail.context,"$point",iPoint)
    --     mMail.context = string.gsub(mMail.context,"$rank",iRank)
    --     oMailMgr:SendMail(0, sMail, iPid, mMail, {},self:CreateItemList(mConfig["rewardlist"]))
    -- end
    local mMail, sMail = oMailMgr:GetMailInfo(61)
    local iDefend = self:GetCityDefend()
    local mRewardList = self:GetDefendRewardList()
    local mRewardInfo
    for _,info in ipairs(mRewardList) do
        mRewardInfo = info
        if iDefend >= info.value then
            break
        end
    end
    if mRewardInfo then
        for iPid,_ in pairs(mJoin) do
            oMailMgr:SendMail(0, sMail, iPid, mMail, {},self:CreateItemList(mRewardInfo["rewardlist"]))
        end
    end
end

function CHuodong:CreateItemList(mReward)
    local mItem = {}
    for _,mInfo in pairs(mReward) do
        local sShape,iAmount = mInfo["sid"],mInfo["num"]
        local oItem = loaditem.ExtCreate(sShape)
        oItem:SetAmount(iAmount)
        table.insert(mItem,oItem)
    end
    return mItem
end

function CHuodong:GetRankRewardList(iNo)
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["rank_reward"][iNo]
end

function CHuodong:GetDefendRewardList()
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["defense_reward"]
end

function CHuodong:ClearAll()
    local mDel = table_key_list(self.m_MonsterList)
    for _,npcid in pairs(mDel) do
        local oNpc = self:GetMosterNpc(npcid)
        if oNpc then
            local iPoint = oNpc:Point()
            self:AddCityDefend(-iPoint)
        end
        self:ClearHDNpc(npcid)
    end
    self:GS2CDelAttackMoster(mDel)
end

function CHuodong:GetRefreshConfig()
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["refresh"]
end

function CHuodong:GetNidListByType(sType)
    local sFlag = sType .. "_nid"
    local res = require "base.res"
    return res["daobiao"]["huodong"]["msattack"]["basecontrol"][1][sFlag]
end

function CHuodong:ProductNpcNidList(mList,sType,iCnt)
    local nList = self:GetNidListByType(sType)
    local iLen = #nList
    for iNo=1,iCnt do
        table.insert(mList,{
            sType,
            nList[math.random(iLen)]
        })
    end
end

function CHuodong:CheckHaveMonster()
    if next(self.m_MonsterList) then
        return
    end
    if self.m_FinishWave ~= self.m_MsWave then
        return
    end
    if self.m_MsWave >= 10 then
        self:GameOver(true)
        return
    end
    self:RefreshNpc(self.m_MsWave+1)
end

function CHuodong:GetNpcLimitCnt(sFlag)
    local res = require "base.res"
    return res["daobiao"]["huodong"]["msattack"]["basecontrol"][1][sFlag]
end

function CHuodong:RefreshNpc(iStep)
    self:DelTimeCb("RefreshNpc")
    local mConfig = self:GetRefreshConfig()
    mConfig = mConfig[iStep]
    if not mConfig then
        return
    end
    if iStep == 1 then
        self.m_FinishWave = 0
    end
    self.m_MsWave = iStep
    local iNextTime = mConfig["next_time"] * 60
    local iNextNpcTime = mConfig["dis_small_time"]
    local iCnt = global.oWorldMgr:GetNearOnlinePlayerCnt()
    iCnt = math.max(iCnt,1)
    local iSmall = formula_string(mConfig["small"],{online=iCnt})
    local iMiddle = formula_string(mConfig["middle"],{online=iCnt})
    local iLarge = formula_string(mConfig["large"],{online=iCnt})
    local iMinNum = self:GetNpcLimitCnt("math_min")
    local iMaxNum = self:GetNpcLimitCnt("math_max")
    local mList = {}
    iSmall = math.min(iSmall,iMaxNum)
    iSmall = math.max(iSmall,iMinNum)
    iMiddle = math.min(iMiddle,iMaxNum)
    iMiddle = math.max(iMiddle,iMinNum)
    self:ProductNpcNidList(mList,"small",iSmall)
    self:ProductNpcNidList(mList,"middle",iMiddle)
    -- self:ProductNpcNidList(mList,"large",iLarge)
    self.m_TmpList = mList
    self:CreateOneByOne(iStep,1)
    self.m_NextRefreshTime = 0
    if iNextTime > 0 then
        self:AddTimeCb("RefreshNpc", iNextTime * 1000, function ()
            self:RefreshNpc(iStep+1)
        end)
        self.m_NextRefreshTime = get_time() + iNextTime
    end
    self:GS2COpenMsAttackUI(1)
    record.user("msattack", "refresh", {
        small=iSmall,
        middle=iMiddle,
        large=iLarge,
    })
end

function CHuodong:CreateOneByOne(iStep,iNo)
    self:DelTimeCb("CreateOneByOne")
    local mConfig = self:GetRefreshConfig()
    mConfig = mConfig[iStep]
    if not mConfig then
        return
    end
    local mTmpList = self.m_TmpList
    if not mTmpList[iNo] then
        return
    end
    local sType,nid = table.unpack(mTmpList[iNo])
    if iNo+1 <= #mTmpList then
        local sNextType,_ = table.unpack(mTmpList[iNo+1])
        local iNextNpcTime = mConfig["dis_"..sNextType.."_time"]
        self:AddTimeCb("CreateOneByOne", iNextNpcTime * 1000, function ()
            self:CreateOneByOne(iStep,iNo+1)
        end)
    else
        self.m_FinishWave = iStep
    end
    self:CreateHDNpc(sType,nid)
end

function CHuodong:CreateHDNpc(sType,nid)
    local npcid = self:DispatchMonsterID()
    local oNpc = NewHDNpc({
        id = npcid,
        nid = nid,
        type = sType
    })
    self.m_MonsterList[npcid] = oNpc
    oNpc:PackInfo()
    oNpc:GS2CRefreshNpc()
    if oNpc:IsBoss() then
        self.m_oBossObj:SetNpcID(npcid)
        local oNotifyMgr = global.oNotifyMgr
        local mData = self:GetTempNpcData(nid)
        local iMapID = mData.mapId
        local oSceneMgr = global.oSceneMgr
        local oScene = oSceneMgr:SelectDurableScene(iMapID)
        local sText = self:GetTextData(1003)
        sText = string.gsub(sText,"$map",oScene:GetName())
        oNotifyMgr:SendPrioritySysChat("MonsterAtk_char",sText,1)
    end
end

function CHuodong:GetMosterNpc(id)
    return self.m_MonsterList[id]
end

function CHuodong:MSBossHPNotify()
    self:DelTimeCb("MSBossHPNotify")
    self:AddTimeCb("MSBossHPNotify",3*1000,function ()
        self:MSBossHPNotify()
    end)
    local oBoss = self.m_oBossObj
    if oBoss then
        local mNet = {
            hp = oBoss:GetHp(),
            hp_max = oBoss:GetHpMax(),
        }
        local mData = {
            message = "GS2CMSBossHPNotify",
            type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
            id = 1,
            data = mNet,
            exclude = {}
        }
        interactive.Send(".broadcast","channel","SendChannel",mData)
    end
end

function CHuodong:CheckMonsterOver()
    self:DelTimeCb("CheckMonsterOver")
    self:AddTimeCb("CheckMonsterOver", 60 * 1000, function ()
        self:CheckMonsterOver()
    end)
    local mDel = {}
    local bBossDead = false
    for id,oNpc in pairs(self.m_MonsterList) do
        if not oNpc:InWar() and not oNpc:IsAlive() then
            table.insert(mDel,id)
        end
        if oNpc:IsBoss() and not oNpc:IsAlive() then
            bBossDead = true
            table.insert(mDel,id)
            break
        end
    end
    if bBossDead then
        self:DelTimeCb("CheckMonsterOver")
        self.m_oBossObj:AddAlive()
        self:GameOver()
        return
    end
    for _,id in pairs(mDel) do
        local oNpc = self:GetMosterNpc(id)
        if oNpc then
            local iPoint = oNpc:Point()
            self:AddCityDefend(-iPoint)
        end
        self:ClearHDNpc(id)
    end
    if #mDel > 0 then
        self:GS2CDelAttackMoster(mDel)
        self:GS2COpenMsAttackUI(1)
        self:CheckHaveMonster()
    end
end

function CHuodong:ClearHDNpc(id)
    local oNpc = self.m_MonsterList[id]
    self.m_MonsterList[id] = nil
    if oNpc then
        baseobj_safe_release(oNpc)
    end
end

function CHuodong:GetNpcPackInfo(nid)
    local mData = self:GetTempNpcData(nid)
    local oScene = global.oSceneMgr:SelectDurableScene(tonumber(mData.mapId))
    return {
        name = mData.name,
        title = mData.title,
        model_info = {
            shape = mData.modelId,
            scale = mData.scale,
            color = mData.mutateColor,
            mutate_texture = mData.mutateTexture,
            weapon = mData.wpmodel,
            adorn =mData.ornamentId,
        },
        map_id = mData.mapId,
        sceneid = oScene:GetSceneId(),
        path_id = mData.path_id or 0,
    }
end

function CHuodong:GetCreateWarArg(mArg)
    mArg = mArg or {}
    mArg.remote_war_type = "msattack"
    mArg.war_type = gamedefines.WAR_TYPE.MSATTACK
    return mArg
end

function CHuodong:TransMonsterAble(oWar,sAttr,mArgs)
    local mEnv = mArgs.env or {}
    mEnv.bosslv = self.m_oBossObj:GetGrade()
    mEnv.playcnt = self.m_oBossObj:PlayArg()
    mArgs.env = mEnv
    return math.floor(super(CHuodong).TransMonsterAble(self,oWar,sAttr,mArgs))
end

function CHuodong:GetGradeLimit()
    local res = require "base.res"
    return res["daobiao"]["global_control"][self.m_sName]["open_grade"]
end

function CHuodong:FightAttackMoster(oPlayer,npcid)
    if oPlayer:GetGrade() < self:GetGradeLimit() then
        oPlayer:NotifyMessage(self:GetTextData(1005))
        return
    end
    local oNpc = self:GetMosterNpc(npcid)
    if not oNpc then
        return
    end
    if oNpc:InWar() and not oNpc:IsBoss() then
        oPlayer:NotifyMessage(self:GetTextData(1004))
        return
    end
    local iPid = oPlayer:GetPid()
    local oCbMgr = global.oCbMgr
    local mNet = oCbMgr:PackConfirmData(nil, {
        uitype = 0,default = 0,time = 30,
        sContent = "是否攻击["..oNpc:GetName().."]",
        sConfirm = "确定",
        sCancle = "取消",
    })
    local func = function (oResponse,mData)
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer and mData.answer ==1 then
            self:FightAttackMoster2(oPlayer,npcid)
        end
    end
    oCbMgr:SetCallBack(iPid,"GS2CConfirmUI",mNet,nil,func)
end

function CHuodong:FightAttackMoster2(oPlayer,npcid)
    local oWorldMgr = global.oWorldMgr
    local oNpc = self:GetMosterNpc(npcid)
    if not oNpc then
        return
    end
    if oNpc:InWar() and not oNpc:IsBoss() then
        oPlayer:NotifyMessage(self:GetTextData(1004))
        return
    end
    if oPlayer and oPlayer.m_oActiveCtrl:GetNowWar() then
        return
    end
    local iPid = oPlayer:GetPid()
    self:AddKeep(iPid,"wardiff",oNpc:Type())
    local nid = oNpc:Nid()
    local iFight = oNpc:GetFightID()
    local oWar = self:Fight(iPid,nil,iFight)
    local plist = oPlayer:AllMember()
    for _,pid in ipairs(plist) do
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        if pobj then
            pobj:AddSchedule("msattack")
            pobj:RecordPlayCnt("msattack",1)
        end
    end
    oWar.m_TmpNpcID = npcid
    oWar.m_TmpType = oNpc:Type()
    oNpc:EnterWar(iPid)
    oNpc:GS2CRefreshNpc()
end

function CHuodong:CreateMonster(oWar,iMonsterIdx,npcobj)
    local oMonster = super(CHuodong).CreateMonster(self,oWar,iMonsterIdx,npcobj)
    if oMonster:GetAttr("boss") == 1 then
        oMonster:SetAttr("hp", self.m_oBossObj:GetHp())
        oMonster:SetAttr("maxhp", self.m_oBossObj:GetHpMax())
    end
    return oMonster
end

function CHuodong:CreateWar(pid,npcobj,iFight,mInfo)
    local sType = self:GetKeep(pid,"wardiff","small")
    mInfo = mInfo or {}
    mInfo.enter_arg ={extra_info={{key="diff",value=sType}}}
    return super(CHuodong).CreateWar(self,pid,npcobj,iFight,mInfo)
end

function CHuodong:GetServant(oWar,mArgs)
    local iFight = oWar.m_FightIdx
    local mConfig = self:GetTollGateData(iFight)
    local mMonsterList = mConfig["call_monster"] or {}
    local mServant = {}
    for _,iMonsterIdx in ipairs(mMonsterList) do
        local oMonster = self:CreateMonster(oWar,iMonsterIdx,nil, mArgs)
        mServant[iMonsterIdx] = oMonster:PackAttr()
    end
    return mServant
end

function CHuodong:GetMonsterPoint(sFlag)
    local res = require "base.res"
    return res["daobiao"]["huodong"]["msattack"]["basecontrol"][1][sFlag]
end

function CHuodong:OnWarEnd(oWar, iPid, oNpc, mArgs, bWin)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local npcid = oWar.m_TmpNpcID
    local oNpc = self:GetMosterNpc(npcid)
    if oNpc and not oNpc:IsBoss() then
        if bWin then
            oNpc:AddFightFail()
        end
        oNpc:LeaveWar(iPid)
        oNpc:GS2CRefreshNpc()
        if oNpc:IsDead() then
            self:ClearHDNpc(npcid)
            self:GS2CDelAttackMoster({npcid})
            self:CheckHaveMonster()
        end
    end
    local sType = oWar.m_TmpType
    if oPlayer and bWin then
        local sFlag = sType .. "_fight_point"
        local iPoint = self:GetMonsterPoint(sFlag)
        local memlist = mArgs.win_list or {}
        local iFight = oWar.m_FightIdx
        local mFight = self:GetTollGateData(iFight)
        local mReward = mFight["rewardtbl"] or {}
        local sMsg = self:GetTextData(1007)
        for _,mid in pairs(memlist) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem then
                for _,info in ipairs(mReward) do
                    self:Reward(mid,info.rewardid,{chuanwen=sMsg})
                end
                self:LogWarReward(oMem)
                if iPoint then
                    self:AddPoint(oMem,iPoint,"战斗奖励")
                    self:PushDataToMsAttackRank(oMem)
                end
            end
        end
    end
    if sType == "large" then
        self:ProcessBossWarEnd(oPlayer)
    end
end

function CHuodong:ProcessBossWarEnd(oPlayer)
    local res = require "base.res"
    local sCoin = res["daobiao"]["huodong"]["msattack"]["basecontrol"][1]["large_damage_coin"]
    local oWorldMgr = global.oWorldMgr
    if oPlayer then
        local memlist = oPlayer:GetTeamMember() or {oPlayer:GetPid()}
        for _,mid in pairs(memlist) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem then
                local iDamage = self:GetPlayerDamage(oMem)
                local iCoin = 0
                local mEnv = {
                    damage = iDamage
                }
                if iDamage > 0 then
                    iCoin = formula_string(sCoin,mEnv)
                    self:RewardCoin(oMem,iCoin)
                end
                self:GS2CMSBossWarEnd(oMem,iDamage,iCoin)
                self:ClearPlayerDamage(oMem)
            end
        end
    end
end

function CHuodong:GS2CMSBossWarEnd(oPlayer,iDamage,iCoin)
    local oBoss = self.m_oBossObj
    local mNet = {
            hit = iDamage,
            all_hit = oBoss:GetHpMax() - oBoss:GetHp(),
            hit_per = math.ceil(iDamage*100/oBoss:GetHpMax()),
            coin = iCoin,
    }
    oPlayer:Send("GS2CMSBossWarEnd",mNet)
end

function CHuodong:AddPlayerDamage(oPlayer,iDamage)
    oPlayer.m_oToday:Add("ms_damage",iDamage)
end

function CHuodong:GetPlayerDamage(oPlayer)
    return oPlayer.m_oToday:Query("ms_damage",0)
end

function CHuodong:ClearPlayerDamage(oPlayer)
    oPlayer.m_oToday:Delete("ms_damage")
end

function CHuodong:LogWarReward(oPlayer)
    local mKeepItem = self:GetKeep(oPlayer:GetPid(), "item", {})
    local mItem = {}
    for iShape,info in pairs(mKeepItem) do
        for _,amount in pairs(info) do
            mItem[iShape] = mItem[iShape] or 0
            mItem[iShape] = mItem[iShape] + amount
        end
    end
    record.user("msattack", "reward", {
        pid=oPlayer:GetPid(),
        item = ConvertTblToStr(mItem),
    })
end

function CHuodong:AddPoint(oPlayer,iVal,sReason)
    local iOld = oPlayer.m_oToday:Query("ms_point",0)
    oPlayer.m_oToday:Add("ms_point",iVal)
    local iNew = oPlayer.m_oToday:Query("ms_point",0)
    record.user("msattack", "addpoint", {
        pid=oPlayer:GetPid(),
        old = iOld,
        point = iNew,
        add = iVal,
        reason = sReason,
    })
end

function CHuodong:GetPoint(oPlayer)
    return oPlayer.m_oToday:Query("ms_point",0)
end

function CHuodong:PushDataToMsAttackRank(oPlayer)
    global.oRankMgr:PushDataToMsAttackRank(oPlayer)
    self:DelTimeCb("SyncRanktoAll")
    self:AddTimeCb("SyncRanktoAll", 1000, function ()
        self:SyncRanktoAll()
    end)
end

function CHuodong:SyncRanktoAll()
    self:DelTimeCb("SyncRanktoAll")
    self:AddTimeCb("SyncRanktoAll", 60 * 1000, function ()
        self:SyncRanktoAll()
    end)
    interactive.Send(".rank","rank","SyncMSRanktoAll",{})
end

function CHuodong:DamageBoss(mDamage)
    local res = require "base.res"
    local sPoint = res["daobiao"]["huodong"]["msattack"]["basecontrol"][1]["large_damage_point"]
    mDamage = mDamage or {}
    local iDamage = 0
    for iPid,iSub in pairs(mDamage) do
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local mEnv = {
                damage = iSub,
                maxhp = self.m_oBossObj:GetHpMax(),
                playcnt = self:GetPlayerCnt(),
            }
            local iPoint = formula_string(sPoint,mEnv)
            self:AddPoint(oPlayer,iPoint,"击打boss")
            self:AddPlayerDamage(oPlayer,iSub)
            self:PushDataToMsAttackRank(oPlayer)
        end
        iDamage = iDamage + iSub
    end
    local oBossObj = self.m_oBossObj
    if oBossObj then
        oBossObj:AddHp(iDamage)
        if oBossObj:IsDead() then
            oBossObj:AddExp(1)
            self:GameOver(true)
        end
    end
end

function CHuodong:BossDead(iWin)
    local oWarMgr = global.oWarMgr
    for _,v in pairs(oWarMgr.m_lWarRemote) do
        interactive.Send(v,"msattack","BossDie",{win=iWin})
    end
end

function CHuodong:GS2CDelAttackMoster(idList)
    local mData = {
        message = "GS2CDelAttackMoster",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = {idlist=idList},
        exclude = {}
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end

function CHuodong:GS2COpenMsAttackUI(iOpen,oPlayer)
    local mNet = {
        open = iOpen,
        defend = self:GetCityDefend(),
        defend_max = self:GetMaxCityDefend(),
        nexttime = self.m_NextRefreshTime,
        wave = self.m_MsWave or 1,
        endtime = self.m_EndTime,
    }
    if oPlayer then
        oPlayer:Send("GS2COpenMsAttackUI",mNet)
    else
        local mData = {
            message = "GS2COpenMsAttackUI",
            type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
            id = 1,
            data = mNet,
            exclude = {}
        }
        interactive.Send(".broadcast","channel","SendChannel",mData)
    end
end

function CHuodong:GetPlayerCnt()
    if self.m_TestCnt then
        return self.m_TestCnt
    end
    return self.m_oBossObj:PlayArg()
end

function CHuodong:TestOP(oPlayer,iFlag,...)
    if iFlag == 100 then
        local oChatMgr = global.oChatMgr
        oChatMgr:HandleMsgChat(oPlayer,"101-活动预热")
        oChatMgr:HandleMsgChat(oPlayer,"102-活动开始")
        oChatMgr:HandleMsgChat(oPlayer,"103-活动结束")
        oChatMgr:HandleMsgChat(oPlayer,"104 val -加积分")
        oChatMgr:HandleMsgChat(oPlayer,"105-推数据上排行榜")
    elseif iFlag == 101 then
        self:GameStart()
    elseif iFlag == 102 then
        self:GameStart2()
    elseif iFlag == 103 then
        self:GameOver()
    elseif iFlag == 104 then
        local iVal = tonumber(...)
        self:AddPoint(oPlayer,iVal,"gm指令")
    elseif iFlag == 105 then
        global.oRankMgr:PushDataToMsAttackRank(oPlayer)
    elseif iFlag == 106 then
        self:SyncRanktoAll()
    elseif iFlag == 107 then
        local iStep = tonumber(...)
        self:RefreshNpc(iStep)
    elseif iFlag == 108 then
        local iCnt = tonumber(...)
        self.m_TestCnt = iCnt
    elseif iFlag == 109 then
        self:GS2COpenMsAttackUI(1,oPlayer)
    elseif iFlag == 110 then
        self:ClearRank()
    end
end

function NewHDNpc(mArg)
    return CHDNpc:New(mArg)
end

CHDNpc = {}
CHDNpc.__index = CHDNpc
inherit(CHDNpc, datactrl.CDataCtrl)

function CHDNpc:New(mArg)
    local o = super(CHDNpc).New(self)
    o.m_CreateTime = get_time()
    o.m_ID = mArg.id
    o.m_Nid = mArg.nid
    o.m_Type = mArg.type
    o.m_bWar = false
    o.m_mWarList = {}
    o.m_WarCnt = 0
    return o
end

function CHDNpc:Type()
    return self.m_Type
end

function CHDNpc:Nid()
    return self.m_Nid
end

function CHDNpc:Point()
    local sFlag = self.m_Type.."_point"
    local res = require "base.res"
    return res["daobiao"]["huodong"]["msattack"]["basecontrol"][1][sFlag]
end

function CHDNpc:GetFightID()
    local res = require "base.res"
    return res["daobiao"]["huodong"]["msattack"]["npc"][self.m_Nid]["tollgateId"]
end

function CHDNpc:AddFightFail()
    self.m_FightFail = self.m_FightFail or 0
    self.m_FightFail = self.m_FightFail + 1
end

function CHDNpc:GetHitCnt()
    if self.m_HitCnt then
        return self.m_HitCnt
    end
    local sFlag = self.m_Type.."_hit_cnt"
    local res = require "base.res"
    local sValue = res["daobiao"]["huodong"]["msattack"]["basecontrol"][1][sFlag]
    if not sValue then return 1 end
    local oHuodong = self:GetHDObj()
    local mEnv = {
        playcnt = oHuodong:GetPlayerCnt() ,
    }
    local iCnt = math.floor(formula_string(sValue,mEnv))
    self.m_HitCnt = iCnt
    return self.m_HitCnt
end

function CHDNpc:IsDead()
    local iFightFail = self.m_FightFail or 0
    if iFightFail >= self:GetHitCnt() then
        return true
    end
    return false
end

function CHDNpc:GetRestHit()
    local iCnt = self:GetHitCnt()
    local iFightFail = self.m_FightFail or 0
    return iCnt - iFightFail
end

function CHDNpc:AliveTime()
    local oHuodong = self:GetHDObj()
    local mData = oHuodong:GetTempNpcData(self.m_Nid)
    return mData["alive"]
end

function CHDNpc:IsAlive()
    if not self.m_EndTime then
        local iAliveTime = self:AliveTime()
        local iEndTime = self.m_CreateTime + iAliveTime
        self.m_EndTime = iEndTime
    end
    if get_time() > self.m_EndTime then
        return false
    end
    return true
end

function CHDNpc:EnterWar(iPid)
    self.m_mWarList[iPid] = true
    if table_count(self.m_mWarList) >= self:GetRestHit() then
        self.m_bWar = true
    end
end

function CHDNpc:InWar()
    return self.m_bWar
end

function CHDNpc:LeaveWar(iPid)
    self.m_mWarList[iPid] = nil
    if table_count(self.m_mWarList) < self:GetRestHit() then
        self.m_bWar = false
    end
end

function CHDNpc:IsBoss()
    return self.m_Type == "large"
end

function CHDNpc:GetHDObj()
    return global.oHuodongMgr:GetHuodong("msattack")
end

function CHDNpc:PackInfo()
    local bWar = self:InWar()
    if self:IsBoss() then
        bWar = false
    end
    if self.m_CacheNet then
        local mNet = self.m_CacheNet
        mNet.inwar = bWar
        return mNet
    end
    local oHuodong = self:GetHDObj()
    local mNet = oHuodong:GetNpcPackInfo(self.m_Nid)
    mNet.npctype = self.m_Type
    mNet.npcid = self.m_ID
    mNet.createtime = self.m_CreateTime
    mNet.inwar = bWar
    self.m_CacheNet = mNet
    return mNet
end

function CHDNpc:GetName()
    local mData = self:PackInfo()
    return mData.name or "未知怪物"
end

function CHDNpc:GS2CRefreshNpc()
    local mData = {
        message = "GS2CAddAttackMoster",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = {npcinfo=self:PackInfo()},
        exclude = {}
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end

--封印之地
CMsattackBoss = {}
CMsattackBoss.__index = CMsattackBoss
inherit(CMsattackBoss, logic_base_cls())

function CMsattackBoss:New()
    local o = super(CMsattackBoss).New(self)
    o.m_Grade=1
    o.m_Exp = 0
    o.m_bDead = false
    o.m_PlayCnt = 0
    o.m_AliveCnt = 0
    o.m_Monster = 40001
    o.m_HP_MAX = 0
    o.m_HP = 0
    o.m_NpcID = 0
    return o
end

function CMsattackBoss:GetHp()
    return self.m_HP
end

function CMsattackBoss:GetHpMax()
    return self.m_HP_MAX
end

function CMsattackBoss:GetGrade()
    local oWorldBoss = self:GetWorldBoss()
    return oWorldBoss.m_Grade
end

function CMsattackBoss:GetPlayerCnt()
    return self.m_PlayCnt
end

function CMsattackBoss:GetMonsterData()
    local oHuodong = self:GetHuoDong()
    return oHuodong:GetMonsterData(self.m_Monster)
end

function CMsattackBoss:GetHuoDong()
    return global.oHuodongMgr:GetHuodong("msattack")
end

function CMsattackBoss:Dirty()
    self:GetHuoDong():Dirty()
end

function CMsattackBoss:SaveDb()
    local mData = {}
    mData.grade = self.m_Grade
    mData.exp = self.m_Exp
    mData.alive_cnt = self.m_AliveCnt
    return mData
end

function CMsattackBoss:LoadDb(mData)
    mData = mData or {}
    self.m_Grade = mData.grade or 1
    self.m_Exp = mData.exp or 0
    self.m_AliveCnt = mData.alive_cnt or 0
end

function CMsattackBoss:PlayArg()
    local oHuodong = self:GetHuoDong()
    return math.max(self.m_PlayCnt*oHuodong:GetConfigValue("cntratio"),oHuodong:GetConfigValue("playcnt"))
end

function CMsattackBoss:GetWorldBoss()
    local oHuodong = global.oHuodongMgr:GetHuodong("worldboss")
    return oHuodong.m_Boss
end

function CMsattackBoss:Reset()
    local oWorldMgr = global.oWorldMgr
    local mData = self:GetMonsterData()
    local oWorldBoss = self:GetWorldBoss()
    self.m_PlayCnt = oWorldMgr:GetNearOnlinePlayerCnt()
    local mEnv = {
        bosslv = oWorldBoss.m_Grade,
        playcnt = self:PlayArg() ,
    }
    local iHp = math.floor(formula_string(mData["maxhp"],mEnv))
    self.m_bDead = false
    self.m_HP = iHp
    self.m_HP_MAX = iHp
    self:Dirty()
end

function CMsattackBoss:AddHp(iDamage)
    self.m_HP = self.m_HP - iDamage
    self.m_HP = math.max(self.m_HP,0)
    if self.m_HP <= 0 then
        self.m_bDead = true
    end
    self:Dirty()
end

function CMsattackBoss:IsDead()
    return self.m_bDead
end

function CMsattackBoss:GetNextExp()
    local res = require "base.res"
    local mExp = res["daobiao"]["huodong"]["msattack"]["expconfig"][self.m_Grade]
    if not mExp then
        return 2100000000
    end
    return mExp["exp"]
end

function CMsattackBoss:AddExp(iExp)
    local oWorldBoss = self:GetWorldBoss()
    oWorldBoss:AddExp(iExp)
    self:Dirty()
    -- self:Dirty()
    -- self.m_Exp = self.m_Exp + iExp
    -- local iNext = self:GetNextExp()
    -- if self.m_Exp >= iNext then
    --     self.m_Grade = self.m_Grade + 1
    --     self.m_Exp = 0
    -- end
end

function CMsattackBoss:AddAlive()
    local oWorldBoss = self:GetWorldBoss()
    oWorldBoss:Alive()
    self:Dirty()
    -- if self.m_Grade <= 1 then
    --     return
    -- end
    -- local res = require "base.res"
    -- local mExp = res["daobiao"]["huodong"]["msattack"]["expconfig"][self.m_Grade]
    -- if not mExp then
    --     return
    -- end
    -- self:Dirty()
    -- self.m_AliveCnt = self.m_AliveCnt + 1
    -- if mExp["demote"] < self.m_AliveCnt then
    --     self.m_Grade = self.m_Grade - 1
    --     self.m_AliveCnt = 0
    --     self.m_Exp = 0
    -- end
end

function CMsattackBoss:SetNpcID(npcid)
    self.m_NpcID = npcid
end

function CMsattackBoss:GetNpcID()
    return self.m_NpcID
end
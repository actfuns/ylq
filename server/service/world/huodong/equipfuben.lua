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
local handleitem = import(service_path("item.handleitem"))
local loaditem = import(service_path("item.loaditem"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "埋骨之地"
inherit(CHuodong, huodongbase.CHuodong)

FLOOR_MARK = 1000
MIN_CACHE = 3
CACHE_THRESHOLD = 100
SWEEP_ITEM = 10030

function CHuodong:Init()
    self.m_FubenList = {}
    self.m_EmptyList = {}
    self.m_GameID = 0
    self:TryCleanFuBen()
    self:TryStartRewardMonitor()
    self.m_FBName = {[1]="前庭",[2]="暗道",[3]="秘牢"}
end

function CHuodong:GetFubenData(oPlayer)
    return oPlayer.m_oHuodongCtrl:GetData("EquipFBData",{})
end

function CHuodong:SetFubenData(oPlayer,mData)
    oPlayer.m_oHuodongCtrl:SetData("EquipFBData",mData)
end

function CHuodong:GetFuBenByID(oPlayer,iFB)
    local mData = self:GetFubenData(oPlayer)
    return mData[db_key(iFB)] or {}
end

function CHuodong:GetFloorHistoryStar(oPlayer, iFloor)
    local mData = self:GetFubenData(oPlayer)
    local mFloorInfo = mData["floor"]
    local sFloor = db_key(iFloor)
    if mFloorInfo and mFloorInfo[sFloor] then
        return mFloorInfo[sFloor]["star"] or 0
    end
    return 0
end

function CHuodong:GetFloorSumStar(oPlayer, iFloor)
    local mData = self:GetFubenData(oPlayer)
    local mStarFloor = mData["star_floor"]
    if mStarFloor and mStarFloor[iFloor] then
        return mStarFloor[iFloor] or 0
    end
    return 0
end

function CHuodong:SetFloorSumStar(oPlayer, iFloor, iSumStar)
    local mData = self:GetFubenData(oPlayer)
    local mStarFloor = mData["star_floor"] or {}
    mStarFloor[iFloor] =  iSumStar
    mData["star_floor"] = mStarFloor
    self:SetFubenData(oPlayer, mData)
end


function CHuodong:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
    end
end


function CHuodong:FloorData(iFloor)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["floor"][iFloor]
    assert(mData,string.format("err floordata %d",iFloor))
    return mData
end

function CHuodong:FuBenData(iFB)
    local mData = self:FuBenList()[iFB]
    assert(mData,string.format("err fubendata %d",iFB))
    return mData
end

function CHuodong:FuBenList()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["fuben"]
    return mData
end

function CHuodong:GetFuBenGame(gid)
    return self.m_FubenList[gid]
end

function CHuodong:GetFuBenGameByPlayer(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local gid = oNowScene.m_EquiFuBenGame
    return self:GetFuBenGame(gid)
end

function CHuodong:TryCleanFuBen()
    self:DelTimeCb("TryCleanFuBen")
    self:AddTimeCb("TryCleanFuBen",1200*1000,function ()
        self:TryCleanFuBen()
    end)
    self:CleanFuBen()
end

function CHuodong:CleanFuBen()
    for iFloor,idlist in pairs(self.m_EmptyList) do
        local iLen = #idlist
        local iClean = 0
        if iLen > CACHE_THRESHOLD then
            iClean = iLen - CACHE_THRESHOLD
        elseif iLen  > MIN_CACHE then
            iClean = iLen - MIN_CACHE
        end
        if iClean ~=0 then
            for i = 1,iClean do
                local gid = self:PushEmptyFuBen(iFloor)
                local oGame = self:GetFuBenGame(gid)
                if oGame then
                    self.m_FubenList[gid] = nil
                    baseobj_safe_release(oGame)
                end
            end
        end
    end
end

function CHuodong:OnLogin(oPlayer,reenter)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local gid = oNowScene.m_EquiFuBenGame
    if gid then
        local oGame = self:GetFuBenGame(gid)
        if oGame and oGame:InGame(oPlayer:GetPid()) then
            oGame:RefreshScene()
        else
            self:GobackRealScene(oPlayer:GetPid())
        end
    end
end

function CHuodong:CreateFuBenFloor(iFB,iFloor)
    local mArg = {type = iFB,floor=iFloor,}
    local gid = self:NewGameID()
    local oFloor = NewGame(gid,mArg)
    self.m_FubenList[gid] = oFloor
    return oFloor
end


function CHuodong:NewGameID()
    self.m_GameID = self.m_GameID + 1
    return self.m_GameID
end


function CHuodong:GetCreateWarArg(mArg)
    mArg.remote_war_type = "equipfuben"
    mArg.war_type = gamedefines.WAR_TYPE.EQUIP_TYPE
    return mArg
end

function CHuodong:EnterGame(oPlayer,iFloor)
    local mFloor = self:FloorData(iFloor)
    local iFB = mFloor["type"]
    assert(iFB==iFloor//FLOOR_MARK,string.format("err floor %d %d",iFB,iFloor))
    if not self:ValidEnterGame(oPlayer,iFB,iFloor) then
        return
    end

    local gid = self:PushEmptyFuBen(iFloor)
    local oGame = self:GetFuBenGame(gid)
    if not oGame then
        oGame = self:CreateFuBenFloor(iFB,iFloor)
    end
    if not oGame then
        return
    end
    oGame:OnStartGame(oPlayer)
end

function CHuodong:GetEnergyCost(oPlayer)
    return self:GetConfigValue("tili_cost")
end

function CHuodong:PushEmptyFuBen(iFloor)
    if self.m_EmptyList[iFloor] and #self.m_EmptyList[iFloor] > 0 then
        local gid = table.remove(self.m_EmptyList[iFloor])
        local oGame = self:GetFuBenGame(gid)
        if oGame then
            oGame.m_InEmpty = nil
        end
        return gid
    end
end

function CHuodong:NewWar(mArgs)
    local oWar = super(CHuodong).NewWar(self,mArgs)
    oWar.m_NetRirectFunc={
    C2GSWarAutoFight = function (o,iPid,mData)
        interactive.Send(o.m_iRemoteAddr, "war", "Forward", {pid = iPid, war_id = o.m_iWarId, cmd = "C2GSWarAutoFight", data = mData})
        self:C2GSWarAutoFight(o,iPid,mData)
        return true
    end
    }
    return oWar
end

function CHuodong:C2GSWarAutoFight(oWar,pid,mData)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer and mData.type == 0 then
        local oGame = self:GetFuBenGameByPlayer(oPlayer)
        if oGame then
            oGame.m_Auto = 0
            oGame:RefreshScene()
        end
    end
end

function CHuodong:InsertEmptyFuBen(iFloor,oGame)
    if not self.m_EmptyList[iFloor] then
        self.m_EmptyList[iFloor] = {}
    end
    if not oGame.m_InEmpty then
        table.insert(self.m_EmptyList[iFloor],oGame.m_ID)
        oGame.m_InEmpty = iFloor
    end
end

function CHuodong:ValidEnterGame(oPlayer,iFB,iFloorID)
    local oWorldMgr = global.oWorldMgr
    local iGrade = oWorldMgr:QueryControl("equipfuben","open_grade")
    local mData = self:GetFubenData(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local iFloor = iFloorID%FLOOR_MARK
    if oPlayer:GetGrade()< iGrade then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1001))
        return false
    end
    if oWorldMgr:IsClose("equipfuben") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    if not mData and iFloor ~= 1 then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1002))
        return false
    end
    local mFloor = mData["floor"]
    if iFloor~= 1 and not mFloor[db_key(iFloorID-1)] then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1002))
        return false
    end
    if  not oPlayer:ValidEnergy(self:GetEnergyCost(oPlayer)) then
        return false
    end
    if oPlayer:GetNowWar() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1004))
        return false
    end

    if not oPlayer:IsSingle() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1005))
        return false
    end
    if self:RemainChallenge(oPlayer) <= 0 then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1008))
        return false
    end
    return true
end


function CHuodong:LeaveFuBen(oPlayer,sReason)
    local oGame =self:GetFuBenGameByPlayer(oPlayer)
    if not oGame then
        return
    end
    --cost energy
    if sReason ~= "Win" then
        local iCostEnergy = self:GetFailCost(oPlayer, oGame.m_Floor % FLOOR_MARK)
        if oPlayer:ValidEnergy(iCostEnergy, {cancel_tip = 1, short =1}) then
            oPlayer:ResumeEnergy(iCostEnergy, {}, "装备副本失败")
        else
            record.warning("equipfuben war fail, energy not enough, pid %s", oPlayer:GetPid())
        end
    end
    self:GobackRealScene(oPlayer:GetPid())
end


function CHuodong:CreateWar(pid,npcobj,iFight,mInfo)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    local oGame = self:GetFuBenGameByPlayer(oPlayer)
    if oGame  and oGame.m_Auto == 1 then
        self.m_InGameAuto = true
    end
    local oWar =super(CHuodong).CreateWar(self,pid,npcobj,iFight,mInfo)
    self.m_InGameAuto = false
    return oWar
end

function CHuodong:GetWarConfig(sKey,mData)
    local result = super(CHuodong).GetWarConfig(self,sKey,mData)
    if self.m_InGameAuto and sKey == "war_config" then
        result = 0
    end
    return result
end

function CHuodong:OnWarWin(oWar, pid, npcobj, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        local oGame = self:GetFuBenGameByPlayer(oPlayer)
        if oGame then
            oGame:OnWarWin(oPlayer,npcobj,mArgs)
        end
    end
    super(CHuodong).OnWarWin(self,oWar, pid, npcobj, mArgs)
end

function CHuodong:OnWarFail(oWar, pid, npcobj, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        local oGame = self:GetFuBenGameByPlayer(oPlayer)
        if oGame then
            oGame:OnWarFail(oPlayer,npcobj,{nodead = mArgs.m_HasDead})
        end
    end
    super(CHuodong).OnWarFail(self,oWar, pid, npcobj, mArgs)
end



function CHuodong:PackFuBenBrief(oPlayer,iFB)
    local res = require "base.res"
    local mFBData = self:FuBenData(iFB)
    local mMyFBData = self:GetFuBenByID(oPlayer,iFB)
    local mOwnerFB = self:GetFubenData(oPlayer)
    local iMaxFloor = mMyFBData.max_floor or 0
    local iBuy = (mOwnerFB["buy_times"] or {})[iFB] or 0
    local sShowKey = string.format("show_PEFB_%d",iFB)

    local mStarFloor = mOwnerFB["star_floor"] or {}
    if not oPlayer.m_oToday:Query(sShowKey) then
        oPlayer.m_oToday:Set(sShowKey,iBuy)
    end

    local iRed = 0
    for floor,iStar in pairs(mStarFloor) do
        local iCnt = floor%FLOOR_MARK
        local iF = floor//FLOOR_MARK
        if iF == iFB then
            local mFloorConfig = res["daobiao"]["huodong"][self.m_sName]["config"][iCnt]
            if iStar >= mFloorConfig["star"] then
                iRed = 1
                break
            end
        end
    end
    local mNet = {
            f_id = iFB,
            floor = iMaxFloor,
            redpoint = iRed,
            tili_cost = self:GetEnergyCost(oPlayer),
    }
    return mNet
end

function CHuodong:LookFuBen(oPlayer,npcobj)
    self:OpenMainUI(oPlayer)
end

function CHuodong:OpenMainUI(oPlayer)
    local mNet = {}
    for iFB,mData in pairs(self:FuBenList()) do
        local mNetFB = self:PackFuBenBrief(oPlayer,iFB)
        table.insert(mNet,mNetFB)
    end
    oPlayer:Send("GS2COpenEquipFubenMain",{brief=mNet, remain = self:RemainChallenge(oPlayer)})
end

function CHuodong:RemainChallenge(oPlayer)
    local iChallenge = oPlayer.m_oToday:Query("equipFB_count", 0)
    return math.max(0, self:GetConfigValue("daily_count") - iChallenge)
end


 function CHuodong:OpenFubenUI(oPlayer,iFB)
    local mFBData = self:FuBenData(iFB)
    local mData = self:GetFubenData(oPlayer)
    local mMyFBData = self:GetFuBenByID(oPlayer,iFB)
    local iMaxFloor = mMyFBData.max_floor or 0

    local mNet = {
        brief = self:PackFuBenBrief(oPlayer,iFB)
    }
    local iStartFloor = mFBData["floor"]
    local iCnt = math.min(iMaxFloor,mFBData["floor_cnt"])
    local iRun = math.min(7,iCnt)
    local mStar = mData["star_floor"] or {}
    mNet.floor = {}
    mNet.max_floor = iCnt
    mNet.remain = self:RemainChallenge(oPlayer)
    for i=1,iRun do
        local iSelectFloor = iStartFloor+i
        local iSumStar = mStar[iSelectFloor] or 0
        local mTmp = mData["floor"] or {}
        local mMyFloorInfo = mTmp[db_key(iSelectFloor)] or {}
        local iStar = mMyFloorInfo["star"] or 0
        local mNetFloor ={
            floor = iSelectFloor,
            star = iStar,
            sum_star = iSumStar,
            sweep_cost = self:GetSweepCost(oPlayer, i),
        }
        table.insert(mNet.floor,mNetFloor)
    end
    oPlayer:Send("GS2COpenEquiFuben",mNet)
 end

 function CHuodong:GetSweepCost(oPlayer, iCnt)
    local res = require "base.res"
     local mData = res["daobiao"]["huodong"][self.m_sName]["config"][iCnt]
     return mData.sweep_cost
 end

  function CHuodong:GetFailCost(oPlayer, iCnt)
    local res = require "base.res"
     local mData = res["daobiao"]["huodong"][self.m_sName]["config"][iCnt]
     return mData.fail_cost
 end

function CHuodong:RefreshScene(oPlayer)
    local oGame = self:GetFuBenGameByPlayer(oPlayer)
    if oGame then
        oGame:RefreshScene()
    end
end

function CHuodong:SetAutoFuBen(oPlayer,iAuto)
    local oGame = self:GetFuBenGameByPlayer(oPlayer)
    if oGame then
        oGame.m_Auto = iAuto
        oGame:RefreshScene()
    end
end


function CHuodong:BuyEquipPlayCnt(oPlayer,iCnt,iCostValue,iFB)
end

function CHuodong:GetVipReward(oPlayer,floor,iEquip)
    local res = require "base.res"
    local iCnt = floor%FLOOR_MARK
    local iFB = floor//FLOOR_MARK
    local mFloorConfig = res["daobiao"]["huodong"][self.m_sName]["config"][iCnt]
    if not mFloorConfig then
        return
    end

    local mFBData = self:GetFubenData(oPlayer)
    local mStarFloor = mFBData["star_floor"] or {}
    local iSumStar = mStarFloor[floor] or 0
    if iSumStar < mFloorConfig["star"] then
        return
    end
    local mFloorData = self:FloorData(floor)
    if not string.find(mFloorData["vip_reward_select"],tostring(iEquip)) then
        return
    end
    if not handleitem.ValidEquip(oPlayer,iEquip) then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(oPlayer:GetPid(),"选择装备和人物不相符")
        return
    end
    local iPid = oPlayer:GetPid()
    iSumStar = iSumStar - mFloorConfig["star"]
    mStarFloor[floor] = iSumStar
    self:SetFubenData(oPlayer,mFBData)
    oPlayer:GiveItem({{iEquip,1}},"equipfuben_vip")
    self:OpenFubenUI(oPlayer,iFB)
end

function CHuodong:ValidSweepFuBen(oPlayer, iFloor, iCount)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if not iCount or iCount == 0 then
        return false
    end
    if oPlayer:GetInfo("equipFB_lock") == 1 then
        oNotifyMgr:Notify(iPid,self:GetTextData(1011))
        return false
    end
    if self:RemainChallenge(oPlayer) < iCount then
        oNotifyMgr:Notify(iPid,self:GetTextData(1008))
        return false
    end
    local res = require "base.res"
    local iCnt = iFloor % FLOOR_MARK
    local iFB = iFloor // FLOOR_MARK
    local mFloorConfig = res["daobiao"]["huodong"][self.m_sName]["config"][iCnt]
    if not mFloorConfig then
        return false
    end
    local iSumStar = self:GetFloorSumStar(oPlayer, iFloor)
    local iNeedStar = mFloorConfig["star"] - iSumStar
    if iNeedStar <= 0 then
        oNotifyMgr:Notify(iPid, self:GetTextData(1009))
        return false
    end
    local iRealCnt = math.ceil(iNeedStar / 3)
    if iRealCnt < iCount then
        oNotifyMgr:Notify(iPid, self:GetTextData(1010))
        return false
    end
    local iCostEnergy = self:GetEnergyCost(oPlayer)
    if not oPlayer:ValidEnergy(iCostEnergy * iCount) then
        return false
    end
    local iItemAmount = oPlayer:GetItemAmount(SWEEP_ITEM)
    local iCostCount = self:GetSweepCost(oPlayer, iCnt)
    if iCount * iCostCount > iItemAmount then
        local oItem = loaditem.GetItem(SWEEP_ITEM)
        local iNeedGold = (iCount * iCostCount - iItemAmount) * oItem:BuyPrice()
        if not oPlayer:ValidGoldCoin(iNeedGold) then
            return false
        end
    end
    return true
end

function CHuodong:SweepFuBen(oPlayer, iFloor, iCount)
    if not self:ValidSweepFuBen(oPlayer, iFloor, iCount) then
        return
    end
    local sReason = "装备副本扫荡"
    local iPid = oPlayer:GetPid()

    oPlayer:SetInfo("equipFB_sweep", 1)
    local iCostEnergy = self:GetEnergyCost(oPlayer)
    oPlayer:ResumeEnergy(iCount * iCostEnergy, sReason)

    if oPlayer:IsZskVip() then
        self:SweepFuBenSuccess(oPlayer, iFloor, iCount)
    else
        self:SweepFuBenByItem(oPlayer, iFloor, iCount)
    end
end

function CHuodong:SweepFuBenByItem(oPlayer, iFloor, iCount)
    local sReason = "装备副本扫荡"
    local oItem = loaditem.GetItem(SWEEP_ITEM)
    local iItemAmount = oPlayer:GetItemAmount(SWEEP_ITEM)
    local iNeedGold = math.max(0, (iCount * 2- iItemAmount) * oItem:BuyPrice())
    local mFrozon
    if iNeedGold > 0 then
        local sSession = oPlayer:FrozenMoney("goldcoin", iNeedGold, sReason)
        mFrozon = {sSession, iNeedGold}
    end
    local iCostItem = math.min(iItemAmount, iCount * 2)
    if iCostItem > 0 then
        local iPid = oPlayer:GetPid()
        local fCallback = function(mRecord, mData)
            local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
            self:SweepFuBenByItem2(oPlayer, iFloor, iCount, mFrozon, mData)
        end
        oPlayer:RemoveItemAmount(SWEEP_ITEM, iCostItem,sReason,{}, fCallback)
    else
        self:SweepFuBenSuccess(oPlayer, iFloor, iCount, mFrozon)
    end
end

function CHuodong:SweepFuBenByItem2(oPlayer, iFloor, iCount, mFrozon, mArgs)
    if mArgs.success then
        self:SweepFuBenSuccess(oPlayer, iFloor, iCount, mFrozon)
    else
        self:SweepFuBenFail(oPlayer, iFloor, iCount, mFrozon)
    end
end

function CHuodong:SweepFuBenFail(oPlayer, iFloor, iCount, mFrozon, mArgs)
    if mFrozon then
        local iSession, iVal = table.unpack(mFrozon)
        local oProfile = oPlayer:GetProfile()
        oProfile:UnFrozenMoney(iSession)
    end
    oPlayer:SetInfo("equipFB_sweep", 0)
    --pid|玩家ID,type|副本类型,floor|层数,count|扫荡次数
    record.user("equipfuben","sweep_fail", {
        pid = oPlayer:GetPid(),
        type = iFloor // FLOOR_MARK,
        floor = iFloor,
        count = iCount,
        })
end

function CHuodong:SweepFuBenSuccess(oPlayer, iFloor, iCount, mFrozon)
    local sReason = "装备副本扫荡"
    if mFrozon then
        local oProfile = oPlayer:GetProfile()
        local iSession, iVal = table.unpack(mFrozon)
        oProfile:UnFrozenMoney(iSession)
        oPlayer:ResumeGoldCoin(iVal, sReason, {})
    end
    local res = require "base.res"
    local iCnt = iFloor % FLOOR_MARK
    local iFB = iFloor // FLOOR_MARK
    local mFloorConfig = res["daobiao"]["huodong"][self.m_sName]["config"][iCnt]
    local iSumStar = self:GetFloorSumStar(oPlayer, iFloor) + iCount * 3
    iSumStar = math.min(iSumStar, mFloorConfig["star"])
    self:SetFloorSumStar(oPlayer,iFloor,iSumStar)
    self:OpenFubenUI(oPlayer, iFB)
    self:SweepFuBenReward(oPlayer, iFloor, iCount)
end

function CHuodong:SweepFuBenReward(oPlayer, iFloor, iCount)
    local iPid = oPlayer:GetPid()
    local mFloorData =self:FloorData(iFloor)
    local mNet = {}
    mNet.sweep = {}
    local lIdx = {mFloorData["base_reward"]}
    list_combine(lIdx, mFloorData["star_3_reward"])
    for i=1, iCount do
        local mContent = {}
        for _, iReward in ipairs(lIdx) do
            local mRewardContent = self:Reward(iPid,iReward, {cancel_tip = 1,cancel_channel = 1})
            if mRewardContent then
                local lItemObj = mRewardContent.briefitem
                if lItemObj then
                    for _, mItem in ipairs(lItemObj) do
                        local mData = {sid = mItem["sid"],amount=mItem["amount"],virtual=mItem["virtual"]}
                        table.insert(mContent,mData)
                    end
                end
            end
        end
        table.insert(mNet.sweep, {idx = i, item = mContent})
    end
    local mSweepItem = table_deep_copy(mNet.sweep)
    oPlayer.m_oToday:Add("equipFB_count", iCount)
    oPlayer:SetInfo("equipFB_sweep", 0)
    oPlayer:Send("GS2CSweepEquipFBResult", mNet)
    for i=1,iCount do
        oPlayer:AddSchedule("equipfuben")
    end
    self:PushAchieve(oPlayer, iCount, iFloor)

    --pid|玩家ID,type|副本类型,floor|层数,count|扫荡次数,item|奖励道具
    record.user("equipfuben","sweep_success", {
        pid = oPlayer:GetPid(),
        type = iFloor // FLOOR_MARK,
        floor = iFloor,
        count = iCount,
        remain = self:RemainChallenge(oPlayer),
        item = ConvertTblToStr(mSweepItem),
        })
end

function CHuodong:PushAchieve(oPlayer, iVal, iFloor)
    local iFB = iFloor // FLOOR_MARK
    local iCnt = iFloor % FLOOR_MARK
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"通关埋骨之地次数",{value=iVal})
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),string.format("通关埋骨之地%d层",iCnt),{value=iVal})
    local sAchieve = string.format("通关埋骨之地－%s",self.m_FBName[iFB])
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),sAchieve,{value=iVal})
end

function CHuodong:TestOP(oPlayer,iFlag,...)
    local args = {...}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    if iFlag == 100 then
        oChatMgr:HandleMsgChat(oPlayer,"101-设置通关X副本的N层")
        oChatMgr:HandleMsgChat(oPlayer,"102-设置N层的总星数X(不会超过最大值)")
    elseif iFlag == 101 then
        local res = require "base.res"
        local iFB = tonumber(args[1])
        local iCnt = tonumber(args[2])
        local mFuBenData = self:FuBenData(iFB)
        local mFBData = self:GetFubenData(oPlayer)
        local mData = mFBData[db_key(iFB)] or {}
        mFBData[db_key(iFB)] = mData
        mFBData["star"] = mFBData["star"] or {}
        mFBData["floor"] = mFBData["floor"] or {}
        local mFloorInfo = mFBData["floor"]
        local mFloorData = res["daobiao"]["huodong"][self.m_sName]["floor"]
        for i=1,iCnt do
            local floor = mFuBenData["floor"] + i
            if not mFloorData[floor] then
                return
            end
            mData.max_floor = i
            mFBData["star"][i] = mFBData["star"][i] or 0
            mFloorInfo[db_key(floor)] = mFloorInfo[db_key(floor)] or {}
            local mMyFloorInfo = mFloorInfo[db_key(floor)]
            mMyFloorInfo["star"] = mMyFloorInfo["star"] or 3
            self:SetFubenData(oPlayer,mFBData)
        end
        oNotifyMgr:Notify(oPlayer:GetPid(),string.format("已设置通关层数 %d %d",iFB,iCnt))
    elseif iFlag == 102 then
        local res = require "base.res"
        local floor = tonumber(args[1])
        local iSum = tonumber(args[2])
        local iCnt = tonumber(args[3])
        local mFBData = self:GetFubenData(oPlayer)
        mFBData["star_floor"] = mFBData["star_floor"] or {}
        local mFloorConfig = res["daobiao"]["huodong"][self.m_sName]["config"][iCnt]
        if not mFloorConfig then
            oNotifyMgr:Notify(oPlayer:GetPid(),"找不到该层配置")
            return
        end

        iSum = math.min(iSum,mFloorConfig["star"])
        mFBData["star_floor"][floor] = iSum
        self:SetFubenData(oPlayer,mFBData)
        oNotifyMgr:Notify(oPlayer:GetPid(),string.format(" 设置了星数%d %d",iCnt,iSum))
    elseif iFlag == 106 then
        self:EnterGame(oPlayer,1001)
    elseif iFlag == 107 then
        self:GetVipReward(oPlayer,1001,3102200)
    elseif iFlag == 999 then
        self:CleanFuBen()
    end
end

-- 只有玩家离场才清理资源
function OnLeaveScene(oScene,oPlayer)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    local gid = oScene.m_EquiFuBenGame
    local oGame = oHuodong:GetFuBenGame(gid)
    if oGame then
        oGame:ClearResource()
        oPlayer:Send("GS2CEndFBScene",{})
    end
end

function NewGame(gid,mArg)
    return CGame:New(gid,mArg)
end
CGame = {}
CGame.__index = CGame
inherit(CGame, datactrl.CDataCtrl)

function CGame:New(gid,mArg)
    local o = super(CGame).New(self)
    o.m_ID = gid
    o.m_Init = false
    o:Init(mArg)
    return o
end

function CGame:Init(mArg)
    self.m_Type = mArg.type
    self.m_Floor = mArg.floor -- 层数
    self.m_SceneID = 0
    self.m_NPCList= {}
    self.m_PlayID= 0
    self.m_mData = {}
    self.m_Progress = 0
    self.m_Auto = 0
    self.m_First = 1
end

function CGame:ClearResource()
    local oHuodong = self:Huodong()
    self.m_PlayID = 0
    self.m_Progress = 0
    for _,nid in ipairs(self.m_NPCList) do
        local npcobj = oHuodong:GetNpcObj(nid)
        if npcobj then
            oHuodong:RemoveTempNpc(npcobj)
        end
    end
    self.m_NPCList = {}
    self.m_mData = {}
    self.m_EndFlag = nil
    self.m_Auto = 0
    self.m_Progress = 0
    self.m_First = 1
    oHuodong:InsertEmptyFuBen(self.m_Floor,self)
end

function CGame:Release()
    self:ClearResource()
    local oHuodong = self:Huodong()
    oHuodong:RemoveSceneById(self.m_SceneID)
    self.m_SceneID = 0
    self.m_Progress = 0
    super(CGame).Release(self)
end

function CGame:Build()
    assert(not self.m_Init,"err equipfuben build")
    local oHuodong = self:Huodong()
    local mData = oHuodong:FloorData(self.m_Floor)
    local iScene = mData["scene"]
    self.m_SceneID = self:CreateHDScene(iScene)
    self.m_Init = true
end

function CGame:SceneObject()
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(self.m_SceneID)
    return oScene
end

function CGame:Huodong()
    local oHuodongMgr = global.oHuodongMgr
    return oHuodongMgr:GetHuodong("equipfuben")
end

function CGame:IsEmpty()
    return self.m_PlayID == 0
end

function CGame:InGame(pid)
    return self.m_PlayID == pid
end

function CGame:CreateGame(mData)
    if not self.m_Init then
        self:Build()
    end
    local oHuodong = self:Huodong()
    local mData = oHuodong:FloorData(self.m_Floor)
    local mNpcConfig = mData["npcconfig"]
    local oScene = self:SceneObject()
    local iNeed = 1
    local iCnt = 0
    for _,iNpc in ipairs(mNpcConfig) do
        if iCnt >= iNeed then
            break
        end
        iCnt = iCnt + 1
        local npcobj = self:CreateNpc(iNpc,oScene)
        npcobj.m_DescType = "monster"
    end
end

function CGame:CreateHDScene(iSc)
    local oHuodong = self:Huodong()
    local oScene = oHuodong:CreateVirtualScene(iSc)
    oScene.m_EquiFuBenGame = self.m_ID
    oScene.m_OnLeave = OnLeaveScene
    oScene.m_NoTransfer = 1
    oScene:SetLimitRule("team",1)
    oScene:SetLimitRule("transfer",1)
    return oScene:GetSceneId()
end

function CGame:CreateNpc(nid,oScene)
    local oHuodong = self:Huodong()
    local oSceneMgr = global.oSceneMgr
    local npcobj = oHuodong:CreateTempNpc(nid)
    npcobj.m_NPCType = nid
    npcobj.m_GameID = self.m_ID
    npcobj.m_ShowMode = 1

    self.m_First = self.m_First + 1

    table.insert(self.m_NPCList,npcobj.m_ID)
    local mPosInfo = npcobj:PosInfo()
    oHuodong:Npc_Enter_Scene(npcobj,oScene:GetSceneId(),mPosInfo)
    return npcobj
end


function CGame:OnWarWin(oPlayer,npcobj,mArg)
    local nid = npcobj.m_ID
    extend.Array.remove(self.m_NPCList,nid)
    self:RefreshFBNpcList(oPlayer)
    if mArg.m_HasDead then
        if not self:GetData("death") then
            self:SetData("death",1)
            self:RefreshScene()
        end
    end

    if self.m_Progress == 1 then
        local oHuodong = self:Huodong()
        local mData = oHuodong:FloorData(self.m_Floor)
        local mNpcConfig = mData["npcconfig"]
        local iNpc = mNpcConfig[self.m_First]
        if iNpc then
            local oScene = self:SceneObject()
            self:CreateNpc(iNpc,oScene)
            self:RefreshScene()
            return
        end
    end

    if #self.m_NPCList == 0 then
        if self.m_Progress == 1 then
            self:OnBossStart(oPlayer)
        elseif self.m_Progress == 2 then
            self:OnGameOver(oPlayer,mArg)
        end
    end
end

function CGame:OnWarFail(oPlayer,npcobj,mArgs)
    local bRefresh = false
    if not self:GetData("death") then
        self:SetData("death",1)
        bRefresh = true
    end
    if self.m_Auto then
        self.m_Auto = 0
        bRefresh = true
    end
    if bRefresh then
        self:RefreshScene()
    end
end

function CGame:OnStartGame(oPlayer)
    assert(self:IsEmpty(),"equipfuben is not emptygame")
    local oHuodong = self:Huodong()
    local oWorldMgr = global.oWorldMgr
    self.m_Progress = 1
    self.m_StartTime = get_time()
    self.m_StartDayNo = get_dayno()
    self.m_PlayID = oPlayer:GetPid()
    self:CreateGame()
    local mFloorData = oHuodong:FloorData(self.m_Floor)
    local mPos = mFloorData["initpos"]
    oHuodong:TransferPlayerBySceneID(oPlayer:GetPid(),self.m_SceneID
        ,mPos["x"],mPos["y"])
    self:RefreshScene()
end


function CGame:RefreshScene()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_PlayID)
    if not oPlayer then
        return
    end
    local oHuodong = self:Huodong()
    local mFloor = oHuodong:FloorData(self.m_Floor)
    local iCode,iStar  = self:CallGradeStar()
    local npclist = {}

    for _,nid in ipairs(self.m_NPCList) do
        local npcobj = oHuodong:GetNpcObj(nid)
        if npcobj then
            local mPos = npcobj:PosInfo()
            table.insert(npclist,{nid = nid,x=mPos["x"],y=mPos["y"],nno=npcobj.m_NPCType})
        end
    end
    local mNet = {
    floor = self.m_Floor,
    time = get_time()-self.m_StartTime,
    auto = self.m_Auto,
    scene_id = self.m_SceneID,
    estimate = iCode,
    nid_list = npclist,
    count = self.m_First -1 ,
    }
    oPlayer:Send("GS2CRefreshEquipFBScene",net.Mask("GS2CRefreshEquipFBScene", mNet))
end

function CGame:RefreshFBNpcList(oPlayer)
    local oHuodong = self:Huodong()
    local npclist = {}
    for _,nid in ipairs(self.m_NPCList) do
        local npcobj = oHuodong:GetNpcObj(nid)
        if npcobj then

            local mPos = npcobj:PosInfo()
            table.insert(npclist,{nid = nid,x=mPos["x"],y=mPos["y"],nno=npcobj.m_NPCType})
        end
    end
    local mNet = {
    count = self.m_First -1,
    nid_list = npclist,
    }
    oPlayer:Send("GS2CRefreshEquipFBScene",net.Mask("GS2CRefreshEquipFBScene", mNet))
end

function CGame:LeftTime()
    local oHuodong = self:Huodong()
    local mFloor = oHuodong:FloorData(self.m_Floor)
    local iLeft = math.max(mFloor["time"]*60+self.m_StartTime - get_time(),0)
    return iLeft
end

function CGame:OnBossStart(oPlayer)
    local oHuodong = self:Huodong()
    self.m_Progress = 2
    local mData = oHuodong:FloorData(self.m_Floor)
    local mNpcConfig = mData["bossconfig"]
    local oScene = self:SceneObject()
    local iNum = mNpcConfig["num"]
    local iNpc = mNpcConfig["npc"]
    for _,iNpc in pairs(mNpcConfig) do
        local npcobj = self:CreateNpc(iNpc,oScene)
        npcobj.m_DescType = "boss"
    end
    self:RefreshFBNpcList(oPlayer)
end


function CGame:OnGameOver(oPlayer,mArg)
    local res = require "base.res"
    self.m_Progress = 3
    local oWorldMgr = global.oWorldMgr
    local oHuodong = self:Huodong()
    local iCode,iStar = self:CallGradeStar()
    local iFB = self.m_Type
    local floor = self.m_Floor
    local mFBData = oHuodong:GetFubenData(oPlayer)
    local mData = mFBData[db_key(iFB)] or {}
    local iMax = mData.max_floor or 0
    local iCnt = floor%FLOOR_MARK
    local mFloorConfig = res["daobiao"]["huodong"][oHuodong.m_sName]["config"][iCnt]
    local bVipReward = false
    local bFirst = false
    if iMax < iCnt then
        iMax = iCnt
    end
    mData.max_floor = iMax
    mFBData[db_key(iFB)] = mData
    local iCostEnergy = oHuodong:GetEnergyCost(oPlayer)
    if  oPlayer:ValidEnergy(iCostEnergy) then
        oPlayer:ResumeEnergy(iCostEnergy,"装备副本")
    else
        local mNet = {
            star = iStar,
            estimate = iCode,
            sum_star = 0,
            item = {},
            use_time = get_time()-self.m_StartTime,
            floor = self.m_Floor
            }
            oPlayer:Send("GS2CEquipFBWarResult",mNet)
            record.error(string.format("equipufben cost energy err %s %d %d",oPlayer:GetPid(),iCostEnergy,oPlayer:GetEnergy()))
            oHuodong:LeaveFuBen(oPlayer,"Win")
        return
    end

    oPlayer:AddSchedule("equipfuben")
    oHuodong:PushAchieve(oPlayer, 1, floor)

    local mStarFloor = mFBData["star_floor"] or {}
    local iSumStar = mStarFloor[floor] or 0
    local iLogSumStart = iSumStar
    iSumStar = math.min(iSumStar + iStar,mFloorConfig["star"])
    mStarFloor[floor] = iSumStar
    mFBData["star_floor"]= mStarFloor

    if not mFBData["floor"] then
        mFBData["floor"] = {}
    end
    local mFloorInfo = mFBData["floor"]
    if not mFloorInfo[db_key(floor)] then
        bFirst = true
        mFloorInfo[db_key(floor)] = {}
    end
    local mMyFloorInfo = mFloorInfo[db_key(floor)]
    mMyFloorInfo["star"] = math.max(iStar,(mMyFloorInfo.star or 0))

    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30028,1)
    oPlayer.m_oToday:Add("equipFB_count", 1)
    local mLog = {
        pid = oPlayer:GetPid(),
        type = iFB,
        use = oPlayer.m_oToday:Query(string.format("Cnt_fb_%d",iFB),0),
        star = iStar,
        timeout =iCode>>2&1~=0 and 0 or 1,
        dead = iCode>>1&1~=0 and 0 or 1,
        befor_star = iLogSumStart,
        after_Star = iSumStar,
        floor = iCnt,
        first = bFirst and  1  or 0,
        remain = oHuodong:RemainChallenge(oPlayer),
    }
    record.user("equipfuben","join",mLog)


    oHuodong:SetFubenData(oPlayer,mFBData)


    local mItem = self:GameReward(oPlayer,bVipReward,iStar,bFirst,mArg)
    local mNet = {
    star = iStar,
    estimate = iCode,
    sum_star = iSumStar,
    item = mItem,
    use_time = get_time()-self.m_StartTime,
    floor = self.m_Floor
    }
    oPlayer:Send("GS2CEquipFBWarResult",mNet)

    if oPlayer.m_oActiveCtrl:SetGuideFlag(oPlayer,7000061) then
        oPlayer.m_oActiveCtrl:GS2CGuidanceInfo()
    end
    if bFirst then
        local mData = oHuodong:FloorData(self.m_Floor)
        local mFirstList = mData["first_reward"]
        local iPid = oPlayer:GetPid()
        for _,idx in ipairs(mFirstList) do
            oHuodong:Reward(iPid,idx,mArg)
        end
        global.oUIMgr:ShowKeepItem(iPid)
    end



    oHuodong:LeaveFuBen(oPlayer,"Win")
    self.m_PlayID = 0
    local mItem2 = {}
    for _,info in pairs(mItem) do
        mItem2[info.sid] = info.amount
    end
    oPlayer:LogAnalyGame({},"equipfuben",mItem2)
end

function CGame:GameReward(oPlayer,bVip,iStar,bFirst,mArg)
    local oHuodong = self:Huodong()
    local iPid = oPlayer:GetPid()
    local mData = oHuodong:FloorData(self.m_Floor)
    local mRewardList = {}
    table.insert(mRewardList,mData["base_reward"])
    local mExtrList = {}
    if iStar == 1 then
        mExtrList = mData["star_1_reward"]
    elseif iStar == 2 then
        mExtrList = mData["star_2_reward"]
    elseif iStar == 3 then
        mExtrList = mData["star_3_reward"]
    end
    mRewardList = extend.Array.append(mRewardList,mExtrList)
    local mContent = {}
    for _,idx in ipairs(mRewardList) do
        local mRewardContent = oHuodong:Reward(iPid,idx,mArg)
        if mRewardContent then
            local lItemObj = mRewardContent.briefitem
            if lItemObj then
                for _, mItem in ipairs(lItemObj) do
                    local mData = {sid = mItem["sid"],amount=mItem["amount"],virtual=mItem["virtual"]}
                    table.insert(mContent,mData)
                end
            end
        end
    end
    return mContent
end

function CGame:CallGradeStar()
    local iNoTimeOut = 0
    local iNoDeath = 0
    local iPass = 0
    if self:LeftTime()>0 then
        iNoTimeOut = 1
    end
    if not self:GetData("death") then
        iNoDeath = 1
    end
    if self.m_Progress == 3 then
        iPass= 1
    end
    return iPass|iNoDeath<<1|iNoTimeOut<<2,iNoTimeOut+iNoDeath+iPass
end






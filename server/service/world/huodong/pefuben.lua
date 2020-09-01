--import module
local skynet = require "skynet"
local global  = require "global"
local extend = require "base.extend"
local net = require "base.net"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item.loaditem"))

local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "异空流放"
inherit(CHuodong, huodongbase.CHuodong)

FLOOR_MARK = 1000
SWEEP_ITEM = 10030
MAX_STAR = 3 --最大星级

function CHuodong:Init()
    self:TryStartRewardMonitor()
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
    end
end


function CHuodong:GetFubenData(oPlayer)
    return oPlayer.m_oHuodongCtrl:GetData("PEFuBen",{})
end

function CHuodong:SetFubenData(oPlayer,mData)
    oPlayer.m_oHuodongCtrl:SetData("PEFuBen",mData)
end

function CHuodong:GetFubenFloorData(oPlayer, iFloor)
    local mMyData =self:GetFubenData(oPlayer)
    local mMyFloor = mMyData.floor or {}
    return mMyFloor[iFloor] or {}
end

function CHuodong:SetFubenFloorData(oPlayer, iFloor, mMyFloor)
    local mMyData =self:GetFubenData(oPlayer)
    local mFloor = mMyData.floor or {}
    mFloor[iFloor] = mMyFloor
    mMyData.floor = mFloor
    self:SetFubenData(oPlayer, mMyData)
end

function CHuodong:FloorData(iFloor)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["floor"][iFloor]
    assert(mData,string.format("err floordata %d",iFloor))
    return mData
end

function CHuodong:FuBenDaobiaoData(iFB)
    local mData = self:FuBenList()[iFB]
    assert(mData,string.format("err fubendata %d",iFB))
    return mData
end

function CHuodong:FuBenList()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["fuben"]
    return mData
end

 function CHuodong:GetSweepCost(oPlayer, iCnt)
    local res = require "base.res"
     local mData = res["daobiao"]["huodong"][self.m_sName]["floor_config"][iCnt]
     return mData.sweep_cost
 end

 function CHuodong:GetFailCost(oPlayer, iCnt)
    local res = require "base.res"
     local mData = res["daobiao"]["huodong"][self.m_sName]["floor_config"][iCnt]
     return mData.fail_cost
 end

  function CHuodong:StarMaxBout(oPlayer, iCnt)
    local res = require "base.res"
     local mData = res["daobiao"]["huodong"][self.m_sName]["floor_config"][iCnt]
     return mData.turn_limit
 end

function CHuodong:IsOpenFuBen(iFB)
    local iWeek = get_weekday()
    local mData = self:FuBenDaobiaoData(iFB)
    local open_list = mData["open_date"]
    return extend.Array.member(open_list,iWeek)
end

function CHuodong:IsTodayOpen(oPlayer,iFB)
    if self:IsOpenFuBen(iFB) then
        return true
    end
    if table_in_list(oPlayer.m_oToday:Query("pay_PEFB",{}),iFB) then
        return true
    end
    return false
end

function CHuodong:TodayOpen()
    local mFBList = {}
    for iFB,mData in pairs(self:FuBenList()) do
        if self:IsOpenFuBen(iFB) then
            table.insert(mFBList,iFB)
        end
    end
    return extend.Random.random_choice(mFBList)
end


function CHuodong:EnterWar(oPlayer,floor)

    if not self:ValidEnterWar(oPlayer,floor) then
        return
    end
    local iFB = floor//FLOOR_MARK
    local mFloorData = self:FloorData(floor)
    local iFight = mFloorData["fight"]
    local mData = oPlayer.m_oToday:Query(string.format("peFBTurn_%d",iFB))
    local oWar = self:CreateWar(oPlayer:GetPid(),nil,iFight)
    if oWar then
        oWar.m_FloorData = {
        floor = floor,
        day = get_dayno(),
        turn = table_copy(mData),
        start_time = get_time(),
        }
    end
end

function CHuodong:ValidEnterGame(oPlayer,iFB,iCheckTili)
    local oWorldMgr = global.oWorldMgr
    local iGrade = oWorldMgr:QueryControl("pefuben","open_grade")
    local oNotifyMgr = global.oNotifyMgr
    if oWorldMgr:IsClose("pefuben") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    if oPlayer:GetGrade()< iGrade then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1001))
        return false
    end
    if not self:IsTodayOpen(oPlayer,iFB) then
        oNotifyMgr:Notify(oPlayer:GetPid(),"副本还未准备好")
        return false
    end
    if not oPlayer:ValidEnergy(self:GetTiLiCost(oPlayer)) then
        return  false
    end
    if oPlayer:GetNowWar() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1004))
        return false
    elseif not oPlayer:IsSingle() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1005))
        return false
    end
    if self:RemainChallenge(oPlayer) <= 0 then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1008))
        return false
    end
    return true
end

function CHuodong:ValidEnterWar(oPlayer,iFloorID)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iFB = iFloorID//FLOOR_MARK
    local iFloor = iFloorID%FLOOR_MARK
    local mData = self:GetFubenData(oPlayer)
    local mFBData = self:FuBenDaobiaoData(iFB)

    if not self:ValidEnterGame(oPlayer,iFB) then
        return false
    end

    -- if iFloor > mFBData["floor_cnt"] then
    --     oNotifyMgr:Notify(oPlayer:GetPid(),"你还未通关")
    --     return false
    -- end
    if (not mData or table_count(mData) <= 0 )and iFloor ~= 1 then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1002))
        return false
    end
    local iMax = mData["max_floor"] or 1
    if iFloor~= 1 and  iFloor > iMax+1 then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1002))
        return false
    end
    if not oPlayer.m_oToday:Query(string.format("peFBTurn_%d",iFB)) then
        oNotifyMgr:Notify(oPlayer:GetPid(),"尚未抽取符文")
        return false
    end
    return true
end

function CHuodong:GetCreateWarArg(mArg)
    mArg.war_type = gamedefines.WAR_TYPE.PE_FUBEN
    mArg.remote_war_type = "pefuben"
    return mArg
end

function CHuodong:OnWarWin(oWar, pid, npcobj, mArgs)
    super(CHuodong).OnWarWin(self,oWar, pid, npcobj, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    local mWarFloor = oWar.m_FloorData
    local iFloor = mWarFloor.floor
    local iFB = iFloor//FLOOR_MARK
    local iCnt = iFloor%FLOOR_MARK
    local mMyData = self:GetFubenData(oPlayer)
    local iNowDay = get_dayno()

    local mData = mMyData[db_key(iFB)] or {}

    local iMax = mMyData.max_floor or 0
    if iMax < iCnt then
        iMax = iCnt
    end
    mMyData.max_floor = iMax
    mMyData[db_key(iFB)] = mData
    local mMyFloor = self:GetFubenFloorData(oPlayer, iCnt)
    local iStar = mMyFloor.star or 1
    local iWinStar = self:WarWinStar(oPlayer, mArgs)
    iStar = math.max(iStar, iWinStar)
    mMyFloor.star = iStar
    self:SetFubenFloorData(oPlayer, iCnt, mMyFloor)
    -- mMyData.floor = mMyData.floor
    -- mMyData.floor[iCnt] = mMyFloor

    oPlayer:AddSchedule("pefuben")
    oPlayer:ResumeEnergy(self:GetTiLiCost(oPlayer),"符文副本")
    local mTurn = mWarFloor.turn
    local iPart = mTurn["part"]
    local iEquip = mTurn["equip"]
    local mLog = {
        pid = oPlayer:GetPid(),
        type = iFB,
        part = iPart,
        equip = iEquip,
        use = oPlayer.m_oToday:Query("Cnt_pefb",0),
        start = mWarFloor.start_time,
        }
    self:SetFubenData(oPlayer,mMyData)

    oPlayer.m_oToday:Delete(string.format("peFBTurn_%d",iFB))
    oPlayer.m_oToday:Add("peFBcount", 1)
    self:DoAchieve(oPlayer, iFloor)
    local r1,mReward = safe_call(self.PassReward,self,oPlayer,iFB,iFloor,mTurn,mArgs)
    if not r1 then
        mReward = {}
    end

    mLog.reward_item = extend.Table.serialize(mReward)
    record.user("pefuben","join",mLog)
    oPlayer:LogAnalyGame({},"pefuben",mReward)
end

function CHuodong:OnWarFail(oWar, pid, nociob, mArgs)
    super(CHuodong).OnWarWin(self,oWar, pid, npcobj, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    local mWarFloor = oWar.m_FloorData
    local iFloor = mWarFloor.floor
    local iCnt = iFloor%FLOOR_MARK
    local iCostEnergy = self:GetFailCost(oPlayer, iCnt)
    if oPlayer:ValidEnergy(iCostEnergy, {cancel_tip=1, short = 1}) then
        oPlayer:ResumeEnergy(iCostEnergy,"符文副本失败")
    else
        record.warning("pefuben war fail, energy not enough, pid:%s", pid)
    end
end

function  CHuodong:PassReward(oPlayer,iFB,iFloor,mTurn,mArgs)
    local mRewardItem = {}

    local mFloorData = self:FloorData(iFloor)
    local mRewardList = mFloorData["reward_list"]
    self.m_TmpRewardArg = {
    pos = mTurn["part"],
    type = mTurn["equip"],
    fb = iFB,
    floor = iFloor,
    }
    for _,iReward in ipairs(mRewardList) do
        local mRewardContent = self:Reward(oPlayer:GetPid(),iReward,mArgs)
        if mRewardContent and mRewardContent.briefitem then
            for _,mItemData in ipairs(mRewardContent.briefitem) do
                local sid = mItemData["sid"]
                local amount = mItemData["amount"]
                mRewardItem[sid]  = (mRewardItem[sid] or 0) + amount
            end
        end
    end
    self.m_TmpRewardArg = nil
    return mRewardItem
end

function CHuodong:WarWinStar(oPlayer, mArgs)
    local iMaxBout = self:StarMaxBout(oPlayer, mArgs.pefuben_cnt or 1)
    local iWinStar = 3
    mArgs = mArgs or {}
    local iDeath = mArgs.m_HasDead or 0
    if iDeath > 1 then
        iWinStar =1
    elseif iDeath > 0 then
        iWinStar = 2
    end
    if mArgs.bout > iMaxBout and iWinStar == 3 then
        iWinStar = 2
    end
    return iWinStar
end

function CHuodong:GetWarWinRewardUIData(oPlayer, mArgs)
    local mData = super(CHuodong).GetWarWinRewardUIData(self,oPlayer, mArgs)
    if mArgs.win_side == 1 then
        local apply = {}
        table.insert(apply, {key = "star", value = self:WarWinStar(oPlayer, mArgs)})
        table.insert(apply, {key = "bout", value = self:StarMaxBout(oPlayer, mArgs.pefuben_cnt or 1)})
        mData.apply = apply
    end
    return mData
end

function CHuodong:TransItemShape(oPlayer,iItemIdx,sShape,mArgs)
    local sid,sArg = string.match(sShape,"(%d+)(.+)")

    if sid == "1028" and sArg ~= "" and self.m_TmpRewardArg then
        local mFBArg = self.m_TmpRewardArg
        local sResult = ""
        local bTran = false
        local mEvn = {}
        local mFBData = self:FuBenDaobiaoData(mFBArg.fb)
        for k,v in string.gmatch(sArg,"(%w+)=(%w+)") do
            mEvn[k] = v
        end
        local iLen = table_count(mEvn)
        local i = 0

        for k,v in pairs(mEvn) do
            i = i + 1
            local val = v
            if not tonumber(v) then
                if v == "UD" then
                    if k == "type" then
                        val = mFBArg["type"]
                    elseif k == "pos" then
                        val = mFBArg["pos"]
                    end
                elseif v == "RAN" then
                    if k == "type" then
                        val = table_choose_key(mFBData["reward_equip_ratio"])
                    elseif k == "pos" then
                        val = table_choose_key(mFBData["reward_part_ratio"])
                    end
                end
            end
            if i == iLen then
                sResult= sResult..string.format("%s=%s",k,val)
            else
                sResult= sResult..string.format("%s=%s,",k,val)
            end
        end

        if sResult ~= "" then
            sArg = sResult
        end
        sShape = string.format("%s(%s)",sid,sArg)
    end
    return sShape
end

function CHuodong:RemainChallenge(oPlayer)
    local iChallenge = oPlayer.m_oToday:Query("peFBcount", 0)
    return math.max(0, self:GetConfigValue("daily_count") - iChallenge)
end

function CHuodong:OpenMainUI(oPlayer,iFB)
    for fb,m in pairs(self:FuBenList()) do
        if oPlayer.m_oToday:Query(string.format("peFBTurn_%d",fb)) then
            iFB = fb
            break
        end
    end
    if not iFB or iFB==0 or not self:IsTodayOpen(oPlayer,iFB) then
        if oPlayer.m_oToday:Query("select_pefuben") then
            iFB = oPlayer.m_oToday:Query("select_pefuben")
        end
        if not iFB or iFB==0 or not self:IsTodayOpen(oPlayer,iFB) then
            iFB = self:TodayOpen()
        end
    end
    oPlayer.m_oToday:Set("select_pefuben",iFB)
    local viplist = oPlayer.m_oToday:Query("pay_PEFB",{})
    if not table_in_list(viplist,iFB) then
        oPlayer.m_oToday:Set("pay_PEFB",{})
    end
    local mMyData = self:GetFubenData(oPlayer)
    local mFBData = self:FuBenDaobiaoData(iFB)
    local mData = mMyData[db_key(iFB)] or {}
    local iMax = mMyData.max_floor or 0

    local mTurnData = oPlayer.m_oToday:Query(string.format("peFBTurn_%d",iFB),{})
    local mNet ={
    fb_id = iFB,
    open_floor = iMax,
    select_part = mTurnData["part"] or 0,
    select_equip = mTurnData["equip"] or 0,
    lock = mTurnData["lock"] or 0,
    reset_cost = self:GetResetCost(oPlayer),
    energy = self:GetTiLiCost(oPlayer),
    remain = self:RemainChallenge(oPlayer),
    floors = self:PackFloorList(oPlayer),
    }
    oPlayer:Send("GS2CMainPEFuben",mNet)
end

function CHuodong:PackFloorList(oPlayer)
    local mMyData = self:GetFubenData(oPlayer)
    local iMax =mMyData.max_floor or 0
    local lNet = {}
    for iCnt = 1, iMax do
        local m = self:GetFubenFloorData(oPlayer, iCnt)
        table.insert(lNet, {floor = iCnt, star = m.star or 1, sweep_cost = self:GetSweepCost(oPlayer, iCnt)})
    end
    return lNet
end

function CHuodong:GetTodayShowBuy(oPlayer)
    local mMyData = self:GetFubenData(oPlayer)
    if not oPlayer.m_oToday:Query("show_PEFB") then
        oPlayer.m_oToday:Set("show_PEFB",mMyData["buy_times"] or 0)
    end
    return oPlayer.m_oToday:Query("show_PEFB",0)
end

function CHuodong:GetResetCost(oPlayer)
    local res = require "base.res"
    local m = res["daobiao"]["huodong"][self.m_sName]["floor_config"]
    local mData = self:GetFubenData(oPlayer)
    local iMax = mData["max_floor"] or 0
    local mConfig = m[iMax+1] or m[#m]
    return mConfig["reset_cost"]
end

function CHuodong:GetTiLiCost(oPlayer)
    local res = require "base.res"
    local m = res["daobiao"]["huodong"][self.m_sName]["floor_config"]
    local mData = self:GetFubenData(oPlayer)
    local iMax = mData["max_floor"] or 0
    return m[iMax+1]["tili_cost"] or m[#m]["tili_cost"]
end


function CHuodong:StartTurn(oPlayer,iFB,iEnter)
    if not self:ValidEnterGame(oPlayer,iFB,1) then
        return
    end
    local mFBData = self:FuBenDaobiaoData(iFB)
    local sKey = string.format("peFBTurn_%d",iFB)
    local mData = oPlayer.m_oToday:Query(sKey)
    local bFree = false
    if not mData then
        mData = {}
        bFree = true
    end
    local iCostVal = 0
    if not bFree then
        iCostVal = self:GetResetCost(oPlayer)
        if not oPlayer:ValidCoin(iCostVal) then
            return
        end
        oPlayer:ResumeCoin(iCostVal , "异空流放重新抽取")
    end

    local iLock = mData["lock"] or 0
    local iPart = mData["part"]
    local iEquip = mData["equip"]
    if not iPart or iLock ~= 1 then
        iPart =  table_choose_key(mFBData["part_ratio"])
        assert(iPart,"err pefuben turn part")
    end

    if not iEquip or iLock ~=2 then
        iEquip = table_choose_key(mFBData["equip_ratio"])
        assert(iEquip,"err pefuben turn equip")
    end

    local mLog = {
    pid = oPlayer:GetPid(),
    type = iFB,
    part = iPart,
    equip = iEquip,
    cost = iCostVal,
    }
    record.user("pefuben","turn",mLog)

    mData["part"] = iPart
    mData["equip"] = iEquip
    oPlayer.m_oToday:Set(sKey,mData)
    local mNet = {
    fb_id = iFB,
    select_part = iPart,
    select_equip = iEquip,
    enter = iEnter,
    }
    oPlayer:Send("GS2CPETurnResult",mNet)
end



function CHuodong:LockEquip(oPlayer,iFB,iLock)
    if not self:IsTodayOpen(oPlayer,iFB) then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local sKey = string.format("peFBTurn_%d",iFB)
    local mData = oPlayer.m_oToday:Query(sKey)
    if not mData then
        return
    end
    if iLock ~= 1 and iLock ~= 2 and iLock ~= 0 then
        return
    end

    assert(mData["part"] and mData["equip"],"err pefuben lock")
    if iLock ~= 0 then
        local iCostVal = self:GetConfigValue("lock_cost")
        if not oPlayer:ValidGoldCoin(iCostVal) then
            return
        end
        oPlayer:ResumeGoldCoin(iCostVal , "异空流放锁定")
    end

    local mLog = {
    pid = oPlayer:GetPid(),
    type = iFB,
    lock = iLock,
    }
    record.user("pefuben","lock",mLog)

    mData["lock"] = iLock
    oPlayer.m_oToday:Set(sKey,mData)
    local mNet = {
    fb_id = iFB,
    lock = iLock,
    }
    oPlayer:Send("GS2CPELockResult",mNet)
    if iLock == 0 then
    oNotifyMgr:Notify(oPlayer:GetPid(),"解锁成功")
    else
        oNotifyMgr:Notify(oPlayer:GetPid(),"锁定成功")
    end
end

function CHuodong:EnterGame(oPlayer,iFB,floor)
    if not oPlayer.m_oToday:Query(string.format("peFBTurn_%d",iFB)) then
        self:StartTurn(oPlayer,iFB,1)
        return
    end
    local iFloor = iFB*1000 + floor
    self:EnterWar(oPlayer,iFloor)
end



function CHuodong:BuyFuBenTimes(oPlayer,iCnt,iFB)
end


function CHuodong:OpenSchedule(oPlayer)
    if not oPlayer.m_oToday:Query("select_pefuben") then
        oPlayer.m_oToday:Set("select_pefuben",self:TodayOpen())
    end
    local iCur = oPlayer.m_oToday:Query("select_pefuben")

    local mFBList = {}
    for iFB,m in pairs(self:FuBenList()) do
        local iCost = 0
        if not self:IsTodayOpen(oPlayer,iFB) then
            iCost = self:VIPSelectFuBenCost(oPlayer,iFB)
        end
        table.insert(mFBList,{fb=iFB,cost=iCost})
    end
    oPlayer:Send("GS2CPEFuBenSchedule",{cur_fb=iCur,fd_list=mFBList})
end

function CHuodong:VIPSelectFuBenCost(oPlayer,iFB)
    local m = self:GetConfigValue("buy_select")
    local mData = self:GetFubenData(oPlayer)
    local iMax = mData["max_floor"] or 0
    return m[iMax+1] or m[#m]
end



function CHuodong:VIPSelectFuBen(oPlayer,iFB)
    local m = self:FuBenDaobiaoData(iFB)
    local mFBList = {}
    for iFB,m in pairs(self:FuBenList()) do
        local sKey = string.format("peFBTurn_%d",iFB)
        local mData = oPlayer.m_oToday:Query(sKey)
        if mData then
            global.oNotifyMgr:Notify(oPlayer:GetPid(),"请先通关当前副本")
            return
        end
    end
    local iCost = self:VIPSelectFuBenCost(oPlayer,iFB)
    local viplist = oPlayer.m_oToday:Query("pay_PEFB",{})
    if iCost == 0 or self:IsTodayOpen(oPlayer,iFB) then
        if not table_in_list(iFB,viplist) then
            oPlayer.m_oToday:Set("pay_PEFB",{})
        end
        self:OpenMainUI(oPlayer,iFB)
    end
    if not oPlayer:ValidGoldCoin(iCost) then
        return
    end
    local mFbList = table_key_list(self:FuBenList())
    if not table_in_list(mFbList,iFB) then
        return
    end
    if self:IsTodayOpen(oPlayer,iFB) then
        return
    end
    oPlayer:ResumeGoldCoin(iCost,"pefuebn.buy_select")
    local viplist = oPlayer.m_oToday:Query("pay_PEFB",{})
    viplist = {iFB,}
    oPlayer.m_oToday:Set("pay_PEFB",viplist)
    self:OpenMainUI(oPlayer,iFB)
end

function CHuodong:ValidSweepFuBen(oPlayer, iFloor)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if not self:ValidEnterWar(oPlayer, iFloor) then
        return false
    end
    if oPlayer:GetInfo("peFB_lock", 0) == 1 then
        oNotifyMgr:Notify(iPid,self:GetTextData(1007))
        return false
    end
    if self:RemainChallenge(oPlayer) <= 0 then
        oNotifyMgr:Notify(iPid,self:GetTextData(1008))
        return false
    end
    local iCnt = iFloor % FLOOR_MARK

    local mMyFloor = self:GetFubenFloorData(oPlayer,iCnt)
    if mMyFloor.star ~= MAX_STAR then
        oNotifyMgr:Notify(iPid,self:GetTextData(1009))
        return false
    end
    local iCnt = iFloor % FLOOR_MARK
    local iItemAmount = oPlayer:GetItemAmount(SWEEP_ITEM)
    local oItem = loaditem.GetItem(SWEEP_ITEM)
    local iCostItem = self:GetSweepCost(oPlayer, iCnt)
    if iCostItem > iItemAmount then
        local iNeedGold = (iCostItem - iItemAmount) * oItem:BuyPrice()
        if not oPlayer:ValidGoldCoin(iNeedGold) then
            return false
        end
    end
    return true
end

function CHuodong:SweepFuBen(oPlayer, iFB, iCnt)
    if not oPlayer.m_oToday:Query(string.format("peFBTurn_%d",iFB)) then
        self:StartTurn(oPlayer,iFB,2)
        return
    end
    local iFloor = iFB * FLOOR_MARK + iCnt
    if not self:ValidSweepFuBen(oPlayer, iFloor) then
        return
    end
    local sReason = "装备副本扫荡"

    oPlayer:SetInfo("peFB_sweep", 1)
    local iCount = 1
    local iCostEnergy = self:GetTiLiCost(oPlayer)
    oPlayer:ResumeEnergy(iCount * iCostEnergy, sReason)

    if oPlayer:IsZskVip() then
        self:SweepFuBenSuccess(oPlayer, iFloor)
    else
        self:SweepFuBenByItem(oPlayer, iFloor)
    end
end

function CHuodong:SweepFuBenByItem(oPlayer, iFloor)
    local sReason = "装备副本扫荡"
    local oItem = loaditem.GetItem(SWEEP_ITEM)
    local iItemAmount = oPlayer:GetItemAmount(SWEEP_ITEM)
    local iCostItem = self:GetSweepCost(oPlayer, iFloor % FLOOR_MARK)
    local mFrozon
    if iCostItem > iItemAmount then
        local iNeedGold = (iCostItem - iItemAmount) * oItem:BuyPrice()
        local sSession = oPlayer:FrozenMoney("goldcoin", iNeedGold, sReason)
        mFrozon = {sSession, iNeedGold}
    end
    if iItemAmount > 0 then
        local iPid = oPlayer:GetPid()
        local fCallback = function(mRecord, mData)
            local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
            self:SweepFuBenByItem2(oPlayer, iFloor, mFrozon, mData)
        end
        local iCostAmount = math.min(iItemAmount, iCostItem)
        oPlayer:RemoveItemAmount(SWEEP_ITEM,iCostAmount, sReason,{}, fCallback)
    else
        self:SweepFuBenSuccess(oPlayer, iFloor, mFrozon)
    end
end

function CHuodong:SweepFuBenByItem2(oPlayer, iFloor, mFrozon, mArgs)
    if mArgs.success then
        self:SweepFuBenSuccess(oPlayer, iFloor, mFrozon)
    else
        self:SweepFuBenFail(oPlayer, iFloor, mFrozon)
    end
end

function CHuodong:SweepFuBenFail(oPlayer, iFloor, mFrozon, mArgs)
    if mFrozon then
        local iSession, iVal = table.unpack(mFrozon)
        local oProfile = oPlayer:GetProfile()
        oProfile:UnFrozenMoney(iSession)
    end
    oPlayer:SetInfo("peFB_sweep", 0)
    --pid|玩家ID,type|副本类型,floor|层数,count|扫荡次数
    record.user("pefuben","sweep_fail", {
        pid = oPlayer:GetPid(),
        type = iFloor // FLOOR_MARK,
        floor = iFloor,
        })
end

function CHuodong:SweepFuBenSuccess(oPlayer, iFloor, mFrozon)
    oPlayer:SetInfo("peFB_sweep", 0)
    local sReason = "装备副本扫荡"
    if mFrozon then
        local oProfile = oPlayer:GetProfile()
        local iSession, iVal = table.unpack(mFrozon)
        oProfile:UnFrozenMoney(iSession)
        oPlayer:ResumeGoldCoin(iVal, sReason, {})
    end
    local iCnt = iFloor % FLOOR_MARK
    local iFB = iFloor // FLOOR_MARK
    oPlayer.m_oToday:Add("peFBcount", 1)
    oPlayer:AddSchedule("pefuben")
    self:SweepFuBenReward(oPlayer, iFloor)
    self:DoAchieve(oPlayer, iFloor)
    self:OpenMainUI(oPlayer, iFB)
end

function CHuodong:SweepFuBenReward(oPlayer, iFloor)
    local iFB = iFloor // FLOOR_MARK
    local sKey = string.format("peFBTurn_%d",iFB)
    local mTurn = oPlayer.m_oToday:Query(sKey)
    self:PassReward(oPlayer,iFB,iFloor,mTurn,mArgs)
    global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
     oPlayer.m_oToday:Delete(sKey)
end

function CHuodong:DoAchieve(oPlayer, iFloor)
    local iCnt = iFloor % FLOOR_MARK
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),string.format("通关异空流放第%d层次数",(iCnt)),{value=1})
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"通关异空流放次数",{value=1})
    oPlayer:PushBookCondition(string.format("通关第%s层异空流放次数", iCnt), {value = 1})
end


function CHuodong:TestOP(oPlayer,iFlag,...)
    local args={...}
    local oNotifyMgr = global.oNotifyMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    if iFlag == 100 then
        oChatMgr:HandleMsgChat(oPlayer,"101-进入X关卡战斗")
        oChatMgr:HandleMsgChat(oPlayer,"102-拿X关奖励")
    elseif iFlag == 102 then
        local iFloor = tonumber(args[1])
        local iFB = iFloor//FLOOR_MARK
        local mFBData = self:FuBenDaobiaoData(iFB)
        local mTurn = {
        part = table_choose_key(mFBData["part_ratio"]),
        equip=table_choose_key(mFBData["equip_ratio"]),
        }
        self:PassReward(oPlayer,iFB,iFloor,mTurn)
    elseif iFlag == 105 then
        local mData = self:GetFubenData(oPlayer)
        local iMax = mData["max_floor"] or 1
        mMyFloor = mData.floor or {}
        mFloor = mMyFloor[iMax] or {}
        mMyFloor[iMax] = mFloor
        mFloor.star = MAX_STAR
        mData["max_floor"] = iMax + 1
        mData.floor = mMyFloor
        print(mData)
        self:SetFubenData(oPlayer,mData)
    elseif iFlag == 999 then
        --(type=1,quality=2,attr=3)
        local sShape = "1028(type=1,quality=2,attr=3)"
        local loaditem = import(service_path("item/loaditem"))
        local oItem = loaditem.ExtCreate(sShape)
        print("GetItem:",oItem)
    end
end






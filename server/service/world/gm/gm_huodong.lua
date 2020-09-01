local global = require "global"
local record = require "public.record"
local interactive = require "base.interactive"
local loadtask = import(service_path("task/loadtask"))

Commands = {}
Helpers = {}
Opens = {}  --是否对外开放

Helpers.help = {
    "GM指令帮助",
    "help 指令名",
    "help 'clearall'",
}
function Commands.help(oMaster, sCmd)
    if sCmd then
        local o = Helpers[sCmd]
        if o then
            local sMsg = string.format("%s:\n指令说明:%s\n参数说明:%s\n示例:%s\n", sCmd, o[1], o[2], o[3])
            oMaster:Send("GS2CGMMessage", {
                msg = sMsg,
            })
        else
            oMaster:Send("GS2CGMMessage", {
                msg = "没查到这个指令"
            })
        end
    end
end

Helpers.setloginday = {
    "设置累积奖励登录天数",
    "setloginday 天数",
    "setloginday ７",
}
function Commands.setloginday(oMaster, iVal)
    local oNotifyMgr = global.oNotifyMgr
    iVal = iVal or 7
    if iVal < 0 then
        oNotifyMgr:Notify(oMaster:GetPid(),"天数范围要求:day >= 0")
        return
    end
    local iOldLoginDay = oMaster.m_oActiveCtrl:GetData("count_login_day", 0)
    oMaster.m_oActiveCtrl:SetData("count_login_day", iVal)
    local iLoginDay = oMaster.m_oActiveCtrl:GetData("count_login_day", 0)
    oNotifyMgr:Notify(oMaster:GetPid(), string.format("累积登录天数已设置为:%s天",iLoginDay))
    record.user("loginreward", "login_day", {
    pid = oMaster:GetPid(),
    name = oMaster:GetName(),
    grade = oMaster:GetGrade(),
    old_login_day = iOldLoginDay,
    now_login_day = oMaster.m_oActiveCtrl:GetData("count_login_day", 0),
    reason = "gm设置登录天数",
    })
end

Helpers.resetloginreward = {
    "重置登录奖励",
    "setloginreward ",
    "setloginreward ",
}
function Commands.resetloginreward(oMaster)
    local oNotifyMgr = global.oNotifyMgr
    oMaster.m_oActiveCtrl:SetData("login_rewarded_day", 0)
    oMaster:Send("GS2CLoginRewardDay", {
        rewarded_day = 0,
        })
    oNotifyMgr:Notify(oMaster:GetPid(), "登录奖励已重置")
end

Helpers.morenpc = {
    "满图刷怪",
    "morenpc 地图ID ",
    "morenpc 101000",
}
function Commands.morenpc(oMaster,iMapId)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("minglei")
    if not iMapId then
        oHuodong:FullMonster(101000)
    else
        oHuodong:FullMonster(iMapId)
    end
end

Helpers.addlilian = {
    "增加修行次数,若无目标ID则默认为自身",
    "addlilian 修行次数 目标ID",
    "addlilian 修行次数 目标ID",
}

function Commands.addlilian(oMaster,iTimes,iTarget)
    local oWorldMgr = global.oWorldMgr
    local oTarget = oMaster
    if iTarget then
        oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    end
    if not oTarget then
        return
    end
    if iTimes > 0 then
        oTarget.m_oHuodongCtrl:AddTrainRewardTime(tonumber(iTimes),string.format("%s使用gm指令给%s添加修行次数",oMaster:GetName(),oTarget:GetName()))
    else
        oTarget.m_oHuodongCtrl:DelTrainRewardTime(-iTimes,string.format("%s使用gm指令给%s减少修行次数",oMaster:GetName(),oTarget:GetName()))
    end
end


Helpers.SetTreasureReward = {
    "设置下次挖宝必中物品,type和value对应treasureevent表里面填的数据",
    --type为3则默认贪玩童子，type为4则默认传说伙伴
    "SetTreasureReward type value ",
}
function Commands.SetTreasureReward(oMaster,iType,iValue)
    local mData
    if iType == 3 then
        mData = {2,1}
    elseif iType == 4 then
        local iCurTimes = oMaster.m_oActiveCtrl:GetTreasureTotalTimes()
        local t = iCurTimes + (5 - iCurTimes%5) - 1
        oMaster.m_oActiveCtrl:SetTreasureTotalTimes(t)
        mData = {2,2}
    else
        mData = {iType,iValue}
    end
    local sKey = "GMTreasure"
    oMaster.m_oItemCtrl:SetPlayerInfo(oMaster,sKey,mData)
end

function Commands.GetMonitorObj(oMaster)
    local oHuodongMgr = global.oHuodongMgr
    local mMonitor = {}
    if oHuodongMgr.m_mHuodongList then
        for _,oHuodong in pairs(oHuodongMgr.m_mHuodongList) do
            if oHuodong.m_oRewardMonitor then
                table.insert(mMonitor,oHuodong.m_oRewardMonitor)
            end
        end
    end
    local oTaskMonitor  = global.oTaskMgr:GetTaskRewardMonitor()
    table.insert(mMonitor,oTaskMonitor)
    return mMonitor
end

Helpers.ClearMonitor = {
    "清空奖励监控数据",
    --不填1则默认只清自己的，填了则清所有玩家的
    "ClearMonitor 1 ",
}

function Commands.ClearMonitor(oMaster,iIsAll)
    local iTarget = iIsAll ~= 1 and oMaster:GetPid() or nil
    local mMonitor = Commands.GetMonitorObj(oMaster)
    for _,obj in pairs(mMonitor) do
        obj:ClearRecordInfo(iTarget)
    end
end

Helpers.hdnewhour = {
    "采用测试时间活动刷时",
    "hdnewhour"
}

function Commands.hdnewhour(oMaster,...)
    local oHDMgr = global.oHuodongMgr
    local oWorldMgr = global.oWorldMgr
    local iTime = oWorldMgr:GetNowTime()
    local mDate = os.date("*t",iTime)
    local iWeekDay = get_weekday(iTime)
    local iHour = mDate.hour
    oHDMgr:CleanHuodongState(iHour)

    interactive.Send(".assisthd", "common", "NewHour", {
        weekday = iWeekDay,
        hour = iHour,
    })

    for sName,_ in pairs(oHDMgr.m_mHuodongList) do
        local fNewHour = function ()
            local oHuodong = oHDMgr:GetHuodong(sName)
            if oHuodong then
                oHuodong:NewHour(iWeekDay,iHour)
            end
        end
        safe_call(fNewHour)
    end
end

Helpers.setpatalv = {
    "设置爬塔层数",
    "setpatalv 层数",
    "setpatalv 10",
}

function Commands.setpatalv(oMaster,iLevel)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("pata")
    oHuoDong:SetPlayerLevel(oMaster,iLevel)
    oHuoDong:OpenPataUI(oMaster)
end

function Commands.startfilm(oMaster,sFilm)
    local oWarFilmMgr = global.oWarFilmMgr
    sFilm = tostring(sFilm)
    oWarFilmMgr:StartFilm(oMaster,sFilm)
end

function Commands.savefilm(oMaster)
    local oWarFilmMgr = global.oWarFilmMgr
    oWarFilmMgr:_CheckSave(oMaster)
end

function Commands.testreward(oMaster)
    local oModule = import(service_path("templ"))
    local oTempl = oModule.CTempl:New()
    oTempl:Reward(oMaster:GetPid(),1001)
end

Helpers.setaibattle = {
    "比武场匹配AI",
    "setaibattle",
}

function Commands.setaibattle(oMaster)
    oMaster.m_TestAiBattle  = 1
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oMaster:GetPid(),"下场开始进行AI比武")
end


Helpers.arenaon = {
    "开启比武场",
    "arenaon",
}

function Commands.arenaon(oMaster)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("arenagame")
    oHuoDong:TestOP(oMaster,101)
end

Helpers.arenaoff = {
    "关闭比武场",
    "arenaoff",
}

function Commands.arenaoff(oMaster)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("arenagame")
    oHuoDong:TestOP(oMaster,102)
end

function Commands.mingleiinfo(oMaster)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("minglei")
    oHuodong:GetCurMapInfo(oMaster)
end

function Commands.SetMingleiTime(oMaster,iTime)
    oMaster.m_oToday:Set("minglei_fighttime",iTime)
end

Helpers.arenapoint = {
    "增加比武积分",
    "arenapoint 999",
}

function Commands.arenapoint(oMaster,ipoint)
    oMaster:SetArenaScore(ipoint)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("arenagame")
    oHuoDong:RecordRank(oMaster)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oMaster:GetPid(),string.format("竞技点设置为 %d",ipoint))
end

function Commands.TestDailyTask(oMaster)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("dailytask")
    oHuoDong:GMTest(oMaster)
end

function Commands.AddLingli(oMaster,iValue,iTarget)
    local oWorldMgr = global.oWorldMgr
    local oPlayer
    if iTarget then
        oPlayer = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        if not oPlayer then
            return
        end
    else
        oPlayer = oMaster
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
    oHuodong:GMSetLingli(oPlayer,iValue or 10)
end

function Commands.TerraWarsPartner(oMaster,iCreateOrg)
    oMaster:RewardExp(10000000,"gm",{bEffect = false})
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "addpartner", {{301, 20}})
    for i=1,20 do
        oMaster.m_oPartnerCtrl:Forward("C2GSRenamePartner", oMaster:GetPid(), {partnerid=i,name="伙伴"..i})
        oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "addexp", {i, 1000000})
    end
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(oMaster:GetPid(),function (oProfile)
        if not oProfile then
            return
        end
        oProfile:AddGoldCoin(1000000,"gm")
    end)
    -- if iCreateOrg == 1 then
    --     local temp = "1234567890qwertyuiopasdfghjklzxcvbnm请清情轻青未位喂味俄饿呃恶任忍认仁填田添甜阿吖呵腌噢喔嚄筽飘陪跑怕类来漏雷卡口框看及将旧级和唤呼会个给改过服分发否秒码萌满为额人天已朋啊时的防该后加可了再先次表你摸好日啥杀傻沙砂鈤馹囸氜槽草操曹肏"
    --     local oOrgMgr = global.oOrgMgr
    --     if oOrgMgr:IsClose(oPlayer) then
    --         return
    --     end
    --     local sFlag = string.sub(temp,1,1)
    --     for i=2,string.len(temp)-1 do
    --         if oOrgMgr:GetNormalOrgByFlag(sFlag) then
    --             sFlag = string.sub(temp,i,1)
    --         else
    --             break
    --         end
    --     end
    --     local tArgs = {
    --          sflag=sFlag,
    --          flagbgid=1,
    --          aim = "qqqqqqqqqq",
    --     }
    --     oOrgMgr:CreateNormalOrg(oMaster, oMaster:GetName(), tArgs)
    -- end
end

function Commands.ShowTerra(oMaster)
    interactive.Send(".rank","rank","ResetTerrawars",{})
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("terrawars")
    oHuoDong:Close()
    oHuoDong:DelTimeCb("StartPrepare")
    oHuoDong:DelTimeCb("StartClose")
    oHuoDong:StartOpen()
end

function Commands.TerraNewHour(oMaster,iW,iH)
    global.oRankMgr:NewHour(iW,iH)
end

function Commands.TestOpenTime(oMaster)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("terrawars")
    oHuoDong:TestOpenTime(4,0,0)
end

function Commands.TestSaveDb(oMaster)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("terrawars")
    oHuoDong:SaveDb()
end

function Commands.TestInitName(oMaster)
    local oRenameMgr = global.oRenameMgr
    oRenameMgr:InitRoleName(oMaster, "444")
end

function Commands.fieldbossreborn(oMaster,iBossid)
    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
    oHuodong:RebornBoss(iBossid)
end

function Commands.clearplayerterra(oMaster)
    local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
    oHuoDong:ClearPlayerInfo(oMaster.m_iPid)
end

function Commands.ClearTerra(oMaster,iTerraId)
    local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
    oHuoDong:ClearTerra(iTerraId)
end

function Commands.RefreshColdTime(oMaster,iTerraId)
    local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
    local oTerra = oHuoDong:GetTerra(iTerraId)
    if oTerra then
        oTerra:SetSaveTime(0)
    end
end

function Commands.CloseTerra(oMaster)
    local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
    oHuoDong:DelTimeCb("StartPrepare")
    oHuoDong:DelTimeCb("StartOpen")
    oHuoDong:StartClose()
end

function Commands.PrepareTerra(oMaster)
    local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
    oHuoDong:DelTimeCb("StartClose")
    oHuoDong:DelTimeCb("StartOpen")
    oHuoDong:StartPrepare()
end

function Commands.GetFieldbossInfo(oMaster)
    local oHuoDong = global.oHuodongMgr:GetHuodong("fieldboss")
    local oBossBattle = oHuoDong.m_mBossBattle[1]
    for npcid,oNpc in pairs(oBossBattle.m_mNpcList) do
        print(oNpc.m_mPosInfo)
    end
end

function Commands.fixterrabug(oMaster)
    local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
    oHuoDong:FixBug()
end

function Commands.ReInitFieldBoss(oMaster)
    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
    oHuodong:Clean()
end

function Commands.SetFieldBossHp(oMaster,iBossid,iRate)
    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
    oHuodong:SetFieldBossHp(iBossid,iRate)
end

function Commands.TestTime(oMaster,iEndTime)
    local mTime = os.date("%H:%M:%S",iEndTime)
    global.oNotifyMgr:Notify(oMaster.m_iPid,mTime)
    global.oNotifyMgr:Notify(oMaster.m_iPid,get_dayno())
end

function Commands.PrintFieldbossInfo(oMaster,iBossId)
    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
    oHuodong:PrintFieldbossInfo(iBossId)
end

function Commands.startoffline(oMaster)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("trapmine")
    if not oHuodong then
        return
    end
    local oScene = oMaster.m_oActiveCtrl:GetNowScene()
    if not oScene:HasAnLei()  then
        return
    end
    local iMapId = oScene:MapId()
    if not oHuodong:ValidStart(oMaster, iMapId) then
        return
    end
    local oSceneMgr = global.oSceneMgr
    oSceneMgr:ClickOfflineTrapMineMap(oMaster,iMapId)
    local fCallback = function ()
        oHuodong:StartOfflineTrapmine(oMaster, iMapId)
    end
    oSceneMgr:QueryPos(oMaster:GetPid(),fCallback)
end

function Commands.stopoffline(oMaster)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("trapmine")
    if not oHuodong then
        return
    end
    local oScene = oMaster.m_oActiveCtrl:GetNowScene()
    if not oScene:HasAnLei()  then
        return
    end
    local iMapId = oScene:MapId()
    oHuodong:StopTrapmine(oMaster, iMapId)
end

Helpers.ResetOnlineGift = {
    "重置在线奖励数据",
    "ResetOnlineGift",
    "ResetOnlineGift 重置类型（1为全部重置，2为重置领奖状态） iPid(目标ID，可不填，不填默认为自己)"
}

function Commands.ResetOnlineGift(oMaster,iResetType,iPid)
    if not iResetType then
        global.oNotifyMgr:Notify(oMaster,"参数错误")
        return
    end
    local oTarget = oMaster
    if iPid then
        oTarget = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    end
    if not oTarget then
        return
    end
    if iResetType == 1 then
        local mOnlineGift = {status = 0,onlinetime = 0}
        oTarget:Send("GS2COnlineGift",mOnlineGift)
        mOnlineGift["lastrecordtime"] = get_time()
        oTarget.m_oActiveCtrl:SetData("onlinegift",mOnlineGift)
    elseif iResetType == 2 then
        local mOnlineGift = oTarget.m_oActiveCtrl:GetData("onlinegift",{})
        mOnlineGift["status"] = 0
        oTarget:Send("GS2COnlineGift",{status = 0,onlinetime = mOnlineGift["onlinetime"]})
        oTarget.m_oActiveCtrl:SetData("onlinegift",mOnlineGift)
    end
end

--完成主线任务10000，触发开启关卡1-1
function Commands.TestChapterfb1(oMaster)
    for taskid,oTask in pairs(oMaster.m_oTaskCtrl.m_mList) do
        oMaster.m_oTaskCtrl:RemoveTask(oTask)
    end
    local oTask = loadtask.CreateTask(10001)
    if not oTask then
        return
    end
    oMaster:AddTask(oTask)
    oMaster.m_oHuodongCtrl:OnFinishStoryTask()
end

--升级，触发下一关
function Commands.TestChapterfb2(oMaster)
    oMaster:RewardExp(300000,"gm",{bEffect = false})
end

function Commands.OpenChapter(oMaster,iChapter,iType)
    oMaster.m_oHuodongCtrl:GMOpenChapter(iChapter,iType)
end

function Commands.GetConvoyInfo(oMaster)
    local iTotalRefreshTime = oMaster.m_oActiveCtrl:GetData("convoy_refresh",0)
    global.oNotifyMgr:Notify(oMaster.m_iPid,string.format("当前刷新次数为：%d",iTotalRefreshTime))
end

function Commands.luckdrawreset(oMaster)
    global.oFuliMgr:RefreshLuckItem()
end

function Commands.convoyinfo(oMaster)
    local iTime = oMaster.m_oToday:Query("convoytime",0)
    global.oNotifyMgr:Notify(oMaster.m_iPid,"已护送次数："..iTime)
end

function Commands.SetHeroBoxReward(oMaster,iType,iIndex)
    if not iType or not iIndex then
        return
    end
    local mData = {iType,iIndex}
    local sKey = "GMHeroBox"
    oMaster:SetInfo(sKey,mData)
end
----------------------------------------开放指令-----------------------------
Opens["huodong"] = true
function Commands.huodong(oMaster,sName,...)
    local mArg = {...}
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong(sName)
    if oHuoDong and oHuoDong.TestOP then
        oHuoDong:TestOP(oMaster,...)
    else
        global.oNotifyMgr:Notify(oMaster:GetPid(),"没有该活动")
    end
end

function Commands.RefreshHeroBox(oMaster)
    local oHuodong = global.oHuodongMgr:GetHuodong("herobox")
    oHuodong:DelTimeCb("_RefreshBox")
    oHuodong:ClearLastHourBox()
    oHuodong:RefreshBox()
end

function Commands.TerrawarBrocast(oMaster)
    local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
    oHuodong:SendWarBrocast()
end

function Commands.ShowVirtualChat(oMaster)
    local oHuodong = global.oHuodongMgr:GetHuodong("virtualchat")
    if oHuodong then
        print(oHuodong.m_mRobot)
    end
end

function Commands.TestCharge(oMaster,iNum)
    local oHuodong = global.oHuodongMgr:GetHuodong("chargescore")
    if oHuodong then
        oHuodong:AfterCharge(oMaster,iNum)
    end
end


Opens["quitkfwar"] = true
function Commands.quitkfwar(oMaster,iTarget)
    local oTarget = global.oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oTarget then
        local oWar = oTarget:GetNowWar()
        if oWar and oWar.m_KFProxy then
            oWar:TestCmd("warend",iTarget,{})
        end
    end
end

Opens["quitkfgame"] = true
function Commands.quitkfgame(oMaster,iTarget)
    local oTarget = global.oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oTarget then
        local oProxy = global.oKFMgr:GetProxy(iTarget)
        if oProxy then
            local sMode = oProxy:GetMode()
            local oHuodong = global.oHuodongMgr:GetHuodong(sMode)
            if oHuodong then
                oHuodong:_CheckInMatch(oTarget,1)
            end
        end
    end
end

function Commands.Test(oMaster)
    local oHuodong = global.oHuodongMgr:GetHuodong("question")
    oHuodong:SetHuodongState(2)
end

function Commands.hdtime(oMaster,iWeekDay,iHour)
    if not iWeekDay or not iHour then
        return
    end
    local oHDMgr = global.oHuodongMgr
    local oWorldMgr = global.oWorldMgr
    local iTime = oWorldMgr:GetNowTime()
    local mDate = os.date("*t",iTime)
    oHDMgr:CleanHuodongState(iHour)

    interactive.Send(".assisthd", "common", "NewHour", {
        weekday = iWeekDay,
        hour = iHour,
    })

    for sName,_ in pairs(oHDMgr.m_mHuodongList) do
        local fNewHour = function ()
            local oHuodong = oHDMgr:GetHuodong(sName)
            if oHuodong then
                oHuodong:NewHour(iWeekDay,iHour)
            end
        end
        safe_call(fNewHour)
    end
end

function Commands.resume(oMaster,iReward)
    local oHuodong = global.oHuodongMgr:GetHuodong("timelimitresume")
    if oHuodong then
        oHuodong:GetTimeResumeReward(oMaster, iReward)
    end
end


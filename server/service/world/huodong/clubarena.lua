--import module
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"


local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))


function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "武馆"
inherit(CHuodong, huodongbase.CHuodong)

NEWBIE = 1

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_AutoReward = {}
    return o
end


function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.reward = self.m_AutoReward
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    self.m_AutoReward = mData["reward"] or {}
end



function CHuodong:AddAutoReward(iPid,iClub,iNum)
    if not self.m_AutoReward[iPid] then
        self.m_AutoReward[iPid] = {}
    end
    local m = self.m_AutoReward[iPid]
    if not m[iClub] then
         m[iClub] = 0
    end
    m[iClub]  = m[iClub]  + iNum
    self:Dirty()
end

function CHuodong:PopAutoReward(iPid)
    local m = self.m_AutoReward[iPid]
    self.m_AutoReward[iPid] = nil
    self:Dirty()
    return m
end

function CHuodong:GetArenaData(oPlayer)
return oPlayer.m_oHuodongCtrl:GetData("ClubArena",{})
end

function CHuodong:SetArenaData(oPlayer,mData)
    oPlayer.m_oHuodongCtrl:SetData("ClubArena",mData)
end


function CHuodong:SendAssist(sFunc,mArg,callback)
    if not callback then
        interactive.Send(".assisthd","clubarena",sFunc,mArg)
    else
        interactive.Request(".assisthd","clubarena",sFunc,mArg,function(mRecord,mData)
            callback(mRecord,mData)
            end)
    end
end


function CHuodong:UpdateInfo(oPlayer)
    local iGrade = global.oWorldMgr:QueryControl("clubarena","open_grade")
    if oPlayer:GetGrade() < iGrade then
        return
    end
    local iPid = oPlayer:GetPid()
    local sKey = string.format("update_key%s",iPid)
    local f = function()
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:UpdateInfo2(oPlayer)
        end
    end
    self:DelTimeCb(sKey)
    self:AddTimeCb(sKey,5000,f)
end

function CHuodong:UpdateInfo2(oPlayer)
    local iPid = oPlayer:GetPid()
    local f = function (oRom)
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:UpdateInfo3(oPlayer,oRom)
        end
    end
    self:SaveRom(oPlayer,f)
end

function CHuodong:UpdateInfo3(oPlayer,oRom)
    local mWarInfo = oRom:ClubArenaData()
    local mPartner = mWarInfo["partner"]
    local parlist = {}
    local postlist = {}
    local iCnt = 1
    for _,m in ipairs(mPartner) do
        table.insert(parlist,m["parid"])
        table.insert(postlist,iCnt)
        iCnt = iCnt + 1
    end
    self:SaveDefencePartner(oPlayer,postlist,parlist)
end

function CHuodong:GetWarPower(oPlayer,oRom)
    local iPower = oPlayer:GetPower()
    local mPlayer = oRom:ClubArenaData()
    if not mPlayer or #mPlayer["partner"] == 0 then
        return iPower
    end
    for _,mPartner in ipairs(mPlayer["partner"]) do
        iPower = iPower + mPartner["power"]
    end
    return iPower
end

function CHuodong:SaveRoleInfo(oPlayer,oRom)
    local mData = {
                name = oPlayer:GetName(),
                org = oPlayer:GetOrgName(),
                power = self:GetWarPower(oPlayer,oRom),
                model = oPlayer:GetModelInfo(),
    }
    self:SendAssist("UpdateInfo",{pid=oPlayer:GetPid(),data=mData})
end

function CHuodong:SaveRom(oPlayer,fbackcall)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local mWarInfo = oPlayer:PackWarInfo()

    local f = function (oRom)
        self:SaveRom2(oRom,mWarInfo,fbackcall)
    end
    oWorldMgr:LoadRom(iPid,f)
end

function CHuodong:SaveRom2(oRom,mWarInfo,fbackcall)
    mWarInfo["is_team_leader"] = nil
    mWarInfo["team_size"] = 0
    mWarInfo["testman"] = nil
    oRom:UpdateWar(mWarInfo)
    if fbackcall then
        fbackcall(oRom)
    end
end

function CHuodong:SaveDefencePartner(oPlayer,poslist,parlist)
    local oWorldMgr = global.oWorldMgr
    local m = {}
    for _,parid in ipairs(parlist) do
        if not table_in_list(m,parid) then
            table.insert(m,parid)
        end
    end
    if #m<= 0  then
        return
    end
    local func = function (iPid,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:SaveDefencePartner2(oPlayer,poslist,mData)
        end
    end
    oPlayer.m_oPartnerCtrl:GetPartnerWarInfoList(m,func)
end

function CHuodong:SaveDefencePartner2(oPlayer,poslist,mData)
    if #mData == 0 then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local mSet = {}
    for idx,mInfo in ipairs(mData) do
        local iPos = poslist[idx]
        mInfo.equip = nil
        mSet[iPos] = mInfo
    end

    local f = function (oRom)
        self:SaveDefencePartner3(oRom,mSet)
    end
    oWorldMgr:LoadRom(iPid,f)
end

function CHuodong:SaveDefencePartner3(oRom,mSetPartner)
    oRom:SetClubArenaPartner(mSetPartner)
    local iPid = oRom:GetPid()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local mArg = {
                    pid = iPid,
                    data = {
                        name = oPlayer:GetName(),
                        org = oPlayer:GetOrgName(),
                        power = oPlayer:GetPower(),
                        model = oPlayer:GetModelInfo(),
                    },
            }
        self:SendAssist("CreateNewMember",mArg)
        self:SaveRoleInfo(oPlayer,oRom)
    end
end

function CHuodong:LeftPlayTimes(oPlayer)
    local mData = self:GetArenaData(oPlayer)
    return math.max(0,self:GetConfigValue("max_times") +(mData["playcnt"] or 0) - oPlayer.m_oToday:Query("clubarena_free_cnt",0))
end

function CHuodong:TodayMaxTimes(oPlayer)
    local mData = self:GetArenaData(oPlayer)
    local iCnt = mData["playcnt"] or 0
    return self:GetConfigValue("max_times") + iCnt + oPlayer.m_oToday:Query("clubarena_cost_cnt",0)
end

function CHuodong:TodayUseTimes(oPlayer)
    return oPlayer.m_oToday:Query("clubarena_free_cnt",0) + oPlayer.m_oToday:Query("clubarena_cost_cnt",0)
end

function CHuodong:UsePlayTimes(oPlayer)
    if oPlayer.m_oToday:Query("clubarena_free_cnt",0) < self:GetConfigValue("max_times") then
        oPlayer.m_oToday:Add("clubarena_free_cnt",1)
    else
        oPlayer.m_oToday:Add("clubarena_cost_cnt",1)
        local mData = self:GetArenaData(oPlayer)
        mData["playcnt"] = math.max(mData["playcnt"] - 1,0)
        self:SetArenaData(oPlayer,mData)
    end
end

function CHuodong:OnLogin(oPlayer,reener)
    self:CheckAutoReward(oPlayer)
    self:UpdateInfo(oPlayer)
end

function CHuodong:OnDisconnected(oPlayer)
    self:UpdateInfo(oPlayer)
end

function CHuodong:CheckAutoReward(oPlayer)
    if not self.m_AutoReward[oPlayer:GetPid()] then
        return
    end
    local m = self:PopAutoReward(oPlayer:GetPid())
    for iClub,iNum in pairs(m) do
        self:AutoReward(oPlayer,iClub,iNum)
    end
end


function CHuodong:GiveAutoReward(mData)
    local oWorldMgr = global.oWorldMgr
    local mReward = mData["reward"]
    local f = function(iPid,iClub,iNum)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:AutoReward(oPlayer,iClub,iNum)
        else
            self:AddAutoReward(iPid,iClub,iNum)
        end
    end

    for _,m in ipairs(mReward) do
        f(m[1],m[2],m[3])
    end
end

function CHuodong:NotifyMessage(mData)
    local iType = mData["type"]
    local sText = mData["text"]
    local oNotifyMgr = global.oNotifyMgr
    local oMailMgr = global.oMailMgr
    if iType == 1 then
        oNotifyMgr:SendPrioritySysChat("huodong_char",sText,1)
    elseif iType == 2 then
        local target = mData["target"]
        local info = table_deep_copy(oMailMgr:GetMailInfo(76))
        info.context = sText
        oMailMgr:SendMail(0, "系统", target, info, {}, {}, {})
    end
end

function CHuodong:AutoReward(oPlayer,iClub,iCoin)
    oPlayer:RewardArenaMedal(iCoin, "clubarena", {cancel_tip=1,cancel_channel=1})
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        local fcallback = function (mRecord,mData)
            local sLog = ConvertTblToStr(mData["data"])
            record.user("clubarena","reward_cluba",{reward=sLog})
            self:RewardDay(mData["data"])
        end
        self:SendAssist("GetRewardDay",{},fcallback)
    end
end

function CHuodong:RewardDay(mRewardList)
    self:DelTimeCb("RewardDay")
    if #mRewardList <= 0 then
        return
    end
    self:AddTimeCb("RewardDay",5*1000,function ()
        self:RewardDay(mRewardList)
        end)
    for i = 1,100 do
        if #mRewardList == 0 then
            break
        end
        local m = table.remove(mRewardList,1)
        self:SendDayReward(m)
    end
end

function CHuodong:SendDayReward(m)
    local iClub  = m[1]
    local iPid = m[2]
    local m = self:GetRewardInfo(iClub)
    local sName = m["desc"]
    local mReward = m["reward_day"]
    local iMail = 75
    local oMailMgr = global.oMailMgr
    local info = table_deep_copy(oMailMgr:GetMailInfo(iMail))
    info.context = string.gsub(info.context,"CLUB",sName)
    self:RewardListByMail(iPid,mReward,{mailinfo = info})
end


function CHuodong:GetRewardInfo(iClub)
     local res = require "base.res"
    local mData = assert(res["daobiao"]["huodong"][self:ResName()]["config"][iClub])
    return mData
end



function CHuodong:StartRomWar(oPlayer,iPid,mArgs)
    if oPlayer:GetPid() == iPid then
        self:UnLockWar(oPlayer:GetPid(),mArgs["club"],mArgs["post"],mArgs["target"])
        return
    end
    local oWorldMgr = global.oWorldMgr
    local iOwner = oPlayer:GetPid()
    local f = function (oRom)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iOwner)
        if oPlayer then
            self:StartRomWar2(oPlayer,oRom,mArgs)
        else
            self:UnLockWar(iOwner,mArgs["club"],mArgs["post"],mArgs["target"])
        end
    end
    oWorldMgr:LoadRom(iPid,f)
end


function CHuodong:StartRomWar2(oPlayer,oRom,mArgs)
    if not oRom then
        self:UnLockWar(oPlayer:GetPid(),mArgs["club"],mArgs["post"],mArgs["target"])
        return
    end
    local mWarInfo = oRom:ClubArenaData()
    if not mWarInfo then
        self:UnLockWar(oPlayer:GetPid(),mArgs["club"],mArgs["post"],mArgs["target"])
        return
    end
    local mRomPlayer = mWarInfo["player"]
    local mPartner = table_copy(mWarInfo["partner"])
    --[[
    if table_count(mPartner) ~= 4 then
        return
    end
    ]]
    local oWar  = self:CreateRomWar(oPlayer:GetPid(),nil,mRomPlayer,mPartner)
    if oWar then
        oWar.m_ClubInfo = mArgs
    else
        self:UnLockWar(oPlayer:GetPid(),mArgs["club"],mArgs["post"],mArgs["target"])
    end
end


function CHuodong:RobotInfo(iR)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["robot"]
    return mData[iR]
end

function CHuodong:StartRobotWar(oPlayer,mRobot,mInfo)
    local iFight = mRobot["tollgate"]
    local oWar = self:CreateWar(oPlayer:GetPid(),nil,iFight)
    return oWar
end


function CHuodong:GetCreateWarArg(mArg)
    mArg.remote_war_type = "clubarena"
    mArg.war_type = gamedefines.WAR_TYPE.CLUB_TYPE
    return mArg
end

function CHuodong:GetRemoteWarArg()
    return {
        war_record = 1,
    }
end


function CHuodong:OpenMainUI(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local f = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:OpenMainUI2(oPlayer,mData)
        end

    end
    self:SendAssist("OpenMainUI",{pid=oPlayer:GetPid(),},f)
end


function CHuodong:OpenMainUI2(oPlayer,m)
    local iClub = m["data"]["club"] or NEWBIE
    local iCoin = 0
    if m["data"]["master"] then
        local mReward = self:GetRewardInfo(iClub)
        iCoin = mReward["reward_time"]
    end
    local mNet = {
        club = iClub,
        cd_fight = oPlayer.m_oThisTemp:QueryLeftTime("clubarena_cd"),
        coin_reward = iCoin,
        gold_reward = m["data"]["coin"],
        max_times = self:TodayMaxTimes(oPlayer),
        use_times = self:TodayUseTimes(oPlayer),
        master = m["data"]["name"],
        }
    oPlayer:Send("GS2CClubArenaMainUI",mNet)
end


function CHuodong:ResetEnemy(oPlayer,iClub)
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local iBase = self:GetConfigValue("reset_cost")
    local sKey = string.format("cbarena_reset_%d",iClub)
    local iToday = oPlayer.m_oToday:Query(sKey,0)
    local iCost = 0
    if iClub ~= NEWBIE then
        iCost = iToday * iBase
    end
    if iCost > 0 then
        local sContent = self:GetTextData(1018)
        sContent = string.gsub(sContent,"COST",iCost)
        local iPid = oPlayer:GetPid()
        local fback = function(oResponse,mData)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer and mData.answer ==1 then
                self:ResetEnemy2(oPlayer,iClub,iCost)
            end
        end
        oCbMgr:SimpleConfirmUI(iPid,sContent,nil,nil,0,fback)
    else
        self:ResetEnemy2(oPlayer,iClub,iCost)
    end
end

function CHuodong:ResetEnemy2(oPlayer,iClub,iCost)
    local oNotifyMgr = global.oNotifyMgr
    if iCost > 0 then
        if not oPlayer:ValidGoldCoin(iCost,"clubarena_reset") then
            return
        end
        oPlayer:ResumeGoldCoin(iCost,"clubarena_reset")
    end

    local sKey = string.format("cbarena_reset_%d",iClub)
    if iClub ~= NEWBIE then
        oPlayer.m_oToday:Add(sKey,1)
    end
    local mFight = oPlayer.m_oToday:Query("clubarena_fight",{})
    if mFight[iClub] then
        mFight[iClub] = nil
    end
    oPlayer.m_oToday:Set("clubarena_fight",mFight)
    local mData = self:GetArenaData(oPlayer)
    mData["playcnt"]  = mData["playcnt"] or 0 + 1
    self:SetArenaData(oPlayer,mData)
    self:OpenClubUI(oPlayer,iClub)
end


function CHuodong:CleanCBTime(oPlayer)
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local iSum = self:GetConfigValue("cb_cost")
    local iTime = oPlayer.m_oThisTemp:QueryLeftTime("clubarena_cd")
    --总水晶-总水晶/600*（600-剩余时间）
    local iCost = math.floor(iSum - iSum /600*(600-iTime))

    local sContent = self:GetTextData(1015)
    sContent = string.gsub(sContent,"COST",iCost)
    local iPid = oPlayer:GetPid()
    local fback = function(oResponse,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer and mData.answer ==1 then
            self:CleanCBTime2(oPlayer,iCost)
        end
    end
    oCbMgr:SimpleConfirmUI(iPid,sContent,nil,nil,0,fback)
end

function CHuodong:CleanCBTime2(oPlayer,iCost)
    if iCost < 1 then
        return
    end
    if not oPlayer:ValidGoldCoin(iCost) then
        return
    end
    oPlayer:ResumeGoldCoin(iCost,"武馆清除CD")
    oPlayer.m_oThisTemp:Delete("clubarena_cd")
    self:OpenMainUI(oPlayer)
end

function CHuodong:AddClubArenaFightCnt(oPlayer)
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local iCost = self:GetConfigValue("addcnt_cost")
    local iBuy = oPlayer.m_oToday:Query("buy_clubcnt",0) + 1
    iCost = iBuy*iCost
    local sContent = self:GetTextData(1014)
    sContent = string.gsub(sContent,"COST",iCost)
    sContent = string.gsub(sContent,"CNT",1)
    local iPid = oPlayer:GetPid()
    local fback = function(oResponse,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer and mData.answer ==1 then
            self:AddClubArenaFightCnt2(oPlayer,iCost)
        end
    end
    oCbMgr:SimpleConfirmUI(iPid,sContent,nil,nil,0,fback)
end

function CHuodong:AddClubArenaFightCnt2(oPlayer,iNeed)
    local iCost = self:GetConfigValue("addcnt_cost")
    local iBuy = oPlayer.m_oToday:Query("buy_clubcnt",0) + 1
    iCost = iBuy*iCost
    if iCost ~= iNeed or not oPlayer:ValidGoldCoin(iCost) then
        return
    end
    oPlayer:ResumeGoldCoin(iCost,"武馆增加次数")
    oPlayer.m_oToday:Add("buy_clubcnt",1)
    local mData  = self:GetArenaData(oPlayer)
    mData["playcnt"] = (mData["playcnt"] or 0) + 1
    self:SetArenaData(oPlayer,mData)
    self:OpenMainUI(oPlayer)
end

function CHuodong:SaveClubArenaLineup(oPlayer,mData)
    local parlist = mData["parlist"]
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local postlist = {}
    local mPartnerList = {}
    local iCnt = 1
    for iPos,parid in ipairs(parlist) do
        table.insert(mPartnerList,parid)
        table.insert(postlist,iCnt)
        iCnt = iCnt + 1
    end
    self:SaveDefencePartner(oPlayer,postlist,mPartnerList)
end


function CHuodong:SendClubArenaDefensePartner(oPlayer)
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local f = function (oRom)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:SendClubArenaDefensePartner2(oPlayer,oRom)
        end
    end
    oWorldMgr:LoadRom(iPid,f)
end

function CHuodong:SendClubArenaDefensePartner2(oPlayer,oRom)
    local mNet = {parlist={}}
    local m = oRom:ClubArenaData()
    if m then
        local mPartner = m["partner"]
        if mPartner then
            for _,mPartner in pairs(mPartner) do
                table.insert(mNet["parlist"],mPartner["parid"])
            end
        end
    end
    oPlayer:Send("GS2CClubArenaDefenseLineUp",mNet)
end

function CHuodong:OpenClubUI(oPlayer,iClub)
    if iClub < NEWBIE or iClub > 6 then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local mFight = oPlayer.m_oToday:Query("clubarena_fight",{})
    local m = self:GetArenaData(oPlayer)
    local iPid = oPlayer:GetPid()
    local mArg = {
        info = m,
        pid = iPid,
        club = iClub,
        fight = mFight[iClub],
    }

    local fbackcall = function(mRecord,mData)
            local f2 = function(oRom)
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    self:OpenClubUI2(oPlayer,iClub,mData["data"],oRom)
                end
            end
            oWorldMgr:LoadRom(iPid,f2)
    end
    self:SendAssist("GetClubFightInfo",mArg,fbackcall)
end



function CHuodong:OpenClubUI2(oPlayer,iClub,mData,oRom)
    local mFight = mData["fight"]
    local mInfo = mFight["fight"]
    local m = oPlayer.m_oToday:Query("clubarena_fight",{})
    if mFight["new"] then
        m[iClub] = mInfo
        oPlayer.m_oToday:Set("clubarena_fight",m)
    end

    local fpack = function(m)
        return {
            pid=m["pid"] or 0,
            club = m["club"],
            power = m["power"],
            model = m["model"],
            name = m["name"],
            orgname = m["orgname"],
            post = 0,
        }
    end
    local mEnemy = {}
    for i,m in ipairs(mInfo) do
        local mPack = fpack(m)
        mPack["post"] = i
        table.insert(mEnemy,mPack)
    end


    local mArena = self:GetArenaData(oPlayer)
    local mClub = mArena[iClub] or {}
    local mNet = {
        club = iClub,
        power = self:GetWarPower(oPlayer,oRom),
        enemy = mEnemy,
        win = mClub["win"],

        }

    if mFight["master"] then
        mNet["master"] = fpack(mFight["master"])
    end
    oPlayer:Send("GS2CClubArenaInfo",mNet)
end



function CHuodong:UnLockWar(iPid,iClub2,iPost2,target)
    local mArg = {
    pid = iPid,
    club = iClub2,
    post = iPost2,
    target= target,
    }
    self:SendAssist("UnLockWar",mArg)
end

function CHuodong:LockWar(iPid,iClub,iPost,iTarget,callback)
    local mArg = {
    pid = iPid,
    club = iClub,
    post = iPost,
    target = iTarget,
    }

    self:SendAssist("LockWar",mArg,callback)
end

function CHuodong:ClubArenaFight(oPlayer,mData)
    local oWorldMgr = global.oWorldMgr
    local iPost = mData["post"]
    local iClub = mData["club"]
    local iTarget = mData["pid"]

    local iPid = oPlayer:GetPid()
    local f = function (oRom)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:ClubArenaFight2(oPlayer,oRom,iClub,iPost,iTarget)
        end
    end
    oWorldMgr:LoadRom(iPid,f)
end

function CHuodong:ClubArenaFight2(oPlayer,oRom,iClub,iPost,iTarget)
    local m = oRom:ClubArenaData()
    if not m or #m["partner"] < 1 then
        self:AutoSetRomInfo(oPlayer,oRom,iClub,iPost,iTarget)
    else
        self:ClubArenaFight3(oPlayer,iClub,iPost,iTarget)
    end
end


function CHuodong:AutoSetRomInfo(oPlayer,oRom,iClub,iPost,iTarget)
    self:SaveRom(oPlayer)
    local iPid = oPlayer:GetPid()
    local postlist = {}
    local mFightPartner = oPlayer.m_oPartnerCtrl:GetFightPartner()
    local mPartnerList = {}
    local iCnt = 1
    for iPos,oPartner in pairs(mFightPartner) do
        table.insert(mPartnerList,oPartner:ID())
        table.insert(postlist,iCnt)
        iCnt = iCnt + 1
    end
    self:SaveDefencePartner(oPlayer,postlist,mPartnerList)
    self:ClubArenaFight3(oPlayer,iClub,iPost,iTarget)
end

function CHuodong:ClubArenaFight3(oPlayer,iClub,iWhere,iTarget)
    local oNotifyMgr = global.oNotifyMgr
    local m = self:ValidEnerWar(oPlayer,iClub,iWhere,iTarget)
    if not m.ok then
        if m.reason then
            oNotifyMgr:Notify(oPlayer:GetPid(),m.reason)
        end
        return
    end
    local iPost = 0
    if m["data"] then
        iPost = m["data"]["post"]
    end
    if iPost == 0 and iClub ~= NEWBIE then
        local iCost = self:GetConfigValue("challenge_cost")
        if not oPlayer:ValidCoin(iCost) then
            return
        end
    end
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local callback = function (mRecord,mData)
        self:ClubArenaFight4(iPid,iClub,iPost,iWhere,m,mData.data)
    end
    self:LockWar(iPid,iClub,iPost,iTarget,callback)
end

function CHuodong:ClubArenaFight4(iPid,iClub,iPost,iWhere,mData,mResult)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oNotifyMgr = global.oNotifyMgr
    if not mResult.ok then
        local mErrCode = {
            [3] =   1022,
            [4] =   1021,
            [5] =   1023,
            [6] =   1024,
            }
        if mResult["war1"] then
            local sText = self:GetTextData(1019)
            oNotifyMgr:Notify(iPid,sText)
        elseif mResult["war2"] then
            local sText = self:GetTextData(1020)
            oNotifyMgr:Notify(iPid,sText)
        elseif mErrCode[mResult["err"]] then
            oNotifyMgr:Notify(iPid,self:GetTextData(mErrCode[mResult["err"]]))
        end
        return
    end

    local mInfo = mResult["info"]
    local iTarget = mInfo["pid"] or 0
    if not oPlayer then
        self:UnLockWar(iPid,iClub,iPost,iTarget)
        return
    end
    local m = self:ValidEnerWar(oPlayer,iClub,iWhere,iTarget)
    if not m.ok then
        self:UnLockWar(iPid,iClub,iPost,iTarget)
        return
    end

    if iPost == 0 and iClub ~= NEWBIE then
        local iCost = self:GetConfigValue("challenge_cost")
        if not oPlayer:ValidCoin(iCost) then
            self:UnLockWar(iPid,iClub,iPost,iTarget)
            oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1016))
            return
        end
        oPlayer:ResumeCoin(iCost,"challenge_cost")
    end

    local mFight = m["data"] or mInfo
    local oWar

    local mArgs  = {club = iClub ,post=iPost,mypost =  mResult["mypost"] ,target=mInfo["pid"],robot = mFight["robot"],myclub = mResult["myclub"],targetname = mFight["name"],where=iWhere}
    if mFight["robot"] then
        local mRobot = assert(self:RobotInfo(mFight["robot"]))
        oWar = self:StartRobotWar(oPlayer,mRobot,mInfo)
        oWar.m_ClubInfo = mArgs
    else
        self:StartRomWar(oPlayer,mInfo["pid"],mArgs)
    end
end

function CHuodong:ShowClubArenaHistory(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local f = function (oRom)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:ShowClubArenaHistory2(oPlayer,oRom)
        end
    end
    oWorldMgr:LoadRom(iPid,f)
end


function CHuodong:ShowClubArenaHistory2(oPlayer,oRom)
    local mInfo = {}
    local mRecord = oRom:Record()
    for i = #mRecord,1,-1 do
        table.insert(mInfo,mRecord[i])
    end
    oPlayer:Send("GS2CClubArenaHistory",{info=mInfo})
end

function CHuodong:OnWarEnd(oWar, iPid, oNpc, mArgs,bWin)
    local mClub = oWar.m_ClubInfo
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        record.warning("clubarena not onlineline1 "..iPid)
        return
    end
    local iWin =  (bWin  == true and 1) or 0
    local mArg = {
    player = {
        pid = iPid,
        data = {
        name = oPlayer:GetName(),
        org = oPlayer:GetOrgName(),
        power = oPlayer:GetPower(),
        model = oPlayer:GetModelInfo(),
        }
        },
        win = iWin,
        club = mClub["club"],
        post = mClub["post"],
        target = mClub["target"],
    }
    local f = function (mRecord,mData)
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:OnWarEnd2(oPlayer,mArgs,mClub,mData["data"],bWin)
        else
            record.warning("clubarena not onlineline2 "..iPid)
        end
    end
    self:SendAssist("OnWarEnd",mArg,f)
end

function CHuodong:OnWarEnd2(oPlayer,mArgs,mClub,mResult,bWin)
    local mShow = mArgs["show_end"]
    mShow["info1"]["club"] = mResult["club1"]
    mShow["info1"]["upordown"] = mResult["updown1"]
    mShow["info2"]["club"] = mResult["club2"]
    mShow["info2"]["upordown"] = mResult["updown2"]

    local mLog = {
        pid = oPlayer:GetPid(),
        name  = oPlayer:GetName(),
        club = mClub["myclub"],
        post = mClub["mypost"],

        target = mClub["target"],
        targetname = mClub["targetname"] or "errname",
        target_club = mClub["club"],
        target_post = mClub["post"],

        cur_club = mResult["club1"],
        cur_post = mResult["post1"],
        cur_target_club = mResult["club2"] or -1,
        cur_target_post = mResult["post2"] or -1,
        win = mArgs["win_side"],
        }
    record.user("clubarena","war_end",mLog)

    local mNet = {
        medal = 0,
        result = mArgs["win_side"],
        info1 = mShow["info1"],
        info2 = mShow["info2"],
        }

    local iPid = oPlayer:GetPid()
    local iClub = mClub["club"]
    local iNowClub = mResult["club1"]
    local iNowPost = mResult["post1"]
    local iPost = mClub["post"]
    local iTarget = mClub["target"]
    local iWhere = mClub["where"]
    if not (iPost == 0 and  iClub ~= NEWBIE ) then
        self:UsePlayTimes(oPlayer)
        oPlayer:AddSchedule("clubarena")
    end
    local mTodayClub = oPlayer.m_oToday:Query("clubarena_fight",{})
    if mTodayClub[iClub] then
        local m = mTodayClub[iClub][iWhere]
        if m then
            m["win"] = 1
        end
        oPlayer.m_oToday:Set("clubarena_fight",mTodayClub)
    end
    local mInfo = self:GetArenaData(oPlayer)
    if iClub ~= NEWBIE then
        if not mInfo[iClub] then
            mInfo[iClub] = {}
        end
        local mMyClub = mInfo[iClub]
        if bWin then
            if iPost == 0 then
                mMyClub["win"] = 0
            else
                mMyClub["win"] = math.min((mMyClub["win"] or 0) + 1 ,5)
            end
        else
            if iPost == 0 then
                mMyClub["win"] = 0
            end
        end
        self:SetArenaData(oPlayer,mInfo)
    end
    local mRewarInfo = self:GetRewardInfo(iNowClub)
    if not bWin then
        local iTime = self:GetConfigValue("warfalse_time")
        oPlayer.m_oThisTemp:Set("clubarena_cd",1,iTime)
        local rewardlist = mRewarInfo["fail_reward"]
        for _,iReward in pairs(rewardlist) do
            self:Reward(iPid,iReward)
        end
    else
        local rewardlist = mRewarInfo["win_rewad"]
        for _,iReward in pairs(rewardlist) do
            self:Reward(iPid,iReward)
        end
    end

    local mItem = self:GetKeep(oPlayer:GetPid(),"item",{})
    if mItem[1009] then
        mNet["medal"] = mItem[1009][1009]
    end
    oPlayer:Send("GS2CClubArenaFightResult",mNet)
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"武馆挑战",{value=1})
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"武馆挑战次数",{value=1})
    if iPost == 0 and iClub ~= NEWBIE and bWin then
        local mNowClub = self:GetRewardInfo(iClub)
        local sName = mNowClub["desc"]
        global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),string.format("成为%s馆主次数",sName),{value=1})
    end
    self:RecordData(oPlayer:GetPid(),iTarget,mArgs,mResult,mClub,bWin)

    self:UpdateInfo(oPlayer)
    local oTarget = global.oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oTarget then
        self:UpdateInfo(oTarget)
    end

end

----record----
function CHuodong:RecordData(iPid,iTarget,mWarInfo,mResult,mClub,bWin)
    local iTime = get_time()
    local iFilm = mWarInfo.war_film_id
    local mRecord = mWarInfo["record"]
    local m1 = mRecord[iTarget]

    m1["time"] = iTime
    m1["fid"] = iFilm
    m1["club"] = mResult["club1"]
    m1["updown"] = mResult["updown1"]
    if bWin then
        m1["win"] =1
        if mClub["post"] == 0 and mClub["club"] ~= NEWBIE then
            m1["master"] = 1
        end
    else
        m1["win"] = 0
    end
    self:RecordData2(iPid,m1)
    if iTarget ~= 0  then
        local m2 = mRecord[iPid]
        m2["time"] = iTime
        m2["fid"] = iFilm
        m2["club"] = mResult["club2"]
        m2["updown"] = mResult["updown2"]
        if bWin then
            m2["win"] = 0
        else
            m2["win"] = 1
        end
        self:RecordData2(iTarget,m2)
    end
end

function CHuodong:RecordData2(iPid,mInfo)
    local oWorldMgr = global.oWorldMgr
    local mPack = {

    }
    local f = function (oRom)
        oRom:AddRecord(mInfo,5)
    end
    oWorldMgr:LoadRom(iPid,f)
end

function CHuodong:ValidEnerWar(oPlayer,iClub,iWhere,iTarget)
    local iGrade = global.oWorldMgr:QueryControl("clubarena","open_grade")
    if oPlayer:GetGrade() < iGrade then
        return {ok=false}
    end
    if not oPlayer:IsSingle() then
        return {ok=false,reason=self:GetTextData(1005),}
    end
    if oPlayer:GetPid() == iTarget then
        return {ok=false}
    end
    if  oPlayer:GetNowWar() then
        return {ok=false,}
    end

    local mFight = oPlayer.m_oToday:Query("clubarena_fight",{})
    if not mFight[iClub] then
        return {ok=false,reason=self:GetTextData(1008),}
    end
    local mInfo = mFight[iClub][iWhere]
    if not mInfo and  iWhere ~= 0 then
        return {ok=false,reason=self:GetTextData(1008),}
    end
    local iPost = 0
    if mInfo then
        iPost = mInfo["post"]
    end
    if iPost == 0 and iClub ~= NEWBIE then
        local mData = self:GetArenaData(oPlayer)
        local info = mData[iClub] or {}

        if (info["win"] or 0) < self:GetConfigValue("challenge") then
            return {ok = false,reason = self:GetTextData(1010)}
        end
    end

    if iClub ~= NEWBIE and  iPost ~=0 and not mInfo then
        return {ok=false,reason=self:GetTextData(1009),}
    end
    if mInfo and mInfo["win"] then
        return {ok=false,reason=self:GetTextData(1012),}
    end

    if self:LeftPlayTimes(oPlayer) <= 0 and not (iPost == 0 and iClub ~= NEWBIE) then
        return {ok = false,reason = self:GetTextData(1006)}
    end

    if oPlayer.m_oThisTemp:Query("clubarena_cd") then
        return {ok=false,reason= self:GetTextData(1011)}
    end
    return {ok=true,data=mInfo}
end


function CHuodong:TestOP(oPlayer,iFlag,...)
    local args = {...}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    if iFlag == 100 then
        local show = [[
        101: fight target
    	]]
        oChatMgr:HandleMsgChat(oPlayer,show)
    elseif iFlag == 101 then
        self:StartRomWar(oPlayer,tonumber(args[1]))
    elseif iFlag == 102 then
        --self:SaveRom(oPlayer)
        local iPid = oPlayer:GetPid()
        local postlist = {1,2,3,4}
        local mFightPartner = oPlayer.m_oPartnerCtrl:GetFightPartner()

        for _,i in ipairs(postlist) do
            if not mFightPartner[i] then
                oPlayer.m_oPartnerCtrl:Forward("C2GSPartnerFight", iPid, {fight_info={pos=i,parid=i}})
            end
        end
        local mPartnerList = {}
        for iPos,oPartner in pairs(mFightPartner) do
            table.insert(mPartnerList,oPartner:ID())
        end
        self:SaveDefencePartner(oPlayer,postlist,mPartnerList)
    elseif iFlag == 103 then
        self:OpenClubUI(oPlayer,tonumber(args[1]))
    elseif iFlag == 104 then
        self:OpenMainUI(oPlayer)
    elseif iFlag == 105 then
        local mData = {post=tonumber(args[1]),club=tonumber(args[2])}
        self:ClubArenaFight(oPlayer,mData)
    elseif iFlag == 106 then
        local mArg = {
        player = {
            pid = oPlayer:GetPid(),
            data = {
            name = oPlayer:GetName(),
            org = oPlayer:GetOrgName(),
            power = oPlayer:GetPower(),
            model = oPlayer:GetModelInfo(),
            }
            },
        win = tonumber(args[1]),
        club = tonumber(args[2]),
        post = tonumber(args[3]),
        }
        self:SendAssist("OnWarEnd",mArg)
    elseif iFlag == 107 then
        local info = oPlayer.m_oToday:Query("clubarena_fight",{})
        print("Fight_Today:",info)
    elseif iFlag == 108 then
        local info = oPlayer.m_oToday:Query("clubarena_fight",{})
        local iClub =  tonumber(args[1])
        local iPost = tonumber(args[2])
        if not info[iClub] then
            return
        end
    elseif iFlag == 109 then
        local iClub = tonumber(args[1])
        local mInfo = self:GetArenaData(oPlayer)
        if not mInfo[iClub] then
            mInfo[iClub] = {}
        end
        local mMyClub = mInfo[iClub]
        mMyClub["win"] = 5
        self:SetArenaData(oPlayer,mInfo)
    elseif iFlag == 110 then
        print("ArenaData:",self:GetArenaData(oPlayer),oPlayer:GetModelInfo())
    elseif iFlag == 111 then
        self:NewHour(1,0)
    elseif iFlag == 112 then
        self:CleanCBTime(oPlayer)
    elseif iFlag == 901 then
        self:SendAssist("TestOP",{flag = iFlag,args=args })
    elseif iFlag == 902 then
        self:SendDayReward({2,oPlayer:GetPid()})
    elseif iFlag == 100001 then -- 机器人
        self:SaveRom(oPlayer)
        local parid = {1,2,3,4}
        self:SaveDefencePartner(oPlayer,parid,parid)
    elseif iFlag == 100002 then
        local mArg = {
                    pid = oPlayer:GetPid(),
                    data = {
                        name = oPlayer:GetName(),
                        org = oPlayer:GetOrgName(),
                        power = oPlayer:GetPower(),
                        model = oPlayer:GetModelInfo(),
                    },
            }
        self:SendAssist("TestOP",{flag = iFlag,args=args ,data=mArg})
    elseif iFlag == 100003 then
        self:SendAssist("TestOP",{flag = iFlag,args=args })
    end
end




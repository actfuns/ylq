--import module
local skynet = require "skynet"
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item/loaditem"))

local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "公会副本"
inherit(CHuodong, huodongbase.CHuodong)


function CHuodong:Init()
    self.m_FightOrgBoss = {}
    self.m_OrgBossMgr = {}
end

function CHuodong:BossData(iBoss)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["boss"][iBoss]
    assert(mData,string.format("err orgfuben",iBoss))
    return mData
end

function CHuodong:FubenData()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["fuben"]
    return mData
end

function CHuodong:NewHour(iWeekDay,iHour)
    if iHour == 3 then
        self:CheckRubbishOrg()
    end
end



function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    local mBossList = {}
    for iOrg,o in pairs(self.m_OrgBossMgr) do
        mBossList[iOrg] = o:Save()
    end
    mData["boss"] = mBossList
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    local mBossList = mData["boss"] or {}
    for iOrg,d in pairs(mBossList) do
        local obj = NewOrgHuodongMgr(iOrg)
        self.m_OrgBossMgr[iOrg] = obj
        obj:Load(d)
    end
end

function CHuodong:CheckRubbishOrg()
    local mKeyList = table_key_list(self.m_OrgBossMgr)
    interactive.Request(".org","common","CheckRubbishOrg",{orglist = mKeyList,},function(mRecord,mData)
        self:CleanRubbishOrg(mData["rubbish"])
    end)
end

function CHuodong:CleanRubbishOrg(mRubbish)
    if #mRubbish > 0 then
        self:Dirty()
    end
    for _,iOrg in ipairs(mRubbish) do
        local obj = self.m_OrgBossMgr[iOrg]
        if obj then
            self.m_OrgBossMgr[iOrg] = nil
            baseobj_safe_release(obj)
            record.user("orgfuben","rubbish_org",{org=iOrg})
        end
    end
end


function CHuodong:CheckReset()
    for iOrg,o in pairs(self.m_OrgBossMgr) do
        o:CheckReset()
    end
end

function CHuodong:OnDisconnected(oPlayer)
    local oWar = oPlayer:GetNowWar()
    if oWar and oWar.m_OrgInfo then
        local mInfo = oWar.m_OrgInfo
        self:SubFightBoss(mInfo["org"],mInfo["boss"],oPlayer:GetPid())
    end
end

function CHuodong:OnLogin(oPlayer,bReEnter)
    local oWar = oPlayer:GetNowWar()
    if oWar and oWar.m_OrgInfo then
        local mInfo = oWar.m_OrgInfo
        self:AddFightBoss(mInfo["org"],mInfo["boss"],oPlayer)
        local iOrg  = oPlayer:GetOrgID()
        if iOrg then
            local mNet =self:PackHpNotify(iOrg,mInfo["boss"])
            if mNet then
                oPlayer:Send("GS2COrgFBBossHpNotify",mNet)
            end
        end
    end
end

function CHuodong:OnLogout(oPlayer)
    local oWar = oPlayer:GetNowWar()
    if oWar and oWar.m_OrgInfo then
        local mInfo = oWar.m_OrgInfo
        self:SubFightBoss(mInfo["org"],mInfo["boss"],oPlayer:GetPid())
    end
end



function CHuodong:NewOrgBossMgr(iOrg)
    assert(not self.m_OrgBossMgr[iOrg],"err new org boss")
    local obj = NewOrgHuodongMgr(iOrg)
    self.m_OrgBossMgr[iOrg] = obj
    obj:CheckReset()
    return obj
end

function CHuodong:GetOrgBossMgr(iOrg)
    local obj = self.m_OrgBossMgr[iOrg]
    if not obj then
        obj = self:NewOrgBossMgr(iOrg)
    end
    return obj
end

function CHuodong:AddFightBoss(iOrg,iBoss,oPlayer)
    local iPid = oPlayer:GetPid()
    local mData = self.m_FightOrgBoss[iOrg]
    if not mData then
        mData = {
        fight = iBoss,
        last_per = 100,
        plist = {},
        }
        self.m_FightOrgBoss[iOrg] = mData
    end
    assert(mData["fight"] == iBoss,string.format("addrr err %d %d %d",iOrg,iBoss,mData["fight"]))
    if not table_in_list(mData["plist"],iPid) then
        table.insert(mData["plist"],iPid)
    end

    local mRole = {
        pid = iPid,
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = iPid,
        channel_list = {
            {gamedefines.BROADCAST_TYPE.ORG_FUBEN, iOrg, true},
        },
        info = mRole,
    })
end

function CHuodong:SubFightBoss(iOrg,iBoss,iPid)
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = iPid,
        channel_list = {
            {gamedefines.BROADCAST_TYPE.ORG_FUBEN, iOrg, false},
        },
        info = mBroadcastRole,
    })

    local mData = self.m_FightOrgBoss[iOrg]
    if  mData then
        extend.Array.remove(mData["plist"],iPid)
        if #mData["plist"] <= 0 then
            self.m_FightOrgBoss[iOrg] = nil
        end
    end
end

function CHuodong:PackHpNotify(iOrg,iBoss)
    local mData = self.m_FightOrgBoss[iOrg]
    if not mData then
        return
    end
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    if not oBossMgr then
        return
    end
    local mBoss = oBossMgr:GetBossInfo(iBoss)
    local mNet = {
        boss_id = iBoss,
        hp = mBoss["hp"],
        hp_max = mBoss["maxhp"],
        }
    return mNet
end

function CHuodong:BroadCastHpNotify(iOrg,iBoss)
    local mData = self.m_FightOrgBoss[iOrg]
    if not mData then
        return
    end
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    if not oBossMgr then
        return
    end
    local mBoss = oBossMgr:GetBossInfo(iBoss)
    local iPer = 100
    if mBoss["hp"] > 0 then
        iPer = math.max(math.floor(mBoss["hp"]/mBoss["maxhp"]*100),1)
    end
    if mData["last_per"] == iPer then
        return
    end
    mData["last_per"] = iPer
    local mNet = self:PackHpNotify(iOrg,iBoss)
    if not mNet then
        return
    end
    local mData = {
        message = "GS2COrgFBBossHpNotify",
        type = gamedefines.BROADCAST_TYPE.ORG_FUBEN,
        id = iOrg,
        data = mNet,
        exclude = {}
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end

function CHuodong:GetOrgFubenCnt(oPlayer)
    local iOrg = oPlayer:GetOrgID()
    if not iOrg then
        return 0
    end
    return self:GetConfigValue("play_times") - oPlayer.m_oToday:Query("org_fb",0)
end

function CHuodong:OpenMainUI(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local iOrg = oPlayer:GetOrgID()
    if iOrg == 0 then
        return
    end
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    if not oBossMgr then
        return
    end
    local oBosslist = oBossMgr:BossList()
    local iLeft = self:GetConfigValue("play_times") - oPlayer.m_oToday:Query("org_fb",0)
    local iFight = oBossMgr:NowFightBoss() or 0
    local mNetBoss = {}
    for _,m in ipairs(oBosslist) do
        local iPer = 0
        local iState = 2
        if m["hp"] > 0 then
            iPer = math.max(math.floor(m["hp"]/m["maxhp"]*100),1)
        else
            iState = 0
        end
        if iFight == m["id"] then
            iState = 1
        end

        local mPackBoss = {
            bid=m["id"],
            hp = iPer,
            status = iState,
            }
        table.insert(mNetBoss,mPackBoss)
    end
    local iCost = 0
    local iReset = oBossMgr:FreeReset()
    if iReset <= 0 then
        iCost = self:ResetCost(iOrg)
    end
    local mNet = {
    boss_list =mNetBoss,
    left = iLeft,
    rest = iReset,
    cost = iCost,
    }
    oPlayer:Send("GS2COrgFBBossList",mNet)
end

function CHuodong:EnterGame(oPlayer,iBoss)
    if not self:ValidEnterGame(oPlayer,iBoss) then
        return
    end
    local iOrg = oPlayer:GetOrgID()
    local iPid = oPlayer:GetPid()
    interactive.Request(".org","common","GetOrgSimpleInfo",{org=iOrg},function(mRecord,mData)
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:EnterGame2(oPlayer,iBoss,mData["data"])
        end
    end
        )
end


function CHuodong:EnterGame2(oPlayer,iBoss,mOrgData)
    local iLv = mOrgData["level"]
    if not iLv then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    --[[
    for iLevel,m in pairs(self:FubenData()) do
        if m["boss"] == iBoss and  iLv< iLevel then
            oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1014))
            return
        end
    end
    ]]
    local iRemoteAddr = oPlayer.m_oPartnerCtrl:GetRemoteAddr()
    interactive.Request(iRemoteAddr, "partner", "GetDayLimitFightPartner", {pid = oPlayer:GetPid(),key="orgfuben",fix=1}, function(mRecord, mData)
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(mData.pid)
        if oPlayer then
            local lPartner = oPlayer.m_oPartnerCtrl:NewPartnerList(mData.pid, mData.data)
            self:EnterGame3(oPlayer,iBoss, mOrgData,lPartner)
        end
    end
    )
end




function CHuodong:EnterGame3(oPlayer,iBoss,mOrgData,lPartner)
    if not self:ValidEnterGame(oPlayer,iBoss) then
        return
    end
    local iOrg = oPlayer:GetOrgID()
    local mFightOrg = self.m_FightOrgBoss[iOrg]
    if mFightOrg and mFightOrg["fight"] ~= iBoss then
        self.m_FightOrgBoss[iOrg] = nil
    end
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    local oWorldMgr = global.oWorldMgr
    local mEnterWarArg = {}
    local mFightPartner = lPartner
    mEnterWarArg.CurrentPartner = mFightPartner[1] or 1
    mEnterWarArg.FightPartner = mFightPartner
    local mBoss = self:BossData(iBoss)
    local mOrgBoss = oBossMgr:GetBossInfo(iBoss)
    self.m_mPartnerList = {}
    self.m_mPartnerList[oPlayer:GetPid()] =oPlayer.m_oToday:Query("orgfuben_partnerlist",{})
    self.m_TempOrgInfo = {org = oPlayer:GetOrgID(), boss = iBoss }
    for iLevel,m in pairs(self:FubenData()) do
        if m["boss"] == iBoss then
             self.m_TempBossLv = iLevel
        end
    end
    local oWar = self:CreateWar(oPlayer:GetPid(),nil,mBoss["fight"],{enter_arg=mEnterWarArg})
    self.m_TempOrgInfo = nil
    self.m_mPartnerList = nil
    self.m_TempBossLv = nil
    if oWar then
        oWar.m_FightType = mBoss["fight"]
        oWar.m_OrgInfo = {org = oPlayer:GetOrgID(), boss = iBoss }
        self:AddFightBoss(oPlayer:GetOrgID(),iBoss,oPlayer)
        local mLog = {
        pid = oPlayer:GetPid(),
        org = iOrg,
        boss  = iBoss,
        boss_hp = mOrgBoss["hp"],
        left = oPlayer.m_oToday:Query("org_fb",0),
        }
        record.user("orgfuben","join_war",mLog)
        oPlayer.m_oToday:Add("org_fb",1)
        local mNet =self:PackHpNotify(iOrg,iBoss)
        if mNet then
            oPlayer:Send("GS2COrgFBBossHpNotify",mNet)
        end

        oPlayer:PropChange("org_fuben_cnt")
        interactive.Send(".org","common","SetOrgMemberData",{
            pid = oPlayer:GetPid(),
            key = "fb_boss",
            val = get_time(),
            })


    end
end

function CHuodong:ValidEnterGame(oPlayer,iBoss)
    local oNotifyMgr = global.oNotifyMgr
    local iOrg = oPlayer:GetOrgID()
    if not iOrg then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1002))
        return false
    elseif oPlayer.m_oToday:Query("org_fb",0) >= self:GetConfigValue("play_times") then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1003))
        return false
    elseif oPlayer:GetNowWar() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1004))
        return false
    elseif not oPlayer:IsSingle() then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1005))
        return false
    end
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    local mBoss = oBossMgr:GetBossInfo(iBoss)
    local iNow = oBossMgr:NowFightBoss()

    if not mBoss or mBoss["hp"] == 0 then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1006))
        return false
    elseif not iNow or iNow ~= iBoss then
        
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1007))
        return false
    end
    return true
end

function CHuodong:GetCreateWarArg(mArg)
    mArg.war_type = gamedefines.WAR_TYPE.ORG_FUBEN
    mArg.remote_war_type = "orgfuben"
    return mArg
end

function CHuodong:GetRemoteWarArg()
    local mArg = {
    org=self.m_TempOrgInfo["org"],
    boss=self.m_TempOrgInfo["boss"],
    use_parlist = self.m_mPartnerList  or {}
    }
    return mArg
end



function CHuodong:CreateMonster(oWar,iMonsterIdx,npcobj, mArgs)
    local oMonster = super(CHuodong).CreateMonster(self,oWar,iMonsterIdx,npcobj, mArgs)
    local mExtra = oMonster:GetAttr("extra_data") or {}
    mExtra["Org"] = self.m_TempOrgInfo["org"]
    mExtra["OrgBoss"] = self.m_TempOrgInfo["boss"]
    oMonster:SetAttr("extra_data",mExtra)
    if iMonsterIdx < 20000 then
        local oBossMgr = self:GetOrgBossMgr(self.m_TempOrgInfo["org"])
        local mOrgBoss = oBossMgr:GetBossInfo(self.m_TempOrgInfo["boss"])
        oMonster:SetAttr("hp", mOrgBoss["hp"])
        oMonster:SetAttr("maxhp", mOrgBoss["maxhp"])
    end
    return oMonster
end


function CHuodong:GetServant(oWar,mArgs)
    local  mMonsterList = {20001,20002,20003,20004}
    local mServant = {}
    for _,iMonsterIdx in ipairs(mMonsterList) do
        local oMonster = self:CreateMonster(oWar,iMonsterIdx,nil, mArgs)
        mServant[iMonsterIdx] = oMonster:PackAttr()
    end
    return mServant
end



function CHuodong:TransMonsterAble(oWar,sAttr,mArgs)
    mArgs = mArgs or {}
    local sValue = mArgs.value
    local mEnv = mArgs.env
    mEnv.bosslv = self.m_TempBossLv or 1
    local iValue = formula_string(sValue,mEnv)
    return iValue
end


function CHuodong:OnWarEnd(oWar, iPid, oNpc, mArgs,bWin)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mOrgInfo = oWar.m_OrgInfo
    self:SubFightBoss(mOrgInfo["org"],mOrgInfo["boss"],iPid)
    local iBoss = mOrgInfo["boss"]
    if oPlayer then
        local sPart = self:AddPartner(oPlayer,mArgs.world)
        local iHit = mArgs.bosshit
        local mLog = {
        pid = oPlayer:GetPid(),
        partlist = sPart,
        org = mOrgInfo["org"],
        hit = iHit,
        left  = oPlayer.m_oToday:Query("org_fb",0),
        boss = mOrgInfo["boss"],
        }
        record.user("orgfuben","war_end",mLog)
        oPlayer:AddSchedule("orgfuben")
        oPlayer:Send("GS2COrgFuBenWarEnd",{boss_hit=iHit})
        local iFight = oWar.m_FightType
        local mFight = self:GetTollGateData(iFight)
        local mReward = mFight["rewardtbl"] or {}
        for _,m in ipairs(mReward) do
            self:Reward(oPlayer:GetPid(),m["rewardid"])
        end
        global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"挑战公会赏金",{value=1})
        self:GiveOrgReward(oPlayer,iBoss,iHit)
        self:LogAnalyGame("orgfuben",oPlayer)
    else
        record.error(string.format("orgfuben offline %d",iPid))
    end
    super(CHuodong).OnWarEnd(self,oWar, iPid, oNpc, mArgs,bWin)

end

function CHuodong:GiveOrgReward(oPlayer,iBoss,iHit)
    local mBossData = self:BossData(iBoss)
    local iTotalReward = mBossData["total_offer"]
    local iMinimum = mBossData["minimum_offer"]
    local iLevel
    for iLv,m in pairs(self:FubenData()) do
        if m["boss"] == iBoss then
            iLevel = iLv
            break
        end
    end
    if not iLevel then
        record.error("GiveOrgReward error:"..iBoss)
        return
    end
    local iHp = self:GetBossHP(iBoss,iLevel)
    local iRate = iHit/iHp
    local iReward = math.max(iMinimum,math.floor(iRate*iTotalReward))
    iReward = math.min(iReward,iTotalReward)
    oPlayer:RewardOrgOffer(iReward,"工会赏金伤害奖励")
end

function CHuodong:AddPartner(oPlayer,mFightPartner)
    local mPar1 = mFightPartner[oPlayer:GetPid()] or {}
    local mDayPartnerList = oPlayer.m_oToday:Query("orgfuben_partnerlist",{})
    local parlist = {}
    local sParter = ""
    for parid, mArgs in pairs(mPar1) do
        table.insert(parlist,parid)
        if not extend.Array.member(mDayPartnerList,parid) then
            table.insert(mDayPartnerList,parid)
            sParter = sParter..string.format("[%d,%s,%d]",parid,mArgs.name,mArgs.shape)
        end
    end
    oPlayer.m_oToday:Set("orgfuben_partnerlist",mDayPartnerList)
    local iRemoteAddr = oPlayer.m_oPartnerCtrl:GetRemoteAddr()
     interactive.Send(iRemoteAddr,"partner","RecordDayLimitPartner",{pid=oPlayer:GetPid(),partner=parlist,key="orgfuben"})
     return string.format("[%s]",sParter)
end



function CHuodong:OnHpChange(iHit,iOrg,iBossType)
    local oWarMgr = global.oWarMgr
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    local mBoss = oBossMgr:GetBossInfo(iBossType)
    if mBoss["hp"] == 0 then
        return
    end
    local iLv = 1
    for iLevel,m in pairs(self:FubenData()) do
        if m["boss"] == iBoss then
            iLv = iLevel
            break
        end
    end

    local oBossMgr = self:GetOrgBossMgr(iOrg)
    local bDead = oBossMgr:BossSubHp(iBossType,iHit)
    self:BroadCastHpNotify(iOrg,iBossType)
    if  bDead then
        local mData ={org =iOrg,boss = iBossType }
        for _,v in pairs(oWarMgr.m_lWarRemote) do
            interactive.Send(v,"orgfuben","BossDie",mData)
        end
        interactive.Request(".org","common","GetOrgMemberData",{org=iOrg},function(mRecord,mData)
            self:RewardOrgMember({org=iOrg,type=iBossType},mData["data"])
        end
            )
    end
end

function CHuodong:RewardOrgMember(mBossInfo,mOrgMember)
    local iOrg = mBossInfo["org"]
    local iBossType = mBossInfo["type"]
    local mDaoBiao = self:BossData(iBossType)
    local oOrgMgr = global.oOrgMgr

    local mReward = mDaoBiao["kill_reward"]
    local oMailMgr = global.oMailMgr
    local info = oMailMgr:GetMailInfo(18)
    info.context = string.format(info.context, mDaoBiao["name"])
    local iWeek = get_weekno()
    local plist = {}
    local sPlist = ""
    local sMsg= string.format("第%d层的【%s】已经被击杀",iBossType//1000,mDaoBiao["name"])

--    oOrgMgr:SendMsg2Org(sMsg,iOrg)
    if mReward and #mReward > 0 then
        for pid,m in pairs(mOrgMember) do
            local iTime = m["fb_boss"]
            if iTime and get_weekno(iTime) == iWeek then
                table.insert(plist,pid)
                sPlist = sPlist..string.format("%d,",pid)
            end
        end
    end
    self:RewardOrgCoin(iOrg, mDaoBiao["org_reward"], string.format("击杀公会boss:%s", mDaoBiao["name"]))
    self.m_FightOrgBoss[iOrg] = nil
    local mLog = {
    org = iOrg,
    boss = iBossType,
    reward_list = sPlist,
    }
    record.user("orgfuben","boss_die",mLog)
    for _,pid in pairs(plist) do
        self:SendAchieve(pid,string.format("击杀公会第%s层BOSS次数",iLv),{value=1})
        self:RewardListByMail(pid,mReward,{mailinfo=info})
    end
end

function CHuodong:RewardOrgCoin(iOrg, mReward, sReason)
    -- local sReason = "击杀公会boss"
    local mShape = {
        [1015] = true,
        [1019] = true,
        [1026] = true,
    }
    mReward = mReward or {}
    for _, m in pairs(mReward) do
        local oItem = loaditem.ExtCreate(m.sid)
        oItem:SetAmount(m.amount)
        local iShape = oItem:SID()
        if mShape[iShape] then
            oItem:Reward(nil, sReason, {orgid = iOrg})
        else
            record.warning("RewardOrgCoin, sid:%s not exsit", iShape)
        end
    end
end


function CHuodong:SendAchieve(pid,sKey,mArg)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        global.oAchieveMgr:PushAchieve(pid,sKey,mArg)
    else
        oWorldMgr:LoadPrivy(pid, function (oPrivy)
            oPrivy:AddFunc("PushAchieve",{sKey,mArg})
        end)

    end
end


function CHuodong:BossList2String(bosslist)
    local sPirnt = ""
    for idx,mBoss in ipairs(bosslist) do
        sPirnt = sPirnt..string.format("[%s,%s,%s],",idx,mBoss["id"],mBoss["hp"])
    end
    return string.format("[%s]",sPirnt)
end


function CHuodong:RestOrgFuBen(oPlayer)
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local iOrg = oPlayer:GetOrgID()
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    if oBossMgr:FreeReset() ~= 0 then
        local sContent = self:GetTextData(1012)
        local mNet1 = {
            sContent = sContent,
            uitype = 0,
            sConfirm = "确定",
            sCancle = "取消",
            default = 0,
            time = 30,
        }
        mNet1 = oCbMgr:PackConfirmData(nil, mNet1)
        local func = function (oResponse,mData)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer and mData.answer ==1 then
                self:TrueRestOrgFuBen(oPlayer,false)
            end
        end
        oCbMgr:SetCallBack(oPlayer:GetPid(),"GS2CConfirmUI",mNet1,nil,func)
    else
        local sContent = self:GetTextData(1013)
        local oBossMgr = self:GetOrgBossMgr(iOrg)
        local iCnt = math.min(15,oBossMgr:GetData("reset_count",15))

        local res = require "base.res"
        local mCost = res["daobiao"]["huodong"][self.m_sName]["cost_fuben"]
        local iCost = mCost[iCnt]["use"]
        sContent = string.gsub(sContent,"$COST",iCost)
        local mNet1 = {
            sContent = sContent,
            uitype = 0,
            sConfirm = "确定",
            sCancle = "取消",
            default = 0,
            time = 30,
        }
        mNet1 = oCbMgr:PackConfirmData(nil, mNet1)
        local func = function (oResponse,mData)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer and mData.answer ==1 then
                self:TrueRestOrgFuBen(oPlayer,true)
            end
        end
        oCbMgr:SetCallBack(oPlayer:GetPid(),"GS2CConfirmUI",mNet1,nil,func)
    end

end

function CHuodong:ResetCost(iOrg)
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    local iCnt = math.min(15,oBossMgr:GetData("reset_count",15))
    local res = require "base.res"
    local mCost = res["daobiao"]["huodong"][self.m_sName]["cost_fuben"]
    local iCost = mCost[iCnt]["use"]
    return iCost
end

function CHuodong:TrueRestOrgFuBen(oPlayer,bCost)
    local iOrg = oPlayer:GetOrgID()
    if iOrg == 0 then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local iCost = 0
    local iPid = oPlayer:GetPid()
    if bCost then
        iCost = self:ResetCost(iOrg)
    end
    if not self:ValidResetOrgFuBen(oPlayer,iCost) then
        return
    end
    interactive.Request(".org","common","ResetOrgFuBen",{org=iOrg,pid=iPid,cost=iCost},function(mRecord,mData)
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:TrueRestOrgFuBen2(oPlayer,iOrg,iCost,mData["data"])
        end
    end
        )
end




function CHuodong:TrueRestOrgFuBen2(oPlayer,iOrg,iCost,mData)
    local iCode = mData["code"]
    local oNotifyMgr = global.oNotifyMgr
    if iCode > 0 then
            local mCode = {[3]=1008,[4]=1011}
            if mCode[iCode] then
                oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(mCode[iCode]))
            end
        return
    end

    local  iPost = mData["pos"]
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    local sBefor = self:BossList2String(oBossMgr:BossList())
    local mLog = {
    pid = oPlayer:GetPid(),
    org = iOrg,
    boss_info = oBossMgr:NowFightBoss(),
    post = iPost,
    cost = iCost,
    use = oBossMgr:GetData("reset_count",0),
    }
    
    safe_call(oBossMgr.ResetFuBen,oBossMgr,true)
    local sAfter = self:BossList2String(oBossMgr:BossList())
    mLog.boss_reset = sAfter
    record.user("orgfuben","reset",mLog)
    oNotifyMgr:Notify(oPlayer:GetPid(),"重置完成")
    self:OpenMainUI(oPlayer)
end



function CHuodong:ValidResetOrgFuBen(oPlayer,iCost)
    local iOrg = oPlayer:GetOrgID()
    local oNotifyMgr = global.oNotifyMgr
    if iOrg == 0 then
        return false
    end

    local iPid = oPlayer:GetPid()
    local oBossMgr = self:GetOrgBossMgr(iOrg)
    local iLeft = oBossMgr:FreeReset()
    local mData = self.m_FightOrgBoss[iOrg]
    if mData and #mData["plist"] > 0 then
         oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1010))
        return false
    end

    if not iCost or iCost == 0 and  iLeft <= 0 then
        oNotifyMgr:Notify(oPlayer:GetPid(),"免费重置次数不足")
        return false
    end
    return true
end




function CHuodong:GetBossHP(iBoss,iLevel)
    local mBoss = self:BossData(iBoss)
    local iFight = mBoss["fight"]
    local mFight = self:GetTollGateData(iFight)
    local mMonster
    for _,mMonsterData in pairs(mFight["monster"]) do
        local iMonsterIdx = mMonsterData["monsterid"]
        local m = self:GetMonsterData(iMonsterIdx)
        if m["boss"] == 1 then
            mMonster = m
        end
    end
    local mEnv = {
            bosslv = iLevel
        }
    return formula_string(mMonster["maxhp"], mEnv)
end

function CHuodong:GetOrgFubenCnt(oPlayer)
    return self:GetConfigValue("play_times") - oPlayer.m_oToday:Query("org_fb",0)
end

function CHuodong:TestOP(oPlayer,iFlag,...)
    local args = {...}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    if iFlag == 100 then
        oChatMgr:HandleMsgChat(oPlayer,"101-消灭当前的BOSS")
    elseif iFlag == 101 then
        local iOrg = oPlayer:GetOrgID()
        local oBossMgr = self:GetOrgBossMgr(iOrg)
        local iBoss = oBossMgr:NowFightBoss()
        local mBoss = oBossMgr:GetBossInfo(iBoss)
        self:OnHpChange(mBoss["hp"] - 1,iOrg,iBoss)
        oNotifyMgr:Notify(oPlayer:GetPid(),"已击杀")
    elseif iFlag == 102 then
        self:OpenMainUI(oPlayer)
    elseif iFlag == 103 then
        local iOrg = oPlayer:GetOrgID()
        local oBossMgr = self:GetOrgBossMgr(iOrg)
        oBossMgr:TruePromoteLevel()
    elseif iFlag == 104 then
        local iOrg = oPlayer:GetOrgID()
        local oBossMgr = self:GetOrgBossMgr(iOrg)
        oBossMgr:ResetFuBen()
    elseif iFlag == 105 then
        self:RestOrgFuBen(oPlayer)
    elseif iFlag == 106 then
        local iOrg = oPlayer:GetOrgID()
        local oBossMgr = self:GetOrgBossMgr(iOrg)
        oBossMgr:Dirty()
        self:DoSave()
    elseif iFlag == 107 then
        local oMailMgr = global.oMailMgr
        local mDaoBiao = self:BossData(1001)
        local mReward = mDaoBiao["kill_reward"]
        local info = oMailMgr:GetMailInfo(18)
        self:RewardListByMail(oPlayer:GetPid(),mReward,{mailinfo=info})
    elseif iFlag == 108 then
        local iBoss = tonumber(args[1])
        self:OnHpChange(21000000,oPlayer:GetOrgID(),iBoss)
    elseif iFlag == 999 then
        self:NewOrgBossMgr(9)
        self:NewHour(1,3)
    end
end


COrgHuodongMgr = {}
COrgHuodongMgr.__index = COrgHuodongMgr
inherit(COrgHuodongMgr, datactrl.CDataCtrl)


function NewOrgHuodongMgr(orgid)
    return COrgHuodongMgr:New(orgid)
end

function COrgHuodongMgr:New(orgid)
    local o = super(COrgHuodongMgr).New(self)
    o.m_ID = orgid
    o.m_BossList = {}
    o.m_ResetTime = 0
    return o
end

function COrgHuodongMgr:Dirty()
    super(COrgHuodongMgr).Dirty(self)
    local oHuodong = global.oHuodongMgr:GetHuodong("orgfuben")
    oHuodong:Dirty()
end

function COrgHuodongMgr:Save()
    local mData = {}
    mData.bosslist = self.m_BossList
    mData.reset = self.m_ResetTime
    mData.count =  self:GetData("reset_count",0)
    return mData
end

function COrgHuodongMgr:Load(mData)
    mData = mData or {}
    self.m_BossList = mData["bosslist"] or self.m_BossList
    self.m_ResetTime = mData["reset"] or self.m_ResetTime
    self:SetData("reset_count",mData["count"] or 0)
end

function COrgHuodongMgr:SetBossList(bosslist)
    self.m_BossList  = bosslist
    self:Dirty()
end


function COrgHuodongMgr:BossSubHp(iBoss,iHp)
    for idx,mBoss in ipairs(self:BossList()) do
        if mBoss["id"] == iBoss then
            mBoss["hp"] = math.max(0,mBoss["hp"] - iHp )
            self:Dirty()
            if mBoss["hp"] == 0 then
                return true
            end
        end
    end
    return false
end



function COrgHuodongMgr:GetBossInfo(iBoss)
    for idx,mBoss in ipairs(self:BossList()) do
        if mBoss["id"] == iBoss then
            return mBoss
        end
    end
end

function COrgHuodongMgr:BossList()
    return self.m_BossList
end

function COrgHuodongMgr:NowFightBoss()
    for idx,mBoss in ipairs(self:BossList()) do
        if mBoss["hp"] ~= 0 then
            return mBoss["id"]
        end
    end
end

function COrgHuodongMgr:GetOrg()
    local oOrgMgr = global.oOrgMgr
    return oOrgMgr:GetNormalOrg(self.m_ID)
end


function COrgHuodongMgr:ResetFuBen(bSet)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("orgfuben")
    local mBossList = {}
    for iLevel,m in pairs(oHuodong:FubenData()) do
        local iBoss = m["boss"]
        local iMaxHP = oHuodong:GetBossHP(iBoss,iLevel)
        local mInfo = {
            hp = iMaxHP,
            id = iBoss,
            maxhp = iMaxHP,
            }
        table.insert(mBossList,mInfo)
    end

    self.m_BossList = mBossList
    local iWeek = get_weekno(self.m_ResetTime)
    local iNow = get_weekno()
    local iCount = self:GetData("reset_count",0)
    if iWeek ~= iNow  then
        iCount = 0
    end
    if bSet then
        self.m_ResetTime = get_time()
        iCount = iCount + 1
        self:SetData("reset_count",iCount)
    end
    self:Dirty()
end


function COrgHuodongMgr:CheckReset()
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("orgfuben")
    if #self:BossList() == 0 then
        self:ResetFuBen()
    end
end


function COrgHuodongMgr:FreeReset(oPlayer)
    local iWeek = get_weekno(self.m_ResetTime)
    local iNow = get_weekno()
    if iNow > iWeek then
        return 1
    end
    return 0
end


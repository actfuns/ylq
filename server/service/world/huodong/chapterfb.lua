-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"
local record = require "public.record"

local loaditem = import(service_path("item/loaditem"))
local gamedefines = import(lualib_path("public.gamedefines"))
local analy = import(lualib_path("public.dataanaly"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "chapterfb"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
end

function CHuodong:GetBaseData(iChapter,iLevel,iType)
    local mData = res["daobiao"]["huodong"][self.m_sName]["config"]
    local sKey = self:GetChapterKey(iChapter,iLevel)
    assert(mData[sKey],"GetBaseData faild:"..self.m_sName.."    "..iChapter.."    ",iLevel)
    for _,info in pairs(mData[sKey]) do
        if info["type"] == iType then
            return info
        end
    end
    --record.error(string.format("miss chapter config:%d-%d-%d",iChapter,iLevel,iType))
end

function CHuodong:GetTransText(iText)
    local sText = self:GetTextData(iText)
    return sText
end

function CHuodong:CoinIcon(iType)
    local mCoinInfo = gamedefines.COIN_TYPE[iType]
    assert(mCoinInfo,string.format("MaxCoin %d",iType))
    return mCoinInfo.icon or mCoinInfo.name
end

function CHuodong:FightChapterFb(oPlayer,iChapter,iLevel,iType)
    -- body
    if oPlayer:HasTeam() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,self:GetTransText(1003))
        return
    end
    if oPlayer:GetNowWar() then
        return
    end
    local mBaseData = self:GetBaseData(iChapter,iLevel,iType)

    local mOpenCondition = mBaseData["open_condition"]
    local bOpen = oPlayer.m_oHuodongCtrl:CheckChapterOpen(iChapter,iLevel,iType)
    if not bOpen then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,self:GetTransText(1002))
        return
    end
    local iMaxFightTime = mBaseData["fight_time"] or 0
    local iDoneTime = oPlayer.m_oHuodongCtrl:GetChapterFbFightTime(iChapter,iLevel,iType)
    if iMaxFightTime <= iDoneTime then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,self:GetTransText(1001))
        return
    end
    local iNeedEnergy = mBaseData["energy_cost"]
    if not oPlayer:ValidEnergy(iNeedEnergy,{cancel_tip = true}) then
        return
    end

    local iFightIdx = mBaseData["fightid"]
    self:Fight(oPlayer.m_iPid,nil,iFightIdx,iChapter,iLevel,iType)
    local iStar = oPlayer.m_oHuodongCtrl:GetChapterPassStar(iChapter,iLevel,iType)
    self:AddBackGoundLog(oPlayer,iChapter,iLevel,iType,(iStar == 0) and 1 or 2,0,1,iStar)
end

function CHuodong:Fight(iPid,oNpc,iFightIdx,iChapter,iLevel,iType)
    self:AddKeep(iPid,"fight_info",{starttime = get_time(),chapter = iChapter,level=iLevel,type = iType})
    super(CHuodong).Fight(self,iPid,oNpc,iFightIdx)
    record.user("chapterfb","chellange",{pid = iPid,chapter = iChapter,level = iLevel,type = iType})
end

function CHuodong:CreateWar(pid,npcobj,iFight,mInfo)
    mInfo = mInfo or {}
    self.m_FirstGiude = nil
    self.m_SetAutoCmd = nil
    local mFight = self:GetKeep(pid,"fight_info")
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer and not oPlayer.m_oActiveCtrl:HasGuideKey(2002099) then
        self.m_SetAutoCmd = 1
    end
    if mFight then
        if mFight["type"] == 1 then
            if mFight["chapter"] == 1 and mFight["level"] == 1 then
                mInfo["war_type"] = 10001
                if oPlayer and not oPlayer.m_oActiveCtrl:HasGuideKey(2001099) then
                    self.m_FirstGiude = 1
                end
            elseif mFight["chapter"] == 1 and mFight["level"] == 2 then
                mInfo["war_type"] = 10004
            elseif mFight["chapter"] == 1 and mFight["level"] == 3 then
                mInfo["war_type"] = 10003
            else
                mInfo["war_type"] = gamedefines.WAR_TYPE.CHAPTERFB_TYPE
            end
        else
            mInfo["war_type"] = gamedefines.WAR_TYPE.CHAPTERFB_TYPE
        end
    end
    mInfo["remote_war_type"] = "chapterfb"
    return super(CHuodong).CreateWar(self,pid,npcobj,iFight,mInfo)
end

function CHuodong:OnDisconnected(oPlayer)
    local mList = {10001,10004}
    local mFight = self:GetKeep(oPlayer:GetPid(),"fight_info")
    if mFight then
        if mFight["type"] == 1 and mFight["chapter"] == 1 and (mFight["level"] == 1 or mFight["level"] == 2) then
            local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
            if oWar and (oWar.m_iWarType == 10001 or oWar.m_iWarType == 10004)then
                local mArgs = {
                    war_result = 2
                }
                oWar:TestCmd("warend",oPlayer:GetPid(),mArgs)
            end
        end
    end
end

function CHuodong:GetCreateWarArg(mArg)
    if self.m_FirstGiude then
        mArg["remote_args"]["FirstGuide"] = 1
    end
    if self.m_SetAutoCmd then
        mArg["remote_args"]["SetAutoCmd"] = 1
    end
    return mArg
end

function CHuodong:_Reward1(iFight,pid,iChapter,iLevel,iType,mArgs)
    local mFightData = self:GetTollGateData(iFight)
    local mReward = mFightData["rewardtbl"]
    mArgs = mArgs or {}
    mArgs["reason"] = string.format("章节难度%d副本%d-%d固定奖励",iType,iChapter,iLevel)
    for i = 1,#mReward do
        self:Reward(pid,mReward[i]["rewardid"],mArgs)
    end
end

function CHuodong:_Reward2(oWar,pid,iChapter,iLevel,iType)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
    local bHasPass = oPlayer.m_oHuodongCtrl:HasPassChapter(iChapter,iLevel,iType)
    local mStableReward,mRandomReward = self:GivePassReward(oPlayer,iChapter,iLevel,iType)
    local mFirstPassReward = {}
    if not bHasPass then
        mFirstPassReward = self:GiveFirstPassReward(oPlayer,iChapter,iLevel,iType)
    end
    return mFirstPassReward,mStableReward,mRandomReward
end

function CHuodong:BuildItemList(mReward)
    local mItem = {}
    for _,info in pairs(mReward) do
        local sShape = info["sid"]
        local iAmount = info["amount"]
        for iNo=1,100 do
            local oItem = loaditem.ExtCreate(sShape)
            local iAddAmount = math.min(oItem:GetMaxAmount(),iAmount)
            iAmount = iAmount - iAddAmount
            oItem:SetAmount(iAddAmount)
            table.insert(mItem,oItem)
            if iAmount <= 0 then
                break
            end
        end
    end
    return mItem
end

function CHuodong:GiveReward(oPlayer,mReward,sReason,mArgs)
    local mItem = self:BuildItemList(mReward)
    local mLogItem = {}
    for _,oItem in pairs(mItem) do
        table.insert(mLogItem,oItem:LogInfo())
        oPlayer:RewardItem(oItem,sReason,mArgs)
    end
end

function CHuodong:GivePassReward(oPlayer,iChapter,iLevel,iType)
    local mData = self:GetBaseData(iChapter,iLevel,iType)
    local mReward = mData["pass_reward"]
    local mStableReward = {}
    local mRandomReward  ={}
    local bHasPass = oPlayer.m_oHuodongCtrl:HasPassChapter(iChapter,iLevel,iType)
    for _,reward in pairs(mReward) do
        local iRate = reward["rate"]
        local oItem = loaditem.GetItem(reward["sid"])
        local mShow = oItem:GetShowInfo()
        mShow["amount"] = reward["amount"]
        if iRate == 100 then
            table.insert(mStableReward,mShow)
        else
            if not bHasPass and oItem:ItemType() == "partnerchip" then
                table.insert(mStableReward,mShow)
            else
                if math.random(100) <= iRate then
                    table.insert(mRandomReward,mShow)
                end
            end
        end
    end
    self:GiveReward(oPlayer,mStableReward,string.format("难度%d章节副本%d-%d固定奖励",iType,iChapter,iLevel))
    self:GiveReward(oPlayer,mRandomReward,string.format("难度%d章节副本%d-%d随机奖励",iType,iChapter,iLevel))
    return mStableReward,mRandomReward
end

function CHuodong:GiveFirstPassReward(oPlayer,iChapter,iLevel,iType)
    local mData = self:GetBaseData(iChapter,iLevel,iType)
    local mReward = mData["first_reward"]
    local m = {}
    for _,reward in pairs(mReward) do
        local oItem = loaditem.GetItem(reward["sid"])
        local mShow = oItem:GetShowInfo()
        mShow["amount"] = reward["amount"]
        table.insert(m,mShow)
    end
    local sReason = string.format("难度%d章节副本%d-%d首次通关奖励",iType,iChapter,iLevel)
    self:GiveReward(oPlayer,m,sReason)
    return m
end

function CHuodong:OnWarFail(oWar, iPid, npcobj, mArgs)
    super(CHuodong).OnWarFail(self,oWar, iPid, npcobj, mArgs)
    self.m_PopRewardUIFirst = false
    local mFight = self:GetKeep(iPid,"fight_info")
    local iChapter = mFight["chapter"]
    local iLevel = mFight["level"]
    local iType = mFight["type"]
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mBaseData = self:GetBaseData(iChapter,iLevel,iType)
    local iNeedEnergy = mBaseData["energy_cost"]
    oPlayer:ResumeEnergy(iNeedEnergy/2,"挑战副本失败:"..self:GetChapterKey(iChapter,iLevel),{cancel_tip = true,cancel_channel = true})
    record.user("chapterfb","failed",{pid = iPid,chapter = iChapter,level = iLevel,type = iType})
    local iStar = oPlayer.m_oHuodongCtrl:GetChapterPassStar(iChapter,iLevel,iType)
    self:AddBackGoundLog(oPlayer,iChapter,iLevel,iType,(iStar == 0) and 1 or 2,2,1,iStar)
end

function CHuodong:OnWarWin(oWar, iPid, npcobj, mArgs)
    super(CHuodong).OnWarWin(self,oWar,iPid,npcobj,mArgs)
    self.m_PopRewardUIFirst = true
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    global.oAchieveMgr:PushAchieve(iPid,"战役中通关关卡次数",{value=1})
    local mFight = self:GetKeep(iPid,"fight_info")
    self:AddKeep(iPid,"fight_info",nil)
    assert(mFight,"chapterfb OnWarWin faild:"..oWar.m_FightIdx)
    local iChapter = mFight["chapter"]
    local iLevel = mFight["level"]
    local iType = mFight["type"]
    local mBaseData = self:GetBaseData(iChapter,iLevel,iType)
    local iNeedEnergy = mBaseData["energy_cost"]
    oPlayer:ResumeEnergy(iNeedEnergy,string.format("挑战副本难度%d胜利:%s",iType,self:GetChapterKey(iChapter,iLevel)),{cancel_tip = true,cancel_channel = true})
    local bHasPass = oPlayer.m_oHuodongCtrl:HasPassChapter(iChapter,iLevel,iType)

    self:_Reward1(oWar.m_FightIdx,iPid,iChapter,iLevel,iType,mArgs)
    local mFirstPassReward,mStableReward,mRandomReward = self:_Reward2(oWar,iPid,iChapter,iLevel,iType)
    local iHasDead = mArgs.m_HasDead
    local iBout = mArgs["bout"]
    local iEndTime = get_time()
    local iStartTime = mFight["starttime"]
    local iFightTime = math.floor((iEndTime - iStartTime)/60)
    local mParam = {win=true,bout=iBout,fight_time = iFightTime,has_dead = iHasDead}
    local iStar,mCondition = self:CheckStarCondition(iChapter,iLevel,iType,mParam)

    local iGainExp = self:GetKeep(iPid,"exp",0)
    local bOverGrade = false
    if iGainExp == 0 then
        bOverGrade = true
    end
    local iLimitGrade = oWorldMgr:GetMaxPlayerGrade()
    local iOldGrade = self:GetKeep(iPid,"old_grade") or oPlayer:GetGrade()
    local iCurExp = math.max(oPlayer:GetExp() - iGainExp,0)
    local mPlayerExp = {limit_grade = iLimitGrade,grade = iOldGrade,exp = iCurExp,gain_exp = iGainExp,is_over_grade = bOverGrade}
    local mPartnerExp = {}
    local mAddExp = self:GetKeep(iPid,"partner_exp",{})
    local mPartner = self:GetFightPartner(oPlayer, mArgs)
    for iParId,mInfo in pairs(mPartner) do
        local iPartnerExp = mAddExp[iParId]
        local iGrade = mInfo.grade
        local iExp = mInfo.exp
        local iLimitGrade = iOldGrade + 5
        table.insert(mPartnerExp,{parid = iParId,gain_exp = iPartnerExp,exp = iExp,grade = iGrade,limit_grade = iLimitGrade})
    end
    local iCoin = self:GetKeep(iPid, "coin", 0)
    local mNet = {
        war_id = oWar:GetWarId(),
        player_exp = mPlayerExp,
        partner_exp = mPartnerExp,
        firstpass_reward = mFirstPassReward,
        stable_reward = mStableReward,
        random_reward = mRandomReward,
        win = 1,
        star = iStar,
        coin = iCoin,
        condition = mCondition,
    }
    oPlayer:AddSchedule("chapterfb")
    oPlayer.m_oHuodongCtrl:SetChapterStar(iChapter,iLevel,iType,iStar,mCondition)
    oPlayer.m_oHuodongCtrl:AddChapterFbFightTime(iChapter,iLevel,iType,1)
    local fFunc = function(player,mData)
        local oHuodong = global.oHuodongMgr:GetHuodong("chapterfb")
        oHuodong:OnWarWin2(iPid,mNet,mData.data)
    end
    oPlayer.m_oItemCtrl:GetShowItem(fFunc)
    record.user("chapterfb","win",{pid = iPid,chapter = iChapter,level = iLevel,type = iType,star = iStar,reward = "firstpass_reward:"..ConvertTblToStr(mFirstPassReward or {}).."    stable_reward:"..ConvertTblToStr(mStableReward or {}).."   random_reward:"..ConvertTblToStr(mRandomReward or {})})

    self:AddBackGoundLog(oPlayer,iChapter,iLevel,iType,bHasPass and 2 or 1,1,1,iStar)
end

function CHuodong:OnWarWin2(iPid,mNet,mKeepItem)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        mNet["firstpass_reward"] = self:SetRewardItemId(mNet["firstpass_reward"],mKeepItem)
        mNet["stable_reward"] = self:SetRewardItemId(mNet["stable_reward"],mKeepItem)
        mNet["random_reward"] = self:SetRewardItemId(mNet["random_reward"],mKeepItem)
        oPlayer:Send("GS2CChapterFbWinUI",mNet)
    end
end

function CHuodong:CheckStarCondition(iChapter,iLevel,iType,mArgs)
    -- body
    local mBaseData = self:GetBaseData(iChapter,iLevel,iType)
    local mStarCondition = mBaseData["star_condition"]
    local iStar = 0
    local mResult = {}
    for i=1,3 do
        local sCondition = mStarCondition[i]
        local bReach = false
        if sCondition == "战斗胜利" then
            bReach = mArgs.win
        elseif sCondition == "己方无阵亡单位" then
            bReach = not mArgs.has_dead or mArgs.has_dead == 0
        elseif string.find(sCondition,"分钟内通关") then
            local iIndex = string.find(sCondition,"分钟内通关")
            local iMin = tonumber(string.sub(sCondition,1,iIndex-1))
            bReach = iMin >= (mArgs.fight_time or 0)
        elseif string.find(sCondition,"回合内胜利") then
            local iIndex = string.find(sCondition,"回合内胜利")
            local iBout = tonumber(string.sub(sCondition,1,iIndex-1))
            bReach = iBout >= (mArgs.bout or 0)
        elseif string.find(sCondition,"阵亡伙伴不超过") then
            local _,iNum = string.match(sCondition,"([^0-9]+)(%d+)(.+)")
            local iNum = tonumber(iNum)
            bReach = not mArgs.has_dead or mArgs.has_dead <= iNum
        end
        if bReach then
            iStar = iStar + 1
        end
        table.insert(mResult,{condition = sCondition,reach=bReach and 1 or 0})
    end
    return iStar,mResult
end

function CHuodong:CoinIcon(iType)
    local mCoinInfo = gamedefines.COIN_TYPE[iType]
    assert(mCoinInfo,string.format("MaxCoin %d",iType))
    return mCoinInfo.icon or mCoinInfo.name
end

function CHuodong:SweepChapterFb(oPlayer,iChapter,iLevel,iType,iCount)
    -- body
    if oPlayer:GetNowWar() then
        return
    end
    local bValid,iMsgCode = oPlayer.m_oHuodongCtrl:ValidSweepChapterFb(iChapter,iLevel,iType,iCount)
    if not bValid then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,self:GetTransText(iMsgCode))
        return
    end
    local mBaseData = self:GetBaseData(iChapter,iLevel,iType)
    local iEnergyCost = mBaseData["energy_cost"] * iCount
    local iSweepCost = mBaseData["sweep_cost"] * iCount
    if not oPlayer:ValidEnergy(iEnergyCost,{cancel_tip = true}) then
        return
    end
    local iSweepItemAmount = oPlayer:GetItemAmount(10030)
    if iSweepItemAmount < iSweepCost then
        local mItemData = loaditem.GetItemData(10030)
        local iBuyPrice = mItemData["buy_price"]
        local iTotalCost = (iSweepCost - iSweepItemAmount) * iBuyPrice
        self:_SweepChapterFb2(oPlayer,iChapter,iLevel,iType,iCount,iSweepItemAmount,iTotalCost)
    else
        self:_SweepChapterFb3(oPlayer,iChapter,iLevel,iType,iCount,iSweepCost)
    end
end

function CHuodong:_SweepChapterFb2(oPlayer,iChapter,iLevel,iType,iCount,iSweepItemAmount,iTotalCost)
    if not oPlayer:ValidGoldCoin(iTotalCost) then
        return
    end
    oPlayer:ResumeGoldCoin(iTotalCost,"购买扫荡券")
    self:_SweepChapterFb3(oPlayer,iChapter,iLevel,iType,iCount,iSweepItemAmount)
end

function CHuodong:_SweepChapterFb3(oPlayer,iChapter,iLevel,iType,iCount,iUseItem)
    if iUseItem > 0 then
        local iPid = oPlayer.m_iPid
        local func = function()
            local oHuodong = global.oHuodongMgr:GetHuodong("chapterfb")
            local oPlayerObj = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
            oHuodong:_TrueSweepChapterFb(oPlayerObj,iChapter,iLevel,iType,iCount)
        end
        oPlayer:RemoveItemAmount(10030,iUseItem,"扫荡副本",{},func)
    else
        self:_TrueSweepChapterFb(oPlayer,iChapter,iLevel,iType,iCount)
    end
end

function CHuodong:_TrueSweepChapterFb(oPlayer,iChapter,iLevel,iType,iCount)
    local iPid = oPlayer.m_iPid
    global.oAchieveMgr:PushAchieve(iPid,"战役中通关关卡次数",{value=iCount})
    local mBaseData = self:GetBaseData(iChapter,iLevel,iType)
    local iNeedEnergy = mBaseData["energy_cost"] * iCount
    oPlayer:ResumeEnergy(iNeedEnergy,"扫荡副本:"..self:GetChapterKey(iChapter,iLevel),{cancel_tip = true,cancel_channel = true})
    local mSweepReward = {}
    local sKey = self:GetChapterKey(iChapter,iLevel)
    local iFight = mBaseData["fightid"]
    local mArgs = {}
    mArgs.fight_partner = oPlayer.m_oPartnerCtrl:PackFightPartnerInfo()
    mArgs.cancel_tip = true
    for i = 1,iCount do
        oPlayer:AddSchedule("chapterfb")
        self:_Reward1(iFight,iPid,iChapter,iLevel,iType,mArgs)
        local iGainExp = self:GetKeep(iPid,"exp",0)
        local bOverGrade = false
        if iGainExp == 0 then
            bOverGrade = true
        end
        local iLimitGrade = global.oWorldMgr:GetMaxPlayerGrade()
        local iOldGrade = self:GetKeep(iPid,"old_grade") or oPlayer:GetGrade()
        local iCurExp = math.max(oPlayer:GetExp() - iGainExp,0)
        local mPlayerExp = {limit_grade = iLimitGrade,grade = iOldGrade,exp = iCurExp,gain_exp = iGainExp,is_over_grade=bOverGrade}
        local mPartnerExp = {}
        local mAddExp = self:GetKeep(iPid,"partner_exp",{})
        local mPartner = oPlayer.m_oPartnerCtrl:PackFightPartnerInfo()
        for iParId,mInfo in pairs(mPartner) do
            local iPartnerExp = mAddExp[iParId]
            local iGrade = mInfo.grade
            local iExp = mInfo.exp
            local iLimitGrade = iOldGrade + 5
            table.insert(mPartnerExp,{parid = iParId,gain_exp = iPartnerExp,exp = iExp,grade = iGrade,limit_grade = iLimitGrade})
        end
        local iCoin = self:GetKeep(iPid, "coin", 0)
        local mStableReward,mRandomReward = self:GivePassReward(oPlayer,iChapter,iLevel,iType)
        local mReward = {
            player_exp = mPlayerExp,
            partner_exp = mPartnerExp,
            stable_reward = mStableReward,
            random_reward = mRandomReward,
            coin = iCoin,
            sweep_time = i,
        }
        table.insert(mSweepReward,mReward)
        self:ClearKeep(iPid)
    end
    local fFunc = function(player,mData)
        local oHuodong = global.oHuodongMgr:GetHuodong("chapterfb")
        oHuodong:_TrueSweepChapterFb2(iPid,mSweepReward,iChapter,iLevel,iType,iCount,mData.data)
    end
    oPlayer.m_oItemCtrl:GetShowItem(fFunc)
    record.user("chapterfb","sweep",{pid = iPid,chapter = iChapter,level = iLevel,type = iType,times = iCount,reward = "stable_reward:"..ConvertTblToStr(mStableReward or {}).."   random_reward:"..ConvertTblToStr(mRandomReward or {})})
end

function CHuodong:SetRewardItemId(mReward,mShow)
    for _,m in pairs(mReward) do
        for iIndex,tmp in pairs(mShow) do
            if m["sid"] == tmp["virtual"] then
                m["sid"] = tmp["sid"]
                m["id"] = tmp["id"]
                m["virtual"] = tmp["virtual"]
                table.remove(mShow,iIndex)
                break
            end
        end
    end
    return mReward
end

function CHuodong:_TrueSweepChapterFb2(iPid,mSweepReward,iChapter,iLevel,iType,iCount,mKeepItem)
    for iSweepTime,info in pairs(mSweepReward) do
        info["random_reward"] = self:SetRewardItemId(info["random_reward"],mKeepItem)
        info["stable_reward"] = self:SetRewardItemId(info["stable_reward"],mKeepItem)
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    oPlayer:Send("GS2CSweepChapterReward",{reward = mSweepReward,chapter = iChapter,level = iLevel,type = iType})
    oPlayer.m_oHuodongCtrl:AddChapterFbFightTime(iChapter,iLevel,iType,iCount)
    local iStar = oPlayer.m_oHuodongCtrl:GetChapterPassStar(iChapter,iLevel,iType)
    self:AddBackGoundLog(oPlayer,iChapter,iLevel,iType,3,1,iCount,iStar)
end

function CHuodong:GetFightPartner(oPlayer,mArgs)
    local mPartnerInfo = {}
    if mArgs and mArgs.fight_partner then
        mPartnerInfo = mArgs.fight_partner[oPlayer:GetPid()] or oPlayer.m_oPartnerCtrl:PackFightPartnerInfo()
    end
    return mPartnerInfo
end

function CHuodong:GetMaxEnergyBuyTime()
    local sValue = res["daobiao"]["global"]["buyenergy_maxtime"]["value"]
    return tonumber(sValue)
end

function CHuodong:GetBuyEnergyCost()
    local sValue = res["daobiao"]["global"]["buyenergy_cost"]["value"]
    return tonumber(sValue)
end

function CHuodong:GetBuyEnergyValue()
    local sValue = res["daobiao"]["global"]["buyenergy_cost"]["value"]
    return tonumber(sValue)
end

function CHuodong:GetStarReward(oPlayer,iChapter,iType,iIndex)
    local bValid,iMsg = oPlayer.m_oHuodongCtrl:VaildGetStarReward(iChapter,iType,iIndex)
    if not bValid then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,self:GetTransText(iMsg))
        return
    end
    oPlayer.m_oHuodongCtrl:GetStarReward(iChapter,iType,iIndex)
    local mData = res["daobiao"]["huodong"][self.m_sName]["starreward"][iChapter][iIndex][iType]
    local mReward = mData["star_reward"]
    self:GiveReward(oPlayer,mReward,"星级奖励",{cancel_tip = true})
    global.oUIMgr:ShowKeepItem(oPlayer.m_iPid)
    local sKey = string.format("领取第%d章第%d个宝箱",iChapter,iIndex)
    global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,sKey,{value=1})
    record.user("chapterfb","star_reward",{pid = oPlayer.m_iPid,chapter = iChapter,type = iType,index = iIndex,reward = ConvertTblToStr(mReward or {})})
end

function CHuodong:GetExtraReward(oPlayer,iChapter,iLevel,iType)
    local bValid,iMsg = oPlayer.m_oHuodongCtrl:VaildGetExtraReward(iChapter,iLevel,iType)
    if not bValid then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,self:GetTransText(iMsg))
        return
    end
    if not oPlayer.m_oHuodongCtrl:GetExtraReward(iChapter,iLevel,iType) then
        return
    end
    local mBaseData = self:GetBaseData(iChapter,iLevel,iType)
    local mReward = mBaseData["extra_reward"]
    self:GiveReward(oPlayer,mReward,"星级奖励",{cancel_tip = true})
    global.oUIMgr:ShowKeepItem(oPlayer.m_iPid)
    record.user("chapterfb","extra_reward",{pid = oPlayer.m_iPid,chapter = iChapter,level = iLevel,type = iType,reward = ConvertTblToStr(mReward or {})})
end

function CHuodong:GetChapterKey(iChapter,iLevel)
    return iChapter.."-"..iLevel
end

function CHuodong:AddBackGoundLog(oPlayer,iChapter,iLevel,iType,iOperate,iResult,iTimes,iStar)
    local sKey = self:GetChapterKey(iChapter,iLevel)
    local mLog = oPlayer:GetPubAnalyData()
    mLog["level"] = sKey
    mLog["operation"] = iOperate
    mLog["war_result"] = iResult
    mLog["times"] = iTimes
    mLog["star"] = iStar
    mLog["type"] = iType
    analy.log_data("chapterfb",mLog)
end

function CHuodong:ConfigWar(oWar,pid,npcobj,iFight, mInfo)
    local mFight = self:GetKeep(pid,"fight_info")
    local iChapter = mFight["chapter"]
    local iLevel = mFight["level"]
    local iType = mFight["type"]
    if iChapter == 1 and iLevel == 2 and iType == 1 then
        mInfo["enter_arg"] = mInfo["enter_arg"] or {}
        mInfo["enter_arg"]["skill_ratio"] = {}
        mInfo["enter_arg"]["skill_ratio"][30202] = 10000
    end
end
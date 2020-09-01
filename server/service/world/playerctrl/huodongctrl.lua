local global = require "global"
local extend = require "base/extend"
local res = require "base.res"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local playboynpc = import(service_path("huodong/npcobj/playboynpcobj"))
local legendboynpc = import(service_path("huodong/npcobj/legendboynpcobj"))
local trapminenpc = import(service_path("huodong/npcobj/trapminenpcobj"))

local TRAIN_REWARD_TIMES = 10
local REWARD_TIMES = 10
local TRAIN_MAX_TIMES = 50

local TYPE2KEY = {
    [1] = "normal",
}

local mCreateNpcFunc= {
    ["playboynpc"] = playboynpc.NewClientNpc,
    ["legendboynpc"] = legendboynpc.NewClientNpc,
    ["trapmine"] = trapminenpc.NewClientNpc,
}

CHuodongCtrl = {}
CHuodongCtrl.__index = CHuodongCtrl
inherit(CHuodongCtrl, datactrl.CDataCtrl)

function CHuodongCtrl:New(pid)
    local o = super(CHuodongCtrl).New(self, {pid = pid})
    o.m_ID = pid
    o.m_mData = {}
    o.m_mChapterFB = {}
    o.m_mTraining = {}
    o.m_iHuntID = 0
    o.m_mHirePartner = {}
    o.m_mChargeScoreInfo = {}
    o.m_mTimeLimitResume = {}
    o.m_mResumeRestore = {}
    return o
end

function CHuodongCtrl:Load(data)
    data = data or {}
    self.m_mGame = data["game"] or {}
    self:SetData("EquipFBData",data["equipfb"] or {})
    self:SetData("shop",data["shop"] or {})
    self:SetData("PEFuBen",data["pe_fb"] or {})
    self:SetData("ComChat",data["chat"] or {})
    self:SetData("EqualArena",data["e_arena"] or {})
    self:SetData("RewardBack",data["rback"] or {})
    self:SetData("ClubArena",data["club"] or {})
    self.m_mClientNpc = {}
    local mClient = data["clientnpc"] or {}
    for key,tbl in pairs(mClient) do
        self.m_mClientNpc[key] = self.m_mClientNpc[key] or {}
        for index,m in ipairs(tbl) do
            local oClientNpc = mCreateNpcFunc[key](m)
            self.m_mClientNpc[key][oClientNpc:ID()] = oClientNpc
        end
    end
    self.m_mChapterFB = data["chapterfb"] or {}
    if self.m_mChapterFB["normal"] then
        self.m_mChapterFB[1] = self.m_mChapterFB["normal"]
        self.m_mChapterFB["normal"] = nil
    end
    self.m_mConvoyInfo = data["convoyinfo"] or {}
    self.m_mTraining = data["training"] or {}
    self.m_mHirePartner = data["hirepartner"] or {}
    self.m_mHuntInfo = data["huntinfo"] or {}
    self.m_iHuntID = data["huntid"] or 0
    self.m_mChargeScoreInfo = data["chargescore_info"] or {}
    self.m_mTimeLimitResume = data["timelimit_resume"] or {}
    self.m_mResumeRestore = data["resume_restore"] or {}
end

function CHuodongCtrl:Save()
    local data = {}
    local mClientNpc = {}
    for key,tbl in pairs(self.m_mClientNpc) do
        mClientNpc[key] = {}
        for index,npcobj in pairs(tbl) do
            table.insert(mClientNpc[key],npcobj:Save())
        end
    end
    data["clientnpc"] = mClientNpc
    data["equipfb"] = self:GetData("EquipFBData",{})
    data["shop"] = self:GetData("shop",{})
    data["game"] = self.m_mGame
    data["pe_fb"] = self:GetData("PEFuBen",{})
    data["chat"] = self:GetData("ComChat",{})
    data["e_arena"] = self:GetData("EqualArena",{})
    data["rback"] = self:GetData("RewardBack",{})
    data["club"] = self:GetData("ClubArena",{})
    data["chapterfb"] = self.m_mChapterFB or {}
    data["convoyinfo"] = self.m_mConvoyInfo or {}
    data["training"] = self.m_mTraining or {}
    data["hirepartner"] = self.m_mHirePartner or {}
    data["huntinfo"] = self.m_mHuntInfo or {}
    data["huntid"] = self.m_iHuntID or 0
    data["chargescore_info"]  = self.m_mChargeScoreInfo or {}
    data["timelimit_resume"] = self.m_mTimeLimitResume or {}
    data["resume_restore"] = self.m_mResumeRestore or {}
    return data
end

function CHuodongCtrl:GetPlayer()
    return global.oWorldMgr:GetOnlinePlayerByPid(self.m_ID)
end

function CHuodongCtrl:OnLogin(oPlayer,bReEnter)
    for key,tbl in pairs(self.m_mClientNpc) do
        for index,npcobj in pairs(tbl) do
            if npcobj:CheckTimeOut() then
                self:Dirty()
                self.m_mClientNpc[key][index] = nil
                self:RemoveNpcSession(npcobj.m_ID)
                baseobj_delay_release(npcobj)
            else
                npcobj:CountDown()
            end
        end
    end
    local mClientData = {}
    for sName,m in pairs(self.m_mClientNpc) do
        for _,oClientNpc in pairs(m) do
            table.insert(mClientData,oClientNpc:PackInfo())
        end
    end
    local mConvoyInfo = self:PackConvoyInfo()
    oPlayer:Send("GS2CLoginHuodongInfo",{npcinfo = mClientData,convoyinfo = mConvoyInfo,dailytrain = self:PackTrainInfo(),huntinfo = self:PackHuntInfo(),hireinfo = self:PackHireInfo()})
    local mChapterFbInfo = self:PackChapterFbLoginInfo()
    oPlayer:Send("GS2CLoginChapterInfo",mChapterFbInfo)
    if self:CheckConvoyDailyReset() then
        self:ConvoyDailyReset()
    end
    self:CheckTrainOfflineRewardTime(oPlayer)
    self:CheckNextLevelOpen(nil,nil,2)
end

function CHuodongCtrl:OnUpGrade(iGrade)
    self:CheckNextLevelOpen(nil,nil,1)
    self:CheckNextLevelOpen(nil,nil,2)
    self:CheckTrainOpen(iGrade)
    self:CheckHuntOpen(iGrade)
end

function CHuodongCtrl:OnFinishStoryTask()
    self:CheckNextLevelOpen(nil,nil,1)
end

function CHuodongCtrl:RemoveClientNpc(sType,iID,sReason)
    self:Dirty()
    local oPlayer = self:GetPlayer()
    local npcobj = self:GetNpcByID(sType, iID)
    assert(npcobj,string.format("not npcobj,%s,%s",sType,iID))
    local mNet = {}
    mNet["npcid"] = npcobj.m_ID
    mNet["flag"] = npcobj.m_iTrapMine or 0
    self.m_mClientNpc[sType][iID] = nil
    self:RemoveNpcSession(npcobj.m_ID)
    local npcid = npcobj.m_ID
    local oNpcMgr = global.oNpcMgr
    oNpcMgr:RemoveObject(npcid)
    baseobj_delay_release(npcobj)
    oPlayer:Send("GS2CRemoveHuodongNpc",mNet)
end

function CHuodongCtrl:AddClientNpc(sName,npcobj)
    self:Dirty()
    self.m_mClientNpc = self.m_mClientNpc or {}
    self.m_mClientNpc[sName] = self.m_mClientNpc[sName] or {}
   self.m_mClientNpc[sName][npcobj:ID()] = npcobj
end

function CHuodongCtrl:CheckHasClient(sName,iID)
    for _,n in pairs(self.m_mClientNpc[sName]) do
        if n.m_ID == iID then
            return true
        end
    end
    return false
end

function CHuodongCtrl:GetNpcByType(sName)
    return self.m_mClientNpc[sName] or {}
end

function CHuodongCtrl:GetNpcByID(sName, iID)
    local mNpc = self.m_mClientNpc[sName] or {}
    return mNpc[iID]
end

function CHuodongCtrl:AddNpcSessionId(iID,iSessionIdx)
    self.m_SessionIdx = self.m_SessionIdx or {}
    self.m_SessionIdx[iID] = iSessionIdx
end

function CHuodongCtrl:RemoveNpcSession(iID)
    if not self.m_SessionIdx or not self.m_SessionIdx[iID] then
        return
    end
    local oCbMgr = global.oCbMgr
    oCbMgr:RemoveCallBack(self.m_SessionIdx[iID])
end

function CHuodongCtrl:AddGame(sGame)
    if self.m_mGame[sGame] then
        return
    end
    self:Dirty()
    self.m_mGame[sGame] = true
end

function CHuodongCtrl:RemoveGame(sGame)
    if not self.m_mGame[sGame] then
        return
    end
    self:Dirty()
    self.m_mGame[sGame] = nil
end

function CHuodongCtrl:HasGame(sGame)
    return self.m_mGame[sGame]
end

function CHuodongCtrl:GetChapterFbFightTime(iChapter,iLevel,iType)
    local sKey = "fight_time:"..self:GetChapterKey(iChapter,iLevel,iType)
    local oPlayer = self:GetPlayer()
    return oPlayer.m_oToday:Query(sKey,0)
end

function CHuodongCtrl:AddChapterFbFightTime(iChapter,iLevel,iType,iAdd)
    local sKey = "fight_time:"..self:GetChapterKey(iChapter,iLevel,iType)
    local oPlayer = self:GetPlayer()
    local iCurTime = oPlayer.m_oToday:Query(sKey,0)
    iCurTime = iCurTime + iAdd
    oPlayer.m_oToday:Set(sKey,iCurTime)
    self:UpdateClientChapter(iChapter,iLevel,iType)
end

function CHuodongCtrl:GetChapterBaseData(iChapter,iLevel,iType)
    local mData = res["daobiao"]["huodong"]["chapterfb"]["config"]
    local sKey = self:GetChapterKey(iChapter,iLevel)
    if mData[sKey] then
        for _,info in pairs(mData[sKey]) do
            if info["type"] == iType then
                return info
            end
        end
    end
    return
    --record.error(string.format("miss chapter config:%d-%d-%d",iChapter,iLevel,iType))
end

function CHuodongCtrl:HasPassChapter(iChapter,iLevel,iType)
    local sKey = self:GetChapterKey(iChapter,iLevel)
    if self.m_mChapterFB[iType] and self.m_mChapterFB[iType][sKey] and self.m_mChapterFB[iType][sKey]["pass"] and self.m_mChapterFB[iType][sKey]["pass"] == 1 then
        return true
    end
    return false
end

function CHuodongCtrl:CheckChapterOpen(iChapter,iLevel,iType)
    local sKey = self:GetChapterKey(iChapter,iLevel)
    if self.m_mChapterFB[iType] and self.m_mChapterFB[iType][sKey] and self.m_mChapterFB[iType][sKey]["open"] then
        return true
    end
    local mChapterData = self:GetChapterBaseData(iChapter,iLevel,iType)
    if not mChapterData then
        return false
    end
    local mOpenCondition = mChapterData["open_condition"] or {}
    for _,sCondition in pairs(mOpenCondition) do
        if not self:CheckChapterCondition(sCondition,iType) then
            return false
        end
    end
    self:ChapterOpen(iChapter,iLevel,iType)
    return true
end

function CHuodongCtrl:ChapterOpen(iChapter,iLevel,iType)
    self:Dirty()
    local sKey = self:GetChapterKey(iChapter,iLevel)
    if not self.m_mChapterFB[iType] then
        self.m_mChapterFB[iType] = {}
    end
    if not self.m_mChapterFB[iType][sKey] then
        self.m_mChapterFB[iType][sKey] = {}
    end
    self.m_mChapterFB[iType][sKey]["open"] = 1
    self.m_mChapterFB[iType]["finalchapter"] = {chapter = iChapter,level = iLevel,open = 1,type = iType}
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CChapterOpen",{chapter = iChapter,level = iLevel,type = iType})

end

function CHuodongCtrl:CheckChapterCondition(sCondition,iType)
    local m = split_string(sCondition,"=")
    local sTarget = m[1]
    local sValue = m[2]
    assert(sValue,"CheckChapterCondition failed:"..sTarget)
    if sTarget == "通关" then
        local tmp = split_string(sValue,"-")
        local iChapter,iLevel = tonumber(tmp[1]),tonumber(tmp[2])
        return self:CheckChapterPass(iChapter,iLevel,1)
    elseif sTarget == "通关困难关卡" then
        local tmp = split_string(sValue,"-")
        local iChapter,iLevel = tonumber(tmp[1]),tonumber(tmp[2])
        return self:CheckChapterPass(iChapter,iLevel,2)
    elseif sTarget == "等级" then
        local iGrade = tonumber(sValue)
        local oPlayer = self:GetPlayer()
        return oPlayer:GetGrade() >= iGrade
    elseif sTarget == "完成剧情任务" then
        local iTaskId = tonumber(sValue)
        local oPlayer = self:GetPlayer()
        return oPlayer.m_oTaskCtrl:GetCurStoryTaskId() > iTaskId
    elseif string.find(sTarget,"星通关困难关卡") then
        local tmp = split_string(sValue,"-")
        local iChapter,iLevel = tonumber(tmp[1]),tonumber(tmp[2])
        local i,j = string.find(sTarget,"星通关困难关卡")
        local iStar = tonumber(string.sub(sTarget,1,i-1))
        assert(iStar,"CheckChapterCondition failed:"..sTarget)
        return iStar <= self:GetChapterPassStar(iChapter,iLevel,iType)
    elseif string.find(sTarget,"星通关") then
        local tmp = split_string(sValue,"-")
        local iChapter,iLevel = tonumber(tmp[1]),tonumber(tmp[2])
        local i,j = string.find(sTarget,"星通关")
        local iStar = tonumber(string.sub(sTarget,1,i-1))
        assert(iStar,"CheckChapterCondition failed:"..sTarget)
        return iStar <= self:GetChapterPassStar(iChapter,iLevel,iType)
    end
end

function CHuodongCtrl:GetChapterPassStar(iChapter,iLevel,iType)
    local sKey = self:GetChapterKey(iChapter,iLevel)
    if not self.m_mChapterFB[iType] or not self.m_mChapterFB[iType][sKey] or not self.m_mChapterFB[iType][sKey]["pass"] then
        return 0
    end
    return self.m_mChapterFB[iType][sKey]["star"] or 0
end

function CHuodongCtrl:CheckChapterPass(iChapter,iLevel,iType)
    local sKey = self:GetChapterKey(iChapter,iLevel)
    if self.m_mChapterFB[iType] and self.m_mChapterFB[iType][sKey] and self.m_mChapterFB[iType][sKey]["pass"] then
        return true
    end
    return false
end

function CHuodongCtrl:ChapterLevelPass(iChapter,iLevel,iType)
    self:Dirty()
    local sKey = self:GetChapterKey(iChapter,iLevel)
    assert(self.m_mChapterFB[iType][sKey],"ChapterLevelPass failed:"..sKey)
    self.m_mChapterFB[iType][sKey]["pass"] = 1
    if self.m_mChapterFB[iType] and self.m_mChapterFB[iType]["finalchapter"] and self.m_mChapterFB[iType]["finalchapter"]["chapter"] == iChapter and self.m_mChapterFB[iType]["finalchapter"]["level"] == iLevel then
        self.m_mChapterFB[iType]["finalchapter"]["pass"] = 1
    end
    global.oAchieveMgr:PushAchieve(self.m_ID,string.format("通关战役%d-%d",iChapter,iLevel),{value = 1})
    if iLevel == 8 then
        global.oAchieveMgr:PushAchieve(self.m_ID,"通过战役章节数",{value=1})
    end
    self:CheckChapterExtraReward(iChapter,iLevel,iType)
    self:CheckNextLevelOpen(iChapter,iLevel,iType)
    if iType == 1 then
        self:CheckNextLevelOpen(nil,nil,2)
    end
end

function CHuodongCtrl:SetChapterStar(iChapter,iLevel,iType,iStar,mCondition)
    local sKey = self:GetChapterKey(iChapter,iLevel)
    local oPlayer = self:GetPlayer()
    assert(self.m_mChapterFB[iType][sKey],"SetChapterStar faild:pid"..self.m_ID.."  chapter:"..sKey)
    local bUpdateClient = false

    if not self.m_mChapterFB[iType][sKey]["pass"] then
        self:Dirty()
        self:ChapterLevelPass(iChapter,iLevel,iType)
        bUpdateClient = true
    end

    local iOldStar = self.m_mChapterFB[iType][sKey]["star"] or 0
    if iOldStar <= iStar and iOldStar ~= 3 then
        self:Dirty()
        self.m_mChapterFB[iType][sKey]["star"] = iStar
        self.m_mChapterFB[iType][sKey]["star_condition"] = mCondition
        bUpdateClient = true
    end
    if iStar - iOldStar > 0 then
        global.oAchieveMgr:PushAchieve(self.m_ID,"战役中获得星星数量",{value=(iStar - iOldStar)})
    end
    if bUpdateClient then
        self:ChapterTotalStarChange(iChapter,iType,iOldStar,iStar)
        self:UpdateClientChapter(iChapter,iLevel,iType)
    end
end

function CHuodongCtrl:ChapterTotalStarChange(iChapter,iType,iOldStar,iNewStar)
    self:Dirty()
    self.m_mChapterFB[iType]["total_star"] = self.m_mChapterFB[iType]["total_star"] or {}
    if not self.m_mChapterFB[iType]["total_star"][iChapter] then
        self.m_mChapterFB[iType]["total_star"][iChapter] = {star = iNewStar,reward_status = 0}
    else
        self.m_mChapterFB[iType]["total_star"][iChapter]["star"] = (self.m_mChapterFB[iType]["total_star"][iChapter]["star"] or 0) + (iNewStar - iOldStar)
    end
    self:UpdateTotalStar(iChapter,iType)
end

function CHuodongCtrl:UpdateTotalStar(iChapter,iType)
    assert(self.m_mChapterFB[iType]["total_star"][iChapter],"UpdateTotalStar failed:"..iChapter)
    local oPlayer = self:GetPlayer()
    local mNet = table_deep_copy(self.m_mChapterFB[iType]["total_star"][iChapter])
    mNet["chapter"] = iChapter
    mNet["type"] = iType
    oPlayer:Send("GS2CUpdateChapterTotalStar",{info = mNet})
end

function CHuodongCtrl:UpdateClientChapter(iChapter,iLevel,iType)
    local oPlayer = self:GetPlayer()
    local mInfo = self:GetLevelInfo(iChapter,iLevel,iType)
    oPlayer:Send("GS2CUpdateChapter",{info = mInfo})
end

function CHuodongCtrl:GetLevelInfo(iChapter,iLevel,iType)
    local oPlayer = self:GetPlayer()
    local sKey = self:GetChapterKey(iChapter,iLevel)
    local mData  = self.m_mChapterFB[iType] and self.m_mChapterFB[iType][sKey]
    mData = mData or {}
    local iOpen = mData["open"] or 0
    local iPass = mData["pass"] or 0
    local iStar = mData["star"] or 0
    local mStarCondition = mData["star_condition"] or {}
    local s = "fight_time:"..self:GetChapterKey(iChapter,iLevel,iType)
    local iFightTime = oPlayer.m_oToday:Query(s,0)
    return {type = iType,chapter = iChapter,level = iLevel,open = iOpen,pass = iPass,star = iStar,fight_time = iFightTime,star_condition = mStarCondition}
end

function CHuodongCtrl:CheckChapterExtraReward(iChapter,iLevel,iType)
    self:Dirty()
    local sKey = self:GetChapterKey(iChapter,iLevel)
    local mBaseData = self:GetChapterBaseData(iChapter,iLevel,iType)
    if table_count(mBaseData["extra_reward"]) > 0 then
        if not self.m_mChapterFB[iType]["extra_reward"] or not self.m_mChapterFB[iType]["extra_reward"][sKey] then
            self.m_mChapterFB[iType]["extra_reward"] = self.m_mChapterFB[iType]["extra_reward"] or {}
            self.m_mChapterFB[iType]["extra_reward"][sKey] = 0
            local oPlayer = self:GetPlayer()
            oPlayer:Send("GS2CUpdateChapterExtraReward",{info = {chapter = iChapter,level = iLevel,type = iType,reward_status = 0}})
        end
    end
end

function CHuodongCtrl:GetNextLevel(iChapter,iLevel,iType)
    local iNextChapter = iChapter + 1
    local iNextLevel = iLevel+1
    local mBaseData = self:GetChapterBaseData(iChapter,iNextLevel,iType)
    if mBaseData then
        iNextChapter = iChapter
    else
        mBaseData = self:GetChapterBaseData(iNextChapter,1,iType)
        if mBaseData then
            iNextLevel = 1
        else
            return
        end
    end
    return iNextChapter,iNextLevel
end

function CHuodongCtrl:GetFirstUnOpenLevel(iType)
    if not self.m_mChapterFB[iType] or not self.m_mChapterFB[iType]["finalchapter"] or not self.m_mChapterFB[iType]["finalchapter"]["chapter"] then
        return 1,1
    end
    local iChapter,iLevel = self.m_mChapterFB[iType]["finalchapter"]["chapter"],self.m_mChapterFB[iType]["finalchapter"]["level"]
    local iNextChapter,iNextLevel = self:GetNextLevel(iChapter,iLevel,iType)
    if not iChapter then
        return
    end
    return iNextChapter,iNextLevel
end

function CHuodongCtrl:CheckNextLevelOpen(iChapter,iLevel,iType)
    local iNextChapter,iNextLevel
    if not iChapter then
        iNextChapter,iNextLevel = self:GetFirstUnOpenLevel(iType)
    else
        iNextChapter,iNextLevel = self:GetNextLevel(iChapter,iLevel,iType)
    end
    if not iNextChapter then
        return
    end
    self:CheckChapterOpen(iNextChapter,iNextLevel,iType)
end

function CHuodongCtrl:ValidSweepChapterFb(iChapter,iLevel,iType,iCount)
    local oPlayer = self:GetPlayer()
    if oPlayer:HasTeam() then
        return false,1004
    end
    local mBaseData = self:GetChapterBaseData(iChapter,iLevel,iType)
    local iMaxFightTime = mBaseData["fight_time"]
    local iFightTime = self:GetChapterFbFightTime(iChapter,iLevel,iType)
    if (iFightTime + iCount) > iMaxFightTime then
        return false,1001
    end
    local mSweepCondition = mBaseData["sweep_condition"]
    for _,sCondition in pairs(mSweepCondition) do
        if not self:CheckChapterCondition(sCondition,iType) then
            return false,1005
        end
    end
    return true
end

function CHuodongCtrl:PackChapterFbLoginInfo()
    local mNet = {}
    local oPlayer = self:GetPlayer()
    mNet["totalstar_info"] = self:PackChapterTotalStarInfo()
    mNet["extrareward_info"] = self:PackChapterExtraRewardInfo()
    local mFinalChapter = {}
    for iType,info in pairs(self.m_mChapterFB) do
        if info["finalchapter"] then
            table.insert(mFinalChapter,info["finalchapter"])
        end
    end
    mNet["finalchapter"] = mFinalChapter
    mNet["energy_buytime"] = oPlayer.m_oToday:Query("energy_buytime",0)
    return mNet
end

function CHuodongCtrl:PackChapterTotalStarInfo()
    local mNet = {}
    for iType,info in pairs(self.m_mChapterFB) do
        if info["total_star"] then
            for iChapter,m in pairs(info["total_star"]) do
                table.insert(mNet,{star = m["star"],reward_status = m["reward_status"],chapter = iChapter,type = iType})
            end
        end
    end
    return mNet
end

function CHuodongCtrl:PackChapterExtraRewardInfo()
    local mNet = {}
    for iType,info in pairs(self.m_mChapterFB) do
        if info["extra_reward"] then
            for sKey,iStatus in pairs(info["extra_reward"]) do
                local m = split_string(sKey,"-")
                local iChapter,iLevel = tonumber(m[1]),tonumber(m[2])
                table.insert(mNet,{chapter = iChapter,level = iLevel,reward_status = iStatus,type = iType})
            end
        end
    end
    return mNet
end

function CHuodongCtrl:GetChapterInfo(iChapter,iType)
    local oPlayer = self:GetPlayer()
    local mNet = {}
    self.m_mChapterFB[iType] = self.m_mChapterFB[iType] or {}
    for sKey,info in pairs(self.m_mChapterFB[iType]) do
        local iLevel = string.match(sKey,string.format("^%d%%-(%%w+)",iChapter))
        if iLevel then
            iLevel = tonumber(iLevel)
            local iOpen = info["open"] or 0
            local iPass = info["pass"] or 0
            local iStar = info["star"] or 0
            local mStarCondition = info["star_condition"] or {}
            local iFightTime = oPlayer.m_oToday:Query("fight_time:"..self:GetChapterKey(iChapter,iLevel,iType),0)
            table.insert(mNet,{chapter = iChapter,level = iLevel,type = iType,open = iOpen,pass = iPass,star = iStar,fight_time = iFightTime,star_condition = mStarCondition})
        end
    end
    oPlayer:Send("GS2CChapterInfo",{info = mNet})
end

function CHuodongCtrl:HasReward(iStatus,iIndex)
    local iBit = 1 << (iIndex - 1)
    local iBitStatus = iStatus & iBit
    return iBitStatus ~= 0
end


function CHuodongCtrl:VaildGetStarReward(iChapter,iType,iIndex)
    if not self.m_mChapterFB[iType] or not self.m_mChapterFB[iType]["total_star"] or not self.m_mChapterFB[iType]["total_star"][iChapter] then
        return false,1007
    end
    local mData = res["daobiao"]["huodong"]["chapterfb"]["starreward"]
    if not mData[iChapter] or not mData[iChapter][iIndex] or not mData[iChapter][iIndex][iType]then
        record.warning(string.format("VaildGetStarReward error:%d，%d",iChapter,iIndex))
        return false,1007
    end

    local iTarget = mData[iChapter][iIndex][iType]["star"]
    local iTotalStar = self.m_mChapterFB[iType]["total_star"][iChapter]["star"]

    if iTarget > iTotalStar then
        return false,1007
    end

    local iStatus = self.m_mChapterFB[iType]["total_star"][iChapter]["reward_status"]
    if self:HasReward(iStatus,iIndex) then
        return false,1008
    end
    return true
end

function CHuodongCtrl:GetStarReward(iChapter,iType,iIndex)
    -- body
    self:Dirty()
    local iStatus = self.m_mChapterFB[iType]["total_star"][iChapter]["reward_status"]
    local iBit = 1 << (iIndex - 1)
    local iNewStatus = iStatus | iBit
    self.m_mChapterFB[iType]["total_star"][iChapter]["reward_status"] = iNewStatus
    self:UpdateTotalStar(iChapter,iType)
end

function CHuodongCtrl:VaildGetExtraReward(iChapter,iLevel,iType)
    local sKey = self:GetChapterKey(iChapter,iLevel)
    if not self.m_mChapterFB[iType] then
        return false,1008
    end
    self.m_mChapterFB[iType]["extra_reward"] = self.m_mChapterFB[iType]["extra_reward"] or {}
    local mBaseData = self:GetChapterBaseData(iChapter,iLevel,iType)
    if table_count(mBaseData["extra_reward"]) <= 0 then
        record.warning("VaildGetExtraReward error:"..sKey)
        return false,1007
    end
    if self.m_mChapterFB[iType]["extra_reward"] and self.m_mChapterFB[iType]["extra_reward"][sKey] and self.m_mChapterFB[iType]["extra_reward"][sKey] ~= 0 then
        return false,1008
    end
    return true
end

function CHuodongCtrl:GetExtraReward(iChapter,iLevel,iType)
    self:Dirty()
    local sKey = self:GetChapterKey(iChapter,iLevel)
    if not self.m_mChapterFB[iType] then
        return
    end
    self.m_mChapterFB[iType]["extra_reward"] = self.m_mChapterFB[iType]["extra_reward"] or {}
    local mBaseData = self:GetChapterBaseData(iChapter,iLevel,iType)
    if table_count(mBaseData["extra_reward"]) <= 0 then
        record.warning("GetExtraReward error:"..sKey)
        return false
    end
    self.m_mChapterFB[iType]["extra_reward"][sKey] = 1
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CUpdateChapterExtraReward",{info = {chapter = iChapter,level = iLevel,type = iType,reward_status = 1}})
    return true
end


function CHuodongCtrl:NewDay()
    self:Dirty()
    self:ResetConvoyInfo()
    self.m_mConvoyInfo.time = get_dayno()
    local iRewardTimes = global.oWorldMgr:QueryGlobalData("train_rewardtimes") or 0
    iRewardTimes = tonumber(iRewardTimes)
    self:AddTrainRewardTime(iRewardTimes,string.format("%s点奖励次数",0))
end

function CHuodongCtrl:PackConvoyInfo()
    if not self.m_mConvoyInfo or not self.m_mConvoyInfo["convoyinfo"] then
        self:Dirty()
        self:ResetConvoyInfo()
        self.m_mConvoyInfo.time = get_dayno()
    end
    local mNet = self.m_mConvoyInfo["convoyinfo"]
    return mNet
end

function CHuodongCtrl:CheckConvoyDailyReset()
    if not self.m_mConvoyInfo or not self.m_mConvoyInfo.time or self.m_mConvoyInfo.time < get_dayno() then
        return true
    end
    return false
end

function CHuodongCtrl:ConvoyDailyReset()
    self:Dirty()
    self:ResetConvoyInfo()
    self.m_mConvoyInfo.time = get_dayno()
    self:UpdateConvoyInfo()
end

function CHuodongCtrl:ResetConvoyInfo(mArgs)
    mArgs = mArgs or {}
    local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
    if oHuodong:IsOnGame(self.m_ID) then
        return
    end
    self:Dirty()
    if mArgs.convoyinfo then
        self.m_mConvoyInfo["convoyinfo"] = mArgs.convoyinfo
        return
    end
    self.m_mConvoyInfo["convoyinfo"] = {}
    local m = {}
    m = mArgs.pool_info or oHuodong:RandomPool()
    local mPoolInfo = table_deep_copy(m)
    m["status"] = 0
    m["refresh_time"] = mArgs.refresh_time or 0
    m["refresh_cost"] = mArgs.refresh_cost or 0
    m["free_time"] = mArgs.free_time or oHuodong:GetFreeRefreshTime(self:GetPlayer())
    self.m_mConvoyInfo["convoyinfo"] = m
    record.user("convoy","reset",{pid = self.m_ID,pool_info = ConvertTblToStr(mPoolInfo or {}),status = m["status"],refresh_time = m["refresh_time"],free_time = m["free_time"],refresh_cost = m["refresh_cost"]})
end

function CHuodongCtrl:ConvoyEnd(sReason)
    if self:CheckConvoyDailyReset() then
        self:ConvoyDailyReset()
        return
    end
    local mData = self.m_mConvoyInfo["convoyinfo"] or {}
    local mPoolInfo
    if sReason ~= "win" then
        mPoolInfo = {selected_pos = mData.selected_pos,pool_info = mData.pool_info,convoy_partner = mData.convoy_partner,target_npc = mData.target_npc}
    end

    local iRefreshTime,iRefreshCost,iFreeTime = mData["refresh_time"] or 0,mData["refresh_cost"] or 0,mData["free_time"] or 0
    self:ResetConvoyInfo({refresh_time = iRefreshTime,refresh_cost = iRefreshCost,free_time = iFreeTime,pool_info = mPoolInfo})
    self:UpdateConvoyInfo()
end

function CHuodongCtrl:UpdateConvoyInfo(mConvoyInfo)
    if mConvoyInfo then
        self:Dirty()
        self.m_mConvoyInfo["convoyinfo"] = mConvoyInfo
    end
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CUpdateConvoyInfo",{convoyinfo = self.m_mConvoyInfo["convoyinfo"] or {}})
end

function CHuodongCtrl:GetChapterKey(iChapter,iLevel,iType)
    if iType then
        return iChapter.."-"..iLevel.."-"..iType
    end
    return iChapter.."-"..iLevel
end

function CHuodongCtrl:GMOpenChapter(iChapter,iType)
    for i = 1,10 do
        if self:GetChapterBaseData(iChapter,i,iType) then
            self:ChapterOpen(iChapter,i,iType)
        end
    end
end

function CHuodongCtrl:PackTrainInfo()
    return {reward_times = self.m_mTraining["reward_times"]}
end

function CHuodongCtrl:SetTranInfo( ... )
    -- body
end

function CHuodongCtrl:GetTrainRewardTime()
    return self.m_mTraining["reward_times"] or 0
end

function CHuodongCtrl:AddTrainRewardTime(iTimes,sReason)
    assert(iTimes > 0,"AddTrainRewardTime error:"..iTimes)
    self:Dirty()
    local iOldTimes = self.m_mTraining["reward_times"] or 0
    local iMaxTimes = global.oWorldMgr:QueryGlobalData("train_maxtimes") or 0
    iMaxTimes = tonumber(iMaxTimes)
    self.m_mTraining["reward_times"] =iOldTimes + iTimes
    self.m_mTraining["reward_times"] = math.min(self.m_mTraining["reward_times"],iMaxTimes)
    local iCurDay = get_dayno()
    local m = os.date("*t", get_time())
    local iCurHour = m.hour
    local iCurMin = m.min
    local mRewardTime = {day=iCurDay,hour = iCurHour,min = iCurMin}
    self.m_mTraining.last_rewardtime = mRewardTime
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CRefreshTrainTimes",{times = self.m_mTraining["reward_times"]})
    record.user("lilian","times_change",{pid=self.m_ID,oldtimes=iOldTimes,newtimes=self.m_mTraining["reward_times"],reason = sReason})
end

function CHuodongCtrl:DelTrainRewardTime(iTimes,sReason)
    assert(iTimes > 0,"DelTrainRewardTime error:"..iTimes)
    assert(self.m_mTraining["reward_times"] and self.m_mTraining["reward_times"] >= iTimes,"DelTrainRewardTime error2:"..iTimes)
    self:Dirty()
    local iOldTimes = self.m_mTraining["reward_times"] or 0
    self.m_mTraining["reward_times"] =( self.m_mTraining["reward_times"] or 0 ) - iTimes
    record.user("lilian","times_change",{pid=self.m_ID,oldtimes=iOldTimes,newtimes=self.m_mTraining["reward_times"],reason = sReason})
end

function CHuodongCtrl:CheckTrainOfflineRewardTime(oPlayer)
    local iGrade = global.oWorldMgr:QueryControl("dailytrain","open_grade")
    if oPlayer:GetGrade() < iGrade then
        return
    end
    local mRewardTime = self.m_mTraining.last_rewardtime
    if not mRewardTime then
        return
    end
    local iLastRewardDay = mRewardTime.day
    local iLastRewardHour = mRewardTime.hour
    local iLastRewardMin = mRewardTime.min
    local iCurDay = get_dayno()
    local m = os.date("*t", get_time())
    local iCurHour = m.hour
    local iCurMin = m.min
    local iTotalRewardTime = 0
    if iCurDay > iLastRewardDay then
        iTotalRewardTime = iCurDay - iLastRewardDay
    end
    local iRewardTimes = global.oWorldMgr:QueryGlobalData("train_rewardtimes") or 0
    iRewardTimes = tonumber(iRewardTimes)
    if iTotalRewardTime > 0 then
        self:AddTrainRewardTime(iTotalRewardTime*iRewardTimes,"奖励离线次数")
    end
end

function CHuodongCtrl:CheckTrainOpen(iGrade)
    local iOpenGrade = global.oWorldMgr:QueryControl("dailytrain","open_grade")
    if iGrade == iOpenGrade then
        local iRewardTimes = global.oWorldMgr:QueryGlobalData("train_rewardtimes") or 0
        iRewardTimes = tonumber(iRewardTimes)
        self:AddTrainRewardTime(iRewardTimes,"首次开启玩法赠送悬赏点")
    end
end

function CHuodongCtrl:CheckHuntOpen(iGrade)
    local iOpenGrade = global.oWorldMgr:QueryControl("dailytrain","open_grade")
    if iGrade == iOpenGrade then
        self:Dirty()
        self.m_mHuntInfo = {npcinfo = {},freeinfo = {},soulinfo = {}}
        self:ActiveHuntNpc(1,true)
    end
end

function CHuodongCtrl:ActiveHuntNpc(iLevel,bRefresh)
    self:Dirty()
    self.m_mHuntInfo["npcinfo"][iLevel] = self.m_mHuntInfo["npcinfo"][iLevel] or {}
    self.m_mHuntInfo["npcinfo"][iLevel]["status"] = 1
    if bRefresh then
        self:RefreshHuntInfo()
    end
end

function CHuodongCtrl:FreeActiveHuntNpc(iLevel)
    self:Dirty()
    self.m_mHuntInfo["freeinfo"][iLevel] = self.m_mHuntInfo["freeinfo"][iLevel] or {}
    self.m_mHuntInfo["freeinfo"][iLevel]["last_freetime"] = get_time()
    self:ActiveHuntNpc(iLevel,true)
end

function CHuodongCtrl:InActiveHuntNpc(iLevel)
    if iLevel == 1 or not self.m_mHuntInfo["npcinfo"][iLevel] or not (self.m_mHuntInfo["npcinfo"][iLevel]["status"] == 1) then
        return
    end
    self:Dirty()
    self.m_mHuntInfo["npcinfo"][iLevel]["status"] = 0
end

function CHuodongCtrl:PackHuntInfo()
    local mNet = {freeinfo = {},npcinfo = {},soulinfo = self.m_mHuntInfo["soulinfo"]}
    for iLevel,info in pairs(self.m_mHuntInfo["freeinfo"] or {}) do
        table.insert(mNet["freeinfo"],{level = iLevel,last_freetime = info["last_freetime"]})
    end
    for iLevel,info in pairs(self.m_mHuntInfo["npcinfo"] or {}) do
        table.insert(mNet["npcinfo"],{level = iLevel,status = info["status"]})
    end
    return mNet
end

function CHuodongCtrl:GetNpcStatus(iLevel)
    if self.m_mHuntInfo["npcinfo"] and self.m_mHuntInfo["npcinfo"][iLevel] and self.m_mHuntInfo["npcinfo"][iLevel]["status"] then
        return self.m_mHuntInfo["npcinfo"][iLevel]["status"]
    end
    return 0
end

function CHuodongCtrl:RefreshHuntInfo()
    local mInfo = self:PackHuntInfo()
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CHuntInfo",mInfo)
end

function CHuodongCtrl:HuntSoul(iLevel,iRewardType,iRewardId)
    self:Dirty()
    self.m_mHuntInfo["soulinfo"] = self.m_mHuntInfo["soulinfo"] or {}
    local iCreateTime = self:DispatchSoulID()
    table.insert(self.m_mHuntInfo["soulinfo"],{type = iRewardType,id = iRewardId,createtime = iCreateTime})
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CAddHuntSoul",{type = iRewardType,id = iRewardId,createtime = iCreateTime})
end

function CHuodongCtrl:PickUpSoul(iCreateTime)
    for i=1,#self.m_mHuntInfo["soulinfo"] do
        if self.m_mHuntInfo["soulinfo"][i]["createtime"] == iCreateTime then
            self:RewardHuntSoul(self.m_mHuntInfo["soulinfo"][i]["type"],self.m_mHuntInfo["soulinfo"][i]["id"])
            table.remove(self.m_mHuntInfo["soulinfo"],i)
            local oPlayer = self:GetPlayer()
            oPlayer:Send("GS2CDelHuntSoul",{createtime = {iCreateTime}})
            return
        end
    end
end

function CHuodongCtrl:ValidAddSoul(oPlayer,iSoulId)
    return oPlayer:ValidGive({{iSoulId,1}},{cancel_tip = 1})
end

function CHuodongCtrl:PickUpSoulByOneKey()
    local iAmount = 0
    local oPlayer = self:GetPlayer()
    local m = {}
    local iIndex = 1
    local iLen = #self.m_mHuntInfo["soulinfo"]
    local bDel
    for i = 1,iLen do
        bDel = false
        local iType = self.m_mHuntInfo["soulinfo"][iIndex]["type"]
        local iID = self.m_mHuntInfo["soulinfo"][iIndex]["id"]
        if iType == 1 then
            if self:ValidAddSoul(oPlayer,iID) then
                iAmount = iAmount + 1
                table.insert(m,self.m_mHuntInfo["soulinfo"][iIndex]["createtime"])
                table.remove(self.m_mHuntInfo["soulinfo"],iIndex)
                bDel = true
                self:RewardHuntSoul(iType,iID)
            else
                global.oNotifyMgr:Notify(oPlayer.m_iPid,"御灵已满，请清理后再拾取新的御灵")
                oPlayer:Send("GS2CDelHuntSoul",{createtime = m})
                return iAmount
            end
        end
        iIndex = bDel and iIndex or (iIndex + 1)
    end
    oPlayer:Send("GS2CDelHuntSoul",{createtime = m})
    return iAmount
end

function CHuodongCtrl:RewardHuntSoul(iType,iID)
    local oHuodong = global.oHuodongMgr:GetHuodong("hunt")
    if oHuodong then
        local oPlayer = self:GetPlayer()
        oHuodong:RewardHuntSoul(oPlayer,iType,iID)
    end

end

function CHuodongCtrl:DispatchSoulID()
    self:Dirty()
    local iHuntid = self.m_iHuntID
    self.m_iHuntID = self.m_iHuntID + 1
    return iHuntid
end

function CHuodongCtrl:SaleSoulByOneKey()
    local iAmount = 0
    local iIndex = 1
    local m = {}
    local iSoulId
    for i=1,#self.m_mHuntInfo["soulinfo"] do
        if self.m_mHuntInfo["soulinfo"][iIndex]["type"] == 2 then
            iSoulId = self.m_mHuntInfo["soulinfo"][iIndex]["id"]
            iAmount = iAmount + 1
            table.insert(m,self.m_mHuntInfo["soulinfo"][iIndex]["createtime"])
            table.remove(self.m_mHuntInfo["soulinfo"],iIndex)
        else
            iIndex = iIndex + 1
        end
    end
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CDelHuntSoul",{createtime = m})
    return iAmount,iSoulId
end

function CHuodongCtrl:PackHireInfo()
    local m = {}
    for iPartnerId,info in pairs(self.m_mHirePartner) do
        table.insert(m,{parid = iPartnerId,times = info["hiretimes"]})
    end
    return m
end

function CHuodongCtrl:GetPartnerHireTime(iPartnerId)
    return self.m_mHirePartner[iPartnerId] and self.m_mHirePartner[iPartnerId]["hiretimes"] or 0
end

function CHuodongCtrl:HirePartner(iPartnerId)
    self:Dirty()
    self.m_mHirePartner[iPartnerId] = self.m_mHirePartner[iPartnerId] or {}
    self.m_mHirePartner[iPartnerId]["hiretimes"] = (self.m_mHirePartner[iPartnerId]["hiretimes"] or 0 ) + 1
    local oPlayer = self:GetPlayer()
    local mNet = {parid = iPartnerId,times = self.m_mHirePartner[iPartnerId]["hiretimes"]}
    oPlayer:Send("GS2CRefreshHireInfo",mNet)
end

function CHuodongCtrl:PackChargeScoreInfo()
    return self.m_mChargeScoreInfo or {}
end

function CHuodongCtrl:ClearChargeScoreInfo(iActivityId)
    self:Dirty()
    self.m_mChargeScoreInfo = {activityid = iActivityId}
end

function CHuodongCtrl:GetChargeScore()
    return self.m_mChargeScoreInfo["score_info"] and (self.m_mChargeScoreInfo["score_info"]["score"] and self.m_mChargeScoreInfo["score_info"]["score"] or 0) or 0
end

function CHuodongCtrl:GetChargeScoreBuyTimes(iID)
    return self.m_mChargeScoreInfo["score_info"] and (self.m_mChargeScoreInfo["score_info"]["buy_info"] and (self.m_mChargeScoreInfo["score_info"]["buy_info"][iID] and self.m_mChargeScoreInfo["score_info"]["buy_info"][iID] or 0) or 0) or 0
end

function CHuodongCtrl:BuyChargeScoreItem(iID,iTimes,iScore)
    self:Dirty()
    self.m_mChargeScoreInfo["score_info"] = self.m_mChargeScoreInfo["score_info"] and self.m_mChargeScoreInfo["score_info"] or {}
    self.m_mChargeScoreInfo["score_info"]["buy_info"] = self.m_mChargeScoreInfo["score_info"]["buy_info"] or {}
    self.m_mChargeScoreInfo["score_info"]["buy_info"][iID] = (self.m_mChargeScoreInfo["score_info"]["buy_info"][iID] and self.m_mChargeScoreInfo["score_info"]["buy_info"][iID] or 0) + iTimes
    self.m_mChargeScoreInfo["score_info"]["score"] = self.m_mChargeScoreInfo["score_info"]["score"] - iScore
    return self.m_mChargeScoreInfo["score_info"]["buy_info"][iID],self.m_mChargeScoreInfo["score_info"]["score"]
end

function CHuodongCtrl:AfterCharge(iAmount)
    self:Dirty()
    self.m_mChargeScoreInfo["score_info"] = self.m_mChargeScoreInfo["score_info"] or {score=0}
    self.m_mChargeScoreInfo["score_info"]["score"] = self.m_mChargeScoreInfo["score_info"]["score"] + iAmount
    return self.m_mChargeScoreInfo["score_info"]["score"]
end

function CHuodongCtrl:PackTimeResumeInfo()
    local mData = {}
    mData["resume_amount"] = self.m_mTimeLimitResume["resume_amount"] or 0
    mData["rewardinfo"] = {}
    if self.m_mTimeLimitResume["rewardinfo"] then
        for iRewardId,iStatus in pairs(self.m_mTimeLimitResume["rewardinfo"]) do
            table.insert(mData["rewardinfo"],{reward = iRewardId,status = iStatus})
        end
    end
    return mData
end

function CHuodongCtrl:PackResumeRestoreInfo()
    local mData = {}
    mData["resume"] = self.m_mResumeRestore["resume"] or 0
    mData["status"] = self.m_mResumeRestore["status"] or 0
    return mData
end

function CHuodongCtrl:RefreshTimeResume()
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CRefreshTimeResume",self:PackTimeResumeInfo())
end

function CHuodongCtrl:RefreshResumeRestore()
    local oPlayer = self:GetPlayer()
    oPlayer:Send("GS2CRefreshResumeRestore",self:PackResumeRestoreInfo())
end

function CHuodongCtrl:AfterResumeGoldCoin(iAmount,sHuodong)
    self:Dirty()
    if sHuodong == "timelimitresume" then
        self.m_mTimeLimitResume["resume_amount"] = (self.m_mTimeLimitResume["resume_amount"] and self.m_mTimeLimitResume["resume_amount"] or 0) + iAmount
        self:RefreshTimeResume()
    elseif sHuodong == "resume_restore" then
        self.m_mResumeRestore["resume"] = (self.m_mResumeRestore["resume"] or 0) + iAmount
        self:RefreshResumeRestore()
    end
end

function CHuodongCtrl:ValidGetTimeResumeReward(iRewardId)
    if self.m_mTimeLimitResume["rewardinfo"] and self.m_mTimeLimitResume["rewardinfo"][iRewardId] then
        return false
    end
    return true
end

function CHuodongCtrl:ValidGetResumeRestoreReward(oPlayer)
    if self.m_mResumeRestore["status"] and self.m_mResumeRestore["status"] == 1 then
        return false
    end
    return true
end

function CHuodongCtrl:GetTimeResumeReward(iRewardId)
    self.m_mTimeLimitResume["rewardinfo"] =  self.m_mTimeLimitResume["rewardinfo"] or {}
    self:Dirty()
    self.m_mTimeLimitResume["rewardinfo"][iRewardId] = 1
end

function CHuodongCtrl:GetResumeRestoreReward()
    self:Dirty()
    self.m_mResumeRestore["status"] = 1
end
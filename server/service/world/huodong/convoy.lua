-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"
local record = require "public.record"
local colorstring = require "public.colorstring"
local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loadpartner = import(service_path("partner/loadpartner"))

local gsub = string.gsub

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "护送"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_GameID = 0
    self.m_mGame = {}
    self.m_mPlayer2Game = {}
    self.m_OnClick = {}  --记录玩家点击状态，防止同时多次点击
    self.m_mOfflineEnd = {}
end

function CHuodong:Load(mArgs)
    local mData = mArgs or {}
    
    self.m_mOfflineEnd = mData.offlineend or {}
    local mGameInfo = mData.game or {}
    for _,info in pairs(mGameInfo) do
        local iGameID = self:NewGameID()
        local oGame = NewGame(iGameID,info)
        local iPlayerID = oGame:GetPlayerID()
        self.m_mPlayer2Game[iPlayerID] = iGameID
        self.m_mGame[iGameID] = oGame
        oGame:GameStart()
    end
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    local mGameInfo = {}
    for gid,oGame in pairs(self.m_mGame) do
        mGameInfo[gid] = oGame:Save()
    end
    mData.game = mGameInfo
    mData.offlineend = self.m_mOfflineEnd
    return mData
end

function CHuodong:MergeFrom(mFromData, mArgs)
    self:Dirty()
    local mOfflineEnd = mFromData.offlineend or {}
    for iPid,iStatus in pairs(mFromData) do
        self.m_mOfflineEnd[iPid] = iStatus
    end
    local mGameInfo = mFromData.game or {}
    for _,info in pairs(mGameInfo) do
        local iGameID = self:NewGameID()
        local oGame = NewGame(iGameID,info)
        local iPlayerID = oGame:GetPlayerID()
        self.m_mPlayer2Game[iPlayerID] = iGameID
        self.m_mGame[iGameID] = oGame
        oGame:GameStart()
    end
    return true
end

function CHuodong:NewHour(iWeekDay, iHour)
    
end

function CHuodong:OnLogin(oPlayer)
    if self.m_mOfflineEnd[oPlayer.m_iPid] then
        self:Dirty()
        oPlayer.m_oHuodongCtrl:ConvoyEnd()
        self.m_mOfflineEnd[oPlayer.m_iPid] = nil
    end
end

function CHuodong:GetConfigData()
    local mData = res["daobiao"]["huodong"][self.m_sName]["config"]
    return mData
end

function CHuodong:GetPoolData(iPool)
    local mData = res["daobiao"]["huodong"][self.m_sName]["convoy_pool"]
    assert(mData[iPool],"GetPoolData failed:"..iPool)
    return mData[iPool]
end

function CHuodong:GetModelData(iModel)
    local mData = res["daobiao"]["huodong"][self.m_sName]["follow_talk"]
    assert(mData[iModel],"GetModelData failed:"..iModel)
    return mData[iModel]
end

function CHuodong:DoScript(iPid,oNpc,mEvent,mArgs)
    if type(mEvent) ~= "table" then
        return
    end
    for _,sEvent in pairs(mEvent) do
        self:DoScript2(iPid,oNpc,sEvent,mArgs)
    end
end

function CHuodong:IsFunctionOpen()
    local bOpen = res["daobiao"]["global_control"]["convoy"]["is_open"]
    return bOpen == "y"
end

function CHuodong:GetFunctionGrade()
    local iGrade = res["daobiao"]["global_control"]["convoy"]["open_grade"]
    return tonumber(iGrade)
end

function CHuodong:ValidDoit(iPid)
    if not self:IsFunctionOpen() then
        return false,1006
    end

    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iOpenGrade = self:GetFunctionGrade()
    if oPlayer:GetGrade() < iOpenGrade then
        return false,1007,{level=iOpenGrade}
    end
    if oPlayer and oPlayer:HasTeam() then
        return false,1005
    end
    return true
end

function CHuodong:DoScript2(iPid,oNpc,sEvent,mArgs)
    if string.sub(sEvent,1,4) == "doit" then
        local bValid,iMsg,mParam = self:ValidDoit(iPid)
        if not bValid then
            global.oNotifyMgr:Notify(iPid,self:GetTransText(iMsg,mParam))
            return
        end
        self:ShowConvoyMainUI(iPid)
        return
    elseif string.sub(sEvent,1,8) == "continue" then
        local oNpc = global.oNpcMgr:GetGlobalNpc(5019)
        local mNpcPos = oNpc:PosInfo()
        local iMapId = oNpc:MapId()
        local iPosx,iPosy = mNpcPos["x"],mNpcPos["y"]
        local func = function(oPlayer,mData)
            local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
            local oNpc = global.oNpcMgr:GetGlobalNpc(5019)
            oHuodong:GS2CDialog(iPid,oNpc,100)
        end
        local oCbMgr = global.oCbMgr
        local mData = {["iMapId"] = iMapId,["iPosx"] = iPosx,["iPosy"] = iPosy,["iAutoType"] = 1}
        oCbMgr:SetCallBack(iPid,"AutoFindTaskPath",mData,nil,func)
    end
    super(CHuodong).DoScript2(self,iPid,oNpc,sEvent,mArgs)
end

function CHuodong:TransString(iPid,oNpc,sContent,mArgs)
    if not sContent then
        return
    end
    if string.find(sContent,"$lefttime") then
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        local iLeftTime = self:GetLeftConvoyTime(oPlayer)
        sContent = gsub(sContent,"$lefttime",iLeftTime)
    end
    if string.find(sContent,"$level") then
        sContent = gsub(sContent,"$level",mArgs["level"] or 0)
    end
    if string.find(sContent,"#convoy_level") then
        sContent = gsub(sContent,"#convoy_level",mArgs["convoy_level"] or 0)
    end
    if string.find(sContent,"$partner_name") then
        sContent = gsub(sContent,"$partner_name",mArgs["partner_name"] or "")
    end
    if string.find(sContent,"$cost") then
        sContent = gsub(sContent,"$cost",mArgs["cost"] or 0)
    end
    return sContent
end

function CHuodong:GetMaxConvoyTime()
    local sValue = res["daobiao"]["global"]["convoy_maxtime"]["value"]
    return tonumber(sValue)
end

function CHuodong:GetGameLastTime()
    local sValue = res["daobiao"]["global"]["convoy_time"]["value"]
    return tonumber(sValue)*60
end

function CHuodong:GetDialogBaseData()
    local mData = res["daobiao"]["huodong"][self.m_sName]["dialog"]
    assert(mData,string.format("Not Dialog Config:%s",self.m_sName))
    return mData
end

function CHuodong:GetDialogInfo(iDialog)
    local mData = self:GetDialogBaseData()
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CHuodong:GetTransText(iText,mParam)
    local sText = self:GetTextData(iText)
    return self:TransString(nil,nil,sText,mParam)
end

function CHuodong:ValidConvoy(oPlayer)
    return self:GetLeftConvoyTime(oPlayer) > 0
end

function CHuodong:GetLeftConvoyTime(oPlayer)
    local iTime = oPlayer.m_oToday:Query("convoytime",0)
    local iMaxTime = self:GetMaxConvoyTime()
    return iMaxTime - iTime
end

function CHuodong:do_look(oPlayer,oNpc)
    local iTime = oPlayer.m_oToday:Query("convoytime",0)
    local iMaxTime = self:GetMaxConvoyTime()
    if self:ValidConvoy(oPlayer) then
        self:GS2CDialog(oPlayer.m_iPid,oNpc,100)
    else
        self:GS2CDialog(oPlayer.m_iPid,oNpc,101)
    end
end

function CHuodong:GS2CDialog(iPid,oNpc,iDialog)
    local mDialogInfo = self:GetDialogInfo(iDialog)
    if not mDialogInfo then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local m = {}
    m["dialog"] = {{
        ["type"] = mDialogInfo["type"],
        ["pre_id_list"] = mDialogInfo["pre_id_list"],
        ["content"] = self:TransString(iPid,oNpc,mDialogInfo["content"]),
        ["voice"] = mDialogInfo["voice"],
        ["last_action"] = mDialogInfo["last_action"],
        ["next"] = mDialogInfo["next"],
        ["ui_mode"] = mDialogInfo["ui_mode"],
        ["status"] = mDialogInfo["status"],
    }}
    m["dialog_id"] = iDialog
    m["npc_id"] = oNpc.m_ID
    m["npc_name"] = oNpc:Name()
    m["shape"] = oNpc:Shape()
    local iNpcId = oNpc.m_ID
    local sName = self.m_sName
    local func = function(oPlayer,mArgs)
        if mArgs.answer and mArgs.answer ~= 0 then
            local event = mDialogInfo["last_action"][mArgs.answer]["event"]
            if event then
                local oHuodongMgr = global.oHuodongMgr
                local oHuodong = oHuodongMgr:GetHuodong(sName)
                local oNpcMgr = global.oNpcMgr
                local obj = oNpcMgr:GetObject(iNpcId)
                if not obj then
                    return
                end
                oHuodong:DoScript(iPid,obj,{event})
            end
        end
    end
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(iPid,"GS2CDialog",m,nil,func)
end

function CHuodong:ShowConvoyMainUI(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local mNet = oPlayer.m_oHuodongCtrl:PackConvoyInfo(iPid)
        oPlayer:Send("GS2CShowConvoyMainUI",{convoyinfo = mNet})
    end
end

function CHuodong:CalTotalWeight(m)
    local iTotal = 0
    for _,info in pairs(m) do
        if info.weight then
            iTotal = iTotal + info.weight
        end
    end
    return iTotal
end

function CHuodong:CalInitWeight(m)
    local iTotal = 0
    for _,info in pairs(m) do
        if info.init_weight then
            iTotal = iTotal + info.init_weight
        end
    end
    return iTotal
end

function CHuodong:RandomConvoy(iPool)
    local mData = self:GetPoolData(iPool)
    mData = mData["convoy_pool"]
    return mData[math.random(#mData)]
end

function CHuodong:RandomSelectTarget(m,iTotalWeight)
    local iRandom = math.random(iTotalWeight)
    local iCur = 0
    for iIndex,info in pairs(m) do
        iCur = iCur + info.init_weight
        if iCur >= iRandom then
            return iIndex
        end
        
    end
end

function CHuodong:RandomPool()
    local mData = self:GetConfigData()
    mData = table_deep_copy(mData[math.random(#mData)])
    local iInitWeight = self:CalInitWeight(mData["config"])
    local iSelectTarget = self:RandomSelectTarget(mData["config"],iInitWeight)
    local iPool = mData["convoy_pool"]
    local mNet = {}
    mNet["selected_pos"] = iSelectTarget
    mNet["pool_info"] = {}
    for iPos,info in ipairs(mData["config"]) do
        local m = {}
        local iPool = info["convoy_pool"]
        local iConvoyPartner = self:RandomConvoy(iPool)
        m["level"] = info.level
        m["pos"] = iPos
        m["partnerid"] = iConvoyPartner
        m["rewardid"] = info.rewarid
        m["weight"] = info.weight
        table.insert(mNet["pool_info"],m)
    end
    local iConvoyPartner = mNet["pool_info"][iSelectTarget]["partnerid"]
    mNet["convoy_partner"] = iConvoyPartner
    local iTargetNpc = self:RandomTargetNpc()
    mNet["target_npc"] = iTargetNpc
    return mNet
end

function CHuodong:ReSelect(oPlayer,mConvoyInfo)
    local iTotalRefreshTime = oPlayer.m_oActiveCtrl:GetData("convoy_refresh",0)
    if iTotalRefreshTime == 1 or (iTotalRefreshTime % 15) == 0  then 
        return self:ReSelect1(oPlayer,mConvoyInfo)
    else
        return self:ReSelect2(oPlayer,mConvoyInfo)
    end
end

function CHuodong:ReSelect1(oPlayer,mConvoyInfo)
    local iSelectPos = mConvoyInfo["selected_pos"] or 1
    local iCurLevel = mConvoyInfo["pool_info"][iSelectPos]["level"]
    local iMaxLevel = iCurLevel
    local iNewPos = iSelectPos
    for iPos,info in ipairs(mConvoyInfo["pool_info"]) do
        if iMaxLevel < info.level then
            iMaxLevel = info.level
            iNewPos = iPos
        end
    end
    mConvoyInfo["selected_pos"] = iNewPos
    local iConvoyPartner = mConvoyInfo["pool_info"][mConvoyInfo["selected_pos"]]["partnerid"]
    mConvoyInfo["convoy_partner"] = iConvoyPartner
    local iTargetNpc = self:RandomTargetNpc()
    mConvoyInfo["target_npc"] = iTargetNpc
    local mPartner = self:GetModelData(iConvoyPartner)
    local sName = mPartner["name"]
    local mParam = {["convoypartner"..iMaxLevel]=sName}
    local sMsg = self:GetTransText(1010,{convoy_level = iMaxLevel})
    global.oNotifyMgr:Notify(oPlayer.m_iPid,colorstring.FormatColorString(sMsg, mParam))
    self:AfterReSelect(oPlayer,mConvoyInfo)
    return iCurLevel,iMaxLevel
end

function CHuodong:ReSelect2(oPlayer,mConvoyInfo)
    local mNewPool = {}
    local iSelectTarget = mConvoyInfo["selected_pos"] or 1
    local iCurLevel = mConvoyInfo["pool_info"][iSelectTarget]["level"]
    for iPos,info in pairs(mConvoyInfo["pool_info"]) do
        if iCurLevel <= info.level then
            table.insert(mNewPool,table_deep_copy(info))
        end
    end
    local iTotalWeight = self:CalTotalWeight(mNewPool)
    local iRandomWeight = math.random(iTotalWeight)
    local iCur = 0
    local iNewPos = mNewPool[1]["pos"]
    local iNewLevel = mNewPool[1]["level"]
    local iNewPartner = mNewPool[1]["partnerid"]
    for iIndex,info in pairs(mNewPool) do
        iCur = iCur + info.weight
        if iCur >= iRandomWeight then
            iNewPos = info.pos
            iNewLevel = info.level
            iNewPartner = info.partnerid
            break 
        end
    end
    if iNewLevel == iCurLevel then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,self:GetTransText(1009))
    else
        local mPartner = self:GetModelData(iNewPartner)
        local sName = mPartner["name"]
        local mParam = {["convoypartner"..iNewLevel]=sName}
        local sMsg = self:GetTransText(1010,{convoy_level = iNewLevel})
        global.oNotifyMgr:Notify(oPlayer.m_iPid,colorstring.FormatColorString(sMsg, mParam))
    end
    mConvoyInfo["selected_pos"] = iNewPos
    local iConvoyPartner = mConvoyInfo["pool_info"][mConvoyInfo["selected_pos"]]["partnerid"]
    mConvoyInfo["convoy_partner"] = iConvoyPartner
    local iTargetNpc = self:RandomTargetNpc()
    mConvoyInfo["target_npc"] = iTargetNpc
    self:AfterReSelect(oPlayer,mConvoyInfo)
    return iCurLevel,iNewLevel
end

--重新计算费用和免费次数
function CHuodong:AfterReSelect(oPlayer,mConvoyInfo)
    mConvoyInfo["refresh_time"] = (mConvoyInfo["refresh_time"] or 0) + 1
    local iFreeTime = self:GetFreeRefreshTime(oPlayer)
    if mConvoyInfo["refresh_time"] >= iFreeTime then
        local iPayTime = mConvoyInfo["refresh_time"] - iFreeTime + 1
        local iNextCost = self:GetRefreshCost(iPayTime)
        mConvoyInfo["refresh_cost"] = tonumber(iNextCost)
    end
    mConvoyInfo["free_time"] = math.max(0,iFreeTime - mConvoyInfo["refresh_time"])
    oPlayer.m_oHuodongCtrl:UpdateConvoyInfo(mConvoyInfo)
end

function CHuodong:RandomTargetNpc()
    local sValue = res["daobiao"]["global"]["convoy_targetlist"]["value"]
    local m = split_string(sValue,",")
    return tonumber(m[math.random(#m)])
end

function CHuodong:StarConvoy(oPlayer)
    if oPlayer:HasTeam() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"组队中，禁止护送")
        return
    end
    if not self:ValidConvoy(oPlayer) then
        record.warning("liuwei-debug:StarConvoy failed--not convoytime")
        return
    end
    local mConvoyInfo = oPlayer.m_oHuodongCtrl:PackConvoyInfo()
    mConvoyInfo["status"] = 0
    if mConvoyInfo["status"] and mConvoyInfo["status"] ~= 0 then
        record.warning("liuwei-debug:StarConvoy failed--status error")
        return
    end
    self:Dirty()
    mConvoyInfo["status"] = 1
    local iLevel = mConvoyInfo["pool_info"][mConvoyInfo["selected_pos"]]["level"]
    local iEndTime = get_time() + self:GetGameLastTime()
    mConvoyInfo["end_time"] = iEndTime
    
    oPlayer.m_oHuodongCtrl:UpdateConvoyInfo(mConvoyInfo)
    local iTargetNpc = mConvoyInfo["target_npc"]
    local gid = self:NewGameID()
    local iConvoyPartner = mConvoyInfo["pool_info"][mConvoyInfo["selected_pos"]]["partnerid"]
    local oGame = NewGame(gid,{playerid = oPlayer.m_iPid,end_time = iEndTime,level = iLevel,targetnpc = iTargetNpc,partnerid = iConvoyPartner})
    self.m_mPlayer2Game[oPlayer.m_iPid] = gid
    self.m_mGame[gid] = oGame
    oGame:GameStart()
    local iTime = oPlayer.m_oToday:Query("convoytime",0)
    record.user("convoy","start",{pid = oPlayer.m_iPid,times = iTime+1})
end

function CHuodong:NewGameID()
    self.m_GameID = self.m_GameID + 1
    return self.m_GameID
end

function CHuodong:GetGame(iGameID)
    return self.m_mGame[iGameID]
end

function CHuodong:GetGameByPid(iPid)
    return self.m_mPlayer2Game[iPid]
end

function CHuodong:GetCreateWarArg(mArg)
    mArg.remote_war_type = "convoy"
    mArg.war_type = gamedefines.WAR_TYPE.CONVOY_TYPE
    return mArg
end

function CHuodong:Fight(iPid,oNpc,iFight,iGameID)
    local oWar = super(CHuodong).Fight(self,iPid,oNpc,iFight)
    if not oWar then
        return
    end
    oWar.m_iGameID = iGameID
    return oWar
end

function CHuodong:WarFightEnd(oWar,iPid,oNpc,mArgs)
    super(CHuodong).WarFightEnd(self,oWar,iPid,oNpc,mArgs)
    local win_side = mArgs.win_side
    local iGameID = oWar.m_iGameID
    local oGame = self.m_mGame[iGameID]
    if not oGame then
        global.oNotifyMgr:Notify(iPid,self:GetTransText(1001))
        return
    end
    oGame:WarEnd(win_side == 1)
end

function CHuodong:IsOnGame(iPid)
    return self.m_mPlayer2Game[iPid]
end

function CHuodong:GameEnd(oGame,sReason)
    self:Dirty()
    local oWorldMgr = global.oWorldMgr
    local iPlayerID = oGame:GetPlayerID()
    local iGameID = oGame:GetGameID()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPlayerID)
    self.m_mPlayer2Game[iPlayerID] = nil
    self.m_OnClick[iPlayerID] = nil
    self.m_mGame[iGameID] = nil
    oGame:Release()
    if oPlayer then
        oPlayer.m_oHuodongCtrl:ConvoyEnd(sReason)
    else
        self.m_mOfflineEnd[iPlayerID] = 1
    end
    self:ClearKeep(iPlayerID)
end

function CHuodong:GameWin(oGame)
    local oWorldMgr = global.oWorldMgr
    local iPlayerID = oGame:GetPlayerID()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPlayerID)
    local mConvoyInfo = oPlayer.m_oHuodongCtrl:PackConvoyInfo()
    local iReward = mConvoyInfo["pool_info"][mConvoyInfo["selected_pos"]]["rewardid"]
    global.oAchieveMgr:PushAchieve(iPlayerID,"成功完成帝都宅急便任务次数",{value=1})
    oPlayer:AddSchedule("convoy")
    oPlayer:RecordPlayCnt("convoy",1)
    local iTime = oPlayer.m_oToday:Query("convoytime",0)
    oPlayer.m_oToday:Set("convoytime",iTime+1)
    self:GameEnd(oGame,"win")
    self:Reward(iPlayerID,iReward)
    record.user("convoy","win",{pid = iPlayerID,rewardid = iReward})
    self:ClearKeep(iPlayerID)
    self:AfterGameWin(iPlayerID)
end

function CHuodong:RewardPartnerExp(oPlayer,sPartnerExp,mArgs)
    local mPartner
    if mArgs and mArgs.win_side and mArgs.win_side == 1 then
        mPartner = self:GetFightPartner(oPlayer,mArgs)
    else
        mPartner = oPlayer.m_oPartnerCtrl:PackFightPartnerInfo()
    end
    local mExp = {}
    if mPartner then
        for iParId,mInfo in pairs(mPartner) do
            local iPartnerExp = self:TransReward(oPlayer,sPartnerExp, {level = mInfo.grade})
            iPartnerExp = math.floor(iPartnerExp)
            assert(iPartnerExp, string.format("schedule reward exp err: %s", sPartnerExp))
            if oPlayer.m_oPartnerCtrl:ValidUpgradePartner(mInfo.effect_type) then
                mExp[mInfo.parid] = iPartnerExp
            end
        end
    end
    oPlayer.m_oPartnerCtrl:AddPartnerListExp(table_deep_copy(mExp), self.m_sName, mArgs)
    self:AddKeep(oPlayer:GetPid(),"partner_exp",mExp)
end

function CHuodong:AfterGameWin(iPid)
    -- body
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iTime = oPlayer.m_oToday:Query("convoytime",0)
    local iMaxTime = self:GetMaxConvoyTime()
    if self:ValidConvoy(oPlayer) then
        local oNpc = global.oNpcMgr:GetGlobalNpc(5019)
        self:GS2CDialog(iPid,oNpc,102)
    end
end

function CHuodong:GiveUpConvoy(oPlayer)
    local iGameID = self.m_mPlayer2Game[oPlayer.m_iPid]
    if not iGameID then
        return
    end
    local oGame = self.m_mGame[iGameID]
    if not oGame then
        return
    end
    local sContent = self:GetTransText(1002)
    local mNet = {
        sContent = sContent,
        sConfirm = "停止",
        sCancle = "取消",
        default = 0,
        time = 30,
    }
    local oCbMgr = global.oCbMgr
    mNet = oCbMgr:PackConfirmData(nil, mNet)
    local func = function(oPlayer,mData)
        if mData.answer and mData.answer == 1 then
            local oHuodongMgr = global.oHuodongMgr
            local oHuodong = oHuodongMgr:GetHuodong("convoy")
            oHuodong:_TrueGiveUpConvoy(oPlayer)
        end
    end
    oCbMgr:SetCallBack(oPlayer.m_iPid,"GS2CConfirmUI",mNet,nil,func)
end

function CHuodong:_TrueGiveUpConvoy(oPlayer)
    local iGameID = self.m_mPlayer2Game[oPlayer.m_iPid]
    if not iGameID then
        return
    end
    local oGame = self.m_mGame[iGameID]
    if not oGame then
        return
    end
    global.oNotifyMgr:Notify(oPlayer.m_iPid,self:GetTransText(1011))
    self:GameEnd(oGame,"giveup")
    record.user("convoy","giveup",{pid = oPlayer.m_iPid})
end

function CHuodong:RefreshTarget(oPlayer)
    local iGameID = self.m_mPlayer2Game[oPlayer.m_iPid]
    if iGameID then
        return
    end
    local bValid,iMsg = self:ValidRefresh(oPlayer)
    if not bValid then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,self:GetTransText(iMsg))
        return
    end
    local mConvoyInfo = oPlayer.m_oHuodongCtrl:PackConvoyInfo()
    local iRefreshCost = mConvoyInfo["refresh_cost"]
    if iRefreshCost > 0 then
        if not oPlayer:ValidGoldCoin(iRefreshCost) then
            return
        else
            oPlayer:ResumeGoldCoin(iRefreshCost,"刷新护送目标")
        end
    end
    self:_TrueRefreshTarget(oPlayer)
end

function CHuodong:_TrueRefreshTarget(oPlayer)
    local mConvoyInfo = oPlayer.m_oHuodongCtrl:PackConvoyInfo()
    local iRefreshCost = mConvoyInfo["refresh_cost"]
    if not oPlayer:ValidGoldCoin(iRefreshCost) then
        return
    end

    local iTotalRefreshTime = oPlayer.m_oActiveCtrl:GetData("convoy_refresh",0)
    oPlayer.m_oActiveCtrl:SetData("convoy_refresh",iTotalRefreshTime+1)
    global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,"帝都宅急便中刷新次数",{value=1})
    
    local iCurLevel,iNewLevel = self:ReSelect(oPlayer,mConvoyInfo)
    record.user("convoy","refresh",{pid = oPlayer.m_iPid,cost = iRefreshCost,refresh_time = iTotalRefreshTime+1,oldlevel = iCurLevel,newlevel = iNewLevel})
end

function CHuodong:GetFreeRefreshTime(oPlayer)
    local sValue = res["daobiao"]["global"]["convoy_freerefresh"]["value"]
    local iValue = tonumber(sValue)
    local bMonthCard = oPlayer:IsMonthCardVip()
    local bZSCard = oPlayer:IsZskVip()
    iValue = iValue + (bMonthCard and 1 or 0) + (bZSCard and 2 or 0)
    return iValue
end

function CHuodong:GetRefreshCost(iTime)
    local sValue = res["daobiao"]["global"]["convoy_refreshcost"]["value"]
    local m = split_string(sValue,",")
    return m[iTime] or m[#m]
end

function CHuodong:ValidRefresh(oPlayer)
    local mConvoyInfo = oPlayer.m_oHuodongCtrl:PackConvoyInfo()
    local iSelectTarget = mConvoyInfo["selected_pos"] or 1
    local iMaxLevel = mConvoyInfo["pool_info"][iSelectTarget]["level"]
    for iPos,info in pairs(mConvoyInfo["pool_info"]) do
        if iMaxLevel < info.level then
            return true
        end
    end
    return false,1004
end

function CHuodong:ClickNpc(oPlayer)
    if self.m_mPlayer2Game[oPlayer.m_iPid] and not self.m_OnClick[oPlayer.m_iPid] then
        self.m_OnClick[oPlayer.m_iPid] = true
        local iGameID = self.m_mPlayer2Game[oPlayer.m_iPid]
        local oGame = self.m_mGame[iGameID]
        if oGame then
            if not oGame:ClickNpc() then
                self.m_OnClick[oPlayer.m_iPid] = false
            end
        else
            self.m_OnClick[oPlayer.m_iPid] = false
        end
    end
end

function NewGame(gid,mArgs)
    return CGame:New(gid,mArgs)
end

CGame = {}
CGame.__index = CGame
CGame.m_sName = "convoy"
inherit(CGame, datactrl.CDataCtrl)

function CGame:New(gid,mArgs)
    local o = super(CGame).New(self)
    o.m_ID = gid
    o:Init(mArgs)
    return o
end

function CGame:Init(mArgs)
    self.m_iPlayerID = mArgs.playerid
    self.m_iEndTime = mArgs.end_time
    self.m_iLevel = mArgs.level
    self.m_iTargetNpc = mArgs.targetnpc
    self.m_iPartnerID = mArgs.partnerid
end

function CGame:Save()
    local mData = {}
    mData.playerid = self.m_iPlayerID
    mData.end_time = self.m_iEndTime
    mData.level = self.m_iLevel
    mData.targetnpc = self.m_iTargetNpc
    mData.partnerid = self.m_iPartnerID
    return mData
end

function CGame:GetGameID()
    return self.m_ID
end

function CGame:GetPlayerID()
    return self.m_iPlayerID
end

function CGame:GetFightInterval()
    local sValue = res["daobiao"]["global"]["convoy_fightinterval"]["value"]
    local m = split_string(sValue,"-")
    local iMin,iMax = tonumber(m[1]),tonumber(m[2])
    return math.random(iMin,iMax)
end

function CGame:GameStart()
    local iGameTime = self.m_iEndTime - get_time()
    if iGameTime <= 0 then
        self:GameEnd("timeout")
        return
    end
    local iGameID = self.m_ID
    self:AddTimeCb("_GameEnd",iGameTime*1000,function()
        local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
        local oGame = oHuodong:GetGame(iGameID)
        if oGame then
            oGame:GameEnd("timeout")
        end
    end)
    self:NewFight()
end

function CGame:NewFight()
    local iGameID = self.m_ID
    local iTriggerFightTime = self:GetFightInterval()
    self:AddTimeCb("_TriggerFight",iTriggerFightTime*1000,function()
        local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
        local oGame = oHuodong:GetGame(iGameID)
        if oGame then
            oGame:TriggerFight()
        end
    end)
end

function CGame:WarEnd(bWin)
    self.m_iFight = nil
    if not bWin then
        self:GameEnd("warfailed")
    end
end

function CGame:GameEnd(sReason)
    local oHuodong = self:Huodong()
    if sReason == "warfailed" then
        global.oNotifyMgr:Notify(self.m_iPlayerID,oHuodong:GetTransText(1003))
    elseif sReason == "timeout" then
        global.oNotifyMgr:Notify(self.m_iPlayerID,oHuodong:GetTransText(1001))
    end
    record.user("convoy","failed",{pid = self.m_iPlayerID,reason = sReason})
    local oHuodong = self:Huodong()
    oHuodong:GameEnd(self,sReason)
end

function CGame:GameWin()
    local oHuodong = self:Huodong()
    oHuodong:GameWin(self)
end

function CGame:Release()
    self:DelTimeCb("_GameEnd")
    self:DelTimeCb("_TriggerFight")
end

function CGame:GetFight(iLevel)
    local mData = res["daobiao"]["huodong"][self.m_sName]["fight_pool"]
    for _,info in pairs(mData) do
        if info["level"] == iLevel and info["par_id"] == self.m_iPartnerID then
            return info["fight_pool"][math.random(#info["fight_pool"])]
        end
    end
    assert(mData,string.format("Not Convoy Fight Config:%s,%d,%d",self.m_sName,iLevel,self.m_iPartnerID))
end

function CGame:Huodong()
    return global.oHuodongMgr:GetHuodong("convoy")
end

function CGame:TriggerFight()
    self:DelTimeCb("_TriggerFight")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iPlayerID)
    if not oPlayer then
        self:NewFight()
        return
    end
    local iFight = self:GetFight(self.m_iLevel)
    self.m_iFight = iFight
    local oHuodong = self:Huodong()
    oHuodong:Fight(self.m_iPlayerID,nil,iFight,self.m_ID)
end

function CGame:ClickNpc()
    local oNpcMgr = global.oNpcMgr
    local oWorldMgr = global.oWorldMgr
    local oNpc = oNpcMgr:GetGlobalNpc(self.m_iTargetNpc)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iPlayerID)
    if self.m_iFight then
        return false
    end
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local mPosInfo = oPlayer.m_oActiveCtrl:GetNowPos()
    local iPmap = oNowScene:MapId()
    local iPposx,iPposy = mPosInfo.x,mPosInfo.y

    local iNmap = oNpc:MapId()
    mPosInfo = oNpc:PosInfo()
    local iNposx,iNposy = mPosInfo.x,mPosInfo.y
    if iNmap == iPmap and gamedefines.OverPosRange(iPposx,iPposy,iNposx,iNposy) then
        self:GameWin()
        return true
    else
        return false
    end
end

function CHuodong:OnChargeCard(oPlayer)
    local mConvoyInfo = oPlayer.m_oHuodongCtrl:PackConvoyInfo()
    local iFreeTime = self:GetFreeRefreshTime(oPlayer)
    if mConvoyInfo["refresh_time"] > iFreeTime then
        local iPayTime = mConvoyInfo["refresh_time"] - iFreeTime
        local iNextCost = self:GetRefreshCost(iPayTime)
        mConvoyInfo["refresh_cost"] = tonumber(iNextCost)
    else
        mConvoyInfo["free_time"] = iFreeTime - mConvoyInfo["refresh_time"]
    end
    oPlayer.m_oHuodongCtrl:UpdateConvoyInfo(mConvoyInfo)
end
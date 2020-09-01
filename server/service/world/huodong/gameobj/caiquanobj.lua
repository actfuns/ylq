--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"
local templ = import(service_path("templ"))
local caiquannpc = import(service_path("huodong/npcobj/caiquannpcobj"))
local loadtask = import(service_path("task/loadtask"))

CGame = {}
CGame.__index = CGame
CGame.m_sName = "game"
inherit(CGame, templ.CTempl)

function NewGame(mArgs)
    local o = CGame:New(mArgs)
    return o
end

function CGame:New(mArgs)
    local o = super(CGame).New(self)
    o.m_ID = mArgs.game_id
    o.m_iOwner = mArgs.owner
    o.m_mPlayerList = {}
    o.m_mNpcObj = {}
    o.m_Progress = 0
    o.m_SysName = mArgs.sys_name
    o.m_mExitGateInfo = mArgs.exit_gate
    o.m_iCreateTime = get_time()
    o.m_mReward = mArgs.reward
    o:Init()
    return o
end

function CGame:Init()
    super(CGame).Init(self)
end

function CGame:CountDown()
    local iTime = self:Timer()
    if iTime <= 0 then
        self:TimeOut()
        return
    end
    self:DelTimeCb("timeout")
    self:AddTimeCb("timeout",iTime, function()  self:TimeOut()  end)
end

function CGame:Timer()
    local iCurTime = get_time()
    local mConfig = self:GetGameConfig()
    local iLastTime = mConfig["time"]
    return ((iLastTime*1000) - (iCurTime - self.m_iCreateTime))
end

function CGame:TimeOut()
    self:DelTimeCb("timeout")
    if self.m_HasResult then
        return
    end
    self:OnGameEnd(false,"timeout")
end

function CGame:AddPlayer(iPid,iType)
    self.m_mPlayerList[iPid] = self.m_mPlayerList[iPid] or {}
    self.m_mPlayerList[iPid] = iType
end

function CGame:GetGameBaseData()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"]["treasure"]["legendconfig"]
    return mData
end

function CGame:InitGame()
    local mConfig = self:GetGameConfig()
    self.m_MapId = mConfig.scene_id
    self.m_SceneID = self:CreateHDScene(self.m_MapId)
    self.m_mNpcList = {}
    for _,iNpc in pairs(mConfig["npc_list"]) do
        local oNpc = self:CreateGameNpc(iNpc)
        self.m_mNpcList[oNpc.m_ID] = oNpc
    end
end

function CGame:GetNpcObj(iNpcId)
    return self.m_mNpcList[iNpcId]
end

function CGame:GetGameConfig()
    local iTotalPlayer = 0
    for iPid,iType in pairs(self.m_mPlayerList) do
        iTotalPlayer = iTotalPlayer + 1
    end
    local mBaseData = self:GetGameBaseData()
    local mConfig
    for _,config in pairs(mBaseData) do
        if config["mem_num"] == iTotalPlayer then
            mConfig = table_deep_copy(config)
            break
        end
    end
    assert(mConfig,string.format("not caiquan config,mem_num:%s",iTotalPlayer))
    return mConfig
end

function CGame:CreateGameNpc(iNpc)
    local mData = self:GetNpcData(iNpc)
    assert(mData,string.format("not NPC config,npcid:%s",iNpc))
    local oScene = self:SceneObject()
    local mModel = {
        shape = mData["modelId"],
        scale = mData["scale"],
        adorn = mData["ornamentId"],
        weapon = mData["wpmodel"],
        color = mData["mutateColor"],
        mutate_texture = mData["mutateTexture"],
    }
    local oSceneMgr = global.oSceneMgr
    local posx,posy = oSceneMgr:RandomPos(oScene:MapId())
    local mPosInfo = {
        x = posx,
        y = posy,
        z = mData["z"],
        face_x = mData["face_x"] or 0,
        face_y = mData["face_y"] or 0,
        face_z = mData["face_z"] or 0,
    }
    local mArgs = {
        type = mData["id"],
        sys_name = self.m_SysName,
        map_id = oScene:MapId(),
        model_info = mModel,
        pos_info = mPosInfo,
        event = mData["event"] or 0,
        reuse = mData["reuse"] or 0,
        dialogId = mData["dialogId"],
        game_id = self.m_ID
    }
    local oClientNpc = caiquannpc.NewClientNpc(mArgs)
    local oHuodong = self:Huodong()
    oHuodong:Npc_Enter_Scene(oClientNpc,oScene:GetSceneId(),mPosInfo)
    return oClientNpc
end

function CGame:GetNpcData(iNpc)
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"][self.m_SysName]["npc"]
    for _,info in pairs(mData) do
        if info["id"] == iNpc then
            return table_deep_copy(info)
        end
    end
    return false
end

function CGame:OnGameStart()
    self:InitGame()
    local oWorldMgr = global.oWorldMgr
    local oHuodong = self:Huodong()
    local mConfig = self:GetGameConfig()
    local iLastTime = mConfig["time"]
    for iPid,iType in pairs(self.m_mPlayerList) do
        local oTask = loadtask.LoadTask(5000,{})
        oTask:SetNpcInfo(table_deep_copy(self.m_mNpcList))
        oTask:SetTimer(iLastTime/60)
        oTask:SetGameId(self.m_ID)
        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oP.m_oTaskCtrl:AddHuodongTask(oTask)
        oP.m_oHuodongCtrl:AddGame("caiquan")
        oHuodong:TransferPlayerBySceneID(iPid,self.m_SceneID,0,0)
    end
    for iPid,iType in pairs(self.m_mPlayerList) do
        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
        local oTeam = oP:HasTeam()
        if oTeam then
            if not oTeam:IsLeader(iPid) then
                oTeam:ShortLeave(iPid)
            end
        end
    end
    local mNpc=table_key_list(self.m_mNpcList)
    record.user("treasure","caiquan_gamestart",{gameid=self.m_ID,player=ConvertTblToStr(self.m_mPlayerList),sceneid=self.m_SceneID,npcid_list=ConvertTblToStr(mNpc)})
    self:CountDown()
end

function CGame:CreateHDScene(iSc)
    local oHuodong = self:Huodong()
    local oScene = oHuodong:CreateVirtualScene(iSc)
    oScene.m_CaiquanGame = self.m_ID
    --oScene.m_OnLeave = OnLeaveScene
    oScene.m_NoTransfer = 1
    oScene.m_sType = "caiquan"
    oScene:SetLimitRule("transfer",1)
    oScene.m_fVaildEnter = VaildEnter
    oScene:SetClickTaskFunc(ClickTaskFunc)
    return oScene:GetSceneId()
end

function VaildEnter(oScene,oPlayer)
    local oTask = oPlayer.m_oTaskCtrl:HasTask(5000)
    local iGameID = oScene.m_CaiquanGame or 0
    if oTask and oTask.m_iGameID == iGameID then
        return true
    end
    return false
end

function ClickTaskFunc(oPlayer,iTask)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene.m_sType and oScene.m_sType == "caiquan" then
        local iGameID = oScene.m_CaiquanGame
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("game")
        local oGame = oHuodong:GetGame(iGameID)
        if oGame then
            oGame:ClickTask(oPlayer,iTask)
        end
    end
end

function CGame:ClickTask(oPlayer,iTask)
    local oCbMgr = global.oCbMgr
    local sContent = "需放弃传说伙伴任务才可传送出该副本地图\n是否放弃任务？"
    local mData = {
        sContent = sContent,
        sConfirm = "确认",
        sCancle = "取消",
        default = 0,
        time = 30,
    }
    local mData = oCbMgr:PackConfirmData(nil, mData)
    local func = function (oP,mData)
        local iAnswer = mData["answer"]
        if iAnswer == 1 then
            local oScene = oP.m_oActiveCtrl:GetNowScene()
            if oScene.m_sType and oScene.m_sType == "caiquan" then
                local iGameID = oScene.m_CaiquanGame
                local oHuodongMgr = global.oHuodongMgr
                local oHuodong = oHuodongMgr:GetHuodong("game")
                local oGame = oHuodong:GetGame(iGameID)
                if oGame then
                    oGame:AbandonGame(oP)
                    oP:Send("GS2CContinueClickTask",{taskid = iTask})
                end
            end
        end
    end
    oCbMgr:SetCallBack(oPlayer.m_iPid,"GS2CConfirmUI",mData,nil,func)
end

function CGame:AbandonGame(oPlayer)
    self.m_mPlayerList[oPlayer.m_iPid] = nil
    local oHuodong = self:Huodong()
    oHuodong:GobackRealScene(oPlayer.m_iPid)
    local oTask = oPlayer.m_oTaskCtrl:GetTask(5000)
    oPlayer.m_oTaskCtrl:RemoveTask(oTask)
    oPlayer.m_oHuodongCtrl:RemoveGame("caiquan")
end

function CGame:Huodong()
    local oHuodongMgr = global.oHuodongMgr
    return oHuodongMgr:GetHuodong("game")
end

function CGame:SceneObject()
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(self.m_SceneID)
    return oScene
end

function CGame:WinNpc(iNpcId)
    self.m_Progress = self.m_Progress + 1
    local oNpc = self.m_mNpcList[iNpcId]
    if oNpc then
        self.m_mNpcList[iNpcId] = nil
        local oHuodong = self:Huodong()
        oHuodong:RemoveTempNpc(oNpc,"被玩家打败")
    end
    self:SysnTaskInfo(iNpcId)
    if self:CheckHasAllWin() and not self.m_HasResult then
        self:OnGameEnd(true,"游戏胜利")
    end
end

function CGame:CheckHasAllWin()
    local bAllWin = true
    for _,oNpc in pairs(self.m_mNpcList) do
        bAllWin = false
        break
    end
    return bAllWin
end

function CGame:SysnTaskInfo(iNpcId)
    local oWorldMgr = global.oWorldMgr
    for iPid,iType in pairs(self.m_mPlayerList) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local oTask = oPlayer.m_oTaskCtrl:GetTask(5000)
            oTask:AddKillTime(iNpcId)
            oTask:RefreshTaskInfo()
        end
    end
end

function CGame:SetRewardInfo(mRewad)
    self.m_mReward = mRewad
end

function CGame:OnGameEnd(bWin,sReason)
    if bWin then
        self:GiveWinReward()
    else
        self:GiveFailReward()
    end
    self.m_HasResult = bWin
    local iResult = bWin and 1 or 0
    local oWorldMgr = global.oWorldMgr
    for iPid,iType in pairs(self.m_mPlayerList) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer:Send("GS2CCaiQuanGameEnd",{result = iResult})
    end
    self:DelTimeCb("timeout")
    self:AddTimeCb("gameend",3*1000, function()  self:AfterGameEnd()  end)
    record.user("treasure","caiquan_gameend",{gameid=self.m_ID,player=ConvertTblToStr(self.m_mPlayerList),sceneid=self.m_SceneID,result=iResult,reason=sReason})
end

function CGame:AfterGameEnd()
    self:DelTimeCb("gameend")
    self:ClearTask()
    self:ExitFB()
    self:ClearNpc()
    local oHuodong = self:Huodong()
    oHuodong:OnGameEnd(self.m_ID)
end

function CGame:GiveWinReward()
    local mRewardData = self.m_mReward
    assert(mRewardData,string.format("not caiquan reward config,%s",self.m_SysName))
    local mCreateorReward = mRewardData["win_creator"]["reward"]
    local mHelperReward = mRewardData["win_helper"]["reward"]
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    for iPid,iType in pairs(self.m_mPlayerList) do
        local sType = "win_creator"
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if iType == 1 then
            for _,idx in pairs(mCreateorReward) do
                oPlayer.m_oToday:Add("legendboy_triggertimes",1)
                self:Reward(iPid,idx)
                record.user("treasure","caiquan_reward",{gameid=self.m_ID,pid=iPid,playertype="获胜方发起者",rewardidx=idx,times=oPlayer.m_oToday:Query("legendboy_triggertimes",0)})
            end
        else
            sType = "win_joiner"
            local iHelpTimes = oPlayer.m_oToday:Query("legendboy_helptimes",0)
            local bCanReward = (iHelpTimes < 2)
            if (iHelpTimes >= 1) then
                oNotifyMgr:Notify(iPid,"你今天已进行过2次帮助，继续帮助不会再获取奖励")
                record.user("treasure","caiquan_reward",{gameid=self.m_ID,pid=iPid,playertype="获胜方参与者",rewardidx=0,times=iHelpTimes})
            end
            for _,idx in pairs(mHelperReward) do
                if oPlayer then
                    if bCanReward then
                        self:Reward(iPid,idx)
                        record.user("treasure","caiquan_reward",{gameid=self.m_ID,pid=iPid,playertype="获胜方参与者",rewardidx=idx,times=iHelpTimes})
                    end
                end
            end
            oPlayer.m_oToday:Add("legendboy_helptimes",1)
        end
        -- local mLog = {}
        -- mLog["type"] = "caiquan"
        -- mLog["subtype"] = sType
        self:LogAnalyGame("treasure",oPlayer)
    end
end

function CGame:GiveFailReward()
    local mRewardData = self.m_mReward
    assert(mRewardData,string.format("not caiquan reward config,%s",self.m_SysName))
    local mCreateorReward = mRewardData["failed_creator"]["reward"]
    local mHelperReward = mRewardData["failed_helper"]["reward"]
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    for iPid,iType in pairs(self.m_mPlayerList) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        local sType = "fail_creator"
        if iType == 1 then
            for _,idx in pairs(mCreateorReward) do
                record.user("treasure","caiquan_reward",{gameid=self.m_ID,pid=iPid,playertype="失败方发起者",rewardidx=idx,times=oPlayer.m_oToday:Query("legendboy_triggertimes",0)})
                self:Reward(iPid,idx)
            end
        else
            sType = "fail_joiner"
            local iHelpTimes = oPlayer.m_oToday:Query("legendboy_helptimes",0)
            local bCanReward = (iHelpTimes < 2)
            if (iHelpTimes >= 1) then
                oNotifyMgr:Notify(iPid,"你今天已进行过2次帮助，继续帮助不会再获取奖励")
                record.user("treasure","caiquan_reward",{gameid=self.m_ID,pid=iPid,playertype="失败方参与者",rewardidx=0,times=iHelpTimes})
            end
            for _,idx in pairs(mHelperReward) do
                if oPlayer then
                    if bCanReward then
                        self:Reward(iPid,idx)
                        record.user("treasure","caiquan_reward",{gameid=self.m_ID,pid=iPid,playertype="失败方参与者",rewardidx=idx,times=iHelpTimes})
                    end
                end
            end
            oPlayer.m_oToday:Add("legendboy_helptimes",1)
        end
        -- local mLog = {}
        -- mLog["type"] = "caiquan"
        -- mLog["subtype"] = sType
        self:LogAnalyGame("treasure",oPlayer)
    end
end

function CGame:ClearTask()
    local oWorldMgr = global.oWorldMgr
    for iPid,iType in pairs(self.m_mPlayerList) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        local oTask = oPlayer.m_oTaskCtrl:GetTask(5000)
        oPlayer.m_oTaskCtrl:RemoveTask(oTask)
    end
end

function CGame:ExitFB()
    local oWorldMgr = global.oWorldMgr
    local oHuodong = self:Huodong()
    for iPid,iType in pairs(self.m_mPlayerList) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oHuodong:GobackRealScene(iPid)
        oPlayer.m_oHuodongCtrl:RemoveGame("caiquan")
    end
end

function CGame:ClearNpc()
    local oHuodong = self:Huodong()
    local oScene = self:SceneObject()
    if not oScene then return end

    local oNpcMgr = global.oNpcMgr
    for iNpc, _ in pairs(oScene.m_mNpc) do
        local oNpc = oHuodong:GetNpcObj(iNpc)
        if oNpc then
            oNpc:ClearSession()
            oHuodong:RemoveTempNpc(oNpc,"游戏结束")
        end
    end
end
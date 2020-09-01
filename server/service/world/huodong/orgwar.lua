--import module
local skynet = require "skynet"
local global  = require "global"
local record = require "public.record"
local interactive = require "base.interactive"

local netteam = import(service_path("netcmd.team"))
local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

RED_CAMP = 1    --红方
BLUE_CAMP = 2   --蓝方

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "orgwar"
CHuodong.m_sTempName = "公会战"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:Init()
    self.m_Shizhe = nil
    self.m_Camp = {}                        --阵营
    self.m_Enemy = {}                      --敌对公会
    self.m_MatchOrg = {}                 --公会对战表
    self.m_mPrepareScene = {}       --准备场景
    self.m_mFightScene = {}             --正式场景
    self.m_mOrgNpc = {}                  --公会水晶
    self.m_mPreNpc = {}
    self.m_mQueue = {}

    self.m_mOrgInfo = {}
    self.m_mOrgJoin = {}

    self.m_iStartTime = nil
    self.m_iEndTime = nil
    self.m_iScheduleID = 2005
    self.m_GameState = 0
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iWeekDay == 7 and iHour == 19 then
        self:AddTimeCb("StartOrgWar",45 * 60 * 1000,function ()
            self:DelTimeCb("StartOrgWar")
            self:StartOrgWar()
        end)
    elseif iWeekDay == 7 and iHour == 20 then
        self:GameStart2()
    elseif iWeekDay == 7 and iHour == 21 then
        self:JudgeAllMatchWinner(1)
    end
end

function CHuodong:FastenOrg(oPlayer)
    local iOrgID = oPlayer:GetOrgID()
    oPlayer.m_oThisTemp:Set("OrgID",iOrgID,5400)
end

function CHuodong:OrgID(oPlayer)
    return oPlayer.m_oThisTemp:Query("OrgID",0)
end

function CHuodong:OnLogin(oPlayer)
    local iOrgID = self:OrgID(oPlayer)

    if self:IsOpen() then
        self:GS2COrgWarTip(oPlayer)
        if iOrgID ~= 0 and self.m_Camp[iOrgID] then
            local iPreScene = self.m_mPrepareScene[iOrgID]
            local iFightScene = self.m_mFightScene[iOrgID]
            if oPlayer.m_oActiveCtrl:GetNowSceneID() == iPreScene then
                oPlayer:Send("GS2COrgWarEnterSc",{type=1})
                oPlayer:PropChange("camp")
            elseif oPlayer.m_oActiveCtrl:GetNowSceneID() == iFightScene then
                oPlayer:Send("GS2COrgWarEnterSc",{type=2})
                oPlayer:PropChange("camp")
                self:GS2COrgWarUI(oPlayer)
            end
            local iEnemyTeamID = self.m_Enemy[iOrgID]
            local iTeamID = oPlayer:TeamID()
            if iTeamID then
                if self:InQueueTeam(iOrgID,iTeamID,"defend") then
                    oPlayer:Send("GS2COrgWarState",{state=2})
                end
                if self:InQueueTeam(iEnemyTeamID,iTeamID,"attack") then
                    oPlayer:Send("GS2COrgWarState",{state=1})
                end
            end
            local iTime = oPlayer.m_oThisTemp:Query("org_failtime")
            if  iTime then
                oPlayer:Send("GS2COrgWarRevive",{end_time=iTime+3*60})
            end
        end
    end
end

function CHuodong:StartOrgWar()
    interactive.Request(".org", "common", "StartOrgWar", {}, function (mRecord,mData)
        if self:IsOpen() then
            return
        end
        local mOrgList =mData.data or {}
        self:GameStart(mOrgList)
    end)
end

function CHuodong:EndOrgWar()
    interactive.Send(".org", "common", "EndOrgWar", {})
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_OVER)
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

function CHuodong:InitTime()
    local tbl = get_hourtime({hour=1})
    self.m_iStartTime = tbl.time
    self.m_iEndTime = tbl.time + 3600
end

function CHuodong:EnterJoin(iOrgID,iPid)
    local mOrgJoin = self.m_mOrgJoin or {}
    mOrgJoin[iOrgID] = mOrgJoin[iOrgID] or {}
    if not mOrgJoin[iOrgID][iPid] then
        local oAchieveMgr = global.oAchieveMgr
        oAchieveMgr:PushAchieve(iPid,"参与公会战次数",{value=1})
    end
    mOrgJoin[iOrgID][iPid] = true
    self.m_mOrgJoin = mOrgJoin
end

function CHuodong:GameStart(mOrgList)
    if #mOrgList < 2 then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:SendPrioritySysChat("orgwar_char",self:GetTextData(1002),1)
        return
    end
    self:InitOrgData(mOrgList)
    self:DivideCamp(mOrgList)
    self:CreateHDScene()
    self:NotifyOrgWarNameList()
    self:SetGameState(1)
    self:InitTime()
    self:GS2COrgWarTip()

    local oShiZhe = self:CreateTempNpc(50001)
    self:Npc_Enter_Map(oShiZhe,101000,oShiZhe:PosInfo())
    self.m_Shizhe = oShiZhe

    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendPrioritySysChat("orgwar_char",self:GetTextData(1003),1)
end

function CHuodong:GameStart2()
    if not self:IsOpen() then
        return
    end
    self:SetGameState(2)
    self:CheckSubOrgHp()
    local mMatchOrg = self.m_MatchOrg or {}
    for _,mUnit in ipairs(mMatchOrg) do
        local iOrgID1,iOrgID2 = table.unpack(mUnit)
        local iActive1,iActive2 = self:GetBothActive(iOrgID1,iOrgID2)
        local sJudgeFlag = "NoOneExist"
        local iWinOrgID
        if iActive1 > iActive2 then
            iWinOrgID = iOrgID1
        else
            iWinOrgID = iOrgID2
        end
        sJudgeFlag = sJudgeFlag .. iWinOrgID
        self:DelTimeCb(sJudgeFlag)
        self:AddTimeCb(sJudgeFlag,5*60*1000,function ()
            self:FinnalWin(iWinOrgID)
        end)
    end
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_START)
    local oWorldMgr = global.oWorldMgr
    local mPrepareScene = self.m_mPrepareScene or {}
    for _,iSceneID in pairs(mPrepareScene) do
        local oScene = self:GetHDScene(iSceneID)
        if oScene then
            local mPlayer = oScene:GetPlayers()
            for _,iPid in pairs(mPlayer) do
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer and oPlayer:HasTeam() and oPlayer:IsTeamLeader() then
                    self:EnterGame(oPlayer,self.m_Shizhe)
                elseif oPlayer and oPlayer:IsSingle() then
                    self:EnterGame(oPlayer,self.m_Shizhe)
                end
            end
        end
    end
end

function CHuodong:CheckSubOrgHp()
    self:DelTimeCb("CheckSubOrgHp")
    self:AddTimeCb("CheckSubOrgHp",1000,function ()
        self:CheckSubOrgHp()
    end)
    local mQueue = self.m_mQueue or {}
    local mCamp = self.m_Camp or {}

    for iOrgID,_ in pairs(mCamp) do
        local mAttack = mQueue[iOrgID] or {}
        mAttack = mAttack["attack"] or {}
        local iHasJuge = self:GetOrgInfo(iOrgID,"win")
        if not iHasJuge and next(mAttack) then
            local iHp = self:GetOrgInfo(iOrgID,"hp") - 1
            self:SetOrgInfo(iOrgID,"hp",iHp)
            if iHp % 50 == 0 then
                self:NoticeOrg(iOrgID,iHp)
            end
        end
    end
end

function CHuodong:NoticeOrg(iOrgID,iHp)
    local sOrgFlag = "PersonNum"..iOrgID
    self:DelTimeCb(sOrgFlag)
    self:AddTimeCb(sOrgFlag,3000,function ()
        self:GS2COrgWarUI(nil,iOrgID)
    end)

    local iEnemyOrg = self.m_Enemy[iOrgID]
    local oChatMgr = global.oChatMgr
    if iHp % 50 == 0 then
        local sText = self:GetTextData(1026)
        sText = string.gsub(sText,"$hp",iHp)
        oChatMgr:SendMsg2Org(sText,iOrgID)
    end
    if iHp % 100 == 0 then
        local sEnemyText = self:GetTextData(1027)
        sEnemyText = string.gsub(sEnemyText,"$hp",iHp)
        oChatMgr:SendMsg2Org(sEnemyText,iEnemyOrg)
    end
    if iHp <= 0 then
        self:FinnalWin(iEnemyOrg)
    end
end

function CHuodong:InitOrgData(mOrgList)
    local mOrgInfo = self.m_mOrgInfo or {}
    for _,mUnit in pairs(mOrgList) do
        mOrgInfo[mUnit.id] = {
            active = mUnit.active,
            name = mUnit.name,
            hp = 1000,
        }
    end
end

function CHuodong:SetOrgInfo(iOrgID,sAttr,Val)
    self.m_mOrgInfo[iOrgID][sAttr] = Val
end

function CHuodong:GetOrgInfo(iOrgID,sAttr)
    return self.m_mOrgInfo[iOrgID][sAttr]
end

function CHuodong:GetOrgName(iOrgID)
    if self.m_mOrgInfo[iOrgID] then
        return self.m_mOrgInfo[iOrgID].name
    end
end

function CHuodong:DivideCamp(mOrgList)
    for iTurn=1,#mOrgList,2 do
        local iRn = math.random(2)-1
        local iNo1 = iTurn + iRn
        local iNo2 = iTurn + (1-iRn)
        local iOrgID1 = mOrgList[iNo1].id
        local iOrgID2 = mOrgList[iNo2].id
        if not iOrgID1 or not iOrgID2 then
            break
        end
        self.m_Camp[iOrgID1] = RED_CAMP
        self.m_Camp[iOrgID2] = BLUE_CAMP
        self.m_Enemy[iOrgID1] = iOrgID2
        self.m_Enemy[iOrgID2] = iOrgID1
        table.insert(self.m_MatchOrg,{iOrgID1,iOrgID2})
        record.user("orgwar", "divide", {orgid1=iOrgID1,orgid2=iOrgID2})
    end
end

function CHuodong:CreateHDScene(iCnt)
    local mMatchOrg = self.m_MatchOrg or {}
    for _,mUnit in ipairs(mMatchOrg) do
        local iOrgID1,iOrgID2 = table.unpack(mUnit)
        if not iOrgID1 or not iOrgID2 then
            break
        end

        local oPreScene = self:CreateVirtualScene(1026)
        oPreScene:SetLimitRule("transfer",1)
        oPreScene:SetLimitRule("bantitle",1)
        oPreScene:SetLimitRule("shortleave",1)
        oPreScene:SetLimitRule("banautoteam",1)
        oPreScene.m_PreOnEnter = HDProxy("OnEnterPreScene")
        oPreScene.m_OnLeave = HDProxy("OnLeavePreScene")
        oPreScene.m_InviteTeam = HDProxy("OnInviteTeam")
        oPreScene.m_TeamApply = HDProxy("OnTeamApply")
        oPreScene.m_ApplyTeamPass = HDProxy("OnTeamApplyPass")
        oPreScene.m_InvitePass = HDProxy("OnInvitePass")
        oPreScene.m_BackTeam = HDProxy("OnBackTeam")
        oPreScene.m_IsOrgWar = true
        self.m_mPrepareScene[iOrgID1] = oPreScene:GetSceneId()
        self.m_mPrepareScene[iOrgID2] = oPreScene:GetSceneId()
        local oPreNpc = self:CreateTempNpc(50004)
        self:Npc_Enter_Scene(oPreNpc, oPreScene:GetSceneId(), oPreNpc:PosInfo())
        self.m_mPreNpc[iOrgID1] = oPreNpc.m_ID
        self.m_mPreNpc[iOrgID2] = oPreNpc.m_ID

        local oFightScene = self:CreateVirtualScene(1027)
        oFightScene:SetLimitRule("transfer",1)
        oFightScene:SetLimitRule("bantitle",1)
        oFightScene:SetLimitRule("shortleave",1)
        oFightScene:SetLimitRule("banautoteam",1)
        oFightScene:SetLimitRule("bantakeleader",1)
        oFightScene.m_PreOnEnter = HDProxy("OnEnterFightScene")
        oFightScene.m_OnLeave = HDProxy("OnLeaveFightScene")
        oFightScene.m_InviteTeam = HDProxy("OnInviteTeam")
        oFightScene.m_TeamApply = HDProxy("OnTeamApply")
        oFightScene.m_ApplyTeamPass = HDProxy("OnTeamApplyPass")
        oFightScene.m_InvitePass = HDProxy("OnInvitePass")
        oFightScene.m_BackTeam = HDProxy("OnBackTeam")
        oFightScene.m_IsOrgWar = true
        self.m_mFightScene[iOrgID1] = oFightScene:GetSceneId()
        self.m_mFightScene[iOrgID2] = oFightScene:GetSceneId()

        local oRedNpc = self:CreateTempNpc(50002)
        local oBlueNpc = self:CreateTempNpc(50003)
        oRedNpc.m_OrgID = iOrgID1
        oBlueNpc.m_OrgID = iOrgID2
        oRedNpc.m_ShowMode = 2
        oBlueNpc.m_ShowMode = 3

        oRedNpc.m_sTitle = string.gsub(oRedNpc.m_sTitle,"$orgname",self:GetOrgInfo(iOrgID1,"name"))
        oBlueNpc.m_sTitle = string.gsub(oBlueNpc.m_sTitle,"$orgname",self:GetOrgInfo(iOrgID2,"name"))

        self:Npc_Enter_Scene(oRedNpc, oFightScene:GetSceneId(), oRedNpc:PosInfo())
        self:Npc_Enter_Scene(oBlueNpc, oFightScene:GetSceneId(), oBlueNpc:PosInfo())

        self.m_mOrgNpc[iOrgID1] = oRedNpc.m_ID
        self.m_mOrgNpc[iOrgID2] = oBlueNpc.m_ID
    end
end

function CHuodong:NotifyOrgWarNameList()
    local sMsg = "本次公会战对战名单如下：\n"
    local mMatchOrg = self.m_MatchOrg or {}
    for _,mUnit in pairs(mMatchOrg) do
        local iOrgID1,iOrgID2 = table.unpack(mUnit)
        local sOrgName1,sOrgName2 = self:GetOrgInfo(iOrgID1,"name"),self:GetOrgInfo(iOrgID2,"name")
        sMsg = sMsg .. "[FF7633]"..sOrgName1.."[FD614C] VS [FF7633]"..sOrgName2.. "\n"
    end
    global.oChatMgr:SendWOrldChat(nil,sMsg)
end

function CHuodong:GameOver()
    self:SetGameState(0)
    self:EndOrgWar()

    self:ClearAllCaChe()
    self:ClearAllNpc()
    self:ClearAllScene()
end

function CHuodong:ClearAllCaChe()
    self.m_Shizhe = nil
    self.m_Camp = {}
    self.m_Enemy = {}
    self.m_MatchOrg = {}
    self.m_mPrepareScene = {}
    self.m_mFightScene = {}
    self.m_mOrgInfo = {}
    self.m_iStartTime = nil
    self.m_iEndTime = nil
    self.m_mOrgJoin = {}
    self.m_mQueue = {}
end

function CHuodong:ClearAllNpc()
    local mNpcList = table_key_list(self.m_mNpcList)
    for _,npcid in pairs(mNpcList) do
        self:RemoveTempNpcById(npcid)
    end
end

function CHuodong:ClearAllScene()
    local mSceneList = table_key_list(self.m_mSceneList)
    for _,iSceneID in pairs(mSceneList) do
        self:RemoveSceneById(iSceneID)
    end
end

function CHuodong:OtherScript(iPid,npcobj,sEvent,mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if sEvent == "$entergame" then
        self:EnterGame(oPlayer,npcobj)
    elseif sEvent == "$entergame2" then
        local iGameState = self:GetGameState()
        if iGameState ~= 2 then
            self:SayText(iPid,npcobj,self:GetTextData(1047))
            return
        end
        self:EnterGame(oPlayer,npcobj)
    elseif sEvent == "$orglist" then
        self:GS2COrgWarList(oPlayer)
    elseif sEvent == "$looksj" then
        local iOrgID = oPlayer:GetOrgID()
        local sText,iHp
        if iOrgID ~= npcobj.m_OrgID then
            local iEnemyOrg = self.m_Enemy[iOrgID]
            iHp = self:GetOrgInfo(iEnemyOrg,"hp")
            sText = self:GetTextData(1020)
        else
            iHp = self:GetOrgInfo(iOrgID,"hp")
            sText = self:GetTextData(1019)
        end
        sText = string.gsub(sText,"$hp",iHp)
        self:SayText(iPid,npcobj,sText)
    elseif sEvent == "$join" then
        local iOrgID = oPlayer:GetOrgID()
        if iOrgID ~= npcobj.m_OrgID then
            if not oPlayer:HasTeam() or oPlayer:GetTeamMemberSize() < 2 then
                npcobj:Say(oPlayer:GetPid(),self:GetTextData(1023))
                return
            end
            self:AttackOrg(oPlayer)
            oPlayer:NotifyMessage("你正在进攻敌方守护水晶")
        else
            if not oPlayer:HasTeam() or oPlayer:GetTeamMemberSize() < 2 then
                npcobj:Say(oPlayer:GetPid(),self:GetTextData(1022))
                return
            end
            self:DefendOrg(oPlayer)
            oPlayer:NotifyMessage("你正在防守我方守护水晶")
        end
    elseif sEvent == "$leave" then
        self:LeaveOrgWar(oPlayer)
    elseif sEvent == "$lookshizhe" then
        local iOrgID = oPlayer:GetOrgID()

        if self.m_Camp[iOrgID] and self:GetOrgInfo(iOrgID,"win") then
            self:SayText(iPid,npcobj,"公会战已结束&T对战信息")
            return
        end

        local iCnt = oPlayer.m_oToday:Query("org_war_cnt",0)
        local sText = self:GetTextData(1004)
        sText = sText .. "\n【剩余战败次数："..math.max(0,3-iCnt).."】&T对战列表&T公会战进场"
        self:SayText(iPid,npcobj,sText)
    end
end

function CHuodong:EnterQueue(iOrgID,iTeamID,sType)
    local mQueue = self.m_mQueue
    mQueue[iOrgID] = mQueue[iOrgID] or {}
    mQueue[iOrgID][sType] = mQueue[iOrgID][sType] or {}
    mQueue[iOrgID][sType][iTeamID] = true
end

function CHuodong:ClearQueue(iOrgID,iTeamID,sType)
    local mQueue = self.m_mQueue or {}
    mQueue[iOrgID] = mQueue[iOrgID] or {}
    mQueue[iOrgID][sType] = mQueue[iOrgID][sType] or {}
    mQueue[iOrgID][sType][iTeamID] = nil
end

function CHuodong:GetQueueTeam(iOrgID,sType)
    local mQueue = self.m_mQueue or {}
    mQueue[iOrgID] = mQueue[iOrgID] or {}
    mQueue[iOrgID][sType] = mQueue[iOrgID][sType] or {}
    return next(mQueue[iOrgID][sType])
end

function CHuodong:InQueueTeam(iOrgID,iTeamID,sType)
    local mQueue = self.m_mQueue or {}
    mQueue[iOrgID] = mQueue[iOrgID] or {}
    mQueue[iOrgID][sType] = mQueue[iOrgID][sType] or {}
    return mQueue[iOrgID][sType][iTeamID]
end

function CHuodong:OnLeaveTeam(oTeam,oPlayer)
    local iOrgID = oPlayer:GetOrgID()
    local iEnemyOrg =  self.m_Enemy[iOrgID]
    oPlayer:Send("GS2COrgWarState",{state=3})
    if not iOrgID and not iEnemyOrg then
        return
    end

    if oTeam:MemberSize() < 2 then
        local iTeamID = oTeam:TeamID()
        if self:InQueueTeam(iOrgID,iTeamID,"defend") then
            oTeam:NotifyAllMem("人数变动，队伍取消防守状态")
        end
        if self:InQueueTeam(iEnemyOrg,iTeamID,"attack") then
            oTeam:NotifyAllMem("人数变动，队伍取消攻击状态")
        end
        local mMem = oTeam:GetTeamMember()
        for _,mid in pairs(mMem) do
            local oMem = global.oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem then
                oMem:Send("GS2COrgWarState",{state=3})
            end
        end
    end
end

function CHuodong:RegisterTeamFunc(iTeamID,iState)
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    oTeam:RegisterFunc("leave","orgwar",function (oTeam,pid)
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            self:OnLeaveTeam(oTeam,oPlayer)
        end
    end)
    local mMem = oTeam:GetTeamMember()
    for _,mid in pairs(mMem) do
        local oMem = global.oWorldMgr:GetOnlinePlayerByPid(mid)
        if oMem then
            oMem:Send("GS2COrgWarState",{state=iState})
        end
    end
end

function CHuodong:CanCelTeamFunc(iTeamID)
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    if oTeam then
        oTeam:CancelRegisterFunc("leave","orgwar")
        local mMem = oTeam:GetTeamMember()
        for _,mid in pairs(mMem) do
            local oMem = global.oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem then
                oMem:Send("GS2COrgWarState",{state=3})
            end
        end
    end
end

function CHuodong:AttackOrg(oPlayer)
    local iOrgID = oPlayer:GetOrgID()
    local iEnemyOrg = self.m_Enemy[iOrgID]
    if not iEnemyOrg then return end

    local iTeamID = oPlayer:TeamID()
    local iEnemyTeamID = self:GetQueueTeam(iEnemyOrg,"defend")
    if iEnemyTeamID then
        self:ClearQueue(iEnemyOrg,iEnemyTeamID,"defend")
        self:CanCelTeamFunc(iEnemyTeamID)
        local oWorldMgr = global.oWorldMgr
        local oTeamMgr = global.oTeamMgr
        local oEnemyTeam = oTeamMgr:GetTeam(iEnemyTeamID)
        local iTarget = oEnemyTeam:Leader()
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        self:CreatePvPWar(oPlayer,oTarget,true)
    else
        self:RegisterTeamFunc(iTeamID,1)
        self:EnterQueue(iEnemyOrg,iTeamID,"attack")
        local mMem = oPlayer:GetTeamMember() or {}
        for _,mid in pairs(mMem) do
            local oMem = global.oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem then
                oMem:AddSchedule("orgwar")
            end
            self:EnterJoin(iOrgID,mid)
        end
    end
end

function CHuodong:DefendOrg(oPlayer)
    local iOrgID = oPlayer:GetOrgID()

    local iTeamID = oPlayer:TeamID()
    local iEnemyTeamID = self:GetQueueTeam(iOrgID,"attack")
    if iEnemyTeamID then
        self:ClearQueue(iOrgID,iEnemyTeamID,"attack")
        self:CanCelTeamFunc(iEnemyTeamID)
        local oWorldMgr = global.oWorldMgr
        local oTeamMgr = global.oTeamMgr
        local oEnemyTeam = oTeamMgr:GetTeam(iEnemyTeamID)
        local iTarget = oEnemyTeam:Leader()
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        self:CreatePvPWar(oTarget,oPlayer,true)
    else
        self:RegisterTeamFunc(iTeamID,2)
        self:EnterQueue(iOrgID,iTeamID,"defend")
    end
end


function CHuodong:LeaveOrgWar(oPlayer)
    local oCbMgr = global.oCbMgr
    local sContent = "是否需要离开战场？"
    local mData = {
        sContent = sContent,
        sConfirm = "是",
        sCancle = "否",
        default = 0,
        time = 10,
    }
    local mData = oCbMgr:PackConfirmData(nil, mData)
    local func = function (oP,mData)
        local iAnswer = mData["answer"]
        if iAnswer == 1 then
            self:GobackRealScene(oP:GetPid())
        end
    end
    oCbMgr:SetCallBack(oPlayer:GetPid(),"GS2CConfirmUI",mData,nil,func)
end

function CHuodong:GS2COrgWarList(oPlayer)
    local mNet = {list={}}
    local mMatchOrg = self.m_MatchOrg or {}
    for _,mUnit in ipairs(mMatchOrg) do
        local iOrgID1,iOrgID2 = table.unpack(mUnit)
        local iWinOrgID
        if self:GetOrgInfo(iOrgID1,"win") == 1 then
            iWinOrgID = iOrgID1
        elseif self:GetOrgInfo(iOrgID2,"win") == 1 then
            iWinOrgID = iOrgID2
        end
        table.insert(mNet.list,{
            orgid1 = iOrgID1,
            orgid2 = iOrgID2,
            name1 = self:GetOrgInfo(iOrgID1,"name"),
            name2 = self:GetOrgInfo(iOrgID2,"name"),
            winid = iWinOrgID,
        })
    end
    oPlayer:Send("GS2COrgWarList",mNet)
end

function CHuodong:GS2COrgWarTip(oPlayer)
    local mNet = {
        starttime = self.m_iStartTime,
        endtime = self.m_iEndTime,
    }
    if oPlayer then
        oPlayer:Send("GS2COrgWarTip",mNet)
    else
        local mData = {
            message = "GS2COrgWarTip",
            type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
            id = 1,
            data = mNet,
            exclude = {}
        }
        interactive.Send(".broadcast","channel","SendChannel",mData)
    end
end

function CHuodong:C2GSOrgWarGuide(oPlayer)
    local oNpc = self.m_Shizhe
    if not oNpc then return end

    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene.m_IsOrgWar then
        oPlayer:NotifyMessage("您已在公会战场景中")
        return
    end

    local oSceneMgr = global.oSceneMgr
    local mPos = oNpc:PosInfo()
    oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),oNpc.m_iMapid,mPos.x,mPos.y,oNpc.m_ID,1,1)
end

function CHuodong:C2GSOrgWarCanCelState(oPlayer,iState)
    local iOrgID = oPlayer:GetOrgID()
    local iEnemyOrg = self.m_Enemy[iOrgID]
    local oTeam = oPlayer:HasTeam()
    local iTeamID = oPlayer:TeamID()

    if oTeam and self:InQueueTeam(iOrgID,iTeamID,"defend") then
        self:ClearQueue(iOrgID,iTeamID,"defend")
        oTeam:NotifyAllMem("取消队伍防守状态")
    end

    if oTeam and self:InQueueTeam(iEnemyOrg,iTeamID,"attack") then
        self:ClearQueue(iEnemyOrg,iTeamID,"attack")
        oTeam:NotifyAllMem("取消队伍攻击状态")
    end

    if oTeam then
        local mMem = oTeam:GetTeamMember()
        for _,mid in pairs(mMem) do
            local oMem = global.oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem then
                oMem:Send("GS2COrgWarState",{state=3})
            end
        end
    end

end

function CHuodong:C2GSOrgWarOption(oPlayer,iCmd)
    local iOrgID = oPlayer:GetOrgID()
    local iSceneID = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local oSceneMgr = global.oSceneMgr
    if iSceneID == self.m_mPrepareScene[iOrgID] then
        local npcid = self.m_mPreNpc[iOrgID]
        if not npcid then return end
        local oNpc = self:GetNpcObj(npcid)
        local mPos = oNpc:PosInfo()
        oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),oNpc.m_iMapid,mPos.x,mPos.y,oNpc.m_ID,1,1)
    elseif iSceneID == self.m_mFightScene[iOrgID] then
        if iCmd == 1 then
            iOrgID = self.m_Enemy[iOrgID]
        end
        local npcid = self.m_mOrgNpc[iOrgID]
        if not npcid then return end
        local oNpc = self:GetNpcObj(npcid)
        local mPos = oNpc:PosInfo()
        oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),oNpc.m_iMapid,mPos.x,mPos.y,oNpc.m_ID,1,1)
    end
end

function CHuodong:C2GSOrgWarPK(oPlayer,iTarget)
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oTarget:GetNowWar() then
        oPlayer:NotifyMessage(self:GetTextData(1016))
        return
    end
    if not oPlayer:HasTeam() or oPlayer:GetTeamMemberSize() < 2 then
        oPlayer:NotifyMessage(self:GetTextData(1017))
        return
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        return
    end
    local iOrgID = oPlayer:GetOrgID()
    local iEnemyOrg = oTarget:GetOrgID()
    if iOrgID == iEnemyOrg then
        return
    end
    local iTeamID = oPlayer:TeamID()
    if iTeamID then
        self:ClearQueue(iOrgID,iTeamID,"defend")
        self:ClearQueue(iEnemyOrg,iTeamID,"attack")
    end
    local iEnemyTeamID = oTarget:TeamID()
    if iEnemyTeamID then
        self:ClearQueue(iOrgID,iEnemyTeamID,"attack")
        self:ClearQueue(iEnemyOrg,iEnemyTeamID,"defend")
    end
    self:CreatePvPWar(oPlayer,oWorldMgr:GetOnlinePlayerByPid(iTarget))
end

function CHuodong:CheckJoinPlayer(oPlayer)
    local iPid = oPlayer:GetPid()
    local oOrgMgr = global.oOrgMgr

    local iNowTime = get_time()
    local iJoinTime = oOrgMgr:GetPlayerOrgInfo(oPlayer:GetPid(),"jointime",0)
    local sText
    if not self.m_BanJoinTime then
        if iNowTime - iJoinTime < 3600*24 then
            sText = self:GetTextData(1005)
            if oPlayer:HasTeam() then
                sText = self:GetTextData(1036)
            end
            return false,sText
        end
    end

    if oPlayer:GetGrade() < 20 then
        sText = self:GetTextData(1006)
        if oPlayer:HasTeam() then
            sText = self:GetTextData(1037)
        end
        return false,sText
    end

    local iFailTime = oPlayer.m_oThisTemp:Query("org_failtime",0)
    local iRestTime = 180 - (iNowTime - iFailTime)
    if iRestTime > 0 then
        sText = self:GetTextData(1010)
        if oPlayer:HasTeam() then
            sText = self:GetTextData(1038)
        end
        sText = string.gsub(sText,"$time",get_second2string(iRestTime))
        return false,sText
    end

    local iCnt = oPlayer.m_oToday:Query("org_war_cnt",0)
    if iCnt >= 3 then
        sText = self:GetTextData(1011)
        if oPlayer:HasTeam() then
            sText = self:GetTextData(1039)
        end
        return false,sText
    end
    return true
end

function CHuodong:ValidEnter(oPlayer,oNpc)
    local iOrgID = oPlayer:GetOrgID()
    if not iOrgID or iOrgID == 0 then
        oNpc:Say(oPlayer:GetPid(),"您没有公会，无法参加公会战")
        return false
    end
    if not self.m_Camp[iOrgID] then
        oNpc:Say(oPlayer:GetPid(),self:GetTextData(1043))
        return false
    end
    local oWorldMgr = global.oWorldMgr
    if oPlayer:HasTeam() then
        if not oPlayer:IsTeamLeader() then
            oNpc:Say(oPlayer:GetPid(),"队伍中，只有队长可以操作")
            return false
        end
        local memlist = oPlayer:GetTeamMember()
        local sTip = ""
        for _,mid in pairs(memlist) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem and oMem:GetOrgID() ~= iOrgID then
                oNpc:Say(oPlayer:GetPid(),self:GetTextData(1009))
                return false
            end
            local bSuc,sMsg = self:CheckJoinPlayer(oMem)
            if not bSuc then
                sMsg = string.gsub(sMsg,"$username",oMem:GetName())
                sTip = sTip .. sMsg .. "\n"
            end
        end
        if sTip ~= "" then
            for _,mid in pairs(memlist) do
                oNpc:Say(mid,sTip)
            end
            return false
        end
    else
        local bSuc,sMsg = self:CheckJoinPlayer(oPlayer)
        if not bSuc then
            oNpc:Say(oPlayer:GetPid(),sMsg)
            return false
        end
    end
    return true
end

function CHuodong:ForceChangeTitle(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oTitleMgr = global.oTitleMgr
    local memlist = oPlayer:GetTeamMember() or {oPlayer:GetPid()}
    local lTidList = {1077,1078,1079,1080,1081}
    for _,mid in pairs(memlist) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
        if oMem then
            self:FastenOrg(oMem)
            for _,iTid in pairs(lTidList) do
                if oMem:GetTitle(iTid) then
                    oTitleMgr:UseTitle(oMem, iTid)
                    break
                end
            end
        end
    end
end

function CHuodong:BackPreScene(oPlayer)
    local iOrgID = oPlayer:GetOrgID()
    local iSceneID = self.m_mPrepareScene[iOrgID]
    local iX,iY = math.random(8,15),math.random(6,10)
    if iSceneID then
        self:TransferPlayerBySceneID(oPlayer:GetPid(),iSceneID,iX,iY)
    end
end

function CHuodong:EnterGame(oPlayer,npcobj)
    if not self:ValidEnter(oPlayer,npcobj) then
        return
    end
    local iOrgID = oPlayer:GetOrgID()
    local iGameState = self:GetGameState()
    local iSceneID,iX,iY

    if iGameState == 1 then
        iSceneID = self.m_mPrepareScene[iOrgID]
        iX,iY = math.random(8,15),math.random(6,10)
    elseif iGameState == 2 then
        iSceneID = self.m_mFightScene[iOrgID]
        local iCamp = self.m_Camp[iOrgID]
        local PosList
        if iCamp == 1 then
            PosList = {{3.7,21}}
        elseif iCamp == 2 then
            PosList = {{28.5,5}}
        end
        iX,iY = table.unpack(PosList[math.random(#PosList)])
    end

    self:CancelAutoTeam(oPlayer)

    if iSceneID then
        self:ForceChangeTitle(oPlayer)
        self:TransferPlayerBySceneID(oPlayer:GetPid(),iSceneID,iX,iY)
    end
end

function CHuodong:CancelAutoTeam(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        oTeam:CancleAutoMatch()
    end

    local iTargetID = oPlayer.m_oActiveCtrl:GetInfo("auto_targetid")
    if iTargetID then
        interactive.Send(".autoteam", "team", "CanclePlayerAutoMatch", {targetid = iTargetID, pid = oPlayer:GetPid()})
        oPlayer:SetAutoMatching(nil)
    end
end

function CHuodong:OnInviteTeam(oPlayer,oTarget)
    local iScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local iScene2 = oTarget.m_oActiveCtrl:GetNowSceneID()
    if iScene ~= iScene2 then
        oPlayer:NotifyMessage("对方不在公会战中")
        return false
    end
    if oPlayer:GetOrgID() ~= oTarget:GetOrgID() then
        oPlayer:NotifyMessage(self:GetTextData(1012))
        return false
    end
    return true
end

function CHuodong:OnTeamApplyPass(oPlayer,oTarget)
    local iScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local iScene2 = oTarget.m_oActiveCtrl:GetNowSceneID()
    if iScene ~= iScene2 then
        oPlayer:NotifyMessage("对方不在公会战中")
        return false
    end
    if oPlayer:GetOrgID() ~= oTarget:GetOrgID() then
        oPlayer:NotifyMessage(self:GetTextData(1012))
        return false
    end
    return true
end

function CHuodong:OnTeamApply(oPlayer,oTarget)
    local iScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local iScene2 = oTarget.m_oActiveCtrl:GetNowSceneID()
    if iScene ~= iScene2 then
        oPlayer:NotifyMessage(self:GetTextData(1015))
        return false
    end
    if oPlayer:GetOrgID() ~= oTarget:GetOrgID() then
        oPlayer:NotifyMessage(self:GetTextData(1013))
        return false
    end
    return true
end

function CHuodong:OnInvitePass(oPlayer,oTarget)
    local iScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local iScene2 = oTarget.m_oActiveCtrl:GetNowSceneID()
    if iScene ~= iScene2 then
        oPlayer:NotifyMessage(self:GetTextData(1015))
        return false
    end
    if oPlayer:GetOrgID() ~= oTarget:GetOrgID() then
        oPlayer:NotifyMessage(self:GetTextData(1013))
        return false
    end
    if oPlayer:GetNowWar() then
        oPlayer:NotifyMessage(self:GetTextData(1046))
        return false
    end
    return true
end

function CHuodong:OnBackTeam(oPlayer)
    local iScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local oTeam = oPlayer:HasTeam()
    local iTarget = oTeam:Leader()
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    local iScene2 = oTarget.m_oActiveCtrl:GetNowSceneID()
    if iScene ~= iScene2 then
        oPlayer:NotifyMessage("你与队长不在同一场景")
        return false
    end
    if oPlayer:GetOrgID() ~= oTarget:GetOrgID() then
        oPlayer:NotifyMessage(self:GetTextData(1013))
        return false
    end
    return true
end

function CHuodong:OnEnterPreScene(oScene,oPlayer)
    oPlayer:Send("GS2COrgWarEnterSc",{type=1})
    local iOrgID = self:OrgID(oPlayer)
    local iCamp = self.m_Camp[iOrgID] or 0
    oPlayer.m_oThisTemp:Set("camp",iCamp,3600)
    oPlayer:SyncSceneInfo({camp=iCamp})
    oPlayer:PropChange("camp")
end

function CHuodong:OnLeavePreScene(oScene,oPlayer)
    oPlayer:Send("GS2COrgWarLeaveSc",{type=1})
    oPlayer.m_oThisTemp:Delete("camp")
    oPlayer:SyncSceneInfo({camp=0})
    oPlayer:PropChange("camp")
end

function CHuodong:OnEnterFightScene(oScene,oPlayer)
    oPlayer:Send("GS2COrgWarEnterSc",{type=2})

    local iOrgID = self:OrgID(oPlayer)
    local iEnemyOrg = self.m_Enemy[iOrgID]
    local iCamp = self.m_Camp[iOrgID] or 0
    oPlayer.m_oThisTemp:Set("camp",iCamp,3600)
    oPlayer:SyncSceneInfo({camp=iCamp})
    oPlayer:PropChange("camp")

    local sOrgFlag = "PersonNum"..iOrgID
    oScene[sOrgFlag] = oScene[sOrgFlag] or 0
    oScene[sOrgFlag] = oScene[sOrgFlag] + 1
    self:DelTimeCb(sOrgFlag)
    self:AddTimeCb(sOrgFlag,3000,function ()
        self:GS2COrgWarUI(nil,iOrgID)
    end)
    self:GS2COrgWarUI(oPlayer)

    local sJudgeFlag = "NoOneExist"..iEnemyOrg
    self:DelTimeCb(sJudgeFlag)
end

function CHuodong:OnLeaveFightScene(oScene,oPlayer)
    oPlayer:Send("GS2COrgWarLeaveSc",{type=2})

    oPlayer.m_oThisTemp:Delete("camp")
    oPlayer:SyncSceneInfo({camp=0})
    oPlayer:PropChange("camp")

    if oPlayer:IsTeamLeader() then
        self:CanCelTeamFunc(oPlayer:TeamID())
    end

    local iOrgID = oPlayer:GetOrgID()
    local iEnemyOrg = self.m_Enemy[iOrgID]

    local sOrgFlag = "PersonNum"..iOrgID
    oScene[sOrgFlag] = oScene[sOrgFlag] or 0
    oScene[sOrgFlag] = math.max(oScene[sOrgFlag] - 1,0)
    self:DelTimeCb(sOrgFlag)
    self:AddTimeCb(sOrgFlag,3000,function ()
        self:GS2COrgWarUI(nil,iOrgID)
    end)
    if oScene[sOrgFlag] <= 0 and iEnemyOrg then
        local sJudgeFlag = "NoOneExist"..iEnemyOrg
        self:DelTimeCb(sJudgeFlag)
        self:AddTimeCb(sJudgeFlag,5*60*1000,function ()
            self:FinnalWin(iEnemyOrg)
        end)
    end
end

function CHuodong:GS2COrgWarUI(oPlayer,iOrgID)
    if oPlayer then
        iOrgID = oPlayer:GetOrgID()
    end

    if not iOrgID then return end

    local iEnemyOrg = self.m_Enemy[iOrgID]
    if not iEnemyOrg then return end

    local npcid = self.m_mOrgNpc[iOrgID]
    local oNpc = self:GetNpcObj(npcid)

    local npcid2 = self.m_mOrgNpc[iEnemyOrg]
    local oEnemyNpc = self:GetNpcObj(npcid2)

    local iSceneID = self.m_mFightScene[iOrgID]
    local oScene = self:GetHDScene(iSceneID)

    local sOrgFlag = "PersonNum"..iOrgID
    local sEnemyOrgFlag = "PersonNum"..iEnemyOrg
    local my = {defend=oScene[sOrgFlag] or 0,hp=self:GetOrgInfo(iOrgID,"hp")}
    local enemy = {defend=oScene[sEnemyOrgFlag] or 0,hp=self:GetOrgInfo(iEnemyOrg,"hp")}

    if oPlayer then
        oPlayer:Send("GS2COrgWarUI",{my=my,enemy=enemy})
    else
        self:SendOrgChannel(iOrgID,"GS2COrgWarUI",{my=my,enemy=enemy})
        self:SendOrgChannel(iEnemyOrg,"GS2COrgWarUI",{my=enemy,enemy=my})
    end
end

function CHuodong:SendOrgChannel(iOrgID,sMessage,mNet)
    interactive.Send(".broadcast", "channel", "SendChannel", {
        message = sMessage,
        id = iOrgID,
        type = gamedefines.BROADCAST_TYPE.ORG_TYPE,
        data = mNet,
    })
end

function CHuodong:CreatePvPWar(oPlayer,oTarget,bPopSay)
    local iOrgID = oTarget:GetOrgID()
    local mArg = {
        remote_war_type="orgwar",
        war_type = gamedefines.WAR_TYPE.ORG_WAR_TYPE,
        pvpflag = 1,
    }
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:CreateWar(mArg)
    oWar:SetData("close_auto_skill",true)
    oWar.m_AttackOrg = iOrgID
    oWar.m_PopSay = bPopSay

    local iWarID = oWar:GetWarId()
    local mArg = {camp_id = 1,}
    if oPlayer:IsSingle() then
        oWarMgr:EnterWar(oPlayer, iWarID, mArg, true)
    else
        oWarMgr:TeamEnterWar(oPlayer, iWarID, mArg, true)
    end

    local mArg = {camp_id = 2,}
    if oTarget:IsSingle() then
        oWarMgr:EnterWar(oTarget, iWarID, mArg, true)
    else
        oWarMgr:TeamEnterWar(oTarget, iWarID, mArg, true)
    end

    oWarMgr:SetWarEndCallback(iWarID,function (mArg)
        local oWar = oWarMgr:GetWar(iWarID)
        self:OnPVPWarEnd(oWar,mArg)
    end)
    oWarMgr:SetEscapeCallBack(iWarID,function (mInfo)
           self:OnEscape(mInfo)
    end)
    oWarMgr:StartWarConfig(iWarID)

    local mMem = oPlayer:GetTeamMember() or {}
    local iOrgID = oPlayer:GetOrgID()
    for _,mid in pairs(mMem) do
        self:EnterJoin(iOrgID,mid)
    end

    mMem = oTarget:GetTeamMember() or {}
    iOrgID = oTarget:GetOrgID()
    for _,mid in pairs(mMem) do
        self:EnterJoin(iOrgID,mid)
    end

    local mem1 = oPlayer:GetTeamMember() or {oPlayer:GetPid()}
    local mem2 = oTarget:GetTeamMember() or {oTarget:GetPid()}

    record.user("orgwar", "enterwar", {mem1= ConvertTblToStr(mem1) , mem2 = ConvertTblToStr(mem2)})
end

function CHuodong:OnPVPWarEnd(oWar,mArg)
    local mWin = mArg.win_list or {}
    local mFail = mArg.fail_list or {}
    local oWinPlayer,oFailPlayer
    local oWorldMgr = global.oWorldMgr
    local iOrgID = oWar.m_AttackOrg
    local bPopSay = oWar.m_PopSay
    local iHasJuge = self:GetOrgInfo(iOrgID,"win")

    local iWinOrgID
    local sWinName = ""
    local sFailName,iFailCnt = "",0


    for _,mid in pairs(mWin) do
        oWinPlayer = oWorldMgr:GetOnlinePlayerByPid(mid)
        if oWinPlayer then
            oWinPlayer:AddSchedule("orgwar")
        end
        if not iHasJuge and oWinPlayer and oWinPlayer:IsTeamLeader() and bPopSay then
            local npcid = self.m_mOrgNpc[iOrgID]
            local oNpc = self:GetNpcObj(npcid)
            if oNpc then
                self:do_look(oWinPlayer,oNpc)
            end
        end
        if oWinPlayer then
            iWinOrgID = oWinPlayer:GetOrgID()
            if sWinName ~= "" then
                sWinName = sWinName .. "、"
            end
            sWinName = sWinName ..oWinPlayer:GetName()
            self:Reward(mid,1001)
            if oWinPlayer.m_oToday:Query("OrgWarCnt",0) < 3 then
                oWinPlayer.m_oToday:Add("OrgWarCnt",1)
                record.user("orgwar", "warcnt", {pid = mid , cnt = oWinPlayer.m_oToday:Query("OrgWarCnt",0)})
                for iRw=1002,1003 do
                    self:Reward(mid,iRw)
                end
            end
            if #mFail > 1 then
                local oAchieveMgr = global.oAchieveMgr
                oAchieveMgr:PushAchieve(mid,"公会战击败对方队伍次数",{value=1})
            end
        end
    end

    local iReviceTime = get_time()

    for _,mid in pairs(mFail) do
        oFailPlayer = oWorldMgr:GetOnlinePlayerByPid(mid)
        if oFailPlayer then
            oFailPlayer:AddSchedule("orgwar")
            oFailPlayer:Send("GS2COrgWarRevive",{end_time=iReviceTime+3*60})
        end
        if oFailPlayer and oFailPlayer:IsTeamLeader() then
            self:BackPreScene(oFailPlayer)
        elseif oFailPlayer and oFailPlayer:IsSingle() then
            self:BackPreScene(oFailPlayer)
        end
        if not iHasJuge and oFailPlayer then
            oFailPlayer.m_oThisTemp:Set("org_failtime",get_time(),180)
            oFailPlayer.m_oToday:Add("org_war_cnt",1)
            local iCnt = oFailPlayer.m_oToday:Query("org_war_cnt")
            local sText = self:GetTextData(1018)
            sText = string.gsub(sText,"$cnt",math.max(0,3-iCnt))
            oFailPlayer:NotifyMessage(sText)
            if sFailName ~= "" then
                sFailName = sFailName .. "、"
            end
            sFailName = sFailName ..oFailPlayer:GetName()
            iFailCnt = iFailCnt + 1
            self:Reward(mid,2001)
            if oFailPlayer.m_oToday:Query("OrgWarCnt",0) < 3 then
                oFailPlayer.m_oToday:Add("OrgWarCnt",1)
                record.user("orgwar", "warcnt", { pid = mid , cnt = oFailPlayer.m_oToday:Query("OrgWarCnt",0)})
                for iRw=2002,2003 do
                    self:Reward(mid,iRw)
                end
            end
        end
    end
    if not iHasJuge and iWinOrgID and iFailCnt > 0 then
        local sMsg = self:GetTextData(1028)
        sMsg = string.gsub(sMsg,"$teamname1",sWinName)
        sMsg = string.gsub(sMsg,"$teamname2",sFailName)
        sMsg = string.gsub(sMsg,"$cnt",iFailCnt)
        local oChatMgr = global.oChatMgr
        oChatMgr:SendMsg2Org(sMsg,iWinOrgID)
    end
end

function CHuodong:OnEscape(mInfo)
    local pid = mInfo.pid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer and oPlayer:HasTeam() then
        netteam.C2GSLeaveTeam(oPlayer)
    end
    if oPlayer then
        local iReviceTime = get_time()
        oPlayer.m_oThisTemp:Set("org_failtime",iReviceTime,180)
        oPlayer:Send("GS2COrgWarRevive",{end_time=iReviceTime+3*60})
        oPlayer.m_oToday:Add("org_war_cnt",1)
        self:BackPreScene(oPlayer)
    end
end

function CHuodong:FinnalWin(iOrgID)
    if not self.m_Camp[iOrgID] then
        return
    end
    local iHasJuge = self:GetOrgInfo(iOrgID,"win")
    if iHasJuge then
        return
    end
    local iEnemyOrg = self.m_Enemy[iOrgID]

    self:SetOrgInfo(iOrgID,"win",1)
    self:SetOrgInfo(iEnemyOrg,"win",0)

    self:StopAllWar(iOrgID)
    self:KickOutAll(iOrgID)

    local sText = self:GetTextData(1029)
    local sEnemyText = self:GetTextData(1030)

    local oChatMgr = global.oChatMgr
    oChatMgr:SendMsg2Org(sText,iOrgID)
    oChatMgr:SendMsg2Org(sEnemyText,iEnemyOrg)

    local oNotifyMgr = global.oNotifyMgr
    local sFinal = self:GetTextData(1035)
    sFinal = string.gsub(sFinal,"$camp1",self:GetOrgInfo(iOrgID,"name"))
    sFinal = string.gsub(sFinal,"$camp2",self:GetOrgInfo(iEnemyOrg,"name"))
    oNotifyMgr:SendPrioritySysChat("orgwar_char",sFinal,1)

    self:RewardOrg(iOrgID,iEnemyOrg)
    local mOrgJoin = self.m_mOrgJoin or {}
    local mPidList = mOrgJoin[iOrgID] or {}
    self:RewardMail(mPidList)
    record.user("orgwar", "judge", { winid = iOrgID , failid = iEnemyOrg })

    self:PushOrgWarAchieve(iOrgID)
end

function CHuodong:PushOrgWarAchieve(iWinID)
    local iFailID = self.m_Enemy[iWinID]
    if not iFailID then return end

    local mOrgJoin = self.m_mOrgJoin or {}
    local mWinList = mOrgJoin[iWinID] or {}
    local mFailList = mOrgJoin[iFailID] or {}
    local oAchieveMgr = global.oAchieveMgr
    for iPid,_ in pairs(mWinList) do
        oAchieveMgr:PushAchieve(iPid,"公会战胜利次数",{value=1})
    end
end

function CHuodong:RewardOrg(iWinID,iFailID)
    local oChatMgr = global.oChatMgr
    local mWinData = self:GetRewardData(3001)
    local mFailData = self:GetRewardData(4001)

    local iCash = mWinData.orgcash
    local iSw = mWinData.orgsw
    local iExp = mWinData.orgexp
    interactive.Send(".org", "common", "OrgWarReward", {
        orgid = iWinID , cash = iCash , prestige = iSw , exp = iExp , reason = "公会战胜利"
    })
    local sText = self:GetTextData(1044)
    sText = string.gsub(sText,"$cash",iCash)
    sText = string.gsub(sText,"$sw",iSw)
    sText = string.gsub(sText,"$exp",iExp)
    oChatMgr:SendMsg2Org(sText,iWinID)

    iCash = mFailData.orgcash
    iSw = mFailData.orgsw
    iExp = mFailData.orgexp
    interactive.Send(".org", "common", "OrgWarReward", {
        orgid = iFailID , cash = iCash , prestige = iSw , exp = iExp , reason = "公会战失败"
    })

    local sText = self:GetTextData(1045)
    sText = string.gsub(sText,"$cash",iCash)
    sText = string.gsub(sText,"$sw",iSw)
    sText = string.gsub(sText,"$exp",iExp)
    oChatMgr:SendMsg2Org(sText,iFailID)
end

function CHuodong:StopAllWar(iOrgID)
    local iSceneID = self.m_mFightScene[iOrgID]
    local oScene = self:GetHDScene(iSceneID)
    local oWorldMgr = global.oWorldMgr
    if oScene then
        local mPlayer = oScene:GetPlayers()
        for _,iPid in pairs(mPlayer) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer and oPlayer:GetOrgID() == iOrgID then
                local oWar = oPlayer:GetNowWar()
                if oWar and (oPlayer:IsTeamLeader() or oPlayer:IsSingle())then
                    oWar:TestCmd("warend",iPid,{
                        war_result = oWar:GetCampId(iPid)
                    })
                end
            end
        end
    end
end

function CHuodong:KickOutAll(iOrgID)
    local iSceneID = self.m_mFightScene[iOrgID]
    local iSceneID2 = self.m_mPrepareScene[iOrgID]
    local oScene = self:GetHDScene(iSceneID)
    local oScene2 = self:GetHDScene(iSceneID2)
    self:KickOutAll2(oScene,iOrgID)
    self:KickOutAll2(oScene2,iOrgID)
end

function CHuodong:KickOutAll2(oScene,iOrgID)
    local oWorldMgr = global.oWorldMgr
    if oScene then
        local mPlayer = oScene:GetPlayers()
        for _,iPid in pairs(mPlayer) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                if oPlayer:IsTeamLeader() or oPlayer:IsSingle() then
                    self:GobackRealScene(iPid)
                end
                if oPlayer:GetOrgID() == iOrgID then
                    oPlayer:NotifyMessage(self:GetTextData(1040))
                else
                    oPlayer:NotifyMessage(self:GetTextData(1041))
                end
            end
        end
    end
end

function CHuodong:JudgeAllMatchWinner(iNo)
    if not self:IsOpen() then
        return
    end
    self:DelTimeCb("JudgeAllMatchWinner")

    local mMatchOrg = self.m_MatchOrg or {}
    for iIdx=iNo,#mMatchOrg do
        local iOrgID1,iOrgID2 = table.unpack(mMatchOrg[iIdx])
        local iHasJuge = self:GetOrgInfo(iOrgID1,"win")
        if not iHasJuge then
            self:AddTimeCb("JudgeAllMatchWinner",5000,function ()
                self:JudgeAllMatchWinner(iIdx+1)
            end)
            self:JudgeWinner(iOrgID1,iOrgID2)
            return
        end
    end

    self:GameOver()
end

function CHuodong:GetBothActive(iOrgID1,iOrgID2)
    return self:GetOrgInfo(iOrgID1,"active"),self:GetOrgInfo(iOrgID2,"active")
end

function CHuodong:GetBothHp(iOrgID1,iOrgID2)
    return self:GetOrgInfo(iOrgID1,"hp"),self:GetOrgInfo(iOrgID2,"hp")
end

function CHuodong:GetBothNum(iOrgID1,iOrgID2)
    local iSceneID = self.m_mFightScene[iOrgID1]
    local oScene = self:GetHDScene(iSceneID)
    local oWorldMgr = global.oWorldMgr
    local iCnt1,iCnt2 = 0,0
    if oScene then
        local mPlayer = oScene:GetPlayers()
        for _,iPid in pairs(mPlayer) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer and oPlayer:GetOrgID() == iOrgID1 then
                iCnt1 = iCnt1 + 1
            elseif oPlayer and oPlayer:GetOrgID() == iOrgID2 then
                iCnt2 = iCnt2 + 1
            end
        end
    end
    return iCnt1,iCnt2
end

function CHuodong:JudgeWinner(iOrgID1,iOrgID2)
    local mFunc = {"GetBothHp","GetBothNum","GetBothActive"}
    for _,sFunc in ipairs(mFunc) do
        local func = self[sFunc]
        local iNum1,iNum2 = func(self,iOrgID1,iOrgID2)
        if iNum1 > iNum2 then
            self:FinnalWin(iOrgID1)
            return
        elseif iNum1 < iNum2 then
            self:FinnalWin(iOrgID2)
            return
        end
    end
    if math.random(2) == 1 then
        self:FinnalWin(iOrgID1)
    else
        self:FinnalWin(iOrgID2)
    end
end

function CHuodong:RewardMail(mPidList)
    if table_count(mPidList) <= 0 then
        return
    end

    local mItem = {}
    for iNo=3001,3003 do
        local mReward = self:GetItemRewardData(iNo)
        mReward = mReward[1]
        for _,info in pairs(mReward) do
            for _,oItem in pairs(self:BuildRewardItemList(info,info["sid"],{})) do
                table.insert(mItem,oItem)
            end
        end
    end
    local oMailMgr = global.oMailMgr
    local mData, name = oMailMgr:GetMailInfo(73)
    for iPid,_ in pairs(mPidList) do
        oMailMgr:SendMail(0, name, iPid, mData, {}, mItem)
    end
end

function CHuodong:TestOP(oPlayer,iFlag,...)
    if iFlag == 100 then
        local oChatMgr = global.oChatMgr
        oChatMgr:HandleMsgChat(oPlayer,"101-活动预备")
        oChatMgr:HandleMsgChat(oPlayer,"102-活动开始")
        oChatMgr:HandleMsgChat(oPlayer,"103-活动结束 判定输赢　　每５秒判定一次")
        oChatMgr:HandleMsgChat(oPlayer,"104-回主城")
        oChatMgr:HandleMsgChat(oPlayer,"105-判定自己公会胜利")
        oChatMgr:HandleMsgChat(oPlayer,"108-取消进入公会时间限制")
        oChatMgr:HandleMsgChat(oPlayer,"109-打开进入公会时间限制")
    elseif iFlag == 101 then
        self:StartOrgWar()
    elseif iFlag == 102 then
        self:GameStart2()
    elseif iFlag == 103 then
        self:JudgeAllMatchWinner(1)
    elseif iFlag == 104 then
        self:GobackRealScene(oPlayer:GetPid())
    elseif iFlag == 105 then
        self:FinnalWin(oPlayer:GetOrgID())
    elseif iFlag == 106 then
        self:RewardMail({oPlayer:GetPid()})
    elseif iFlag == 107 then
        self:Reward(oPlayer:GetPid(),1001)
    elseif iFlag == 108 then
        self.m_BanJoinTime = 1
    elseif iFlag == 109 then
        self.m_BanJoinTime = nil
    elseif iFlag == 110 then
        oPlayer:Send("GS2COrgWarRevive",{end_time=get_time()+3*60})
        self:BackPreScene(oPlayer)
    elseif iFlag == 111 then
        oPlayer.m_oThisTemp:Delete("org_failtime")
    end
end

function HDProxy(sFunName)
    local oHuodong = global.oHuodongMgr:GetHuodong("orgwar")
    local f = function (...)
        local func = oHuodong[sFunName]
        if func then
            return func(oHuodong,...)
        end
    end
    return f
end
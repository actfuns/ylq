--import module
local global  = require "global"
local extend = require "base.extend"
local res = require "base.res"
local extend = require "base.extend"
local record = require "public.record"
local interactive = require "base.interactive"

local huodongbase = import(service_path("huodong.huodongbase"))
local gamedefines = import(lualib_path("public.gamedefines"))
local MINGLEI_FIGHTTIME = 10
local MINGLEI_BUYTIME = 2
local MINGLEI_BUYCOST = 200
local gsub = string.gsub

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "明雷"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_iScheduleID = 1006
    self:TryStartRewardMonitor()
end

function CHuodong:NewHour(iWeekDay, iHour)
    self:RefreshMonster()
    if iHour == 0 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
    end
end

function CHuodong:CheckAnswer(oPlayer, npcobj, iAnswer)
    if iAnswer ~= 1 then
        return false
    end
    if npcobj:InWar() then
        local sText = self:GetTextData(1003)
        self:SayText(oPlayer:GetPid(),npcobj,sText)
        return false
    end
    if oPlayer.m_oActiveCtrl:GetNowWar() then
        return false
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        if oPlayer:GetGrade() < 30 then
            local sText = self:GetTextData(1002)
            sText = string.gsub(sText,"$name",{["$name"] = oPlayer:GetName()})
            self:SayText(oPlayer:GetPid(),npcobj,sText)
            return false
        end
    else
        local oWorldMgr = global.oWorldMgr
        local lName = {}
        for _,pid in ipairs(oTeam:GetTeamMember()) do
            local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
            if pobj and pobj:GetGrade() < 30 then
                table.insert(lName, pobj:GetName())
            end
        end
        if next(lName) then
            local sText = self:GetTextData(1002)
            sText = string.gsub(sText,"$name", table.concat(lName, "、"))
            for _,pid in ipairs(oTeam:GetTeamMember()) do
                self:SayText(pid,npcobj,sText)
            end
            return false
        end
    end
    return true
end

function CHuodong:GetNpcBaseData()
    local mData = res["daobiao"]["huodong"][self.m_sName]["npc"]
    return mData
end

function CHuodong:GetNpcData(iNpc)
    local mData = self:GetNpcBaseData()
    for _,info in pairs(mData) do
        if info["id"] == iNpc then
            return table_deep_copy(info)
        end
    end
    return false
end

function CHuodong:GetRefreshMonsterAmount()
    local oWorldMgr = global.oWorldMgr
    local iOnlinePlayer = oWorldMgr:OnlineAmount()
    if iOnlinePlayer <= 100 then
        return 20
    end
    return (math.min(math.floor((iOnlinePlayer-100)/20) ,10) + 20)
end

function CHuodong:RandomNpc(iMapId)
    local mData = res["daobiao"]["huodong"][self.m_sName]["config_npc"][iMapId]
    assert(mData,"miss config of minglei map:"..iMapId)
    local iRandom = math.random(100)
    local iWeight = 0
    if (iWeight + mData[1]["ratio"]) >= iRandom then
        local iIndex = math.random(#mData[1]["npc_pool"])
        return mData[1]["npc_pool"][iIndex]
    else
        iWeight = iWeight + mData[1]["ratio"]
        if (iWeight + mData[2]["ratio"]) >= iRandom then
            local iIndex = math.random(#mData[2]["npc_pool"])
            return mData[2]["npc_pool"][iIndex]
        else
            local iIndex = math.random(#mData[3]["npc_pool"])
            return mData[3]["npc_pool"][iIndex]
        end
    end
end

function CHuodong:RefreshMonster()
    self:ClearLastHourMonster()
    local bOpen = res["daobiao"]["global_control"]["minglei"]["is_open"]
    if bOpen ~= "y" then
        return
    end

    local iMapGroup = tonumber(res["daobiao"]["global"]["minglei_scene_group"]["value"])
    local mMapId = self:RamdomSceneId(iMapGroup)
    self.m_mCurMap = mMapId
    local iRefreshAmount = self:GetRefreshMonsterAmount()
    local iMapNum = #mMapId
    local oSceneMgr = global.oSceneMgr
    for _, iMapId  in ipairs(mMapId) do
        local mScene = oSceneMgr:GetSceneListByMap(iMapId)
        for _, oScene in ipairs(mScene) do
            local iScene = oScene:GetSceneId()
            local num = math.ceil((iRefreshAmount/(#mMapId)))
            local mPos = oSceneMgr:RandomMonsterPos(iMapId,num)
            for i=1,num do
                local idx = self:RandomNpc(iMapId)
                local x, y = table.unpack(mPos[i])
                local mPosInfo = {
                    x = x or 0,
                    y = y or 0,
                    z = 0,
                    face_x = 0,
                    face_y = 0,
                    face_z = 0,
                }
                local oNpc = self:CreateTempNpc(idx)
                self:Npc_Enter_Scene(oNpc, iScene, mPosInfo)
            end
        end
    end
    local sMsg = "茶会又开始啦，快去野外寻找各方贵宾吧（2人以上组队挑战）！"
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendPrioritySysChat("minglei_start",sMsg, 1)
    
    self:BroadCastMingleiRefresh()
end

function CHuodong:BroadCastMingleiRefresh()
    local mData = {
        message = "GS2CRefreshMinglei",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = {},
        exclude = {},
    }
    interactive.Send(".broadcast", "channel", "SendChannel", mData)
end

function CHuodong:RamdomSceneId(iGroupId)
    local res = require "base.res"
    local mMapList = {}
    if res["daobiao"]["scenegroup"][iGroupId] then
        mMapList = res["daobiao"]["scenegroup"][iGroupId]
    else
        return {101000}
    end
    mMapList = table_deep_copy(mMapList["maplist"])
    local t  = #mMapList
    local m = {}
    for k = 1,t do
        local n = math.random(#mMapList)
        m[k] = mMapList[n]
        table.remove(mMapList,n)
    end
    return m
end

function CHuodong:DoScript2(pid,npcobj,s,mArgs)
    super(CHuodong).DoScript2(self,pid,npcobj,s,mArgs)
    if string.sub(s,1,3) == "MLF" then
        local iType = mArgs["type"] or 1
        self:StartMingLeiFight(pid,npcobj,iType)
    elseif string.sub(s,1,2) == "CT" then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        oPlayer:Send("GS2CGetMingleiTeam",{})
    elseif string.sub(s,1,5) == "ENTER" then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        self:_DoFightScript2(oPlayer,npcobj)
    elseif string.sub(s,1,5) == "BUY" then
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
        local iBuyTime = MINGLEI_BUYTIME - oPlayer.m_oToday:Query("minglei_buytime",0)
        if iBuyTime <= 0 then
            global.oNotifyMgr:Notify(oPlayer.m_iPid,"今天购买次数已满")
            return
        end
        self:ShowBuyTimeWnd(oPlayer)
    elseif string.sub(s,1,7) == "ClickML" then
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
        self:ClickMinglei(oPlayer,npcobj)
    end
end

function CHuodong:GetDialogBaseData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["dialog"]
    assert(mData,string.format("Not Dialog Config:%s",self.m_sName))
    return mData
end

function CHuodong:GetMLFightData()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["fight"] or {}
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
        ["content"] = self:TransString(oPlayer,oNpc,mDialogInfo["content"]),
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
                local obj = oHuodong:GetNpcObj(iNpcId)
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

function CHuodong:StartMingLeiFight(iPid,oNpc,iType)
    local oNotifyMgr = global.oNotifyMgr
    if oNpc._release then
        oNotifyMgr:Notify(iPid,"很遗憾，小萌已经被其他玩家收服了")
        return
    end
    if oNpc:InWar() then
        self:DoScript2(iPid,oNpc,"DI200")
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam or oTeam:IsShortLeave(iPid) then
        oNotifyMgr:Notify(iPid,"挑战至少需要2人以上")
        --self:_DoFightScript1(oPlayer,oNpc)
        return
    else
        if not oTeam:IsLeader(iPid) then
            oNotifyMgr:Notify(iPid,"让你们的队长来见我")
            return
        end
        if oTeam:MemberSize() < 2 then
            oNotifyMgr:Notify(iPid,"挑战至少需要2人以上")
            return
        end
        local bValid,sInvalidMem = self:ValidTeamEnter(oPlayer)
        if not bValid then
            oNotifyMgr:Notify(iPid,"所有成员已无挑战次数，请购买后再挑战")
            return
        end
        bValid,sInvalidMem = self:ValidMemGrade(oPlayer)
        if bValid then
            self:_DoFightScript4(oPlayer,oNpc,iType)
        else
            oNotifyMgr:Notify(iPid,string.format("%s等级不足",sInvalidMem))
            return
        end
    end
end

function CHuodong:ValidTeamEnter(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if not oTeam or oTeam:IsShortLeave(oPlayer.m_iPid) then
        return true
    end
    local oNotifyMgr = global.oNotifyMgr
    local mMem = oTeam:GetTeamMember()
    local s = ""
    local bValid = false
    for i = 1,#mMem do
        local oWorldMgr = global.oWorldMgr
        local oMem = oWorldMgr:GetOnlinePlayerByPid(mMem[i])
        if not self:HasEnterTime(mMem[i]) then
            s = (i==#mMem) and (s..oMem:GetName()) or (s..oMem:GetName().."、")
            if oMem.m_oToday:Query("minglei_buytime",0) <MINGLEI_BUYTIME then
                local iBuyTime = MINGLEI_BUYTIME - oMem.m_oToday:Query("minglei_buytime",0)
                oNotifyMgr:Notify(mMem[i],string.format("邀请次数已使用完，无法继续获得奖励，今日还可购买%d邀请次数。",iBuyTime))
                self:ShowBuyTimeWnd(oMem)
            else
                oNotifyMgr:Notify(mMem[i],"今日邀请次数已全部使用，无法继续获得奖励。")
            end
        else
            --oNotifyMgr:Notify(mMem[i],string.format("今日邀请贵宾次数%d/%d,次数使用完无法获得奖励",oMem.m_oToday:Query("minglei_fighttime",0),MINGLEI_FIGHTTIME+oMem.m_oToday:Query("minglei_buytime",0)))
            bValid = true
        end
    end
    return bValid,s
end

function CHuodong:PackEnterMemInfo(oPlayer)
    local oTeam = oPlayer:HasTeam()
    local s=""
    if not oTeam then
        s = s..oPlayer.m_iPid
    else
        local mMem = oTeam:GetTeamMember()
        for i = 1,#mMem do
            s = (i==#mMem) and (s..mMem[i]) or (s..mMem[i].."、")
        end
    end
    return s
end

function CHuodong:ValidMemGrade(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return true
    end
    local mMem = oTeam:GetTeamMember()
    local s = ""
    local bValid = true
    for i = 1,#mMem do
        if not self:ValidGrade(mMem[i]) then
            local oWorldMgr = global.oWorldMgr
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(mMem[i])
            bValid = false
            s = (i==#mMem) and (s..oPlayer:GetName()) or (s..oPlayer:GetName().."、")
        end
    end
    return bValid,s
end

function CHuodong:ValidGrade(iPid)
    local iOpenGrade = res["daobiao"]["global_control"]["minglei"]["open_grade"]
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    return (oPlayer:GetGrade() >= iOpenGrade)
end

function CHuodong:PackScheduleInfo(oPlayer)
    local iBuyTime = oPlayer.m_oToday:Query("minglei_buytime",0)
    local iFightTime = oPlayer.m_oToday:Query("minglei_fighttime",0)
    return {usetime = iFightTime,maxtime=MINGLEI_FIGHTTIME,buytime=iBuyTime}
end

function CHuodong:HasEnterTime(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    local iBuyTime = oPlayer.m_oToday:Query("minglei_buytime",0)
    return oPlayer.m_oToday:Query("minglei_fighttime",0) < (MINGLEI_FIGHTTIME+iBuyTime)
    -- body
end

function CHuodong:CheckCanReward(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end

    local iBuyTime = oPlayer.m_oToday:Query("minglei_buytime",0)
    return oPlayer.m_oToday:Query("minglei_fighttime",0) < (MINGLEI_FIGHTTIME+iBuyTime)
end

function CHuodong:GetMingleiFightCnt()
    return MINGLEI_FIGHTTIME
end


function CHuodong:CanGetReward(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    local iBuyTime = oPlayer.m_oToday:Query("minglei_buytime",0)
    return oPlayer.m_oToday:Query("minglei_fighttime",0) < (MINGLEI_FIGHTTIME+iBuyTime - 1)
end

function CHuodong:HasBuyTime(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    return oPlayer.m_oToday:Query("minglei_buytime",0) < MINGLEI_BUYTIME
    -- body
end

function CHuodong:TransString(oPlayer,oNpc,s)
    if not s then
        return
    end
    if string.find(s,"{monstername}") then
        s=gsub(s,"{monstername}",oNpc:Name())
    end
    if string.find(s,"{left_fighttime}") then
        local iBuyTime = oPlayer.m_oToday:Query("minglei_buytime",0)
        local iDoneTime = oPlayer.m_oToday:Query("minglei_fighttime",0)
        local iLeftTime  =(MINGLEI_FIGHTTIME+iBuyTime-iDoneTime) > 0 and (MINGLEI_FIGHTTIME+iBuyTime-iDoneTime) or 0
        s=gsub(s,"{left_fighttime}",iLeftTime)
    end
    if string.find(s,"{done_time}") then
        local iDoneTime = oPlayer.m_oToday:Query("minglei_fighttime",0)
        s=gsub(s,"{done_time}",iDoneTime)
    end
    if string.find(s,"{left_buytime}") then
        local iBuyTime = oPlayer.m_oToday:Query("minglei_buytime",0)
        s=gsub(s,"{left_buytime}",(MINGLEI_BUYTIME-iBuyTime))
    end
    if string.find(s,"{totaltime}") then
        local iBuyTime = oPlayer.m_oToday:Query("minglei_buytime",0)
        s=gsub(s,"{totaltime}",MINGLEI_FIGHTTIME+iBuyTime)
    end
    return s
end

function CHuodong:_DoFightScript1(oPlayer,oNpc)
    local oNotifyMgr = global.oNotifyMgr
    local iOpenGrade = res["daobiao"]["global_control"]["minglei"]["open_grade"]
    if oPlayer:GetGrade() < iOpenGrade then
        self:DoScript2(oPlayer.m_iPid,oNpc,"DI300")
        return
    end

    if not self:HasEnterTime(oPlayer.m_iPid) then
        if not self:HasBuyTime(oPlayer.m_iPid) then
            oNotifyMgr:Notify(oPlayer.m_iPid,"今日邀请次数已全部使用，无法继续获得奖励。")
            return
        else
            local iBuyTime = MINGLEI_BUYTIME - oPlayer.m_oToday:Query("minglei_buytime",0)
            oNotifyMgr:Notify(oPlayer.m_iPid,string.format("邀请次数已使用完，无法继续获得奖励，今日还可购买%d邀请次数。",iBuyTime))
            self:ShowBuyTimeWnd(oPlayer)
            return
        end
    end
    --self:DoScript2(oPlayer.m_iPid,oNpc,"DI400")
    self:_DoFightScript2(oPlayer,oNpc)
end

function CHuodong:_DoFightScript2(oPlayer,oNpc)
    if oNpc._release then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    if not self:HasEnterTime(oPlayer.m_iPid) and not self:HasBuyTime(oPlayer.m_iPid) then
        oNotifyMgr:Notify(oPlayer.m_iPid,"今日进行次数已使用完，请明天再尝试。")
        return
    end
    if self:HasEnterTime(oPlayer.m_iPid) then
        --oNotifyMgr:Notify(oPlayer.m_iPid,string.format("今日邀请贵宾次数%d/%d,次数使用完无法获得奖励",oPlayer.m_oToday:Query("minglei_fighttime",0),MINGLEI_FIGHTTIME+oPlayer.m_oToday:Query("minglei_buytime",0)))
        self:_DoFightScript4(oPlayer,oNpc)
        return
    else
        if self:HasBuyTime(oPlayer.m_iPid) then
            self:_DoFightScript3(oPlayer,oNpc)
            return
        end
    end
end

function CHuodong:_DoFightScript3(oPlayer,oNpc)
    self:ShowBuyTimeWnd(oPclilayer)
end

function CHuodong:_DoFightScript4(oPlayer,oNpc,iType)
    if oNpc._release then
        return
    end
    local oTeam  = oPlayer:HasTeam()
    local iAveGrade = oPlayer:GetGrade()
    if oTeam and not oTeam:IsShortLeave(oPlayer:GetPid()) then
        iAveGrade = oTeam:GetTeamMaxGrade()
    end
    local iMonsterGrade = math.floor(iAveGrade/5) * 5
    if iMonsterGrade == 0 then
        iMonsterGrade = 25
    end
    local mFightData = self:GetMLFightData()
    assert(mFightData[iMonsterGrade],string.format("RefreshMonster failed,MonsterGrade:%d",iMonsterGrade))
    local mGrade2Fight = mFightData[iMonsterGrade]["fightid"]
    local iShape = oNpc.m_mModel.shape
    local iFight = self:RandomFight(oNpc.m_iType,iType)
    oNpc.m_iFight = iFight
    oNpc.m_iAveGrade = iAveGrade
    local oWar = self:Fight(oPlayer.m_iPid,oNpc,iFight)
    if not oWar then
        return
    end
    local iMapId = oNpc.m_iMapid
    local oSceneMgr = global.oSceneMgr
    local sSceneName = oSceneMgr:GetSceneName(iMapId)
    local sPlayer = self:PackEnterMemInfo(oPlayer)
    oWar:SetData("splayer",sPlayer)
    record.user("minglei","enter_fight",{player=sPlayer,npcid=oNpc.m_ID,ave_grade=iAveGrade,monster_grade=iMonsterGrade,fightid=iFight,scene_name=sSceneName})
end

function CHuodong:Fight(iPid,oNpc,iFight)
    local oWar = super(CHuodong).Fight(self,iPid,oNpc,iFight)
    if not oWar then
        return
    end
    if oNpc then
        local oSceneMgr = global.oSceneMgr
        oNpc:SetNowWar(oWar.m_iWarId)
        oSceneMgr:NpcEnterWar(oNpc)
    end
    return oWar
end

function CHuodong:RandomFight(iNpcId,iType)
    local mData = res["daobiao"]["huodong"][self.m_sName]["config_fight"][iNpcId]
    assert(mData[iType],"明雷config_fight配置出错，npcid："..iNpcId.." type :"..iType)
    return mData[iType][math.random(#mData[iType])]
end

function CHuodong:ConfigWar(oWar,pid,npcobj,iFight)
    if npcobj then
        oWar:SetData("MLV",npcobj.m_iAveGrade)
    else
        oWar:SetData("MLV",20)
    end
end

function CHuodong:TransMonsterAble(oWar,sAttr,mArgs)
    mArgs = mArgs or {}
    local sValue = mArgs.value
    local mEnv = mArgs.env
    mEnv.MLV = oWar:GetData("MLV",25)
    local iValue = formula_string(sValue,mEnv)
    return iValue
end

function CHuodong:WarFightEnd(oWar,iPid,oNpc,mArgs)
    super(CHuodong).WarFightEnd(self,oWar,iPid,oNpc,mArgs)
    if oNpc and not oNpc._release then
        oNpc.m_iFight = nil
        if oNpc.m_iNeedClear then
            self:RemoveTempNpc(oNpc)
        end
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:PushBookCondition("喵萌茶会战斗场数", {value = 1})
    end
end

function CHuodong:Reward(iPid, sIdx, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    super(CHuodong).Reward(self,iPid,sIdx,mArgs)
end

function CHuodong:OnWarWin(oWar, pid, npcobj, mArgs)
    super(CHuodong).OnWarWin(self,oWar,pid,npcobj,mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end

    local mFightData = self:GetTollGateData(oWar.m_FightIdx)
    local mReward = mFightData["rewardtbl"]
    local lPlayers = self:GetFightList(oPlayer, mArgs)
    for _,pid in ipairs(lPlayers) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            if oWar.m_FightIdx ~= 9999 then
                global.oAchieveMgr:PushAchieve(pid,"击败茶会相关怪物次数",{value=1})
                oPlayer:AddSchedule("minglei")
                oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30022,1)
            end
            if self:CheckCanReward(pid) then
                if oWar.m_FightIdx ~= 9999 then
                    self:AddFightTime(oPlayer)
                end
                for i = 1,#mReward do
                    self:Reward(pid,mReward[i]["rewardid"],mArgs)
                end
            end
            
        end
    end

    record.user("minglei","win_fight",{player = oWar:GetData("splayer") or "",fightid=oWar.m_FightIdx,npcid=npcobj and npcobj.m_ID or oWar.m_FightIdx,reward = ConvertTblToStr(mReward)})
    if npcobj then
        npcobj.m_iNeedClear = false
        self:RemoveTempNpc(npcobj)
    end
    self:LogAnalyGame("minglei",oPlayer)
end

function CHuodong:OnWarFail(oWar, pid, npcobj, mArgs)
    record.user("minglei","fail_fight",{player = oWar:GetData("splayer") or "",fightid=npcobj and npcobj.m_iFight or oWar.m_FightIdx,npcid=npcobj and npcobj.m_ID or oWar.m_FightIdx})
    super(CHuodong).OnWarFail(self,oWar, pid, npcobj, mArgs)
end

function CHuodong:ClearLastHourMonster()
    for iNpcId,oNpc in pairs(self.m_mNpcList) do
        if oNpc then
            if not oNpc:InWar() then
                self:RemoveTempNpc(oNpc)
            else
                oNpc.m_iNeedClear = true
            end
        end
    end
end

function CHuodong:AddFightTime(oPlayer)
    oPlayer.m_oToday:Add("minglei_fighttime",1)
end

function CHuodong:ShowBuyTimeWnd(oPlayer)
    oPlayer:Send("GS2CShowBuyTimeWnd",{lefttime = self:GetLeftBuyTimes(oPlayer),per_cost=MINGLEI_BUYCOST,maxtime=MINGLEI_BUYTIME})
end

function CHuodong:GetLeftBuyTimes(oPlayer)
    return math.max(0,MINGLEI_BUYTIME - oPlayer.m_oToday:Query("minglei_buytime",0))
end

function CHuodong:BuyMingleiTimes(oPlayer,iBuyTime)
    local oNotifyMgr = global.oNotifyMgr
    local iLeftBuyTime = MINGLEI_BUYTIME - oPlayer.m_oToday:Query("minglei_buytime",0)
    if iBuyTime >iLeftBuyTime then
        oNotifyMgr:Notify(oPlayer.m_iPid,"超过今日购买上限")
        return
    end
    if oPlayer:ValidGoldCoin(MINGLEI_BUYCOST*iBuyTime) then
        oPlayer:ResumeGoldCoin(MINGLEI_BUYCOST,"明雷副本购买次数")
        oPlayer.m_oToday:Add("minglei_buytime",iBuyTime)
        oNotifyMgr:Notify(oPlayer.m_iPid,"购买成功")
        local iTotalBuyTime = oPlayer.m_oToday:Query("minglei_buytime",0)
        local iTotalTime = MINGLEI_FIGHTTIME+iTotalBuyTime
        local iDoneTime = oPlayer.m_oToday:Query("minglei_fighttime",0)
        local iLeftBuyTime = MINGLEI_BUYTIME-iBuyTime
        oPlayer:Send("GS2CRefreshMingleiTime",{buytime = iTotalBuyTime,totaltime = iTotalTime,donetime = iDoneTime,leftbuytime = iLeftBuyTime})
    else
    end
end

function CHuodong:EnterMingleiTeam(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    if not self:HasEnterTime(oPlayer.m_iPid) then
        oNotifyMgr:Notify(oPlayer.m_iPid,"次数不足，请购买次数后再进行。")
    end
end

function CHuodong:GetCurMapInfo(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    if #self.m_mCurMap <= 0 then
        oNotifyMgr:Notify(oPlayer.m_iPid,"还没刷呢，查你个头啊")
        return
    end
    local oSceneMgr = global.oSceneMgr
    local sMsg = "当前明雷怪刷在 "
    for _,iMapId  in pairs(self.m_mCurMap) do
        local sSceneName = oSceneMgr:GetSceneName(iMapId)
        sMsg = sMsg..sSceneName.."  "
    end
    oNotifyMgr:Notify(oPlayer.m_iPid,sMsg)
end

function CHuodong:FullMonster(iMapId)
    self:ClearLastHourMonster()
    local mMapId = {iMapId}
    self.m_mCurMap = mMapId
    local oSceneMgr = global.oSceneMgr
    local mPosList = oSceneMgr:GetAllMonsterPos(iMapId)
    local mNpc = self:GetNpcBaseData()
    local iRefreshAmount = #mPosList
    local iMapNum = #mMapId

    for _, iMapId  in ipairs(mMapId) do
        local mScene = oSceneMgr:GetSceneListByMap(iMapId)
        for _, oScene in ipairs(mScene) do
            local iScene = oScene:GetSceneId()
            local num = math.ceil((iRefreshAmount/(#mMapId)))
            local mPos = oSceneMgr:RandomMonsterPos(iMapId,num)
            for i=1,num do
                local idx = self:RandomNpc(iMapId)
                local x, y = table.unpack(mPos[i])
                local mPosInfo = {
                    x = x or 0,
                    y = y or 0,
                    z = 0,
                    face_x = 0,
                    face_y = 0,
                    face_z = 0,
                }
                local oNpc = self:CreateTempNpc(idx)
                self:Npc_Enter_Scene(oNpc, iScene, mPosInfo)
            end
        end
    end
end

function CHuodong:GuideMingleiWar(oPlayer)
    self:CreateWar(oPlayer.m_iPid,nil,9999,{war_type = 9999,remote_war_type = guidance})
end

function CHuodong:ClickMinglei(oPlayer,oNpc)
    local iBuyTime = oPlayer.m_oToday:Query("minglei_buytime",0)
    local iTotalTime = MINGLEI_FIGHTTIME+iBuyTime
    local iDoneTime = oPlayer.m_oToday:Query("minglei_fighttime",0)
    local iNpcType = oNpc:Type()
    local iNpcid = oNpc:ID()
    local iLeftBuyTime = MINGLEI_BUYTIME-iBuyTime
    oPlayer:Send("GS2COpenMingleiUI",{totaltime = iTotalTime,buytime = iBuyTime,donetime = iDoneTime,leftbuytime = iLeftBuyTime,npctype = iNpcType,npcid = iNpcid})
end

function CHuodong:DoCmd(oPlayer,iNpcId,sCmd,mArgs)
    local oNpcMgr = global.oNpcMgr
    local oNpc = oNpcMgr:GetObject(iNpcId)
    if not oNpc then
        return
    end
    self:DoScript2(oPlayer.m_iPid,oNpc,sCmd,mArgs)
end
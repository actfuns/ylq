--import module
local global  = require "global"
local extend = require "base.extend"
local res = require "base.res"
local extend = require "base.extend"
local record = require "public.record"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local boss = import(service_path("huodong/npcobj/fieldbossnpcobj"))
local npcobj = import(service_path("npc.npcobj"))
local templ = import(service_path("templ"))
local rewardobj = import(service_path("huodong/npcobj/fieldbossrewardobj"))

local gsub = string.gsub

function  NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "野外BOSS"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_iHasInit = 0
    self.m_mBossEndTime = {}
    self.m_mInitBoss = {}       --暂无字段记录开服时间，此处用来记录开服首次init时间，用于中断恢复
    self.m_mScene2Boss = {} --场景和BOSS的映射
    self.m_mBossBattle = {}
    self.m_mGateNpc = {}
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.hasinit = self.m_iHasInit
    mData.endtime = self.m_mBossEndTime
    mData.initboss = self.m_mInitBoss
    local mBattle = {}
    for iBossId,oBossBattle in pairs(self.m_mBossBattle) do
        mBattle[iBossId] = oBossBattle:Save()
    end
    mData.bossbattle = mBattle
    local mGatenpc = {}
    for iBossId,oGate in pairs(self.m_mGateNpc) do
        mGatenpc[iBossId] = true
    end
    mData.gatenpc = mGatenpc
    mData = mData
    return mData
end

function CHuodong:Load(mData)
    self.m_mBossEndTime = mData.endtime or {}
    self.m_iHasInit = mData.hasinit or 0
    self.m_mInitBoss = mData.initboss or {}
    if self.m_iHasInit== 0 then
        local iServerDay = global.oWorldMgr:GetOpenDays()
        if iServerDay == 0 then
            self:InitBossSchedule()
            return
        end
    end
    self:ReInitBoss()
    local mGatenpc = mData.gatenpc or {}
    local mBattle = mData.bossbattle or {}
    if table_count(mBattle) > 0 then
        for iBossId,info in pairs(mBattle) do
            local bNotGate = true
            if mGatenpc[iBossId] then
                bNotGate = false
            end
            self:NewBoss(iBossId,bNotGate)
            self.m_mBossBattle[iBossId]:Load(info)
        end
    end

end

function CHuodong:NewHour(iWeekDay, iHour)
end

function CHuodong:OnDisconnected(oPlayer)
end

function CHuodong:InitBossSchedule()
    self:Dirty()
    self.m_iHasInit = 1
    local mBossData = self:GetConfigInfo()
    for iBossId,mInfo in pairs(mBossData) do
        self.m_mInitBoss[iBossId] = get_time()
        local iBornTime = mInfo["born_time"]
        if iBornTime > 0 then
            self:DelTimeCb("_NewBoss"..iBossId)
            self:AddTimeCb("_NewBoss"..iBossId,iBornTime*60*1000,function()
                local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
                if oHuodong then
                    oHuodong:NewBoss(iBossId)
                    oHuodong:FinishInit(iBossId)
                end
            end)
        end
    end
end

function CHuodong:GetConfigInfo()
    local mData = res["daobiao"]["huodong"][self.m_sName]
    return mData["fieldboss_config"]
end

function CHuodong:TransString(oPlayer,oNpc,s)
    if not s then
        return
    end
    if string.find(s,"$name") then
        local iBossId = oNpc.m_iBossId
        local mBossInfo = self:GetBossBaseInfo(iBossId)
        if not mBossInfo then
            return
        end
        local mBossNpcInfo = self:GetTempNpcData(mBossInfo["boss_model"])
        local sBossName = mBossNpcInfo["name"]
        s=gsub(s,"$name",sBossName)
    end
    return s
end

function CHuodong:GetBossBaseInfo(iBossId)
    local mData = self:GetConfigInfo()
    assert(mData[iBossId],string.format("没有配置ID为%d的野外Boss",iBossId))
    return mData[iBossId]
end

function CHuodong:GetDialogBaseData()
    local res = require"base.res"
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
    local sName = oNpc.m_sSysName
    local iBossId = oNpc.m_iBossId
    local bIsBoss = oNpc.m_bIsBoss
    local func = function(oPlayer,mArgs)
        if mArgs.answer and mArgs.answer ~= 0 then
            local event = mDialogInfo["last_action"][mArgs.answer]["event"]
            if event then
                local oHuodongMgr = global.oHuodongMgr
                local oHuodong = oHuodongMgr:GetHuodong(sName)
                local obj = oHuodong:GetNpcObj(iNpcId)
                if bIsBoss then
                    obj = oHuodong:GetBossNpc(iBossId)
                end
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

function CHuodong:GetBossNpc(iBossId)
    local oBossBattle = self.m_mBossBattle[iBossId]
    if oBossBattle then
        return oBossBattle:GetBossNpc()
    end
    return nil
end

function CHuodong:OtherScript(pid,npcobj,s,mArgs)
    -- body
    if string.sub(s,1,2) == "go" then
        self:EnterBossScene(pid,npcobj)
    elseif string.sub(s,1,9) == "fieldboss" then
        self:FightBoss(pid,npcobj.m_iBossId)
    end
end

function CHuodong:EnterBossScene(iPid,oNpc)
    local iBossId = oNpc.m_iBossId
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oTeam = oPlayer:HasTeam()
    if oTeam and not oTeam:IsLeader(iPid)  and not oTeam:IsShortLeave(iPid) then
        global.oNotifyMgr:Notify(iPid,"请让你们的队长来找我")
        return
    end
    if self.m_mBossEndTime[iBossId] then
        global.oNotifyMgr:Notify(iPid,"Boss已陷入沉睡")
        self:RemoveTempNpc(oNpc)
        return
    end
    local oBossBattle = self.m_mBossBattle[iBossId]
    if not oBossBattle then
        return
    end
    local mBossInfo = self:GetBossBaseInfo(iBossId)
    local iEnterCntLimit = oBossBattle:GetEnterCntLimit()
    local iCurCnt = oBossBattle:GetPlayerCnt()
    local iGradeLimit = mBossInfo["enter_gradelimit"]
    if oPlayer:GetGrade() < iGradeLimit then
        global.oNotifyMgr:Notify(iPid,string.format("等级低于%d，无法进入场景",iGradeLimit))
        return
    end
    if oPlayer:HasTeam() and oPlayer:IsTeamLeader() then
        local oTeam = oPlayer:HasTeam()
        local mMem = oTeam:GetTeamMember()
        if (#mMem + iCurCnt) > iEnterCntLimit then
            global.oTeamMgr:TeamNotify(oTeam, "场景当前人数已达到上限，请稍后再试")
            return
        end
        local iEnterCntLimit = oBossBattle:GetEnterCntLimit()
        local bVaildEnter = true
        for _,pid in ipairs(mMem) do
            local oMem = global.oWorldMgr:GetOnlinePlayerByPid(pid)
            if oMem:GetGrade() < iGradeLimit then
                global.oNotifyMgr:Notify(iPid,string.format("%s等级低于%d,无法进入场景",oMem:GetName(),iGradeLimit))
                bVaildEnter = false
            end
            local iLeaveTime = oBossBattle:GetLeaveTime(pid)
            if iLeaveTime ~= 0 and (get_time() - iLeaveTime) < 30 then
                global.oNotifyMgr:Notify(iPid,string.format("%s还有%d秒才可以进入场景",oMem:GetName(),30-(get_time() - iLeaveTime)))
                bVaildEnter = false
            end
        end
        if not bVaildEnter then
            return
        end
        for _,pid in ipairs(mMem) do
            oBossBattle:EnterBattle(pid)
        end
        return
    end

    oBossBattle:EnterBattle(iPid)
end

function CHuodong:NewBoss(iBossId,bNotGate)
    -- body
    self:Dirty()
    self:DelTimeCb("_NewBoss"..iBossId)

    if self.m_mBossEndTime[iBossId] then
        self.m_mBossEndTime[iBossId] = nil
    end

    local mBossInfo = self:GetBossBaseInfo(iBossId)
    local sBornMessage = mBossInfo["refresh_text"]
    local mBossNpcInfo = self:GetTempNpcData(mBossInfo["boss_model"])
    local mGateNpcInfo = self:GetTempNpcData(mBossInfo["gate_model"])

    local iBornMap = mBossInfo["born_map"]

    local oSceneMgr = global.oSceneMgr

    local sBossName = mBossNpcInfo["name"]
    sBornMessage = string.gsub(sBornMessage,"$name", sBossName)
    sBornMessage = string.gsub(sBornMessage,"$place", oSceneMgr:GetSceneName(iBornMap))
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendPrioritySysChat("fieldboss_char",sBornMessage, 1)

    --create boss_battle
    local oBossBattle = self:NewBattle(iBossId)
    self.m_mBossBattle[iBossId] = oBossBattle

    --create gate_npc
    if not bNotGate then
        local oGate = self:CreateGateNpc(iBossId)
        self:Npc_Enter_Map(oGate,iBornMap,table_deep_copy(oGate:PosInfo()))
        self.m_mGateNpc[iBossId] = oGate
    end

    local oWarMgr = global.oWarMgr
    local mNet = oBossBattle:PackInitInfo()
    for _,v in pairs(oWarMgr.m_lWarRemote) do
        interactive.Send(v,"fieldboss","NewFieldBoss",mNet)
    end

    local mData = {
        message = "GS2CNewFieldBoss",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = {bossid={iBossId}},
        exclude = mExclude,
    }
    interactive.Send(".broadcast", "channel", "SendChannel", mData)
end

function CHuodong:CreateGateNpc(iBossId)
    local mBossInfo = self:GetBossBaseInfo(iBossId)
    local iGateNpcId = mBossInfo["gate_model"]
    local mArgs = self:PacketNpcInfo(iGateNpcId)
    mArgs.bossid = mBossInfo["id"]
    mArgs.sys_name = "fieldboss"
    local oTempNpc = self:NewHDNpc(mArgs)
    oTempNpc.m_oHuodong = self
    self.m_mNpcList[oTempNpc.m_ID] = oTempNpc
    return oTempNpc
end

function CHuodong:CheckAliveBoss()
    if table_count(self.m_mBossBattle) > 0 then
        return true
    end
    return false
end

function CHuodong:Clean()
    for id,oNpc in pairs(self.m_mNpcList) do
        if oNpc.m_iBossId and oNpc.m_iBossId ~= 0 then
            self:RemoveTempNpc(oNpc)
        end
    end
    for npcid,oNpc in pairs(global.oNpcMgr.m_mObject) do
        if oNpc.m_iBossId and oNpc.m_iBossId ~= 0 then
            global.oNpcMgr:RemoveSceneNpc(npcid)
        end
    end
    self:ClearBoss()
    self:InitBossSchedule()
end

function CHuodong:MergeFrom(mFromData)
    self:Dirty()
    self:Clean()
    return true
end

function CHuodong:NewHDNpc(mArgs,iTempNpc)
    return NewHDNpc(mArgs)
end

function CHuodong:NewBattle(iBossId)
    local mArgs = {}
    mArgs.bossid = iBossId
    return NewBattle(mArgs)
end

function VaildEnter(oScene,oPlayer,oLeader)
    local oL = oLeader
    if not oLeader then
        local oTeam = oPlayer:HasTeam()
        if oTeam then
            local iLeader = oTeam:Leader()
            oL = global.oWorldMgr:GetOnlinePlayerByPid(iLeader)
        end
    end
    if oL and oL.m_oActiveCtrl:GetNowScene() == oPlayer.m_oActiveCtrl:GetNowScene() then
        return true
    end
    return false
end

function CHuodong:FinishInit(iBossId)
    if self.m_mInitBoss[iBossId] then
        self:Dirty()
        self.m_mInitBoss[iBossId] = false
    end
end

function CHuodong:ReInitBoss()
    local iCurTime = get_time()
    local mBossData = self:GetConfigInfo()
    for iBossId,info in pairs(mBossData) do
        local mBossInfo = self:GetBossBaseInfo(iBossId)
        if self.m_mInitBoss[iBossId] and not self.m_mBossEndTime[iBossId] then  ---开服后BOSS出生前关服了
            local iInterval = (iCurTime-self.m_mInitBoss[iBossId])/60
            local iBornTime = mBossInfo["born_time"]
            if iInterval >= iBornTime then
                self:NewBoss(iBossId)
                self:FinishInit(iBossId)
            else
                self:DelTimeCb("_NewBoss"..iBossId)
                self:AddTimeCb("_NewBoss"..iBossId,(iBornTime-iInterval)*60*1000,function()
                    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
                    if oHuodong then
                        oHuodong:NewBoss(iBossId)
                        oHuodong:FinishInit(iBossId)
                    end
                end)
            end
        elseif self.m_mBossEndTime[iBossId] then
            local iRefreshTime = mBossInfo["refresh_time"]
            local iInterval = (iCurTime-self.m_mBossEndTime[iBossId].time)/60
            if iInterval >= iRefreshTime then
                self:NewBoss(iBossId)
            else
                self:DelTimeCb("_NewBoss"..iBossId)
                self:AddTimeCb("_NewBoss"..iBossId,(iRefreshTime-iInterval)*60*1000,function()
                    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
                    if oHuodong then
                        oHuodong:NewBoss(iBossId)
                    end
                end)
            end
        end
    end
end

function CHuodong:FightBoss(iPid,iBossId)
    local oBossBattle = self.m_mBossBattle[iBossId]
    if oBossBattle then
        oBossBattle:FightBoss(iPid)
    end
end

function CHuodong:HPChange(iBossId,iDamage,lPidList)
    local oBossBattle = self.m_mBossBattle[iBossId]
    oBossBattle:HPChange(iDamage,lPidList)
end

function CHuodong:OnLogin(oPlayer)
    local mNet = {}
    for iBossId,oBossBattle in pairs(self.m_mBossBattle) do
        table.insert(mNet,iBossId)
    end
    oPlayer:Send("GS2CNewFieldBoss",{bossid=mNet})
    local iBossId = oPlayer.m_oActiveCtrl:GetData("fieldboss",0)
    local iPid = oPlayer.m_iPid
    if iBossId ~= 0 then
        interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = iPid,
            channel_list = {
                {gamedefines.BROADCAST_TYPE.FIELD_BOSS, iBossId, false},
            },
        })

        local mRole = {
            pid = iPid,
        }
        interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = iPid,
            channel_list = {
                {gamedefines.BROADCAST_TYPE.FIELD_BOSS, iBossId, true},
            },
            info = mRole,
        })
        local oBossBattle = self.m_mBossBattle[iBossId]
        if oBossBattle then
            oBossBattle:OnLogin(oPlayer)
        end
    end
end

function CHuodong:OnLogout(oPlayer)
    local iBossId = oPlayer.m_oActiveCtrl:GetData("fieldboss",0)
    if iBossId and iBossId ~= 0 then
        local oBossBattle = self.m_mBossBattle[iBossId]
        if oBossBattle then
            oBossBattle:LeaveBattle(oPlayer.m_iPid)
        else
            interactive.Send(".broadcast", "channel", "SetupChannel", {
                pid = oPlayer.m_iPid,
                channel_list = {
                    {gamedefines.BROADCAST_TYPE.FIELD_BOSS, iBossId, false},
                },
            })
        end
    end
end

function CHuodong:LeaveBattle(oPlayer)
    local iBossId = oPlayer.m_oActiveCtrl:GetData("fieldboss",0)
    if iBossId and iBossId ~= 0 then
        local oBossBattle = self.m_mBossBattle[iBossId]
        if oBossBattle then
            oBossBattle:LeaveBattle(oPlayer.m_iPid)
        end
    end
end

function CHuodong:BossEnd(iBossId,iDeadTime,iIsDead)
    self:Dirty()
    self.m_mBossEndTime[iBossId] = {time=iDeadTime,is_dead = iIsDead}

    if self.m_mGateNpc[iBossId] then
        self:RemoveTempNpc(self.m_mGateNpc[iBossId])
        self.m_mGateNpc[iBossId] = nil
    end
    if iIsDead == 1 then
        local mData = {
            message = "GS2CFieldBossDied",
            type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
            id = 1,
            data = {bossid=iBossId},
            exclude = mExclude,
        }
        interactive.Send(".broadcast", "channel", "SendChannel", mData)
        local oWarMgr = global.oWarMgr
        for _,v in pairs(oWarMgr.m_lWarRemote) do
            interactive.Send(v,"fieldboss","RemoveFieldBoss",{bossid = iBossId})
        end
    end
    if iIsDead == 0 then
        self:AfterBossEnd(iBossId)
    end
end

function CHuodong:NotifyBossEnd(iBossId)
    local mBossInfo = self:GetBossBaseInfo(iBossId)
    local sEndMessage = mBossInfo["end_text"]
    local mBossNpcInfo = self:GetTempNpcData(mBossInfo["boss_model"])
    local sBossName = mBossNpcInfo["name"]
    sEndMessage = string.gsub(sEndMessage,"$name", sBossName)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendPrioritySysChat("fieldboss_char",sEndMessage, 1)
end

function CHuodong:AfterBossEnd(iBossId)
    self:Dirty()
    self.m_mInitBoss[iBossId] = get_time()
    local mInfo = self:GetBossBaseInfo(iBossId)
    local iBornTime = mInfo["refresh_time"]
    if iBornTime > 0 then
        self:DelTimeCb("_NewBoss"..iBossId)
        self:AddTimeCb("_NewBoss"..iBossId,iBornTime*60*1000,function()
            local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
            if oHuodong then
                oHuodong:NewBoss(iBossId)
                oHuodong:FinishInit(iBossId)
            end
        end)
    end
end

function CHuodong:GMGetInfo()
    local mNet = self:PackMainUiInfo()
    for iBossId = 1,3 do
        local iStatus = self:GetBossStatus(iBossId)
        if iStatus == 2 then
            local oBossBattle = self.m_mBossBattle[iBossId]
            local mHpInfo = oBossBattle:PackHpInfo()
        elseif iStatus == 1 then
            local mBossInfo = self:GetBossBaseInfo(iBossId)
            local iRebornTime = mBossInfo["refresh_time"]*60
            local iLeftTime = iRebornTime - (get_time() - self.m_mBossEndTime[iBossId].time)
        elseif iStatus == 3 then
            local iInitTime = self.m_mInitBoss[iBossId] or get_time()
            local iRefreshTime
            local mBossInfo = self:GetBossBaseInfo(iBossId)
            if self.m_mBossEndTime[iBossId] and self.m_mBossEndTime[iBossId].is_dead == 0 then
                iRefreshTime = mBossInfo["refresh_time"] * 60
            else
                iRefreshTime = mBossInfo["born_time"] * 60
            end
            local iLeftTime = iRefreshTime - (get_time() - iInitTime)
        end
    end
end

function CHuodong:OpenFieldBossUI(oPlayer)
    local mNet = self:PackMainUiInfo()
    oPlayer:Send("GS2CFieldBossMainUI",{boss_status = mNet})
end

function CHuodong:PackMainUiInfo()
    local mStatusInfo = {}
    local mConfig = self:GetConfigInfo()
    for iBossId,info in pairs(mConfig) do
        local iStatus = self:GetBossStatus(iBossId)
        table.insert(mStatusInfo,{id = iBossId,status = iStatus})
    end
    return mStatusInfo
end

function CHuodong:GetBossStatus(iBossId)
    local iStatus = 0
    if self.m_mBossEndTime[iBossId] then
        if self.m_mBossEndTime[iBossId].is_dead == 1 then
            iStatus = 1
        else
            iStatus = 3
        end
    elseif self.m_mBossBattle[iBossId] then
        iStatus = 2
    else
        iStatus = 3
    end
    return iStatus
end

function CHuodong:GetFieldBossInfo(oPlayer,iBossId)

    local iStatus = self:GetBossStatus(iBossId)
    if iStatus == 2 then
        local oBossBattle = self.m_mBossBattle[iBossId]
        local mHpInfo = oBossBattle:PackHpInfo()
        oPlayer:Send("GS2CFieldBossInfo",{bossid = iBossId,status = iStatus,hpinfo = mHpInfo})
        return
    elseif iStatus == 1 then
        local mBossInfo = self:GetBossBaseInfo(iBossId)
        local iRebornTime = mBossInfo["refresh_time"]*60
        local iLeftTime = iRebornTime - (get_time() - self.m_mBossEndTime[iBossId].time)
        oPlayer:Send("GS2CFieldBossInfo",{bossid = iBossId,status = iStatus,left_time = iLeftTime})
        return
    elseif iStatus == 3 then
        local iInitTime = self.m_mInitBoss[iBossId] or get_time()
        local iRefreshTime
        local mBossInfo = self:GetBossBaseInfo(iBossId)
        if self.m_mBossEndTime[iBossId] and self.m_mBossEndTime[iBossId].is_dead == 0 then
            iRefreshTime = mBossInfo["refresh_time"] * 60
        else
            iRefreshTime = mBossInfo["born_time"] * 60
        end
        local iLeftTime = iRefreshTime - (get_time() - iInitTime)
        oPlayer:Send("GS2CFieldBossInfo",{bossid = iBossId,status = iStatus,left_time = iLeftTime})
        return
    end
end

function CHuodong:ForcePk(oPlayer,iTarget)
    local iBossId = oPlayer.m_oActiveCtrl:GetData("fieldboss",0)
    if iBossId ~= 0 then
        local oBossBattle = self.m_mBossBattle[iBossId]
        if oBossBattle then
            oBossBattle:ForcePk(oPlayer,iTarget)
        end
    end
end

function CHuodong:RewardEnd(iBossId)
    self:Dirty()
    self:ClearBoss(iBossId)
    local mBossInfo = self:GetBossBaseInfo(iBossId)
    local iCurTime = get_time()
    self.m_mInitBoss[iBossId] = iCurTime
    local iRefreshTime = mBossInfo["refresh_time"]
    self:DelTimeCb("_NewBoss"..iBossId)
    self:AddTimeCb("_NewBoss"..iBossId,iRefreshTime*60*1000,function()
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        if oHuodong then
            oHuodong:NewBoss(iBossId)
            oHuodong:FinishInit(iBossId)
        end
    end)
end

function CHuodong:ClearBoss(iBossId)
    if self.m_mBossBattle[iBossId] then
        self.m_mBossBattle[iBossId]:Close()
    end
end

function CHuodong:WarFightEnd(oWar,iPid,oNpc,mArgs)
    local iBossId = oWar:GetData("bossid")
    local oBossBattle = self.m_mBossBattle[iBossId]
    if oBossBattle then
        oBossBattle:WarFightEnd(oWar,iPid,oNpc,mArgs)
    end
end

function CHuodong:RebornBoss(iBossId)
    if not iBossId then
        local mBossData = self:GetConfigInfo()
        for bossid,info in pairs(mBossData) do
            self:KillBoss(bossid)
        end
    else
        self:KillBoss(iBossId)
    end
end

function CHuodong:KillBoss(iBossId)
    self:DelTimeCb("_NewBoss"..iBossId)
    local oBossBattle = self.m_mBossBattle[iBossId]
    if oBossBattle then
        oBossBattle:Close()
        local oGate = self.m_mGateNpc[iBossId]
        if oGate then
            self:RemoveTempNpc(oGate)
        end
        self.m_mBossBattle[iBossId] = nil
    end
    self:NewBoss(iBossId)
end

function CHuodong:ClearBattle(iBossid)
    local oBossBattle = self.m_mBossBattle[iBossid]
    if oBossBattle then
        oBossBattle:Release()
        self.m_mBossBattle[iBossid] = nil
    end
end

function CHuodong:SetFieldBossHp(iBossid,iRate)
    local oBossBattle = self.m_mBossBattle[iBossid]
    if oBossBattle then
        oBossBattle:SetFieldBossHp(iRate)
    end
end

------------------------------------------------------------

CHDNpc = {}
CHDNpc.__index = CHDNpc
inherit(CHDNpc, npcobj.CNpc)

function NewHDNpc(mArgs)
    local o = CHDNpc:New(mArgs)
    return o
end

function CHDNpc:New(mArgs)
    local o = super(CHDNpc).New(self)
    o:Init(mArgs)
    return o
end

function CHDNpc:Init(mArgs)
    local mArgs = mArgs or {}

    self.m_sName = mArgs["name"]
    self.m_sSysName = mArgs.sys_name
    self.m_iType = mArgs["type"]
    self.m_iMapid = mArgs["map_id"] or 0
    self.m_mModel = mArgs["model_info"] or {}
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iEvent = mArgs["event"]
    self.m_iBossId = mArgs["bossid"]
end

function CHDNpc:SetEvent(iEvent)
    self.m_iEvent = iEvent
end

function CHDNpc:do_look(oPlayer)
    if self.m_oHuodong then
        self.m_oHuodong:do_look(oPlayer, self)
    end
end

function CHDNpc:GetData()
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sSysName]["npc"][self.m_iType]
end

function CHDNpc:Name()
    if self.m_sName then
        return self.m_sName
    end
    local mNpcInfo = self:GetData()
    return mNpcInfo["name"]
end

function CHDNpc:Title()
    local mNpcInfo = self:GetData()
    return mNpcInfo["title"]
end

--------------------------------------------------------
CBattle = {}
CBattle.__index = CBattle
CBattle.m_sName = "fieldboss"
inherit(CBattle, huodongbase.CHuodong)

function NewBattle(mArgs)
    local o = CBattle:New(mArgs)
    return o
end

function CBattle:New(mArgs)
    local o = super(CBattle).New(self,self.m_sName)
    o:Init(mArgs)
    return o
end

function CBattle:Init(mArgs)
    self.m_iBossId = mArgs.bossid
    self.m_mPlayerList = {}
    self.m_mLeave = {} --记录玩家离开场景信息
    self.m_mOrg = {}    --记录同工会成员信息
    self.m_lPkWar = {}
    self:InitScene()
    self:InitBoss(mArgs.bossid)
    self:BroadcastBossHP()
    self.m_RewardEndTime = 0
    self.m_mReward = {}     --记录奖励
    self.m_lHit = {}    --记录伤害，可不存盘
    self.m_RewardTimes = {}
end

function CBattle:Save()
    local mData = {}
    mData.playerlist = self.m_mPlayerList
    mData.leave = self.m_mLeave
    mData.org = self.m_mOrg
    mData.boss = {}
    mData.killer = self.m_Killer
    mData.killername = self.m_KillerName
    if self.m_oBoss then
        mData.boss = self.m_oBoss:Save()
    end
    mData.rewardendtime = self.m_RewardEndTime
    mData.reward = self.m_mReward
    return mData
end

function CBattle:Load(mData)
    self.m_mPlayerList = mData.playerlist or {}
    self.m_mLeave = mData.leave or {}
    self.m_mOrg = mData.org or {}
    if table_count(mData.boss) > 0 then
        if self.m_oBoss then
            self.m_oBoss:Load(mData.boss)
        end
    end
    self.m_RewardEndTime = mData.rewardendtime
    self.m_mReward = mData.reward
    if self.m_RewardEndTime > get_time() then
        self:StarReward(self.m_RewardEndTime-get_time(),true)
    end
    self.m_KillerName = mData.killername or ""
    self.m_Killer = mData.killer or ""
end

function CBattle:InitScene()
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    local iSceneIdx = mBossInfo["war_mapid"]
    self.m_iScene = self:CreateBossScene(iBossId,iSceneIdx)
end

function CBattle:GetMapId()
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    local iSceneIdx = mBossInfo["war_mapid"]
    local mRes = self:GetSceneData(iSceneIdx)
    return mRes["map_id"]
end

function CBattle:Huodong()
    return global.oHuodongMgr:GetHuodong("fieldboss")
end

function CBattle:CreateBossScene(iBossId,iMapId)
    local oScene = self:CreateVirtualScene(iMapId)
    oScene.m_iBossId = iBossId
    oScene.m_NoTransfer = 1
    oScene.m_sType = "fieldboss"
    oScene.m_sCallBackFailTips = "$name不在战斗场景，无法被召唤"
    --oScene:SetLimitRule("transfer",1)
    oScene:SetLeaveCallBack(LeaveSceneCallBack)
    oScene.m_fVaildEnter = VaildEnter
    return oScene:GetSceneId()
end

function LeaveSceneCallBack(oPlayer)
    local iBossId = oPlayer.m_oActiveCtrl:GetData("fieldboss",0)
    if iBossId~= 0 then
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        local oBossBattle = oHuodong.m_mBossBattle[iBossId]
        if oBossBattle then
            oBossBattle:LeaveBattle(oPlayer.m_iPid)
        end
    end
end

function CBattle:InitBoss(iBossId)
    --self:StarReward()
    local mBossInfo = self:GetBossBaseInfo(iBossId)
    local iBossNpcId = mBossInfo["boss_model"]
    local mArgs = self:PacketNpcInfo(iBossNpcId)
    mArgs.boss_level = mBossInfo["level"]
    mArgs.bossid = mBossInfo["id"]
    mArgs.born_hp = mBossInfo["born_hp"]
    local oTempNpc = boss.NewBoss(mArgs)
    oTempNpc.m_oHuodong = self
    self.m_mNpcList[oTempNpc.m_ID] = oTempNpc
    self.m_oBoss = oTempNpc
    self:Npc_Enter_Scene(oTempNpc,self.m_iScene,oTempNpc:PosInfo())
end

function CBattle:do_look(oPlayer,oNpc)
    local oHuodong = self:Huodong()
    oHuodong:do_look(oPlayer,oNpc)
end

function CBattle:GetTempNpcData(iTempNpc)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["npc"][iTempNpc]
    assert(mData,string.format("CHuodong GetTempNpcData err: %s %d", self.m_sName, iTempNpc))
    return mData
end

function CBattle:GetBossBaseInfo(iBossId)
    local mData = res["daobiao"]["huodong"][self.m_sName]["fieldboss_config"]
    assert(mData[iBossId],string.format("没有配置ID为%d的野外Boss",iBossId))
    return mData[iBossId]
end

function CBattle:GetEnterHpLimit()
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    return mBossInfo["enter_hplimit"]
end

function CBattle:GetEnterCntLimit()
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    return mBossInfo["player_limit"]
end

function CBattle:GetPlayerCnt()
    return table_count(self.m_mPlayerList)
end

function CBattle:GetLeaveTime(iPid)
    return self.m_mLeave[iPid] and self.m_mLeave[iPid].time or 0
end

function CBattle:EnterBattle(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end

    local iEnterHpLimit = self:GetEnterHpLimit()
    local iBossHpRate = self:GetCurHpRate()
    if iBossHpRate < iEnterHpLimit then
        global.oNotifyMgr:Notify(iPid,"血量已低于"..iEnterHpLimit.."%,禁止进入场景")
        return
    end

    local iEnterCntLimit = self:GetEnterCntLimit()
    if self:GetPlayerCnt() >= iEnterCntLimit then
        global.oNotifyMgr:Notify(iPid,"场景人数已达到上限，无法进入")
        return
    end
    if self.m_mLeave[iPid] then
        local iCurTime = get_time()
        if ( iCurTime - self.m_mLeave[iPid].time ) < 30 then
            global.oNotifyMgr:Notify(iPid,string.format("还有%d秒可进入场景",(30-(iCurTime - self.m_mLeave[iPid].time))))
            return
        end
    end
    oPlayer.m_oActiveCtrl:SetData("fieldboss",self.m_iBossId)

    self.m_mPlayerList[iPid] = {pid = iPid,enter_time = get_time(),old_scene = oPlayer.m_oActiveCtrl:GetNowSceneID(),pos = oPlayer.m_oActiveCtrl:GetNowPos()}

    local iOrgId = oPlayer:GetOrgID()
    if iOrgId and iOrgId ~= 0 then
        self.m_mOrg[iOrgId]= (self.m_mOrg[iOrgId] or 0) + 1
    end

    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    local mSpawnPoint = mBossInfo["spawn_point"]
    local mPos = mSpawnPoint[math.random(#mSpawnPoint)]
    self:TransferPlayerBySceneID(iPid,self.m_iScene,mPos["posx"],mPos["posy"])
    local oState = oPlayer.m_oStateCtrl:GetState(1004)

    oPlayer.m_oStateCtrl:AddState(1004,{time=5})
    oPlayer.m_oStateCtrl:RefreshMapFlag()

    local oInterfaceMgr = global.oInterfaceMgr

    local mRole = {
        pid = iPid,
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = iPid,
        channel_list = {
            {gamedefines.BROADCAST_TYPE.FIELD_BOSS, self.m_iBossId, true},
        },
        info = mRole,
    })
    self:BroadcastBattleInfo()
    self:HPNotify(oPlayer)
end

function CBattle:GetBossNpc()
    return self.m_oBoss
end

function CBattle:BroadcastBattleInfo(m)
    local mExclude = m or {}
    local mNet = self:PackBattleInfo()
    local mData = {
        message = "GS2CFieldBossBattle",
        type = gamedefines.BROADCAST_TYPE.FIELD_BOSS,
        id = self.m_iBossId,
        data = mNet,
        exclude = mExclude,
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end

function CBattle:PackBattleInfo()
    local iOrgNum = 0
    local mOrgInfo = {}
    for iOrgId,num in pairs(self.m_mOrg) do
        table.insert(mOrgInfo,{org_id = iOrgId,amount = num})
    end
    local iPlayerAmount = table_count(self.m_mPlayerList)
    local sBossName = self:GetBossName()
    local mNet = {
        org_info = mOrgInfo,
        playercnt = iPlayerAmount,
        bossname = sBossName,
        bossid = self.m_iBossId,
        reward_endtime = self.m_RewardEndTime,
        reward_amount = table_count(self.m_mReward),
    }
    return mNet
end

function CBattle:GetBossName()
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    local mBossNpcInfo = self:GetTempNpcData(mBossInfo["boss_model"])
    local sName = mBossNpcInfo["name"]
    return sName
end

function CBattle:GetBornHp()
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    return mBossInfo["born_hp"]
end

function CBattle:LeaveBattle(iPid,bNotBrocast)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local bHasPlayer = false
    if self.m_mPlayerList[iPid] then
        bHasPlayer = true
    end
    if not bNotBrocast and oPlayer:HasTeam() then
        local oTeam = oPlayer:HasTeam()
        oTeam:ShortLeave(iPid)
    end
    self.m_mPlayerList[iPid] = nil
    if not bNotBrocast then self:BroadcastBattleInfo({[iPid]=true}) end
    if oPlayer.m_oStateCtrl:GetState(1004) then
        oPlayer.m_oStateCtrl:RemoveState(1004)
        oPlayer.m_oStateCtrl:RefreshMapFlag()
    end
    if oPlayer then
        oPlayer.m_oActiveCtrl:SetData("fieldboss",0)
    end
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = iPid,
        channel_list = {
            {gamedefines.BROADCAST_TYPE.FIELD_BOSS, self.m_iBossId, false},
        },
    })

    self.m_mLeave[iPid] = {time = get_time()}

    local iOrgId = oPlayer:GetOrgID()
    if iOrgId and iOrgId ~= 0 and bHasPlayer then
        if self.m_mOrg and self.m_mOrg[iOrgId]then
            self.m_mOrg[iOrgId]= (self.m_mOrg[iOrgId] or 0) - 1
        end
    end

    self:GobackRealScene(iPid)
    self:AfterLeaveBattel()
    oPlayer:Send("GS2CLeaveFieldBoss",{})
end

function CBattle:AfterLeaveBattel()
    local iPlayerAmount = table_count(self.m_mPlayerList)
    if iPlayerAmount == 0 and (self.m_oBoss and self:GetCurHpRate() or 0) < self:GetEnterHpLimit() then
        self:KickoutWar(0)
        self:DelTimeCb("_PrepareReward"..self.m_iBossId)
        self:DelTimeCb("_BroadcastBossHP")
        local oHuodong = self:Huodong()
        oHuodong:BossEnd(self.m_iBossId,get_time(),0)
        oHuodong:NotifyBossEnd(self.m_iBossId)
        oHuodong:ClearBattle(self.m_iBossId)
    end
end

function CBattle:PackInitInfo()
    local oBoss = self.m_oBoss
    local mData = {}
    mData.bossid = self.m_iBossId
    mData.bossinfo = {
        maxhp = oBoss:GetBornHp(),
        hp = oBoss:GetCurHp(),
    }
    return mData
end

function CBattle:BroadcastBossHP()
    self:DelTimeCb("_BroadcastBossHP")
    if self.m_Status ~= GAME_START then
        return
    end
    self:AddTimeCb("_BroadcastBossHP",3*1000,function ()
        self:BroadcastBossHP()
        end)
    local oBoss = self.m_oBoss
    local mNet = {
    hp_max = oBoss:GetBornHp(),
    hp = oBoss:GetCurHp(),
    }

    local mData = {
        message = "GS2CFieldBossHPNotify",
        type = gamedefines.BROADCAST_TYPE.FIELD_BOSS,
        id = self.m_iBossId,
        data = mNet,
        exclude = {}
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end

function CBattle:HPNotify(oPlayer)
    local oBoss = self.m_oBoss
    local mNet = {
    hp_max = oBoss:GetBornHp(),
    hp = oBoss:GetCurHp(),
    }
    oPlayer:Send("GS2CFieldBossHPNotify",mNet)
end

function CBattle:FightBoss(iPid)
    if not self.m_mPlayerList[iPid] then
        return
    end
    if self.m_oBoss:IsDead() then
        global.oNotifyMgr:Notify(iPid,"BOSS已被击杀")
        return
    end
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    local iFightId = mBossInfo["fightid"]
    self:Fight(iPid,self.m_oBoss,iFightId)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local plist = oPlayer:AllMember()
    for _,pid in ipairs(plist) do
        local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
        if pobj then
            pobj:AddSchedule("fieldboss")
        end
    end
end

function CBattle:CreateWar(pid,npcobj,iFight,mInfo)
    local iBossId = self.m_iBossId
    local mInfo = {war_type = gamedefines.WAR_TYPE.FIELD_BOSS}
    local oWar = super(CBattle).CreateWar(self,pid,npcobj,iFight,mInfo)
    oWar:SetData("bossid",self.m_iBossId)
    local oWarMgr = global.oWarMgr
    local fEscapeCallBack = function(mData)
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        local oBossBattle = oHuodong.m_mBossBattle[iBossId]
        if oBossBattle then
            oBossBattle:EscapeWar(mData.pid)
        end
    end
    oWarMgr:SetEscapeCallBack(oWar:GetWarId(), fEscapeCallBack)
    return oWar
end

function CBattle:GetRemoteWarArg()
    return {bossid = self.m_iBossId}
end

function CBattle:GetSelfCallback()
    local sHuodongName = self.m_sName
    local iBossId = self.m_iBossId
    return function()
        local oHuodong = global.oHuodongMgr:GetHuodong(sHuodongName)
        local oBossBattle = oHuodong.m_mBossBattle[iBossId]
        return oBossBattle
    end
end

function CBattle:WarFightEnd(oWar,iPid,oNpc,mArgs)
    super(CBattle).WarFightEnd(self,oWar,iPid,oNpc,mArgs)
    self:BossFightEnd(oWar,iPid,oNpc,mArgs)
end

function CBattle:GetRewardRatio()
    local res = require "base.res"
    local sRatio = res["daobiao"]["global"]["fieldboss_reward_ratio"]["value"]
    return tonumber(sRatio)
end

function CBattle:GetMaxRewardTimes()
    local res = require "base.res"
    local sRatio = res["daobiao"]["global"]["fieldboss_reward_limit"]["value"]
    return tonumber(sRatio)
end

function CBattle:BossWarReward(iPid,iDamage)
    local iMaxTime = self:GetMaxRewardTimes()
    if self.m_RewardTimes[iPid] and self.m_RewardTimes[iPid] >= iMaxTime then
        return iMaxTime,0
    end
    if iDamage == 0 then
        return self.m_RewardTimes[iPid],0
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iRatio = self:GetRewardRatio()
    local iCoin = math.floor(iDamage * iRatio)
    if iCoin > 0 then
        oPlayer:RewardCoin(iCoin,"野外boss")
        self.m_RewardTimes[iPid] = (self.m_RewardTimes[iPid] or 0) + 1
        self:AddKeep(oPlayer:GetPid(), "coin", iCoin)
        self:LogAnalyGame("fieldboss",oPlayer)
        self:ClearKeep(oPlayer:GetPid())
    end

    return self.m_RewardTimes[iPid]-1,iCoin
end

function CBattle:BossFightEnd(oWar,iPid,oNpc,mArgs)
    -- body

    local mFighter = mArgs.fail_list
    local mEscape = mArgs.escape_list
    local iTeamDamage = 0
    local iFinalAttack = self.m_Killer
    local iTotalHP = self:GetBornHp()
    local iWarid = oWar:GetWarId()
    for _,pid in pairs(mFighter) do
        local iHit = self.m_lHit[iWarid] and self.m_lHit[iWarid][pid] or 0
        iTeamDamage = iTeamDamage + iHit
        if iHit > 0 then
            global.oAchieveMgr:PushAchieve(pid,"人形讨伐",{value=1})
        end
    end
    if mEscape and mEscape[1] then
        for _,pid in pairs(mEscape[1]) do
            local iHit = self.m_lHit[iWarid] and self.m_lHit[iWarid][pid] or 0
            iTeamDamage = iTeamDamage + iHit
            if iHit > 0 then
                global.oAchieveMgr:PushAchieve(pid,"人形讨伐",{value=1})
            end
        end
    end
    for _,playerid in pairs(mFighter) do
        local iDamage = self.m_lHit[iWarid] and self.m_lHit[iWarid][playerid] or 0
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(playerid)
        local iRewardTimes,iCoin = self:BossWarReward(playerid,iDamage)
        oPlayer:Send("GS2CFieldBossAttack",{damage = iDamage,max_hp = iTotalHP,killer = self.m_Killer,teamdamage = iTeamDamage,reward_times = iRewardTimes,coin_reward=iCoin})
        record.user("fieldboss","boss_fight",{pid=playerid,damage = iDamage,bossid=self.m_iBossId})
    end
    self.m_lHit[iWarid] = nil
end

function CBattle:EscapeWar(pid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        global.oNotifyMgr:Notify(pid,"由于您在战斗中逃跑，您已被传送出场景")
    end
    self:LeaveBattle(pid)
end

function CBattle:OnWarFail(oWar, pid, npcobj, mArgs)
    if self.m_Killer and self.m_Killer == pid then
        mArgs.cancel_failtips = true
    end
    super(CBattle).OnWarFail(self,oWar,pid,npcobj,mArgs)
    if not self.m_oBoss then
        return
    end
    if npcobj and npcobj.m_iBossId and mArgs.win_side ~= 0 then --mArgs.win_side = 0  : escapewar
        self:BossWarFail(pid)
    end
end

function CBattle:BossWarFail(iPid)
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    local mSpawnPoint = mBossInfo["spawn_point"]
    local mPos = mSpawnPoint[math.random(#mSpawnPoint)]
    self:TransferPlayerBySceneID(iPid,self.m_iScene,mPos["posx"],mPos["posy"])
    global.oNotifyMgr:Notify(iPid,"被人形怪物击败，已被传送至当前场景随机位置")
end

function CBattle:GetCreateWarArg(mArg)
    mArg.war_type = gamedefines.WAR_TYPE.FIELDBOSS_TYPE
    mArg.remote_war_type = "fieldboss"
    mArg.remote_args = {}
    mArg.remote_args.bossid= self.m_iBossId
    return mArg
end

function CBattle:CreateMonster(oWar,iMonsterIdx,npcobj)
    local oMonster
    oMonster = super(CHuodong).CreateMonster(self,oWar,iMonsterIdx,npcobj)
    local oBoss = self.m_oBoss
    oMonster.m_mData["hp"] = oBoss:GetCurHp()
    return oMonster
end

function CBattle:TransMonsterAble(oWar,sAttr,mArgs)
    mArgs = mArgs or {}
    local sValue = mArgs.value
    local mEnv = mArgs.env
    mEnv.bosslv = self.m_oBoss:GetGrade()
    local iValue = formula_string(sValue,mEnv)
    return iValue
end

function CBattle:GetKillMessage()
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    return mBossInfo["died_text"]
end

function CBattle:GetHpTips()
    local mBossInfo = self:GetBossBaseInfo(self.m_iBossId)
    return mBossInfo["hp_tips"]
end

function CBattle:GetCurHpRate()
    if self.m_oBoss then
        return self.m_oBoss:GetCurHpRate()
    end
    return 0
end

function CBattle:GetEndLimitTime()
    local m = self:GetBossBaseInfo(self.m_iBossId)
    return m["end_limit_time"]
end

function CBattle:EndCountDown(iTime,iInterval)
    if iTime <= 2  and iTime > 0 then
        local sMsg = string.format("讨伐清剿时间还剩%d分钟，结界即将关闭，所有人将被强制传送离开。",iTime)
        local mNet = {
            content = sMsg,
            tag_type = 0,
            horse_race = 1,
        }
        local mData = {
            message = "GS2CSysChat",
            type = gamedefines.BROADCAST_TYPE.FIELD_BOSS,
            id = self.m_iBossId,
            data = mNet,
            exclude = mExclude,
        }
        interactive.Send(".broadcast", "channel", "SendChannel", mData)
    end
    if iTime ~= 0 then
        local iNextTime = (iTime-iInterval) >= 0 and (iTime-iInterval) or 0
        local iNextInterval = (iTime-iInterval) > 0 and 2 or 1
        local iBossId = self.m_iBossId
        local func = function()
            local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
            local oBossBattle = oHuodong.m_mBossBattle[iBossId]
            oBossBattle:EndCountDown(iNextTime,iNextInterval)
        end
        self:DelTimeCb("_EndCountDown")
        self:AddTimeCb("_EndCountDown",iInterval*60*1000,func)
    else
        if self.m_oBoss then
            self:Close()
        end
    end
end

function CBattle:HPChange(iHp,plist)
    local oBoss = self.m_oBoss
    if not oBoss  or oBoss:IsDead() then
        return
    end
    for _,info in pairs(plist) do
        local pid,hit,warid = table.unpack(info)
        self.m_lHit[warid] = self.m_lHit[warid] or {}
        self.m_lHit[warid][pid] = (self.m_lHit[warid][pid] or 0) + hit
    end
    local oWarMgr = global.oWarMgr
    local oWorldMgr = global.oWorldMgr
    local oNotify = global.oNotifyMgr
    local mKiller = plist[math.random(#plist)]
    local pid = mKiller[1]
    local iOldHpRate = self:GetCurHpRate()
    oBoss:HPCHange(iHp)
    local iBossHpRate = self:GetCurHpRate()
    local iEnterHpLimit = self:GetEnterHpLimit()
    if iOldHpRate > iEnterHpLimit and iBossHpRate < iEnterHpLimit then
        local sMsg = self:GetHpTips()
        sMsg = string.gsub(sMsg,"$name",oBoss:Name())
        sMsg = string.gsub(sMsg,"$hp",iEnterHpLimit)
        oNotify:SendPrioritySysChat("fieldboss_char",sMsg,1)
        if not oBoss:IsDead() then
            local iEndTimeLimit = self:GetEndLimitTime()
            self:EndCountDown(iEndTimeLimit,iEndTimeLimit-5)

        end
    end
    if oBoss:IsDead() then
        self:KickoutWar(1)
        self.m_Killer = pid
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
        self.m_KillerName = oPlayer:GetName()
        local sMsg = string.gsub(self:GetKillMessage(),"$role",self.m_KillerName or tostring(pid))
        sMsg = string.gsub(sMsg,"$name",oBoss:Name())
        oNotify:SendPrioritySysChat("fieldboss_char",sMsg,1)

        self:RewardKiller(pid)
        self:BroadcastBossHP()
        self:BossDead()
        local oHuodong = self:Huodong()
        oHuodong:BossEnd(self.m_iBossId,oBoss:GetDeadTime(),1)
    end
end

function CBattle:KickoutWar(iWin)
    local oWarMgr = global.oWarMgr
    for _,v in pairs(oWarMgr.m_lWarRemote) do
            interactive.Send(v,"fieldboss","BossDie",{win=iWin,bossid = self.m_iBossId})
    end
end

function CBattle:PackHpInfo()
    local iHp = self.m_oBoss:GetCurHp()
    local iMaxHp = self.m_oBoss:GetBornHp()
    return {hp = iHp,maxhp = iMaxHp}
end

function CBattle:ForcePk(oPlayer,iTarget)
    if not self.m_oBoss then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"BOSS已被击杀,禁止战斗")
        return
    end
    local oTarget = global.oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget or not self.m_mPlayerList[iTarget] then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"玩家已离开场景")
        return
    end
    if oTarget.m_oStateCtrl:GetState(1004) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"玩家处于无敌状态，禁止PK")
        return
    end
    local iOrgId1 = oPlayer:GetOrgID()
    local iOrgId2 = oTarget:GetOrgID()
    local oPlayerTeam = oPlayer:HasTeam()
    local oTargetTeam = oTarget:HasTeam()
    if oTargetTeam and not oTargetTeam:IsShortLeave(iTarget) then
        local oLeader = global.oWorldMgr:GetOnlinePlayerByPid(oTargetTeam:Leader())
        iOrgId2 = oLeader:GetOrgID()
    end
    if iOrgId2 == iOrgId1 and iOrgId1 ~= 0 then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"攻击失败，不可对同公会的成员发起攻击")
        return
    end
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        return
    end
    oNowWar = oTarget.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"玩家正在战斗中")
        return
    end
    local mArgs = {
        war_type = gamedefines.WAR_TYPE.FIELDBOSSPVP_TYPE,
        remote_war_type = "fieldbosspvp",
        remote_args = {bossid = self.m_iBossId},
    }
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:CreateWar(mArgs)
    oWar:SetData("close_auto_skill",true)
    oWar:SetData("bossid",self.m_iBossId)
    oWar:SetData("pk",true)
    local ret
    if oPlayerTeam and not oPlayerTeam:IsShortLeave(oPlayer.m_iPid) then
        ret = oWarMgr:TeamEnterWar(oPlayer,oWar:GetWarId(),{camp_id=1},true)
    else
        ret = oWarMgr:EnterWar(oPlayer, oWar:GetWarId(), {camp_id = 1}, true)
    end
    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end
    if oTargetTeam and not oTargetTeam:IsShortLeave(iTarget) then
        ret = oWarMgr:TeamEnterWar(oTarget,oWar:GetWarId(),{camp_id=2},true)
    else
        ret = oWarMgr:EnterWar(oTarget, oWar:GetWarId(), {camp_id = 2}, true)
    end
    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end
    local iBossId = self.m_iBossId
    local fWarEndCallback = function (mArgs)
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        local oBossBattle = oHuodong.m_mBossBattle[iBossId]
        if oBossBattle then
            oBossBattle:ForcePkWarEndCallBack(oWar,oPlayer.m_iPid,iTarget,mArgs)
        end
    end
    local fEscapeCallback = function (mData)
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        local oBossBattle = oHuodong.m_mBossBattle[iBossId]
        if oBossBattle then
            oBossBattle:EscapeWar(mData.pid)
        end
    end
    oWarMgr:SetWarEndCallback(oWar:GetWarId(),fWarEndCallback)
    oWarMgr:SetEscapeCallBack(oWar:GetWarId(), fEscapeCallback)
    oWarMgr:StartWarConfig(oWar:GetWarId())
    self:AddPkList(oWar:GetWarId())
    record.user("fieldboss","foece_pk",{pid=oPlayer.m_iPid,target = iTarget,bossid=self.m_iBossId})
end

function CBattle:AddPkList(iWarId)
    self.m_lPkWar[iWarId] = true
end

function CBattle:RemovePkList(iWarId)
    if self.m_lPkWar and self.m_lPkWar[iWarId] then
        self.m_lPkWar[iWarId] = nil
    end
    if not self.m_oBoss and (not self.m_lPkWar or table_count(self.m_lPkWar) <= 0) then
        self:PrepareReward()
    end
end

function CBattle:PrepareReward()
    local iBossId = self.m_iBossId
    local func = function()
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        if oHuodong then
            local oBossBattle = oHuodong.m_mBossBattle[iBossId]
            if oBossBattle then
                oBossBattle:StarReward()
            end
        end
    end
    self:DelTimeCb("_PrepareReward"..iBossId)
    self:AddTimeCb("_PrepareReward"..iBossId,30*1000,func)
end

function CBattle:ForcePkWarEndCallBack(oWar,iCamp1,iCamp2,mArgs)
    self:PopWarPKRewardUI(oWar:GetWarId(),mArgs)
    if mArgs then
        local iWinSide = 0
        if mArgs.win_side and mArgs.win_side ~= 0 then
            iWinSide = mArgs.win_side
            local mFailList = mArgs.fail_list or {}
            local iFailer = 0
            for _,iPid in pairs(mFailList) do
                iFailer = iFailer + 1
                global.oNotifyMgr:Notify(iPid,"由于你被其它玩家击败，已被传离场景")
                global.oAchieveMgr:PushAchieve(iPid, "人形讨伐中，累计被击败次数", {value=1})
                self:LeaveBattle(iPid,true)
            end
            local mWinList = mArgs.win_list or {}
            for _,iPid in pairs(mWinList) do
                global.oAchieveMgr:PushAchieve(iPid, "人形讨伐中，累计击败玩家数量", {value=iFailer})
            end
        end
        record.user("fieldboss","pk_result",{pid=iCamp1,target = iCamp2,winner = iWinSide,bossid=self.m_iBossId})
    end
    self:RemovePkList(oWar:GetWarId())
end

function CBattle:PopWarPKRewardUI(iWarid,mArgs)
    local oWorldMgr = global.oWorldMgr
    if mArgs.win_side ~= 0 then
        local sWinTips = ""
        local sFaliTips = ""
        local iWiner = mArgs.win_list[1]
        local iFailer = mArgs.fail_list[1]
        local oWiner = oWorldMgr:GetOnlinePlayerByPid(iWiner)
        local oFailer = oWorldMgr:GetOnlinePlayerByPid(iFailer)
        if oWiner and oFailer then

            if table_count(mArgs.fail_list) > 1 then
                sWinTips = string.format("你击败了%s带领的队伍",oFailer:GetName() or tostring(iFailer))
            else
                sWinTips = string.format("你击败了%s",oFailer:GetName() or tostring(iFailer))
            end
            mArgs.win_tips = sWinTips

            if table_count(mArgs.win_list) > 1 then
                sFaliTips = string.format("你被%s带领的队伍击败了",oWiner:GetName() or tostring(iWiner))
            else
                sFaliTips = string.format("你被%s击败了",oWiner:GetName() or tostring(iWiner))
            end
            mArgs.fail_tips = sFaliTips
        end
    end
    super(CBattle).PopWarRewardUI(self,iWarid,mArgs)
    -- body
end

function CBattle:GetBaodiReward()
    local mData = self:GetBossBaseInfo(self.m_iBossId)
    return mData["baodi_reward"]
end

function CBattle:GetKillerReward()
    local mData = self:GetBossBaseInfo(self.m_iBossId)
    return mData["kill_reward"]
end

function CBattle:BossDead()
    local oWorldMgr = global.oWorldMgr
    local mRewardId = self:GetBaodiReward()
    for iPid,info in pairs(self.m_mPlayerList) do
        global.oNotifyMgr:Notify(iPid,"BOSS已被击杀，宝物将在30秒后掉落")
        for _,iRewardId in pairs(mRewardId) do
            self:Reward(iPid,iRewardId,{reason="野外BOSS保底奖励"})
            record.user("fieldboss","reward",{pid=iPid,bossid=self.m_iBossId,rewardid = iRewardId,reward_type="野外BOSS保底奖励"})
        end
        if self.m_iBossId == 1 then
            global.oAchieveMgr:PushAchieve(iPid, "击杀熊猫爷爷次数", {value=1})
        elseif self.m_iBossId == 2 then
            global.oAchieveMgr:PushAchieve(iPid, "击杀丑无次数", {value=1})
        elseif self.m_iBossId == 3 then
            global.oAchieveMgr:PushAchieve(iPid, "击杀绯翼次数", {value=1})
        end
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:LogAnalyGame("fieldboss",oPlayer)
        end
    end
    if table_count(self.m_lPkWar) <= 0 then
        self:PrepareReward()
    end
    self:RemoveTempNpc(self.m_oBoss)
    self.m_oBoss  = nil
    self:DelTimeCb("_BroadcastBossHP")
end

function CBattle:GetServant(oWar,mArgs)
    local  mMonsterList = {90001,90002,90003,90003}
    local mServant = {}
    for _,iMonsterIdx in ipairs(mMonsterList) do
        local oMonster = self:CreateMonster(oWar,iMonsterIdx,nil, mArgs)
        mServant[iMonsterIdx] = oMonster:PackAttr()
    end
    return mServant
end

function CBattle:RewardKiller(iPid)
    record.user("fieldboss","boss_dead",{pid=iPid,bossid=self.m_iBossId})
    global.oNotifyMgr:Notify(iPid,"你成功击杀了BOSS")
    local mRewardId = self:GetKillerReward()
    for _,iRewardId in pairs(mRewardId) do
        self:Reward(iPid,iRewardId,{reason="击杀野外BOSS奖励"})
        record.user("fieldboss","reward",{pid=iPid,bossid=self.m_iBossId,rewardid = iRewardId,reward_type="击杀野外BOSS奖励"})
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        self:LogAnalyGame("fieldboss",oPlayer)
    end
end

function CBattle:GetFallReward()
    local mData = self:GetBossBaseInfo(self.m_iBossId)
    return mData["fall_reward"]
end

function CBattle:StarReward(iTime,bLoad)
    local mRewardInfo = self:GetFallReward()
    local mPos = {}
    local iMapId = self:GetMapId()
    local iAmount = table_count(mRewardInfo)
    local mPos = global.oSceneMgr:RandomMonsterPos(iMapId,iAmount)
    for index,npcid in pairs(mRewardInfo) do
        if (not bLoad) or (bLoad and self.m_mReward[npcid]) then
            local oNpc = self:NewRewardItemObj(npcid,mPos[index])
            self:Npc_Enter_Scene(oNpc,self.m_iScene,oNpc:PosInfo())
            self.m_mReward[npcid] = true
        end
    end
    if not bLoad then
        for iPid,_ in pairs(self.m_mPlayerList) do
            global.oNotifyMgr:Notify(iPid,"宝箱已出现，大家捉紧时间拾取！")
        end
    end
    self:StartCountDown(iTime)
end

function CBattle:NewRewardItemObj(iNpcId,mPos)
    local mArgs = self:PacketNpcInfo(iNpcId)
    local iMapId = mArgs["map_id"]
    local posx,posy = table.unpack(mPos)
    mArgs.pos_info.x = posx
    mArgs.pos_info.y = posy
    mArgs.bossid = self.m_iBossId
    mArgs.scene = self.m_iScene
    mArgs.rewardid = iNpcId
    local oTempNpc = rewardobj.NewItem(mArgs)
    oTempNpc.m_oBattle = self
    self.m_mNpcList[oTempNpc.m_ID] = oTempNpc
    return oTempNpc
end

function CBattle:OnLogin(oPlayer)
    if self.m_oBoss then--BOSS还没死亡则刷一次血量给玩家
        self:HPNotify(oPlayer)
    end
    self:BroadcastBattleInfo()
end

function CBattle:StartCountDown(iTime)
    local iBossId = self.m_iBossId
    local func = function()
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        if oHuodong then
            local oBossBattle = oHuodong.m_mBossBattle[iBossId]
            if oBossBattle then
                oBossBattle:RewardEnd()
            end
        end
    end
    local iRewardTime = iTime or 30
    self.m_RewardEndTime = get_time() + iRewardTime*60
    self:DelTimeCb("RewardCountDown"..iBossId)
    self:AddTimeCb("RewardCountDown"..iBossId,iRewardTime*60*1000,func)

    self:BroadcastBattleInfo()
end

function CBattle:Pick(oPlayer,oNpc)
    local oHuodong = self:Huodong()
    oHuodong:ClearKeep(oPlayer:GetPid())
    self:do_look(oPlayer, oNpc)
    global.oAchieveMgr:PushAchieve(oPlayer.m_iPid, "人形讨伐中，累计拾取宝箱次数", {value=1})
    record.user("fieldboss","reward",{pid=oPlayer.m_iPid,bossid=self.m_iBossId,rewardid = oNpc.m_iRewardId,reward_type="野外BOSS宝箱奖励"})
    self.m_mReward[oNpc.m_iRewardId] = nil
    self:RemoveTempNpc(oNpc)
    self:BroadcastBattleInfo()
    oHuodong:LogAnalyGame("fieldboss",oPlayer)
end

function CBattle:RewardEnd(sMsg)
    self:DelTimeCb("RewardCountDown"..self.m_iBossId)
    for iNpcId,oNpc in pairs(self.m_mNpcList) do
        self:RemoveTempNpc(oNpc)
    end

    for iPid,info in pairs(self.m_mPlayerList) do
        global.oNotifyMgr:Notify(iPid,sMsg or "拾取时间到，场景关闭")
    end
    local oHuodong = self:Huodong()
    oHuodong:RewardEnd(self.m_iBossId)
end

function CBattle:Close()
    self:DelTimeCb("_EndCountDown")
    self:DelTimeCb("_PrepareReward"..self.m_iBossId)
    self:DelTimeCb("_BroadcastBossHP")
    self:DelTimeCb("RewardCountDown"..self.m_iBossId)
    for iNpcId,oNpc in pairs(self.m_mNpcList) do
        self:RemoveTempNpc(oNpc)
    end
    local oHuodong = self:Huodong()
    oHuodong:NotifyBossEnd(self.m_iBossId)
    for iPid,info in pairs(self.m_mPlayerList) do
        global.oNotifyMgr:Notify(iPid," 活动结束，场景已关闭")
        self:LeaveBattle(iPid,true)
    end

end

function CBattle:SetFieldBossHp(iRate)
    local oBoss = self.m_oBoss
    if oBoss then
        oBoss:SetCurHpRate(iRate)
    end
end
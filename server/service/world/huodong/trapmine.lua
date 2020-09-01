--import module
local global  = require "global"
local extend = require "base.extend"
local extend = require "base.extend"
local res = require"base.res"
local record = require "public.record"
local interactive = require "base.interactive"

local analy = import(lualib_path("public.dataanaly"))
local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))

local NPC_TIMEOUT = 30 * 60  --暗雷怪倒计时
local NPC_OWNER = 5 * 60 --拥有暗雷怪的时间

local gsub = string.gsub
local random = math.random

function NewHuodong(sHuodongName)
    return CTrapMine:New(sHuodongName)
end

function NewMapScene(...)
    return CMapScene:New(...)
end

function NewMember(...)
    return CMember:New(...)
end

CTrapMine = {}
CTrapMine.__index = CTrapMine
inherit(CTrapMine, huodongbase.CHuodong)

function CTrapMine:New(sHuodongName)
    local o = super(CTrapMine).New(self, sHuodongName)
    o.m_sName = sHuodongName
    o.m_mMapScene = {}
    o.m_mRarePartner = {}
    o.m_iRareMonster = 0
    return o
end

function CTrapMine:Init()
    self:TryStartRewardMonitor()
end

function CTrapMine:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
        self:SetRareMonsterAmount(0)
        self:InitTodayRarePartner()
        local plist = global.oWorldMgr:GetOnlinePlayerList()
        for pid, oPlayer in pairs(plist) do
            self:SendLoginNpc(oPlayer)
        end
    end
end

function CTrapMine:GetTodayRarePartye(iMapId)
    if not next(self.m_mRarePartner) then
        self:InitTodayRarePartner()
    end
    return self.m_mRarePartner[iMapId] or {}
end

function CTrapMine:InitTodayRarePartner()
    self.m_mRarePartner = {}
    local iType = gamedefines.TRAPMINE_MONSTER.RARE
    local mData = res["daobiao"]["huodong"][self:ResName()]["monster_pool"]
    for iMapId, m in pairs(mData) do
        local mRare = m[iType]
        if mRare then
            local lRareMonster = table_deep_copy(mRare.rare_monster)
            local lPartype = extend.Array.multi_weight_choose(lRareMonster, "weight", 3)
            local mPar = {}
            for _, mm in ipairs(lPartype) do
                mPar[mm.partype] = 1
            end
            self.m_mRarePartner[iMapId] = mPar
        end
    end
end

function CTrapMine:OnLogin(oPlayer, bReEnter)
    local iPid = oPlayer:GetPid()
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iMapId = oNowScene and oNowScene:MapId()
    if not oPlayer:HasTeam() or oPlayer:IsTeamLeader() then
        self:StopTrapmine(oPlayer, iMapId)
        self:SendOfflineInfo(oPlayer)

        if not self:IsOfflineTrapmine(iPid) then
            if oPlayer:GetInfo("auto_trapmine") then
                self:StopOfflineTrapmine(iPid)
            end
        end
    elseif self:IsTrapmining(oPlayer) then
        local oMem = self:GetMember(iMapId, iPid)
        if oMem then
            oMem:GS2CTrapmineStatus()
            oMem:GS2CTrapmineTotalReward()
        end
    end
    self:SendLoginNpc(oPlayer)
end

function CTrapMine:SendOfflineInfo(oPlayer)
    local mOffline = oPlayer.m_oActiveCtrl:GetData("trapmine_offline", {})
    if next(mOffline) then
        local iDisc = mOffline.disconnnect
        local iLogout = mOffline.logout or get_time()
        if iDisc and iLogout and iLogout > iDisc then
            local items = mOffline.item or {}
            local iOffline = iLogout - iDisc
            --离线超过30秒才弹奖励窗
            if next(items) and iOffline > 30 then
                oPlayer:Send("GS2CTramineOfflineInfo", {
                    offline_second = iOffline,
                    cost_point = mOffline.cost_point or 0,
                    itemlist = table_deep_copy(items),
                    })
            end
        end
    end
    oPlayer.m_oActiveCtrl:SetData("trapmine_offline", {})
end

function CTrapMine:SendLoginNpc(oPlayer)
    local lNet = {}
    local iPid = oPlayer:GetPid()
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iMapId = oScene:MapId()
    local lNpcList = self:GetNpcListByMap(iMapId)
    for _, oNpc in ipairs(lNpcList) do
        if not is_release(oNpc) and oNpc.m_iOwnerId == iPid then
            table.insert(lNet, oNpc:PackNetInfo())
        end
    end
    if not next(self.m_mRarePartner) then
        self:InitTodayRarePartner()
    end
    local lRare = {}
    for iMapId, mPar in pairs(self.m_mRarePartner) do
        local m = {}
        m.map_id = iMapId
        m.partypes = table_key_list(mPar)
        table.insert(lRare, m)
    end
    oPlayer:Send("GS2CLoginTrapmine", {npc_list = lNet, rare_monster = lRare})
end

function CTrapMine:OnDisconnected(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iMapId = oNowScene and oNowScene:MapId()
    local iPid = oPlayer:GetPid()
    if not self:IsOfflineTrapmine(iPid) then
        self:StopTrapmine(oPlayer, iMapId)
    else
        local mOffline = oPlayer.m_oActiveCtrl:GetData("trapmine_offline", {})
        mOffline.disconnnect = get_time()
        if self:GetMemberStatus(oPlayer) ~= gamedefines.TRAPMINE_STATUS.OFFLINE then
            self:StartOfflineTrapmine(iPid)
        end
    end
end

function CTrapMine:OnLogout(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iMapId = oNowScene and oNowScene:MapId()
    if self:IsTrapmining(oPlayer) then
        local mOffline = oPlayer.m_oActiveCtrl:GetData("trapmine_offline", {})
        if mOffline.disconnnect then
            mOffline.logout = get_time()
        end
        oPlayer.m_oActiveCtrl:SetData("trapmine_offline", mOffline)
    end
    self:StopTrapmine(oPlayer, iMapId)
end

function CTrapMine:NeedSave()
    return true
end

function CTrapMine:Save()
    local mData = {}
    mData.rare_monster = {
        fight_amount = self.m_iRareMonster,
        time = get_time(),
    }
    mData.box_monster = {
        fight_amount = self.m_iBoxMonster,
        time = get_time(),
    }
    return mData
end

function CTrapMine:Load(mData)
    mData = mData or {}

    local mRare = mData.rare_monster or {}
    local iTime = mRare.time or get_time()
    if get_dayno(iTime) == get_dayno() then
        self:SetRareMonsterAmount(mRare.fight_amount or 0)
    else
        self:SetRareMonsterAmount(0)
    end

    local mBox = mData.box_monster or {}
    local iTime = mBox.time or get_time()
    if get_dayno(iTime) == get_dayno() then
        self:SetBoxMonsterAmount(mBox.fight_amount or 0)
    else
        self:SetBoxMonsterAmount(0)
    end
end

function CTrapMine:MergeFrom(mFromData)
    self:Dirty()
    mFromData = mFromData or {}
    local mRare = mFromData.rare_monster or {}
    local iTime = mRare.time or get_time()
    if get_dayno(iTime) == get_dayno() then
        self.m_iRareMonster = math.min(self.m_iRareMonster, mRare.fight_amount)
    end
    local mBox = mFromData.box_monster or {}
    iTime = mBox.time or get_time()
    if get_dayno(iTime) == get_dayno() then
        self.m_iBoxMonster = math.min(self.m_iBoxMonster, mBox.fight_amount)
    end
    return true
end

function CTrapMine:AdjustTeamLeader(oTeam)
    local oLeader = oTeam:GetTeamLeader()
    if oLeader then
        local iPid = oLeader:GetPid()
        local oScene = oLeader.m_oActiveCtrl:GetNowScene()
        local iMapId = oScene:MapId()
        local oWar = oLeader:GetNowWar()
        if not self:IsOfflineTrapmine(iPid) then
            local oSceneMgr = global.oSceneMgr
            if not self:ValidStart(oLeader,iMapId) then
                return
            end
            oSceneMgr:ClickOfflineTrapMineMap(oLeader,iMapId)
            self:ClientStartOfflineTrapmine(oLeader, iMapId)
            local oWorldMgr = global.oWorldMgr
            local lMem = oLeader:GetTeamMember()
            for _, iMem in ipairs(lMem) do
                if iMem ~= iPid then
                    local o = oWorldMgr:GetOnlinePlayerByPid(iMem)
                    if o then
                        o:SyncSceneInfo({trapmine = 0})
                    end
                end
            end
        else
            if self:ValidStart(oLeader, iMapId) then
                self:StartTrapmine(oLeader, iMapId)
            end
        end
    end
end

function CTrapMine:BackTeam(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        local oLeader = oTeam:GetTeamLeader()
        if self:IsTrapmining(oLeader) then
            self:SetMemberStatus(oPlayer, gamedefines.TRAPMINE_STATUS.START)
        end
    end
end

function CTrapMine:LeaveTeam(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer and self:IsTrapmining(oPlayer) then
        self:ClearRewardInfo(oPlayer)
        self:SetMemberStatus(oPlayer, gamedefines.TRAPMINE_STATUS.NORMAL)
        self:StopOfflineTrapmine(iPid)
    end
end

function CTrapMine:ConfigWar(oWar,pid,npcobj,iFight,mInfo)
    if mInfo.auto_skill then
        oWar:SetData("open_auto_skill",true)
    else
        oWar:SetData("close_auto_skill",true)
    end
end

function CTrapMine:GetMapScene(iMapId)
    return self.m_mMapScene[iMapId]
end

function CTrapMine:AddMapScene(o)
    if o then
        self.m_mMapScene[o:MapId()] = o
    end
end

function CTrapMine:GetMember(iMapId, iPid)
    local oMapScene = self:GetMapScene(iMapId)
    if oMapScene then
        return oMapScene:GetMember(iPid)
    end
end

function CTrapMine:EnterScene(oPlayer, iMapId)
    local oWar = oPlayer:GetNowWar()
    if oWar and oWar.m_iWarType == gamedefines.WAR_TYPE.TRAPMINE_TYPE then
        return
    end

    local iPid = oPlayer:GetPid()
    local oMapScene = self:GetMapScene(iMapId)
    if not oMapScene then
        oMapScene = NewMapScene(iMapId)
    end
    if oMapScene then
        self:AddMapScene(oMapScene)
        local oMem = oMapScene:GetMember(iPid)
        if not oMem then
            oMem = NewMember(iMapId, iPid)
        else
            return
        end
        if oMem then
            oMapScene:AddMember(oMem)
            oMem:EnterScene()
        end
    end
end

function CTrapMine:DelMember(iMapId, iPid)
    local oMapScene = self:GetMapScene(iMapId)
    if oMapScene then
        oMapScene:DelMember(iPid)
    end
end

function CTrapMine:LeaveScene(oPlayer, iMapId)
    self:DelMember(iMapId, oPlayer:GetPid())
end

function CTrapMine:IsTrapmining(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iMapId = oNowScene and oNowScene:MapId()
    local oMem =  self:GetMember(iMapId, oPlayer:GetPid())
    if oMem then
        return oMem:IsTrapmining()
    end
    return false
end

function CTrapMine:ValidStart(oPlayer, iMapId)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()

    if oPlayer.m_oActiveCtrl:GetNowWar() then
        return false
    end
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if not oNowScene:HasAnLei() or oNowScene:MapId() ~= iMapId then
        return false
    end

    if not oPlayer:ValidTrapminePoint(1, {cancel_tip=1}) then
        oNotifyMgr:Notify(iPid, "探索点不足，无法探索。")
        return false
    end
    if oPlayer:HasTeam() and not oPlayer:IsTeamLeader() then
        oNotifyMgr:Notify(iPid, "只有队长可以发起探索")
        return false
    end

    local lMem = oPlayer:GetTeamMember() or {iPid}
    for _, iMem in ipairs(lMem) do
        local o = oWorldMgr:GetOnlinePlayerByPid(iMem)
        if o and  not  self:IsOpenGrade(o) then
            oNotifyMgr:Notify(iPid, string.format("%s未达到探索等级，无法进行探索。", o:GetName()))
            return false
        end
    end
    return true
end

function CTrapMine:StartTrapmine(oPlayer, iMapId)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local oMapScene = self:GetMapScene(iMapId)
    if oMapScene then
        local lMem = oPlayer:GetTeamMember() or {iPid}
        for _, iMem in ipairs(lMem) do
            local iStatus = gamedefines.TRAPMINE_STATUS.START
            local oTarget = oWorldMgr:GetOnlinePlayerByPid(iMem)
            local o = oMapScene:GetMember(iMem)
            if o and oTarget then
                if  not oTarget:HasTeam() or oTarget:IsTeamLeader() then
                    local iTriggerTime = o:GetTriggerTime()
                    local oScene = oTarget.m_oActiveCtrl:GetNowScene()
                    oScene.m_oAnLeiCtrl:UpdateTriggerTime(iPid, iTriggerTime)
                    oScene.m_oAnLeiCtrl:Start(iPid)
                    o:SetTriggerTime(get_time())
                    if self:IsClientAutoStart(oTarget) then
                        iStatus = gamedefines.TRAPMINE_STATUS.OFFLINE
                    end
                    oTarget:SyncSceneInfo({trapmine = 1})
                end
                o:SetStatus(iStatus)
            end
        end
    end
end

function CTrapMine:SetMemberStatus(oPlayer,iStatus)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iMapId = oScene:MapId()
    local iPid = oPlayer:GetPid()
    local oMapScene = self:GetMapScene(iMapId)
    if oMapScene then
        local oMem = oMapScene:GetMember(iPid)
        if oMem then
            oMem:SetStatus(iStatus)
        end
    end
end

function CTrapMine:ClearRewardInfo(oPlayer)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iMapId = oScene:MapId()
    local iPid = oPlayer:GetPid()
    local oMapScene = self:GetMapScene(iMapId)
    if oMapScene then
        local oMem = oMapScene:GetMember(iPid)
        if oMem then
            oMem:ClearRewardInfo()
        end
    end
end

function CTrapMine:GetMemberStatus(oPlayer)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iMapId = oScene:MapId()
    local iPid = oPlayer:GetPid()
    local oMapScene = self:GetMapScene(iMapId)
    if oMapScene then
        local oMem = oMapScene:GetMember(iPid)
        if oMem then
            return oMem:GetStatus()
        end
    end
end

function CTrapMine:ValidTrigger(oPlayer, iMapId)
    local oMem = self:GetMember(iMapId, iPid)
    if not oMem then
        return false
    end
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        return false
    end
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oNowScene:MapId() ~= iMapId then
        return false
    end
    return true
end

function CTrapMine:Trigger(oPlayer, iMapId)
    local iPid = oPlayer:GetPid()
    if not self:ValidStart(oPlayer,iMapId) then
        self:StopTrapmine(oPlayer, iMapId)
        return
    end
    if not self:IsTrapmining(oPlayer) then
        return
    end
    local oMem = self:GetMember(iMapId, iPid)
    if oMem then
        if self:TriggerNpc(oPlayer, iMapId) then
            if not self:ValidStart(oPlayer, iMapId) then
                self:StopTrapmine(oPlayer, iMapId)
            else
                self:StartTrapmine(oPlayer, iMapId)
            end
        else
            self:TriggerCommon(oPlayer, iMapId)
        end
    end
end

function CTrapMine:TriggerNpc(oPlayer, iMapId)
    local oWorldMgr = global.oWorldMgr
    local lMem = oPlayer:GetTeamMember() or {oPlayer:GetPid()}
    for _, iMem in ipairs(lMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(iMem)
        local iMonster, iMonsterType = self:GetTriggerMonster(oMem, iMapId)
        if iMonster and iMonsterType then
            self:CreateNpc(oMem, iMapId, iMonster, iMonsterType)
            return true
        end
    end
    return false
end

function CTrapMine:GetTriggerMonster(oPlayer, iMapId)
    local iRareMonster = self:GetRareMonster(oPlayer, iMapId)
    if iRareMonster then
        return iRareMonster, gamedefines.TRAPMINE_MONSTER.RARE
    end
    local iBoxMonster = self:GetBoxMonster(oPlayer, iMapId)
    if iBoxMonster then
        return iBoxMonster, gamedefines.TRAPMINE_MONSTER.BOX
    end
    return nil, nil
end

function CTrapMine:TriggerCommon(oPlayer, iMapId)
    local iFight = self:GetNormalFightId(oPlayer, iMapId)
    if iFight then
        local iStatus = gamedefines.TRAPMINE_STATUS.START
        if self:IsClientAutoStart(oPlayer) then
            iStatus = gamedefines.TRAPMINE_STATUS.OFFLINE
        end
        local oMem = self:GetMember(iMapId, oPlayer:GetPid())
        oMem:SetStatus(iStatus)
        local mArgs = {
            auto_skill = true,
        }
        if not oPlayer:GetNetHandle() then
            mArgs.remote_war_type = "offline_trapmine"
        end
        self:StartWar(oPlayer:GetPid(), iMapId, iFight, nil, mArgs)
        self:LogTrapmine(oPlayer, "trigger", iMapId, {npcid=0})
    end
end

function CTrapMine:StopTrapmine(oPlayer, iMapId)
    local iPid = oPlayer:GetPid()
    if self:IsTrapmining(oPlayer) then
        local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
        if oScene and oScene:HasAnLei() then
            oScene.m_oAnLeiCtrl:Stop(iPid)
        end
        if not oPlayer:HasTeam() or oPlayer:IsTeamLeader() then
            self:ClearAllShowReward(oPlayer, iMapId)
            self:SetAllMemberStatus(oPlayer, iMapId, gamedefines.TRAPMINE_STATUS.NORMAL)
            oPlayer:SyncSceneInfo({trapmine = 0})
        end
    end
    if self:IsOfflineTrapmine(iPid) then
        self:StopOfflineTrapmine(iPid)
    end
end

function CTrapMine:LogTrapmine(oPlayer, sType, iMapId,mArgs)
    local mLog = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        map_id = iMapId,
    }
    if mArgs then
        table_combine(mLog, mArgs)
    end
    record.user("trapmine", sType, mLog)
end

function CTrapMine:IsClose(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if oWorldMgr:IsClose("trapmine") then
        oNotifyMgr:Notify(iPid, "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return true
    end

    return false
end

function CTrapMine:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("trapmine", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CTrapMine:ValidFightRareMonster(oPlayer, oNpc)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if self.m_iRareMonster >= self:GetRareMonsterDailyServer() then
        self:DoScript2(iPid, oNpc, "DI301")
        return false
    end
    local k = oPlayer.m_oToday:Query("trapmine_rare_monster", 0)
    if k >= self:GetRareMonsterDailyPersonal() then
        self:DoScript2(iPid, oNpc, "DI302")
        return false
    end
    return true
end

function CTrapMine:ValidFightBoxMonster(oPlayer, oNpc)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if self.m_iBoxMonster >= self:GetBoxMonsterDailyServer() then
        self:DoScript2(iPid, oNpc, "DI301")
        return false
    end
    local k = oPlayer.m_oToday:Query("trapmine_box_monster", 0)
    if k >= self:GetBoxMonsterDailyPersonal() then
        self:DoScript2(iPid, oNpc, "DI302")
        return false
    end
    return true
end

function CTrapMine:ValidFightMonster(oPlayer, oNpc)
    local iPid = oPlayer:GetPid()
    local iMonsterType = oNpc.boss
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        return false
    end
    if oNpc:IsOwnerProtect(oPlayer) then
        self:DoScript2(iPid, oNpc, "DI304")
        return false
    end
    local lNpcList = self:GetNpcListByMap(oNpc:MapId())
    for _, obj in ipairs(lNpcList) do
        if not is_release(obj) and oNpc:Type() == obj:Type() and obj:InWar() then
            self:DoScript2(iPid, oNpc, "DI200")
            return false
        end
    end
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    if not oPlayer:IsSingle() then
        local oTeam = oPlayer:HasTeam()
        local lMem = oTeam:GetTeamMember()
        local lMsg = {}
        for _, iMem in ipairs(lMem) do
            local o = oWorldMgr:GetOnlinePlayerByPid(iMem)
            if not self:IsOpenGrade(o) then
                table.insert(lMsg, o:GetName())
            end
        end
        if next(lMsg) then
            local sMsg =  table.concat(lMsg)
            oPlayer:SetInfo("trapmine_npc_dialog", sMsg)
            self:DoScript2(iPid, oNpc, "DI300")
            return false
        end
    elseif not self:IsOpenGrade(oPlayer) then
        oPlayer:SetInfo("trapmine_npc_dialog", "你")
        self:DoScript2(iPid, oNpc, "DI300")
        return false
    end
    if oPlayer:IsSingle() or #oPlayer:GetTeamMember() < 2 then
        global.oNotifyMgr:Notify(iPid, "需要2人以上才可挑战噢")
        -- self:DoScript2(iPid, oNpc, "DI305")
        return false
    end

    if iMonsterType == gamedefines.TRAPMINE_MONSTER.RARE then
        return self:ValidFightRareMonster(oPlayer, oNpc)
    elseif iMonsterType == gamedefines.TRAPMINE_MONSTER.BOX then
        return self:ValidFightBoxMonster(oPlayer, oNpc)
    else
        return false
    end
    return true
end

function CTrapMine:FightMonster(iPid,oNpc, mArgs)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    if not oNpc or is_release(oNpc) then
        return
    end
    if not self:ValidFightMonster(oPlayer, oNpc) then
        return
    end
    local iPid = oPlayer:GetPid()
    local iMapId = oNpc:MapId()
    local oMem = self:GetMember(iMapId, iPid)
    if oMem then
        local iFight = oNpc:GetTollgate()
        self:StartWar(iPid, iMapId, iFight, oNpc, {auto_skill=false})
    end
end

function CTrapMine:StartWar(iPid, iMapId, iFight, oNpc, mInfo)
    local oWar = self:CreateWar(iPid, oNpc, iFight, mInfo)
    oWar:SetData("map_id", iMapId)

    if oNpc then
        self:SetNpcInWar(oNpc, oWar:GetWarId())
    else
        self:NotifyTrapminePoint(iPid, iMapId, iFight)
    end
    self:OnStartWar(iPid, iMapId, iFight, oNpc, mInfo)
end

function CTrapMine:NotifyTrapminePoint(iPid, iMapId, iFight)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local lMem = oPlayer:GetTeamMember() or {}
        for _, iMem in ipairs(lMem) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(iMem)
            if not oMem:ValidTrapminePoint(1, {cancel_tip = 1}) then
                local iMaxBuy = tonumber(oWorldMgr:QueryGlobalData("daily_buy_trapmine_point"))
                local iTodayBuy = oMem.m_oToday:Query("trapmine_point_bought", 0)
                local iRemain = math.max(0, iMaxBuy - iTodayBuy)
                local sTips = "您的探索点使用完无法获得奖励，今日还可购买%d探索点。"
                sTips = string.format(sTips, iRemain)
                oNotifyMgr:Notify(iMem, sTips)
            end
        end
    end
end

function CTrapMine:OnStartWar(iPid, iMapId, iFight, oNpc, mInfo)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:SyncSceneInfo({trapmine = 0})
        self:NotifyEnterWar(iPid)
        if iMapId == 206000 then
            oPlayer:PushBookCondition("八门村探索", {value = 1})
        end
    end
end

function CTrapMine:SetNpcInWar(oNpc, iWarId)
    if not is_release(oNpc) then
        local lNpcList = self:GetNpcListByMap(oNpc:MapId())
        for _, obj in ipairs(lNpcList) do
            if not is_release(obj) and obj:Type() == oNpc:Type() then
                obj:SetNowWar(iWarId)
            end
        end
    end
end

function CTrapMine:GetRareMonster(oPlayer, iMapId)
    if self.m_iRareMonster >= self:GetRareMonsterDailyServer() then
        return nil
    end
    local k = oPlayer.m_oToday:Query("trapmine_rare_monster", 0)
    if k >= self:GetRareMonsterDailyPersonal() then
        return nil
    end
    local iType = gamedefines.TRAPMINE_MONSTER.RARE
    if self:HaveSameNPC(oPlayer, iMapId, iType) then
        return nil
    end
    local mArgs = {gm = "gm_trapmine_rare"}
    local iMonster = self:RandMonsterID(oPlayer, iMapId, iType, mArgs)
    return iMonster
end

function CTrapMine:GetBoxMonster(oPlayer, iMapId)
    if self.m_iBoxMonster >= self:GetBoxMonsterDailyServer() then
        return nil
    end
    local k = oPlayer.m_oToday:Query("trapmine_box_monster", 0)
    if k >= self:GetBoxMonsterDailyPersonal() then
        return nil
    end
    local iType = gamedefines.TRAPMINE_MONSTER.BOX
    if self:HaveSameNPC(oPlayer, iMapId, iType) then
        return nil
    end
    local mArgs = {gm = "gm_trapmine_box"}
    local iMonster = self:RandMonsterID(oPlayer, iMapId, iType, mArgs)
    return iMonster
end

function CTrapMine:GetMonsterPoolData(iMapId, iMonsterType)
    local mMonsterPool = res["daobiao"]["huodong"][self:ResName()]["monster_pool"][iMapId][iMonsterType]
    assert(mMonsterPool, string.format("monster_pool config err,mapid:%s, boss:%s", iMapId, iType))
    return mMonsterPool
end

function CTrapMine:HaveSameNPC(oPlayer, iMapId, iType)
    local lNpcList = self.m_mNpcList or {}
    for nid, oNpc in pairs(lNpcList) do
        if oNpc.boss == iType and oNpc:Owner() == oPlayer:GetPid() then
            return true
        end
    end
    return false
end

function CTrapMine:RandMonsterID(oPlayer, iMapId, iType, mArgs)
    mArgs = mArgs or {}
    local mMonsterPool = self:GetMonsterPoolData(iMapId, iType)
    local iCostTrapminePoint =  oPlayer.m_oToday:Query("cost_trapmine_point", 0)
    local sFormula = mMonsterPool.rate_formula
    local mEnv = {
        TRAP_POINT = iCostTrapminePoint
    }
    local iRate = formula_string(sFormula, mEnv)
    if mArgs.gm and oPlayer:GetInfo(mArgs.gm) then
        iRate = 100
    end
    if iRate >= random(1,100) then
        if iType == gamedefines.TRAPMINE_MONSTER.RARE then
            return self:RandRareNPC(oPlayer, iMapId)
        else
            return self:DoRandBoxNPC(oPlayer, iMapId)
        end
    end
end

function CTrapMine:RandRareNPC(oPlayer, iMapId)
    local lPartype = {}
    local mPartype = self:GetTodayRarePartye(iMapId)
    for iPartype, _ in pairs(mPartype) do
        if oPlayer.m_oPartnerCtrl:GetPartnerByType(iPartype) then
            table.insert(lPartype, iPartype)
        end
    end
    local n =  #lPartype
    if n  > 0 then
        return self:DoRandRareNPC(oPlayer, lPartype[random(n)])
    end
end

function CTrapMine:GetNormalFightId(oPlayer, iMapId)
    local mMonsterPool = res["daobiao"]["huodong"][self:ResName()]["common_tollgate"][iMapId]
    assert(mMonsterPool, string.format("huodong:%s common_tollgate config err:%s", self:ResName(), iMapId))
    local iRan = math.random(#mMonsterPool.tollgate_pool)
    return mMonsterPool.tollgate_pool[iRan]
end

function CTrapMine:DoRandRareNPC(oPlayer, iPartype)
    local mMonsterPool = res["daobiao"]["huodong"][self:ResName()]["rare_monster"][iPartype]
    assert(mMonsterPool, string.format("huodong:%s rare_monster config err:%s", self:ResName(), iPartype))
    local iRan = math.random(#mMonsterPool.monsters)
    return mMonsterPool.monsters[iRan]
end

function CTrapMine:DoRandBoxNPC(oPlayer, iMapId)
    local mMonsterPool = res["daobiao"]["huodong"][self:ResName()]["box_monster"][iMapId]
    assert(mMonsterPool, string.format("huodong:%s box_monster config err:%s", self:ResName(), iMapId))
    local iRan = math.random(#mMonsterPool.monsters)
    return mMonsterPool.monsters[iRan]
end

function CTrapMine:GetCreateWarArg(mArgs)
    mArgs = mArgs or {}
    mArgs.war_type = gamedefines.WAR_TYPE.TRAPMINE_TYPE
    return mArgs
end

function CTrapMine:GetWarConfig(sKey, mData, oPlayer)
    local val = mData[sKey]
    if sKey == "war_config" then
        if self:IsClientAutoStart(oPlayer) then
            val = 0
        end
    end
    return val
end

function CTrapMine:GetFightPartner(oPlayer,mArgs)
    return oPlayer.m_oPartnerCtrl:PackFightPartnerInfo()
end

function CTrapMine:OnWarWin(oWar, iPid, oNpc, mArgs)
    mArgs = mArgs or {}
    local iMapId = oWar:GetData("map_id")

    local mFightData = self:GetTollGateData(oWar.m_FightIdx)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oMem = self:GetMember(iMapId, iPid)
    local lPlayer = self:FilterWinner(iPid, oNpc, mArgs.win_list)
    self:AddReward2Winners(lPlayer, mFightData.fallRewardId, iMapId, mArgs)

    local iMonsterType = 0
    if oNpc then
        iMonsterType = oNpc.boss
        self:RemoveNpc(oNpc)
    else
        self:AddOfflineKeep(lPlayer)
        self:AddShowKeep(lPlayer, iMapId)
        self:PushWinnerAchieve(lPlayer)
        local iStatus = self:GetNextTriggerStatus(oWar, iPid,oNpc, mArgs)
        self:SetAllMemberStatus(oPlayer, iMapId, iStatus)
        if iStatus ~= gamedefines.TRAPMINE_STATUS.NORMAL then
            if self:IsClientAutoStart(oPlayer) then
                self:NotifyLeaveWar(iPid)
                self:StartTrapmine(oPlayer,iMapId)
            end
        else
            self:StopTrapmine(oPlayer, iMapId)
        end
    end
    self:LogWinnerAnalyData(oWar, oPlayer, iMonsterType)
end

function CTrapMine:SetAllMemberStatus(oPlayer, iMapId, iStatus)
    local lMem = oPlayer:GetTeamMember() or {oPlayer:GetPid()}
    for _, iPid in ipairs(lMem) do
        local oTrapMem = self:GetMember(iMapId, iPid)
        if oTrapMem then
            oTrapMem:SetStatus(iStatus)
        end
    end
end

function CTrapMine:RemoveNpc(oNpc)
    local iType = oNpc:Type()
    local iOwner = oNpc:Owner()
    local lNpcList = self:GetNpcListByMap(oNpc:MapId())
    for _, obj in ipairs(lNpcList) do
        if obj and not is_release(obj) and obj:Owner() == iOwner and obj:Type() == iType then
            self:RemoveTempNpc(obj)
        end
    end
end

function CTrapMine:AddOfflineKeep(lWinList)
    local oWorldMgr = global.oWorldMgr
    for _, iPid in ipairs(lWinList) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            if oPlayer:GetNetHandle() then
                self:ClearOfflineKeep(oPlayer)
            else
                self:OnAddOfflineReward(oPlayer, self:GetKeep(iPid, "item", {}))
            end
        end
    end
end

function CTrapMine:AddShowKeep(lWinList, iMapId)
    for _, iPid in ipairs(lWinList) do
        local oMem = self:GetMember(iMapId, iPid)
        if oMem then
            oMem:AddRewardInfo(self:GetKeep(iPid, "item", {}))
        end
    end
end

function CTrapMine:PushWinnerAchieve(lWinList)
    local oWorldMgr = global.oWorldMgr
    for _, iPid in ipairs(lWinList) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:AddSchedule("trapmine")
            oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30017,1)
            oPlayer:PushAchieve("探索", {value = 1})
        end
    end
end

function CTrapMine:GetNextTriggerStatus(oWar, pid,oNpc, mAgrs)
    local iMapId = oWar:GetData("map_id")
    local winners = mAgrs.win_list or {}
    local iMem = winners[1]
    local o = global.oWorldMgr:GetOnlinePlayerByPid(iMem)
    if o then
        local oLeader = o:GetTeamLeader() or o
        if self:ValidStart(oLeader, iMapId) then
            return gamedefines.TRAPMINE_STATUS.START
        end
    end
    return gamedefines.TRAPMINE_STATUS.NORMAL
end

function CTrapMine:FilterWinner(iPid, oNpc, winners)
    local lWinner
    if oNpc then
        lWinner = self:WinMonster(iPid, oNpc, winners)
    else
        lWinner = {}
        local oWorldMgr = global.oWorldMgr
        for _, iMem in ipairs(winners) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(iMem)
            if oMem then
                local iCost = 1
                if oMem:ValidTrapminePoint(iCost, {cancel_tip = 1}) then
                    oMem:ResumeTrapminePoint(iCost, "探索消耗", {cancel_tip = 1})
                    table.insert(lWinner, iMem)
                end
            end
        end
    end
    return lWinner
end

function CTrapMine:LogWinnerAnalyData(oWar, oPlayer, iMonsterType)
    local iPoint = 1
    if iMonsterType  == 0 then
        iPoint = 0
    end
    self:LogAnalyData(oWar, oPlayer, iPoint, iMonsterType)
end

function CTrapMine:EscapeCallBack(oWar, pid, npcobj, mArgs)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(mArgs.pid)
    if oPlayer and oPlayer:GetTeamMemberSize() <=1 then
        self:OnWarFail(oWar, pid, npcobj, mArgs)
    end
end

function CTrapMine:OnWarEnd(oWar, iPid, oNpc, bWin)
    super(CTrapMine).OnWarEnd(self, oWar, iPid, oNpc, bWin)
    if oNpc and not is_release(oNpc) then
        local iType = oNpc:Type()
        local iOwner = oNpc:Owner()
        local lNpcList = self:GetNpcListByMap(oNpc:MapId())
        for _, obj in ipairs(lNpcList) do
            if not is_release(obj) and  obj:Type() == oNpc:Type() then
                obj:SetNowWar(nil)
            end
        end
    end
end

function CTrapMine:OnAddOfflineReward(oPlayer, mReward)
    mReward = mReward or {}
    local mOffline = oPlayer.m_oActiveCtrl:GetData("trapmine_offline", {})
    local items = mOffline.item or {}
    for iSid, mInfo in pairs(mReward) do
        for iVirtual, iAmount in pairs(mInfo) do
            table.insert(items, {sid = iSid, virtual = iVirtual, amount = iAmount})
        end
    end

    mOffline.disconnnect = mOffline.disconnnect or get_time()
    mOffline.cost_point = (mOffline.cost_point or 0) + 1
    mOffline.item = items
    oPlayer.m_oActiveCtrl:SetData("trapmine_offline", mOffline)
end

function CTrapMine:ClearOfflineKeep(oPlayer)
    oPlayer.m_oActiveCtrl:SetData("trapmine_offline", {})
end

function CTrapMine:LogAnalyData(oWar,oPlayer,iPoint,iMonsterType)
    local mLog = oPlayer:GetPubAnalyData()
    mLog["team_single"] = (oPlayer:HasTeam() == false)
    mLog["team_leader"] = oPlayer:IsTeamLeader()
    mLog["team_detail"] = self:GetTeamInfoList(oPlayer)
    mLog["npc_id"] = iMonsterType or 0
    mLog["consume_explore"] = iPoint
    mLog["remain_explore"] = oPlayer:TrapminePoint()
    mLog["consume_time"] = oWar:GetWarDuration()
    analy.log_data("exploreBattle",mLog)

    self:LogAnalyGame("trapmine", oPlayer)
end

function CTrapMine:GetTeamInfoList(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local str = ""
    local mMem = oPlayer:GetTeamMember() or {}
    for _,pid in ipairs(mMem) do
        local oMemPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oMemPlayer then
            local sInfo = string.format("%d+%d+%d",pid,oMemPlayer:GetSchool(),oMemPlayer:GetGrade())
            if str ~= "" then
                str = string.format("%s&%s",str,sInfo)
            else
                str = sInfo
            end
        end
    end
    return str
end


function CTrapMine:OnWarFail(oWar, iPid, oNpc, mArgs)
    local oWorldMgr = global.oWorldMgr
    for _, iFail in ipairs(mArgs.fail_list or {}) do
        local o = oWorldMgr:GetOnlinePlayerByPid(iFail)
        if o then
            self:ClearRewardInfo(o)
            self:SetMemberStatus(o, gamedefines.TRAPMINE_STATUS.NORMAL)
            if self:IsOfflineTrapmine(iFail) then
                self:StopOfflineTrapmine(iFail)
            end
            o:SyncSceneInfo({trapmine = 0})
        end
    end
end

function CTrapMine:ClearAllShowReward(oPlayer, iMapId)
    local lMem = oPlayer:GetTeamMember() or {oPlayer:GetPid()}
    for _, iPid in ipairs(lMem) do
        local oTrapMem = self:GetMember(iMapId, iPid)
        if oTrapMem then
            oTrapMem:ClearRewardInfo()
        end
    end
end

function CTrapMine:AddReward2Winners(lWinList, lRewardId, iMapId, mArgs)
    local oWorldMgr = global.oWorldMgr
    lRewardId = lRewardId or {}
    local sRewardId = table.concat(lRewardId, ",")
    for _, iPid in ipairs(lWinList) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            for _, iReward in ipairs(lRewardId) do
                self:Reward(iPid, iReward, mArgs)
            end
            self:LogTrapmine(oPlayer, "warwin", iMapId, {reward = sRewardId})
        end
    end
end

function CTrapMine:GetBoxMonsterCD()
    local mGlobal = res["daobiao"]["global"]["trapmine_box_monster_cd"]
    return tonumber(mGlobal.value)
end

function CTrapMine:GetRareMonsterDailyServer()
    local mGlobal = res["daobiao"]["global"]["trapmine_rare_monster_server"]
    return tonumber(mGlobal.value)
end

function CTrapMine:GetRareMonsterDailyPersonal()
    local mGlobal = res["daobiao"]["global"]["trapmine_rare_monster_personal"]
    return tonumber(mGlobal.value)
end

function CTrapMine:GetBoxMonsterDailyServer()
    local mGlobal = res["daobiao"]["global"]["trapmine_box_monster_server"]
    return tonumber(mGlobal.value)
end

function CTrapMine:GetBoxMonsterDailyPersonal()
    local mGlobal = res["daobiao"]["global"]["trapmine_box_monster_personal"]
    return tonumber(mGlobal.value)
end

function CTrapMine:WinMonster(iPid,oNpc,winners)
    local iMonsterType =  oNpc.boss
    if iMonsterType == gamedefines.TRAPMINE_MONSTER.RARE then
        return self:WinRareMonster(iPid, oNpc, winners)
    elseif iMonsterType == gamedefines.TRAPMINE_MONSTER.BOX then
        return self:WinBoxMonster(iPid, oNpc, winners)
    end
end

function CTrapMine:WinRareMonster(pid,oNpc,winners)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local lRewardPid = {}
    local iNPCType = oNpc and oNpc:Type() or 0
    local iMapId = oNpc:MapId()
    self:SetRareMonsterAmount(self.m_iRareMonster + 1)
    for _, iPid in ipairs(winners) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local k = oPlayer.m_oToday:Query("trapmine_rare_monster", 0)
            local iMax = self:GetRareMonsterDailyPersonal()
            if k < iMax then
                oPlayer.m_oToday:Add("trapmine_rare_monster", 1)
                k = k + 1
                table.insert(lRewardPid, iPid)
            end
            oNotifyMgr:Notify(iPid, string.format("攻击精英怪次数%s/%s，次数使用完无法获得奖励。", k, iMax))
            self:LogTrapmine(oPlayer, "race_monster", iMapId, {
                npcid = iNPCType,
                personal_fight = oPlayer.m_oToday:Query("trapmine_rare_monster", 0),
                daily_fight = self.m_iRareMonster,
                })
        end
        global.oAchieveMgr:PushAchieve(iPid, "击败野外头目次数", {value=1})
    end

    return lRewardPid
end

function CTrapMine:WinBoxMonster(pid, oNpc, winners)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local lRewardPid = {}
    local iNPCType = oNpc and oNpc:Type() or 0
    local iMapId = oNpc:MapId()
    self:SetBoxMonsterAmount(self.m_iBoxMonster + 1)
    for _, iPid in ipairs(winners) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local k = oPlayer.m_oToday:Query("trapmine_box_monster", 0)
            local iMax = self:GetRareMonsterDailyPersonal()
            if k < iMax then
                oPlayer.m_oToday:Add("trapmine_box_monster", 1)
                k = k + 1
                table.insert(lRewardPid, iPid)
            end
            oNotifyMgr:Notify(iPid, string.format("攻击秘宝猎人怪次数%s/%s，次数使用完无法获得奖励。", k, iMax))

            self:LogTrapmine(oPlayer, "box_monster", iMapId, {
                npcid = iNPCType,
                personal_fight = oPlayer.m_oToday:Query("trapmine_box_monster", 0),
                daily_fight = self.m_iBoxMonster,
                })
        end
        global.oAchieveMgr:PushAchieve(iPid, "击败秘宝猎人次数", {value=1})
    end
    return lRewardPid
end

function CTrapMine:SetRareMonsterAmount(iVal)
    self:Dirty()
    self.m_iRareMonster = iVal
end

function CTrapMine:SetBoxMonsterAmount(iVal)
    self:Dirty()
    self.m_iBoxMonster = iVal
end

function CTrapMine:AddReward(iPid, lRewardId, iMapId, mArgs)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        lRewardId = lRewardId or {}
        local sRewardId = table.concat(lRewardId,",")
        for _, iReward in ipairs(lRewardId) do
            self:Reward(iPid, iReward, mArgs)
        end
        self:LogTrapmine(oPlayer, "warwin", iMapId, {reward = sRewardId})
    end
end

function CTrapMine:CreateNpc(oPlayer, iMapId, iNpcSid, iType)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:MapId() == iMapId then
        local oSceneMgr = global.oSceneMgr
        local mScene = oSceneMgr:GetSceneListByMap(iMapId)
        local mPos = self:GetNpcPos(iMapId)
        if not mPos then
            return
        end
        local x, y = table.unpack(mPos)
        local mPosInfo = {x = x, y = y}
        local oNpc
        for _, oScene in ipairs(mScene) do
            local iScene = oScene:GetSceneId()
            local mArgs = {
                ownerid = oPlayer:GetPid(),
                createtime = get_time(),
                endtime = get_time() +  NPC_TIMEOUT,
                owner_sec = NPC_OWNER,
            }
            oNpc = self:CreateTempNpc(iNpcSid)
            oNpc:InitTrapmine(mArgs)
            oNpc.boss = iType
            -- local mPosInfo = oNpc:PosInfo()
            self:Npc_Enter_Scene(oNpc, iScene, mPosInfo)
            oNpc:StartTimer()
            oPlayer:Send("GS2CCreateHuodongNpc", {npcinfo = oNpc:PackNetInfo()})
            self:LogTrapmine(oPlayer, "trigger", iMapId, {npcid=iNpcSid})
        end
        self:DiscoverNpc(oPlayer, oNpc)
    end
end

function CTrapMine:GetNpcPos(iMapId)
    local iMapRes = res["daobiao"]["map"][iMapId]["resource_id"]
    assert(iMapRes, string.format("RandomMonsterPos err %d", iMapId))
    assert(res["map"]["trapmine"][iMapRes],string.format("RandomMonsterPos res_err:%d, %s",iMapId,iMapRes))
    local lPosList = table_deep_copy(res["map"]["trapmine"][iMapRes])
    local mReturn = {}
    local mTemp = {}
    local lNpcList = self:GetNpcListByMap(iMapId)
    local lEmptyPos ={}
    for _, oNpc in ipairs(lNpcList) do
        local m = oNpc:PosInfo()
        mTemp[m.x] = mTemp[m.x] or {}
        mTemp[m.x][m.y] = true
    end
    for _, mPos in ipairs(lPosList) do
        local x, y = table.unpack(mPos)
        if not mTemp[x] or not mTemp[x][y] then
            table.insert(lEmptyPos, mPos)
        end
    end
    if next(lEmptyPos) then
        return lEmptyPos[math.random(#lEmptyPos)]
    end
end

function CTrapMine:DiscoverNpc(oPlayer, oNpc)
    if oNpc and not is_release(oNpc) then
        local oNotifyMgr = global.oNotifyMgr
        local iScene = oNpc:GetScene()
        local oScene = global.oSceneMgr:GetScene(iScene)
        local sScene = oScene:GetName()
        local sName = oPlayer:GetName()
        local sNpc = oNpc:Name()
        if self:GetInfo("broadcast_cd", 0) <= get_time() then
            local sMsg = string.format("#G%s#n在#R%s#n探索时偶然发现了#O%s#n，5分钟后#O%s#n将变为共享状态。", sName,sScene,sNpc,sNpc)
            oNotifyMgr:SendPrioritySysChat("trapmine_char",sMsg, 1, {})
            local iCD = self:GetConfigValue("broadcast_cd") or 600
            self:SetInfo("broadcast_cd", iCD + get_time())
        end
    end
end

function CTrapMine:NewHDNpc(mArgs,iTempNpc)
    return NewHDNpc(mArgs)
end

function CTrapMine:do_look(oPlayer, oNpc)
    if not oNpc or is_release(oNpc) or not oNpc.boss then
        return
    end
    -- if not self:ValidFightMonster(oPlayer, oNpc) then
    --     return
    -- end
    super(CTrapMine).do_look(self, oPlayer, oNpc)
end

function CTrapMine:CheckDull(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    if not oPlayer:GetInfo("offline_trapmine") then
        return
    end
    local iTime = oPlayer:GetInfo("trapmine_dull")
    local iNowTime = get_time()
    if not iTime then
        iTime = iNowTime
        oPlayer:SetInfo("trapmine_dull",get_time())
    end
    if iTime + 10 > get_time() then
        return
    end
    oPlayer:SetInfo("trapmine_dull",get_time())
    local iDullTime = oPlayer:DullTime()
    if iDullTime >= 20 then
        if self:GetMemberStatus(oPlayer) ~= gamedefines.TRAPMINE_STATUS.OFFLINE then
            self:StartOfflineTrapmine(iPid)
        end
    else
        if not oPlayer:GetNetHandle() then
            return
        end
        local mArgs = {
            status = gamedefines.TRAPMINE_STATUS.START
        }
        if self:GetMemberStatus(oPlayer) == gamedefines.TRAPMINE_STATUS.OFFLINE then
            self:StopOfflineTrapmine(iPid,mArgs)
        end
    end
end

function CTrapMine:ClientStartOfflineTrapmine(oPlayer,iMapId)
    local iPid = oPlayer:GetPid()
    oPlayer:SetInfo("offline_trapmine",true)
    local iTimeModel = 5
    oPlayer:SetTestLogoutJudgeTimeMode(iTimeModel)
    self:StartTrapmine(oPlayer,iMapId)
end

function CTrapMine:StartOfflineTrapmine(iPid)
    local oSceneMgr = global.oSceneMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iMapId = oScene:MapId()
    if not oPlayer:GetInfo("offline_trapmine") then
        return
    end
    if not oScene:HasAnLei() then
        --record.info(string.format("trapmine:StartOfflineTrapmine err: %s %s",iPid,iMapId))
        return
    end
    self:SetTrapMinePos(oPlayer,iMapId)
    local fCallback = function ()
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oPlayer then
            return
        end
        self:TrueStartOfflineTrapmine(oPlayer,iMapId)
    end
    oSceneMgr:QueryPos(iPid,fCallback)
end

function CTrapMine:SetTrapMinePos(oPlayer,iMapId)
    local res = require "base.res"
    local lPos = res["daobiao"]["patrol"][iMapId]
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
    local iMinLen = 10000
    local iMinX = 0
    local iMinY = 0
    for _,mData in ipairs(lPos) do
        local iLen = (mNowPos.x - mData.x) ^2 + (mNowPos.y - mData.y) ^2
        if iLen < iMinLen then
            iMinLen = iLen
            iMinX = mData.x
            iMinY = mData.y
        end
    end
    if iMinX == 0 or iMinY == 0 then
        return
    end
    local mData = {
        x = iMinX,
        y = iMinY,
        face_x = mNowPos.face_x,
        face_y = mNowPos.face_y,
    }
    oScene:SetPlayerPos(oPlayer:GetPid(), mData)
end

function CTrapMine:TrueStartOfflineTrapmine(oPlayer,iMapId)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iPid = oPlayer:GetPid()
    local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
    local bWar = false
    if oWar then
        bWar = true
    end
    if not self:IsOfflineTrapmine(iPid) then
        return
    end
    local mData = {
        pid = iPid,
        map_id = iMapId,
        scene_id = oScene:GetSceneId(),
        pos_info = oPlayer.m_oActiveCtrl:GetNowPos(),
        eid = oScene:GetEidByPid(iPid),
        in_war = bWar,
    }
    interactive.Send(".client", "common", "StartOfflineTrapmine",mData)
    self:SetMemberStatus(oPlayer,gamedefines.TRAPMINE_STATUS.OFFLINE)
    local mData = {
        --trapmine = 1,
        offline_trapmine = 1,
    }
    oScene:SyncPlayerInfo(oPlayer,mData)
    oPlayer:SetInfo("auto_trapmine",true)
end

function CTrapMine:IsOfflineTrapmine(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    if not oPlayer:GetInfo("offline_trapmine") then
        return false
    end
    return true
end

function CTrapMine:IsClientAutoStart(oPlayer)
    if oPlayer:GetInfo("auto_trapmine") then
        return true
    end
    return false
end


function CTrapMine:StopOfflineTrapmine(iPid,mArgs)
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local mData = {
        pid = iPid,
        pos_info = oPlayer.m_oActiveCtrl:GetNowPos(),
    }
    interactive.Send(".client", "common", "StopOfflineTrapmine",mData)
    oPlayer:SetInfo("auto_trapmine",nil)
    local iStatus = mArgs.status or gamedefines.TRAPMINE_STATUS.NORMAL
    self:SetMemberStatus(oPlayer,iStatus)
    --切后台不需要处理
    if iStatus == gamedefines.TRAPMINE_STATUS.NORMAL then
        local iTimeModel = 0
        oPlayer:SetTestLogoutJudgeTimeMode(iTimeModel)
        oPlayer:SetInfo("offline_trapmine",nil)
        oPlayer:SyncSceneInfo({trapmine = 0})
        local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
        if oScene and oScene:HasAnLei() then
            oScene.m_oAnLeiCtrl:Stop(iPid)
            oScene:SyncPlayerInfo(oPlayer,{offline_trapmine = 0})
        end
    end
end

function CTrapMine:NpcTimeOut(iNpc)
    local oNpc = self:GetNpcObj(iNpc)
    if oNpc and not is_release(oNpc) then
        self:RemoveNpc(oNpc)
    end
end

function CTrapMine:RemoveTempNpc(oNpc)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(oNpc.m_iOwnerId)
    if oPlayer then
        oPlayer:Send("GS2CRemoveHuodongNpc", {
            npcid = oNpc:ID(),
            flag = 1,
            })
    end
    super(CTrapMine).RemoveTempNpc(self, oNpc)
end

function CTrapMine:GS2CDialog(iPid,oNpc,iDialog)
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

function CTrapMine:TransString(oPlayer,oNpc,s)
    if not s then
        return
    end
    if string.find(s,"{npcname}") then
        s=gsub(s,"{npcname}",oNpc:Name())
    end
    if string.find(s, "{rolename}") then
        s = gsub(s, "{rolename}", oPlayer:GetInfo("trapmine_npc_dialog", "等级不足"))
        oPlayer:SetInfo("trapmine_npc_dialog", nil)
    end
    if string.find(s, "{boxbosscd}") then
        s = gsub(s, "{boxbosscd}",oPlayer:GetInfo("box_monster_dialog", ""))
        oPlayer:SetInfo("box_monster_dialog", nil)
    end
    if string.find(s, "{timeout}") then
        local iSec = oNpc:EndTime() - get_time()
        if iSec > 0 then
            s = gsub(s, "{timeout}", get_second2string(iSec))
        end
    end
    if string.find(s, "{ownercd}") then
        local iSec = oNpc:CreateTime() + oNpc:OwnerSecond() - get_time()
        local ss = ""
        if iSec > 0 then
            ss = string.format("#R%s#n后变成共享状态。", get_second2string(iSec))
        end
        s = gsub(s, "{ownercd}", ss)
    end
    return s
end

function CTrapMine:GetDialogInfo(iDialog)
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["dialog"]
    assert(mData,string.format("Not Dialog Config:%s",self.m_sName))
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CTrapMine:DoScript2(iPid,oNpc,s,mArgs)
    super(CTrapMine).DoScript2(self, iPid, oNpc, s, mArgs)
    local s1to1 = string.sub(s,1,1)
    local s1to2 = string.sub(s,1,2)
    local s1to3 = string.sub(s,1,3)
    if s1to3 == "TPF" then
        self:FightMonster(iPid, oNpc, mArgs)
    elseif s1to2 == "CT" then
        self:CreateTrapTeam(iPid, oNpc, s, mAgrs)
    end
end

function CTrapMine:CreateTrapTeam(iPid, oNpc, s, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    if not self:ValidCreateTeam(oPlayer, oNpc) then
        return
    end

    if oNpc and not is_release(oNpc) then
        local mData = self:GetMonsterPoolData(oNpc:MapId(), oNpc.boss)
        oPlayer:Send("GS2CCreateTeam", {target = mData.team_target})
    end
end

function CTrapMine:ValidCreateTeam(oPlayer, oNpc)
    local iPid = oPlayer:GetPid()
    local iMonsterType = oNpc.boss
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        return false
    end
    if oNpc:IsOwnerProtect(oPlayer) then
        self:DoScript2(iPid, oNpc, "DI304")
        return false
    end
    local lNpcList = self:GetNpcListByMap(oNpc:MapId())
    for _, obj in ipairs(lNpcList) do
        if not is_release(obj) and oNpc:Type() == obj:Type() and obj:InWar() then
            self:DoScript2(iPid, oNpc, "DI200")
            return false
        end
    end
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    if not self:IsOpenGrade(oPlayer) then
        oPlayer:SetInfo("trapmine_npc_dialog", "你")
        self:DoScript2(iPid, oNpc, "DI300")
        return false
    end
    if iMonsterType == gamedefines.TRAPMINE_MONSTER.RARE then
        return self:ValidFightRareMonster(oPlayer, oNpc)
    elseif iMonsterType == gamedefines.TRAPMINE_MONSTER.BOX then
        return self:ValidFightBoxMonster(oPlayer, oNpc)
    else
        return false
    end
    return true
end

function CTrapMine:NotifyEnterWar(iPid)
    if not self:IsOfflineTrapmine(iPid) then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not self:IsClientAutoStart(oPlayer) then
        return
    end
    local mData = {
        pid = iPid,
    }
    interactive.Send(".client", "common", "NotifyEnterWar",mData)
end

function CTrapMine:NotifyLeaveWar(iPid)
    if not self:IsOfflineTrapmine(iPid) then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not self:IsClientAutoStart(oPlayer) then
        return
    end
    local mData = {
        pid = iPid,
    }
    interactive.Send(".client", "common", "NotifyLeaveWar",mData)
end

function CTrapMine:TestOP(oPlayer,iCmd, ...)
    local mArgs = {...}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    if iCmd ==  101 then
        local res = require "base.res"
        local mGlobal = res["daobiao"]["global"]["trapmine_box_monster_cd"]
        local iCDVal =  tonumber(mGlobal.value)
        local iTime = oPlayer.m_oThisTemp:Query("trapmine_box_monster_cd", 0)
        local iCD = math.max(0, iCDVal - (get_time() - iTime))
        local iPersonal = oPlayer.m_oToday:Query("trapmine_rare_monster", 0)
        local sMsg = string.format("宝箱怪冷却时间:%s秒, 个人挑战稀有怪次数:%s, 稀有怪总挑战次数:%s", iCD, iPersonal,self.m_iRareMonster)
        oNotifyMgr:Notify(iPid, sMsg)
    elseif iCmd == 102 then
        oPlayer.m_oThisTemp:Delete("trapmine_box_monster_cd")
        oNotifyMgr:Notify(iPid, "暗雷宝箱怪冷却时间已重置")
    elseif iCmd == 103 then
        oPlayer.m_oToday:Delete("trapmine_rare_monster")
        self:SetRareMonsterAmount(0)
        oNotifyMgr:Notify(iPid, "暗雷稀有怪挑战次数已重置")
    elseif iCmd == 104 then
        local bRare = oPlayer:GetInfo("gm_trapmine_rare", false)
        if not bRare then
            oPlayer:SetInfo("gm_trapmine_rare", true)
            oNotifyMgr:Notify(iPid, "已设置下场必出稀有怪")
        else
            oPlayer:SetInfo("gm_trapmine_rare", false)
            oNotifyMgr:Notify(iPid, "已取消下场必出稀有怪")
        end
    elseif iCmd == 105 then
        local bBox = oPlayer:GetInfo("gm_trapmine_box", false)
        if not bBox then
            oPlayer:SetInfo("gm_trapmine_box", true)
            oNotifyMgr:Notify(iPid, "已设置下场必出宝箱怪")
        else
            oPlayer:SetInfo("gm_trapmine_box", false)
            oNotifyMgr:Notify(iPid, "已取消下场必出宝箱怪")
        end
    elseif iCmd == 106 then
        local sTime = self:FormatTime(21600)
        oNotifyMgr:Notify(iPid, string.format("目前处于宝箱怪诅咒时间%s，诅咒时间结束前无法获得奖励。", sTime))
    elseif iCmd == 107 then
        local iPid = mArgs[1]
        if not iPid then
            return
        end
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oPlayer then
            return
        end
    elseif iCmd == 108 then
        self:InitTodayRarePartner()
        self:SendLoginNpc(oPlayer)
    else
        oNotifyMgr:Notify(iPid, "指令不存在")
    end
end

CMapScene = {}
CMapScene.__index = CMapScene
inherit(CMapScene, datactrl.CDataCtrl)

function CMapScene:New(iMapId)
    local o = super(CMapScene).New(self)
    o.m_iMapId = iMapId
    o.m_mMember = {}
    return o
end

function CMapScene:MapId()
    return self.m_iMapId
end

function CMapScene:GetMember(iPid)
    return self.m_mMember[iPid]
end

function CMapScene:AddMember(o)
    if o then
        local iPid = o:GetPid()
        self.m_mMember[iPid] = o
    end
end

function CMapScene:DelMember(iPid)
    local o = self:GetMember(iPid)
    if o then
        self.m_mMember[iPid] = nil
        o:LeaveScene()
    end
end


CMember = {}
CMember.__index = CMember
inherit(CMember, datactrl.CDataCtrl)

function CMember:New(iMapId, iPid)
    local o = super(CMember).New(self, {pid=iPid})
    self.m_iMapId = iMapId
    o.m_iStatus = 0
    o.m_iStartTime = 0
    o.m_mRewardInfo = {}
    return o
end

function CMember:GetPid()
    return self:GetInfo("pid")
end

function CMember:GetPlayer()
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetPid()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CMember:GetTriggerTime()
    local iNow = get_time()
    local iRemain = 5
    local iTriggerTime = iNow + iRemain + math.random(5,20)
    return iTriggerTime
end

function CMember:GetStatus()
    return self.m_iStatus
end

function CMember:SetStatus(iStatus)
    self.m_iStatus = iStatus
    self:GS2CTrapmineStatus()
end

function CMember:SetTriggerTime(iTime)
    self.m_iStartTime = iTime or get_time()
end

function CMember:AddRewardInfo(mReward)
    mReward = mReward or {}
    for iSid, mInfo in pairs(mReward) do
        local mHave = self.m_mRewardInfo[iSid] or {}
        for iVirtual, iAmount in pairs(mInfo) do
            mHave[iVirtual] = (mHave[iVirtual] or 0) + iAmount
            self.m_mRewardInfo[iSid] = mHave
        end
    end
    self:GS2CTrapmineTotalReward()
end

function CMember:ClearRewardInfo()
    self.m_mRewardInfo = {}
    self:GS2CTrapmineTotalReward()
end

function CMember:EnterScene()
    self.m_iStartTime = 0
    if self:GetStatus() ~= gamedefines.TRAPMINE_STATUS.NORMAL then
        self:SetStatus(gamedefines.TRAPMINE_STATUS.NORMAL)
        self:ClearRewardInfo()
        local oPlayer = self:GetPlayer()
        if oPlayer then
            oPlayer:SyncSceneInfo({trapmine = 0})
        end
    end
end

function CMember:LeaveScene()
    if self:GetStatus() ~= gamedefines.TRAPMINE_STATUS.NORMAL then
        self:SetStatus(gamedefines.TRAPMINE_STATUS.NORMAL)
        self:ClearRewardInfo()
        local oPlayer = self:GetPlayer()
        if oPlayer then
            oPlayer:SyncSceneInfo({trapmine = 0})
        end
    end
    super(CMember).Release(self)
end

function CMember:IsTrapmining()
    return self.m_iStatus ~= gamedefines.TRAPMINE_STATUS.NORMAL
end

function CMember:GS2CTrapmineStatus()
    local oPlayer = self:GetPlayer()
    if oPlayer then
        oPlayer:Send("GS2CTrapmineStatus", {
            status = self.m_iStatus,
        })
    end
end

function CMember:GS2CTrapmineTotalReward()
    local oPlayer = self:GetPlayer()
    if oPlayer then
        local mNet = {}
        for iSid, mInfo in pairs(self.m_mRewardInfo) do
            for iVirtual, iAmount in pairs(mInfo) do
                table.insert(mNet, {
                    sid = iSid,
                    virtual = iVirtual,
                    amount = iAmount,
                    })
            end
        end
        oPlayer:Send("GS2CTrapmineTotalReward", {
            itemlist = mNet,
            })
    end
end

---------------------------------------------------------------
CHDNpc = {}
CHDNpc.__index = CHDNpc
inherit(CHDNpc, huodongbase.CHDNpc)

function NewHDNpc(mArgs)
    local o = CHDNpc:New(mArgs)
    o:Init(mArgs)
    return o
end

function CHDNpc:Init(mArgs)
    super(CHDNpc).Init(self, mArgs)
    self.m_mTrapmine ={}
end

function CHDNpc:InitTrapmine(mArgs)
    mArgs = mArgs or {}
    self.m_iOwnerId = mArgs["ownerid"]
    local m = {}
    m["create_time"] = mArgs["createtime"] or get_time()
    m["end_time"] = mArgs["endtime"] or (get_time() + NPC_TIMEOUT)
    m["owner_sec"] = mArgs["owner_sec"] or NPC_OWNER
    self.m_mTrapmine = m
end

function CHDNpc:PackSceneInfo()
    local mInfo = super(CHDNpc).PackSceneInfo(self)
    mInfo.ownerid = self.m_iOwnerId
    mInfo.trapmine = self:PackTrapmine()
    return mInfo
end

function CHDNpc:StartTimer()
    local iNpc = self:ID()
    local iOwnerSec = self:OwnerSecond()
    local iCreateTime =self:CreateTime()
    local iNow =get_time()
    local  iEndSec = self:EndTime() - iNow
    if iEndSec > 0 then
        self:DelTimeCb("NpcTimeOut")
        self:AddTimeCb("NpcTimeOut", iEndSec * 1000, function()
                local oHuodongMgr = global.oHuodongMgr
                local oHuodong = oHuodongMgr:GetHuodong("trapmine")
                if oHuodong then
                    oHuodong:NpcTimeOut(iNpc)
                end
        end)
    else
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("trapmine")
        if oHuodong then
            oHuodong:NpcTimeOut(iNpc)
        end
    end
end

function CHDNpc:IsOwnerProtect(oPlayer)
    if self.m_iOwnerId == oPlayer:GetPid() then
        return false
    end
    return (self:CreateTime() + self:OwnerSecond() > get_time())
end

function CHDNpc:GetTollgate()
    local mNpcData = self:GetData()
    return mNpcData.tollgateId or 0
end

function CHDNpc:EndTime()
    local mTrap = self.m_mTrapmine or {}
    local iEndTime = mTrap['end_time'] or (get_time() + 30 * 60)
    return iEndTime
end

function CHDNpc:CreateTime()
    local mTrap = self.m_mTrapmine or {}
    local iCreateTime =mTrap["create_time"] or get_time()
    mTrap["create_time"] = iCreateTime
    return iCreateTime
end

function CHDNpc:OwnerSecond()
    local mTrap = self.m_mTrapmine or {}
    local iOwnerSec =mTrap["owner_sec"] or 5 * 60
    mTrap["owner_sec"] = iOwnerSec
    return iOwnerSec
end

function CHDNpc:Owner()
    return self.m_iOwnerId
end

function CHDNpc:PackNetInfo()
    local mData = {
            npctype = self:Type(),
            npcid      = self:ID(),
            name = self:Name(),
            title = self:Title(),
            map_id = self.m_iMapid,
            pos_info = table_deep_copy(self.m_mPosInfo),
            model_info = table_deep_copy(self.m_mModel),
            createtime = self:CreateTime(),
            flag = 1,
    }
    return mData
end

function CHDNpc:PackTrapmine()
    return {
        create_time = self:CreateTime(),
        end_time = self:EndTime(),
        owner_sec = self:OwnerSecond(),
    }
end
--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local playersend = require "base.playersend"
local interactive = require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"

local status = import(lualib_path("base.status"))
local gamedefines = import(lualib_path("public.gamedefines"))
local playerwarrior = import(service_path("playerwarrior"))
local campobj = import(service_path("campobj"))
local npcwarrior = import(service_path("npcwarrior"))
local sumwarrior = import(service_path("sumwarrior"))
local partnerwarrior = import(service_path("partnerwarrior"))
local loadai = import(service_path("ai/loadai"))
local warrecord = import(service_path("warrecord"))
local observer = import(service_path("observer"))

function NewWar(...)
    local o = CWar:New(...)
    return o
end

CWar = {}
CWar.__index = CWar
inherit(CWar, logic_base_cls())

function CWar:New(id,sWarType)
    local o = super(CWar).New(self)
    o.m_iWarId = id
    o.m_sWarType = sWarType or "common"
    o.m_iDispatchId = 0
    o.m_lCamps = {campobj.NewCamp(1,id), campobj.NewCamp(2,id), campobj.NewCamp(3,id)}
    o.m_mWarriors = {}
    o.m_mPlayers = {}
    o.m_mWatcher = {}
    o.m_mObservers = {}
    o.m_mEscapePlayers = {}
    o.m_iWarResult = 0
    o.m_iBout = 0
    o.m_oBoutStatus = status.NewStatus()
    o.m_oBoutStatus:Set(gamedefines.WAR_BOUT_STATUS.NULL)
    o.m_oActionStatus = status.NewStatus()
    o.m_oActionStatus:Set(gamedefines.WAR_ACTION_STATUS.NULL)
    o.m_mBoutCmds = {}
    o.m_mWarConfigCmds = {}
    o.m_mExtData = {}
    o:ResetOperateTime()
    o:ResetAnimationTime()
    o.m_oRecord = warrecord.NewRecord(o.m_iWarId)
    o.m_iWarStatus = gamedefines.WAR_STATUS.NULL

    o.m_mDebugPlayer = {}
    o.m_mDebugMsgQueue = {}
    o.m_mDebugMsg = {}

    o.m_mBoutArgs = {}
    o.m_iStarTime = 0
    o.m_BattleCmd = {{},{}}
    o.m_ActivePlayer = {}
    o.m_ActiveWait = 1
    o.m_BaseClientEnterWarTime = 2000
    o.m_BaseOperateTime = 1000
    o.m_OperateTime = 40000
    o.m_ActionList = {}
    o.m_ActionedList = {}
    o.m_NowAction = 0
    o.m_ActionId = 0
    o.m_ActionStartTime = 0
    o.m_mActionEndList = {}
    return o
end

function CWar:Release()
    for _, v in ipairs(self.m_lCamps) do
        baseobj_safe_release(v)
    end
    self.m_lCamps = {}
    super(CWar).Release(self)
end

function CWar:Init(mInit,mExtra)
    self.m_iWarRecord = mInit.war_record or 0
    self.m_StartSp = mInit.sp_start or 0
    self.m_bPVP = mExtra.pvpflag
end

function CWar:DispatchWarriorId()
    self.m_iDispatchId = self.m_iDispatchId + 1
    return self.m_iDispatchId
end


function CWar:TMaxTime()
    return 5000
end

function CWar:TMinTime()
    if self:QueryBoutArgs("TMinTime") then
        return self:QueryBoutArgs("TMinTime")
    end
    return self:ActionWarrioCount() * 1 + 0.1
end


function CWar:ActionWarrioCount()
    local iCount = 0
    for k,_ in pairs(self.m_mWarriors) do
        local o = self:GetWarrior(k)
        if o and o:ValidAction() then
            iCount = iCount + 1
        end
    end
    return iCount
end

function CWar:NeedWaitBout()
    return self.m_ActiveWait
end

function CWar:AddWait()
    self.m_NextBoutCnt  = self.m_NextBoutCnt + 1
end

function CWar:HeartBeat(wid)
    self.m_ActivePlayer[wid] = 1
end

--是否需要录像
function CWar:IsWarRecord()
    if not self.m_iWarRecord then
        return false
    end
    if self.m_iWarRecord ~= 1 then
        return false
    end
    return true
end

function CWar:GetWarId()
    return self.m_iWarId
end

function CWar:GetWarType()
    return self.m_sWarType
end

function CWar:GetWatcherMap()
    return self.m_mWatcher
end

function CWar:AddWatcher(oWatcher)
    self.m_mWatcher[oWatcher:GetWid()] = true
end

function CWar:DelWatcher(oWatcher)
    self.m_mWatcher[oWatcher:GetWid()] = nil
end

function CWar:WarriorCount()
    return table_count(self.m_mWarriors)
end

function CWar:GetWarriorMap()
    return self.m_mWarriors
end

function CWar:AddBoutCmd(iWid, mCmd)
    local oAction = self:GetWarrior(iWid)
    if oAction and self.m_oActionStatus:Get() == gamedefines.WAR_ACTION_STATUS.OPERATE then
            self:SetBoutCmd(iWid,mCmd)
            oAction:SendAll("GS2CWarCommand",{
                war_id = self.m_iWarId,
                wid = iWid,
            })
    end
end

function CWar:DelBoutCmd(iWid)
    local oAction = self:GetWarrior(iWid)
    if oAction then
        oAction:SetBoutArgs("action_cmd",nil)
    end
end

function CWar:GetBoutCmd(iWid)
    local oAction = self:GetWarrior(iWid)
    if oAction then return oAction:GetActionCmd() end
end

function CWar:SetBoutCmd(iWid,mCmd)
    local oAction = self:GetWarrior(iWid)
    if oAction then
        oAction:SetActionCmd(mCmd)
    end
end

function CWar:AddWarConfigCmd(iWid)
    self.m_mWarConfigCmds[iWid] = 1
    local iCnt = 0
    for k,_ in pairs(self.m_mWarriors) do
        local o = self:GetWarrior(k)
        if o:IsPlayer() then
            iCnt = iCnt + 1
        end
    end

    self:SendAll("GS2CConfigFinish",{war_id = self.m_iWarId,camp = self.m_mWarriors[iWid],wid=iWid})
    if table_count(self.m_mWarConfigCmds) >= iCnt then
        self:DelTimeCb("WarStartConfig")
        self:WarStart()
    end
end

function CWar:GetWarConfigCmd(iWid)
    return self.m_mWarConfigCmds[iWid]
end

function CWar:GetCamp(iCamp)
    return self.m_lCamps[iCamp]
end

function CWar:GetWarrior(id)
    local iCamp = self.m_mWarriors[id]
    if iCamp then
        return self.m_lCamps[iCamp]:GetWarrior(id)
    end
end

function CWar:GetWarriorByPos(iCamp,iPos)
    local oCamp = self.m_lCamps[iCamp]
    if oCamp then
        return oCamp:GetWarriorByPos(iPos)
    end
end

function CWar:GetWarriorList(iCamp)
    local oCamp = self.m_lCamps[iCamp]
    if oCamp then
        return oCamp:GetWarriorList()
    end
end

function CWar:GetPlayerWarrior(iPid)
    local id = self.m_mPlayers[iPid]
    return self:GetWarrior(id)
end


function CWar:Enter(obj, iCamp)
    self.m_lCamps[iCamp]:Enter(obj)
    self.m_mWarriors[obj:GetWid()] = iCamp
    return obj
end

function CWar:EnterNpc(obj,iCamp)
    self.m_lCamps[iCamp]:EnterNpc(obj)
    self.m_mWarriors[obj:GetWid()] = iCamp
end

--进入召唤物
function CWar:EnterCall(obj,iCamp)
    self.m_lCamps[iCamp]:EnterCall(obj)
    self.m_mWarriors[obj:GetWid()] = iCamp
end

function CWar:Leave(obj)
    local iWid = obj:GetWid()
    self:DelBoutCmd(iWid)
    self.m_lCamps[obj:GetCampId()]:Leave(obj)
    self.m_mWarriors[iWid] = nil
    baseobj_delay_release(obj)
end


function CWar:EnterPlayer(iPid, iCamp, mInfo)
    assert(not self.m_mPlayers[iPid], string.format("EnterPlayer error %d", iPid))
    local iWid = self:DispatchWarriorId()
    local obj = self:NewPlayerWarrior(iWid,iPid)
    self.m_mPlayers[iPid] = iWid
    obj:Init({
        camp_id = iCamp,
        war_id = self:GetWarId(),
        data = mInfo,
    })
    self:Enter(obj, iCamp)
    self:AddWatcher(obj)

    local mPartnerData = obj:GetData("partner")
    if mPartnerData then
        local iPos = obj:GetPos() + 4
        self:AddPartner(obj,iPos,mPartnerData)
    end
    obj:SyncFightPartner()
    return obj
end

function CWar:NewPlayerWarrior(iWid,iPid)
    return playerwarrior.NewPlayerWarrior(iWid, iPid)
end


function CWar:AddPartner(oPlayer,iPos,mPartnerData,mArgs)
    mArgs = mArgs or {}
    local iCamp = oPlayer:GetCampId()
    local iWid = oPlayer:GetWid()
    local mData = mPartnerData["partnerdata"]
    local iParId = mData["parid"]
    local mFightPartner = oPlayer:GetTodayFightPartner()
    if mFightPartner[iParId] then
        return
    end
    if mArgs["replace"] and self:IsConfig() then
        mFightPartner[mArgs["replace"]] = nil
    end
    mFightPartner[iParId] = 1
    oPlayer:Set("fight_partner",mFightPartner)
    local iPartnerWid = self:DispatchWarriorId()
    local oPartner = partnerwarrior.NewPartnerWarrior(iPartnerWid)
    if oPartner then
        oPartner:Init({
            camp_id = iCamp,
            war_id = self:GetWarId(),
            data = mData,
        })
        oPartner:SetData("owner",iWid)
        self.m_lCamps[iCamp]:EnterPartner(oPartner,iPos)
        self.m_mWarriors[oPartner:GetWid()] = iCamp

        if oPlayer:IsOpenAutoFight() and oPartner:GetData("auto_skill",0) == 0 then
            local iNormalAttack = oPartner:GetNormalAttackSkillId()
            oPartner:SetAutoSkill(iNormalAttack)
        end
        if mArgs.add_type == 1 then
            self:SendAll("GS2CWarAddWarrior", {
                war_id = self.m_iWarId,
                camp_id = iCamp,
                type = oPartner:Type(),
                partnerwarrior = oPartner:GetSimpleWarriorInfo(),
                add_type = mArgs.add_type,
            })
        end
    end
    return oPartner
end


function CWar:LeavePlayer(iPid,bEscape)
    local obj = self:GetPlayerWarrior(iPid)
    if obj then
        self:OnLeavePlayer(obj,bEscape)
        local iWid = obj:GetWid()
        if not bEscape then
            self:SendAll("GS2CWarDelWarrior", {
                war_id = obj:GetWarId(),
                wid = obj:GetWid(),
            })
        else
            self:LeavePartner(obj)
            self.m_mEscapePlayers[obj:GetCampId()] = self.m_mEscapePlayers[obj:GetCampId()] or {}
            table.insert(self.m_mEscapePlayers[obj:GetCampId()],iPid)
        end
        self.m_mPlayers[iPid] = nil
        self:DelWatcher(obj)
        self:Leave(obj)
    end
end

function CWar:OnLeavePlayer(obj, bEscape)
    local mPartnerInfo = {}
    local mFightPar = {}
    for k,_ in pairs(self.m_mWarriors) do
        local oWarrior = self:GetWarrior(k)
        if oWarrior:IsPartner() and oWarrior:GetData("owner") == obj:GetWid() then
            mPartnerInfo[oWarrior:GetData("parid")] = oWarrior:GetData("auto_skill")
            mFightPar[oWarrior:GetData("parid")] = oWarrior:PackInfo()
        end
    end
    local mFightPartner = obj:GetTodayFightPartner()
    for iParId,_ in pairs(mFightPartner) do
        if not mPartnerInfo[iParId] then
            mPartnerInfo[iParId] = 0
        end
    end
    local iPid = obj:GetPid()

    self:RemoteWorldEvent("remote_leave_player",{
        war_id = self:GetWarId(),
        pid = iPid,
        escape = bEscape,
        is_dead = obj:IsDead(),
        auto_skill = obj:GetData("auto_skill",0),
        auto_skill_switch = obj:GetData("auto_skill_switch",0),
        partner_info = mPartnerInfo,
        fight_partner = {[iPid] = mFightPar},
    })
end

function CWar:LeaveRomPlayer(oAction,bWin)
end

function CWar:LeaveRomPartner(oAction,bWin,iPid)
    -- body
end

function CWar:GetEscapeList()
    return self.m_mEscapePlayers or {}
end

function CWar:KickOutWarrior(oAction,mArgs)
    mArgs = mArgs or {}
    if oAction:IsPlayer() then
        self:LeavePlayer(oAction:GetPid())
        return
    end
    local iDelType = mArgs.del_type or 1
    local iWid = oAction:GetWid()
    self:SendAll("GS2CWarDelWarrior", {
        war_id = oAction:GetWarId(),
        wid = oAction:GetWid(),
        del_type = iDelType,
    })
    self:Leave(oAction)
    if mArgs["speed"] then
        self:DeleteSpeedMQ(oAction:GetWid())
    end
end

function CWar:LeavePartner(oPlayer)
    local iWid = oPlayer:GetWid()
    local lFriend = oPlayer:GetFriendList(true)
    for _,oFriend in pairs(lFriend) do
        if oFriend:GetData("owner") == iWid or  oFriend:GetData("call_player",0) == iWid then
            self:SendAll("GS2CWarDelWarrior", {
                war_id = self:GetWarId(),
                wid = oFriend:GetWid(),
            })
            self:Leave(oFriend)
        end
    end
end

function CWar:ReEnterPlayer(iPid)
    local oWarrior = self:GetPlayerWarrior(iPid)
    assert(oWarrior, string.format("ReEnterPlayer error %d", iPid))
    oWarrior:ReEnter()
end

function CWar:EnterObserver(iPid)
    local oObserver = observer.NewObserver(iPid)
    oObserver:Init({war_id = self:GetWarId(),wid=self:DispatchWarriorId()})

    self.m_mObservers[iPid] = oObserver
    oObserver:Enter()
end

function CWar:GetObserver(iPid)
    return self.m_mObservers[iPid]
end

function CWar:LeaveObserver(iPid)
    if self.m_mObservers[iPid] then
        self.m_mObservers[iPid] = nil
        self:RemoteWorldEvent("remote_leave_observer",{
            war_id = self:GetWarId(),
            pid = iPid,
        })
    end
end

function CWar:GS2CAddAllWarriors(obj)
    local mWarriorMap = self:GetWarriorMap()
    for k, _ in pairs(mWarriorMap) do
        if obj:IsObserver() or k ~= obj:GetWid() then
            local o = self:GetWarrior(k)
            if o then
                local mNet = {}
                mNet.war_id = o:GetWarId()
                mNet.camp_id = o:GetCampId()
                mNet.type = o:Type()
                if o:IsPlayer() or o:IsRomPlayer() then
                    mNet.warrior = o:GetSimpleWarriorInfo()
                elseif o:IsNpc() then
                    mNet.npcwarrior = o:GetSimpleWarriorInfo()
                elseif o:IsPartner() or o:IsRomPartner() then
                    mNet.partnerwarrior = o:GetSimpleWarriorInfo()
                end
                obj:Send("GS2CWarAddWarrior", mNet)
            end
        end
    end
end

function CWar:AddOperateTime(iTime)
    self.m_iOperateWaitTime = self.m_iOperateWaitTime + iTime
end

function CWar:GetOperateTime()
    return self.m_iOperateWaitTime
end

function CWar:BaseClientEnterWarTime()
    return self.m_BaseClientEnterWarTime
end

function CWar:BaseOperateTime()
    return self.m_BaseOperateTime
end

function CWar:OperateTime()
    return self.m_OperateTime
end



function CWar:ResetOperateTime()
    self.m_iOperateWaitTime = 0
end

function CWar:GetAnimationTime()
    return self.m_iAnimationWaitTime
end

function CWar:BaseAnimationTime()
    return 2000
end

function CWar:AddAnimationTime(iTime,mdebug)
    mdebug = mdebug or {}
    mdebug["time"] = iTime
    table.insert(self.m_DebugAnimation,mdebug)
    self.m_iAnimationWaitTime = self.m_iAnimationWaitTime + iTime
end

function CWar:ResetAnimationTime()
    self.m_iAnimationWaitTime = 0
    self.m_DebugAnimation = {}
    self.m_DebugClientTime = {}
end

function CWar:PrepareMonster(mMonsterData)
    for iCamp,mSideData in pairs(mMonsterData) do
        for _, mInfo in ipairs(mSideData) do
            local iWid = self:DispatchWarriorId()
            local obj = self:NewNpcWarrior(iWid)
            obj:Init({
                camp_id = iCamp,
                war_id = self:GetWarId(),
                data = mInfo,
            })
            if iCamp == 1 then
                self:EnterNpc(obj,iCamp)
            else
                self:Enter(obj, iCamp)
            end
        end
    end
end

function CWar:PrepareNextWaveMonster(mMonsterData)
    for iCamp,mSideData in pairs(mMonsterData) do
        for _, mInfo in ipairs(mSideData) do
            local iWid = self:DispatchWarriorId()
            local obj = self:NewNpcWarrior(iWid)
            obj:Init({
                camp_id = iCamp,
                war_id = self:GetWarId(),
                data = mInfo,
            })
            if iCamp == 1 then
                self:EnterNpc(obj,iCamp)
            else
                self:Enter(obj, iCamp)
            end

            self:SendAll("GS2CWarAddWarrior", {
                war_id = obj:GetWarId(),
                camp_id = obj:GetCampId(),
                type = obj:Type(),
                npcwarrior = obj:GetSimpleWarriorInfo(),
            })
        end
    end
end

function CWar:WarPrepare(mInfo)
    local mMonsterData = mInfo.monster_data or {}
    self:PrepareMonster(mMonsterData)

    --怪物波数数据
    local mWaveData = mInfo.wave_enemy or {}
    self:SetExtData("wave_enemy_monster",mWaveData)
    --自定义召唤
    local mServant = mInfo.monster_servant
    self:SetExtData("servant_data",mServant)
end

function CWar:PrepareRomWar(mInfo)
    local mMonsterData = mInfo.monster_data or {}
    local mRomPlayer = mMonsterData.rom_player
    local mRomPartner = mMonsterData.rom_partner
    local iCamp = mInfo.camp_id or 2
    local iRomWid = self:EnterRomPlayer(iCamp,mRomPlayer)
    for idx, mData in pairs(mRomPartner) do
        local iWid = self:DispatchWarriorId()
        local oRomPartner = self:NewRomPartnerWarrior(iWid)
        oRomPartner:Init({
            camp_id = iCamp,
            war_id = self:GetWarId(),
            data = mData,
        })
        oRomPartner:SetData("owner",iRomWid)
        self:Enter(oRomPartner, iCamp)
    end
end

function CWar:EnterRomPlayer(iCamp,mData)
    local iWid = self:DispatchWarriorId()
    local iPid = mData["pid"]
    local oRom = self:NewRomPlayerWarrior(iWid,iPid)
    oRom:Init({
        camp_id = iCamp,
        war_id = self:GetWarId(),
        data = mData,
    })
    self:Enter(oRom, iCamp)
    local mPartnerData = oRom:GetData("partner")
    if mPartnerData then
        local iPos = oRom:GetPos() + 4
        local iPartnerWid = self:DispatchWarriorId()
        local oRomPartner = self:NewRomPartnerWarrior(iPartnerWid)
        if oRomPartner then
            oRomPartner:Init({
                camp_id = iCamp,
                war_id = self:GetWarId(),
                data = mPartnerData,
            })
            oRomPartner:SetData("owner",oRom:GetWid())
            self.m_lCamps[iCamp]:EnterPartner(oRomPartner,iPos)
            self.m_mWarriors[oRomPartner:GetWid()] = iCamp
        end
    end
    return iWid
end

function CWar:NewNpcWarrior(iWid)
    return npcwarrior.NewNpcWarrior(iWid)
end

function CWar:NewRomPlayerWarrior(iWid,iPid)
    return playerwarrior.NewRomPlayerWarrior(iWid,iPid)
end

function CWar:NewRomPartnerWarrior(iWid)
    return partnerwarrior.NewRomPartnerWarrior(iWid)
end


function CWar:PreparePartner(mInfo)
    local iCamp = mInfo.camp_id
    local iPid = mInfo.owner_id
    local oPlayer = self:GetPlayerWarrior(iPid)
    if not oPlayer then
        return
    end
    local mData = mInfo.data or {}
    for _,mInfo in pairs(mData) do
        local iWid = self:DispatchWarriorId()
        local mPartnerData = mInfo.partnerdata
        local oPartner = partnerwarrior.NewPartnerWarrior(iWid)
        oPartner:Init({
            camp_id = iCamp,
            war_id = self:GetWarId(),
            data = mPartnerData,
        })
        oPartner:SetData("owner",oPlayer:GetWid())
        self:Enter(oPartner,iCamp)

        if oPlayer:IsOpenAutoFight() and oPartner:GetData("auto_skill",0) == 0 then
            local iNormalAttack = oPartner:GetNormalAttackSkillId()
            oPartner:SetAutoSkill(iNormalAttack)
        end

        local mFightPartner = oPlayer:GetTodayFightPartner()
        mFightPartner[oPartner:GetData("parid")] = 1
        oPlayer:Set("fight_partner",mFightPartner)
    end
    oPlayer:SyncFightPartner()
end


function CWar:PreparePartnerCommand(oPlayer,mPartner)
    local iCamp = oPlayer:GetCampId()
    local oCamp = self:GetCamp(iCamp)
    local iWid = oPlayer:GetWid()
    local mNewPos = {}
    local mNet = {}
    for _,mInfo in ipairs(mPartner) do
        local iPartnerId = mInfo["parid"] or 0
        local iDestPos = mInfo["pos"] or 0
        local oSrcPartner = oCamp:GetPartnerByID(iWid,iPartnerId)
        oCamp:ResetPos(oSrcPartner,iDestPos)
        local iWid = oSrcPartner:GetWid()
        table.insert(mNet,{wid = iWid, pos = iDestPos})

        local mFightPartner = oPlayer:GetTodayFightPartner()
        mFightPartner[iPartnerId] = 1
        oPlayer:Set("fight_partner",mFightPartner)
    end

    self:SendAll("GS2CSwitchPos",{
        war_id = self:GetWarId(),
        pos_list = mNet,
    })
    oPlayer:SyncFightPartner()
end

function CWar:IsConfig()
    return self.m_iWarStatus == gamedefines.WAR_STATUS.CONFIG
end

function CWar:IsStop()
    return self.m_iWarStatus == gamedefines.WAR_STATUS.STOP
end

function CWar:WarStartConfig(mInfo)
    self:SendWarStartWarrior()
    local iSecs = 20
    self.m_iWarStatus = gamedefines.WAR_STATUS.CONFIG
    self.m_iWarConfigTime = get_time() + 20
    self:SendAll("GS2CWarConfig",{
        war_id = self.m_iWarId,
        secs = iSecs,
    })
    self:DelTimeCb("WarStartConfig")
    local iWarId = self:GetWarId()
    local oWarMgr = global.oWarMgr
    self:AddTimeCb("WarStartConfig",iSecs*1000 + self:BaseOperateTime(),function ()
        local oWar = oWarMgr:GetWar(iWarId)
        oWar:DelTimeCb("WarStartConfig")
        oWar:WarStart(mInfo)
    end)
    self:CleanFightPartner()
end

function CWar:CleanFightPartner()
    for iPid,iWid in pairs(self.m_mPlayers) do
        local oPlayer = self:GetWarrior(iWid)
        if oPlayer then
            oPlayer:Set("fight_partner",nil)
        end
    end
end

function CWar:SendWarStartWarrior()
    if self.m_bSendWarStartWarrior then
        return
    end
    self.m_bSendWarStartWarrior = true

    if self:IsWarRecord() then
        self.m_oRecord:AddClientPacket("GS2CEnterWar",{})
        local mWarriorMap = self:GetWarriorMap()
        for k, _ in pairs(mWarriorMap) do
            local o = self:GetWarrior(k)
            if o then
                local mNet = {}
                mNet.war_id = o:GetWarId()
                mNet.camp_id = o:GetCampId()
                mNet.type = o:Type()
                if o:IsPlayer() or o:IsRomPlayer() then
                    mNet.warrior = o:GetSimpleWarriorInfo()
                elseif o:IsNpc() then
                    mNet.npcwarrior = o:GetSimpleWarriorInfo()
                elseif o:IsPartner() or o:IsRomPartner() then
                    mNet.partnerwarrior = o:GetSimpleWarriorInfo()
                end
                self.m_oRecord:AddClientPacket("GS2CWarAddWarrior", mNet)
            end
        end
    end

    for iPid,iWid in pairs(self.m_mPlayers) do
        local oPlayer = self:GetWarrior(iWid)
        if oPlayer then
            oPlayer:Send("GS2CEnterWar", {})
            self:GS2CWarWave(oPlayer)
            oPlayer:Send("GS2CWarAddWarrior", {
                war_id = oPlayer:GetWarId(),
                camp_id = oPlayer:GetCampId(),
                type = oPlayer:Type(),
                warrior = oPlayer:GetSimpleWarriorInfo(),
            })
            self:GS2CAddAllWarriors(oPlayer)
        end
    end
end


function CWar:WarStart(mInfo)
    self:BeforeWarStar(mInfo)
    self:SendWarStartWarrior()
    self.m_iWarStatus = gamedefines.WAR_STATUS.START
    self:SendWarSpeed()
    if self.m_StartSp > 0 then
        self:AddSP(1,self.m_StartSp)
    end
    for k,_ in pairs(self.m_mWarriors) do
        local o = self:GetWarrior(k)
        if o then
            local iSpeed = o:QueryAttr("speed")
        end
    end
    safe_call(self.OnWarStart,self)
    self:BoutStart()
end

function CWar:BeforeWarStar(mInfo)
    -- 13级单人战斗不需要操作时间
    if self:IsSinglePlayer()  and not self.m_FirstWar then
        for pid,wid in pairs(self.m_mPlayers)  do
            local oPlayer  = self:GetPlayerWarrior(pid)
            if oPlayer:GetData("grade",0) < 13 then
                self.m_BaseClientEnterWarTime = 100
                self.m_BaseOperateTime = 100
                self.m_OperateTime = 0
            end
        end
    end

    if self:IsPVPWar() then
        for pid,wid in pairs(self.m_mPlayers)  do
            local oPlayer  = self:GetPlayerWarrior(pid)
            oPlayer:SetPlaySpeed(2)
        end
    end
end


function CWar:WarEndEffect()
    self:DelTimeCb("WarEndEffect")
    self:DelTimeCb("WarEnd")
    self:DelTimeCb("WarStartConfig")
    self:DelTimeCb("BoutEndTimeOut")
    self:DelTimeCb("AutoActionStart")
    self:DelTimeCb("AutoNextAction")
    self:DelTimeCb("AutoStart")


    self.m_bEndEffect = true

    self:SendAll("GS2CWarResult",{
        war_id = self:GetWarId(),
        win_side = self.m_iWarResult
    })
    local iWarId = self:GetWarId()
    local oWarMgr = global.oWarMgr
    if self:IsSinglePlayer() then
        if self.m_iWarResult and self.m_iWarResult == 1 then
            self:AddTimeCb("WarEnd",2000,function ()
                local oWar = oWarMgr:GetWar(iWarId)
                oWar:WarEnd()
            end)
        else
            self:WarEnd()
        end
    else
        self:AddTimeCb("WarEnd",2000,function ()
            local oWar = oWarMgr:GetWar(iWarId)
            oWar:WarEnd()
        end)
    end
end

function CWar:WarEnd()
    self:DelTimeCb("WarEndEffect")
    self:DelTimeCb("WarEnd")
    self:DelTimeCb("BoutEndTimeOut")
    self:DelTimeCb("WarStartConfig")

    local mWinWarrior
    if self.m_iWarResult ~= 0 then
        mWinWarrior = self:GetWarriorList(self.m_iWarResult) or {}
    else
        mWinWarrior = self:GetWarriorList(2) or {}
    end
    local iFailPos = 1
    if self.m_iWarResult == 1 then
        iFailPos = 2
    end
    local mFailWarrior = self:GetWarriorList(iFailPos) or {}
    local mWinList = {}
    local mFailList = {}
    local mEscapeList = self:GetEscapeList()
    local mPlayerPartner = {}
    local f =function (mWarrior,bWin)
        for _,oAction in pairs(mWarrior) do
            if oAction:IsPlayer() then
                if bWin then
                    table.insert(mWinList,oAction:GetPid())
                else
                    table.insert(mFailList,oAction:GetPid())
                end
            elseif oAction:IsPartner() then
                local iWid = oAction:GetData("owner")
                local oWarrior = self:GetWarrior(iWid)
                if oWarrior and oWarrior:IsPlayer() then
                    local iPid = oWarrior:GetPid()
                    local mPartner = mPlayerPartner[iPid] or {}
                    mPartner[oAction:GetData("parid")] = oAction:PackInfo()
                    mPlayerPartner[iPid] = mPartner
                end
            elseif oAction:IsRomPlayer() then
                self:LeaveRomPlayer(oAction,bWin)
            elseif oAction:IsRomPartner() then
                local iWid = oAction:GetData("owner")
                local oWarrior = self:GetWarrior(iWid)
                if oWarrior and (oWarrior:IsPlayer() or oWarrior:IsRomPlayer())then
                    local iPid = oWarrior:GetPid()
                    local mPartner = mPlayerPartner[iPid] or {}
                    mPartner[oAction:GetData("parid")] = oAction:PackInfo()
                    mPlayerPartner[iPid] = mPartner
                    self:LeaveRomPartner(oAction,bWin,iPid)
                end
            end
        end
    end
    f(mWinWarrior,true)
    f(mFailWarrior,false)

    local mArgs = self:ExtendWarEndArg({
        win_side = self.m_iWarResult,
        win_list = mWinList,
        fail_list = mFailList,
        escape_list = mEscapeList,
        fight_partner = mPlayerPartner,
        current_wave = self:CurrentEnemyWave(),
        bout = self.m_iBout,
        star_time = self.m_iStarTime,
    })

    local l = table_key_list(self.m_mPlayers)
    for _, iPid in ipairs(l) do
        self:LeavePlayer(iPid)
    end
    local l = table_key_list(self.m_mObservers)
    for _, iPid in ipairs(l) do
        self:LeaveObserver(iPid)
    end
    mArgs.war_film_data = self.m_oRecord:PackFilmData()
    self:RemoteWorldEvent("remote_war_end",{
        war_id = self:GetWarId(),
        war_info = mArgs,
    })
end

function CWar:RemoteWorldEvent(sEvent,mData)
    interactive.Send(".world", "war", "RemoteEvent", {event = sEvent, data = mData})
end

function CWar:ExtendWarEndArg(mArgs)
    return mArgs
end

function CWar:BoutStart()
    self.m_iBout = self.m_iBout + 1
    self.m_ActionList = {}
    self.m_ActionedList = {}
    self:SendAll("GS2CWarBoutStart", {
        war_id = self:GetWarId(),
        bout_id = self.m_iBout,
        left_time = 0,
    })

    local iWarId = self:GetWarId()
    local iBoutTime = 400 * 1000
    self:DelTimeCb("BoutEndTimeOut")
    self:AddTimeCb("BoutEndTimeOut",iBoutTime,function ()
        local oWar = global.oWarMgr:GetWar(iWarId)
        if oWar then
            oWar:BoutEndTimeOut()
        end
    end)
    safe_call(self.NewBout,self)
    safe_call(self.OnBoutStart, self)
    self:SyncBoutStart()
    self:ResetActionList()
    self:CheckActionStart()
end


function CWar:BoutEnd()
    self:SendAll("GS2CWarBoutEnd", {
        war_id = self:GetWarId(),
        bout_id = self.m_iBout,
    })
    self:OnBoutEnd()
end

function CWar:BoutEndTimeOut()
    self:DelTimeCb("BoutEndTimeOut")
    record.warning(string.format("boutendtimeout %d %s ",self:GetWarId(),self:GetWarType()))
    local iWarWin  = self:IsCanWarEnd()
    if iWarWin then
        if iWarWin == 1 and self:IsPVEWar() and self:CanStartNextWave() then
            self:StartNextWave()
            self:BoutStart()
            return true
        end
        self:DrawWarEnd(iWarWin)
    else
        self:BoutEnd()
        self:BoutStart()
    end
end

function CWar:ResetActionList()
    self:BuildSpeedMQ()
    self:SendAll("GS2CWarSpeed",{war_id = self:GetWarId(),speed_list =self.m_TmpActionList})
end


function CWar:BuildSpeedMQ()
    local mSpeed = {}
    self.m_TmpActionList = {}
    self.m_ActionList = {}
    for k,_ in pairs(self.m_mWarriors) do
        local o = self:GetWarrior(k)
        if o and not o:IsAction() then
            local iSpeed = o:QueryAttr("speed",0)
            local iDeadAction = o:QueryBoutArgs("dead_action",0)
            table.insert(mSpeed,{wid=k,speed=iSpeed,dead=iDeadAction})
        end
    end

    local fSort = function (mData1,mData2)
        if mData1["dead"] == mData2["dead"] then
            if mData1["speed"] ~= mData2["speed"] then
                return mData1["speed"] > mData2["speed"]
            else
                return mData1["wid"] < mData2["wid"]
            end
        else
            return mData1["dead"] < mData2["dead"]
        end
    end
    table.sort(mSpeed,fSort)
    for _,m in ipairs(mSpeed) do
        local o = self:GetWarrior(m["wid"])
        table.insert(self.m_TmpActionList,{wid=m["wid"],speed=m["speed"],action=0,camp=o:GetCampId()})
        table.insert(self.m_ActionList,m["wid"])
    end

    for _,m in ipairs(self.m_ActionedList) do
        table.insert(self.m_TmpActionList,m)
    end
end

function CWar:DeleteSpeedMQ(iActon)
    for _,m in ipairs(self.m_ActionedList) do
        if m["wid"] == iActon then
            extend.Array.remove(self.m_ActionedList,m)
        end
    end
    self:BuildSpeedMQ()
end

function CWar:GetNowAction()
    return self.m_NowAction
end

function CWar:CheckActionStart()
    self:ActionStart()
end

function CWar:ActionStart()
    self:DelTimeCb("AutoFightTimeOut")
    self:DelTimeCb("AutoActionStart")
    self:DelTimeCb("AutoNextAction")
    local iAction = assert(table.remove(self.m_ActionList,1))
    local iWarId = self:GetWarId()
    self.m_NowAction = iAction
    self.m_mActionEndList = {}
    local oAction = self:GetWarrior(self.m_NowAction)
    self.m_ActionId = self.m_ActionId + 1
    self.m_ActionStartTime = get_time()
    self.m_oActionStatus:Set(gamedefines.WAR_ACTION_STATUS.OPERATE)
    local iTimeOut = 0
    if oAction and oAction:ValidAction() then
        iTimeOut = oAction:GetAutoFightTime()
    end
    if oAction then
        local iCamp = oAction:GetCampId()
        if not oAction:IsDead() then
            self:AddSP(iCamp,10)
        end
        oAction.m_oBuffMgr:CheckActionStartBuff(oAction)
        oAction:OnActionBeforeStart()
        table.insert(self.m_ActionedList,{wid=iAction,speed=oAction:QueryAttr("speed"),camp=oAction:GetCampId(),action=1})
    end


    self:SetExtData("action_start",get_time())
    self:SendAll("GS2CActionStart",{ war_id=self:GetWarId(),
        wid=iAction,
        action_id = self.m_ActionId,
        left_time = iTimeOut,
        })
    self:DelTimeCb("AutoFightTimeOut")
    self:DelTimeCb("AutoActionStart")
    if iTimeOut > 0 and self.m_ActionId == 1 and ( oAction:IsPlayer() or oAction:IsPartner() ) then
        local iAutoFigtTimeOut = oAction:GetBoutAutoFightTime()
        if iAutoFigtTimeOut > 0 then
            local iWid = oAction:GetWid()
            if oAction:IsPartner() then
                iWid = oAction:GetMaster():GetWid()
            end
            self:SetBoutArgs("WaitWautoFightTimeOut",iWid)
            self:AddTimeCb("AutoFightTimeOut",iAutoFigtTimeOut,function()
                   local oWar = global.oWarMgr:GetWar(iWarId)
                   if oWar then
                        oWar:AutoFightTimeOut()
                    end
                end)
        end
    end

    if oAction and iTimeOut > 0 then
        iTimeOut =  iTimeOut * 1000 + 300
        self:AddTimeCb("AutoActionStart",iTimeOut,function ()
               local oWar = global.oWarMgr:GetWar(iWarId)
               if oWar then
                    oWar:ActionAutoStart()
                end
        end)
    else
        self:ActionAutoStart()
    end
end

function CWar:AutoFightTimeOut()
    self:DelTimeCb("AutoFightTimeOut")
    self:ActionAutoStart()
end

function CWar:CancleAutoFight(oPlayer)
    if self:QueryBoutArgs("WaitWautoFightTimeOut") == oPlayer:GetWid() then
        self:DelTimeCb("AutoFightTimeOut")
    end
    oPlayer:CancleAutoFight()
end

function CWar:ActionAutoStart()
    self:DelTimeCb("AutoActionStart")
    self:DelTimeCb("AutoFightTimeOut")
    local oAction = self:GetWarrior(self:GetNowAction())
    if oAction and oAction:ValidAction() then
        oAction:AutoCommand()
    end

    safe_call(self.ActionProcess,self)

    local iWarId = self:GetWarId()
    self:AddTimeCb("AutoNextAction",self:TMaxTime(),function ()
            local oWar = global.oWarMgr:GetWar(iWarId)
            if oWar then
                oWar:ActionAutoNextStart()
            end
    end)
end

function CWar:ActionProcess()
    self:DelTimeCb("AutoActionStart")
    self:DelTimeCb("Wait")
    self:DelTimeCb("AutoNextAction")
    self.m_oActionStatus:Set(gamedefines.WAR_ACTION_STATUS.ANIMATION)
    -- init pack
    self.m_LockCachePacket = {}
    self.m_bCacheCmd = true
    local iAction = self:GetNowAction()
    local oAction = self:GetWarrior(iAction)
    if oAction then
        safe_call(self.ActionExecute,self,oAction)
    end
    safe_call(self.CheckAlive,self)
    safe_call(self.ActionEnd,self)
    self:SendAll("GS2CActionEnd",{
        war_id = self:GetWarId(),
        wid = iAction,
        action_id = self.m_ActionId,
        })

    self.m_bCacheCmd = nil
    self:SendActionCache()
    self.m_LockCachePacket = {}
end

function CWar:ActionAutoNextStart()
    self:NextActionStart()
end

function CWar:ActionExecute(oAction)
    local oActionMgr = global.oActionMgr
    oAction.m_bAction = true
    local wid = oAction:GetWid()
    oAction:OnActionStart()

    if oAction:ValidAction() then
        local v = oAction:GetActionCmd()
        if not v then
            --record.error(string.format("excute err %s %s %s",self.m_sWarType,oAction:GetWid(),oAction:GetName()))
            return
        end
        local sCmd = v.cmd
        local mData = v.data

        self:DispatchActionSort(oAction)
        oAction:BeforeCommand()

        if sCmd == "warpartner" then
            oAction:SendAll("GS2CWarAction",{
                war_id = oAction:GetWarId(),
                wid = oAction:GetWid()
                })
        end

        local mFunction = oAction:GetFunction("OnCommand")
        for ky,fCallback in pairs(mFunction) do
            local nv = fCallback(oAction)
            if nv then
                v= nv
            else
                local record = require "public.record"
                record.error(string.format("warerr oncommand %s %s",oAction:GetName(),ky))
            end
        end

        if not v or not v.cmd then
            local record = require "public.record"
            record.error(string.format("warerr oncommand %s %s %s %s",oAction:GetName(),iNextAction,self.m_sWarType,v))
        end

        local sCmd = v.cmd
        local mData = v.data
        if sCmd == "skill" then
            local lSelect = mData.select_wlist
            local iSkill = mData.skill_id
            local l = {}
            for _, i in ipairs(lSelect) do
                local o = self:GetWarrior(i)
                if o then
                    table.insert(l, o)
                end
            end
            oActionMgr:WarSkill(oAction, l, iSkill)
        elseif sCmd == "escape" then
            oActionMgr:WarEscape(oAction)
        elseif sCmd == "warpartner" then
            --
        end

    else
        oAction:SendAll("GS2CWarAction",{
            war_id = oAction:GetWarId(),
            wid = oAction:GetWid()
                 })
    end

    --可能死亡
    local oCurrentAction = self:GetWarrior(wid)
    if oCurrentAction and not oCurrentAction:QueryBoutArgs("perform_success") then
        oCurrentAction.m_oBuffMgr:CheckAttackBuff(oCurrentAction)
    end
end

function CWar:ActionEnd()
    local iAction = self:GetNowAction()
    local oAction = self:GetWarrior(iAction)
    if oAction then
        oAction:OnActionEnd()
        oAction.m_oBuffMgr:CheckActionEndBuff(oAction)
        oAction.m_oPerformMgr:ActionEnd()
    end
    self:BuildSpeedMQ()
    self:SendAll("GS2CWarSpeed",{war_id = self:GetWarId(),speed_list =self.m_TmpActionList})
end

function CWar:FinishOperate(oAction,mData,mCmd)
    if oAction:GetWid() ~= self:GetNowAction() then
        return
    end
    self:ActionAutoStart()
end

function CWar:NextActionStart()
    self:DelTimeCb("AutoActionStart")

    safe_call(self.CheckDeadAction,self)
    local bOk,iNextBout = safe_call(self.CheckNextBoutStart,self)
    if not bOk or iNextBout then
        return
    end
    self:CheckActionStart()
end

function CWar:CheckDeadAction()
    for _,wid in ipairs(self.m_ActionList) do
        local oAction = self:GetWarrior(wid)
        if oAction and oAction:IsDead() and not oAction:QueryBoutArgs("dead_action") then
            extend.Array.remove(self.m_ActionList,wid)
            oAction:SetBoutArgs("dead_action",1)
        end
    end
end


function CWar:CheckNextBoutStart()
    local iWarWin  = self:IsCanWarEnd()
    if iWarWin then
        if iWarWin == 1 and self:IsPVEWar() and self:CanStartNextWave() then
            self:StartNextWave()
            self:BoutStart()
            return true
        end
        self:DrawWarEnd(iWarWin)
        return true
    else
        if #self.m_ActionList == 0 then
            self:BoutEnd()
            self:BoutStart()
            return true
        end
    end
    return false
end

function CWar:IsCanWarEnd()
    local iAliveCount1 = self.m_lCamps[1]:GetAliveCount()
    local iAliveCount2 = self.m_lCamps[2]:GetAliveCount()
    if iAliveCount1 <= 0 then return 2 end
    if iAliveCount2 <= 0 then return 1 end
    return nil
end

function CWar:DrawWarEnd(iWin)
    self.m_iWarResult = iWin
    self:DelTimeCb("WarEndEffect")
    local iWarId = self:GetWarId()
    self:AddTimeCb("WarEndEffect",30,function ()
            local oWarMgr = global.oWarMgr
            local oWar = oWarMgr:GetWar(iWarId)
            oWar:WarEndEffect()
        end)
end


function CWar:CheckAlive()
    for k,_ in pairs(self.m_mWarriors) do
        local oAction = self:GetWarrior(k)
        if oAction:GetHp() <= 0 and oAction:IsAlive() then
            oAction.m_oStatus:Set(gamedefines.WAR_WARRIOR_STATUS.DEAD)
            oAction:StatusChange("status")
        end
    end

end


function CWar:DisconnectedAutoAction()
    self:DelTimeCb("DisconnectedAutoAction")
    for k,_ in pairs(self.m_mWarriors) do
        local o = self:GetWarrior(k)
        if o and o:IsPlayer() and o:IsDisconnected() then
            o:AutoCommand()
        end
    end
end


function CWar:OnWarStart()
    for _,v in ipairs(self.m_lCamps) do
        v:OnWarStart()
    end
    if self:IsWarRecord() then
        self.m_oRecord:AddBoutTime(0,0)
    end
    self.m_iStarTime = get_time()
end

function CWar:OnBoutStart()
    local mBoutSpeed = self:GetExtData("bout_speed")
    if mBoutSpeed then
        self:SendAll("GS2CWarSpeed",{
            war_id = self.m_iWarId,
            speed_list = mBoutSpeed
        })
    end
    self.m_mBoutArgs = {}
    for _, v in ipairs(self.m_lCamps) do
        v:OnBoutStart()
    end
end

function CWar:NewBout()
    for _,v in ipairs(self.m_lCamps) do
        v:NewBout()
    end
    self:AddDebugMsg(string.format("第%d回合",self.m_iBout),true)
end

function CWar:OnBoutEnd()
    self:CheckAttackFloat()
    for k, v in pairs(self.m_mBoutCmds) do
        local oAction = self:GetWarrior(k)
        if oAction and not oAction:IsAction() then
            oAction:SendAll("GS2CWarAction",{
                war_id = oAction:GetWarId(),
                wid = oAction:GetWid()
            })
        end
    end
    self.m_mBoutCmds = {}
    for iCamp, v in ipairs(self.m_lCamps) do
        v:OnBoutEnd()
    end
    self:SendDebugMsg()
    local iTime = self:GetAnimationTime() + self:BaseAnimationTime()
    self.m_oRecord:AddBoutTime(self.m_iBout,iTime)
end


function CWar:OnWarEscape(oPlayer,iActionWid)
    local oActionMgr = global.oActionMgr
    local oAction = self:GetWarrior(iActionWid)
    if oAction and not self:IsWarEnd() then
        oActionMgr:WarEscape(oAction)
        self:CheckWarEnd()
    end
end

function CWar:SendObserver(sMessage, mData, mExclude)
    mExclude = mExclude or {}
    for iPid, oObserver in pairs(self.m_mObservers) do
        if not mExclude[iPid] then
            oObserver:Send(sMessage, mData)
        end
    end
end

function CWar:SendObserverRaw(sData,mExclude)
    mExclude = mExclude or {}
    for iPid, oObserver in pairs(self.m_mObservers) do
        if not mExclude[iPid] then
            oObserver:SendRaw(sData)
        end
    end
end

function CWar:SendAll(sMessage, mData, mExclude)
    mExclude = mExclude or {}
    local sData = playersend.PackData(sMessage,mData)
    for k, _ in pairs(self.m_mWatcher) do
        if not mExclude[k] then
            local o = self:GetWarrior(k)
            if o then
                o:SendRaw(sData)
            end
        end
    end
    self:SendObserverRaw(sData,mExclude)


    if self:IsWarRecord() then
        if sMessage == "GS2CWarCommand" then
            self.m_oRecord:AddBoutCmd(sMessage,mData)
        else
            self.m_oRecord:AddClientPacket(sMessage,mData)
        end
    end
end


function CWar:Send(iPid,iWid,sMessage,mData)
    if not self.m_bCacheCmd then
        playersend.Send(iPid,sMessage,mData)
    else
        self:InsertActionCache(iPid,iWid,sMessage,mData)
    end
end

function CWar:SendRaw(iPid,iWid,sData)
    if not self.m_bCacheCmd then
        playersend.SendRaw(iPid,sData)
    else
        self:InsertActionRawCache(iPid,iWid,sData)
    end
end

function CWar:SyncBoutStart()
    self.m_SyncOperateCmd = {}
    local f = function(iCamp)
        local oList = self:GetWarriorList(iCamp)
        local mOperate = {}
        for _,o in ipairs(oList) do
            if o:IsPlayer() or o:IsPartner() then
                local iSkill = o:GetNormalAttackSkillId()
                table.insert(mOperate,{wid = o:GetWid(),skill = iSkill,})
            end
        end
        self.m_SyncOperateCmd[iCamp] = mOperate

        local sData = playersend.PackData("GS2CSelectCmd",{cmd = mOperate})
        for _,o in ipairs(oList) do
            if o:IsPlayer() then
                o:SendRaw(sData)
            end
        end
    end
    f(1)
    f(2)
end

function CWar:SyncOperateCmd(oWarrior,skill)
    local mData = self.m_SyncOperateCmd or {}
    local mOperate = mData[oWarrior:GetCampId()]
    if not mOperate then
        return
    end
    local cobj = self:GetCamp(oWarrior:GetCampId())
    local oWarriorList = cobj:GetWarriorList()

    local iWid = oWarrior:GetWid()
    for pos,t in ipairs(mOperate) do
        if t["wid"] == iWid then
            table.remove(mOperate,pos)
            break
        end
    end
    table.insert(mOperate,{wid = iWid,skill = skill})
    local sData = playersend.PackData("GS2CSelectCmd",{cmd = mOperate})
    for _,o in ipairs(oWarriorList) do
        if o:IsPlayer() then
            o:SendRaw(sData)
        end
    end
end

function CWar:InsertActionCache(iPid,wid,sMessage,mData)
    local sData = playersend.PackData(sMessage,mData)
    self:InsertActionRawCache(iPid,wid,sData)
end

function CWar:InsertActionRawCache(iPid,wid,sData)
    if not self.m_LockCachePacket[wid] then
        self.m_LockCachePacket[wid] = {pid=iPid,data = {}}
    end
    table.insert(self.m_LockCachePacket[wid]["data"],sData)
end

function CWar:SendActionCache()
    local mCache = self.m_LockCachePacket
    self.m_LockCachePacket = nil
    mCache = mCache or {}
    for wid,mData in pairs(mCache) do
        local iPid = mData["pid"]
        local lMessage = mData["data"]
        playersend.SendRawList(iPid,lMessage)
    end
end


function CWar:SetExtData(sKey,iValue)
    self.m_mExtData[sKey] = iValue
end

function CWar:GetExtData(sKey,rDefaule)
    return self.m_mExtData[sKey] or rDefaule
end

function CWar:AddBoutArgs(key,value)
    local iValue = self.m_mBoutArgs[key] or 0
    self.m_mBoutArgs[key] = iValue + value
end

function CWar:SetBoutArgs(key,value)
    self.m_mBoutArgs[key] = value
end

function CWar:QueryBoutArgs(key,rDefault)
    return self.m_mBoutArgs[key] or rDefault
end

--是否是单人战斗
function CWar:IsSinglePlayer()
    local iCnt = table_count(self.m_mPlayers)
    if iCnt > 1 then
        return false
    end
    return true
end

function CWar:IsPVEWar()
    return not self.m_bPVP
end

function CWar:IsPVPWar()
    return self.m_bPVP
end

function CWar:PlayerStop()
    if self.m_oActionStatus:Get() ~= gamedefines.WAR_ACTION_STATUS.OPERATE then
        return
    end
    if self.m_iWarResult ~= 0 then
        return
    end
    self:DelTimeCb("AutoNextAction")
    self:DelTimeCb("AutoActionStart")
    self:DelTimeCb("BoutEndTimeOut")
    self:DelTimeCb("AutoStart")

    self.m_iWarStatus = gamedefines.WAR_STATUS.STOP
    self:SendAll("GS2CWarStatus",{
        war_id = self.m_iWarId,
        status = 0,
    })

    self.m_iWarStatus = gamedefines.WAR_STATUS.STOP
    local iStartTime = self:GetExtData("action_start",0)
    local iBoutOpTime = self:GetExtData("action_op_time",15)
    iBoutOpTime = iStartTime + iBoutOpTime - get_time()
    iBoutOpTime = math.max(iBoutOpTime,0)
    self:SetExtData("action_op_time",iBoutOpTime)
    local iWarId = self:GetWarId()
    local oWarMgr = global.oWarMgr
    self:AddTimeCb("AutoStart",3600*2*1000,function ()
        local oWar = oWarMgr:GetWar(iWarId)
        oWar:AutoStart()
    end)
end

function CWar:AutoStart()
    self:PlayerStart()
end

function CWar:PlayerStart()
    self:DelTimeCb("AutoNextAction")
    self:DelTimeCb("AutoActionStart")
    self:DelTimeCb("BoutEndTimeOut")
    self:DelTimeCb("AutoStart")
    local iSecs = self:GetExtData("action_op_time",0)
    self:SendAll("GS2CWarStatus",{
        war_id = self.m_iWarId,
        status = 1,
        left_time = iSecs,
    })
    self:SendAll("GS2CActionStart",{ war_id=self:GetWarId(),
        wid=iAction,
        action_id = self.m_ActionId,
        left_time = iSecs,
        })
    self.m_iWarStatus = gamedefines.WAR_STATUS.START

    local iTimeOut = ( iSecs + 1 ) * 1000
    local iWarId = self:GetWarId()
    self:SetExtData("action_start",get_time())
    self:AddTimeCb("AutoActionStart",iTimeOut,function ()
            local oWar = global.oWarMgr:GetWar(iWarId)
            if oWar then
                oWar:ActionAutoStart()
            end
    end)

    local iBoutTime = 400 * 1000
    self:DelTimeCb("BoutEndTimeOut")
    self:AddTimeCb("BoutEndTimeOut",iBoutTime,function ()
        local oWar = global.oWarMgr:GetWar(iWarId)
        if oWar then
            oWar:BoutEndTimeOut()
        end
    end)


end

function CWar:AddSP(iCamp,iSP,mArg)
    mArg = mArg or {}
    local oCamp = self.m_lCamps[iCamp]
    if not oCamp then
        return
    end
    oCamp:AddSP(iSP)
    oCamp:SendAll("GS2CWarSP",{
        war_id = self.m_iWarId,
        camp_id = iCamp,
        sp = oCamp:GetSP(),
        attack = mArg["wid"] or 0,
        skiller = mArg["skiller"],
        addsp = iSP,
    })
end

function CWar:ValidSP(iCamp,iSP)
    local oCamp = self.m_lCamps[iCamp]
    if not oCamp then
        return false
    end
    return oCamp:ValidResumeSP(iSP)
end

function CWar:AddDebugPlayer(oWarrior)
    self.m_mDebugPlayer[oWarrior:GetPid()] = oWarrior:GetWid()
end

function CWar:DelDebugPlayer(oWarrior)
    self.m_mDebugPlayer[oWarrior:GetPid()] = nil
end

function CWar:IsDebugWar()
    if table_count(self.m_mDebugPlayer) > 0 then
        return true
    end
    return false
end

function CWar:AddDebugMsg(sMsg, bNew)
    if bNew and table_count(self.m_mDebugMsg) then
        local sMessage = table.concat(self.m_mDebugMsg,",")
        table.insert(self.m_mDebugMsgQueue, sMessage)
        self.m_mDebugMsg = {}
    end
    if sMsg and sMsg ~= "" then
        table.insert(self.m_mDebugMsg, sMsg)
    end
end

function CWar:SendDebugMsg()
    if table_count(self.m_mDebugMsg) then
        local sMsg = table.concat(self.m_mDebugMsg,",")
        table.insert(self.m_mDebugMsgQueue, sMsg)
        self.m_mDebugMsg = {}
    end
    for _, sMessage in pairs(self.m_mDebugMsgQueue) do
        local mData = {
            type = gamedefines.CHANNEL_TYPE.MSG_TYPE,
            content = sMessage,
        }
        local sData = playersend.PackData("GS2CConsumeMsg", mData)
        for pid, iWid in pairs(self.m_mDebugPlayer) do
            local o = self:GetWarrior(iWid)
            if o then
                o:SendRaw(sData)
            end
        end
    end
    self.m_mDebugMsgQueue = {}
end

function CWar:SendWarSpeed(oTarget)
    local mSpeed = {}
    for k,_ in pairs(self.m_mWarriors) do
        local o = self:GetWarrior(k)
        if o then
            local iSpeed = o:QueryAttr("speed")
            table.insert(mSpeed,{k,iSpeed})
        end
    end
    if #mSpeed <= 0 then
        return
    end
    local fSort = function (mData1,mData2)
        if mData1[2] ~= mData2[2] then
            return mData1[2] < mData2[2]
        else
            return mData1[1] < mData2[1]
        end
    end
    table.sort(mSpeed,fSort)
    local mBoutSpeed = {}
    for _,mData in pairs(mSpeed) do
        local k,iSpeed = table.unpack(mData)
        table.insert(mBoutSpeed,{wid=k,speed=iSpeed})
    end
    if not oTarget then
        self:SendAll("GS2CWarSpeed",{
            war_id = self.m_iWarId,
            speed_list = mBoutSpeed,
        })
    else
        oTarget:Send("GS2CWarSpeed",{
            war_id = self.m_iWarId,
            speed_list = mBoutSpeed
        })
    end
end

function CWar:DispatchActionSort(oAction)
    local iCamp = oAction:GetCampId()
    local iSort = self:QueryBoutArgs("action_sort",0)
    iSort = iSort + 1
    self:SetBoutArgs("action_sort",iSort)
    oAction:SetBoutArgs("action_sort",iSort)
end

--连击
function CWar:CheckAttackFloat()
    for k,_ in pairs(self.m_mWarriors) do
        local oAction = self:GetWarrior(k)
        if oAction then
            oAction:CheckAttackFloat()
        end
    end
end


--检查战斗是否可以结束
function CWar:CheckWarEnd()
    local iAliveCount1 = self.m_lCamps[1]:GetAliveCount()
    local iAliveCount2 = self.m_lCamps[2]:GetAliveCount()
    if iAliveCount1 <= 0 then
        self.m_iWarResult = 2
        self:WarEndEffect()
    elseif iAliveCount2 <= 0 then
        self.m_iWarResult = 1
        self:WarEndEffect()
    end
end

function CWar:IsWarEnd()
    if self.m_iWarResult ~= 0 then
        return true
    end
    return false
end

--当前战斗怪物的波数
function CWar:CurrentEnemyWave()
    return self:GetExtData("current_enemy_wave",1)
end

function CWar:SetCurrentEnemyWave(iWave)
    self:SetExtData("current_enemy_wave",iWave)
end

--是否有下一波怪物
function CWar:CanStartNextWave()
    local mWaveData = self:GetExtData("wave_enemy_monster",{})
    local iSumWave = #mWaveData
    local iCurrentWave = self:CurrentEnemyWave()
    if iSumWave > iCurrentWave then
        return true
    end
    return false
end

--下一波怪物开始战斗
function CWar:StartNextWave()
    -- 在下一波的时候,由于没有动作时间,所以客户端发C2GSNextBoutStart会比较短
    self:SetBoutArgs("TMinTime",0.5)
    self:SetBoutArgs("Skip_BoutCheck",1)
    local iCurrentWave = self:CurrentEnemyWave()
    local iNextWave = iCurrentWave + 1
    local mWaveData = self:GetExtData("wave_enemy_monster",{})
    self:SetCurrentEnemyWave(iNextWave)
    self:GS2CWarWave()


    self:ClearWarWave()

    local mEnemyData = mWaveData[iNextWave]
    assert(mEnemyData,string.format("start next wave error:%s",self:GetWarId()))
    local mMonsterData = {
        [2] = mEnemyData
    }

    self:PrepareNextWaveMonster(mMonsterData)
end

function CWar:ClearWarWave()
    local iCamp = 1
    local oCamp = self:GetCamp(iCamp)
    local mFriend = oCamp:GetWarriorList()
    for _,oFriend in pairs(mFriend) do
        oFriend.m_oBuffMgr:ClearBuff()
        if oFriend:IsCallNpc() then
            local mArgs = {
            del_type = 2,
            }
            self:KickOutWarrior(oFriend,mArgs)
        end
    end

    local iCamp = 2
    local oCamp = self:GetCamp(iCamp)
    local mEnemy = oCamp:GetWarriorList()
    for _,oEnemy in pairs(mEnemy) do
        self:KickOutWarrior(oEnemy)
    end

end

function CWar:GS2CWarWave(oAction)
    local iMaxWave = self:GetMaxWarWave()
    if not oAction then
        self:SendAll("GS2CWarWave",{
            cur_wave = self:CurrentEnemyWave(),
            sum_wave = iMaxWave,
        })
    else
        oAction:Send("GS2CWarWave",{
            cur_wave = self:CurrentEnemyWave(),
            sum_wave = iMaxWave,
        })
    end
end


function CWar:GetMaxWarWave()
     local mWaveData = self:GetExtData("wave_enemy_monster",{})
     return #mWaveData
end

function CWar:DebugWarrior()
    local record = require "public.record"
    for k,_ in pairs(self.m_mWarriors) do
        local oWarrior = self:GetWarrior(k)
        if oWarrior then
            record.debug(string.format("怪物:%s,wid:%s,dead:%s,hp:%s",oWarrior:GetName(),k,oWarrior:IsDead(),oWarrior:GetHp()))
        end
    end
end

function CWar:SetBattleCmd(iCamp,wid,cmd)
    local oWarrior = self:GetWarrior(wid)
    if not oWarrior then
        return
    end
    if not cmd then
        self.m_BattleCmd[iCamp][wid] = nil
    else
        self.m_BattleCmd[iCamp][wid] = cmd
    end
    self:RefreshBatleCmd(iCamp)
end


function CWar:RefreshBatleCmd(iCamp,oWarrior)
    local mCmd = self.m_BattleCmd[iCamp]
    local mBcmd = {}
    for wid,str in pairs(mCmd) do
        table.insert(mBcmd,{wid=wid,cmd=str})
    end
    local mNet = {
        war_id = self:GetWarId(),
        cmd = mBcmd,
        }
    if not oWarrior then
        for _,oWarrior in pairs(self:GetWarriorList(iCamp)) do
            if oWarrior:IsPlayer() then
                oWarrior:Send("GS2CWarBattleCmd",mNet)
            end
        end
    else
        oWarrior:Send("GS2CWarBattleCmd",mNet)
    end
end

function CWar:AddActionEnd(oPlayer)
    local iPid = oPlayer:GetPid()
    self.m_mActionEndList[iPid] = 1
end

function CWar:IsStartNextAction()
    local iPlayerCnt = 0
    for iPid,iWid in pairs(self.m_mPlayers) do
        local oPlayerWarrior = self:GetWarrior(iWid)
        if oPlayerWarrior and not oPlayerWarrior:IsDisconnected() then
            iPlayerCnt = iPlayerCnt + 1
        end
    end
    local iPlayEndCnt = table_count(self.m_mActionEndList)
    local iNeedCnt = math.floor(iPlayerCnt/2+1)
    if iPlayEndCnt >= iNeedCnt then
        return true
    end
    return false
end

function CWar:CheckStartNextAction()
    if self.m_oActionStatus:Get() == gamedefines.WAR_ACTION_STATUS.OPERATE then
        return
    end
    if not self:IsStartNextAction() then
        return
    end
    self:NextActionStart()
end


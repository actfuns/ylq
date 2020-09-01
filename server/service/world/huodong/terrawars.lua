---TODO
    --可进攻可支援的判断条件顺序修改，把需要异步获取数据的判断条件放最后
    ---GetListInfo
---防守阵营为1,进攻阵营为2
-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local terra = import(service_path("huodong/npcobj/terranpcobj"))
local partnerctrl = import(service_path("playerctrl.partnerctrl"))
local warobj = import(service_path("warobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
local interactive = require "base.interactive"
local npcobj = import(service_path("npc/npcobj"))
local xgpush = import(lualib_path("public.xgpush"))

local res = require "base.res"
local global = require "global"
local record = require "public.record"

local MAX_ATTACK = 5
local MAX_HELP = 5
local PROTECT_TIME = 15
local REFRESHPOINTS_TIME = 1

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "据点攻防战"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_bStart = 0
    self.m_iNextOpenTime = 0           ---下次开启时间
    self.m_iNextPrepareTime = 0     ---下次预热时间
    self.m_iNextCloseTime = 0          ---活动关闭时间
    self.m_mTerra = {}      -----驻点
    self.m_mAttack = {}     -----进攻队列
    self.m_mHelp = {}       -----支援队列
    self.m_mGuard = {}      ---驻守队伍信息
    self.m_mCurFight = {}       ----当前战斗信息
    self.m_mPid2Terra = {}      ----玩家的进攻支援信息
    self.m_mHasHelp = {}        ----当前一轮战斗已经支援过的玩家列表（同一玩家一轮只可支援一次）
    self.m_mHasAttack = {}     ----当前一轮战斗已经进攻过的玩家列表（同一玩家一轮只可进攻一次）
    self.m_mBackUp = {}         ----玩家角色和伙伴镜像临时数据备份
    self.m_PersonalPoints = {}  ----个人积分
    self.m_OrgPoints = {}       ---工会积分
    self.m_mContribution = {}
    self.m_OfflineContribution = {} --玩家离线时获取的贡献度
    self.m_mSetGuad = {}        ---正在设置驻守伙伴的据点
    self.m_mSelfSave = {}   ---自救情况
    self.m_mPlayerStatus = {} --玩家状态：1：正在设置驻守伙伴
    self.m_OfflineRemove={} --离线时被占领据点移除的驻守伙伴，上线后需要同步状态到伙伴service
    self.m_PrepareList = {} --记录正处于30秒准备状态的玩家
    self.m_WarCountDown = {}
    self.m_mClearPartnerMark = {} ---记录离线重登后需要清空上次活动伙伴驻守状态的玩家
    self.m_mAchieveDegree = {} --- 记录本轮活动是否完成过成就
    self.m_iVersion = 0
    self.m_iScheduleID = 2004
    self.m_mOrgLog = {}
    self.m_mTerra2Log = {}      --用于定位log，不存盘
    self.m_mWarEnd = {} --不存盘
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Load(mData)
    self.m_bStart = mData.start or 0
    local mTerra = mData.terra or {}
    self.m_mTerra = {}
    for id,info in pairs(mTerra) do
        local oTerra = terra.NewTerra(info)
        self.m_mTerra[id] = oTerra
        self.m_mNpcList[oTerra.m_ID] = oTerra
        self:Npc_Enter_Map(oTerra, info.map_id, table_deep_copy(oTerra:PosInfo()))
    end
    --self.m_mAttack = mData.attack or {}
    --self.m_mHelp = mData.help or {}
    self.m_mGuard = mData.guard or {}
    self.m_PersonalPoints = mData.personal_points or {}  ----个人积分
    self.m_OrgPoints = mData.org_points or {}       ---工会积分
    self.m_OfflineContribution = mData.offline_contribution or {}
    self.m_mSelfSave = mData.selfsave or {}
    self.m_mPlayerStatus = mData.playerstatus or {}
    self.m_iNextOpenTime = mData.nextopentime or 0
    self.m_iNextPrepareTime = mData.nextpreparetime or 0
    self.m_iNextCloseTime = mData.nextclosetime or 0
    self.m_mBackUp = mData.backup or {}
    self.m_mAchieveDegree = mData.achievedegree or {}
    self.m_iVersion = mData.version or 0
    self.m_OfflineRemove = mData.offlineremove or {}
    self.m_mClearPartnerMark = mData.clearpartnermark or {}
    self.m_mOrgLog = mData.orglog or {}
end

function CHuodong:AfterLoad()
    if self.m_bStart == 0 then
        self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_CLOSE)
        self:CheckPrepare()
    elseif self.m_bStart == 1 then
        self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_START)
        self:CheckClose()
    elseif self.m_bStart == 2 then
        self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_OVER)
        self:CheckOpen()
    end
    if table_count(self.m_mPlayerStatus) > 0 then
        for iPid,iTerraId in pairs(self.m_mPlayerStatus) do
            self:AutoSetGuardPartner(iPid,iTerraId)
        end
    end
end

function CHuodong:Save()
    local m = {}
    m.start = self.m_bStart or 0
    m.terra = self:SaveTerraInfo()
    --m.attack = self.m_mAttack
    --m.help = self.m_mHelp
    m.guard = self.m_mGuard
    m.personal_points = self.m_PersonalPoints
    m.org_points = self.m_OrgPoints
    m.offline_contribution = self.m_OfflineContribution
    m.selfsave = self.m_mSelfSave
    m.playerstatus = self.m_mPlayerStatus
    m.nextopentime = self.m_iNextOpenTime
    m.nextpreparetime = self.m_iNextPrepareTime
    m.nextclosetime = self.m_iNextCloseTime
    m.backup = self.m_mBackUp
    m.achievedegree = self.m_mAchieveDegree
    m.version = self.m_iVersion
    m.offlineremove = self.m_OfflineRemove
    m.clearpartnermark = self.m_mClearPartnerMark
    m.orglog = self.m_mOrgLog
    return m
end

function CHuodong:SaveTerraInfo()
    local mTerra = {}
    for id,oTerra in pairs(self.m_mTerra) do
        mTerra[id] = oTerra:Save()
    end
    return mTerra
end

function CHuodong:GetFirstPrepareTime()
    local sTime = res["daobiao"]["global"]["terrawars_firstprepare_time"]["value"]
    local mArgs = split_string(sTime,"-")
    local iWeekDay,iHour,iMin = table.unpack(mArgs)
    return tonumber(iWeekDay),tonumber(iHour),tonumber(iMin)
end

function CHuodong:GetPrepareTime()
    local sTime = res["daobiao"]["global"]["terrawars_preparetime"]["value"]
    return tonumber(sTime)
end

function CHuodong:GetOpenTime()
    local sTime = res["daobiao"]["global"]["terrawars_open_time"]["value"]
    return tonumber(sTime)
end

function CHuodong:GetOpenInterval()
    local sTime = res["daobiao"]["global"]["terrawars_open_interval"]["value"]
    return tonumber(sTime)
end

function CHuodong:NewHour(iWeekDay, iHour)
    if self.m_iNextPrepareTime == 0 then
        self:NewHour1(iWeekDay,iHour)
    end
    if self.m_bStart == 1 and (iHour == 10 or iHour == 19) then
        self:AddTimeCb("SendWarBrocast",30*60*1000,function()
            local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
            if oHuodong then
                oHuodong:SendWarBrocast()
            end
        end)
    end
end

function CHuodong:NewHour1(iWeekDay,iHour)
    local iFirstPrepareDay,iFirstPrepareHour,iFirstPrepareMin = self:GetFirstPrepareTime()
    local iServerDay = global.oWorldMgr:GetOpenDays()
    if iServerDay ~= iFirstPrepareDay then
        return
    end
    if iHour == iFirstOpenHour then
        if iFirstOpenMin > 0 then
            local func = function()
                local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
                if oHuodong then
                    oHuodong:StartPrepare()
                end
            end
            self:Dirty()
            self.m_iNextPrepareTime = get_time() + iFirstPrepareMin * 60
            self:AddTimeCb("StartPrepare",iFirstPrepareMin*60*1000,func)
        else
            self:StartPrepare()
        end
    end
end

function CHuodong:InitPrepare()
    self:Dirty()
    local iFirstPrepareDay,iFirstPrepareHour,iFirstPrepareMin = self:GetFirstPrepareTime()
    local iServerDay = global.oWorldMgr:GetOpenDays()
    local mTime = get_daytime({day=(iFirstPrepareDay-iServerDay),anchor = iFirstPrepareHour})
    local iTime = mTime.time+iFirstPrepareMin*60
    self.m_iNextPrepareTime = iTime
end

function CHuodong:CheckPrepare()
    if self.m_iNextPrepareTime == 0 then
        self:InitPrepare()
    end
    if self.m_iNextPrepareTime <= get_time() then
        self:StartPrepare()
    else
        local iLeftTime = self.m_iNextPrepareTime - get_time()
        self:AddTimeCb("StartPrepare",iLeftTime*1000,function()
            local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
            oHuodong:StartPrepare()
        end)
    end
end

--开始预热
function CHuodong:StartPrepare()
    self:Dirty()
    self:ClearPointsInfo()
    local iPrepareTime = self:GetPrepareTime() * 60
    self.m_bStart = 2
    if self.m_iNextPrepareTime < get_time() then
        iPrepareTime = iPrepareTime - (get_time() - self.m_iNextPrepareTime)
    end
    self.m_iNextOpenTime = get_time() + iPrepareTime
    self:DelTimeCb("StartPrepare")
    if iPrepareTime > 0 then
        self:BroadCastTerraWarsState(2,self.m_iNextOpenTime)
        self:AddTimeCb("StartOpen",iPrepareTime*1000,function()
            local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
            oHuodong:StartOpen()
        end)
    else
        self:StartOpen()
    end
    interactive.Send(".rank","rank","ResetTerrawars",{})
end

function CHuodong:ClearPointsInfo()
    self.m_PersonalPoints = {}
    self.m_OrgPoints = {}
    self.m_mContribution = {}
end

function CHuodong:CheckOpen()
    if self.m_iNextOpenTime <= get_time() then
        self:StartOpen()
    else
        self:AddTimeCb("StartOpen",(self.m_iNextOpenTime - get_time())*1000,function()
            local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
            oHuodong:StartOpen()
        end)
    end
end

function CHuodong:StartOpen()
    self:Dirty()
    local iOpenTime = self:GetOpenTime()
    self.m_bStart = 1
    self.m_iVersion = self.m_iVersion + 1
    self.m_iNextCloseTime = get_time() + iOpenTime*60
    self:BroadCastTerraWarsState(1,self.m_iNextCloseTime)
    self:ShowTerra()
    self:DelTimeCb("StartOpen")
    self:AddTimeCb("StartClose",iOpenTime*60*1000,function()
        local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
        oHuodong:StartClose()
    end)
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_START)
end

function CHuodong:CheckClose()
    if self.m_iNextCloseTime <= get_time() then
        self:StartClose()
    else
        self:AddTimeCb("StartClose",(self.m_iNextCloseTime - get_time())*1000,function()
            local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
            oHuodong:StartClose()
        end)
    end
end

function CHuodong:StartClose()
    self:Dirty()
    local iInterval = self:GetOpenInterval()
    local iPrepareTime  = self:GetPrepareTime()*60
    self.m_bStart = 0
    self.m_iNextPrepareTime = get_time() + iInterval*60
    self:BroadCastTerraWarsState(0,self.m_iNextPrepareTime+iPrepareTime)
    self:Close()
    self:DelTimeCb("StartClose")
    self:AddTimeCb("StartPrepare",iInterval*60*1000,function()
        local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
        oHuodong:StartPrepare()
    end)
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_OVER)
end

function CHuodong:TestOpenTime(iWeekDay,iHour)
    local iOpenDay,iOpenHour,iOpenMin = self:GetOpenTime()
    if iWeekDay == iOpenDay and iHour == iOpenHour then
        local bOpen = res["daobiao"]["global_control"]["terrawars"]["is_open"]
        if bOpen ~= "y" then
            return
        end
        local m = os.date("*t", get_time())
        local iCurMin = m.min
        if iOpenMin > 0 and iCurMin < iOpenMin then
            local iTime = iOpenMin - iCurMin
        else
        end
    else
    end
end

function CHuodong:GetStatus()
    if self.m_bStart == 1 then
        return 1,self.m_iNextCloseTime
    elseif self.m_bStart == 2 then
        return 2,self.m_iNextOpenTime
    elseif self.m_bStart == 0 then
        local iPrepareTime = self:GetPrepareTime()*60
        return 0,self.m_iNextPrepareTime+iPrepareTime
    end
end

function CHuodong:GetTerraBaseData()
    local mData = res["daobiao"]["huodong"][self.m_sName]["terraconfig"]
    return mData
end

function CHuodong:PacketNpcInfo(iNpcId)
    local mTerra =  self:GetTerraBaseData()
    local info = mTerra[iNpcId]
    local mArgs = super(CHuodong).PacketNpcInfo(self,iNpcId)
    mArgs.terra_id = info.id
    mArgs.size = info.size
    return mArgs
end

function CHuodong:GetTerra(iTerraId)
    return self.m_mTerra[iTerraId]
    -- body
end

function CHuodong:GetTerraOwner(iTerraId)
    if self.m_mGuard[iTerraId] and self.m_mGuard[iTerraId].owner then
        return self.m_mGuard[iTerraId].owner
    else
        return 0
    end
end

function CHuodong:NewHDNpc(mArgs,iTempNpc)
    return terra.NewTerra(mArgs)
end

function CHuodong:NewMirrorNpc(mArgs,iTempNpc)
    return NewMirrorNpc(mArgs)
end

function CHuodong:OnLogin(oPlayer,bReEnter)
    local iPid = oPlayer.m_iPid
    if not bReEnter then
        local iLastLoginTime = oPlayer.m_oActiveCtrl:GetData("lastlogin_time",0)
        if iLastLoginTime ~= 0 then
        end
    end
    if self.m_bStart == 1 then
        local mLingli = oPlayer.m_oActiveCtrl:GetData("lingli",{})
        if not mLingli["version"] or mLingli["version"] ~= self.m_iVersion then
            mLingli = {buy_times=0,lingli = 10,lastgive=get_time(),givelingli=1,version = self.m_iVersion}
            oPlayer.m_oActiveCtrl:SetData("lingli",mLingli)
        end
    end
    local iStatus,iTime = self:GetStatus()
    oPlayer:Send("GS2CTerraWarState",{state = iStatus,time = iTime})

    self:CheckOfflineContribution(oPlayer)
    self:CheckOfflineRemove(oPlayer)
    self:CheckQueueStatus(oPlayer)

    if self.m_mClearPartnerMark[iPid] then
        self:Dirty()
        oPlayer.m_oPartnerCtrl:SyncGuardInfo(self.m_mClearPartnerMark[iPid])
        self.m_mClearPartnerMark[iPid] = nil
    end
    --self:CheckOfflineRewardLingli(oPlayer)
end

function CHuodong:CheckQueueStatus(oPlayer)
    local iStatus = 0
    if self.m_mPid2Terra[oPlayer.m_iPid] then
        iStatus = 1
    end
    oPlayer:Send("GS2CTerraQueueStatus",{status=iStatus})
end

function CHuodong:CheckOfflineRewardLingli(oPlayer)

end

function CHuodong:CheckOfflineRemove(oPlayer)

    local iPid = oPlayer:GetPid()
    if self.m_OfflineRemove[iPid] then
        self:Dirty()
        local mBusyPartner = oPlayer.m_oActiveCtrl:GetData("terra_partner",{})
        for iTerraId,info in pairs(self.m_OfflineRemove[iPid]) do
            oPlayer.m_oPartnerCtrl:SyncGuardInfo(info)
            for iParId,_ in pairs(info) do
                if mBusyPartner[iParId] then
                    mBusyPartner[iParId] = nil
                end
            end
        end
        oPlayer.m_oActiveCtrl:SetData("terra_partner",mBusyPartner)
        self.m_OfflineRemove[iPid] = nil
    end
end

function CHuodong:ShowTerra()
    self:Dirty()
    local mTerra =  self:GetTerraBaseData()
    for id,info in pairs(mTerra) do
        local oTerra  = self:CreateTempNpc(id)
        self.m_mTerra[id] = oTerra
        self:Npc_Enter_Map(oTerra, info.map_id, table_deep_copy(oTerra:PosInfo()))
    end
    local fRefreshFunc = function()
        self:RefreshPoints()
    end
    self:DelTimeCb("_RefreshPoints")
    self:AddTimeCb("_RefreshPoints",REFRESHPOINTS_TIME*60*1000,fRefreshFunc)
end

function CHuodong:Npc_Enter_Map(oTempNpc, iMapid, mPosInfo)
    iMapid = iMapid or oTempNpc.m_iMapid
    if not iMapid then
        return
    end
    local oSceneMgr = global.oSceneMgr
    local mScene = oSceneMgr:GetSceneListByMap(iMapid)
    local oNpc = oTempNpc
    local iMainNpc = oTempNpc:ID()
    for k, oScene in ipairs(mScene) do
        if k ~= 1 then
            oNpc = self:CreateMirrorNpc(oTempNpc:Type(),iMainNpc)
        end
        oNpc.m_mPosInfo = mPosInfo
        oNpc.m_iMapid = oScene:MapId()
        oNpc:SetScene(oScene:GetSceneId())
        oScene:EnterNpc(oNpc)
    end
end

function CHuodong:CreateMirrorNpc(iType,iMainNpc)
    local mArgs = self:PacketNpcInfo(iType)
    mArgs.main_npc = iMainNpc
    local oTempNpc = self:NewMirrorNpc(mArgs)
    oTempNpc.m_oHuodong = self
    self.m_mNpcList[oTempNpc.m_ID] = oTempNpc
    return oTempNpc
end

function CHuodong:BroadCastTerraWarsState(iState,iTime)
    local mData = {
        message = "GS2CTerraWarState",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = {state = iState,time = iTime},
        exclude = {},
    }
    interactive.Send(".broadcast", "channel", "SendChannel", mData)
    local oNotifyMgr = global.oNotifyMgr
    if iState == 1 then
        oNotifyMgr:SendPrioritySysChat("terrawars_char","战争的号角已经吹响，[FF0000FF]据点攻防战[-]开始。团结力量占领据点，世界的未来掌握在强者手中！", 1)
    elseif iState == 0 then
        oNotifyMgr:SendPrioritySysChat("terrawars_char","[FF0000FF]据点攻防战[-]在滚滚硝烟之中落下帷幕，世界恢复了短暂的和平。",  1)
    end
end

function CHuodong:RefreshPoints()
    self:Dirty()
    for iTerraId,oTerra in pairs(self.m_mTerra) do
        local iOrgId = oTerra:GetOrgID()
        local iOwner = oTerra:GetTerraOwner()
        if iOwner ~= 0 then
            local iPerPoints = oTerra:GetPersonalPoint()
            local iOrgPoints = oTerra:GetOrgPoint()
            self.m_OrgPoints[iOrgId] = (self.m_OrgPoints[iOrgId] or 0) + REFRESHPOINTS_TIME*iOrgPoints
            self.m_PersonalPoints[iOwner] = (self.m_PersonalPoints[iOwner] or 0) + REFRESHPOINTS_TIME*iPerPoints
        end
    end
end

function CHuodong:PackTerraInfo(iTerraId)
    local oTerra = self.m_mTerra[iTerraId]
    local mData = oTerra:PackNetInfo()
    return mData
end

function CHuodong:ClickTerra(oPlayer,iTerraId)
    local oTerra = self.m_mTerra[iTerraId]
    if not oTerra then
        return
    end
    local iOpenGrade = res["daobiao"]["global_control"]["terrawars"]["open_grade"]
    if oPlayer:GetGrade() < tonumber(iOpenGrade) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,string.format("%s级后开启据点攻防战",iOpenGrade))
        return
    end
    local mData = self:GetTerraInfo(oPlayer,nil,iTerraId)
    local mLingli = self:PackLingliInfo(oPlayer)
    if oPlayer:GetOrgID() == 0 then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(oPlayer.m_iPid,"请先加入公会")
        return
    end
    oPlayer:Send("GS2CTerraInfo",{terrainfo=mData,lingli_info=mLingli})
    -- body
end

function CHuodong:PackLingliInfo(oPlayer)
    local iPid = oPlayer.m_iPid
    local mLingli = oPlayer.m_oActiveCtrl:GetData("lingli",{})
    if not mLingli["version"] or mLingli["version"] ~= self.m_iVersion then
        mLingli = {buy_times=0,lingli = 10,lastgive=get_time(),givelingli=1,version = self.m_iVersion}
    end
    local iLingli = mLingli["lingli"]
    local iMaxLingli = tonumber(res["daobiao"]["global"]["terrawars_max_lingli"]["value"])
    if iLingli >= iMaxLingli then
        oPlayer.m_oActiveCtrl:SetData("lingli",mLingli)
        return {lingli = iLingli,max_lingli=iMaxLingli,lefttime=0}
    end
    local iLastGiveLingliTime = mLingli["lastgive"]
    local iCurTime = get_time()
    local iRewardInterval = tonumber(res["daobiao"]["global"]["lingli_interval"]["value"])
    local iRewarTime,iOverTime = math.modf((iCurTime - iLastGiveLingliTime)/60)
    local iGive = tonumber(res["daobiao"]["global"]["lingli_pergive"]["value"])
    local iT,iM,iLeftTime=0,iRewarTime/iRewardInterval,0
    if iRewarTime >= iRewardInterval then
        iT,iM = math.modf(iRewarTime/iRewardInterval)
        iLingli = iLingli+(iT*iGive)
        iLastGiveLingliTime = (iLingli > iMaxLingli) and iCurTime or (iCurTime - (iM+iOverTime)*60)
        mLingli["lastgive"] = iLastGiveLingliTime
        iLingli = iLingli>iMaxLingli and iMaxLingli or iLingli
        local iAdd = iLingli - mLingli["lingli"]
        mLingli["lingli"] = iLingli
        record.user("terrawars","lingli_change",{pid=iPid,amount = iAdd,reason="灵力恢复"})
        if mLingli["givelingli"] == 0 then
             mLingli["givelingli"] = 1
        end
    end
    oPlayer.m_oActiveCtrl:SetData("lingli",mLingli)
    iLeftTime = iRewardInterval*60 - (iCurTime - iLastGiveLingliTime)
    local iBuyTime = mLingli["buy_times"] or 0
    return {lingli = iLingli,max_lingli=iMaxLingli,lefttime=iLeftTime,buy_times = iBuyTime }
end

function CHuodong:GetLingliInfo(oPlayer)
    local mLingli = oPlayer.m_oActiveCtrl:GetData("lingli",{})
    if not mLingli["version"] or mLingli["version"] ~= self.m_iVersion then
        mLingli = {buy_times=0,lingli = 10,lastgive=get_time(),givelingli=1,version = self.m_iVersion}
        oPlayer.m_oActiveCtrl:SetData("lingli",mLingli)
    end
    return mLingli
end

function CHuodong:UseLingli(oPlayer)
    local iPid = oPlayer.m_iPid
    self:Dirty()
    if not self.m_mAchieveDegree[iPid] then
        global.oAchieveMgr:PushAchieve(iPid,"参与据点战次数",{value=1})
        self.m_mAchieveDegree[iPid] = true
    end
    local mLingli = self:GetLingliInfo(oPlayer)
    local iLingli = mLingli["lingli"] or  0
    local iMaxLingli = tonumber(res["daobiao"]["global"]["terrawars_max_lingli"]["value"])
    if iLingli == iMaxLingli then
        mLingli["lastgive"] = get_time()
    end
    mLingli["lingli"] = iLingli-1
    oPlayer.m_oActiveCtrl:SetData("lingli",mLingli)
    record.user("terrawars","lingli_change",{pid=oPlayer.m_iPid,amount = -1,reason="灵力消耗"})
end

function CHuodong:HasHelp(iPid,iTerraId)
    return self.m_mHasHelp[iTerraId] and self.m_mHasHelp[iTerraId][iPid]
end

function CHuodong:HasAttack(iPid,iTerraId)
    return self.m_mHasAttack[iTerraId] and self.m_mHasAttack[iTerraId][iPid]
end

function CHuodong:IsOnHelp(oPlayer)
    if self.m_mPid2Terra[oPlayer.m_iPid] and self.m_mPid2Terra[oPlayer.m_iPid]["help"] then
        return self.m_mPid2Terra[oPlayer.m_iPid]["terra_id"]
    end
    return false
end

function CHuodong:IsOnAttack(oPlayer)
    if self.m_mPid2Terra[oPlayer.m_iPid] and self.m_mPid2Terra[oPlayer.m_iPid]["attack"] then
        return self.m_mPid2Terra[oPlayer.m_iPid]["terra_id"]
    end
    return false
end

function CHuodong:IsGuardAlive(iTerraId)
    local oTerra = self.m_mTerra[iTerraId]
    return oTerra:IsGuardAlive()
end

function CHuodong:CheckEnoughPartner(oPlayer,mData)
    local mParInfo = oPlayer.m_oActiveCtrl:GetData("terra_partner",{})
    local iValidCnt = 0
    for iParId,info in pairs(mData) do
        if not mParInfo[iParId] and info.grade >= 20 then
            iValidCnt = iValidCnt + 1
            if iValidCnt == 3 then
                return true
            end
        end
    end
    return false
end

function CHuodong:CheckCanAttack(oPlayer,fCallBack)
    oPlayer.m_oPartnerCtrl:GetAllPartnerInfo({grade={"gte",20},status = {"include",5}},fCallBack)
end

function CHuodong:CheckCanAttack2(oPlayer,iTerraId,mData)
    local bEnough = self:CheckEnoughPartner(oPlayer,mData)
    if not bEnough then
        return false,"进攻失败，需要有3个20级以上的伙伴"
    end
    local oTerra = self.m_mTerra[iTerraId]
    if oTerra:IsOnSave() then
        return false,"当前据点处于保护状态"
    end
    if oTerra:GetOrgID() ~= 0 and oTerra:GetOrgID() == oPlayer:GetOrgID() then
        return false,"禁止进攻同一工会的据点"
    end
    if self:HasAttack(oPlayer.m_iPid,iTerraId) then
        return false,"一轮战斗只可进攻一次"
    end
    local iNowId = self:IsOnAttack(oPlayer) or self:IsOnHelp(oPlayer)
    if iNowId then
        local oNow = self.m_mTerra[iNowId]
        local sMsg = string.format("您目前正在%s排队，无法重复进行。",oNow:Name())
        return false,sMsg
    elseif self:GetTerraOwner(iTerraId) == oPlayer.m_iPid then
        return false,"不能进攻自己的据点"
    elseif self.m_mAttack[iTerraId] and ((self.m_mAttack[iTerraId] and table_count(self.m_mAttack[iTerraId]) or 0)+(self.m_mHasAttack[iTerraId] and table_count(self.m_mHasAttack[iTerraId]) or 0)) >= MAX_ATTACK then
        return false,"当前据点进攻人数达到上限"
    else
        local mLingli = self:GetLingliInfo(oPlayer)
        if mLingli["lingli"] <= 0 then
            return false,"灵力不足，无法进攻"
        end
    end
    return true
end

function CHuodong:CanHelp(oPlayer,iTerraId,mData)
    local bEnough = self:CheckEnoughPartner(oPlayer,mData)
    if not bEnough then
        return false,"没有足够伙伴驻守据点，无法支援"
    end
    if not self:IsOnFight(iTerraId) then
        return false,"当前据点不需要支援"
    end
    if self:HasHelp(oPlayer.m_iPid,iTerraId) then
        return false,"一轮战斗只可支援一次"
    end
    local oTerra = self.m_mTerra[iTerraId]
    local iNowId = self:IsOnAttack(oPlayer) or self:IsOnHelp(oPlayer)
    if iNowId then
        local oNow = self.m_mTerra[iNowId]
        local sMsg = string.format("您目前正在%s排队，无法重复进行。",oNow:Name())
        return false,sMsg
    elseif self:GetTerraOwner(iTerraId) ~= oPlayer.m_iPid and self.m_mHelp[iTerraId] and (table_count(self.m_mHelp[iTerraId]) + (self.m_mHasHelp[iTerraId] and table_count(self.m_mHasHelp[iTerraId]) or 0)) >= MAX_HELP then
        return false,"当前据点支援人数达到上限"
    elseif self:GetTerraOwner(iTerraId) == oPlayer.m_iPid and self.m_mHelp[iTerraId] and (table_count(self.m_mHelp[iTerraId]) + (self.m_mHasHelp[iTerraId] and table_count(self.m_mHasHelp[iTerraId]) or 0)) >= (MAX_HELP+1) then
        return false,"当前据点支援人数达到上限"
    else
        local mLingli = self:GetLingliInfo(oPlayer)
        if mLingli["lingli"] <= 0 then
            return false,"灵力不足，无法支援"
        end
    end
    return true
end

function CHuodong:IsOnFight(iTerraId)
    if self.m_mCurFight[iTerraId] and table_count(self.m_mCurFight[iTerraId]) > 0  then
        return true
    else
        return false
    end
end

function CHuodong:AttackTerra(iPid,iTerraId,iNextCmd)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iOpenGrade = res["daobiao"]["global_control"]["terrawars"]["open_grade"]
    if oPlayer:GetGrade() < tonumber(iOpenGrade) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,string.format("%s级后开启据点攻防战",iOpenGrade))
        return
    end
    if oPlayer:HasTeam() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"请退出队伍后，进行操作")
        return
    end
    local oTerra = self.m_mTerra[iTerraId]
    if not oTerra then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    if oPlayer:GetOrgID() == 0 then
        oNotifyMgr:Notify(oPlayer.m_iPid,"请先加入公会")
        return
    end
    if self.m_mSetGuad[iTerraId] then
        oNotifyMgr:Notify(oPlayer.m_iPid,"领主正在设置驻守伙伴，请稍后再试")
        return
    end
    if self.m_mPlayerStatus[oPlayer.m_iPid] then

        oNotifyMgr:Notify(oPlayer.m_iPid,"您的据点正在自动设置驻守伙伴")
        return
    end
    if oPlayer:GetOrgID() == oTerra:GetOrgID() and oTerra:GetOrgID() ~= 0 then
        oNotifyMgr:Notify(oPlayer:GetPid(),"禁止进攻同一工会的据点")
        return
    end
    local iPid = oPlayer.m_iPid
    local fCallBack =  function(mData)
        local oWorldMgr = global.oWorldMgr
        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oP then
            self:AttackTerra2(oP,iTerraId,mData,iNextCmd)
        end
    end
    self:CheckCanAttack(oPlayer,fCallBack)
end

function CHuodong:FixBug()
    interactive.Send(".rank","rank","fixterra_reward",{})
end

function CHuodong:GetTerraState()
    local iStatus,iTime = self:GetStatus()
end

function CHuodong:AttackTerra2(oPlayer,iTerraId,mData,iNextCmd)
    local bCanAttack,sErrorMsg = self:CheckCanAttack2(oPlayer,iTerraId,mData)
    local oNotifyMgr = global.oNotifyMgr
    if not bCanAttack then
        oNotifyMgr:Notify(oPlayer.m_iPid, sErrorMsg)
        return
    end
    self:AddAttackList(oPlayer,iTerraId)
    oNotifyMgr:Notify(oPlayer.m_iPid,"已加入进攻队列")
    self:DoNextCmd(oPlayer,iTerraId,iNextCmd)
    if self.m_mAttack[iTerraId] and table_count(self.m_mAttack[iTerraId]) == 1 then
        self:CheckAttackList(iTerraId)
    end
end

function CHuodong:CheckAttackList(iTerraId)
    if not self:IsOnFight(iTerraId) then
        local iAttacker = self.m_mAttack[iTerraId][1]["pid"]
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(iAttacker,"即将对据点发起进攻，请做好准备")
        self:FightAttackWar(iTerraId,iAttacker)
    end
end

function CHuodong:RemoveFromAttackList(iPid,iTerraId)
    self:Dirty()
    self.m_mAttack[iTerraId] = self.m_mAttack[iTerraId]  or {}
    self.m_mHasAttack[iTerraId] = self.m_mHasAttack[iTerraId] or {}
    if self.m_mPid2Terra[iPid] then
        self.m_mPid2Terra[iPid] = nil
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CTerraQueueStatus",{status=0})
    end
    for iIdx,mInfo in pairs(self.m_mAttack[iTerraId]) do
        if mInfo.pid == iPid then
            self.m_mHasAttack[iTerraId] = self.m_mHasAttack[iTerraId] or {}
            self.m_mHasAttack[iTerraId][iPid] = table_deep_copy(mInfo)
            table.remove(self.m_mAttack[iTerraId],iIdx)
            return
        end
    end

end

function CHuodong:RemoveFromHelpList(iPid,iTerraId)
    self:Dirty()
    self.m_mHelp[iTerraId] = self.m_mHelp[iTerraId]  or {}
    self.m_mHasHelp[iTerraId] = self.m_mHasHelp[iTerraId] or {}
    self.m_mPid2Terra[iPid] = nil
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CTerraQueueStatus",{status=0})
    end
    for iIdx,mInfo in pairs(self.m_mHelp[iTerraId]) do
        if mInfo.pid == iPid then
            self.m_mHasHelp[iTerraId][iPid] = table_deep_copy(mInfo)
            table.remove(self.m_mHelp[iTerraId],iIdx)
            return
        end
    end
end

function CHuodong:AddAttackList(oPlayer,iTerraId)
    self:Dirty()
    self:BackUpPlayerInfo(oPlayer.m_iPid)
    self.m_mAttack[iTerraId] = self.m_mAttack[iTerraId]  or {}
    table.insert(self.m_mAttack[iTerraId],{pid = oPlayer.m_iPid,terra_id = iTerraId,name = oPlayer:GetName()})
    self.m_mPid2Terra[oPlayer.m_iPid] = {terra_id=iTerraId,attack=true}
    oPlayer:Send("GS2CTerraQueueStatus",{status=1})
    record.user("terrawars","add_attack",{pid = oPlayer.m_iPid,terraid = iTerraId})
    if table_count(self.m_mAttack[iTerraId]) == 1 and self:GetTerraOwner(iTerraId) ~= 0 then
        self:AskForHelp(iTerraId,oPlayer)
        self:RecordOrgLog(iTerraId,oPlayer,1,true)
    end
end

function CHuodong:HelpTerra(oPlayer,iTerraId,iNextCmd)
    local iOpenGrade = res["daobiao"]["global_control"]["terrawars"]["open_grade"]
    if oPlayer:GetGrade() < tonumber(iOpenGrade) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,string.format("%s级后开启据点攻防战",iOpenGrade))
        return
    end
    if oPlayer:HasTeam() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"请退出队伍后，进行操作")
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    if not self.m_mTerra[iTerraId] then
        return
    end
    if oPlayer:GetOrgID() == 0 then

        oNotifyMgr:Notify(oPlayer.m_iPid,"请先加入公会")
        return
    end
    if self.m_mPlayerStatus[oPlayer.m_iPid] then
        oNotifyMgr:Notify(oPlayer.m_iPid,"您的据点正在自动设置驻守伙伴")
        return
    end
    local iPid = oPlayer.m_iPid
    local fCallBack =  function(mData)
        local oWorldMgr = global.oWorldMgr
        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oP then
            self:HelpTerra2(oP,iTerraId,mData,iNextCmd)
        end
    end
    self:CheckCanAttack(oPlayer,fCallBack)
end

function CHuodong:HelpTerra2(oPlayer,iTerraId,mParInfo,iNextCmd)
    local oNotifyMgr = global.oNotifyMgr
    local bCanHelp,sErrorMsg = self:CanHelp(oPlayer,iTerraId,mParInfo)
    if not bCanHelp then
        oNotifyMgr:Notify(oPlayer.m_iPid, sErrorMsg)
        return
    end
    self:AddHelpList(oPlayer,iTerraId)
    oNotifyMgr:Notify(oPlayer.m_iPid, "成功加入支援队列")
    self:DoNextCmd(oPlayer,iTerraId,iNextCmd)
end

function CHuodong:AddHelpList(oPlayer,iTerraId)
    self:Dirty()
    self.m_mHelp[iTerraId] = self.m_mHelp[iTerraId]  or {}
    table.insert(self.m_mHelp[iTerraId],{pid = oPlayer.m_iPid,terra_id = iTerraId,name = oPlayer:GetName()})
    self.m_mPid2Terra[oPlayer.m_iPid] = {terra_id=iTerraId,help=true}
    oPlayer:Send("GS2CTerraQueueStatus",{status=1})
    record.user("terrawars","add_help",{pid = oPlayer.m_iPid,terraid=iTerraId})
end


function CHuodong:AttackSuccess(iPid,iTerraId)
    self:ClearWarInfo(iTerraId,iPid)
    local iOldOwner = self:GetTerraOwner(iTerraId)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if iOldOwner ~= 0 then
        self:UpdateOrgLog(iTerraId,1)
        self:RecordOrgLog(iTerraId,oPlayer,2)
        self:SendChangeOwnerMail(iTerraId,iOldOwner,iPid,"attack")
        self:ClearPlayerTerra(iOldOwner,iTerraId)
    end
    local oTerra = self.m_mTerra[iTerraId]
    if not oTerra then
        return
    end
    oTerra:SetTerraOwner(iPid)
    if self.m_mGuard[iTerraId] and self.m_mGuard[iTerraId].guard then
        self:Dirty()
        self.m_mGuard[iTerraId].guard = nil
    end
    local func = function()
        self:CheckPartnerSet(iPid,iTerraId)
    end
    local oWorldMgr = global.oWorldMgr
    self.m_mSetGuad[iTerraId] = iPid
    self.m_mPlayerStatus[iPid] = iTerraId
    self.m_mWarEnd[iTerraId] = get_time()
    if oPlayer then
        oPlayer:Send("GS2CSetGuard",{terraid = iTerraId,end_time = get_time()+30})
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(iPid,"战斗胜利，请派出>=3个伙伴驻守据点")
    end
    self:DelTimeCb("_CheckPartnerSet"..iTerraId)
    self:AddTimeCb("_CheckPartnerSet"..iTerraId,30*1000,func)
    record.user("terrawars","attack_success",{pid=iPid,terraid=iTerraId})
end

function CHuodong:SetTerraOwner(iPid,iTerraId)
    self:Dirty()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oTerra = self.m_mTerra[iTerraId]
    oTerra:SetTerraOwner(iPid,self.m_mGuard[iTerraId]["guard"]["player"]["owner_info"])
    local mNeighbour1 = oTerra:GetNeighbour()
    local mWhiteList = {}
    local mHasCheck = {}
    --检测和当前点可形成暴升区域的相邻点
    for _,id1 in pairs(mNeighbour1) do
        local oTerraTemp1 = self.m_mTerra[id1]
        if oTerraTemp1:GetOrgID() ~= 0 and oTerraTemp1:GetOrgID() ~= 0 and oTerraTemp1:GetOrgID() == oTerra:GetOrgID() then
            local mNeighbour2 = oTerraTemp1:GetNeighbour()
            for _,id2 in pairs(mNeighbour2) do
                if not mHasCheck[id2] then
                    local oTerraTemp2 = self.m_mTerra[id2]
                    if oTerraTemp2:GetOrgID() ~= 0 and oTerraTemp2:GetOrgID() == oTerra:GetOrgID() and oTerraTemp2:IsNeighbour(iTerraId) then
                        oTerraTemp2:SetUp(1)
                        oTerraTemp1:SetUp(1)
                        oTerra:SetUp(1)
                        mWhiteList[id1] = true
                        mWhiteList[id2] = true
                    end
                end
            end
            mHasCheck[id1] = true
        end
    end
    --检测和当前点不可形成暴升的相邻点
    for _,id in pairs(mNeighbour1) do
        if not mWhiteList[id] then
            local oTerraTemp = self.m_mTerra[id]
            if oTerraTemp:IsUp() and not self:CheckCanUp(id) then
                oTerraTemp:SetUp(0)
            end
        end
    end
end

function CHuodong:CheckCanUp(iTerraId)
    local oTerra = self.m_mTerra[iTerraId]
    local mNeighbour1 = oTerra:GetNeighbour()
    for _,id1 in pairs(mNeighbour1) do
        local oTerraTemp1 = self.m_mTerra[id1]
        if oTerraTemp1:GetOrgID() == oTerra:GetOrgID() then
            local mNeighbour2 = oTerraTemp1:GetNeighbour()
            for _,id2 in pairs(mNeighbour2) do
                local oTerraTemp2 = self.m_mTerra[id2]
                if oTerraTemp2:GetOrgID() == oTerra:GetOrgID() and oTerraTemp2:IsNeighbour(iTerraId) then
                    return true
                end
            end
        end
    end
    return false
end

function CHuodong:ClearPartnerMark(iTerraId)
    if not (self.m_mGuard[iTerraId] and self.m_mGuard[iTerraId]["guard"]) then
        return
    end

    local mPartner = {}
    for iParId,info in pairs(self.m_mGuard[iTerraId]["guard"]["partner"]) do
        mPartner[iParId] = 1
    end

    local iOwner = self.m_mGuard[iTerraId]["guard"]["player"].pid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iOwner)
    if not oPlayer then
        self:Dirty()
        self.m_mClearPartnerMark[iOwner] = mPartner
    else
        oPlayer.m_oPartnerCtrl:SyncGuardInfo(mPartner)
    end
end

--清空据点，用于处理据点坏数据
function CHuodong:ClearTerra(iTerraId)
    self:ClearAttackList(iTerraId)
    self:ClearHelpList(iTerraId)
    self:ClearWarInfo(iTerraId)
    self.m_mSetGuad[iTerraId] = nil
    local iPid = self:GetTerraOwner(iTerraId)
    if iPid and iPid ~= 0 then
        if self.m_mPlayerStatus[iPid] == iTerraId then
            self.m_mPlayerStatus[iPid] = nil
        end
        self:ClearPlayerTerra(iPid,iTerraId)
    end
    local oTerra = self.m_mTerra[iTerraId]
    if oTerra then
        oTerra:Clear()
    end
end

function CHuodong:CheckPartnerSet(iPid,iTerraId)
    self:Dirty()
    self:DelTimeCb("_CheckPartnerSet"..iTerraId)
    if self.m_bStart ~= 1 then
        return
    end
    local oTerra = self.m_mTerra[iTerraId]
    assert(oTerra,"CheckPartnerSet fail:not oTerra"..iTerraId)
    if oTerra:GetTerraOwner() ~= self:GetTerraOwner(iTerraId) then
        self:AutoSetGuardPartner(iPid,iTerraId)
    else
        return
    end
    oTerra:SetSaveTime()
    oTerra:SetTakeTime(get_time())
    self:ClearWarInfo(iTerraId,iPid)
end

function CHuodong:IsOnSetGuard(iPid)
    for _,pid in pairs(self.m_mSetGuad) do
        if pid == iPid then
            return true
        end
    end
    return false
end

function CHuodong:AutoSetGuardPartner(iPid,iTerraId)
    local oTerra = self.m_mTerra[iTerraId]
    local oWorldMgr = global.oWorldMgr
    if oTerra:GetTerraOwner(iTerraId) ~= iPid then
        return
    end
    self:SetGuardByBackUp(iPid,iTerraId)
    self:SetTerraOwner(iPid,iTerraId)
    self:ClearWarInfo(iTerraId,iPid)
    self:SetGuardSuccess(iTerraId,iPid)
end

function CHuodong:ClearWarInfo(iTerraId,iPid)
    self:Dirty()
    local oTerra = self.m_mTerra[iTerraId]
    if oTerra then
        oTerra:SetDefeated(0)
    end
    self:ClearAttackList(iTerraId)
    self:ClearHelpList(iTerraId)
    self.m_mHasAttack[iTerraId] = nil
    self.m_mHasHelp[iTerraId] = nil
    self.m_mCurFight[iTerraId] = nil
    self.m_mHelp[iTerraId] = nil
    self.m_mAttack[iTerraId] = nil
    if self.m_mSelfSave[iTerraId] then
        self.m_mSelfSave[iTerraId] = nil
    end
end

function CHuodong:ClearHelpList(iTerraId)
    if self.m_mHelp[iTerraId] then
        for index,info in pairs(self.m_mHelp[iTerraId]) do
            local iPid = info.pid
            if self.m_mPid2Terra[iPid] then
                self.m_mPid2Terra[iPid] = nil
                local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    oPlayer:Send("GS2CTerraQueueStatus",{status=0})
                end
            end
        end
    end
end

function CHuodong:ClearAttackList(iTerraId)
    if self.m_mAttack[iTerraId] then
        for index,info in pairs(self.m_mAttack[iTerraId]) do
            local iPid = info.pid
            if self.m_mPid2Terra[iPid] then
                self.m_mPid2Terra[iPid] = nil
                local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    oPlayer:Send("GS2CTerraQueueStatus",{status=0})
                end
            end
        end
    end
end

function CHuodong:GiveUpTerra(iPid,iTerraId,sReason,iNextCmd)
    local oTerra = self.m_mTerra[iTerraId]
    if oTerra:GetTerraOwner() ~= iPid then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    if self.m_mSetGuad[iTerraId] then
        global.oNotifyMgr:Notify(iPid,"正在自动设置驻守伙伴")
        return
    end
    if self.m_mAttack[iTerraId] and table_count(self.m_mAttack[iTerraId]) > 0 then
        global.oNotifyMgr:Notify(iPid,"本轮战斗结束前不可放弃据点")
        return
    end
    local sContent = string.format("确认召回驻守伙伴码？\n[FF0000]召回后15分钟内无法再次占领该据点")
    local mNet2 = {
        sContent = sContent,
        sConfirm = "确认",
        sCancle = "取消",
        default = 0,
        time = 30,
    }
    local oCbMgr = global.oCbMgr
    local mNet = oCbMgr:PackConfirmData(nil, mNet2)
    local func = function(oPlayer,mData)
        if mData.answer and mData.answer == 1 then
            local oHuodongMgr = global.oHuodongMgr
            local oHuodong = oHuodongMgr:GetHuodong("terrawars")
            oHuodong:TrueGiveUpTerra(iPid,iTerraId,sReason,iNextCmd)
        end
    end
    oCbMgr:SetCallBack(oPlayer.m_iPid,"GS2CConfirmUI",mNet,nil,func)
end

function CHuodong:TrueGiveUpTerra(iPid,iTerraId,sReason,iNextCmd)
    local oTerra = self.m_mTerra[iTerraId]
    local oNotifyMgr = global.oNotifyMgr
    if oTerra:GetTerraOwner() ~= iPid then
        oNotifyMgr:Notify(iPid,"据点状态已发生变化")
        return
    end
    if self:IsOnFight(iTerraId) then
        oNotifyMgr:Notify(iPid,"据点正在战斗中，无法放弃")
        return
    end
    if self.m_mSetGuad[iTerraId] then
        oNotifyMgr:Notify(iPid,"正在自动设置驻守伙伴")
        return
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    self:Dirty()
    local mBusyPartner = oPlayer.m_oActiveCtrl:GetData("terra_partner",{})
    local mGuard = self.m_mGuard[iTerraId]["guard"]
    local mTmp = {}
    for iParId,info in pairs(mGuard["partner"]) do
        mBusyPartner[iParId] = nil
        mTmp[iParId] = 0
    end
    oPlayer.m_oPartnerCtrl:SyncGuardInfo(mTmp)
    oPlayer.m_oActiveCtrl:SetData("terra_partner",mBusyPartner)
    self.m_mGuard[iTerraId] = nil
    oTerra:SetTerraOwner(0)
    oTerra:SetSaveTime()
    oPlayer:Send("GS2CGiveUpSuccess",{terraid=iTerraId})
    self:DoNextCmd(oPlayer,iTerraId,iNextCmd)
    record.user("terrawars","giveup_terra",{pid=iPid,terraid=iTerraId})
end

function CHuodong:GetCreateWarArg(mArg)
    mArg.remote_war_type = "terrawars"
    mArg.war_type = gamedefines.WAR_TYPE.TERRAWARS_TYPE
    return mArg
end

function CHuodong:BackUpPartnerInfo(iPid,mWarPtn,func)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local fCallBack = function(mData)
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        oHuodong:BackUpPartnerInfo2(iPid,mWarPtn,mData,func)
    end
    oPlayer.m_oPartnerCtrl:BackUpTerraWarsInfo(iPid,fCallBack)
end

function CHuodong:BackUpPlayerInfo(iPid)
    self:Dirty()
    self.m_mBackUp[iPid] = self.m_mBackUp[iPid] or {player = {}}
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    self.m_mBackUp[iPid]["player"] = oPlayer:PackWarInfo()
    self.m_mBackUp[iPid]["player"]["owner_info"] = {
        name = oPlayer:GetName(),
        orgid = oPlayer:GetOrgID(),
        orgname = oPlayer:GetOrgName(),
        sflag = oPlayer:GetOrgSFlag(),
    }
end

function CHuodong:BackUpPartnerInfo2(iPid,mWarPtn,mData,func)
    self:Dirty()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    self.m_mBackUp[iPid] = self.m_mBackUp[iPid] or {}
    self.m_mBackUp[iPid]["partner"] = self.m_mBackUp[iPid]["partner"] or {}
    local mBusyPartner = oPlayer.m_oActiveCtrl:GetData("terra_partner",{})
    if mWarPtn then
        for iParId,info in pairs(mWarPtn) do
            if not mBusyPartner[iParId] and mData[iParId] then
                self.m_mBackUp[iPid]["partner"][iParId] = info
            end
        end
    end
    local iCnt = 0
    if self.m_mBackUp[iPid] and self.m_mBackUp[iPid]["partner"] then
        iCnt = table_count(self.m_mBackUp[iPid]["partner"])
    end
    if iCnt < 3 then
        for iParId,info in pairs(mData) do
            if not mBusyPartner[iParId] and not (self.m_mBackUp[iPid] and self.m_mBackUp[iPid]["partner"] and self.m_mBackUp[iPid]["partner"][iParId]) then
                self.m_mBackUp[iPid]["partner"][iParId] = info
                iCnt = iCnt + 1
                if iCnt >= 3 then
                    break
                end
            end
        end
    end
    if func then
        func(self)
    end
end

function CHuodong:SetGuardByBackUp(iPid,iTerraId)
    self:Dirty()
    if not self.m_mBackUp[iPid] then
        return
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    self.m_mGuard[iTerraId] = {owner = iPid,guard=self.m_mBackUp[iPid]}
    if oPlayer then
        local mBusyPartner = oPlayer.m_oActiveCtrl:GetData("terra_partner",{})
        for iParId,info in pairs(self.m_mGuard[iTerraId]["guard"]["partner"]) do
            mBusyPartner[iParId] = iTerraId
        end
        oPlayer.m_oActiveCtrl:SetData("terra_partner",mBusyPartner)
    end
    self:SyncGuardInfo(iPid,iTerraId)
    self.m_mBackUp[iPid] = nil
end

function CHuodong:SetGuard(iPid,iTerraId,mPartner)
    local oNotifyMgr = global.oNotifyMgr
    if not self.m_mSetGuad[iTerraId] then
        oNotifyMgr:Notify(iPid,"已自动设置驻守伙伴")
        return
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mBusyPartner = oPlayer.m_oActiveCtrl:GetData("terra_partner",{})
    if table_count(mPartner) < 3 then
        oNotifyMgr:Notify(iPid,"驻守据点必须选择>=3名伙伴")
        return
    end
    for _,iParId in pairs(mPartner) do
        if mBusyPartner[iParId] then

            oNotifyMgr:Notify(iPid,"伙伴不可同时驻守多个据点，请重新选择伙伴")
            return
        end
    end
    local mPlayerWarInfo = oPlayer:PackWarInfo()
    local fCallBack = function(mPartnerWarInfo)
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        oHuodong:SetGuard2(iPid,iTerraId,mPartnerWarInfo,mPlayerWarInfo)
    end
    oPlayer.m_oPartnerCtrl:PackTerraWarInfo(mPartner,fCallBack)
end

function CHuodong:SetGuard2(iPid,iTerraId,mPartnerWarInfo,mPlayerWarInfo)
    self:Dirty()
    local mGuard = {player = mPlayerWarInfo,partner = mPartnerWarInfo}
    self.m_mGuard[iTerraId] = {owner = iPid,guard=mGuard}
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    self.m_mGuard[iTerraId]["guard"]["player"]["owner_info"] = {
        name = oPlayer:GetName(),
        orgid = oPlayer:GetOrgID(),
        orgname = oPlayer:GetOrgName(),
        sflag = oPlayer:GetOrgSFlag(),
    }
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mBusyPartner = oPlayer.m_oActiveCtrl:GetData("terra_partner",{})
    for iParId,info in pairs(mPartnerWarInfo) do
        mBusyPartner[iParId] = iTerraId
    end
    oPlayer.m_oActiveCtrl:SetData("terra_partner",mBusyPartner)
    self:SyncGuardInfo(iPid,iTerraId)
    self:SetTerraOwner(iPid,iTerraId)
    self:SetGuardSuccess(iTerraId,iPid)
end

function CHuodong:SetGuardSuccess(iTerraId,iPid)
    self:Dirty()
    self.m_mSetGuad[iTerraId] = nil
    if self.m_mBackUp[iPid] then
        self.m_mBackUp[iPid] = nil
    end
    local oTerra = self.m_mTerra[iTerraId]
    if self.m_mPlayerStatus[iPid] and self.m_mPlayerStatus[iPid] == iTerraId then
        self.m_mPlayerStatus[iPid] = nil
    end
    local mPartner = {}
    for iParId,info in pairs(self.m_mGuard[iTerraId]["guard"]["partner"]) do
        mPartner[iParId] = 1
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:SyncGuardInfo(mPartner)
    end
    local iPerPoints = oTerra:GetOccupyPoint()
    self.m_PersonalPoints[iPid] = (self.m_PersonalPoints[iPid] or 0) + iPerPoints
    self:AddPerContribution(iPid,iTerraId,iPerPoints)
    record.user("terrawars","set_guard",{pid=iPid,terraid=iTerraId,guard_info=ConvertTblToStr(mPartner)})
end

function CHuodong:PackPartnerNetInfo(iTerraId)
    if self.m_mGuard[iTerraId] and self.m_mGuard[iTerraId].guard and self.m_mGuard[iTerraId].guard.partner then
        local mPartner = {}
        for iParId,info in pairs(self.m_mGuard[iTerraId].guard.partner) do
            local mTemp = {
                    id = info.parid,
                    name = info.name,
                    star = info.star,
                    rare = info.rare,
                    model_info = info.model_info,
                    grade = info.grade,
                    awake = info.awake,
                    hp = info.terrawars_hp or info.hp,
                    max_hp = info.max_hp,
            }
            table.insert(mPartner,mTemp)
        end
        return mPartner
    else
        return {}
    end
end

function CHuodong:SyncGuardInfo(iPid,iTerraId)
    self:Dirty()
    local oTerra = self.m_mTerra[iTerraId]
    oTerra:SetSaveTime()
    oTerra:SetTakeTime(get_time())
    local mNet = self:PackPartnerNetInfo(iTerraId)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(iPid,"成功驻守该据点")
        oPlayer:Send("GS2CSetGuardSuccess",{terraid = iTerraId})
    end
end

function CHuodong:UpdateTerraWarsInfo(iPid,iParId,mInfo)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local mBusyPartner = oPlayer.m_oActiveCtrl:GetData("terra_partner",{})
        local iTerraId = mBusyPartner[iParId]
        if not iTerraId then
            return
        end
        if not self.m_mGuard[iTerraId] or not self.m_mGuard[iTerraId]["guard"] or not self.m_mGuard[iTerraId]["guard"]["partner"] then
            return
        end
        local mParInfo = self.m_mGuard[iTerraId]["guard"]["partner"]
        local mOld = mParInfo[iParId]
        if not mOld then
            return
        end
        local iCurHp = mOld.terrawars_hp or mOld.hp
        mInfo.terrawars_hp = iCurHp
        mParInfo[iParId] = mInfo
    end
end

function CHuodong:OpenMainUI(oPlayer)
    local iOrgId = oPlayer:GetOrgID()
    if not iOrgId then
        return
    end
    local iPerPoints = self:GetPersonalPoint(oPlayer)
    local iOrgPoints = self:GetOrgPoint(oPlayer)
    local iStatus,iTime = self:GetStatus()
    local iContribution = self:GetContribution(oPlayer)
    oPlayer:Send("GS2CTerraWarsMainUI",{personal_points=iPerPoints,org_points=iOrgPoints,time = iTime,contribution=iContribution,status = iStatus})
end

function CHuodong:GetPersonalPoint(oPlayer)
    return self.m_PersonalPoints[oPlayer.m_iPid] or 0
end

function CHuodong:GetOrgPoint(oPlayer)
    local iOrgId = oPlayer:GetOrgID()
    if not iOrgId then
        return 0
    end
    return self.m_OrgPoints[iOrgId] or 0
end

function CHuodong:GetContribution(oPlayer)
    return self.m_mContribution[oPlayer.m_iPid] or nil
end

function CHuodong:HasOccupyTerra(iPid)
    if self.m_bStart == 0 then
        return false
    end
    for iTerraId,oTerra in pairs(self.m_mTerra) do
        if self:GetTerraOwner(iTerraId) == iPid then
            return true
        end
    end
    return false
end

function CHuodong:ClearPlayerAllTerra(iPid)
    for iTerraId,pid in pairs(self.m_mSetGuad) do
        if pid == iPid then
            self.m_mSetGuad[iTerraId] = nil
        end
    end
    local iPlayerTerra = self.m_mPid2Terra[iPid]
    for iTerraId,oTerra in pairs(self.m_mTerra) do
        if self:GetTerraOwner(iTerraId) == iPid or iPlayerTerra == iTerraId then
            self:ClearPlayerTerra(iPid,iTerraId)
        end
    end
end

function CHuodong:ClearPlayerTerra(iPid,iTerraId)
    self:Dirty()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oTerra = self.m_mTerra[iTerraId]
    local mGuard = self.m_mGuard[iTerraId]["guard"]
    if oPlayer then
        local mBusyPartner = oPlayer.m_oActiveCtrl:GetData("terra_partner",{})
        local mTmp = {}
        for iParId,info in pairs(mGuard["partner"]) do
            mBusyPartner[iParId] = nil
            mTmp[iParId] = 0
        end
        oPlayer.m_oPartnerCtrl:SyncGuardInfo(mTmp)
        oPlayer.m_oActiveCtrl:SetData("terra_partner",mBusyPartner)
    else
        self.m_OfflineRemove[iPid] = self.m_OfflineRemove[iPid] or {}
        self.m_OfflineRemove[iPid][iTerraId] = self.m_OfflineRemove[iPid][iTerraId] or {}
        for iParId,info in pairs(mGuard["partner"]) do
            self.m_OfflineRemove[iPid][iTerraId][iParId] = true
        end
    end
    self.m_mGuard[iTerraId] = nil
    oTerra:SetTerraOwner(0)
    oTerra:SetSaveTime()
end

function CHuodong:LeaveOrg(iPid,iOldOrgId)
    self:Dirty()
    if self:HasOccupyTerra(iPid) then
        self:ClearPlayerAllTerra(iPid)
    end
    if self.m_mPid2Terra[iPid] then
        self:LeaveQueue(iPid,nil,true)
    end
    if self.m_PersonalPoints[iPid] then
        self.m_PersonalPoints[iPid] = nil
    end
end

function CHuodong:GetMapInfo(oPlayer,iMapId)
    local mNet = self:GetTerraInfo(oPlayer,iMapId)
    oPlayer:Send("GS2CTerrawarMapInfo",{map_id = iMapId,terrainfo = mNet})
end

function CHuodong:GetTerraInfo(oPlayer,iMapId,iID)
    local mNet = {}
    for iTerraId,oTerra in pairs(self.m_mTerra) do
        local iMap = oTerra:GetMapId()
        if (iMapId and (iMap == iMapId)) or (iID and (iTerraId == iID))then
            local mTerraInfo = oTerra:PackNetInfo()
            if self:GetTerraOwner(iTerraId) ~= 0 then
                if self:IsOnFight(iTerraId) then
                    mTerraInfo.status = 1
                else
                    mTerraInfo.status = 3
                end
            end
            if oTerra:IsOnSave() then
                mTerraInfo.status = 2
            end
            local iAttack = 0
            local iHelp = 0
            if self.m_mAttack[iTerraId] then
                iAttack = table_count(self.m_mAttack[iTerraId])
            end
            if self.m_mHasAttack[iTerraId] then
                iAttack = iAttack + table_count(self.m_mHasAttack[iTerraId])
            end
            if self.m_mHelp[iTerraId] then
                iHelp = table_count(self.m_mHelp[iTerraId])
            end
            if self.m_mHasHelp[iTerraId] then
                iHelp = iHelp+table_count(self.m_mHasHelp[iTerraId])
            end
            mTerraInfo.attack = iAttack
            mTerraInfo.help = iHelp
            mTerraInfo.max_attack = MAX_ATTACK
            mTerraInfo.max_help = MAX_HELP
            mTerraInfo.partner_info = self:PackPartnerNetInfo(iTerraId)
            if (iID and (iTerraId == iID)) then
                return mTerraInfo
            end
            table.insert(mNet,mTerraInfo)
        end
    end
    return mNet
end

function CHuodong:ChangeOwner(iOldOwner,iNewOwner)
    self:Dirty()
    --self.m_PersonalPoints[iOldOwner] = 0
end

function CHuodong:AddPerPoints(iPid,iTerraId,iNum)
    self:Dirty()
    local oTerra = self.m_mTerra[iTerraId]
    self.m_PersonalPoints[iPid] = (self.m_PersonalPoints[iPid] or 0) + iNum
    self:UpdatePerRank(iPid,{personal_points = self.m_PersonalPoints[iPid],orgid = oTerra:GetOrgID()})
    record.user("terrawars","addperpoints",{pid=iPid,terraid=iTerraId,amount=iNum})
end

function CHuodong:AddPerContribution(iPid,iTerraId,iNum,bNotTips)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    ----TODO,-回头这里要删掉，冗余代码，临时处理
    if not self.m_mContribution then
        self.m_mContribution ={}
    end
    --------------
    self.m_mContribution[iPid] =  (self.m_mContribution[iPid] or 0) + iNum
    if oPlayer then
        oPlayer:RewardOrgOffer(iNum,"据点战奖励",{cancel_tip = bNotTips,cancel_channel = bNotTips,cancel_show = 1})
    else
        self:AddOfflineContribution(iPid,iNum)
    end
    record.user("terrawars","addpercontribution",{pid=iPid,terraid=iTerraId,amount=iNum})

    if oPlayer then
        oPlayer:LogAnalyGame({},"terrawars",nil,{[gamedefines.COIN_FLAG.COIN_ORG_OFFER]=iNum})
    else
        local oWorldMgr = global.oWorldMgr
        oWorldMgr:LoadProfile(iPid, function (oProfile)
            if not oProfile then
                return
            end
            oProfile:LogAnalyGame({},"terrawars",nil,{[gamedefines.COIN_FLAG.COIN_ORG_OFFER]=iNum})
        end)
    end
end

function CHuodong:RecoverHp(iTerraId)
    if not self.m_mTerra[iTerraId] then
        return
    end
    if not self.m_mGuard[iTerraId] then
        return
    end
    if self:IsOnFight(iTerraId) then
        return
    end
    self:Dirty()
    local oTerra = self.m_mTerra[iTerraId]
    local iUpRate = 0
    if oTerra:IsUp() then
        iUpRate = oTerra:GetUpRate()/100
    end
    local mParInfo = self.m_mGuard[iTerraId]["guard"]["partner"]
    for iParId,info in pairs(mParInfo) do
        local iCurHp = info.terrawars_hp or info.hp
        local iMaxHp = info.max_hp
        if iMaxHp ~= iCurHp then
            iCurHp = math.min(iMaxHp*(0.03+iUpRate)+iCurHp,iMaxHp)
            info.terrawars_hp = iCurHp
        end
    end
    local mPlayerInfo = self.m_mGuard[iTerraId]["guard"]["player"]
    local iCurHp = mPlayerInfo.hp
    local iMaxHp = mPlayerInfo.max_hp
    if iCurHp ~= iMaxHp then
        iCurHp = math.min(iMaxHp*0.03+iCurHp,iMaxHp)
        mPlayerInfo.hp = iCurHp
    end
end

function CHuodong:AddOrgPoints(iPid,iOrgId,iTerraId,iNum)
    self:Dirty()
    self.m_OrgPoints[iOrgId] = (self.m_OrgPoints[iOrgId] or 0) + iNum
    self:UpdateServerRank(iOrgId,{org_points = self.m_OrgPoints[iOrgId],orgid = iOrgId})
    record.user("terrawars","addorgpoints",{pid=iPid,orgid=iOrgId,terraid=iTerraId,amount=iNum})
end

function CHuodong:AddOfflineContribution(iPid,iNum)
    self:Dirty()
    self.m_OfflineContribution[iPid] = (self.m_OfflineContribution[iPid] or 0) + iNum
end

function CHuodong:CheckOfflineContribution(oPlayer)
    if self.m_OfflineContribution[oPlayer.m_iPid] then
        self:Dirty()
        oPlayer:RewardOrgOffer(self.m_OfflineContribution[oPlayer.m_iPid],"据点战奖励",{cancel_tip = bNotTips,cancel_channel = bNotTips,cancel_show = 1})
        self.m_OfflineContribution[oPlayer.m_iPid] = nil
    end
end

function CHuodong:GetMyTerraInfo(oPlayer,iID)
    local mNet = {}
    for iTerraId,oTerra in pairs(self.m_mTerra) do
        if ((iID and oTerra:GetID() == iID) or not iID) and oTerra:GetOrgID() == oPlayer:GetOrgID() then
            local mInfo1 = oTerra:PackNetInfo()
            if self:IsOnFight(iTerraId) then
                mInfo1.status = 1
            elseif oTerra:IsOnSave() then
                mInfo1.status = 2
            else
                mInfo1.status = 3
            end
            local mInfo2 = oTerra:PackPersonalInfo()
            table_combine(mInfo1,mInfo2)
            local mParInfo = self:PackPartnerNetInfo(iTerraId)
            mInfo1["partner_info"] = mParInfo
            table.insert(mNet,mInfo1)
        end
    end
    oPlayer:Send("GS2CMyTerraInfo",{terrainfo = mNet})
end

function CHuodong:AutoFightAttackWar(iTerraId,iAttacker)
    local oTerra = self.m_mTerra[iTerraId]
    if not oTerra then
        return
    end
    local iDefender = oTerra:GetTerraOwner()
    local mGuard = self.m_mGuard[iTerraId]["guard"]
    if not mGuard then
        self:AttackSuccess(iAttacker,iTerraId)
    end
    local mRomPlayer =  self:GetGuardPlayerForWar(iTerraId)
    local mParInfo = self:GetGuardPartnerForWar(iTerraId)
    local mRomPartner = {}
    for _,oPartner in pairs(mParInfo) do
        table.insert(mRomPartner,oPartner:PackTerraWarInfo())
    end
    local oWar = self:CreateRomWar(iAttacker,nil,mRomPlayer,mRomPartner,{war_config=1,remote_war_type="terrawars",enter_arg={camp_id=2,rom_camp_id=1},war_type=gamedefines.WAR_TYPE.TERRAWARS_TYPE})
    oWar:SetData("defender",iDefender)
    oWar:SetData("attacker",iAttacker)
    oWar:SetData("terra_id",iTerraId)
    local iWarID = oWar:GetWarId()
    self.m_mCurFight[iTerraId] = self.m_mCurFight[iTerraId] or {}
    self.m_mCurFight[iTerraId]["warid"] = iWarID
    self.m_mCurFight[iTerraId]["attacker"] = iAttacker
    self.m_mCurFight[iTerraId]["defender"] = iDefender
end

function CHuodong:CheckHasHelp(iTerraId)
    local oTerra = self.m_mTerra[iTerraId]
    if not oTerra then
        return false
    end
    local iOwner = self:GetTerraOwner(iTerraId)
    local iHelpNum = table_count(self.m_mHelp[iTerraId] or {})
    local iHasHelpNum = table_count(self.m_mHasHelp[iTerraId] or {})
    local iTotalNum = iHelpNum+iHasHelpNum
    if iHelpNum == 0 then
        return false
    elseif iHelpNum == 1 then
        if self.m_mHasHelp[iTerraId] and self.m_mHelp[iTerraId] and self.m_mHasHelp[iTerraId][self.m_mHelp[iTerraId][1].pid] then
            return false
        end
    end
    return true
end

function CHuodong:WarFightEnd(oWar,iPid,oNpc,mArgs)
    super(CHuodong).WarFightEnd(self,oWar,iPid,oNpc,mArgs)
    if self.m_bStart == 0 then
        return
    end
    local iWinSide = mArgs.win_side
    local iTerraId = oWar:GetData("terra_id",0)
    local oTerra = self.m_mTerra[iTerraId]
    local iAttacker = oWar:GetData("attacker",0)
    local iDefender = oWar:GetData("defender",0)
    if iWinSide == 1 then
        self:AttackWarFailed(iTerraId,iAttacker,iDefender)
    elseif iWinSide == 2 then
        self:DefendFailed(iTerraId,iAttacker,iDefender)
    end
end

function CHuodong:AttackWarFailed(iTerraId,iAttacker,iDefender)
    self:Dirty()
    local iAttackPoint = self:GetAttackPoint(iTerraId)
    self:AddPerPoints(iAttacker,iTerraId,iAttackPoint)
    self:AddPerContribution(iAttacker,iTerraId,iAttackPoint)
    self:RemoveFromAttackList(iAttacker,iTerraId)
    self.m_mBackUp[iAttacker] = nil
    self:ContinueCheckAttack(iTerraId,iDefender,iAttacker)
    record.user("terrawars","attack_fail",{pid=iAttacker,terraid=iTerraId})
end

function CHuodong:DefendFailed(iTerraId,iAttacker,iDefender)
    self:Dirty()
    record.user("terrawars","defend_fail",{pid=iDefender,terraid=iTerraId})
    local iAttackPoint = self:GetAttackPoint(iTerraId)
    self:AddPerPoints(iDefender,iTerraId,iAttackPoint)
    self:AddPerContribution(iDefender,iTerraId,iAttackPoint)
    if iDefender and iDefender~= 0 then
        local iOwner = self:GetTerraOwner(iTerraId)
        if (iDefender == iOwner and not self:IsGuardAlive(iTerraId)) or iDefender ~= iOwner then
            self.m_mBackUp[iDefender] = nil
            self:RemoveFromHelpList(iDefender,iTerraId)
        end
    end
    local oTerra = self.m_mTerra[iTerraId]
    oTerra:SetDefeated(1)
    local bHasHelp = self:CheckHasHelp(iTerraId)
    if not bHasHelp then
        local func1 = function( ... )
            local oHuodongMgr = global.oHuodongMgr
            local oHuodong = oHuodongMgr:GetHuodong("terrawars")
            oHuodong:ContinueCheckHelp(iTerraId,iAttacker)
            oHuodong:SetPrepare(iAttacker,iTerraId)
        end
        self:SetPrepare(iAttacker,iTerraId,true)
        self:OnWaiting(iTerraId,func1,30)
        local oAttacker = global.oWorldMgr:GetOnlinePlayerByPid(iAttacker)
        if oAttacker then
            oAttacker:Send("GS2CTerrawarsCountDown",{endtime = get_time() + 29,type = 2})
        end
    else
        self:ContinueCheckHelp(iTerraId,iAttacker)
    end
end

function CHuodong:OnWaiting(iTerraId,fFunc,iSecond)
    self:DelTimeCb("Waiting"..iTerraId)
    self:AddTimeCb("Waiting"..iTerraId,(iSecond or 30)*1000,fFunc)
end

function CHuodong:DefendSuccess(iTerraId,iDefender)
    self:Dirty()
    local oNotifyMgr = global.oNotifyMgr
    local iOldOwner = self:GetTerraOwner(iTerraId)
    if iDefender ~= iOldOwner then
        self:SendChangeOwnerMail(iTerraId,iOldOwner,iDefender,"defend")
        self:ClearPlayerTerra(iOldOwner,iTerraId)
    end
    self:ClearWarInfo(iTerraId,iDefender)
    local oTerra = self.m_mTerra[iTerraId]
    if not oTerra then
        return
    end
    if oTerra:GetTerraOwner() == iDefender then
        oNotifyMgr:Notify(iDefender,"据点防守成功")
        oTerra:SetSaveTime()
        self:UpdateOrgLog(iTerraId,1)
        self:RecordOrgLog(iTerraId,nil,4)
        return
    end
    oTerra:SetTerraOwner(iDefender)
    local func = function()
        self:CheckPartnerSet(iDefender,iTerraId)
    end
    local oWorldMgr = global.oWorldMgr
    self.m_mSetGuad[iTerraId] = iDefender
    self.m_mPlayerStatus[iDefender] = iTerraId
    self.m_mWarEnd[iTerraId] = get_time()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iDefender)
    if oPlayer then
        oPlayer:Send("GS2CSetGuard",{terraid = iTerraId,end_time = get_time()+30})

        oNotifyMgr:Notify(iDefender,"援助据点成功，请派出伙伴驻守据点")
        self:UpdateOrgLog(iTerraId,1)
        self:RecordOrgLog(iTerraId,oPlayer,3)
    end
    self:DelTimeCb("_CheckPartnerSet"..iTerraId)
    self:AddTimeCb("_CheckPartnerSet"..iTerraId,30*1000,func)
    record.user("terrawars","defend_success",{pid=iDefender,terraid=iTerraId})

end

function CHuodong:ContinueCheckAttack(iTerraId,iDefender,iAttacker)
    if not self.m_mAttack[iTerraId] or (self.m_mAttack[iTerraId] and table_count(self.m_mAttack[iTerraId]) <= 0) then
        self:DefendSuccess(iTerraId,iDefender)
        return
    end
    local iNextAttacker = self.m_mAttack[iTerraId][1].pid
    local func = function()
        local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
        oHuodong:SetTerraWarCountDown(iNextAttacker,iDefender)
        if not oHuodong.m_mAttack[iTerraId] or (oHuodong.m_mAttack[iTerraId] and table_count(oHuodong.m_mAttack[iTerraId]) <= 0) then
            oHuodong:DefendSuccess(iTerraId,iDefender)
            return
        end
        oHuodong:FightAttackWar(iTerraId,iNextAttacker)
    end
    self:DelTimeCb("WarCountDown"..iTerraId)
    self:AddTimeCb("WarCountDown"..iTerraId,30*1000,func)


    self:SetTerraWarCountDown(iNextAttacker,iDefender,true)
end

function CHuodong:SetTerraWarCountDown(iAttacker,iDefender,bSet)
    if bSet then
        local oDefenders = global.oWorldMgr:GetOnlinePlayerByPid(iDefender)
        if oDefenders then
            global.oNotifyMgr:Notify(iDefender,"下轮据点战斗将在30秒后开始，请做好准备")
            oDefenders:Send("GS2CTerrawarsCountDown",{endtime = get_time() + 29,type = 1})
        end
        local oAttacker = global.oWorldMgr:GetOnlinePlayerByPid(iAttacker)
        if oAttacker then
            global.oNotifyMgr:Notify(iAttacker,"下轮据点战斗将在30秒后开始，请做好准备")
            oAttacker:Send("GS2CTerrawarsCountDown",{endtime = get_time() + 29,type = 1})
        end
    end
    self.m_WarCountDown[iAttacker] = bSet
    self.m_WarCountDown[iDefender] = bSet
end

function CHuodong:ContinueCheckHelp(iTerraId,iAttacker)
    if not self.m_mHelp[iTerraId] or (self.m_mHelp[iTerraId] and table_count(self.m_mHelp[iTerraId]) <= 0) then
        self:AttackSuccess(iAttacker,iTerraId)
        return
    end
    local iDefender = self.m_mHelp[iTerraId][1].pid
    local func = function()
        local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
        oHuodong:SetTerraWarCountDown(iAttacker,iDefender)
        if not oHuodong.m_mHelp[iTerraId] or (oHuodong.m_mHelp[iTerraId] and table_count(oHuodong.m_mHelp[iTerraId]) <= 0) then
            oHuodong:AttackSuccess(iAttacker,iTerraId)
            return
        end
        oHuodong:FightAttackWar(iTerraId,iAttacker)
    end
    self:DelTimeCb("WarCountDown"..iTerraId)
    self:AddTimeCb("WarCountDown"..iTerraId,30*1000,func)

    self:SetTerraWarCountDown(iAttacker,iDefender,true)
end

function CHuodong:FightAttackWar(iTerraId,iAttacker)
    local oAttacker = global.oWorldMgr:GetOnlinePlayerByPid(iAttacker)
    local iDefender = self:GetTerraOwner(iTerraId)
    if (self.m_mSelfSave[iTerraId] and self.m_mSelfSave[iTerraId][iDefender]) or not self:IsGuardAlive(iTerraId) then
        iDefender = self.m_mHelp[iTerraId][1].pid
    end
    local func = function()
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        oHuodong:ContinueFightAttackWar1(iTerraId,iAttacker,iDefender)
    end
    if oAttacker then
        self:BackUpPlayerInfo(iAttacker)
        self:BackUpPartnerInfo(iAttacker,nil,func)
    else
        self:AttackWarFailed(iTerraId,iAttacker)
    end
end

function CHuodong:ContinueFightAttackWar1(iTerraId,iAttacker,iDefender)
    if iDefender == 0 or iDefender == self:GetTerraOwner(iTerraId) then  ---空据点和据点领主无需备份防守方伙伴数据
        self:ContinueFightAttackWar2(iTerraId,iAttacker,iDefender)
        return
    end
    local oDefenders = global.oWorldMgr:GetOnlinePlayerByPid(iDefender)
    local func = function ()
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        oHuodong:ContinueFightAttackWar2(iTerraId,iAttacker,iDefender)
    end
    if oDefenders then
        self:BackUpPlayerInfo(iDefender)
        self:BackUpPartnerInfo(iDefender,nil,func)
    else
        self:DefendFailed(iTerraId,iAttacker,iDefender)
    end
end

function CHuodong:ContinueFightAttackWar2(iTerraId,iAttacker,iDefender)
    local oWorldMgr = global.oWorldMgr
    local oTerra = self.m_mTerra[iTerraId]
    if not oTerra then
        return
    end
    local oAttacker = oWorldMgr:GetOnlinePlayerByPid(iAttacker)
    if not oAttacker then
        self:AttackWarFailed(iTerraId,iAttacker,iDefender)
        return
    end
    local mLingli = self:GetLingliInfo(oAttacker)
    local iLingli = mLingli["lingli"]
    if iLingli <= 0 then
        self:AttackWarFailed(iTerraId,iAttacker,iDefender)
        return
    end
    self:UseLingli(oAttacker)

    local iDefender = oTerra:GetTerraOwner()
    if iDefender == 0 then
        self:AttackSuccess(iAttacker,iTerraId)
        return
    end
    if self:IsGuardAlive(iTerraId) then
        self:FightAttackWar1(iTerraId,iAttacker,iDefender)
        return
    end
    if (self.m_mSelfSave[iTerraId] and self.m_mSelfSave[iTerraId][iDefender]) or not self:IsGuardAlive(iTerraId) then
        iDefender = self.m_mHelp[iTerraId][1].pid
        if self.m_mHasHelp[iTerraId]  and self.m_mHasHelp[iTerraId][iDefender] then
            self:AttackSuccess(iAttacker,iTerraId)
            return
        end
    end
    if not self.m_mHasHelp[iTerraId] or (self.m_mHasHelp[iTerraId]  and not self.m_mHasHelp[iTerraId][iDefender]) then
        self:FightAttackWar3(iTerraId,iAttacker,iDefender)
    else
        self:AttackSuccess(iAttacker,iTerraId)
        return
    end
end

function CHuodong:SetPrepare(iPid,iTerraId,iStatus)
    if not self.m_PrepareList[iPid] then
        self.m_PrepareList[iPid] = {}
    end
    self.m_PrepareList[iPid][iTerraId] = iStatus
end

function CHuodong:IsPrepare(iPid)
    if self.m_bStart ~= 1 then
        return false
    end
    if (not self.m_PrepareList[iPid]) or table_count(self.m_PrepareList[iPid]) == 0 then
        return false
    end
    return true
end

function CHuodong:PackReadyInfo(iTerraId,iPid)
    if iPid == self:GetTerraOwner(iTerraId) then
        return self:_PackReadyInfo1(iTerraId,iPid)
    else
        return self:_PackReadyInfo2(iTerraId,iPid)
    end
end

function CHuodong:_PackReadyInfo1(iTerraId,iPid)
    local m = {}
    local mBackUp = self.m_mGuard[iTerraId]["guard"]["player"]
    m.pid = iPid
    m.name = mBackUp.name
    m.shape = mBackUp.model_info.shape
    return m
end

function CHuodong:_PackReadyInfo2(iTerraId,iPid)
    local m = {}
    local mBackUp = self.m_mBackUp[iPid]["player"]
    m.pid = iPid
    m.name = mBackUp.name
    m.shape = mBackUp.model_info.shape
    return m
end

function CHuodong:UpdateReadyInfo(m,iPid,iChoice,iEndTime)
    for _,info in pairs(m) do
        if info.pid == iPid then
            info.status = iChoice
            break
        end
    end
    for _,info in pairs(m) do
        if info.status and info.status == 2 then
            local pid = info.pid
            local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
            oPlayer:Send("GS2CTerraReadyInfo",{ready=m,end_time = iEndTime})
        end
    end
end

function CHuodong:CheckChoice1(iTerraId,iAttacker,iDefender,mChoice)
    if mChoice and (mChoice[iAttacker] and mChoice[iAttacker] == 0 or not mChoice[iAttacker])then
        self:AttackWarFailed(iTerraId,iAttacker,iDefender)
        return
    end
    local oAttacker = global.oWorldMgr:GetOnlinePlayerByPid(iAttacker)
    if not oAttacker or oAttacker:GetNowWar() then
        self:AttackWarFailed(iTerraId,iAttacker,iDefender)
        return
    end
    if mChoice and ((mChoice[iDefender] and mChoice[iDefender] == 0) or not mChoice[iDefender]) then
        self:AutoFightAttackWar(iTerraId,iAttacker)
        return
    end
    local oDefender = global.oWorldMgr:GetOnlinePlayerByPid(iDefender)
    if not oDefender or oDefender:GetNowWar() then
        self:AutoFightAttackWar(iTerraId,iAttacker)
        return
    end
end

function CHuodong:FightAttackWar1(iTerraId,iAttacker,iDefen)
    local oWorldMgr = global.oWorldMgr
    local oTerra = self.m_mTerra[iTerraId]
    local iDefender = iDefen or oTerra:GetTerraOwner()
    local mReady = {}
    table.insert(mReady,self:PackReadyInfo(iTerraId,iAttacker))
    table.insert(mReady,self:PackReadyInfo(iTerraId,iDefender))
    local iEndTime = get_time() + 30
    local oAttacker = global.oWorldMgr:GetOnlinePlayerByPid(iAttacker)
    local oDefenders = oWorldMgr:GetOnlinePlayerByPid(iDefender)
    if not oAttacker then
        oHuodong:AttackWarFailed(iTerraId,iAttacker,iDefender)
        return
    end
    local mChoice = {}
    local fCallBack = function()
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        oHuodong:DelTimeCb("HelpCountDown"..iTerraId)
        oHuodong:SetPrepare(iAttacker,iTerraId)
        oHuodong:SetPrepare(iDefender,iTerraId)
        oHuodong:CheckChoice1(iTerraId,iAttacker,iDefender,mChoice)
    end
    self:AddTimeCb("HelpCountDown"..iTerraId,31*1000,fCallBack)


    self:SetPrepare(iDefender,iTerraId,true)
    self:SetPrepare(iAttacker,iTerraId,true)
    if oDefenders and oDefenders:GetNowWar() then
        local oNotifyMgr = global.oNotifyMgr
        local sContent = string.format("您的[%s]正在被攻击，请快去支援!",oTerra:Name())
        oNotifyMgr:SendSelf(oDefenders,sContent, 0, 1)
    end
    local iAnswer = 2
    if oAttacker:GetNowWar() or not oDefenders then
        iAnswer = 1
    end

    local sContent = string.format("据点正受到攻击，是否回去支援？")
    if oDefenders and oDefenders:HasTeam() then
        sContent = sContent.."\n确认将强制退出队伍"
    end
    local mNet2 = {
        sContent = sContent,
        sConfirm = "确认",
        sCancle = "取消",
        default = 0,
        time = 30,
    }
    local iAttackSession,iDefendSession
    local oCbMgr = global.oCbMgr
    local mNet = oCbMgr:PackConfirmData(nil, mNet2)
    local func = function(oPlayer,mData)
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        if not (oHuodong.m_PrepareList[oPlayer.m_iPid] and oHuodong.m_PrepareList[oPlayer.m_iPid][iTerraId]) then
            return
        end
        if mChoice[iAttacker] and mChoice[iAttacker] == 0 then
            global.oNotifyMgr:Notify(oPlayer.m_iPid,"对方已放弃本轮进攻")
            return
        end
        local iChoice = mData.answer
        oHuodong:UpdateReadyInfo(mReady,oPlayer.m_iPid,iChoice == 0 and 1 or 2,iEndTime)
        mChoice[oPlayer.m_iPid] = iChoice
        if iChoice and iChoice == 1 then
            if oPlayer:HasTeam() then
                local oTeam = oPlayer:HasTeam()
                local iTeamID = oPlayer:TeamID()
                oTeam:Leave(oPlayer.m_iPid)
                global.oTeamMgr:OnLeaveTeam(iTeamID,oPlayer.m_iPid)
            end
        else
            if oPlayer.m_iPid == iAttacker then
                oHuodong:DelTimeCb("HelpCountDown"..iTerraId)
                global.oNotifyMgr:Notify(iAttacker,"您已放弃本轮进攻")
                oHuodong:AttackWarFailed(iTerraId,iAttacker,iDefender)
                local oDefender = global.oWorldMgr:GetOnlinePlayerByPid(iDefender)
                if oDefender and iDefendSession then
                    oDefender:Send("GS2CCloseConfirmUI",{sessionidx=iDefendSession})
                end
                self:SetPrepare(iAttacker,iTerraId)
                self:SetPrepare(iDefender,iTerraId)
                return
            end
        end
        if table_count(mChoice) == iAnswer and iAnswer == 2 then
            oHuodong:DelTimeCb("HelpCountDown"..iTerraId)
            self:SetPrepare(iAttacker,iTerraId)
            self:SetPrepare(iDefender,iTerraId)
            local oAttacker = global.oWorldMgr:GetOnlinePlayerByPid(iAttacker)
            if oAttacker:GetNowWar() then
                oHuodong:AttackWarFailed(iTerraId,iAttacker,iDefender)
                return
            end
            if mChoice[iDefender] == 0 and mChoice[iAttacker] == 1 then
                oHuodong:AutoFightAttackWar(iTerraId,iAttacker)
            elseif mChoice[iDefender] == 1 and mChoice[iAttacker] == 1 then
                oHuodong:FightAttackWar2(iTerraId,iAttacker)
            end
        else
            global.oNotifyMgr:Notify(oPlayer.m_iPid,"等待对方确认")
        end
    end
    if oDefenders and not oDefenders:GetNowWar() then
        iDefendSession = oCbMgr:SetCallBack(iDefender,"GS2CConfirmUI",mNet,nil,func)
    end
    if oAttacker:GetNowWar() then
        local sContent = "本轮进攻方为您，请快去支援!"
        global.oNotifyMgr:SendSelf(oAttacker,sContent, 0, 1)
    else
        mNet = oCbMgr:PackConfirmData(nil, mNet2)
        mNet.sContent = "本轮进攻方为您，是否出战？"..(oAttacker:HasTeam() and "\n确认将自动离队" or "")
        iAttackSession = oCbMgr:SetCallBack(iAttacker,"GS2CConfirmUI",mNet,nil,func)
    end
end

function CHuodong:FightAttackWar2(iTerraId,iAttacker)
    local oTerra = self.m_mTerra[iTerraId]
    local iDefender = oTerra:GetTerraOwner()
    local oWorldMgr = global.oWorldMgr
    local oDefenders = oWorldMgr:GetOnlinePlayerByPid(iDefender)
    local oAttacker = oWorldMgr:GetOnlinePlayerByPid(iAttacker)
    self:DelTimeCb("HelpCountDown"..iTerraId)
    local mGuard = self.m_mGuard[iTerraId]["guard"]
    if not mGuard then
        self:AttackSuccess(iAttacker,iTerraId)
    end
    local mGuardPartner = self:GetGuardPartnerForWar(iTerraId)

    local mArg = {
        remote_war_type="terrawars",
        war_type = gamedefines.WAR_TYPE.TERRAWARS_TYPE,
        remote_args = { war_record = 1,defender = iDefender,auto = 0},
        pvpflag = 1,
    }
    local oWar = self:CreateWar(mArg)
    oWar:SetData("close_auto_skill",true)
    oWar:SetData("defender",iDefender)
    oWar:SetData("attacker",iAttacker)
    oWar:SetData("terra_id",iTerraId)
    local iWarID = oWar:GetWarId()
    self.m_mCurFight[iTerraId] = self.m_mCurFight[iTerraId] or {}
    self.m_mCurFight[iTerraId]["warid"] = iWarID
    self.m_mCurFight[iTerraId]["attacker"] = iAttacker
    self.m_mCurFight[iTerraId]["defender"] = iDefender
    local mArg = {camp_id = 1,
    FightPartner = mGuardPartner,
    CurrentPartner = mGuardPartner[1],
    }
    local oWarMgr = global.oWarMgr
    oWarMgr:EnterWar(oDefenders, iWarID, mArg, true)

    mArg = {camp_id=2}
    oWarMgr:EnterWar(oAttacker, iWarID, mArg, true)
    oWarMgr:SetWarEndCallback(oWar:GetWarId(),function (mArgs)
        local oWar = oWarMgr:GetWar(iWarID)
        self:OnTerraWarEnd(oWar,iTerraId,iAttacker,mArgs)
        end)
    oWarMgr:StartWarConfig(oWar:GetWarId(),{terrawars_defender = iDefender})
    oWar:AddTerraWarsDefenderCmd(iDefender)
end

function CHuodong:CheckChoice2(iTerraId,iDefender,iAttacker,mChoice)
    local oDefenders = global.oWorldMgr:GetOnlinePlayerByPid(iDefender)
    local oAttacker = global.oWorldMgr:GetOnlinePlayerByPid(iAttacker)
    if oAttacker:GetNowWar() then
        self:AttackWarFailed(iTerraId,iAttacker,iDefender)
        return
    end
    if not mChoice or (not mChoice[iDefender] or mChoice[iDefender] == 0) then
        global.oNotifyMgr:Notify(iAttacker,"对方放弃本轮战斗")
        self:DefendFailed(iTerraId,iAttacker,iDefender)
        return
    end
    if mChoice and mChoice[iAttacker] and mChoice[iAttacker] == 0 then
        global.oNotifyMgr:Notify(iDefender,"对方放弃本轮战斗")
        self:AttackWarFailed(iTerraId,iAttacker,iDefender)
        return
    end
    self:FightAttackWar4(iTerraId,iAttacker)
end

function CHuodong:FightAttackWar3(iTerraId,iAttacker,iDefend)
    if table_count(self.m_mHelp[iTerraId]) <= 0 then
        self:DefendFailed(iTerraId,iAttacker)
    end
    local mChoice = {}
    local iDefender = iDefend or self.m_mHelp[iTerraId][1].pid
    local fCallBack = function()
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        oHuodong:DelTimeCb("HelpCountDown"..iTerraId)
        oHuodong:SetPrepare(iAttacker,iTerraId)
        oHuodong:SetPrepare(iDefender,iTerraId)
        oHuodong:CheckChoice2(iTerraId,iDefender,iAttacker,mChoice)
    end
    self:AddTimeCb("HelpCountDown"..iTerraId,31*1000,fCallBack)
    self:SetPrepare(iDefender,iTerraId,true)
    self:SetPrepare(iAttacker,iTerraId,true)
    local oAttacker = global.oWorldMgr:GetOnlinePlayerByPid(iAttacker)
    local oDefenders = global.oWorldMgr:GetOnlinePlayerByPid(iDefender)
    local oNotifyMgr = global.oNotifyMgr
    local iAnswer = 2       --需要等待响应的人数
    if oAttacker:GetNowWar() then
        iAnswer = iAnswer - 1
        local sContent = "本轮进攻方为您，准备时间为30秒!"
        oNotifyMgr:SendSelf(oDefenders,sContent, 0, 1)
    end
    if oDefenders:GetNowWar() then
        iAnswer = iAnswer - 1
        local sContent = "本轮支援方为您，准备时间为30秒!"
        oNotifyMgr:SendSelf(oDefenders,sContent, 0, 1)
    end
    if iAnswer == 0 then
        return
    end
    local sContent = string.format("本轮支援方为您，是否回去支援？")
    if oDefenders and oDefenders:HasTeam() then
        sContent = sContent.."\n确认将强制退出队伍"
    end
    local mNet2 = {
        sContent = sContent,
        sConfirm = "确认",
        sCancle = "取消",
        default = 0,
        time = 30,
    }
    local mReady = {}
    local iAttackSession,iDefendSession
    table.insert(mReady,self:PackReadyInfo(iTerraId,iAttacker))
    table.insert(mReady,self:PackReadyInfo(iTerraId,iDefender))
    local iEndTime = get_time() + 30

    local oCbMgr = global.oCbMgr
    local mNet = oCbMgr:PackConfirmData(nil, mNet2)
    local func = function(oPlayer,mData)
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        if not (oHuodong.m_PrepareList[oPlayer.m_iPid] and oHuodong.m_PrepareList[oPlayer.m_iPid][iTerraId]) then
            return
        end
        local iChoice = mData.answer
        mChoice[oPlayer.m_iPid] = iChoice
        oHuodong:UpdateReadyInfo(mReady,oPlayer.m_iPid,iChoice == 0 and 1 or 2,iEndTime)
        if iChoice and iChoice == 1 then
            if oPlayer:HasTeam() then
                local oTeamMgr = global.oTeamMgr
                local oTeam = oPlayer:HasTeam()
                local iTeamID = oPlayer:TeamID()
                oTeam:Leave(oPlayer.m_iPid)
                oTeamMgr:OnLeaveTeam(iTeamID,oPlayer.m_iPid)
            end
            if table_count(mChoice) == iAnswer and (mChoice[iAttacker] == 1 and mChoice[iDefender] == 1) and iAnswer == 2 then
                oHuodong:DelTimeCb("HelpCountDown"..iTerraId)
                oHuodong:FightAttackWar4(iTerraId,iAttacker)
                self:SetPrepare(iDefender,iTerraId)
                self:SetPrepare(iAttacker,iTerraId)
            end
        else
            oHuodong:DelTimeCb("HelpCountDown"..iTerraId)
            if oPlayer.m_iPid == iDefender then
                oHuodong:DefendFailed(iTerraId,iAttacker,iDefender)
                local oAttacker = global.oWorldMgr:GetOnlinePlayerByPid(iAttacker)
                if oAttacker and iAttackSession then
                    oAttacker:Send("GS2CCloseConfirmUI",{sessionidx = iAttackSession})
                end
            else
                local oDefenders = global.oWorldMgr:GetOnlinePlayerByPid(iDefender)
                if oDefenders and iDefendSession then
                    oDefenders:Send("GS2CCloseConfirmUI",{sessionidx = iDefendSession})
                end
                oHuodong:AttackWarFailed(iTerraId,iAttacker,iDefender)
            end
            self:SetPrepare(iDefender,iTerraId)
            self:SetPrepare(iAttacker,iTerraId)
        end
    end
    if not oDefenders:GetNowWar() then
        iDefendSession = oCbMgr:SetCallBack(iDefender,"GS2CConfirmUI",mNet,nil,func)
    end

    if not oAttacker:GetNowWar() then
        mNet = oCbMgr:PackConfirmData(nil, mNet2)
        mNet.sContent = "本轮进攻方为您，是否出战？"..(oAttacker:HasTeam() and "\n确认将自动离队" or "")
        iAttackSession = oCbMgr:SetCallBack(iAttacker,"GS2CConfirmUI",mNet,nil,func)
    end
end

function  CHuodong:FightAttackWar4(iTerraId,iAttacker)
    local iDefender = self.m_mHelp[iTerraId][1].pid
    local oTerra = self.m_mTerra[iTerraId]
    local oWorldMgr = global.oWorldMgr
    local oWarMgr = global.oWarMgr
    local oDefenders = oWorldMgr:GetOnlinePlayerByPid(iDefender)
    local oAttacker = oWorldMgr:GetOnlinePlayerByPid(iAttacker)
    if not oDefenders then
        self:DefendFailed(iTerraId,iAttacker,iDefender)
        return
    end
    if oDefenders:HasTeam() then
        local oTeam = oDefenders:HasTeam()
        oTeam:ShortLeave(iDefender)
    end
    if oAttacker:HasTeam() then
        local oTeam = oAttacker:HasTeam()
        oTeam:ShortLeave()
    end
    local mArgs = {
        war_type = gamedefines.WAR_TYPE.TERRAWARS_TYPE,
    }
    local oWar = oWarMgr:CreateWar(mArgs)
    local iWarID = oWar:GetWarId()
    self.m_mCurFight[iTerraId] = self.m_mCurFight[iTerraId] or {}
    self.m_mCurFight[iTerraId]["warid"] = iWarID
    self.m_mCurFight[iTerraId]["attacker"] = iAttacker
    self.m_mCurFight[iTerraId]["defender"] = iDefender
    oWar:SetData("close_auto_skill",true)
    oWar:SetData("defender",iDefender)
    oWar:SetData("attacker",iAttacker)
    oWar:SetData("terra_id",iTerraId)
    local oNowWar = oAttacker.m_oActiveCtrl:GetNowWar()
    assert(not oNowWar,string.format("CreateWar err %d",iAttacker))
    local oNowWar = oDefenders.m_oActiveCtrl:GetNowWar()
    assert(not oNowWar,string.format("CreateWar err %d",iDefender))
    local ret
    ret = oWarMgr:EnterWar(oAttacker, oWar:GetWarId(), {camp_id = 2}, true)
    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end

    ret = oWarMgr:EnterWar(oDefenders, oWar:GetWarId(), {camp_id = 1}, true)
    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end
    oWarMgr:SetWarEndCallback(oWar:GetWarId(),function (mArgs)
        local oWar = oWarMgr:GetWar(iWarID)
        local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
        oHuodong:WarFightEnd(oWar,iAttacker,oTerra,mArgs)
        end)
    oWarMgr:StartWarConfig(oWar:GetWarId())
    local iHelpPoints = self:GetHelpPoint(iTerraId)
    self:AddPerPoints(iDefender,iTerraId,iHelpPoints)
    self:AddPerContribution(iDefender,iTerraId,iHelpPoints)
    -- body
end

function CHuodong:GetHelpPoint(iTerraId)
    local mInfo = self:GetTerraBaseData()
    return mInfo[iTerraId]["help_point"]
end

function CHuodong:GetAttackPoint(iTerraId)
    local mInfo = self:GetTerraBaseData()
    return mInfo[iTerraId]["attack_point"]
end

function CHuodong:GetOccupyPoint(iTerraId)
    local mInfo = self:GetTerraBaseData()
    return mInfo[iTerraId]["occupy_point"]
end

--自救回调
function CHuodong:OnTerraWarEnd(oWar,iTerraId,iAttacker,mArgs)
    if self.m_bStart == 0 then
        self:ClearTerra(iTerraId)
        return
    end
    local iWinSide = mArgs.win_side
    local iTerraId = oWar:GetData("terra_id",0)
    local oTerra = self.m_mTerra[iTerraId]
    local iAttacker = oWar:GetData("attacker",0)
    local iDefender = oWar:GetData("defender",0)
   if iWinSide == 1 then
        self:AttackWarFailed(iTerraId,iAttacker,iDefender)
    elseif iWinSide == 2 then
        self.m_mSelfSave[iTerraId] = self.m_mSelfSave[iTerraId] or {}
        self.m_mSelfSave[iTerraId][iDefender] = true
        self:DefendFailed(iTerraId,iAttacker,iDefender)
    end
end

function CHuodong:GetGuardPartnerForWar(iTerraId)
    local mGuard = self.m_mGuard[iTerraId]["guard"]["partner"]
    local mParInfo = {}
    for iParId,info in pairs(mGuard) do
        info.equip = nil
        local oPartner = partnerctrl.NewPartner(iParId,info)
        table.insert(mParInfo,oPartner)
    end
    return mParInfo
end

function CHuodong:GetGuardPlayerForWar(iTerraId)
    local mGuard = self.m_mGuard[iTerraId]["guard"]["player"]
    return mGuard
end

function CHuodong:CreateWar(mInfo)
    local oWarMgr = global.oWarMgr
    local id = oWarMgr:DispatchSceneId()
    local oWar = CMyWar:New(id, mInfo)
    oWar:ConfirmRemote()
    oWarMgr.m_mWars[id] = oWar
    return oWar
end

function CHuodong:WatchWar(iPid,iTerraId)
    local oNotifyMgr = global.oNotifyMgr
    local oTerra = self.m_mTerra[iTerraId]
    if not oTerra then
        return
    end
    if not self:IsOnFight(iTerraId) then
        oNotifyMgr:Notify(iPid,"据点状态已发生变化")
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oWatcher = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oWatcher then
        return
    end
    local iDefender = self.m_mCurFight[iTerraId].defender
    local iAttacker = self.m_mCurFight[iTerraId].attacker
    local oDefenders = global.oWorldMgr:GetOnlinePlayerByPid(iDefender)
    local iObserverView = iDefender
    if (not oDefenders) or (not oDefenders.m_oActiveCtrl:GetNowWar()) then
        iObserverView = iAttacker
    end
    local oPubMgr = global.oPubMgr
    oPubMgr:WatchWar(oWatcher,iObserverView)
end

function CHuodong:DoOperation(iPid,iTerraId,iOperate,iNextCmd)
    if iOperate == 1 then
        self:GiveUpTerra(iPid,iTerraId,"玩家手动放弃",iNextCmd)
    elseif iOperate == 3 then
        self:WatchWar(iPid,iTerraId)
    elseif iOperate == 4 then
        self:AttackTerra(iPid,iTerraId,iNextCmd)
    elseif iOperate == 5 then
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        self:HelpTerra(oPlayer,iTerraId,iNextCmd)
    end
end

function CHuodong:DoNextCmd(oPlayer,iTerraId,iNextCmd)
    if iNextCmd == 1 then
        self:ClickTerra(oPlayer,iTerraId)
    elseif iNextCmd == 2 then
        local iWarID = self.m_mCurFight[iTerraId] and self.m_mCurFight[iTerraId]["warid"] or 0
        if iWarID ~= 0 then
            self:GetListInfo(oPlayer,iWarID)
        end
    end
end

function CHuodong:GetListInfo(oPlayer,iID,iWarID)
    local iTerraId = iID or (self.m_mPid2Terra[oPlayer.m_iPid] and self.m_mPid2Terra[oPlayer.m_iPid]["terra_id"])
    if not iTerraId then
        local oWarMgr  = global.oWarMgr
        local oWar = oWarMgr:GetWar(iWarID)
        if oWar then
            iTerraId = oWar:GetData("terra_id",0)
            if iTerraId == 0 then
                return
            end
        else
            return
        end
    end

    local oTerra = self.m_mTerra[iTerraId]
    if not oTerra then
        return
    end
    if not oPlayer then
        return
    end
    local mHelpList = {}
    local mAttackList = {}
    if self.m_mHasHelp[iTerraId] then
        for idx,mInfo in pairs(self.m_mHasHelp[iTerraId]) do
            table.insert(mHelpList,{pid=mInfo.pid,name=mInfo.name,status = 1})
        end
    end
    if self.m_mHelp[iTerraId] then
        for idx,mInfo in pairs(self.m_mHelp[iTerraId]) do
            table.insert(mHelpList,{pid=mInfo.pid,name=mInfo.name,status = 0})
        end
    end
    if self.m_mHasAttack[iTerraId] then
        for idx,mInfo in pairs(self.m_mHasAttack[iTerraId]) do
            table.insert(mAttackList,{pid=mInfo.pid,name=mInfo.name,status = 1})
        end
    end
    if self.m_mAttack[iTerraId] then
        for idx,mInfo in pairs(self.m_mAttack[iTerraId]) do
            table.insert(mAttackList,{pid=mInfo.pid,name=mInfo.name,status = 0})
        end
    end
    local sOwner = oTerra:GetOwnerName()
    oPlayer:Send("GS2CListInfo",{terraid=iTerraId,orgid = oTerra:GetOrgID(),helplist=mHelpList,attacklist=mAttackList,name=sOwner})
end

function CHuodong:CheckCanLeaveQueue(iPid,iTerraId)
    if self.m_PrepareList[iPid] and self.m_PrepareList[iPid][iTerraId] then
        return false,"回合准备时间，禁止离开队列"
    end
    if self.m_WarCountDown[iPid] then
        return false,"回合准备时间，禁止离开队列"
    end
    return true
end

function CHuodong:LeaveQueue(iPid,iTerraId,bNotNotify)
    local bCanLeave,sMsg = self:CheckCanLeaveQueue(iPid,iTerraId)
    if not bCanLeave then
        global.oNotifyMgr:Notify(iPid,sMsg)
        return
    end
    if self.m_mPid2Terra[iPid] and self.m_mPid2Terra[iPid]["attack"] then
        self:LeaveAttackQueue(iPid,iTerraId or self.m_mPid2Terra[iPid]["terra_id"],bNotNotify)
    elseif self.m_mPid2Terra[iPid] and self.m_mPid2Terra[iPid]["help"] then
        self:LeaveHelpQueue(iPid,iTerraId or self.m_mPid2Terra[iPid]["terra_id"],bNotNotify)
    end
end

function CHuodong:LeaveAttackQueue(iPid,iTerraId,bNotNotify)
    self:Dirty()
    if not self.m_mAttack[iTerraId] then
        return
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    for idx,info in pairs(self.m_mAttack[iTerraId]) do
        if info.pid == iPid then
            table.remove(self.m_mAttack[iTerraId],idx)
            self.m_mPid2Terra[iPid] = nil
            oPlayer:Send("GS2CTerraQueueStatus",{status=0})
            if not bNotNotify then
                self:GetListInfo(oPlayer,iTerraId)
                global.oNotifyMgr:Notify(iPid,"成功退出进攻队伍")
            end
            record.user("terrawars","cancel_attack",{pid = iPid,terraid = iTerraId})
            return
        end
    end
end

function CHuodong:LeaveHelpQueue(iPid,iTerraId,bNotNotify)
    self:Dirty()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    for idx,info in pairs(self.m_mHelp[iTerraId]) do
        if info.pid == iPid then
            table.remove(self.m_mHelp[iTerraId],idx)
            if self.m_mPid2Terra[iPid] then
                self.m_mPid2Terra[iPid] = nil
                oPlayer:Send("GS2CTerraQueueStatus",{status=0})
            end
            if not bNotNotify then
                self:GetListInfo(oPlayer,iTerraId)
                global.oNotifyMgr:Notify(iPid,"成功退出支援队伍")
            end
            record.user("terrawars","cancel_help",{pid = iPid,terraid = iTerraId})
            return
        end
    end
end

function CHuodong:HelpFirst(oPlayer,iTerraId)
    local oNotifyMgr = global.oNotifyMgr
    if self.m_mHasHelp[iTerraId] and self.m_mHasHelp[oPlayer.m_iPid] then
        oNotifyMgr:Notify(oPlayer.m_iPid,"你已支援过该据点")
        return
    end
    if self:GetTerraOwner(iTerraId) ~= oPlayer.m_iPid then
        oNotifyMgr:Notify(oPlayer.m_iPid,"只有领主可以优先支援")
        return
    end
    if not self.m_mHelp[iTerraId] then
        oNotifyMgr:Notify(oPlayer.m_iPid,"据点状态已发生变化")
        return
    end
    self:Dirty()
    for idx,info in ipairs(self.m_mHelp[iTerraId]) do
        if info.pid == oPlayer.m_iPid then
            local temp = table_deep_copy(info)
            table.remove(self.m_mHelp[iTerraId],idx)
            table.insert(self.m_mHelp[iTerraId],1,temp)
            local iWarID = self.m_mCurFight[iTerraId] and self.m_mCurFight[iTerraId]["warid"] or 0
            self:GetListInfo(oPlayer,iWarID)
            global.oNotifyMgr:Notify(oPlayer.m_iPid,"插队成功")
            return
        end
    end
end

function CHuodong:RecordRomPartnerHp(iWarId,bWin,iPid,iParId,iHp)
    local iTerraId = self:GetTerraByWarId(iWarId)
    if iTerraId == 0 then
        return
    end
    local iOwner = self:GetTerraOwner(iTerraId)
    if iOwner ~= iPid then
        return
    end
    self:Dirty()
    local mGuard = self.m_mGuard[iTerraId]
    if mGuard and mGuard["guard"] and mGuard["guard"]["partner"] and mGuard["guard"]["partner"][iParId] then
        mGuard["guard"]["partner"][iParId]["terrawars_hp"] = iHp
    end
end

function CHuodong:GetTerraByWarId(iWarId)
    if not self.m_mCurFight then
        return 0
    end
    for iTerraId,info in pairs(self.m_mCurFight) do
        if info["warid"] == iWarId then
            return iTerraId
        end
    end
    return 0
end

function CHuodong:Close()
    self:Dirty()
    self.m_bStart = 0
    self:DelTimeCb("_RefreshPoints")
    self:DelTimeCb("_StarWars")
    self:DelTimeCb("_ShowTerra")
    for iTerraId,oTerra in pairs(self.m_mTerra) do
        self:DelTimeCb("_CheckPartnerSet"..iTerraId)
        self:DelTimeCb("HelpCountDown"..iTerraId)
        oTerra:Close()
        self:ClearTerra(iTerraId)
        self:RemoveTempNpc(oTerra)
    end
    self:DoReward()
    self.m_mTerra = {}
    self.m_mPlayerStatus = {}
    self.m_mAttack = {}
    self.m_mHelp = {}
    self.m_mGuard = {}
    self.m_PersonalPoints = {}
    self.m_OrgPoints = {}
    self.m_OfflineContribution = {}
    self.m_mSelfSave = {}
    self.m_mBackUp = {}
    self.m_mAchieveDegree = {}
    self.m_mOrgLog = {}
    self.m_mTerra2Log = {}
end

function CHuodong:BuyLingli(oPlayer,iBuyTime,iTerraId)
    if self.m_bStart ~= 1 then
        return false
    end
    local mLingli = self:GetLingliInfo(oPlayer)
    local iLingli = mLingli["lingli"]
    local iMaxLingli = tonumber(res["daobiao"]["global"]["terrawars_max_lingli"]["value"])
    if iLingli >= iMaxLingli then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"灵力已达上限，无法购买")
        return
    end
    local iCost = tonumber(res["daobiao"]["global"]["lingli_cost"]["value"])

    self:TrueBuyLingli(oPlayer,iBuyTime,iTerraId)
end

function CHuodong:TrueBuyLingli(oPlayer,iBuyTime,iTerraId)
    local iPid = oPlayer.m_iPid
    local iCost = tonumber(res["daobiao"]["global"]["lingli_cost"]["value"])
    local iInterval = tonumber(res["daobiao"]["global"]["lingli_cost_interval"]["value"])
    local mLingli = self:GetLingliInfo(oPlayer)
    local iDoneTime = mLingli["buy_times"] or 0
    iCost = iDoneTime * iInterval + iCost
    iCost = math.min(iCost,50)
    if oPlayer:ValidGoldCoin(iBuyTime*iCost) then
        local iLingli = mLingli["lingli"]
        local iMaxLingli = tonumber(res["daobiao"]["global"]["terrawars_max_lingli"]["value"])
        iLingli = (iLingli+iBuyTime)>iMaxLingli and iMaxLingli or (iLingli+iBuyTime)
        oPlayer:ResumeGoldCoin(iBuyTime*iCost,"据点战购买灵力")
        mLingli["lingli"] = iLingli
        if iLingli == iMaxLingli then
            mLingli["lastgive"] = get_time()
        end
        mLingli["buy_times"] = (mLingli and mLingli["buy_times"] or 0) + 1
        oPlayer.m_oActiveCtrl:SetData("lingli",mLingli)
        global.oNotifyMgr:Notify(iPid,"购买成功")
        self:ClickTerra(oPlayer,iTerraId)
        
    else
        local sContent = string.format("你的水晶不足，是否立即前往补充？")
        local mNet2 = {
            sContent = sContent,
            sConfirm = "确认",
            sCancle = "取消",
            default = 0,
            time = 30,
        }
        local oCbMgr = global.oCbMgr
        local mNet = oCbMgr:PackConfirmData(nil, mNet2)
        local func = function(oPlayer,mData)
            if mData.answer and mData.answer == 1 then
                --TODO
            end
        end
        oCbMgr:SetCallBack(iPid,"GS2CConfirmUI",mNet2,nil,func)
    end
end

function CHuodong:GetTerrawarOrgRank(oPlayer,iPage)
    -- body
end

function CHuodong:RecordPersonalRank(oPlayer,mData)
    mData.time = get_current()
    local mRank = {}
    mRank.rank_name = "terrawars_org"
    mRank.rank_data = mData
    interactive.Send(".rank","rank","PushDataToRank",mRank)
end

function CHuodong:UpdatePerRank(iPid,mData)
    local mRank = {}
    mRank.rank_name = "terrawars_org"
    mRank.rank_data = mData
    mRank.pid = iPid
    interactive.Send(".rank","rank","OnTerrPointUpdate",mRank)
    -- body
end

function CHuodong:UpdateServerRank(iOrgID,mData)
    local mRank = {}
    mRank.rank_name = "terrawars_server"
    mRank.rank_data = mData
    mRank.orgid = iOrgID
    interactive.Send(".rank","rank","OnTerrOrgPointUpdate",mRank)
end

function CHuodong:DoReward()
    interactive.Send(".rank","rank","RewardTerraWars",{})
end

function CHuodong:AfterCreateOrg(iOrgID,mInfo)
    self:InsertOrgRank(iOrgID)
    self:InsertServerRank(iOrgID,mInfo)
end

function CHuodong:InsertOrgRank(iOrgID,mInfo)
    local mData = {}
    mData.rank_name = {"terrawars_org"}
    mData.orgid = iOrgID
    interactive.Send(".rank","rank","NewOrg",mData)
end

function CHuodong:InsertServerRank(iOrgID,mInfo)
    local mData = {}
    mData.time = get_current()
    mData.org_points = 0
    mData.org_name = mInfo.orgname or "未知公会"
    mData.org_level = 1
    mData.leader = mInfo.orgleader or "无名"
    mData.flag = mInfo.orgsflag or ""
    mData.orgid = iOrgID
    local mRank = {}
    mRank.rank_name = "terrawars_server"
    mRank.arg = {orgid = iOrgID}
    mRank.rank_data = mData
    interactive.Send(".rank","rank","PushDataToRank",mRank)
end

function CHuodong:OnOrgLeaderChange(mInfo)
    local mData = {}
    mData.rank_name = {"terrawars_server"}
    mData.orgid = iOrgID
    mData.leader_info = mInfo
    interactive.Send(".rank","rank","OnOrgLeaderChange",mData)
end

function CHuodong:AfterAddMem(iOrgID,mPlayerInfo)
    local mData = {}
    mData.rank_name = {"terrawars_org"}
    mData.orgid = iOrgID
    mData.rankinfo = {
        pid = mPlayerInfo.pid,
        name = mPlayerInfo.name,
        time = get_current(),
        position = mPlayerInfo.position,
        personal_points = self.m_PersonalPoints[iPid] or 0
    }
    interactive.Send(".rank","rank","NewOrgMem",mData)
end

function CHuodong:AfterLeaveOrg(iOrgID,iPid)
    self:LeaveOrg(iPid)
    local mData = {}
    mData.rank_name = {"terrawars_org"}
    mData.orgid = iOrgID
    mData.pid = iPid
    --interactive.Send(".rank","rank","LeaveOrg",mData)
end

function CHuodong:ClearPlayerInfo(iPid)
    self:ClearPlayerAllTerra(iPid)
    self:LeaveQueue(iPid,nil,true)
    self.m_mPlayerStatus[iPid] = nil
end

function CHuodong:OnUpdateName(oPlayer)
    for iTerraId,info in pairs(self.m_mGuard) do
        if info.owner == oPlayer.m_iPid then
            local oTerra = self.m_mTerra[iTerraId]
            oTerra:SetOwnerName(oPlayer:GetName())
            self.m_mGuard[iTerraId]["guard"]["player"]["name"] = oPlayer:GetName()
        end
    end
    if self.m_mBackUp[oPlayer.m_iPid] and self.m_mBackUp[oPlayer.m_iPid]["player"]then
        self.m_mBackUp[oPlayer.m_iPid]["player"]["name"] = oPlayer:GetName()
    end
end

function CHuodong:SendChangeOwnerMail(iTerraId,iOldOwner,iNewOwner,sType)
    local iMailId = 42
    if sType == "defend" then
        iMailId = 43
    end
    local mArgs = self:GetMailInfo(iTerraId,iOldOwner,iNewOwner)
    local oMailMgr = global.oMailMgr
    local mData, sName = oMailMgr:GetMailInfo(iMailId)
    mData = self:TranMailString(mData,mArgs)
    oMailMgr:SendMail(0, sName, iOldOwner, mData,{} , {})
    local sTitle = "据点战捷报"
    local sContent = "大事不妙！您的公会据点被其他公会成员抢走了，快去夺回吧。"
    xgpush.Push(iOldOwner, sTitle,sContent)
end

function CHuodong:GetMailInfo(iTerraId,iOldOwner,iNewOwner)
    local oTerra = self.m_mTerra[iTerraId]
    local mPosInfo = oTerra:PosInfo()
    local iX,iY = mPosInfo["x"],mPosInfo["y"]
    local mNewOwner = self.m_mBackUp[iNewOwner]["player"]["owner_info"]
    local sOrgName = mNewOwner["orgname"]
    local sOrgFlag = mNewOwner["sflag"]
    local sName = mNewOwner["name"]
    return {posx = math.floor(iX),posy = math.floor(iY),orgname = sOrgName,orgflag = sOrgFlag,name = sName}
end

function CHuodong:TranMailString(mMailInfo,mArgs)
    if not mArgs then
        return
    end
    if string.find(mMailInfo.context,"$posx") then
        mMailInfo.context = string.gsub(mMailInfo.context,"$posx",mArgs.posx or "")
    end
    if string.find(mMailInfo.context,"$posy") then
        mMailInfo.context = string.gsub(mMailInfo.context,"$posy",mArgs.posy or "")
    end
    if string.find(mMailInfo.context,"$orgname") then
        mMailInfo.context = string.gsub(mMailInfo.context,"$orgname",mArgs.orgname or "")
    end
    if string.find(mMailInfo.context,"$orgflag") then
        mMailInfo.context = string.gsub(mMailInfo.context,"$orgflag",mArgs.orgflag or "")
    end
    if string.find(mMailInfo.context,"$name") then
        mMailInfo.context = string.gsub(mMailInfo.context,"$name",mArgs.name or "")
    end
    return mMailInfo
end

function CHuodong:GMSetLingli(oPlayer,iLingli)
    if self.m_bStart ~= 1 then
        return
    end
    local iPid = oPlayer.m_iPid
    local mLingli = self:GetLingliInfo(oPlayer)
    if mLingli["givelingli"] == 0 then
        mLingli["givelingli"] = 1
        mLingli["lingli"] = mLingli["lingli"] + 1
        mLingli["lastgive"] = get_time()
    end
    mLingli["lingli"] = iLingli
    oPlayer.m_oActiveCtrl:SetData("lingli",mLingli)
end

function CHuodong:UpdateMirrorNpc(iTerraId,mInfo)
    for iNpcId,oNpc in pairs(self.m_mNpcList) do
        if oNpc.m_bMirror and oNpc.m_iTerraId == iTerraId then
            oNpc:SyncSceneInfo(mInfo)
        end
    end
end

function CHuodong:RemoveTempNpc(oNpc)
    local npcid = oNpc.m_ID
    local oNpcMgr = global.oNpcMgr
    local iTerraId = oNpc.m_iTerraId
    for iNpcId,npc in pairs(self.m_mNpcList) do
        if npc.m_iTerraId and npc.m_iTerraId == iTerraId then
            self.m_mNpcList[iNpcId] = nil
            oNpcMgr:RemoveSceneNpc(iNpcId)
        end
    end
end

function CHuodong:UpdateOrgFlag(iOrgID,sFlag)
    if self.m_bStart ~= 1 then
        return
    end
    for iTerraId,oTerra in pairs(self.m_mTerra) do
        if oTerra:GetOrgID() == iOrgID then
            oTerra:SetOrgFlag(sFlag)
        end
    end
end

function CHuodong:ValidWatchWar(oPlayer)
    if self:IsPrepare(oPlayer.m_iPid) then
        return false
    end
    return true
end

function CHuodong:AskForHelp(iTerraId,oAttacker)
    local oTerra = self.m_mTerra[iTerraId]
    local sTerraName = oTerra:Name()
    local iOrgID = oTerra:GetOrgID()
    local iOwner = oTerra:GetTerraOwner()
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = string.format("{link22,%d,#O【%s】#n发出了求救信号！\n [u]#G【前往支援】,%d}",iTerraId,sTerraName,get_time())
    oNotifyMgr:SendOrgChat(sMsg,iOrgID,{pid = 0})
end

function CHuodong:GoToHelp(oPlayer,iTerraId,iStartTime)
    if oPlayer:GetNowWar() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"战斗中，无法支援")
        return
    end
    if self.m_mWarEnd[iTerraId] and self.m_mWarEnd[iTerraId] > iStartTime then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"链接已失效")
        return
    end
    self:FindNpcPath(oPlayer,iTerraId)
end

function CHuodong:FindNpcPath(oPlayer,iTerraId)
    if iTerraId then
        local npc = self.m_mTerra[iTerraId]
        if not npc then
            return
        end
        local iNpcId = npc.m_ID
        local oCbMgr = global.oCbMgr
        local mPosInfo = npc:PosInfo()
        local mData = {["iMapId"] = npc:MapId(),["iPosx"] = mPosInfo.x,["iPosy"] = mPosInfo.y,["iAutoType"] = 1}
        local func = function(oPlayer,mData)
            local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
            oHuodong:ClickTerra(oPlayer,iTerraId)
        end
        oCbMgr:SetCallBack(oPlayer.m_iPid,"AutoFindTaskPath",mData,nil,func)
    end
end

function CHuodong:RecordOrgLog(iTerraId,oPlayer2,iType,bStart)
    self:Dirty()
    local oTerra = self.m_mTerra[iTerraId]
    local sOwnerName = oTerra:GetOwnerName()
    local iOwnerId = oTerra:GetTerraOwner()
    local iOrgID = oTerra:GetOrgID()
    self.m_mOrgLog[iOrgID] = self.m_mOrgLog[iOrgID] or {}
    local m = {
        createtime = get_time(),
        option = iType,
        defender_id = iOwnerId,
        defender_name = sOwnerName,
        attacker_id = oPlayer2 and oPlayer2.m_iPid,
        attacker_name = oPlayer2 and oPlayer2:GetName(),
        terraid = iTerraId,
        status = 0,
    }
    table.insert(self.m_mOrgLog[iOrgID],m)
    self:CheckOrgLog(iOrgID)
    if bStart then
        self.m_mTerra2Log[iTerraId] = {iOrgID,#self.m_mOrgLog[iOrgID]}
    end
end

function CHuodong:UpdateOrgLog(iTerraId,iStatus)
    if not self.m_mTerra2Log[iTerraId] then
        return
    end
    self:Dirty()
    local iOrgID,iIndex = table.unpack(self.m_mTerra2Log[iTerraId])
    self.m_mTerra2Log[iTerraId] = nil
    if iIndex <= 0 then
        return
    end
    self.m_mOrgLog[iOrgID][iIndex]["status"] = iStatus
end

function CHuodong:CheckOrgLog(iOrgID)
    if not iOrgID or not self.m_mOrgLog[iOrgID] or table_count(self.m_mOrgLog[iOrgID]) < 50 then
        return
    end
    local mHistory = self.m_mOrgLog[iOrgID] or {}
    local iLen = 0
    local iFirstID
    for id,tHis in pairs(mHistory) do
        local iTime = tHis["createtime"]
        if not iFirstID or iTime < mHistory[iFirstID]["createtime"] then
            iFirstID = id
        end
        iLen = iLen + 1
    end
    if iLen > 50 then
        self:Dirty()
        table.remove(self.m_mOrgLog[iOrgID],iFirstID)
    end
    for iTerraId,info in pairs(self.m_mTerra2Log) do
        if info[1] == iOrgID then
            info[2] = info[2] - 1
        end
    end
end

function CHuodong:PackOrgLog(oPlayer)
    local iOrgID = oPlayer:GetOrgID()
    if not iOrgID or iOrgID == 0 then
        return
    end
    local m = self.m_mOrgLog[iOrgID] or {}
    oPlayer:Send("GS2CTerrawarsLog",{log = m})
end

function CHuodong:SendWarBrocast()
    self:DelTimeCb("SendWarBrocast")
    local mRank = self:CalculateOrgScore()
    local iTop1,iTop2,iTop3 = mRank[1] and mRank[1][1] or 0,mRank[2] and mRank[2][1] or 0,mRank[3] and mRank[3][1] or 0
    local iTextId = 1001
    local mArgs = {}
    if iTop1 ~= 0 then
        if iTop1 == iTop2 then
            if iTop2 == iTop3 then
                iTextId = 1004
            else
                iTextId = 1002
                mArgs["orgname1"] = mRank[1]["orgname"]
                mArgs["orgname2"] = mRank[2]["orgname"]
            end
        else
            iTextId = 1003
            mArgs["orgname1"] = mRank[1]["orgname"]
        end
    end
    local sText = self:GetTextData(iTextId)
    sText = self:TranString(sText,mArgs)
    global.oNotifyMgr:SendPrioritySysChat("terrawars_char",sText,1)
end

function CHuodong:TranString(sText,mArgs)
    if string.find(sText,"#orgname1") then
        sText = string.gsub(sText,"#orgname1",mArgs["orgname1"] or "")
    end
    if string.find(sText,"#orgname2") then
        sText = string.gsub(sText,"#orgname2",mArgs["orgname2"] or "")
    end
    return sText
end

function CHuodong:CalculateOrgScore()
    local mRank = {}
    for iTerraId,oTerra in pairs(self.m_mTerra) do
        local iOrgID = oTerra:GetOrgID()
        if iOrgID and iOrgID ~= 0 then
            local iSize = oTerra:GetSize()
            mRank[iOrgID] = mRank[iOrgID] or {orgname=oTerra.m_sOrgName}
            mRank[iOrgID][1] = (mRank[iOrgID][1] or 0) + iSize
        end
    end
    local m = {}
    for iOrgID,info in pairs(mRank) do
        table.insert(m,info)
    end
    local func = function(a,b)
        return a[1]>b[1]
    end
    table.sort(m,func)
    return m
end
-------
CMyWar = {}
CMyWar.__index = CMyWar
inherit(CMyWar, warobj.CWar)

function CMyWar:PackPlayerWarInfo(oPlayer)
    local mWarInfo = oPlayer:PackWarInfo()
    if self:GetData("defender",0) == oPlayer.m_iPid then
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        local mPlayerWarInfo = oHuodong:GetGuardPlayerForWar(self:GetData("terra_id"))
        mWarInfo.hp = mPlayerWarInfo.hp
    end
    return mWarInfo
end

function CMyWar:AddTerraWarsDefenderCmd(iPid)
    interactive.Send(self.m_iRemoteAddr,"war","AddTerraWarsDefenderCmd",{war_id = self.m_iWarId,pid = iPid})
end


CMirrorNpc = {}
CMirrorNpc.__index = CMirrorNpc
CMirrorNpc.m_sName = "terrawars"
inherit(CMirrorNpc, terra.CTerra)

function NewMirrorNpc(mArgs)
    local o = CMirrorNpc:New(mArgs)
    return o
end

function CMirrorNpc:New(mArgs)
    local o = super(CMirrorNpc).New(self)
    o.m_bMirror = true
    o:Init(mArgs)
    return o
end

function CMirrorNpc:Init(mArgs)
    local mArgs = mArgs or {}
    super(CMirrorNpc).Init(self,mArgs)
    self.m_iMainNpc = mArgs.main_npc    
end

function CMirrorNpc:GetMainNpc()
    return global.oNpcMgr:GetObject(self.m_iMainNpc)
end

function CMirrorNpc:do_look(oPlayer)
    local oNpcMgr = global.oNpcMgr
    local oMainNpc = oNpcMgr:GetObject(self.m_iMainNpc)
    oMainNpc:do_look(oPlayer)
end

function CMirrorNpc:PackSceneInfo()
    local oNpcMgr = global.oNpcMgr
    local oMainNpc = oNpcMgr:GetObject(self.m_iMainNpc)
    return oMainNpc:PackSceneInfo()
end
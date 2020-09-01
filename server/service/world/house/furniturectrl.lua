--import module
local global = require "global"

local extend = require "base.extend"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local defines = import(service_path("house.defines"))
local loaditem = import(service_path("item.loaditem"))

CFurniture = {}
CFurniture.__index = CFurniture
inherit(CFurniture,datactrl.CDataCtrl)

function CFurniture:New(iType)
    local o = super(CFurniture).New(self)
    o.m_iType = iType
    o.m_iLevel = 1
    o.m_iLockStatus = defines.LOCK_STATUS.LOCKED
    o.m_iTime = 0
    return o
end

function CFurniture:Load(mData)
    self.m_iLevel = mData["level"] or self.m_iLevel
    self.m_iTime = mData["time"] or self.m_iTime
    self.m_iLockStatus = mData["lock_status"] or self.m_iLockStatus
    self:Dirty()
    -- self:Setup()
end

function CFurniture:Save()
    local mData = {}
    mData["level"] = self.m_iLevel
    mData["time"] = self.m_iTime
    mData["lock_status"] = self.m_iLockStatus
    return mData
end

function CFurniture:Setup()
    if self.m_iTime > 0 then
        local iSecs = self:Timer()
        if iSecs > 0 then
            local iPid = self:GetOwner()
            local oHouseMgr = global.oHouseMgr
            local iType = self.m_iType
            self:AddTimeCb("FurnitureLevel",iSecs*1000,function()
                local oFurniture = defines.GetFurniture(iPid,iType)
                if not oFurniture then
                    return
                end
                oFurniture:TruePromoteLevel()
            end)
        else
            self:TruePromoteLevel()
        end
    end
end

function CFurniture:SetOwner(iOwner)
    self.m_iOwner = iOwner
end

function CFurniture:GetOwner()
    return self.m_iOwner
end

function CFurniture:GetHouse()
    local iOwner = self:GetOwner()
    local oHouseMgr = global.oHouseMgr
    return oHouseMgr:GetHouse(iOwner)
end

function CFurniture:GetScene()
    local oHouse = self:GetHouse()
    return oHouse:GetScene()
end

function CFurniture:Type()
    return self.m_iType
end

function CFurniture:Shape()
    return  10001
end

function CFurniture:LockStatus()
    return self.m_iLockStatus
end

function CFurniture:SetLockStatus(iStatus)
    self:Dirty()
    self.m_iLockStatus = iStatus
    self:Refresh()
end

function CFurniture:IsLockStatus()
    if self.m_iLockStatus == defines.LOCK_STATUS.LOCKED then
        return true
    end
    return false
end

function CFurniture:Timer()
    local iSecs = self.m_iTime or 0
    if iSecs <= 0 then
        return 0
    end
    iSecs = math.max(iSecs - get_time(),0)
    return iSecs
end

function CFurniture:Level()
    return self.m_iLevel
end

function CFurniture:LevelLimit()
    return 10
end

function CFurniture:GetFurnitureLevel(iType)
    local oHouse = self:GetHouse()
    local oFurniture = oHouse:GetFurniture(iType)
    return oFurniture:Level()
end

function CFurniture:GetLevelData(iLevel)
    local res = require "base.res"
    local mData = res["daobiao"]["furniture"][self.m_iType][iLevel]
    assert(mData,string.format("furniture up_level err:%s %s",self.m_iType,iLevel))
    return mData
end

--是否是主家具
function CFurniture:IsMainFurniture()
    if self.m_iType == defines.FURNITURE_TYPE.SOFA then
        return true
    end
    return false
end

function CFurniture:ValidPromoteLevel(iPid)
    local oNotifyMgr = global.oNotifyMgr
    local iNextLevel = self.m_iLevel + 1
    local mData = self:GetLevelData(iNextLevel)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if self.m_iLockStatus == defines.LOCK_STATUS.LOCKED then
        oNotifyMgr:Notify(iPid,"家具未解锁")
        return false
    end
    if self:Level() >= self:LevelLimit() then
        oNotifyMgr:Notify(iPid,"家具已达最大等级，无法升级")
        return false
    end
    if self.m_iTime > 0 then
        oNotifyMgr:Notify(iPid,"家具升级中")
        return false
    end
    local iCoin = mData["gold"] or 100
    local mArgs = {
        short = true,
    }
    if not oPlayer:ValidCoin(iCoin,mArgs) then
        return false
    end
    local iCnt = mData["item_cnt"] or 0
    local iSid = FURNITURE_UPLEVEL_ITEM
    local oHouse = self:GetHouse()
    if oHouse.m_oItemCtrl:GetItemAmount(iSid) < iCnt then
        oNotifyMgr:Notify(iPid,"家具升级所需道具不足")
        return false
    end
    return true
end

function CFurniture:ValidSpeed()
    if self.m_iTime > 0 then
        return true
    end
    return false
end

function CFurniture:PromoteLevel(iPid)
    self:DelTimeCb("FurnitureLevel")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oHouse = self:GetHouse()
    self:Dirty()
    local iNextLevel = self.m_iLevel + 1
    local mData = self:GetLevelData(iNextLevel)
    local iGold = mData["gold"]
    local iCnt = mData["item_cnt"]
    local iShape = FURNITURE_UPLEVEL_ITEM
    oHouse.m_oItemCtrl:RemoveItemAmount(iShape,iCnt,"家具升级")
    oPlayer:ResumeCoin(iGold,"宅邸家具升级")

    local iMin = mData["up_level_time"]
    self.m_iTime = get_time() + iMin * 60
    local iPid = self:GetOwner()
    local iType = self.m_iType
    local oHouseMgr = global.oHouseMgr
    self:AddTimeCb("FurnitureLevel",iMin*60*1000,function()
        local oFurniture = defines.GetFurniture(iPid,iType)
        if not oFurniture then
            return
        end
        oFurniture:TruePromoteLevel()
    end)
    self:Refresh()
    record.user("house","upgrade_furniture", {
        pid = self:GetOwner(),
        level = self.m_iLevel,
        })
end

function CFurniture:TruePromoteLevel(iAddLevell, sReason)
    sReason = sReason or "家具升级结束"
    local iAddLevel  = iAddLevel or 1
    local iOld = self.m_iLevel
    self:DelTimeCb("FurnitureLevel")
    self:Dirty()
    self.m_iTime = 0
    self.m_iLevel = self.m_iLevel + iAddLevel
    self:PromoteEffect()
    self:BroadCast()
    local oHouse = self:GetHouse()
    oHouse:OnPromoteLevel(self)

    record.user("house", "upgrade_furniture_done", {
        pid = self:GetOwner(),
        old_level = iOld,
        new_level = self.m_iLevel,
        reason = sReason,
        })
end

function CFurniture:PromoteEffect()
end

function CFurniture:ProduceWarm()
    local iWarm = 0
    local iLevel = self:Level()
    for i = 1,iLevel do
        local mData = self:GetLevelData(iLevel)
        local mArgs = defines.GetFurnitureEffect(self.m_iType,iLevel)
        local iValue = mArgs["warm"] or 0
        iWarm = iWarm + iValue
    end
    return iWarm
end

function CFurniture:Refresh(iPid)
    iPid = iPid or self.m_iOwner
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CFurnitureInfo",{
            furniture_info = self:PackNetInfo()
        })
    end
end

function CFurniture:BroadCast()
    local oScene = self:GetScene()
    oScene:BroadCast("GS2CFurnitureInfo",{
        furniture_info = self:PackNetInfo()
    })
end

function CFurniture:PackNetInfo()
    return {
        type = self.m_iType,
        level = self.m_iLevel,
        lock_status = self.m_iLockStatus,
        secs = self:Timer(),
    }
end

--沙发
CSofa = {}
CSofa.__index = CSofa
inherit(CSofa,CFurniture)

function CSofa:New(iType)
    local o = super(CSofa).New(self,iType)
    o.m_iLockStatus = defines.LOCK_STATUS.UNLOCKED
    return o
end

function CSofa:PromoteEffect()
end

--工作台家具
CWorkDeskFurniture = {}
CWorkDeskFurniture.__index = CWorkDeskFurniture
inherit(CWorkDeskFurniture,CFurniture)

function CWorkDeskFurniture:New(iType)
    local o = super(CWorkDeskFurniture).New(self,iType)
    o.m_iTalentLevel = 0                                                                    --才艺等级
    o.m_iTalentSchedule = 0                                                             -- 才艺进度
    o:Init()
    return o
end

function CWorkDeskFurniture:Init()
    local iOwner = self:GetOwner()
    self.m_mDesk = {}
    local oFriendDesk = CFriendWorkDesk:New()
    self.m_oFriendDesk = oFriendDesk
    local iCnt = 3
    for iPos=1,iCnt do
        local oWorkDesk = CWorkDesk:New(iPos)
        self.m_mDesk[iPos] = oWorkDesk
    end
end

function CWorkDeskFurniture:Setup()
    super(CWorkDeskFurniture).Setup(self)
    for iPos, oWorkDesk in pairs(self.m_mDesk) do
        oWorkDesk:Setup()
    end
    self.m_oFriendDesk:Setup()
    self:CheckUnlockDesk()
end

function CWorkDeskFurniture:SetOwner(iOwner)
    super(CWorkDeskFurniture).SetOwner(self,iOwner)
    self.m_oFriendDesk:SetOwner(iOwner)
    for iPos,oWorkDesk in pairs(self.m_mDesk) do
        oWorkDesk:SetOwner(iOwner)
    end
end

function CWorkDeskFurniture:Release()
    for _,oWorkDesk in pairs(self.m_mDesk) do
        baseobj_safe_release(oWorkDesk)
    end
    baseobj_safe_release(self.m_oFriendDesk)
    super(CWorkDeskFurniture).Release(self)
end

function CWorkDeskFurniture:Load(mData)
    super(CWorkDeskFurniture).Load(self,mData)
    local mDesk = mData["desk"] or {}
    for iPos,oWorkDesk in pairs(self.m_mDesk) do
        local mDeskData = mDesk[iPos] or {}
        oWorkDesk:Load(mDeskData)
    end
    local mFriendDesk = mData["friend_desk"] or {}
    self.m_oFriendDesk:Load(mFriendDesk)
    self.m_iTalentLevel = mData["talent_level"] or self.m_iTalentLevel
    self.m_iTalentSchedule = mData["talent_schedule"] or self.m_iTalentSchedule
end

function CWorkDeskFurniture:Save()
    local mData = super(CWorkDeskFurniture).Save(self)
    local mDesk = {}
    for iPos,oWorkDesk in pairs(self.m_mDesk) do
        mDesk[iPos] = oWorkDesk:Save()
    end
    mData["desk"] = mDesk
    mData["friend_desk"] = self.m_oFriendDesk:Save()
    mData["talent_level"] = self.m_iTalentLevel
    mData["talent_schedule"] = self.m_iTalentSchedule
    return mData
end

function CWorkDeskFurniture:GetWorkDesk(iPos)
    return self.m_mDesk[iPos]
end

function CWorkDeskFurniture:GetFriendWorkDesk()
    return self.m_oFriendDesk
end

function CWorkDeskFurniture:PromoteEffect()
end

function CWorkDeskFurniture:GetTalentData(iLevel)
    local res = require "base.res"
    local mData = res["daobiao"]["talent_gift"][iLevel]
    assert(mData,string.format("house workdesc talent err:%s",self.m_iLevel))
    return mData
end

function CWorkDeskFurniture:TalentLevel()
    return self.m_iTalentLevel
end

function CWorkDeskFurniture:TalentSchedule()
    return self.m_iTalentSchedule
end

function CWorkDeskFurniture:OpenWorkDesk(iSrcPid, iHandle)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iSrcPid)
    if not oPlayer then
        return
    end
    local mData = {}
    for _,oWorkDesk in ipairs(self.m_mDesk) do
        table.insert(mData,oWorkDesk:PackNetInfo())
    end
    table.insert(mData,self.m_oFriendDesk:PackNetInfo())
    oPlayer:Send("GS2COpenWorkDesk",{
        owner_pid = self:GetOwner(),
        desk_info = mData,
        talent_level = self.m_iTalentLevel,
        talent_schedule = self.m_iTalentSchedule,
        handle_type = iHandle,
    })
end

function CWorkDeskFurniture:ValidTalentShow(iPid,iPos)
    local oNotifyMgr = global.oNotifyMgr
    local oWorkDesk = self:GetWorkDesk(iPos)
    if not oWorkDesk then
        return false
    end
    local mDeskData = defines.GetWorkDeskData()[iPos]
    if not mDeskData then
        return
    end
    if oWorkDesk:IsLockStatus() then
        local sTips = mDeskData.tips
        local iOpenCount = oWorkDesk:OpenCount()
        if iPos == 3 then
            iOpenCount = defines.WORK_DESK_OPEN_LEVEL
        end
        oNotifyMgr:Notify(iPid,string.format(sTips,iOpenCount))
        return false
    end
    if oWorkDesk:Status() ~= defines.WORKDESK_STATUS.FREE then
        oNotifyMgr:Notify(iPid,"该工作台不能进行才艺展示")
        return false
    end
    return true
end

function CWorkDeskFurniture:TalentShow(iPid,iPos)
    local oWorkDesk = self:GetWorkDesk(iPos)
    oWorkDesk:TalentShow(iPid)
    oWorkDesk:Refresh(iPid)
    self:AddTalentSchedule()
    self:RefreshTalent(iPid)
end

function CWorkDeskFurniture:AddTalentSchedule()
    local iLevel = self:TalentLevel()
    local iBase = defines.GetDaobiaoDefines("talent_base_grow")
    local iAttach = defines.GetDaobiaoDefines("talent_attach_grow")
    local iAddSchedule = math.floor(iLevel * iBase + iAttach)

    local iType = defines.FURNITURE_TYPE.CPAN
    local iFurnitureLevel = self:GetFurnitureLevel(iType)
    local mArgs = defines.GetFurnitureEffect(iType,iFurnitureLevel)
    local iCriticalRatio = mArgs["cook_rate"] or 0
    if in_random(iCriticalRatio,100) then
        iAddSchedule = iAddSchedule * 2
    end
    self:AddSchedule(iAddSchedule)
end

function CWorkDeskFurniture:AddSchedule(iAddSchedule)
    self:Dirty()
    local iLevel = self:TalentLevel()
    if iLevel >= 10 then
        return
    end
    local mTalentData = self:GetTalentData(iLevel)
    self.m_iTalentSchedule = self.m_iTalentSchedule + iAddSchedule
    local iNeedSchedule = mTalentData["rate"]
    local iCnt = 0
    while(self.m_iTalentSchedule >= iNeedSchedule and iCnt < 10 ) do
        iCnt = iCnt + 1
        self.m_iTalentSchedule = self.m_iTalentSchedule - iNeedSchedule
        self.m_iTalentLevel = self.m_iTalentLevel + 1
        mTalentData = self:GetTalentData(self.m_iTalentLevel)
        iNeedSchedule = mTalentData["rate"]
    end
end

function CWorkDeskFurniture:ValidDrawGift(iPid,iPos)
    local oWorkDesk = self:GetWorkDesk(iPos)
    if not oWorkDesk then
        return false
    end
    if oWorkDesk:Status() ~= defines.WORKDESK_STATUS.TALENT_GIFT then
        return false
    end
    if oWorkDesk:DrawRewardSid() == 0 then
        return false
    end
    return true
end

function CWorkDeskFurniture:GetTalentGift()
    local mData = defines.GetTalentGiftData()
    local iTalentLevel = self.m_iTalentLevel
    local mGiftItem = {}
    for _,mLevelData in pairs(mData) do
        local mShape = mLevelData["sid_list"]
        local iLevel = mLevelData["talent_level"]
        if iTalentLevel >= iLevel then
            for _,iSid in pairs(mShape) do
                table.insert(mGiftItem,iSid)
            end
        end
    end
    if #mGiftItem <= 0 then
        mGiftItem = {0,}
    end
    local iGiftItem = mGiftItem[math.random(#mGiftItem)]
    return iGiftItem
end

function CWorkDeskFurniture:GetTalentReward()
    local iTalentLevel = self.m_iTalentLevel
    local mData = defines.GetTalentGiftData()[iTalentLevel]
    if mData then
        local mReward = mData.reward or {}
        local m = extend.Array.weight_choose(mData.reward or {}, "weight")
        return {{m.sid, m.amount}}
    end
    return {}
end

function CWorkDeskFurniture:GetRentCoin()
    local iTalentLevel = self.m_iTalentLevel
    local mData = defines.GetTalentGiftData()[iTalentLevel]
    if mData then
        return mData.coin
    else
        return 0
    end
end

function CWorkDeskFurniture:DrawGift(iPid,iPos)
    local oWorldMgr = global.oWorldMgr
    local oMailMgr = global.oMailMgr

    local sReason = "领取工作台奖励"
    local oWorkDesk = self:GetWorkDesk(iPos)
    local lReward = oWorkDesk:DrawRewardInfo()
    local lLogReward =table_deep_copy(lReward)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)

    local iShape = oWorkDesk:DrawRewardSid()
    local oItem = loaditem.Create(iShape)
    local iAmount = 1
    oItem:SetAmount(iAmount)
    local oHouse = self:GetHouse()
    oHouse:AddItem(oItem,sReason, {})
    oWorkDesk:DrawGift(iPid)

    local oUIMgr = global.oUIMgr
    if next(lReward) then
        if oPlayer:ValidGive(lReward,{cancel_tip = 1}) then
            oPlayer:GiveItem(lReward,sReason,{cancel_tip = 1})
        else
            local iMailId = 1
            local mData, name = oMailMgr:GetMailInfo(iMailId)
            local l = {}
            for _, m  in ipairs(lReward) do
                local oItem = loaditem.ExtCreate(m[1])
                oItem:SetAmount(m[2])
                table.insert(l, oItem)
                oUIMgr:AddKeepItem(iPid, oItem:GetShowInfo())
            end
            oMailMgr:SendMail(0, name, iPid, mData, {}, l)
        end
    end
    oUIMgr:ShowKeepItem(iPid)

    local mReward = {}
    mReward[iShape] = (mReward[iShape] or 0) + iAmount
    for _, m in ipairs(lLogReward) do
        local sid, amount = table.unpack(m)
        mReward[sid] = (mReward[sid] or 0) + amount
    end
    record.user("house", "receive_talent_show", {
        pid = self:GetOwner(),
        reward = ConvertTblToStr(mReward)
        })

    local mLog = {}
    -- mLog["pos"] = iPos
    -- mLog["operation"] = "house_furniture"
    oPlayer:LogAnalyGame(mLog,"house",mReward,{},{},0)
end

function CWorkDeskFurniture:ValidHelpFriendWorkDesk(iPid)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    if self.m_oFriendDesk:Status() ~= defines.WORKDESK_STATUS.TALENT_SHOW then
        return false
    end
    local oHouse = self:GetHouse()
    local iCnt = defines.GetDaobiaoDefines("help_friend_talent")
    if oHouse.m_oToday:Query("help_friend_talent",0) >= iCnt then
        oNotifyMgr:Notify(iPid,"今日帮忙次数已经用完了，明天再帮忙吧")
        return false
    end
    return true
end

function CWorkDeskFurniture:HelpFriendWorkDesk(iPid)
    local oHouse = self:GetHouse()
    oHouse.m_oToday:Add("help_friend_talent", 1)
    self.m_oFriendDesk:AddSpeed(iPid)

    record.user("house", "help_workdesk", {
        pid = self:GetOwner(),
        frd_pid = self.m_oFriendDesk:FrdPid(),
        count = oHouse.m_oToday:Query("help_friend_talent", 0),
        })
end

function CWorkDeskFurniture:ValidUseFriendWorkDesk(iPid)
    if self.m_oFriendDesk:IsUsing() then
        return false
    end
    return true
end

--使用好友工作台
function CWorkDeskFurniture:UseFriendWorkDesk(iPid)
    local oHouseMgr = global.oHouseMgr
    local iOwner = self:GetOwner()
    local oHouse = oHouseMgr:GetHouse(iPid)
    if oHouse then
        self.m_oFriendDesk:UseFriendWorkDesk(iPid)
        oHouse:TrueUseFriendWorkDesk(iOwner)
    end
end

--检查开放
function CWorkDeskFurniture:CheckUnlockDesk(bRefresh)
    local oHouse = self:GetHouse()
    local iHavePartner = oHouse:CountPartner()
    local mDeskData = defines.GetWorkDeskData()
    for iPos, m in pairs(mDeskData) do
        if iPos ~= 3 then
            local o = self:GetWorkDesk(iPos)
            if o and o:IsLockStatus() then
                if iHavePartner >= m.unlock then
                    o:SetLockStatus(defines.LOCK_STATUS.UNLOCKED)
                    if bRefresh then
                        o:Refresh()
                    end
                end
            end
        end
    end
end

function CWorkDeskFurniture:CheckUnlockDeskByParLv(bRefresh)
    local iPos = 3
    local oHouse = self:GetHouse()
    local iCntLv = oHouse.m_oPartnerCtrl:CountPartnerLevel()
    if iCntLv ~= defines.WORK_DESK_OPEN_LEVEL then
        return
    end

    local o = self:GetWorkDesk(iPos)
    if o and o:IsLockStatus() then
        o:SetLockStatus(defines.LOCK_STATUS.UNLOCKED)
        if bRefresh then
            o:Refresh()
        end
    end
end

function CWorkDeskFurniture:WorkDeskSpeedFinish(iPid, iPos, iCheck)
    local oWorkDesk = self:GetWorkDesk(iPos)
    if not oWorkDesk then
        return
    end
    if oWorkDesk:Status() ~= defines.WORKDESK_STATUS.TALENT_SHOW then
        return
    end
    local oHouse = self:GetHouse()
    if not oHouse then
        return
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local sReason = "工作台加速完成"
    local iHaveBuy = oHouse:GetWorkDeskBuy(iPos)
    local iCost = self:SpeedFinishCost(iHaveBuy + 1)
    if iCost ~= iCheck then
        oPlayer:NotifyMessage("价格变动")
        return
    end
    if oPlayer:ValidGoldCoin(iCost, {cancel_tip = 1}) then
        oPlayer:ResumeGoldCoin(iCost,sReason,{})
        oHouse:AddWorkDeskBuyCnt(iPos, 1)
        oWorkDesk:DelTimeCb("TalentShow")
        oWorkDesk:WaitDrawGift()
    end
end

function CWorkDeskFurniture:SpeedFinishCost(iDailyBuy)
    local res = require "base.res"
    local iMaxCost = tonumber(res["daobiao"]["global"]["house_worddesk_max_cost"]["value"])
    local sCost = res["daobiao"]["global"]["house_teaart_speed_cost"]["value"]
    local iCost = formula_string(sCost, {n = iDailyBuy})
    return math.min(iMaxCost, math.ceil(iCost))
end

function CWorkDeskFurniture:IsDirty()
    local bFlag = super(CWorkDeskFurniture).IsDirty(self)
    if bFlag then
        return true
    end
    if self.m_oFriendDesk:IsDirty() then
        return true
    end
    for _,oWorkDesk in pairs(self.m_mDesk) do
        if oWorkDesk:IsDirty() then
            return true
        end
    end
    return false
end

function CWorkDeskFurniture:UnDirty()
    super(CWorkDeskFurniture).UnDirty(self)
    self.m_oFriendDesk:UnDirty()
    for _,oWorkDesk in pairs(self.m_mDesk) do
        oWorkDesk:UnDirty()
    end
end

function CWorkDeskFurniture:RefreshTalent(iPid)
    iPid = iPid or self.m_iOwner
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CRefreshTalent",{
        talent_level = self.m_iTalentLevel,
        talent_schedule = self.m_iTalentSchedule
    })
end

--工作台
CWorkDesk = {}
CWorkDesk.__index = CWorkDesk
inherit(CWorkDesk,datactrl.CDataCtrl)

function CWorkDesk:New(iPos)
    local o = super(CWorkDesk).New(self)
    o.m_iPos = iPos
    o.m_iLockStatus = defines.LOCK_STATUS.LOCKED
    o.m_iStatus = defines.WORKDESK_STATUS.FREE
    o.m_iTalentTime = 0
    o.m_iRewardSid = 0
    o.m_lReward = {}
    return o
end

function CWorkDesk:Load(mData)
    mData = mData or {}
    self.m_iLockStatus = mData["lock_status"] or self.m_iLockStatus
    self.m_iTalentTime = mData["talent_time"] or self.m_iTalentTime
    self.m_iRewardSid = mData["reward_item"] or self.m_iRewardSid
    self.m_lReward = mData["reward"] or self.m_lReward
    -- self:Setup()
end

function CWorkDesk:Save()
    local mData = {}
    mData["lock_status"] = self.m_iLockStatus
    mData["talent_time"] = self.m_iTalentTime
    mData["reward_item"] = self.m_iRewardSid
    mData["reward"] = self.m_lReward
    return mData
end

function CWorkDesk:Setup()
    local iCurTime = get_time()
    if self.m_iTalentTime > 0 then
        self.m_iStatus = defines.WORKDESK_STATUS.TALENT_SHOW
        local iPid = self:GetOwner()
        local iPos = self.m_iPos
        if iCurTime < self.m_iTalentTime then
            local iTime = self.m_iTalentTime - iCurTime
            self:AddTimeCb("TalentShow",iTime *  1000,function ()
                local oWorkDesk = defines.GetFurnitureDesk(iPid,iPos)
                if not oWorkDesk then
                    return
                end
                oWorkDesk:WaitDrawGift()
            end)
        else
            self:WaitDrawGift()
        end
    end
end

function CWorkDesk:TalentTime()
    local iTime = 0
    local iCurTime = get_time()
    if self.m_iTalentTime > 0 then
        iTime = self.m_iTalentTime - iCurTime
    end
    return iTime
end

function CWorkDesk:SetLockStatus(iStatus)
    self:Dirty()
    self.m_iLockStatus = iStatus
end

function CWorkDesk:IsLockStatus()
    if self.m_iLockStatus == defines.LOCK_STATUS.LOCKED then
        return true
    end
    return false
end

function CWorkDesk:SetOwner(iOwner)
    self.m_iOwner = iOwner
end

function CWorkDesk:GetOwner()
    return self.m_iOwner
end

function CWorkDesk:GetHouse()
    local iOwner = self:GetOwner()
    local oHouseMgr = global.oHouseMgr
    return oHouseMgr:GetHouse(iOwner)
end

function CWorkDesk:GetScene()
    local oHouse = self:GetHouse()
    return oHouse:GetScene()
end

function CWorkDesk:OpenCount()
    local mData = defines.GetWorkDeskData()[self.m_iPos]
    return mData.unlock
end

--开始才艺展示
function CWorkDesk:TalentShow(iPid)
    self:Dirty()
    local oHouse = self:GetHouse()
    local iTime = oHouse:GetTestInfo("talent_show_time")
    if not iTime then
        iTime = defines.GetDaobiaoDefines("talent_show_time") or 3600
    end
    self.m_iTalentTime = get_time() + iTime
    self.m_iStatus = defines.WORKDESK_STATUS.TALENT_SHOW
    local iPid = self:GetOwner()
    local iPos = self.m_iPos
    self:AddTimeCb("TalentShow",iTime*1000,function ()
        local oDesk = defines.GetFurnitureDesk(iPid,iPos)
        if oDesk then
            oDesk:WaitDrawGift()
        end
    end)

    self:LogTalentStatus()
end

function CWorkDesk:WaitDrawGift()
    self:Dirty()
    self.m_iStatus = defines.WORKDESK_STATUS.TALENT_GIFT
    local iOwner = self:GetOwner()
    local oHouse = self:GetHouse()
    if not oHouse then
        return
    end
    local iType = defines.FURNITURE_TYPE.WORK_DESK
    local oFurniture = oHouse:GetFurniture(iType)
    local iReward = oFurniture:GetTalentGift()
    self.m_iRewardSid = iReward
    self.m_lReward = oFurniture:GetTalentReward()
    if oHouse:InHouse(iOwner) then
        self:Refresh(iOwner)
    end

    self:LogTalentStatus()
end

function CWorkDesk:DrawGift(iPid)
    self:Dirty()
    self.m_iTalentTime = 0
    self.m_iStatus = defines.WORKDESK_STATUS.FREE
    self:Refresh(iPid)

    self:LogTalentStatus()
end

function CWorkDesk:LogTalentStatus(iStatus, iEndTime)
    record.user("house", "talent_show", {
        pid = self:GetOwner(),
        end_time = iEndTime or self.m_iTalentTime,
        status = iStatus or self.m_iStatus,
        })
end

function CWorkDesk:DrawRewardSid()
    return self.m_iRewardSid
end

function CWorkDesk:DrawRewardInfo()
    return self.m_lReward
end

function CWorkDesk:Status()
    if self.m_iStatus then
        return self.m_iStatus
    end
    if self.m_iTalentTime > 0 then
        if self.m_iTalentTime > get_time() then
            self.m_iStatus = defines.WORKDESK_STATUS.TALENT_SHOW
        else
            self.m_iStatus = defines.WORKDESK_STATUS.TALENT_GIFT
        end
    else
        self.m_iStatus = defines.WORKDESK_STATUS.FREE
    end
    return self.m_iStatus
end

function CWorkDesk:Refresh(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CRefreshWorkDesk",{
            desk_info = self:PackNetInfo(),
            owner_pid = self:GetOwner(),
        })
    end
end

function CWorkDesk:BroadCast()
    local oScene = self:GetScene()
    oScene:BroadCast("GS2CRefreshWorkDesk",{
        desk_info = self:PackNetInfo(),
        owner_pid = self:GetOwner(),
    })
end

function CWorkDesk:PackNetInfo()
    local iTime = math.max(self.m_iTalentTime-get_time(),0)
    local oHouse = self:GetHouse()
    return {
        pos = self.m_iPos,
        lock_status = self.m_iLockStatus,
        status = self.m_iStatus,
        talent_time = iTime,
        item_sid = self.m_iRewardSid,
        speed_num =oHouse:GetWorkDeskBuy(self.m_iPos),
    }
end

--好友工作台
CFriendWorkDesk = {}
CFriendWorkDesk.__index = CFriendWorkDesk
inherit(CFriendWorkDesk,CWorkDesk)

function CFriendWorkDesk:New()
    local o = super(CFriendWorkDesk).New(self)
    o.m_iLockStatus = defines.LOCK_STATUS.UNLOCKED
    o.m_iFriend = 0
    return o
end

function CFriendWorkDesk:Load(mData)
    self.m_iFriend = mData["friend"] or self.m_iFriend
    super(CFriendWorkDesk).Load(self,mData)
end

function CFriendWorkDesk:Save()
    local mData = super(CFriendWorkDesk).Save(self)
    mData["friend"] = self.m_iFriend
    return mData
end

function CFriendWorkDesk:Setup()
    local iCurTime = get_time()
    if self.m_iTalentTime > 0 then
        self.m_iStatus = defines.WORKDESK_STATUS.TALENT_SHOW
        if iCurTime < self.m_iTalentTime then
            local iTime = self.m_iTalentTime - iCurTime
            local iPid = self:GetOwner()
            self:AddTimeCb("AutoDrawGift",iTime *  1000,function ()
                local oFriendDesk = defines.GetFriendDesk()
                if oFriendDesk then
                    oFriendDesk:AutoDrawGift()
                end
            end)
        else
            self:AutoDrawGift()
        end
    else
        self.m_iFriend = 0
    end
end

--使用中
function CFriendWorkDesk:IsUsing()
    if self.m_iFriend ~= 0 then
        return true
    end
    return false
end

function CFriendWorkDesk:IsLockStatus()
    return false
end

function CFriendWorkDesk:FrdPid()
    return self.m_iFriend
end

function CFriendWorkDesk:UseFriendWorkDesk(iPid)
    local oWorldMgr = global.oWorldMgr
    local oFriendMgr = global.oFriendMgr

    self:Dirty()
    self.m_iFriend = iPid
    local oHouse = self:GetHouse()
    local iSecs = oHouse:GetTestInfo("use_friend_desk_second")
    if not iSecs then
        iSecs = defines.GetDaobiaoDefines("use_friend_desk_second")
    end

    self.m_iTalentTime = get_time() + iSecs
    self.m_iStatus = defines.WORKDESK_STATUS.TALENT_SHOW
    local iOwner = self:GetOwner()
    self:AddTimeCb("AutoDrawGift",iSecs*1000,function ()
        local oFriendDesk = defines.GetFriendDesk(iOwner)
        if oFriendDesk then
            oFriendDesk:AutoDrawGift()
        end
    end)
    self:BroadCast()
    self:Refresh(iPid)
    local iDegree = defines.GetDaobiaoDefines("friend_work_desk_degree")
    oFriendMgr:AddFriendDegree(iOwner, iPid, iDegree)
    record.user("house", "use_friend_desk", {
        pid = iOwner,
        frd_pid = iPid,
        end_time = self.m_iTalentTime,
        })
end

function CFriendWorkDesk:AutoDrawGift()
    self:Dirty()
    local iOwner = self:GetOwner()
    local oHouseMgr = global.oHouseMgr
    oHouseMgr:HouseAutoDrawGift(iOwner,self.m_iFriend)
    self.m_iFriend = 0
    self.m_iTalentTime = 0
    self.m_iStatus = defines.WORKDESK_STATUS.FREE
    self:BroadCast()
end

function CFriendWorkDesk:AddSpeed(iPid)
    self:Dirty()
    local sKey = "talent_speed_time"
    local iMin = defines.GetDaobiaoDefines(sKey)
    -- local iMin = mData["value"]
    local iDelSec = iMin * 60
    self:DelTimeCb("AutoDrawGift")
    local iTotalSec = self.m_iTalentTime - get_time()
    iTotalSec = iTotalSec - iDelSec
    self.m_iTalentTime = math.max(self.m_iTalentTime - iDelSec, 0)
    if iTotalSec > 0 then
        local iOwner = self:GetOwner()
        self:AddTimeCb("AutoDrawGift",iTotalSec*1000,function ()
            local oFriendDesk = defines.GetFriendDesk(iPid)
            if oFriendDesk then
                oFriendDesk:AutoDrawGift()
            end
        end)
    else
        self:AutoDrawGift()
    end
    self:BroadCast()
    global.oNotifyMgr:Notify(iPid, string.format("加油成功，制作时间减少%s秒", iDelSec))
    -- self:Refresh(iPid)
end

function CFriendWorkDesk:Refresh(iPid)
    iPid = iPid or self.m_iFriend
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CRefreshWorkDesk",{
            desk_info = self:PackNetInfo(),
            owner_pid = self:GetOwner(),
        })
    end
end

function CFriendWorkDesk:PackNetInfo()
    local iDefaultPos = 4
    local iTime = math.max(self.m_iTalentTime-get_time(),0)
    return {
        pos = iDefaultPos,
        lock_status = self.m_iLockStatus,
        status = self.m_iStatus,
        talent_time = iTime,
        frd_pid = self.m_iFriend,
        -- friend_name = self.m_sFriendName,
    }
end


--物品柜
CWareHouse = {}
CWareHouse.__index = CWareHouse
inherit(CWareHouse,CFurniture)

function CWareHouse:New(iType)
    local o = super(CWareHouse).New(self,iType)
    return o
end

function CWareHouse:PromoteEffect()
end

--电力锅
CPan = {}
CPan.__index = CPan
inherit(CPan,CFurniture)

function CPan:New(iType)
    local o = super(CPan).New(self,iType)
    return o
end

function CPan:PromoteEffect()
end

--秘籍书籍
CBook = {}
CBook.__index = CBook
inherit(CBook,CFurniture)

function CBook:New(iType)
    local o = super(CBook).New(self,iType)
    return o
end

function CBook:PromoteEffect()
end

CFurnitureCtrl = {}
CFurnitureCtrl.__index = CFurnitureCtrl
inherit(CFurnitureCtrl,datactrl.CDataCtrl)

function CFurnitureCtrl:New(iPid)
    local o = super(CFurnitureCtrl).New(self,iPid)
    o.m_iOwner = iPid
    o.m_mList = {}
    o:Init()
    return o
end

function CFurnitureCtrl:Init()
    local iPid = self.m_iOwner
    local mFurniture = {
        [defines.FURNITURE_TYPE.SOFA] = CSofa,
        [defines.FURNITURE_TYPE.WORK_DESK] = CWorkDeskFurniture,
        [defines.FURNITURE_TYPE.CWAREHOUSE] = CWareHouse,
        [defines.FURNITURE_TYPE.CPAN] = CPan,
        [defines.FURNITURE_TYPE.CBOOK] = CBook,
    }
    for iType,oClass in pairs(mFurniture) do
        local oFurniture = oClass:New(iType)
        self.m_mList[iType] = oFurniture
        oFurniture:SetOwner(iPid)
    end
end

function CFurnitureCtrl:Release()
    for iType,oFurniture in pairs(self.m_mList) do
        baseobj_safe_release(oFurniture)
    end
    self.m_mList = {}
    super(CFurnitureCtrl).Release(self)
end

function CFurnitureCtrl:Load(mData)
    mData = mData or {}
    local mFurniture = mData["furniture"] or {}
    for iType,mData in pairs(mFurniture) do
        local oFurniture = self.m_mList[iType]
        oFurniture:Load(mData)
    end
    self.m_iFriendDesk = mData["friend_desk"] or self.m_iFriendDesk
end

function CFurnitureCtrl:Save()
    local mData = {}
    local mFurniture = {}
    for iType,oFurniture in ipairs(self.m_mList) do
        mFurniture[iType] = oFurniture:Save()
    end
    mData["furniture"] = mFurniture
    mData["friend_desk"] = self.m_iFriendDesk
    return mData
end

function CFurnitureCtrl:Setup()
    for iType, oFurniture in pairs(self.m_mList) do
        if oFurniture.Setup then
            oFurniture:Setup()
        end
    end
end

function CFurnitureCtrl:GetFurniture(iType)
    return self.m_mList[iType]
end

function CFurnitureCtrl:PromoteLevel(iPid,iType)
    local oFurniture = self:GetFurniture(iType)
    oFurniture:PromoteLevel()
end

function CFurnitureCtrl:GetLockData()
    local res = require "base.res"
    return res["daobiao"]["furniture_lock"]
end

function CFurnitureCtrl:OnPromoteLevel(oFurniture)
    if oFurniture:IsMainFurniture() then
        local iLevel = oFurniture:Level()
        local mLockData = self:GetLockData()
        for _,mData in pairs(mLockData) do
            local iLockLevel = mData["level"]
            if iLevel >= iLockLevel then
                local mTypeData = mData["type_list"] or {}
                for _,iType in pairs(mTypeData) do
                    local oLockFurniture = self:GetFurniture(iType)
                    if oLockFurniture:IsLockStatus() then
                        oLockFurniture:SetLockStatus(defines.LOCK_STATUS.UNLOCKED)
                    end
                end
            end
        end
    end
end

function CFurnitureCtrl:ProduceWarm()
    local iWarm = 0
    for _,oFurniture in pairs(self.m_mList) do
        iWarm = iWarm + oFurniture:ProduceWarm()
    end
    return iWarm
end

function CFurnitureCtrl:TalentLevel()
    local iType = defines.FURNITURE_TYPE.WORK_DESK
    local oFurniture = self:GetFurniture(iType)
    return oFurniture:TalentLevel()
end

function CFurnitureCtrl:TalentSchedule()
    local iType = defines.FURNITURE_TYPE.WORK_DESK
    local oFurniture = self:GetFurniture(iType)
    return oFurniture:TalentSchedule()
end

function CFurnitureCtrl:SetFriendDeskPid(iFrdPid)
    self:Dirty()
    self.m_iFriendDesk = iFrdPid
end

function CFurnitureCtrl:GetFriendDeskPid()
    return self.m_iFriendDesk
end

function CFurnitureCtrl:IsUsingFriendDesk()
    if self.m_iFriendDesk and self.m_iFriendDesk > 0 then
        return true
    end
    return false
end

function CFurnitureCtrl:PackNetInfo()
    local mData = {}
    for _,oFurniture in pairs(self.m_mList) do
        table.insert(mData,oFurniture:PackNetInfo())
    end
    return mData
end

function CFurnitureCtrl:IsDirty()
    local bFlag = super(CFurnitureCtrl).IsDirty(self)
    if bFlag then
        return true
    end
    for _,oFurniture in pairs(self.m_mList) do
        if oFurniture:IsDirty() then
            return true
        end
    end
    return false
end

function CFurnitureCtrl:UnDirty()
    super(CFurnitureCtrl).UnDirty(self)
    for _,oFurniture in pairs(self.m_mList) do
        oFurniture:UnDirty()
    end
end

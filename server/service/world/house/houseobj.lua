--import module

local global = require "global"
local res = require "base.res"
local interactive = require "base.interactive"
local record = require "public.record"
local colorstring = require "public.colorstring"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))
local furniturectrl = import(service_path("house.furniturectrl"))
local itemctrl = import(service_path("house.itemctrl"))
local partnerctrl = import(service_path("house.partnerctrl"))
local timectrl = import(lualib_path("public.timectrl"))
local defines = import(service_path("house.defines"))
local loaditem = import(service_path("item.loaditem"))
local gamedefines = import(lualib_path("public.gamedefines"))

CHouse = {}
CHouse.__index = CHouse
inherit(CHouse,datactrl.CDataCtrl)

function CHouse:New(iPid)
    local o = super(CHouse).New(self)
    o.m_iOwner = iPid
    o.m_mWaitFuncList = {}
    o.m_bLoading = true
    o.m_oItemCtrl = itemctrl.CItemCtrl:New(iPid)
    o.m_oFurnitureCtrl = furniturectrl.CFurnitureCtrl:New(iPid)
    o.m_oPartnerCtrl = partnerctrl.CPartnerCtrl:New(iPid)
    o.m_oToday = timectrl.CToday:New(iPid)
    o.m_iWarmDegree = 0                                                                 --温馨度
    o:Init()
    return o
end

function CHouse:Init()
    local iSceneType = 1021
    local mScene = res["daobiao"]["scene"]
    local oSceneMgr = global.oSceneMgr
    local mData = mScene[iSceneType]
    assert(mData, string.format("scene config:%s not exist!", iSceneType))
    local mArgs = {
        map_id = mData.map_id,
        scene_type = iSceneType,
        scene_name = mData.scene_name,
    }
    local oScene = oSceneMgr:CreateVirtualScene(mArgs)
    self.m_iSceneId = oScene:GetSceneId()
end

function CHouse:NewDay(iWeekDay)
    self.m_oPartnerCtrl:NewDay(iWeekDay)
end

function CHouse:Release()
    baseobj_safe_release(self.m_oItemCtrl)
    baseobj_safe_release(self.m_oFurnitureCtrl)
    baseobj_safe_release(self.m_oToday)
    local oSceneMgr = global.oSceneMgr
    oSceneMgr:RemoveScene(self.m_iSceneId)
    super(CHouse).Release(self)
end

function CHouse:Load(mData)
    mData = mData or {}
    local mItemData = mData["item"] or {}
    self.m_oItemCtrl:Load(mItemData)
    local mFurniture = mData["furniture"] or {}
    self.m_oFurnitureCtrl:Load(mFurniture)
    local mPartner = mData["partner"] or {}
    self.m_oPartnerCtrl:Load(mPartner)
    self.m_iWarmDegree = mData["warm_degree"] or self.m_iWarmDegree
    local mTodayData = mData["today"] or {}
    self.m_oToday:Load(mTodayData)
end

function CHouse:Save()
    local mData = {}
    local mItemData = self.m_oItemCtrl:Save()
    mData["item"] = mItemData
    local mFurniture = self.m_oFurnitureCtrl:Save()
    mData["furniture"] = mFurniture
    local mPartner = self.m_oPartnerCtrl:Save()
    mData["partner"] = mPartner
    mData["warm_degree"] = self.m_iWarmDegree
    mData["today"] = self.m_oToday:Save()
    return mData
end

function CHouse:AddWaitFunc(func)
    table.insert(self.m_mWaitFuncList,func)
end

function CHouse:WakeUpFunc()
    for _,fCallBack in ipairs(self.m_mWaitFuncList) do
        fCallBack(self)
    end
    self.m_iLastTime = get_time()
end

function CHouse:IsLoading()
    return self.m_bLoading
end

function CHouse:IsActive()
    local iNowTime = get_time()
    if iNowTime - self.m_iLastTime <= 10 * 60 then
        return true
    end
    return false
end

function CHouse:ConfigSaveFunc()
    local iPid = self:GetOwner()
    self:ApplySave(function ()
        local oHouseMgr = global.oHouseMgr
        local oHouse = oHouseMgr:GetHouse(iPid)
        if not oHouse then
            record.warning(string.format("%s house save err:",iPid))
            return
        end
        oHouse:SaveDb()
    end)
end

function CHouse:GetOwner()
    return self.m_iOwner
end

function CHouse:IsOwner(iPid)
    if self.m_iOwner == iPid then
        return true
    end
    return false
end

function CHouse:GetScene()
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(self.m_iSceneId)
    return oScene
end

function CHouse:InHouse(iPid)
    local oScene = self:GetScene()
    local mPlayers = oScene:GetPlayers()
    if table_in_list(mPlayers,iPid) then
        return true
    end
    return false
end

--产生温馨度
function CHouse:ProduceWarm()
    local iWarm = defines.GetDaobiaoDefines("warm_degree_cycle")
    iWarm = iWarm + self.m_oFurnitureCtrl:ProduceWarm()
    local iLimitWarm = self:GetWarmDegreeLimit()
    if self.m_iWarmDegree >= iLimitWarm then
        return
    end
    self:Dirty()
    self.m_iWarmDegree = self.m_iWarmDegree + iWarm + self.m_oFurnitureCtrl:ProduceWarm()
    if self.m_iWarmDegree > iLimitWarm then
        self.m_iWarmDegree = iLimitWarm
    end
    local iPid = self.m_iOwner
    if self:InHouse(iPid) then
        self:RefreshWarm(iPid)
    end
end

function CHouse:GetWarmDegreeLimit()
    local iLimitWarm = defines.GetDaobiaoDefines("warm_degree_limit")
    iLimitWarm = iLimitWarm + self.m_oPartnerCtrl:PromoteWarmLimit()
    return iLimitWarm
end

function CHouse:EnterHouse(iPid)
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mPos = {
        x = 0,
        y = 0,
        z = 0,
        face_x = 0,
        face_y = 0,
        face_z = 0,
    }
    oSceneMgr:EnterScene(oPlayer,self.m_iSceneId , {pos = mPos}, true)
    local mData = {
        furniture_info = self.m_oFurnitureCtrl:PackNetInfo(),
        partner_info = self.m_oPartnerCtrl:PackNetInfo(),
        item_info = self.m_oItemCtrl:PackNetInfo(),
        warm_degree = self.m_iWarmDegree,
        max_warm_degree = self:GetWarmDegreeLimit(),
        max_train = self.m_oPartnerCtrl:TrainSpace(),
        owner_pid = self:GetOwner(),
        talent_level = self:TalentLevel(),
        buff_info = self.m_oPartnerCtrl:PackHouseBuff(),
    }
    oPlayer:Send("GS2CEnterHouse",mData)
    if self:GetOwner() == iPid then
        self.m_oPartnerCtrl:OnEnter(iPid)
    end
    self:DailyVisit(iPid)
end

function CHouse:DailyVisit(iTarget)
    local oWorldMgr = global.oWorldMgr
    local oFriendMgr = global.oFriendMgr

    local iOwner = self:GetOwner()
    if iOwner ~= iTarget then
        local iDegree = defines.GetDaobiaoDefines("visit_degree")
        local mVisit = self.m_oToday:Query("visit", {})
        local iVisit = table_count(mVisit)
        local iMaxVisit = defines.GetDaobiaoDefines("daily_visit")
        if not mVisit[iTarget] and iVisit < iMaxVisit then
            mVisit[iTarget] = 1
            self.m_oToday:Set("visit", mVisit)
            oFriendMgr:AddFriendDegree(iOwner, iTarget, iDegree)
        end
        global.oAchieveMgr:PushAchieve(iTarget, "拜访好友宅邸", {value = 1})
    end
end

function CHouse:LeaveHouse(iPid)
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local mDurableInfo = oPlayer.m_oActiveCtrl:GetDurableSceneInfo()
    local iMapId = mDurableInfo.map_id
    local mPos = mDurableInfo.pos
    local oScene = oSceneMgr:SelectDurableScene(iMapId)
    oSceneMgr:EnterScene(oPlayer, oScene:GetSceneId(), {pos = mPos}, true)
end

function CHouse:GetFurniture(iType)
    local oFurnitureCtrl = self.m_oFurnitureCtrl
    return oFurnitureCtrl:GetFurniture(iType)
end

function CHouse:TalentLevel()
    return self.m_oFurnitureCtrl:TalentLevel()
end

function CHouse:OnPromoteLevel(oFurntire)
    self.m_oFurnitureCtrl:OnPromoteLevel(oFurntire)
end

function CHouse:AutoDrawGift(iGiftItem,iFrdPid)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local oItem = loaditem.Create(iGiftItem)
    local iAmount = 1
    oItem:SetAmount(iAmount)
    self:AddItem(oItem,"AutoDrawGift")
    self.m_oFurnitureCtrl:SetFriendDeskPid(nil)

    local iOwner = self:GetOwner()
    local iQuality = oItem:Quality()
    local sItemName = oItem:Name()
    oWorldMgr:LoadProfile(iFrdPid, function(oProfile)
        if oProfile then
            local sItem = string.format(loaditem.FormatItemColor(iQuality,"%s"), sItemName)
            local sMsg = "#role好友工作台料理已完成，您获得了#item"
            sMsg = colorstring.FormatColorString(sMsg, {role = oProfile:GetName(), item = sItem})
            oNotifyMgr:Notify(iOwner, sMsg)
        end
    end)

    record.user("house", "friend_desk_reward", {
        pid = iOwner,
        frd_pid = iFrdPid,
        sid = iGiftItem,
        amount = iAmount,
        })

    oWorldMgr:LoadProfile(iOwner, function(oProfile)
        if oProfile then
            local mItem = {}
            mItem[iGiftItem] = iAmount
            local mLog = {}
            -- mLog["frd_pid"] = iFrdPid
            -- mLog["operation"] = "friend_house_furniture"
            oProfile:LogAnalyGame(mLog,"house",mItem,{},{},0)
        end
    end)
end

function CHouse:AutoDrawCoin(iCoin)
    if iCoin > 0 then
        local iOwner = self:GetOwner()
        local iMailId = 28
        local oMailMgr = global.oMailMgr
        local mMail, sMail = oMailMgr:GetMailInfo(iMailId)
        oMailMgr:SendMail(0, sMail, iOwner, mMail, {{sid=gamedefines.COIN_FLAG.COIN_COIN, value = 1000}})
    end
end

function CHouse:OpenExchangeUI(iPid)
    -- self.m_oPartnerCtrl:OpenExchangeUI(iPid)
end

function CHouse:AddPartner(oPartner, sReason, mArgs)
    mArgs = mArgs or {}
    self.m_oPartnerCtrl:AddPartner(oPartner, sReason)
    if not mArgs.cancel_show then
        self:ShowAddPartner(oPartner:Type())
    end
    local oFurniture = self:GetFurniture(defines.FURNITURE_TYPE.WORK_DESK)
    oFurniture:CheckUnlockDesk(true)
end

function CHouse:GetPartner(iType)
    return self.m_oPartnerCtrl:GetPartner(iType)
end

function CHouse:ShowLove(iPid,iType,sPart)
    if not self.m_oPartnerCtrl:ValidShowLove(iPid,iType) then
        return
    end
    self.m_oPartnerCtrl:ShowLove(iPid,iType,sPart)
end

function CHouse:TrainPartner(iType,iTrainType)
    if not self.m_oPartnerCtrl:ValidTrainPartner(iType,iTrainType) then
        return
    end
    self.m_oPartnerCtrl:TrainPartner(iType,iTrainType)
end

function CHouse:GivePartnerGift(iPid,iType,iItemid)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        -- record.warning("CHouse:GivePartnerGift, pid:%s offline", iPid)
        return
    end
    local oPartner = self.m_oPartnerCtrl:GetPartner(iType)
    if not oPartner then
        -- record.warning("CHouse:GivePartnerGift, partner:%s not exist!", iType)
        return
    end
    local oItem = self.m_oItemCtrl:HasItem(iItemid)
    if not oItem then
        -- record.warning("CHouse:GivePartnerGift, item:%s not exist!", iItemid)
        return
    end
    local iMaxCnt = defines.PARTNER_MAX_GIFT_CNT
    local iRemain = self:ParnterGiftCnt()
    if iRemain <= 0 then
        return
    end
    local sReason = "伙伴送礼物"
    self.m_oToday:Add("partner_gift_cnt",1)
    local iLastCnt = self:ParnterGiftCnt()
    local iLoveShip = oItem:GetLoveShip()
    local iShape = oItem:SID()
    self.m_oItemCtrl:AddAmount(oItem,-1, sReason)
    oPartner:AddLoveShip(iLoveShip, sReason)
    oPartner:Refresh(iPid)
    self.m_oPartnerCtrl:SendPartnerExchangeUI()
    oPlayer:Send("GS2CGivePartnerGift", {})

    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30032, 1)
    --pid|玩家id,partype|伙伴id,old_cnt|原来次数,remain_cnt|剩余次数,sid|道具导表id
    record.user("house", "give_partner_gift", {
        pid = iPid,
        partype = iType,
        old_cnt =iRemain,
        remain_cnt =iLastCnt,
        sid =iShape,
        })
end

function CHouse:ParnterGiftCnt()
    local iMaxCnt = defines.PARTNER_MAX_GIFT_CNT
    local iBuy = self.m_oToday:Query("daily_buy_giftcnt", 0)
    local iUse = self.m_oToday:Query("partner_gift_cnt", 0)
    return math.max(0, iMaxCnt + iBuy - iUse)
end

function CHouse:AddItem(oItem,sReason)
    if not self.m_oItemCtrl:ValidAddItem(oItem) then
        return
    end
    return self.m_oItemCtrl:AddItem(oItem,sReason)
end

function CHouse:RefreshWarm(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CRefreshHouseWarm",{
        warm_degree = self.m_iWarmDegree,
        max_warm_degree = self:GetWarmDegreeLimit(),
    })
end

function CHouse:UnChainPartnerReward(oPlayer, iParType, iLevel)
    local oPartner = self:GetPartner(iParType)
    if not oPartner then
        record.info("UnChainPartnerReward, pid:%s, partype:%s", oPlayer:GetPid(), iParType)
        return
    end
    if not oPartner:ValidUnChainRewardLevel(iLevel) then
        return
    end
    local mData = oPartner:GetParterTaskData(iLevel) or {}
    local mItemData = mData.item or {}
    local lItem = {}
    local mItem = {}
    for _,mData in pairs(mItemData) do
        local iShape = mData["sid"]
        local iAmount = mData["amount"]
        table.insert(lItem, {iShape, iAmount})
        mItem[iShape] = (mItem[iShape] or 0) + iAmount
    end
    if next(lItem) and not oPlayer.m_oItemCtrl:ValidGive(lItem) then
        -- oPlayer:NotifyMessage("背包已满")
        return
    end
    local iPid = oPlayer:GetPid()
    local oHouseMgr = global.oHouseMgr
    if next(lItem) then
        local fCallBack = function (mRecord,mData)
            local oHouse = oHouseMgr:GetHouse(iPid)
            if oHouse then
                oHouse:TrueUnChainPartnerReward(iPid, iParType, iLevel, mData, mItem)
            end
        end
        oPartner:UnChainRewardLevel(oPlayer:GetPid(), iLevel)
        oPlayer:GiveItem(lItem,"领取宅邸伙伴等级奖励",{},fCallBack)
    end
end

function CHouse:TrueUnChainPartnerReward(iPid, iParType, iLevel, mData, mRwd)
    local bSuc = mData.success
    local oPartner = self:GetPartner(iParType)
    if not oPartner then
        return
    end
    if not bSuc then
        record.error("TrueUnChainPartnerReward fail !")
        oPartner:RemoveUnChainLevel(iPid, iLevel)
        return
    end
    -- oPartner:UnChainRewardLevel(iPid, iLevel)
    --pid|玩家id,partype|伙伴id,level|等级,reward|奖励信息
    record.user("house", "partner_level_reward", {
        pid = iPid,
        partype = iParType,
        level = iLevel,
        reward = ConvertTblToStr(mRwd),
        })
end

function CHouse:RecievePartnerTrain(oPlayer, iParType)
    local oPartner = self:GetPartner(iParType)
    if not oPartner then
        return
    end
    if not oPartner:ValidRecieveTrain() then
        return
    end
    oPartner:RecieveTrainReward()
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30005, 1)
end

function CHouse:RecievePartnerCoin(iFrdPid, iParType)
    local oFrd = global.oWorldMgr:GetOnlinePlayerByPid(iFrdPid)
    if self.m_oPartnerCtrl:ValidPartnerCoin(iFrdPid) then
        self.m_oPartnerCtrl:RecievePartnerCoin(iFrdPid)
    end
    if oFrd then
        local mNet = {}
        mNet.status = 0
        mNet.frd_pid = self:GetOwner()
        if self.m_oPartnerCtrl:WithCoinPartner() then
            mNet.status = 1
        end
        oFrd:Send("GS2CRecieveHouseCoin", mNet)
    end
end

function CHouse:ValidUseFriendWorkDesk(iFrdPid)
    local iType = defines.FURNITURE_TYPE.WORK_DESK
    local oFurniture = self:GetFurniture(iType)
    return oFurniture:ValidUseFriendWorkDesk(iFrdPid)
end

function CHouse:TrueUseFriendWorkDesk(iFrdPid)
    local iOwner = self:GetOwner()
    self.m_oToday:Add("use_friend_desk", 1)
    self.m_oFurnitureCtrl:SetFriendDeskPid(iFrdPid)
    record.user("house", "daily_friend_desk", {
        pid = iOwner,
        frd_pid = iFrdPid,
        count = self.m_oToday:Query("use_friend_desk", 0),
        })
end

function CHouse:CountPartner()
    return self.m_oPartnerCtrl:CountPartner()
end

function CHouse:PackHouseProfile(iFrdPid)
    local mNet = {}
    mNet["frd_pid"] = self:GetOwner()
    mNet["talent_level"] = self:TalentLevel()
    mNet["coin"] = 0
    local o = self.m_oPartnerCtrl:WithCoinPartner()
    if o then
        mNet["coin"] = o:GetCoin()
    end
    mNet["desk_empty"] = self:PackFriendDeskStatus(iFrdPid)
    -- if self:ValidUseFriendWorkDesk(iFrdPid) then
    --     mNet["desk_empty"] = 1
    -- end
    return mNet
end

function CHouse:PackFriendDeskStatus(iFrdPid)
    local iStatus = 0
    local oFrdHouse = global.oHouseMgr:GetHouse(iFrdPid)
    if oFrdHouse then
        local oFCtrl = oFrdHouse.m_oFurnitureCtrl
        if oFCtrl:GetFriendDeskPid() == self:GetOwner() then
            iStatus = 1
        elseif oFCtrl:IsUsingFriendDesk() then
            iStatus = 0
        elseif self:ValidUseFriendWorkDesk(iFrdPid) then
            iStatus = 1
        end
    end
    return iStatus
end

function CHouse:GetWorkDeskBuy(iPos)
    local mBuy = self.m_oToday:Query("daily_desk_buy", {})
    return mBuy[iPos] or 0
end

function CHouse:AddWorkDeskBuyCnt(iPos, iAdd)
    assert(iAdd > 0, "AddWorkDeskBuyCnt")
    local mBuy = self.m_oToday:Query("daily_desk_buy", {})
    local iBuy = mBuy[iPos] or 0
    mBuy[iPos] = iBuy + iAdd
    self.m_oToday:Set("daily_desk_buy", mBuy)
    self:Dirty()
end

function CHouse:GetGiftBuyCnt()
    return self.m_oToday:Query("daily_buy_giftcnt", 0)
end

function CHouse:AddPartnerGiftCnt(oPlayer, iAdd, iCheck)
    if iAdd <= 0 then
        return
    end
    local sReason = "购买送礼次数"
    local iHaveAdd = self:GetGiftBuyCnt()
    local iCost = self:PartnerGiftCost(iAdd + iHaveAdd)
    if iCost ~= iCheck then
        oPlayer:NotifyMessage("价格变动")
        return
    end
    if oPlayer:ValidGoldCoin(iCost, {cancel_tip = 1}) then
        oPlayer:ResumeGoldCoin(iCost,sReason,{})
        self.m_oToday:Set("daily_buy_giftcnt", iHaveAdd + iAdd)
        self.m_oPartnerCtrl:SendPartnerExchangeUI()
    end
end

function CHouse:PartnerGiftCost(iDailyAdd)
    local res = require "base.res"
    local iMaxCost = tonumber(res["daobiao"]["global"]["house_gift_count_max_cost"]["value"])
    local sCost = res["daobiao"]["global"]["house_gift_count_cost"]["value"]
    local iCost = formula_string(sCost, {n = iDailyAdd})
    return math.min(iMaxCost, math.ceil(iCost))
end

function CHouse:ShowAddPartner(iParType)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetOwner())
    if oPlayer then
        oPlayer:Send("GS2CAddHousePartner", {
            type = iParType,
            })
    end
end

function CHouse:LoadFinish()
    self.m_oPartnerCtrl:Setup()
    self.m_oFurnitureCtrl:Setup()
end

function CHouse:Schedule()
    local iPid = self:GetOwner()
    local oHouseMgr = global.oHouseMgr
    local f1
    f1 = function ()
        local oHouse = oHouseMgr:GetHouse(iPid)
        if oHouse then
            oHouse:DelTimeCb("_CheckClean")
            oHouse:AddTimeCb("_CheckClean", 5*60*1000, f1)
            oHouse:_CheckClean()
        end
    end
    f1()
    local iMin = defines.GetDaobiaoDefines("warm_degree_cycle_time")
    local f2
    f2 = function ()
        local oHouse = oHouseMgr:GetHouse(iPid)
        if oHouse then
            oHouse:DelTimeCb("ProduceWarm")
            oHouse:AddTimeCb("ProduceWarm",iMin*60*1000,f2)
            oHouse:ProduceWarm()
        end
    end
    f2()
end

function CHouse:SaveDb()
    if self:IsDirty() then
        self:UnDirty()
        local mData = {
            pid = self:GetOwner(),
            data = self:Save()
        }
        gamedb.SaveDb(self:GetOwner(),"common", "SaveDb", {module="house",cmd="SaveHouse",data=mData})
    end
end

function CHouse:_CheckClean()
    if self.m_bLoading then
        return
    end
    local oScene = self:GetScene()
    local lPlayer = oScene:GetPlayers()
    if #lPlayer > 0 then
        return
    end
    if self:IsActive() then
        return
    end
    local oHouseMgr = global.oHouseMgr
    oHouseMgr:RemoveHouse(self.m_iOwner)
end

function CHouse:IsDirty()
    local bDirty = super(CHouse).IsDirty(self)
    if bDirty then
        return true
    end
    if self.m_oPartnerCtrl:IsDirty() then
        return true
    end
    if self.m_oFurnitureCtrl:IsDirty() then
        return true
    end
    if self.m_oItemCtrl:IsDirty() then
        return true
    end
    if self.m_oToday:IsDirty() then
        return true
    end
    return false
end

function CHouse:UnDirty()
    super(CHouse).UnDirty(self)
    self.m_oPartnerCtrl:UnDirty()
    self.m_oFurnitureCtrl:UnDirty()
    self.m_oItemCtrl:UnDirty()
    self.m_oToday:UnDirty()
end

function CHouse:TestOP(oPlayer,iCmd,...)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local mArgs = {...}
    if iCmd == 100 then
        oNotifyMgr:Notify(iPid,"101　伙伴类型 经验值--增加伙伴亲密度经验值")
        oNotifyMgr:Notify(iPid,"102　--重置爱抚次数")
        oNotifyMgr:Notify(iPid,"103　--重置送礼物次数")
        oNotifyMgr:Notify(iPid,"104　经验值--增加才艺经验值")
        oNotifyMgr:Notify(iPid,"105　家具类型　提升等级--提升家具等级")
        oNotifyMgr:Notify(iPid,"106 道具编号 道具数目--克隆宅邸道具")
        oNotifyMgr:Notify(iPid, "107 时间 --设置伙伴特训时间，单位秒")
    elseif iCmd == 101 then
        if #mArgs < 2 then
            oNotifyMgr:Notify(iPid,"参数输入错误")
            return
        end
        local iParType,iVal = table.unpack(mArgs)
        local oPartner = self:GetPartner(iParType)
        if oPartner then
            oPartner:AddLoveShip(iVal, "gm")
            oPartner:Refresh(iPid)
        end
    elseif iCmd == 102 then
        local iMaxCnt = defines.PARTNER_MAX_LOVE_CNT
        local oPartnerCtrl = self.m_oPartnerCtrl
        oPartnerCtrl:AddLoveCnt(iMaxCnt, "gm")
    elseif iCmd == 103 then
        oPlayer.m_oToday:Set("partner_gift_cnt",nil)
    elseif iCmd == 104 then
        local iType = defines.FURNITURE_TYPE.WORK_DESK
        local oFurniture = self:GetFurniture(iType)
        if not oFurniture then
            oNotifyMgr:Notify(iPid,"没有该家具")
            return
        end
        if #mArgs <= 0 then
            return
        end
        local iVal = table.unpack(mArgs)
        oFurniture:AddSchedule(iVal)
        oFurniture:RefreshTalent(iPid)
    elseif iCmd == 105 then
        local iType,iLevel = table.unpack(mArgs)
        local oFurniture = self:GetFurniture(iType)
        if not oFurniture then
            oNotifyMgr:Notify(iPid,"没有该家具")
            return
        end
        iLevel = iLevel or 1
        oFurniture:TruePromoteLevel(iLevel)
    elseif iCmd == 106 then
        local iItem,iAmount = table.unpack(mArgs)
    elseif iCmd == 107  then
        local iVal = table.unpack(mArgs)
        local iTrainTime = self:GetTestInfo("partner_train_time")
        if iTrainTime then
            self:SetTestInfo("partner_train_time", nil)
            oNotifyMgr:Notify(iPid, "gm取消伙伴训练时间")
        else
            if type(iVal) == "number" and iVal > 0 then
                self:SetTestInfo("partner_train_time", iVal)
                oNotifyMgr:Notify(iPid, string.format("gm设置伙伴训练时间:%s秒", iVal))
            end
        end
    elseif iCmd == 108 then
        local res = require "base.res"
        local iType = table.unpack(mArgs)
        local m = res["daobiao"]["housepartner"]
        if m[iType] then
            if not self:GetPartner(iType) then
                local oPartner = partnerctrl.NewPartner(iType)
                self:AddPartner(oPartner, "gm")
                oPartner:BroadCast()
                oNotifyMgr:Notify(iPid, string.format("添加伙伴%s成功", iType))
            else
                oNotifyMgr:Notify(iPid, string.format("伙伴%s已存在", iType))
            end
        else
            oNotifyMgr:Notify(iPid, "添加失败，不存在该伙伴")
        end
    elseif iCmd == 109 then
        local iVal = table.unpack(mArgs)
        local iTime = self:GetTestInfo("talent_show_time")
        if iTime then
            self:SetTestInfo("talent_show_time", nil)
            oNotifyMgr:Notify(iPid, "gm取消才艺展示时间")
        else
            if type(iVal) == "number" and iVal > 0 then
                self:SetTestInfo("talent_show_time", iVal)
                oNotifyMgr:Notify(iPid, string.format("gm设置才艺展示时间:%s秒", iVal))
            end
        end
    elseif iCmd == 110 then
        self.m_oPartnerCtrl:RandomCoin()
        oNotifyMgr:Notify(iPid, "已刷新金币")
    elseif iCmd == 111 then
        self.m_oToday:Set("help_friend_talent",0)
        oNotifyMgr:Notify(iPid, "已重置加油次数")
    elseif iCmd == 112 then
        --use_friend_desk_second
        local iVal = table.unpack(mArgs)
        local iTime = self:GetTestInfo("use_friend_desk_second")
        if iTime then
            self:SetTestInfo("use_friend_desk_second", nil)
            oNotifyMgr:Notify(iPid, "gm取消加油时间")
        else
            if type(iVal) == "number" and iVal > 0 then
                self:SetTestInfo("use_friend_desk_second", iVal)
                oNotifyMgr:Notify(iPid, string.format("gm设置加油时间:%s秒", iVal))
            end
        end
    elseif iCmd == 113 then
        self.m_oToday:Set("use_friend_desk",0)
        oNotifyMgr:Notify(iPid, "已重置制作次数")
    elseif iCmd == 114 then
        local iVal = table.unpack(mArgs)
        if not iVal then
            oNotifyMgr:Notify(iPid,"参数输入错误")
            return
        end
        if type(iVal) ~= "number" or iVal <= 0 then
            oNotifyMgr:Notify(iPid,"参数输入错误")
            return
        end
        -- self.m_oPartnerCtrl:AddTotalLoveShip(math.ceil(iVal), "测试")
    elseif iCmd == 1 then
        -- local bGive = oPlayer:ValidGive({{18000,1}})
    end
    oNotifyMgr:Notify(iPid,"指令执行成功")
end

--testop
function CHouse:GetTestInfo(sTest, ...)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetOwner()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local mArgs = {...}
    return oPlayer:GetInfo(sTest)
end

function CHouse:SetTestInfo(sTest, ... )
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetOwner()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local mArgs = {...}
    if sTest == "partner_train_time" then
        local iValue = table.unpack(mArgs)
        oPlayer:SetInfo(sTest, iValue)
    elseif sTest == "talent_show_time" then
        local iValue = table.unpack(mArgs)
        oPlayer:SetInfo(sTest, iValue)
    elseif sTest == "use_friend_desk_second" then
        local iValue = table.unpack(mArgs)
        oPlayer:SetInfo(sTest, iValue)
    end
end

function NewHouseObj(iPid)
    local o = CHouse:New(iPid)
    return o
end



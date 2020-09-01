--import module

local global = require "global"
local interactive = require "base.interactive"

local gamedb = import(lualib_path("public.gamedb"))
local houseobj = import(service_path("house.houseobj"))
local housedefines = import(service_path("house.defines"))
local partnerctrl = import(service_path("house.partnerctrl"))


function NewHouseMgr()
    local o = CHouseMgr:New()
    return o
end

CHouseMgr = {}
CHouseMgr.__index = CHouseMgr
inherit(CHouseMgr, logic_base_cls())

function CHouseMgr:New()
    local o = super(CHouseMgr).New(self)
    o.m_mHouse = {}
    return o
end

function CHouseMgr:NewDay(iWeekDay)
    local oWorldMgr = global.oWorldMgr
    for _, oHouse in pairs(self.m_mHouse) do
        oHouse:NewDay(iWeekDay)
    end
end

function CHouseMgr:GetHouse(iPid)
    local oHouse = self.m_mHouse[iPid]
    return oHouse
end

function CHouseMgr:RemoveHouse(iPid)
    local oHouse = self.m_mHouse[iPid]
    self.m_mHouse[iPid] = nil
    if oHouse then
        baseobj_delay_release(oHouse)
    end
end

function CHouseMgr:EnterHouse(oPlayer,iTarget)
    local iPid = oPlayer.m_iPid
    local fCallback = function (oHouse)
        oHouse:EnterHouse(iPid)
    end
    self:LoadHouse(iTarget,fCallback)
end

function CHouseMgr:CloseGS()
    for iPid, oHouse in pairs(self.m_mHouse) do
        oHouse:DoSave()
    end
end

function CHouseMgr:OnLogin(oPlayer,bReEnter)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oNowScene:MapId() == 501000 then
        -- local mResData = oNowScene:GetResData()
        -- local iOwner = mResData["house_owner"]
        -- local oHouse = self:GetHouse(iOwner)
        -- if oHouse then
        --     oHouse:EnterHouse(oPlayer.m_iPid)
        -- end
        local oSceneMgr = global.oSceneMgr
        local mDurableInfo = oPlayer.m_oActiveCtrl:GetDurableSceneInfo()
        local iMapId = mDurableInfo.map_id
        local oScene = oSceneMgr:SelectDurableScene(iMapId)
        local mPos = {
            x = 0,
            y = 0,
        }
        oSceneMgr:EnterScene(oPlayer, oScene:GetSceneId(), {pos = mPos}, true)
    end

    local iPid =oPlayer:GetPid()
    self:LoadHouse(iPid, function(oHouse)
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local mData = {
                furniture_info = oHouse.m_oFurnitureCtrl:PackNetInfo(),
                partner_info = oHouse.m_oPartnerCtrl:PackNetInfo(),
                item_info = oHouse.m_oItemCtrl:PackNetInfo(),
                warm_degree = oHouse.m_iWarmDegree,
                max_warm_degree = oHouse:GetWarmDegreeLimit(),
                max_train = oHouse.m_oPartnerCtrl:TrainSpace(),
                owner_pid = oHouse:GetOwner(),
                talent_level = oHouse:TalentLevel(),
                handle_type = 1,
                buff_info = oHouse.m_oPartnerCtrl:PackHouseBuff(),
            }
            oPlayer:Send("GS2CEnterHouse",mData)
            oHouse.m_oPartnerCtrl:SendPartnerExchangeUI(1)

            local iType = housedefines.FURNITURE_TYPE.WORK_DESK
            local oFurniture = oHouse:GetFurniture(iType)
            oFurniture:OpenWorkDesk(iPid, 1)
            oHouse.m_oPartnerCtrl:UpdatePlayerBuff()
        end
    end)
end

function CHouseMgr:UseFriendWorkDesk(oPlayer,iTarget)
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    local oHouse = self:GetHouse(iPid)
    local iUse = oHouse.m_oToday:Query("use_friend_desk", 0)
    local iMaxUse = housedefines.GetDaobiaoDefines("use_friend_work_desk")
    if iUse >= iMaxUse then
        oNotifyMgr:Notify(iPid, "今日次数已用完，明天再来吧。")
        return
    end
    if oHouse.m_oFurnitureCtrl:IsUsingFriendDesk() then
        oNotifyMgr:Notify(iPid, "好友工作台不可重复进行")
        return
    end

    local fCallback = function (oHouse)
        if oHouse then
            local mNet = {}
            mNet.frd_pid = iTarget
            mNet.status = 0
            local iType = housedefines.FURNITURE_TYPE.WORK_DESK
            local oFurniture = oHouse:GetFurniture(iType)
            if oFurniture:ValidUseFriendWorkDesk(iPid) then
                oFurniture:UseFriendWorkDesk(iPid)
            else
                mNet.status = 1
                oNotifyMgr:Notify(iPid, "工作台已被占用")
            end
            local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer:Send("GS2CUseFriendWorkDesk", mNet)
            end
        end
        -- self:UseFriendWorkDesk(oHouse,iPid)
    end
    self:LoadHouse(iTarget,fCallback)
end

function CHouseMgr:HouseAutoDrawGift(iOwner,iFriend)
    local oHouse = self:GetHouse(iOwner)
    local iType = housedefines.FURNITURE_TYPE.WORK_DESK
    local oFurniture = oHouse:GetFurniture(iType)
    local iRentCoin= oFurniture:GetRentCoin()
    oHouse:AutoDrawCoin(iRentCoin)
    local iGiftItem = oFurniture:GetTalentGift()
    local fCallback = function (oHouse)
        oHouse:AutoDrawGift(iGiftItem,iOwner)
    end
    self:LoadHouse(iFriend,fCallback)
end

function CHouseMgr:InitHouse(iPid)
    self:LoadHouse(iPid,fCallback)
end

function CHouseMgr:LoadHouse(iPid,fCallback)
    local oHouse = self.m_mHouse[iPid]
    if oHouse then
        if fCallback then
            if oHouse:IsLoading() then
                oHouse:AddWaitFunc(fCallback)
            else
                fCallback(oHouse)
                oHouse.m_iLastTime = get_time()
            end
        end
    else
        local oHouse = houseobj.NewHouseObj(iPid)
        self.m_mHouse[iPid] = oHouse
        if fCallback then
          oHouse:AddWaitFunc(fCallback)
        end
        local mData = {
            pid = iPid,
        }
        local mArgs = {
            module = "house",
            cmd = "LoadHouse",
            data = mData
        }
        gamedb.LoadDb(iPid,"common","LoadDb",mArgs,function (mRecord,mData)
            if not is_release(self) then
                local m = mData.data
                local oHouse = self:GetHouse(iPid)
                if oHouse then
                    oHouse:Load(m)
                    oHouse.m_bLoading = false
                    oHouse:LoadFinish()
                    oHouse:WakeUpFunc()
                    oHouse:ConfigSaveFunc()
                    oHouse:Schedule()
                end
            end
        end)
    end
end

function CHouseMgr:IsClose()
    local oWorldMgr = global.oWorldMgr
    local sKey = "house"
    if oWorldMgr:IsClose(sKey) then
        return true
    end
    return false
end

function CHouseMgr:QueryFriendHouseProfile(oPlayer)
    local iPid = oPlayer:GetPid()
    local oFriendCtrl = oPlayer:GetFriend()
    local lBothFriend = oFriendCtrl:GetBothFriends()
    if next(lBothFriend) then
        self:BatchQueryProfile(iPid, lBothFriend, self.SendHouseProfile)
    else
        self:SendHouseProfile(oPlayer, {})
    end
end

function CHouseMgr:BatchQueryProfile(iPid, lPidList, sendfunc)
    local oHouseMgr = global.oHouseMgr
    local iRequestCount = #lPidList
    local mHandle = {
        count = iRequestCount,
        list = {},
        is_sent = false,
    }

    for _, k in ipairs(lPidList) do
        local o = self:GetHouse(k)
        if o then
            self:_HandleQueryProfile(iPid, o, mHandle, sendfunc)
        else
            oHouseMgr:LoadHouse(k, function (o)
                if not o then
                    mHandle.count = mHandle.count - 1
                    self:_JudgeSend(iPid, mHandle, sendfunc)
                else
                    self:_HandleQueryProfile(iPid, o, mHandle, sendfunc)
                end
            end)
        end
    end
end

function CHouseMgr:_HandleQueryProfile(iPid, oFrdHouse, mHandle, sendfunc)
    mHandle.count = mHandle.count - 1
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        table.insert(mHandle.list, oFrdHouse:PackHouseProfile(iPid))
    end
    self:_JudgeSend(iPid, mHandle, sendfunc)
end

function CHouseMgr:_JudgeSend(iPid, mHandle, sendfunc)
    if mHandle.count <= 0 and not mHandle.is_sent then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            sendfunc(self, oPlayer, mHandle.list)
        end
        mHandle.is_sent = true
    end
end

function CHouseMgr:SendHouseProfile(oPlayer, mResult)
    oPlayer:Send("GS2CFriendHouseProfile", {
        profile_list = mResult,
        })
end

function CHouseMgr:RecieveHouseCoin(oPlayer, iFrdPid)
    local iPid = oPlayer:GetPid()
    local oFriendCtrl = oPlayer:GetFriend()
    if not oFriendCtrl:IsBothFriend(iFrdPid) then
        return
    end
    self:LoadHouse(iFrdPid, function(oHouse)
        oHouse:RecievePartnerCoin(iPid)
    end)
end

function CHouseMgr:OpenWorkDesk(oPlayer, iTargetPid)
    local iPid = oPlayer:GetPid()
    self:LoadHouse(iTargetPid, function(oHouse)
        local iType = housedefines.FURNITURE_TYPE.WORK_DESK
        local oFurniture = oHouse:GetFurniture(iType)
        --[[test
        if oFurniture:IsLockStatus() then
            oNotifyMgr:Notify(iPid,"工作台尚未解锁,无法开启")
            return
        end
        ]]
        oFurniture:OpenWorkDesk(iPid)
    end)
end

function CHouseMgr:RemoteAddHousePartner(iPid, mPartnerType, sReason)
    mPartnerType = mPartnerType or {}
    if not next(mPartnerType) then
        return
    end
    self:LoadHouse(iPid, function(oHouse)
        local mPartner = housedefines.GetPartnerData()
        for iType, m in pairs(mPartner) do
            local iUnlock = m.unlock_type
            if mPartnerType[iUnlock] and not oHouse:GetPartner(iType)  then
                local oPartner = partnerctrl.NewPartner(iType)
                oHouse:AddPartner(oPartner,sReason)
            end
        end
    end)
end
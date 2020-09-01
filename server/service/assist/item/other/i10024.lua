local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local record = require "public.record"
local itembase = import(service_path("item.other.otherbase"))
local itemdefines = import(service_path("item/itemdefines"))
local HUODONG_TREASURE_NAME = "treasure"
local interactive = require "base.interactive"
local gamedefines = import(lualib_path("public.gamedefines"))

local TOTALWEIGHT_BAODI = 10000
local TOTALWEIGHT_NORMAL = 10000

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:OnAddToContainer()
    super(CItem).OnAddToContainer(self)
    self:InitMap()
end

function CItem:InitMap()
    self:InitMapData()
    self:InitRewardInfo()
end

function CItem:RamdomSceneIdForTreasureMap()
    local res = require "base.res"
    local mMapList = {}

    if res["daobiao"]["scenegroup"][tonumber(res["daobiao"]["global"]["treasure_scene_group"]["value"])] then
        mMapList = res["daobiao"]["scenegroup"][tonumber(res["daobiao"]["global"]["treasure_scene_group"]["value"])]
    else
        return 101000
    end
    mMapList = mMapList["maplist"]
    return mMapList[math.random(#mMapList)]
end

function CItem:InitMapData()
    self:Dirty()
    local iSceneId = self:RamdomSceneIdForTreasureMap()
    local oSceneMgr = global.oSceneMgr
    local mPosInfo = oSceneMgr:RandomMonsterPos(iSceneId)
    local iPosx,iPosy= table.unpack(mPosInfo[1])
    self.m_mTreasuremap={["treasure_mapid"] = iSceneId,["treasure_posx"] = iPosx,["treasure_posy"] = iPosy}
    record.user("treasure","init_mapinfo",{pid = self:GetOwner(),itemid=self.m_ID,posinfo=ConvertTblToStr(self.m_mTreasuremap)})
end

function CItem:RandomNormalSlot()
    local res = require "base.res"
    local mNormalReward = res["daobiao"]["huodong"]["treasure"]["normal_reward"]
    local iN = math.random(TOTALWEIGHT_NORMAL)
    local iT = 0
    for _,info in pairs(mNormalReward) do 
        iT = iT + info.weight
        if iN <= iT then
            return table_deep_copy(info)
        end
    end
end

function CItem:InitRewardInfo()
    self:Dirty()
    self.m_mRewardInfo = self:RandomNormalSlot()
end

function CItem:IsPlayerOnTrulyScene(iPid,iSceneId)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(iSceneId)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    return oNowScene:MapId() == iSceneId
end

function CItem:GetMapPosInfo()
    return self.m_mTreasuremap
end

function CItem:ValidUse(oPlayer, iUseAmount,mArgs)
    local bValid = super(CItem).ValidUse(self,oPlayer,iUseAmount,mArgs)
    if not bValid then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    if mArgs.has_team then
        oNotifyMgr:Notify(oPlayer:GetPid(),"挖宝这么神秘的事情，还是一个人完成比较好")
        return false
    end
    
    local bOpen = res["daobiao"]["global_control"]["treasure"]["is_open"]
    local iGrade = res["daobiao"]["global_control"]["treasure"]["open_grade"]
    if bOpen ~= "y" then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return false
    end
    local iPlayerGrade = mArgs.grade
    if iPlayerGrade < iGrade then
        oNotifyMgr:Notify(oPlayer:GetPid(),"等级不足")
        return false
    end
    return true
end

function CItem:TrueUse(oPlayer,iTarget,iAmount,mArgs)
    local iTreasureMapId = self.m_mTreasuremap["treasure_mapid"]
    local iPosX = self.m_mTreasuremap["treasure_posx"]
    local iPosY = self.m_mTreasuremap["treasure_posy"]
    local mNowPos = mArgs.pos_info or {}
    local iMapId = mArgs.map_id or 0
    local mTreasureInfo = mArgs.treasure_info or 0
    local iT = mTreasureInfo.treasure_cnt
    local iID = self.m_ID
    if iMapId == iTreasureMapId and gamedefines.OverPosRange(mNowPos.x,mNowPos.y,iPosX,iPosY) then
        local fCallback = function(oPlayer,mData)
            local oItem = oPlayer.m_oItemCtrl:HasItem(iID)
            if not oItem then
                return
            end
            oItem:_TrueUse1(oPlayer,mData,mTreasureInfo)
        end
        local oCbMgr = global.oCbMgr
        local mReward = self:PackRewardInfo(oPlayer,iT)
        oCbMgr:SetCallBack(oPlayer:GetPid(),"GS2CShowNormalReward",{rewardinfo = mReward,times = iT},nil,fCallback)
    end
 end

function CItem:_TrueUse1(oPlayer,mData,mTreasureInfo)
    if mData.answer ~= 1 then
        return
    end
    local sReason = "挖宝"
    local iT = mTreasureInfo.treasure_cnt or 0
    local mReward = self:RandomReward(iT,mTreasureInfo)
    local mMapInfo = table_deep_copy(self:GetMapPosInfo())
    local iAmount = self:GetAmount()
    oPlayer.m_oItemCtrl:AddAmount(self,-1,sReason)
    if iAmount > 1 then
        self:InitMap()
        self:Refresh()
    end
    local mArgs = {
        reward_info = mReward,
        itemid = self.m_ID,
        map_info = mMapInfo,
    }
    local mRemoteData = {
        pid = oPlayer:GetPid(),
        args = mArgs,
    }
    interactive.Send(".world", "item", "UseBaotu",mRemoteData)
end

function CItem:PackRewardInfo(oPlayer,iT)
    local mReward = {}
    if (iT+1)%5 == 0 then
        if not self.m_mBaodiReward then
            self:Dirty()
            local m = self:GetBaodiReward()
            for _,t in pairs(m["iteminfo"]) do
                table.insert(mReward,{type = t["type"],idx=t["value"]})
            end
            self.m_mBaodiReward = m
        else
            for _,t in pairs(self.m_mBaodiReward["iteminfo"]) do
                table.insert(mReward,{type = t["type"],idx=t["value"]})
            end
        end
    else
        for _,info in pairs(self.m_mRewardInfo["iteminfo"]) do
            table.insert(mReward,{type=info["type"],idx=info["value"]})
        end
    end
    return mReward
end

function CItem:RandomReward(iTimes,mTreasureInfo)
    if (iTimes+1)%5 == 0 then
        return self:RandomBaodiReward(mTreasureInfo)
    else
        return self:RandomNormalReward(mTreasureInfo)
    end
end

function CItem:RandomNormalReward(mTreasureInfo)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(self:GetOwner())
    if mTreasureInfo and mTreasureInfo.treasure_cnt == 2 then
        oPlayer:SetInfo("GMTreasure",{2,1})
    end
    local iT = self:GetNormalTotalWeight()
    local iR = math.random(iT)
    local iC = 0
    local iNextType,iNextValue = table.unpack(oPlayer:GetInfo("GMTreasure",{0,0}))
    for _,info in pairs(self.m_mRewardInfo["iteminfo"]) do
        if iNextType ~= 0 then
            if iNextType == info["type"] and iNextValue == info["value"] then
                oPlayer:SetInfo("GMTreasure",{0,0})
                return info
            end
        else
            iC = iC + info["weight"]
            if iR <= iC then
                if info["type"] == 2 and info["value"] == 2 then
                    if mTreasureInfo.treasure_reward  == 1 then
                        return self:RandomNormalReward(mTreasureInfo)
                    else 
                        return info
                    end
                else
                    return info
                end
            end
        end
    end
    return self.m_mRewardInfo["iteminfo"][1]
end

function CItem:RandomBaodiReward(mTreasureInfo)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(self:GetOwner())
    local iT = self:GetBaodiTotalWeight()
    local iR = math.random(iT)
    local iC = 0
    local iNextType,iNextValue = table.unpack(oPlayer:GetInfo("GMTreasure",{0,0}))
    for _,info in pairs(self.m_mBaodiReward["iteminfo"]) do
        if iNextType ~= 0 then
            if iNextType == info["type"] and iNextValue == info["value"] then
                oPlayer:SetInfo("GMTreasure",{0,0})
                return info
            end
        else
            iC = iC + info["weight"]
            if iR <= iC then
                if info["type"] == 2 and info["value"] == 2 then
                    if mTreasureInfo.treasure_reward  == 1 then
                        return self:RandomBaodiReward(mTreasureInfo)
                    else
                        return info
                    end
                else
                    return info
                end
            end
        end
        
    end
    return self.m_mBaodiReward["iteminfo"][1]
end

function CItem:CheckHasLegendBoy(oPlayer)
    local mNpc = oPlayer.m_oHuodongCtrl:GetNpcByType("legendboynpc")
    if #mNpc > 0 then
        return true
    else
        return false
    end
end

function CItem:GetBaodiReward()
    local res = require "base.res"
    local mNormalReward = res["daobiao"]["huodong"]["treasure"]["baodi_reward"]
    local iN = math.random(TOTALWEIGHT_BAODI)
    local iT = 0
    for _,info in pairs(mNormalReward) do
        iT = iT + info.weight
        if iN <= iT then
            return table_deep_copy(info)
        end
    end
end

function CItem:GetNormalTotalWeight()
    local iT = 0
    for _,info in pairs(self.m_mRewardInfo["iteminfo"]) do
        iT = iT + info["weight"]
    end
    return iT
end

function CItem:GetBaodiTotalWeight()
    local iT = 0
    for _,info in pairs(self.m_mBaodiReward["iteminfo"]) do
        iT = iT + info["weight"]
    end
    return iT
end

function CItem:Load(mData)
    super(CItem).Load(self,mData)
    self.m_mTreasuremap  = mData["treasuremap_info"] or self.m_mTreasuremap 
    self.m_mRewardInfo = mData["rewardinfo"] or self.m_mRewardInfo
    self.m_mBaodiReward = mData["baodireward"] or self.m_mBaodiReward
end

function CItem:Save()
    local mData = super(CItem).Save(self)
    mData["treasuremap_info"] = self.m_mTreasuremap
    mData["rewardinfo"] = self.m_mRewardInfo
    mData["baodireward"] = self.m_mBaodiReward
    return mData
end

function  CItem:PackItemInfo()
    local mRet = super(CItem).PackItemInfo(self)
    mRet["treasure_info"] = self.m_mTreasuremap
    return mRet
end

function CItem:GS2CAddItem(mArgs)
    local mArgs = mArgs or {}
    local mNet = {}
    local itemdata = self:PackItemInfo()
    mNet["itemdata"] = itemdata
    mNet["from_wh"] =  mArgs.from_wh
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetOwner())
    if oPlayer then
        oPlayer:Send("GS2CAddItem",mNet)
    end
end
--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"

local huodongbase = import(service_path("huodong.huodongbase"))
local itemdefines = import(service_path("item/itemdefines"))
local loaditem = import(service_path("item/loaditem"))
local gamedefines = import(lualib_path("public.gamedefines"))
local playboynpc = import(service_path("huodong/npcobj/playboynpcobj"))
local legendboynpc = import(service_path("huodong/npcobj/legendboynpcobj"))

local TOTALWEIGHT_NORMAL = 10000
local TOTALWEIGHT_BAODI = 10000
local PLAYBOY_NORMALREWARD = 5
local PLAYBOY_SPECIALREWARD = 1

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "挖宝"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    return o
end

function CHuodong:Init()
    self.m_sName = "treasure"
    self.m_iScheduleID = 1004
end

function CHuodong:RandomNormalSlot()
    local res = require "base.res"
    local mNormalReward = res["daobiao"]["huodong"][self.m_sName]["normal_reward"]
    local iN = math.random(TOTALWEIGHT_NORMAL)
    local iT = 0
    for _,info in pairs(mNormalReward) do
        iT = iT + info.weight
        if iN <= iT then
            return table_deep_copy(info)
        end
    end
end

function CHuodong:RandomPlayBoyReward()
    local res = require "base.res"
    local mPlayBoyReward = res["daobiao"]["huodong"][self.m_sName]["playboy_reward"]
    local m = {}
    local iST = self:GetPlayBoyTotalWeight(mPlayBoyReward["special"])
    local iNT = self:GetPlayBoyTotalWeight(mPlayBoyReward["normal"])
    local iN = 0
    local mT = {}
    for i = 1,PLAYBOY_SPECIALREWARD do
        local iR = math.random(iST)
        iN = 0
        for _,info in pairs(mPlayBoyReward["special"]) do
            iN = iN+info.weight
            if iR<=iN and not mT[info.id] then
                mT[info.id] = true
                table.insert(m,table_deep_copy(info))
                iST = iST - info.weight
                break
            end
        end
    end
    for i = 1,PLAYBOY_NORMALREWARD do
        local iR = math.random(iNT)
        iN = 0
        for _,info in pairs(mPlayBoyReward["normal"]) do
            iN = iN+info.weight
            if iR<=iN and not mT[info.id] then
                mT[info.id] = true
                table.insert(m,table_deep_copy(info))
                iNT = iNT - info.weight
                break
            end
        end
    end
    return m
end

function CHuodong:GetPlayBoyTotalWeight(mReward)
    local iT = 0
    for _,info in pairs(mReward) do
        iT = iT+info.weight
    end
    return tonumber(iT)
end

function CHuodong:GiveNormalReward(oPlayer,mReward,mArgs)
    local iT = oPlayer.m_oActiveCtrl:GetTreasureTotalTimes()
    record.user("treasure","find_treasure",{pid=oPlayer.m_iPid,times=iT,itemid=mArgs.itemid,posinfo=ConvertTblToStr(mArgs.map_info),rewardinfo=ConvertTblToStr(mReward)})
    if mReward["type"] == 1 then
        self:Reward(oPlayer.m_iPid,mReward["value"],{cancel_tip = 1})
    elseif mReward["type"] == 2 then
        if mReward["value"] == 1 then
            self:TriggerPlayBoy(oPlayer,mReward,mArgs)
        elseif mReward["value"] == 2 then
            self:TriggerLegendBoy(oPlayer,mReward,mArgs)
        end
    end
    local iCoinReward = (((iT+1)%5) == 0) and 402 or 401
    self:Reward(oPlayer.m_iPid,iCoinReward,{cancel_tip = 1})
    global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
    local mLog = {}
    -- mLog["type"] = "common"
    self:LogAnalyGame("treasure",oPlayer,{log = mLog})
end

function CHuodong:GivePlayBoyReward(iPid,iReward,iText)
    local bChuanwen  = (iText == 1 and true or false)
    local sMsg = nil
    if bChuanwen then
        sMsg = self:GetTextData(1002)
    end
    self:Reward(iPid,iReward,{chuanwen = sMsg,priority="treasure_char"})

    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local mLog = {}
        -- mLog["type"] = "playboy"
        self:LogAnalyGame("treasure",oPlayer, {log = mLog})
    end
    -- global.oUIMgr:ShowKeepItem(iPid)
end

function CHuodong:GetBaodiReward()
    local res = require "base.res"
    local mNormalReward = res["daobiao"]["huodong"][self.m_sName]["baodi_reward"]
    local iN = math.random(TOTALWEIGHT_BAODI)
    local iT = 0
    for _,info in pairs(mNormalReward) do
        iT = iT + info.weight
        if iN <= iT then
            return table_deep_copy(info)
        end
    end
end

function CHuodong:GetLegendReward()
    local res = require "base.res"
    local mNormalReward = res["daobiao"]["huodong"][self.m_sName]["legend_reward"]
    return mNormalReward
end

function CHuodong:TriggerPlayBoy(oPlayer,mReward,mRemoteArgs)
    local mMapPosInfo=mRemoteArgs.map_info
    local iEvent = mReward ["value"]
    if iEvent ~= 1 then
        return
    end
    local mNpcData = self:GetNpcData()
    local mTargetInfo = mNpcData[63001]
    local oSceneMgr = global.oSceneMgr
    local mModel = {
        shape = mTargetInfo["modelId"],
        scale = mTargetInfo["scale"],
        adorn = mTargetInfo["ornamentId"],
        weapon = mTargetInfo["wpmodel"],
        color = mTargetInfo["mutateColor"],
        mutate_texture = mTargetInfo["mutateTexture"],
    }
    local mPosInfo = {
        x = mMapPosInfo["treasure_posx"],
        y = mMapPosInfo["treasure_posy"],
        z = mTargetInfo["z"],
        face_x = mTargetInfo["face_x"] or 0,
        face_y = mTargetInfo["face_y"] or 0,
        face_z = mTargetInfo["face_z"] or 0,
    }
    local mArgs = {
        type = mTargetInfo["id"],
        sys_name = self.m_sName,
        map_id = mMapPosInfo["treasure_mapid"],
        model_info = mModel,
        pos_info = mPosInfo,
        event = mTargetInfo["event"] or 0,
        reuse = mTargetInfo["reuse"] or 0,
        owner = oPlayer:GetPid(),
        createtime = get_time(),
    }
    local oClientNpc = playboynpc.NewClientNpc(mArgs)
    local iNowScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    oClientNpc:SetScene(iNowScene)
    local mClientNpc = oClientNpc:PackInfo()
    oPlayer:Send("GS2CCreateHuodongNpc",{npcinfo = mClientNpc})
    oPlayer.m_oHuodongCtrl:AddClientNpc("playboynpc",oClientNpc)
    global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,"挖宝触发树叶飞舞任务次数",{value=1})
    oPlayer:PushBookCondition("星象图触发奇遇", {value = 1})
    record.user("treasure","trigger_playerboy",{pid=oPlayer.m_iPid,itemid=mRemoteArgs.itemid,npcid=oClientNpc.m_ID,posinfo=ConvertTblToStr(mPosInfo)})
end

function CHuodong:TriggerLegendBoy(oPlayer,mReward,mRemoteArgs)
    local mMapPosInfo=mRemoteArgs.map_info
    local iEvent = mReward ["value"]
    if iEvent ~= 2 then
        return
    end
    local mNpcData = self:GetNpcData()
    local mTargetInfo = mNpcData[63002]
    local oSceneMgr = global.oSceneMgr
    local mModel = {
        shape = mTargetInfo["modelId"],
        scale = mTargetInfo["scale"],
        adorn = mTargetInfo["ornamentId"],
        weapon = mTargetInfo["wpmodel"],
        color = mTargetInfo["mutateColor"],
        mutate_texture = mTargetInfo["mutateTexture"],
    }
    local mPosInfo = {
        x = mMapPosInfo["treasure_posx"],
        y = mMapPosInfo["treasure_posy"],
        z = mTargetInfo["z"],
        face_x = mTargetInfo["face_x"] or 0,
        face_y = mTargetInfo["face_y"] or 0,
        face_z = mTargetInfo["face_z"] or 0,
    }
    local mArgs = {
        type = mTargetInfo["id"],
        map_id = mMapPosInfo["treasure_mapid"],
        model_info = mModel,
        pos_info = mPosInfo,
        event = mTargetInfo["event"] or 0,
        reuse = mTargetInfo["reuse"] or 0,
        owner = oPlayer:GetPid(),
        createtime = get_time(),
        sys_name = self.m_sName,
    }
    local oClientNpc = legendboynpc.NewClientNpc(mArgs)
    local iNowScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    oClientNpc:SetScene(iNowScene)
    local mClientNpc = oClientNpc:PackInfo()
    oPlayer:Send("GS2CCreateHuodongNpc",{npcinfo = mClientNpc})
    oPlayer.m_oHuodongCtrl:AddClientNpc("legendboynpc",oClientNpc)
    local sMsg = string.gsub(self:GetTextData(1001),"#role",{["#role"]=oPlayer:GetName()})
    sMsg = string.gsub(sMsg,"#npcname",mTargetInfo.name)
    local oNotify = global.oNotifyMgr
    oNotify:DelaySendSysChat(sMsg,1,1,{},{pid=oPlayer.m_iPid,delay=15,sys_name="treasure"})
    global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,"挖宝触发一拳胜负任务次数",{value=1})
    oPlayer:PushBookCondition("星象图触发奇遇", {value = 1})
    record.user("treasure","trigger_legendboy",{pid=oPlayer.m_iPid,itemid=mRemoteArgs.itemid,npcid=oClientNpc.m_ID,posinfo=ConvertTblToStr(mPosInfo)})
end

function CHuodong:GetHuodongBaseData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName] or {}
    return mData
end

function CHuodong:GetNpcData()
    local mData = self:GetHuodongBaseData()
    return mData["npc"] or {}
end

function CHuodong:RewardGold(oPlayer, iGold, mArgs)
    mArgs = mArgs or {}
    mArgs["notify"] = "off"
    oPlayer:RewardGold(iGold, self.m_sName, mArgs)
end

function CHuodong:RewardSilver(oPlayer, iSliver, mArgs)
    mArgs = mArgs or {}
    mArgs["notify"] = "off"
    oPlayer:RewardSilver(iSliver, self.m_sName, mArgs)
end

function CHuodong:RamdomSceneIdForTreasureMap()
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

function CHuodong:IsPlayerOnTrulyScene(iPid,iSceneId)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(iSceneId)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    return oNowScene:MapId() == iSceneId
end

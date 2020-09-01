-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"
local loaditem = import(service_path("item/loaditem"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loadpartner = import(service_path("partner/loadpartner"))
local partnerdefine = import(service_path("partner.partnerdefine"))
local loaditem = import(service_path("item/loaditem"))

local KEY_ITEMID = 10040

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "魂匣"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    o.m_mOpenRecord = {}
    return o
end

function CHuodong:NewHour(iWeekDay, iHour)
    self:RefreshBox()
    self.m_mOpenRecord = {}
    local mOnLinePlayer = global.oWorldMgr:GetOnlinePlayerList()
    for iPid,oPlayer in pairs(mOnLinePlayer) do
        self:PushRecord(oPlayer)
    end
end

function CHuodong:RefreshBox()
    self:ClearLastHourBox()
    local bOpen = res["daobiao"]["global_control"]["herobox"]["is_open"]
    if bOpen ~= "y" then
        return
    end
    local iMapGroup = tonumber(res["daobiao"]["global"]["herobox_scene_group"]["value"])
    local mMapId = self:RamdomSceneId(iMapGroup)
    self.m_mCurMap = mMapId
    local iMapNum = #mMapId
    local oSceneMgr = global.oSceneMgr
    for _, iMapId  in ipairs(mMapId) do
        local mScene = oSceneMgr:GetSceneListByMap(iMapId)
        for _, oScene in ipairs(mScene) do
            local iScene = oScene:GetSceneId()
            local num = self:GetRefreshMonsterAmount()
            local mPos = oSceneMgr:RandomHeroBoxPos(iMapId,num)
            for i=1,num do
                local x, y = table.unpack(mPos[i])
                local mPosInfo = {
                    x = x or 0,
                    y = y or 0,
                    z = 0,
                    face_x = 0,
                    face_y = 0,
                    face_z = 0,
                }
                local oNpc = self:CreateTempNpc(70001)
                self:Npc_Enter_Scene(oNpc, iScene, mPosInfo)
            end
        end
    end
    local sMsg = self:GetTextData(1002)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendPrioritySysChat("herobox_start",sMsg,  1)
    
end

function CHuodong:GetNpcBaseData()
    local mData = res["daobiao"]["huodong"][self.m_sName]["npc"]
    return mData
end

function CHuodong:ClearLastHourBox()
    for iNpcId,oNpc in pairs(self.m_mNpcList) do
        if oNpc then
            self:RemoveTempNpc(oNpc)
        end
    end
end

function CHuodong:RamdomSceneId(iGroupId)
    local res = require "base.res"
    if res["daobiao"]["scenegroup"][iGroupId] then
        return table_deep_copy(res["daobiao"]["scenegroup"][iGroupId]["maplist"])
    else
        return {101000}
    end
end

function CHuodong:GetRefreshMonsterAmount()
    return 8
end

function CHuodong:do_look(oPlayer,oNpc)
    local iGrade = res["daobiao"]["global_control"]["herobox"]["open_grade"]
    if iGrade > oPlayer:GetGrade() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,string.format("你的等级不足，%d级可开启灵魂宝箱",iGrade))
        return
    end
    if oPlayer:GetItemAmount(KEY_ITEMID) > 0 then
        self:_ClickBox1(oNpc,oPlayer)
    else
        self:_ClickBox2(oNpc,oPlayer)
    end
end

function CHuodong:_ClickBox1(oNpc,oPlayer)
    local sContent = "是否使用灵魂钥匙开启灵魂宝箱？"
    local mNet = {
        sContent = sContent,
        sConfirm = "确定",
        sCancle = "取消",
        default = 0,
        time = 30,
    }
    local iNpcId = oNpc.m_ID
    local oCbMgr = global.oCbMgr
    mNet = oCbMgr:PackConfirmData(nil, mNet)
    local func = function(oPlayer,mData)
        if mData.answer and mData.answer == 1 then
            local oHuodongMgr = global.oHuodongMgr
            local oHuodong = oHuodongMgr:GetHuodong("herobox")
            local npcobj = oHuodong:GetNpcObj(iNpcId)
            if npcobj then
                oHuodong:_OpenBox1(npcobj,oPlayer)
            else
                global.oNotifyMgr:Notify(oPlayer.m_iPid,"您来晚了，宝箱已经消失")
            end
        end
    end
    oCbMgr:SetCallBack(oPlayer.m_iPid,"GS2CConfirmUI",mNet,nil,func)
end

function CHuodong:_ClickBox2(oNpc,oPlayer)
    local mNet = {
        sContent = "灵魂钥匙不足，是否前往商店购买？",
        sConfirm = "确定",
        sCancle = "取消",
        default = 0,
        time = 30,
    }
    local iNpcId = oNpc.m_ID
    local oCbMgr = global.oCbMgr
    mNet = oCbMgr:PackConfirmData(nil, mNet)
    local func = function(oPlayer,mData)
        if mData.answer and mData.answer == 1 then
            local oHuodongMgr = global.oHuodongMgr
            local oHuodong = oHuodongMgr:GetHuodong("herobox")
            local npcobj = oHuodong:GetNpcObj(iNpcId)
            if npcobj then
                oHuodong:_OpenBox2(npcobj,oPlayer)
            else
                global.oNotifyMgr:Notify(oPlayer.m_iPid,"您来晚了，宝箱已经消失")
            end
        end
    end
    oCbMgr:SetCallBack(oPlayer.m_iPid,"GS2CConfirmUI",mNet,nil,func)
end

function CHuodong:CoinIcon(iType)
    local mCoinInfo = gamedefines.COIN_TYPE[iType]
    assert(mCoinInfo,string.format("MaxCoin %d",iType))
    return mCoinInfo.icon or mCoinInfo.name
end

function CHuodong:_OpenBox1(oNpc,oPlayer)
    local iScene = oNpc:GetScene()
    local fFunc = function()
        local oHuodong = global.oHuodongMgr:GetHuodong("herobox")
        oHuodong:_TrueOpenBox(oPlayer,iScene,oNpc)
    end
    oPlayer:RemoveItemAmount(KEY_ITEMID,1,"开启魂匣宝箱",{},fFunc)
end

function CHuodong:_OpenBox2(oNpc,oPlayer)
    oPlayer:Send("GS2COpenShop",{shop_id = 212})
end

function CHuodong:GetConfigInfo()
    local mData = res["daobiao"]["huodong"][self.m_sName]["config"]
    return mData
end

function CHuodong:GetItemPool()
    return res["daobiao"]["huodong"][self.m_sName]["item_pool"]
end

function CHuodong:RandomRewardType(oPlayer)
    local mInfo = self:GetConfigInfo()
    local iTotalWeight = 0
    for _,info in pairs(mInfo) do
        iTotalWeight = iTotalWeight + info["weight"]
    end
    local iRan = math.random(iTotalWeight)
    local iC = 0
    for iType,info in pairs(mInfo) do
        iC = iC + info["weight"]
        if iRan <= iC then
            return iType
        end
    end
end

function CHuodong:RandomRewardIndex(oPlayer,mInfo)
    local iTotalWeight = 0
    for _,info in pairs(mInfo) do
        iTotalWeight = iTotalWeight + info["extract_weight"]
    end
    local iRan = math.random(iTotalWeight)
    local iC = 0
    for iIndex,info in pairs(mInfo) do
        iC = iC + info["extract_weight"]
        if iRan <= iC then
            return iIndex
        end
    end
end

function CHuodong:_TrueOpenBox(oPlayer,iScene,oNpc)
    local mInfo = self:GetConfigInfo()
    local mItem = self:GetItemPool()
    local iGMType,iGMIndex = table.unpack(oPlayer:GetInfo("GMHeroBox",{0,0}))
    local m = {}
    for iType,info in pairs(mInfo) do
        m[iType] = {}
        local iAmount = info["amount"]
        local iTotalWeight = mItem[iType]["totalweight"]
        local i = 0
        for i=1,iAmount do
            local iRan = math.random(iTotalWeight)
            local iT = 0
            for j=1,#mItem[iType] do
                if not m[iType][j] then
                    iT = iT + mItem[iType][j]["weight"]
                    if iT >= iRan or (iType == iGMType and j == iGMIndex) then
                        m[iType][j] = mItem[iType][j]
                        iTotalWeight = iTotalWeight - mItem[iType][j]["weight"]
                        break
                    end
                end
            end
        end
    end
    local iRewardType = iGMType ~= 0 and iGMType or self:RandomRewardType(oPlayer)
    local mNet = {}
    local iRewardIndex = iGMIndex ~= 0 and iGMIndex or self:RandomRewardIndex(oPlayer,m[iRewardType])
    local iRewardID = mItem[iRewardType][iRewardIndex]["sid"]
    local iRewardAmount = mItem[iRewardType][iRewardIndex]["amount"]
    local iSys = mInfo[iRewardType]["sys"]
    for iType,info in pairs(m) do
        for iIndex,n in pairs(info) do
            if iType == iRewardType and iIndex == iRewardIndex then
                table.insert(mNet,{sid = n["sid"],hit = 1,type = n["type"],amount = n["amount"]})
            else
                table.insert(mNet,{sid = n["sid"],hit = 0,type = n["type"],amount = n["amount"]})
            end
        end
    end
    oPlayer:Send("GS2CHeroBoxMainUI",{item = mNet})
    local sItemName
    local iSid,iAmount
    if iRewardType == 4 and tonumber(iRewardID) == 16002 then
        local iPatnerId = self:RandomPartnerReward()
        oPlayer.m_oPartnerCtrl:GivePartner({{iPatnerId,1}},"开启魂匣宝箱")
        iSid = iPatnerId
        iAmount = 1
    else
        local oItem = loaditem.ExtCreate(iRewardID)
        oItem:SetAmount(iRewardAmount)
        iSid = iRewardID
        iAmount = iRewardAmount
        oPlayer:RewardItem(oItem,"开启魂匣宝箱")
    end
    
    
    if iSys == 1 then
        local oSceneMgr = global.oSceneMgr
        local oScene = oSceneMgr:GetScene(iScene)
        local sSceneName = oScene:GetName()
        local sMsg = string.gsub(self:GetTextData(1001),"#role",oPlayer:GetName())
        local iLinkId = 28
        if iRewardType == 4 and tonumber(iRewardID) == 16002 then
            iLinkId = 29
        end
        sMsg = string.gsub(sMsg,"#linkid",iLinkId)
        sMsg = string.gsub(sMsg,"#sid",iSid)
        sMsg = string.gsub(sMsg,"#amount",iAmount)
        global.oNotifyMgr:DelaySendSysChat(sMsg,1,1,{},{pid=oPlayer.m_iPid,delay = 40,sys_name="herobox"})
    end
    if iGMType ~= 0 then
        oPlayer:SetInfo("GMHeroBox",{0,0})
    end
    global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,"成功开启灵魂宝箱次数",{value=1})
    self:RecordOpen(oPlayer,oNpc)
end

function CHuodong:RandomPartnerReward()
    local mData = res["daobiao"]["huodong"][self.m_sName]["hero_pool"]
    local iTotalWeight = 0
    for _,info in pairs(mData) do
        iTotalWeight = iTotalWeight + info["weight"]
    end
    local iRan = math.random(iTotalWeight)
    local iC = 0
    for iParId,info in pairs(mData) do
        iC = iC + info["weight"]
        if iRan <= iC then
            return iParId
        end
    end
end

function CHuodong:RandomPathNpc(oPlayer)
    local mUnValid = self.m_mOpenRecord[oPlayer.m_iPid] or {}
    local iScene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local mDurableInfo = oPlayer.m_oActiveCtrl:GetDurableSceneInfo()
    local iNowMapId = mDurableInfo.map_id
    local mNowPos = mDurableInfo.pos
    local iBaodi
    local mDistance = {}
    for iNpcId,npc in pairs(self.m_mNpcList) do
        if not table_in_list(mUnValid,npc.m_ID) then
            local iMapId = npc:MapId()
            local mPosInfo = npc:PosInfo()
            mDistance[iMapId] = mDistance[iMapId] or {}
            local iDistance
            if iNowMapId == iMapId then
                iDistance = ((mNowPos.x - mPosInfo.x)^2 + (mNowPos.y-mPosInfo.y)^2)
            else
                local x,y = global.oSceneMgr:GetFlyData(iMapId)
                iDistance = ((x - mPosInfo.x)^2 + (y-mPosInfo.y)^2)
            end
            table.insert(mDistance[iMapId],{npcid = iNpcId,distance = iDistance})
        end
    end
    local sSort = function(a,b)
        return a["distance"] < b["distance"]
    end
    if mDistance[iNowMapId] then
        table.sort(mDistance[iNowMapId],sSort)
        return mDistance[iNowMapId][1]["npcid"]
    else
        if table_count(mDistance) > 0 then
            local iRan = table_random_key(mDistance)
            table.sort(mDistance[iRan],sSort)
            return mDistance[iRan][1]["npcid"]
        end
    end
end

function CHuodong:FindNpcPath(oPlayer,iType)
    local iNpcId = iType ~= 0 and iType or self:RandomPathNpc(oPlayer)
    if iNpcId then
        local npc = self.m_mNpcList[iNpcId]
        if not npc then
            return
        end
        local oCbMgr = global.oCbMgr
        local mPosInfo = npc:PosInfo()
        local mData = {["iMapId"] = npc:MapId(),["iPosx"] = mPosInfo.x,["iPosy"] = mPosInfo.y,["iAutoType"] = 1}
        local func = function(oPlayer,mData)
            local oHuodong = global.oHuodongMgr:GetHuodong("herobox")
            local oNpc = oHuodong:GetNpcObj(iNpcId)
            if oNpc then
                oHuodong:do_look(oPlayer,oNpc)
            end
        end
        oCbMgr:SetCallBack(oPlayer.m_iPid,"AutoFindTaskPath",mData,nil,func)
    else
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"每到整点，帝都外各场景都会出现灵魂宝箱")
    end
end

function CHuodong:RecordOpen(oPlayer,oNpc)
    self.m_mOpenRecord[oPlayer.m_iPid] = self.m_mOpenRecord[oPlayer.m_iPid] or {}
    table.insert(self.m_mOpenRecord[oPlayer.m_iPid],oNpc.m_ID)
    self:PushRecord(oPlayer)
end

function CHuodong:PushRecord(oPlayer)
    local mData = self.m_mOpenRecord[oPlayer.m_iPid] or {}
    oPlayer:Send("GS2CHeroBoxRecord",{npcid=mData})
end

function CHuodong:OnLogin(oPlayer)
    self:PushRecord(oPlayer)
end
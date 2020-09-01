-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"
local templ = import(service_path("templ"))
local itemdefines = import(service_path("item.itemdefines"))
local loaditem = import(service_path("item/loaditem"))
local gamedefines = import(lualib_path("public.gamedefines"))

local FREEACTIVE_LEVEL = 4
local FREEACTIVE_INTERVAL = 86400

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "猎灵"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()

end

function CHuodong:GetNpcBaseInfo(iLevel)
    local mData = res["daobiao"]["huodong"][self.m_sName]["config"]
    local mInfo = mData[iLevel]
    assert(mInfo,"GetNpcBaseInfo falid:"..iLevel)
    return mInfo
end

function CHuodong:GetNpcStatus(oPlayer,iLevel)
    return oPlayer.m_oHuodongCtrl:GetNpcStatus(iLevel)
end

--iType:0免费 1付费
function CHuodong:CallHuntNpc(oPlayer,iType)
    if self:GetNpcStatus(oPlayer,FREEACTIVE_LEVEL) == 1 then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"该档次NPC已激活")
        return
    end
    if iType == 0 then
        local mHuntInfo = oPlayer.m_oHuodongCtrl:PackHuntInfo()

        if (mHuntInfo["freeinfo"][FREEACTIVE_LEVEL] and (get_time() - mHuntInfo["freeinfo"][FREEACTIVE_LEVEL]) < FREEACTIVE_INTERVAL) then
            global.oNotifyMgr:Notify(oPlayer.m_iPid,"免费召唤时间未到")
            return
        end
        oPlayer.m_oHuodongCtrl:FreeActiveHuntNpc(FREEACTIVE_LEVEL)
        local mInfo = self:GetNpcBaseInfo(FREEACTIVE_LEVEL)
        global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,string.format("直接激活%s次数",mInfo["name"]),{value=1})
    elseif iType == 1 then
        local mInfo = self:GetNpcBaseInfo(FREEACTIVE_LEVEL)
        local iCost = mInfo["activate_cost"]
        if not oPlayer:ValidGoldCoin(iCost) then
            global.oNotifyMgr:Notify(oPlayer.m_iPid,"水晶不足")
            return
        end
        oPlayer:ResumeGoldCoin(iCost,"召唤猎灵NPC")
        oPlayer.m_oHuodongCtrl:ActiveHuntNpc(FREEACTIVE_LEVEL,true)
        global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,string.format("直接激活%s次数",mInfo["name"]),{value=1})
    end
    local m = self:GetNpcBaseInfo(FREEACTIVE_LEVEL)
    global.oNotifyMgr:Notify(oPlayer.m_iPid,string.format("恭喜你遇到了%s%s",m["npc_color"],m["name"]))
end

function CHuodong:GetNextLevelRatio(oPlayer,iLevel)
    local iNext = iLevel + 1
    local mData = res["daobiao"]["huodong"][self.m_sName]["config"]
    if mData[iNext] and self:GetNpcStatus(oPlayer,iNext) ~= 1 then
        return mData[iNext]["activate_ratio"]
    end
    return 0
end

function CHuodong:HuntSoul(oPlayer,iLevel)
    if not (self:GetNpcStatus(oPlayer,iLevel) == 1) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"该NPC尚未激活")
        return
    end
    local mInfo = self:GetNpcBaseInfo(iLevel)
    local iCost = mInfo["hunt_cost"]
    if not oPlayer:ValidCoin(iCost) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"金币不足")
        return
    end
    oPlayer:ResumeCoin(iCost,"猎灵")
    local iNextLevelRatio = self:GetNextLevelRatio(oPlayer,iLevel)
    local iNextActive = 0
    if in_random(iNextLevelRatio,100) then
        local m = self:GetNpcBaseInfo(iLevel+1)
        global.oNotifyMgr:Notify(oPlayer.m_iPid,string.format("恭喜你遇到了%s%s",m["npc_color"],m["name"]))
        oPlayer.m_oHuodongCtrl:ActiveHuntNpc(iLevel+1)
        global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,string.format("激活%s次数",m["name"]),{value=1})
        iNextActive = 1
    end
    local iType,iID = self:RandomItem(oPlayer,iLevel)
    if iType == 2 then
        local mHuntSetting  = oPlayer.m_oBaseCtrl:GetSystemSetting("huntsetting")
        if mHuntSetting["auto_sale"] == 1 then
            self:RewardHuntSoul(oPlayer,2,iID)
        else
            oPlayer.m_oHuodongCtrl:HuntSoul(iLevel,iType,iID)
        end
    else
        oPlayer.m_oHuodongCtrl:HuntSoul(iLevel,iType,iID)
    end
    oPlayer:AddSchedule("hunt")
    oPlayer.m_oHuodongCtrl:InActiveHuntNpc(iLevel)
    oPlayer.m_oHuodongCtrl:RefreshHuntInfo()
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"猎灵次数",{value=1})
    oPlayer:Send("GS2CHuntSuccess",{level = iLevel,next_active = iNextActive})
end

function CHuodong:RandomItem(oPlayer,iLevel)
    local iHuntTimes = oPlayer.m_oActiveCtrl:GetData("hunt_times",0)
    oPlayer.m_oActiveCtrl:SetData("hunt_times",iHuntTimes+1)
    if iHuntTimes == 0 then
        local oPartner = oPlayer.m_oPartnerCtrl:GetMainPartner()
        if oPartner then
            local iParId = oPartner:SID()
            local mInfo = res["daobiao"]["partner"]["partner_gonglue"]
            local iSid = itemdefines.RandomParSoulByQuality(mInfo[iParId]["equip_list"][1],2)
            return 1,iSid
        end
    end
    local mInfo = self:GetNpcBaseInfo(iLevel)
    local iTotalWeight = 0
    for _,info in pairs(mInfo["pool_list"]) do
        iTotalWeight = iTotalWeight + info["weight"]
    end
    local iRan = math.random(iTotalWeight)
    local iCurWeight = 0
    for _,info in pairs(mInfo["pool_list"]) do
        iCurWeight = iCurWeight + info["weight"]
        if iRan <= iCurWeight then
            if info["type"] == 1 then
                ------TODO
                local iType,iSid = self:RandomSoul(info["id"])
                if info["id"] >= 5 then
                    local sNpcName = mInfo["name"]
                    local oItem = loaditem.GetItem(iSid)
                    local sItemName = oItem:Name()
                    local sColorName = self:_ColorName(oItem:Quality())
                    global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,string.format("猎灵获得%s御灵个数",sColorName),{value = 1})
                    sItemName = string.format(loaditem.FormatItemColor(oItem:Quality(),"%s"), "["..sItemName.."]")
                    local sMsg = string.format("#R%s#n在猎灵过程中得到%s%s#n的帮助，成功获得了御灵{link27, %d, %s}",oPlayer:GetName(),mInfo["npc_color"],sNpcName,iSid,sItemName)
                    local oNotify = global.oNotifyMgr
                    oNotify:SendSysChat(sMsg,1,1)
                end
                return 1,iSid
            end
            return info["type"],info["id"]
        end
    end
end

function CHuodong:_ColorName(iQuality)
    local res = require "base.res"
    local mData = res["daobiao"]["itemcolor"][iQuality]
    assert(mData, string.format("format item color err:%s", iQuality))
    return mData.name
end

-----TODO:生成一个对应品质的随机散件
function CHuodong:RandomSoul(iQuality)
    local iType = self:RandomSoulType()
    local iSid = itemdefines.RandomParSoulByQuality(nil,iQuality,iType)
    return iType,iSid
end

function CHuodong:RandomSoulType()
    local mData = res["daobiao"]["huodong"][self.m_sName]["soultype_config"]
    local iTotalWeight = 0
    for iType,info in pairs(mData) do
        iTotalWeight = iTotalWeight + info["weight"]
    end
    local iR = math.random(iTotalWeight)
    local iC = 0
    for iType,info in pairs(mData) do
        iC = iC + info["weight"]
        if iR<= iC then
            return iType
        end
    end
end

function CHuodong:PickUpSoul(oPlayer,iCreateTime,iId)
    if not self:ValidPickUp(oPlayer,iId) then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"御灵已满，请清理后再拾取新的御灵")
        return
    end
    oPlayer.m_oHuodongCtrl:PickUpSoul(iCreateTime)
end

function CHuodong:SetAutoSale(oPlayer,iAuto)
    oPlayer.m_oBaseCtrl:SetSystemSetting({huntsetting = {auto_sale=iAuto}})
end

function CHuodong:PickUpSoulByOneKey(oPlayer)
    oPlayer.m_oHuodongCtrl:PickUpSoulByOneKey()
end


function CHuodong:ValidPickUp(oPlayer,iSid)
    return oPlayer:ValidGive({{iSid,1}})
end

-----
function CHuodong:SaleSoulByOneKey(oPlayer)
    local iAmount,iSoulId = oPlayer.m_oHuodongCtrl:SaleSoulByOneKey()
    local iSalePrice = global.oWorldMgr:QueryGlobalData("hunt_saleprice")
    iSalePrice = tonumber(iSalePrice)
    local iGet = iAmount*iSalePrice
    if iGet == 0 then
        return
    end
    oPlayer:RewardCoin(iGet,"猎灵",{cancel_tip = true})
    global.oNotifyMgr:Notify(oPlayer.m_iPid,string.format("出售灵气渣,获得%s#G%d",self:CoinIcon(gamedefines.COIN_FLAG.COIN_COIN),iGet))
end

function CHuodong:RewardHuntSoul(oPlayer,iType,iID)
    if iType == 2 then
        local iSalePrice = global.oWorldMgr:QueryGlobalData("hunt_saleprice")
        iSalePrice = tonumber(iSalePrice)
        oPlayer:RewardCoin(iSalePrice,"猎灵",{cancel_tip = true})
        global.oNotifyMgr:Notify(oPlayer.m_iPid,string.format("出售灵气渣,获得%s#G%d",self:CoinIcon(gamedefines.COIN_FLAG.COIN_COIN),iSalePrice))
    else
        oPlayer:GiveItem({{iID,1}},"猎灵")
    end

end

function CHuodong:CoinIcon(iType)
    local mCoinInfo = gamedefines.COIN_TYPE[iType]
    assert(mCoinInfo,string.format("MaxCoin %d",iType))
    return mCoinInfo.icon or mCoinInfo.name
end
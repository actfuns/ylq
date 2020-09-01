--import module
local global = require "global"
local record = require "public.record"

local defines = import(service_path("house.defines"))

function C2GSEnterHouse(oPlayer,mData)
    local iTarget = mData["target"]
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    if not oPlayer:IsSingle() then
        oNotifyMgr:Notify(oPlayer.m_iPid,"组队不能进入宅邸")
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oHouseMgr:EnterHouse(oPlayer,iTarget)
end

function C2GSLeaveHouse(oPlayer,mData)
    local oHouseMgr = global.oHouseMgr
    local iPid = oPlayer.m_iPid
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSLeaveHouse pid:%s", iPid)
        return
    end
    oHouse:LeaveHouse(iPid)
end

function C2GSHousePromoteFurniture(oPlayer, mData)
    local iType = mData["type"]
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer.m_iPid
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSHousePromoteFurniture pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    local oFurniture = oHouse:GetFurniture(iType)
    if not oFurniture or not oFurniture:ValidPromoteLevel(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oFurniture:PromoteLevel(iPid)
end

function C2GSHouseSpeedFurniture(oPlayer,mData)
    local iType = mData["type"]
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer.m_iPid
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSHouseSpeedFurniture pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
     local oFurniture = oHouse:GetFurniture(iType)
    if not oFurniture or not oFurniture:ValidSpeed() then
        return
    end
    local iTime = oFurniture:Timer()
    local iGoldTime = 15 * 60
    local iGold = 0
    if iTime % iGoldTime == 0 then
        iGold = math.floor(iTime / iGoldTime)
    else
        iGold = math.floor(iTime // iGoldTime) + 1
    end
    iGold = math.max(iGold,1)
    if not oPlayer:ValidGoldCoin(iGold) then
        return
    end
    local sReason = "宅邸家具加速"
    oPlayer:ResumeGoldCoin(iGold, sReason)
    oFurniture:TruePromoteLevel(1, sReason)
end

function C2GSOpenWorkDesk(oPlayer,mData)
    local iPid = oPlayer.m_iPid
    local oNotifyMgr = global.oNotifyMgr
    local oHouseMgr = global.oHouseMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSOpenWorkDesk pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    -- local iType = defines.FURNITURE_TYPE.WORK_DESK
    -- local oFurniture = oHouse:GetFurniture(iType)
    --[[test
    if oFurniture:IsLockStatus() then
        oNotifyMgr:Notify(iPid,"工作台尚未解锁,无法开启")
        return
    end
    ]]
    -- oFurniture:OpenWorkDesk(iPid)
    oHouseMgr:OpenWorkDesk(oPlayer, mData["target_pid"])
end

function C2GSTalentShow(oPlayer,mData)
    local iPos = mData["pos"]
    local iPid = oPlayer.m_iPid
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSTalentShow pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local iType = defines.FURNITURE_TYPE.WORK_DESK
    local oFurniture = oHouse:GetFurniture(iType)
    if not oFurniture:ValidTalentShow(iPid,iPos) then
        return
    end
    oFurniture:TalentShow(iPid,iPos)
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30005,1)
    oPlayer:AddSchedule("TeaArt")
end

function C2GSTalentDrawGift(oPlayer,mData)
    local iPos = mData["pos"]
    local iPid = oPlayer.m_iPid
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSTalentDrawGift pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local iType = defines.FURNITURE_TYPE.WORK_DESK
    local oFurniture = oHouse:GetFurniture(iType)
    if not oFurniture:ValidDrawGift(iPid,iPos) then
        return
    end
    oFurniture:DrawGift(iPid,iPos)
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30031, 1)
end

function C2GSHelpFriendWorkDesk(oPlayer,mData)
    local iPid = oPlayer.m_iPid
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSHelpFriendWorkDesk pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local iType = defines.FURNITURE_TYPE.WORK_DESK
    local oFurniture = oHouse:GetFurniture(iType)
    if not oFurniture:ValidHelpFriendWorkDesk(iPid) then
        return
    end
    oFurniture:HelpFriendWorkDesk(iPid)
end

function C2GSUseFriendWorkDesk(oPlayer,mData)
    local iTarget = mData["target"]
    local iPid = oPlayer.m_iPid
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    -- if not oHouse:InHouse(iPid) then
    --     return
    -- end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    if oPlayer.m_oToday:Query("usefriend_workdesk",0) >= 5 then
        oNotifyMgr:Notify(iPid,"今日可租赁的次数已用完喽，明天再来吧！")
        return
    end
    -- local oHouse = oHouseMgr:GetHouse(iTarget)
    -- if oHouse then
    --     local iType = defines.FURNITURE_TYPE.WORK_DESK
    --     local oFurniture = oHouse:GetFurniture(iType)
    --     if not oFurniture:ValidUseFriendWorkDesk(iPid) then
    --         return
    --     end
    --     oFurniture:UseFriendWorkDesk(iPid)
    -- end
    oHouseMgr:UseFriendWorkDesk(oPlayer, iTarget)
end

function C2GSOpenExchangeUI(oPlayer,mData)
    local iPid = oPlayer.m_iPid
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSOpenExchangeUI pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oHouse:OpenExchangeUI(iPid)
end

function C2GSLovePartner(oPlayer,mData)
    local iType = mData["type"]
    local iPart = mData["body_part"]
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer.m_iPid
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSLovePartner pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local sPart = defines.GetPartnerBodyPartName(iPart)
    if not sPart then
        return
    end
    oHouse:ShowLove(iPid,iType,sPart)
end

function C2GSGivePartnerGift(oPlayer,mData)
    local iType = mData["type"]
    local iItemid = mData["itemid"]
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer.m_iPid
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSGivePartnerGift pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oHouse:GivePartnerGift(iPid,iType,iItemid)
end

function C2GSTrainPartner(oPlayer,mData)
    local iType = mData["type"]
    local iTrainType = mData["train_type"]
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer.m_iPid
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSTrainPartner pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oHouse:TrainPartner(iType,iTrainType)
end

function C2GSUnChainPartnerReward(oPlayer,mData)
    local iType = mData["type"]
    local iLevel = mData["level"]
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSUnChainPartnerReward pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oHouse:UnChainPartnerReward(oPlayer,iType,iLevel)
end

function C2GSRecievePartnerTrain(oPlayer, mData)
    local oHouseMgr = global.oHouseMgr
    local iParType = mData["train_type"]
    local iPid = oPlayer:GetPid()
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSRecievePartnerTrain pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oHouse:RecievePartnerTrain(oPlayer,iParType)
end

function C2GSFriendHouseProfile(oPlayer, mData)
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr

    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oHouseMgr:QueryFriendHouseProfile(oPlayer)
end

function C2GSRecieveHouseCoin(oPlayer, mData)
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr

    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oHouseMgr:RecieveHouseCoin(oPlayer, mData["frd_pid"])
end

function C2GSAddPartnerGift(oPlayer, mData)
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(iPid,"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSAddPartnerGift pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    oHouse:AddPartnerGiftCnt(oPlayer, mData["cnt"], mData["cost"])
end


function C2GSWorkDeskSpeedFinish(oPlayer, mData)
    local oHouseMgr = global.oHouseMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    if oHouseMgr:IsClose() then
        oNotifyMgr:Notify(iPid,"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        record.error("C2GSWorkDeskSpeedFinish pid:%s", iPid)
        return
    end
    if not oHouse:InHouse(iPid) and not oHouse:IsOwner(iPid) then
        return
    end
    local iType = defines.FURNITURE_TYPE.WORK_DESK
    local oFurniture = oHouse:GetFurniture(iType)
    if not oFurniture then
        return
    end
    oFurniture:WorkDeskSpeedFinish(iPid, mData["pos"], mData["cost"])
end
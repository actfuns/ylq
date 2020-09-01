local  global = require "global"

function C2GSAchieveMain(oPlayer,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Forward("C2GSAchieveMain",oPlayer:GetPid(),mData)
end

function C2GSAchieveDirection(oPlayer,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Forward("C2GSAchieveDirection",oPlayer:GetPid(),mData)
end

function C2GSAchieveReward(oPlayer,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Forward("C2GSAchieveReward",oPlayer:GetPid(),mData)
end

function C2GSAchievePointReward(oPlayer,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Forward("C2GSAchievePointReward",oPlayer:GetPid(),mData)
end

function C2GSOpenPicture(oPlayer,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Forward("C2GSOpenPicture",oPlayer:GetPid(),mData)
end

function C2GSPictureReward(oPlayer,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Forward("C2GSPictureReward",oPlayer:GetPid(),mData)
end

function C2GSCloseMainUI(oPlayer,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Forward("C2GSCloseMainUI",oPlayer:GetPid(),mData)
end

function C2GSOpenSevenDayMain(oPlayer, mData)
    local oAchieveMgr = global.oAchieveMgr
    if oAchieveMgr:IsSevAchieveClose(oPlayer) then
        return
    end
    oAchieveMgr:Forward("C2GSOpenSevenDayMain", oPlayer:GetPid(), mData)
end

function C2GSOpenSevenDay(oPlayer, mData)
    local oAchieveMgr = global.oAchieveMgr
    if oAchieveMgr:IsSevAchieveClose(oPlayer) then
        return
    end
    oAchieveMgr:Forward("C2GSOpenSevenDay", oPlayer:GetPid(), mData)
end

function C2GSSevenDayReward(oPlayer, mData)
    local oAchieveMgr = global.oAchieveMgr
    if oAchieveMgr:IsSevAchieveClose(oPlayer) then
        return
    end
    oAchieveMgr:Forward("C2GSSevenDayReward", oPlayer:GetPid(), mData)
end

function C2GSSevenDayPointReward(oPlayer, mData)
    local oAchieveMgr = global.oAchieveMgr
    if oAchieveMgr:IsSevAchieveClose(oPlayer) then
        return
    end
    oAchieveMgr:Forward("C2GSSevenDayPointReward", oPlayer:GetPid(), mData)
end

function C2GSBuySevenDayGift(oPlayer, mData)
    local oAchieveMgr = global.oAchieveMgr
    if oAchieveMgr:IsSevAchieveClose(oPlayer) then
        return
    end
    oAchieveMgr:BuySevenDayGift(oPlayer, mData)
    -- oAchieveMgr:Forward("C2GSOpenSevenDay", oPlayer:GetPid(), mData)
end

function C2GSGetAchieveTaskReward(oPlayer,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Forward("C2GSGetAchieveTaskReward",oPlayer:GetPid(),mData)
end
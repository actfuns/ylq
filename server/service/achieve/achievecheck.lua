local global = require "global"
local skynet = require "skynet"
local net = require "base.net"

function NewAchieveCheck(...)
    local o = CAchieveCheck:New(...)
    return o
end

local mKey2Func={
    ["玩家战力"] = "CalPlayerPower",
}

CAchieveCheck = {}
CAchieveCheck.__index = CAchieveCheck
inherit(CAchieveCheck, logic_base_cls())

function CAchieveCheck:New()
    local o = super(CAchieveCheck).New(self)
    return o
end

function CAchieveCheck:CheckCondition(iPid,iAchieveID,sKey,data,degreetype)
    local sFunName = mKey2Func[sKey]
    local value = data["value"]
    if sFunName then
        local func = self[sFunName]
        value = func(self,iPid,iAchieveID,sKey,data)
    end
    if value > 0 then
        local oAchieveMgr = global.oAchieveMgr
        if table_in_list({1,3},degreetype) then
            oAchieveMgr:SetDegree(iPid,iAchieveID,value)
        elseif degreetype == 2 then
            oAchieveMgr:AddDegree(iPid,iAchieveID,value)
        end
    end
end

function CAchieveCheck:CalPlayerPower(iPid,iAchieveID,sKey,data)
    local oAchieveMgr = global.oAchieveMgr
    local oPlayer = oAchieveMgr:GetPlayer(iPid)
    if data.power then
        oPlayer:UpdatePower(data.power)
    end
    if data.ppower then
        oPlayer:UpdatePartnerPower(data.ppower)
    end
    return oPlayer:GetWarPower()
end

function CAchieveCheck:CheckSevenDayCondition(iPid,iAchieveID,sKey,data,degreetype)
    local sFunName = mKey2Func[sKey]
    local value = data["value"]
    if sFunName then
        local func = self[sFunName]
        value = func(self,iPid,iAchieveID,sKey,data)
    end
    if value > 0 then
        local oAchieveMgr = global.oAchieveMgr
        if table_in_list({1,3},degreetype) then
            oAchieveMgr:SetSevenDayDegree(iPid,iAchieveID,value)
        elseif degreetype == 2 then
            oAchieveMgr:AddSevenDayDegress(iPid,iAchieveID,value)
        end
    end
end
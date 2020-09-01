local global = require "global"

local loaditem = import(service_path("item/loaditem"))

Commands = {}
Helpers = {}
Opens = {}  --是否对外开放

Helpers.help = {
    "GM指令帮助",
    "help 指令名",
    "help 'clearall'",
}
function Commands.help(oMaster, sCmd)
    if sCmd then
        local o = Helpers[sCmd]
        if o then
            local sMsg = string.format("%s:\n指令说明:%s\n参数说明:%s\n示例:%s\n", sCmd, o[1], o[2], o[3])
            oMaster:Send("GS2CGMMessage", {
                msg = sMsg,
            })
        else
            oMaster:Send("GS2CGMMessage", {
                msg = "没查到这个指令"
            })
        end
    end
end

Helpers.house = {
    "宅邸指令",
    "示例:house 100",
}
function Commands.house(oMaster,iCmd,...)
    local oHouseMgr = global.oHouseMgr
    local iPid = oMaster:GetPid()
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        return
    end
    if not oHouse:InHouse(iPid) then
        return
    end
    oHouse:TestOP(oMaster,iCmd,...)
end

function Commands.houseinit(oMaster)
    local oHouseMgr = global.oHouseMgr
    local iPid = oMaster.m_iPid
    oHouseMgr:InitHouse(iPid)
end

Helpers.houseclone = {
    "克隆宅邸道具",
    "houseclone 物品类型 物品数量",
    "houseclone 12000 100",
}
function Commands.houseclone(oMaster,sid,iAmount)
    local oNotifyMgr = global.oNotifyMgr
    local itemobj = loaditem.GetItem(sid)
    if not itemobj then
        return
    end
    local iPid = oMaster.m_iPid
    local oHouseMgr = global.oHouseMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        return
    end

    local oItem = loaditem.GetItem(sid)
    if oItem:ItemType() ~= "housegift" then
        oNotifyMgr:Notify(iPid, "非宅邸道具")
        return
    end

    while(iAmount>0) do
        local itemobj = loaditem.Create(sid)
        local iMaxAmount = itemobj:GetMaxAmount()
        local iAddAmount = math.min(iAmount,iMaxAmount)
        iAmount = iAmount - iAddAmount
        itemobj:SetAmount(iAddAmount)
        local retobj = oHouse:AddItem(itemobj,"gm")
        if retobj then
            oNotifyMgr:Notify(oMaster.m_iPid,"已满，无法获得道具")
            return
        end
    end
end
--import module

local global = require "global"

local gamedefines = import(lualib_path("public/gamedefines"))
local loaditem = import(service_path("item/loaditem"))
local itemdefines = import(service_path("item/itemdefines"))

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

Helpers.clone = {
    "克隆道具",
    "clone 物品类型 物品数量 绑定",
    "clone 1001 200 1",
}
function Commands.clone(oMaster,sid,iAmount,iBind)
    local res = require "base.res"
    local mData = res["daobiao"]["item"][sid]
    local oNotifyMgr = global.oNotifyMgr
    if not mData then
        oNotifyMgr:Notify(oMaster:GetPid(),"没有该道具")
        return
    end
    if type(iAmount) ~= "number" or iAmount <= 0 then
         oNotifyMgr:Notify(oMaster:GetPid(),"参数错误")
        return
    end
    local iPid = oMaster:GetPid()
    local lType = table_value_list(gamedefines.ITEM_CONTAINER)
    local itemobj = loaditem.GetItem(sid)
    if not table_in_list(lType, itemobj:Type()) then
       oNotifyMgr:Notify(iPid,"该道具不属于背包物品")
       return
    end
    local oNotifyMgr = global.oNotifyMgr
    -- iBind = iBind or 0
    local lGive = {{sid, iAmount}}
    if oMaster:ValidGive(lGive) then
        oMaster:GiveItem(lGive, "gm", {cancel_tip=1, cancel_show = 1}, function(mRecord,mData)
            if mData.success then
                oNotifyMgr:Notify(iPid, "添加道具成功")
            else
                oNotifyMgr:Notify(iPid, "添加道具失败")
            end
        end)
    end
end

Helpers.cloneall = {
    "同类型道具添加一个",
    "cloneall 物品类型",
    "cloneall 1",
}
function Commands.cloneall(oMaster,iType)
    local CONTAINER_TYPE = itemdefines.CONTAINER_TYPE
    local lType = table_value_list(CONTAINER_TYPE)
    local res = require "base.res"
    local mData = res["daobiao"]["item"]
    local lGive = {}
    if table_in_list(lType, iType) then
        for id, m in pairs(mData) do
            if m.type and m.type == iType then
                table.insert(lGive, {id, 1})
            end
        end
    end
    oMaster:GiveItem(lGive, "gm", {cancel_tip = 1, cancel_channel=1})
end

Helpers.removeitem = {
    "克隆道具",
    "removeitem  物品id 绑定",
    "removeitem 1 200",
}
function Commands.removeitem(oMaster, iItemid, iAmount)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oMaster:GetPid()
    local oItem = oMaster:HasItem(iItemid)
    if not oItem then
        oNotifyMgr:Notify(iPid, "道具不存在")
        return
    end
    local iHaveAmount = oItem:GetAmount()
    if iHaveAmount >= iAmount then
        oMaster.m_oItemCtrl:AddAmount(oItem,-iAmount,"gm")
        oNotifyMgr:Notify(iPid, "成功扣除道具")
    else
        oNotifyMgr:Notify(iPid, "道具不足")
    end
end

Helpers.setitemendtime = {
    "设置道具时效",
    "setitemendtime 物品id 结束时间 单位为秒",
    "setitemendtime 2 3600 ",
}
function Commands.setitemendtime(oMaster, iItemid, iEndTime)
    iEndTime = iEndTime or 0
    local oItem = oMaster:HasItem(iItemid)
    if oItem then
        oItem:SetTimer(iEndTime)
    else
        oNotifyMgr:Notify(iPid, string.format("编号为%s 的道具不存在"), iItemid)
    end
end

Helpers.clearall = {
    "清空背包",
    "clearall",
    "clearall",
}
function Commands.clearall(oMaster)
    oMaster.m_oItemCtrl:TestCmd(oMaster:GetPid(),"clearall", {})
end

Helpers.addequipexp = {
    "添加装备经验",
    "addequipexp 装备服务器id 经验值",
    "示例：addequipexp 1 1000",
}
function Commands.addequipexp(oMaster, ...)
    oMaster.m_oItemCtrl:TestCmd(oMaster:GetPid(),"addequipexp", {...})
end

function Commands.clearstonebuff(oMaster)
    oMaster.m_oItemCtrl:TestCmd(oMaster:GetPid(),"clearstonebuff", {})
end

function Commands.init_item_robot(oMaster,lShape)
    local res = require "base.res"
    local measure = require "measure"
    measure.start()
    for _,iShape in pairs(lShape) do
        local oItem = loaditem.Create(iShape)
        local iMaxAmount = oItem:GetMaxAmount()
        oItem:SetAmount(iMaxAmount)
        oMaster:RewardItem(oItem,"testclone")
    end
end

function Commands.debug_arrange(oMaster)
    oMaster.m_oItemCtrl:TestCmd(oMaster:GetPid(),"debug_arrange", {})
end

function Commands.stonebufftime(oMaster, ...)
    oMaster.m_oItemCtrl:TestCmd(oMaster:GetPid(),"stonebufftime", {...})
end

function Commands.shapeitem(oMaster, iType)
    local sid = string.format("1027(gain_way=%s)", iType)
    local oItem = loaditem.ExtCreate(sid)
    oMaster:RewardItem(oItem, "gm")
end

function Commands.fullitem(oMaster, ...)
    oMaster.m_oItemCtrl:TestCmd(oMaster:GetPid(),"fullitem", {})
end

function Commands.printitem(oMaster, ...)
    oMaster.m_oItemCtrl:TestCmd(oMaster:GetPid(),"printitem", {...})
end

function Commands.printparsoul(oMaster)
    print("gtxiedebug, random partner soul sid:", itemdefines.RandomParSoulByQuality())
end

function Commands.printNotExist(oMaster, ...)
    local mOther = {}
    for sid = 10001, 16000 do
        if global.oDerivedFileMgr:ExistFile("item","other","i"..sid) then
            mOther[sid] = 1
        end
    end
    oMaster.m_oItemCtrl:TestCmd(oMaster:GetPid(),"printNotExist", mOther)
end

function Commands.svndelete(oMaster, ...)
    local lSid = {}
    local sPath = ""
    for _, sid in ipairs(lSid) do
        if global.oDerivedFileMgr:ExistFile("item","other","i"..sid) then
            sPath = sPath ..  " service/world/item/other/i" .. sid .. ".lua"
        end
    end
    print("gtxiedebug delet world item files:", sPath)
    os.execute(string.format("svn del %s", sPath))
    oMaster.m_oItemCtrl:TestCmd(oMaster:GetPid(),"svndelete", {})
end
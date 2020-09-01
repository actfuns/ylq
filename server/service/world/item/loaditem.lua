local global = require "global"
local extend = require "base/extend"

local ItemList = {}

local ItemDir = {
    ["virtual"]  = {1001,10000},
    ["other"]   = {10001,15999},
    ["housegift"] = {30001,39999},
    ["gem"] = {18000,18999},
    ["fuwen"] = {19000,19999},
    ["partnerchip"] = {20000,20999},
    ["partnerequip"] = {21000, 26999},
    ["awakeitem"] = {27400, 27499},
    ["partnertravel"] = {27501, 27599},
    ["giftbag"] = {27600, 28000},

    ["partnerskin"] = {200001, 219999},
    ["parstone"] = {300001, 399999},
    ["parequip"] = {6000001, 6999999},
    ["parsoul"] = {7000001, 7999999},
    ["equip"] = {2000000,2999900},
    ["equipstone"] = {3000000,5000000},
}
function GetItemGroup(iGroup)
    local res = require "base.res"
    local mData = res["daobiao"]["itemgroup"]
    mData = mData[iGroup]
    assert(mData,string.format("GetItemGroup err:%d",iGroup))
    return mData["itemgroup"]
end

function GetItemDir(sid)
    for sDir,mPos in pairs(ItemDir) do
        local iStart,iEnd = table.unpack(mPos)
        if iStart <= sid and sid <= iEnd then
            return sDir
        end
    end
end

function GetItemPath(sid)
    local sDir = GetItemDir(sid)
    assert(sDir,string.format("item path err:%s",sid))
    if global.oDerivedFileMgr:ExistFile("item",sDir,"i"..sid) then
        return string.format("item/%s/i%d",sDir,sid)
    end
    return string.format("item/%s/%sbase",sDir,sDir)
end

function Create(sid,...)
    sid = tonumber(sid)
    assert(sid,string.format("loaditem Create err:%s",sid))
    if sid < 1000 then
        local mItemGroup = GetItemGroup(sid)
        sid = mItemGroup[math.random(#mItemGroup)]
    end
    local sPath = GetItemPath(sid)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("loaditem err:%d",sid))
    local oItem = oModule.NewItem(sid)
    oItem:Create(...)
    oItem:Setup()
    return oItem
end

function ExtCreate(sid,...)
    local sArg
    if tonumber(sid) then
        sid = tonumber(sid)
    else
        sid,sArg = string.match(sid,"(%d+)(.+)")
        sid = tonumber(sid)
    end
    local oItem = Create(sid,...)
    if sArg then
        sArg = string.sub(sArg,2,#sArg-1)
        local mArg = split_string(sArg,",")
        for _,sArg in ipairs(mArg) do
            local key,value = string.match(sArg,"(.+)=(.+)")
            if tonumber(value) then
                value = tonumber(value)
            end
            local sAttr = string.format("m_i%s",key)
            if oItem[sAttr] then
                oItem[sAttr] = value
            else
                oItem:SetData(key,value)
            end
        end
    end
    return oItem
end

function GetItem(sid,...)
    local oItem = ItemList[sid]
    if not oItem then
        oItem = ExtCreate(sid,...)
        ItemList[sid] = oItem
    end
    return oItem
end

function LoadItem(sid,data)
    sid = tonumber(sid)
    assert(sid,string.format("loaditem LoadItem err:%s",sid))
    local sPath = GetItemPath(sid)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("loaditem err:%d",sid))
    local oItem = oModule.NewItem(sid)
    oItem:Load(data)
    oItem:Setup()
    return oItem
end

function CopyItem(oItem)
    local sid = oItem:SID()
    local dSave = oItem:Save()
    local dCopy = table_deep_copy(dSave)
    local oCopyItem = LoadItem(sid,dCopy)
    return oCopyItem
end

function FormatItemColor(iColor, sMsg)
    local res = require "base.res"
    local mData = res["daobiao"]["itemcolor"][iColor]
    assert(mData, string.format("format item color err:%s,%s", iColor, sMsg))
    return string.format(sMsg, mData.color)
end

function GetItemData(iSid)
    local res = require "base.res"
    local mData = res["daobiao"]["item"][iSid]
    return mData
end

function ItemColorName(iSid)
    local mData = GetItemData(iSid)
    if mData then
        local res = require "base.res"
        local mColor = res["daobiao"]["itemcolor"][mData.quality]
        if mColor then
            return string.format(mColor.color, mData.name)
        end
    end
    return ""
end
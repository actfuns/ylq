local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

local itembase = import(service_path("item/itembase"))
local loaditem = import(service_path("item/loaditem"))
local itemdefines = import(service_path("item/itemdefines"))

CItem = {}
CItem.__index = CItem
CItem.m_ItemType = "giftbag"
inherit(CItem,itembase.CItem)

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:RealObj()
    -- body
end

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:GetMaxAmount()
    return 1
end


function CItem:GetShowInfo()
    return {
        id = self:ID(),
        sid = self:SID(),
        virtual = self:SID(),
        amount = self:GetData("value", 1),
    }
end

function CItem:LogInfo()
    return {
        ["物品编号"] = self:SID(),
        ["数量"] = self:GetData("value", 1),
    }
end

function CItem:Reward(oPlayer,sReason,mArgs)
    mArgs = mArgs or {}
    local iPid = oPlayer:GetPid()
    local lReward = self:GetUseReward()
    assert(lReward, string.format("giftbag TrueUse:%s", self:SID()))
    local lFilter = self:FilterSex(oPlayer, lReward,mArgs)
    local lGiveItem = self:GetGiveItemList(lFilter)
    if #lGiveItem == 0 then
        return
    end
    local sReason = string.format("使用%s",self:Name())
    local arg = {
    cancel_tip = 1,
    }
    oPlayer:GiveItem(lGiveItem, sReason, arg)
    global.oUIMgr:ShowKeepItem(iPid)
end

function CItem:FilterSex(oPlayer, lReward,mArgs)
    local lFilter = {}
    local iSchool = oPlayer:GetSchool()
    local iBranch = oPlayer:GetSchoolBranch()
    for _, mItem in ipairs(lReward) do
        local oItem = loaditem.GetItem(mItem.sid)
        if self:IsEquip(oItem) then
            if self:IsWeapon(oItem) then
                if self:ValidAddWeapon(oPlayer, oItem,mArgs) then
                    table.insert(lFilter, table_deep_copy(mItem))
                end
            elseif oItem:Sex() == gamedefines.EQUIP_SEX_TYPE.COMMON then
                table.insert(lFilter, table_deep_copy(mItem))
            elseif oItem:Sex() == oPlayer:GetSex() then
                table.insert(lFilter, table_deep_copy(mItem))
            end
        else
            table.insert(lFilter, table_deep_copy(mItem))
        end
    end
    return lFilter
end

function CItem:IsEquip(oItem)
    return oItem:Type() == itemdefines.CONTAINER_TYPE.EQUIP_STONE
end

function CItem:IsWeapon(oEquip)
    return oEquip:WieldPos() == itemdefines.EQUIP_WEAPON
end

function CItem:ValidAddWeapon(oPlayer, oEquip,mArgs)
    local res = require "base.res"
    local iSchool = oPlayer:GetSchool()
    local iBranch = oPlayer:GetSchoolBranch()
    local iWeapon = oEquip:WeaponType()
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("switchschool", "open_grade")
    local iGrade = mArgs.grade or 0
    if iGrade < iOpenGrade then
        local mData = res["daobiao"]["schoolweapon"]["weapon"][iSchool][iBranch]
        if mData.weapon == iWeapon then
            return true
        end
    else
        local iSch = res["daobiao"]["schoolweapon"]["school"][iWeapon]
        if iSch == iSchool then
            return true
        end
    end
    return false
end

function CItem:GetGiveItemList(lItem)
    local lGiveItem = {}
    for _, mItem in ipairs(lItem) do
        table.insert(lGiveItem,{mItem.sid,mItem.amount})
    end
    return lGiveItem
end

function CItem:GetTotalWeight(lItem)
    local iWeight = 0
    for _, mItem in ipairs(lItem) do
        iWeight = iWeight + mItem.weight
    end
    return iWeight
end

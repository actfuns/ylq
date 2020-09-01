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
inherit(CItem,itembase.CItem)

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:TrueUse(oPlayer, iTarget, iAmount,mArgs)
    local iPid = oPlayer:GetPid()
    local lReward = self:GetUseReward()
    assert(lReward, string.format("commonbox TrueUse:%s", self:SID()))
    local lFilter = self:FilterSex(oPlayer, lReward,mArgs)
    local lGiveItem = self:GetGiveItemList(lFilter, iAmount)
    if #lGiveItem == 0 then
        return
    end
    if not oPlayer:ValidGive(lGiveItem,{cancel_tip = 1}) then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(iPid, "使用失败，背包已满")
        return
    end
    local sReason = string.format("使用%s",self:Name())
    local mArgs = {
        cancel_tip=1,
    }
    oPlayer.m_oItemCtrl:AddAmount(self,-iAmount,sReason)
    oPlayer:GiveItem(lGiveItem, sReason, mArgs)
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
    local oAssistMgr = global.oAssistMgr
    local iOpenGrade = oAssistMgr:QueryControl("switchschool", "open_grade")
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

function CItem:GetGiveItemList(lItem, iAmount)
    local iTotalWeight = self:GetTotalWeight(lItem)
    assert(iTotalWeight >= 0, string.format("道具sid:%s,字段UseReward error.", self:SID()))
    local lGiveItem = {}
    local mGive = {}
    for i = 1, iAmount do
        local iRanWeight =0
        if iTotalWeight > 0 then
            iRanWeight = math.random(iTotalWeight)
        end
        local iCount = 0
        local bChoose = false
        for _, mItem in ipairs(lItem) do
            iCount = iCount + mItem.weight
            local iHave = mGive[mItem.sid] or 0
            if mItem.weight == 0 then
                mGive[mItem.sid] = iHave + mItem.amount
                -- table.insert(lGiveItem, {mItem.sid,mItem.amount})
            elseif not bChoose and iCount >= iRanWeight then
                mGive[mItem.sid] = iHave + mItem.amount
                -- table.insert(lGiveItem,{mItem.sid,mItem.amount})
                bChoose = true
            end
        end
    end
    for sid, iAmount in pairs(mGive) do
        table.insert(lGiveItem, {sid, iAmount})
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

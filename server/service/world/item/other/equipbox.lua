local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local res = require "base.res"

local gamedefines = import(lualib_path("public.gamedefines"))

local itembase = import(service_path("item/itembase"))
local loaditem = import(service_path("item/loaditem"))
local itemdefines = import(service_path("item/itemdefines"))

local EQUIP_SEX_TYPE = gamedefines.EQUIP_SEX_TYPE

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:TrueUse(who, target, iAmount)
    local iPid = who:GetPid()
    local iSex = who:GetSex()
    local lGiveItem = {}
    local lReward = self:GetUseReward()
    local iSchool = who:GetSchool()
    local iBranch = who:GetSchoolBranch()
    assert(next(lReward), string.format("box sid:%s without item!", self:SID()))
    for _, mItem in ipairs(lReward) do
        local oEquip = loaditem.GetItem(mItem.sid)
        if oEquip:GetItemData()["pos"] == itemdefines.EQUIP_WEAPON then
            local iWeaponType = oEquip:WeaponType()
            if who:GetGrade() < 40 then
                local mData = res["daobiao"]["schoolweapon"]["weapon"][iSchool][iBranch]
                if mData.weapon == iWeaponType then
                    table.insert(lGiveItem, {mItem.sid, mItem.amount * iAmount})
                end
            else
                local iSch = res["daobiao"]["schoolweapon"]["school"][iWeaponType]
                if iSch == iSchool then
                    table.insert(lGiveItem, {mItem.sid, mItem.amount * iAmount})
                end
            end
        elseif oEquip:Sex() == EQUIP_SEX_TYPE.COMMON then
        -- if oEquip:Sex() == EQUIP_SEX_TYPE.COMMON then
            table.insert(lGiveItem, {mItem.sid, mItem.amount * iAmount})
        elseif oEquip:Sex() == iSex then
            table.insert(lGiveItem, {mItem.sid, mItem.amount * iAmount})
        end
    end
    if not who:ValidGive(lGiveItem,{cancel_tip = 1}) then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(iPid, "使用失败，背包已满")
        return
    end
    local sReason = "使用装备礼包"
    who.m_oItemCtrl:AddAmount(self,-iAmount,sReason)
    who:GiveItem(lGiveItem, sReason, {cancel_tip=1})
    global.oUIMgr:ShowKeepItem(iPid)
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end


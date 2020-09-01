local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local extend = require "base.extend"
local res = require "base.res"

local itembase = import(service_path("item/itembase"))
local itemdefines = import(service_path("item.itemdefines"))

local random = math.random

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "fuwen"

function NewItem(sid)
    local o = CItem:New(sid)
    o:InitFuWenAttr()
    return o
end

function CItem:InitFuWenAttr()
    local lAttrs = {}
    local mAttrName = res["daobiao"]["attrname"]
    for sAttr, mData in pairs(mAttrName) do
        if sAttr ~= "cure_critical_ratio" then
            table.insert(lAttrs, sAttr)
        end
    end
    self.m_lFuWenAttrs = lAttrs
end

function CItem:GetFuWenAttr()
    return self.m_lFuWenAttrs
end

function CItem:Level()
    return self:GetItemData()["level"]
end

function CItem:WieldPos()
    return self:GetItemData()["pos"]
end

function CItem:CalculateFuWenK()
    local mData = res["daobiao"]["fuwen_wave"]
    local mRatio = {}
    for iNo,mRatioData in pairs(mData) do
        mRatio[iNo] = mRatioData["ratio"]
    end
    local iNo = table_choose_key(mRatio)
    local mRatioData = mData[iNo]
    local iMinRatio = mRatioData["min_ratio"]
    local iMaxRatio = mRatioData["max_ratio"]
    return math.random(iMinRatio,iMaxRatio)
end

function CItem:ResetQuality(oEquip)
    local mFuWenData = itemdefines.GetFuWenData(oEquip:EquipPos(), oEquip:EquipLevel())
    local mQuality = mFuWenData.quality or {}
    local mTbl = {}
    for k,v in ipairs(mQuality) do
        if v > 0 then
            mTbl[k] = v
        end
    end
    return table_choose_key(mTbl)
end

function CItem:ResetFuWen(oEquip)
    local iAttrCnt = 2
    local mAttr = {}
    local iLevel = oEquip:EquipLevel()
    local mFuWen = oEquip:CurrentFuWen()
    local sDelAttr = table_random_key(mFuWen)
    local lTotalAttr = table_value_list(self.m_lFuWenAttrs)
    extend.Array.remove(lTotalAttr, sDelAttr)
    local lAttrs = extend.Random.random_size(lTotalAttr, iAttrCnt)
    for _, sAttr in ipairs(lAttrs) do
        local iQuality = self:ResetQuality(oEquip)
        local mAttrData = itemdefines.GetFuWenQualityData(iQuality,iLevel)
        local iValue = mAttrData[sAttr]
        if iValue and iValue > 0 then
            local iK = self:CalculateFuWenK()
            iValue = math.floor(iValue * iK / 100)
            local m = {}
            m.quality = iQuality
            m.value  = math.max(iValue, 1)
            mAttr[sAttr] = m
        end
    end
    return mAttr
end

function CItem:ResetFuWen1(oEquip)
    local iAttrCnt = 2
    local mAttr = {}
    local iLevel = oEquip:EquipLevel()
    local mFuWen = oEquip:CurrentFuWen()
    local sDelAttr = table_random_key(mFuWen)
    local lTotalAttr = table_deep_copy(self.m_lFuWenAttrs)
    extend.Array.remove(lTotalAttr, sDelAttr)
    local lAttrs = extend.Random.random_size(lTotalAttr, iAttrCnt)
    for _, sAttr in ipairs(lAttrs) do
        local iQuality = self:ResetQuality(oEquip)
        local mAttrData = itemdefines.GetFuWenQualityData(iQuality,iLevel)
        local iValue = mAttrData[sAttr]
        if iValue and iValue > 0 then
            local iK = self:CalculateFuWenK()
            iValue = math.floor(iValue * iK / 100)
            local m = {}
            m.quality = iQuality
            m.value  = math.max(iValue, 1)
            mAttr[sAttr] = m
        end
    end
    return mAttr
end

function CItem:ResetFuWen2(mSameApply, mAttrData)
    local mSame = table_key_list(mSameApply)
    local iRan = math.random(#mSame)
    local sRemove = mSame[iRan]
    local lFuWenAttr = table_deep_copy(self.m_lFuWenAttrs)
    for i, sAttr in ipairs(lFuWenAttr) do
        if sAttr == sRemove then
            table.remove(lFuWenAttr, i)
            break
        end
    end
    local iAttrCnt = 2
    local mAttrs =  extend.Random.sample_table(lFuWenAttr, iAttrCnt)
    local mApply = {}
    for _,sAttr in pairs(mAttrs) do
        local iValue = mAttrData[sAttr]
        if iValue and iValue > 0 then
            local iK = self:CalculateFuWenK()
            iValue = math.floor(iValue * iK / 100)
            mApply[sAttr] = math.max(iValue, 1)
        end
    end
    return mApply
end
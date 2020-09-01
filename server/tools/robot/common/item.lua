local extend  = require("extend")
local res = require("data")
local tserialize = require('extend').Table.serialize
require("tableop")
local item = {}

local function GetWeaponType(iSchool,iBranch)
    local mWeaponData = res["schoolweapon"]["weapon"][iSchool][iBranch]
    assert(mWeaponData, string.format("schoolweapon config not exist! %s, %s", iSchool, iBranch))
    return mWeaponData.weapon
end

local function GetEquipStoneShape(iSex, iPos, iLevel, iQuality, iWeapon)
    local iShape
    if iPos == 1 then
        iShape = 30000 + iWeapon * 1000 + (iQuality -1) *20 + iLevel // 10
    else
        if table_in_list({EQUIP_CLOTH,EQUIP_BELT,EQUIP_SHOE},iPos) then
            iShape = 40000 + (iPos - 2) * 1000 + (iSex - 1) * 100 + (iQuality -1) *20 + iLevel // 10
        else
            iShape = 40000 + (iPos - 2) * 1000 + (iQuality -1) *20 + iLevel // 10
        end
    end
    return iShape * 100
end

local function GetInitRobotItem(self)
    local mItem = res["item"]
    local iSex = self.m_iSex
    local iSchool = self.m_iSchool
    local iSchoolBranch = self.m_iSchoolBranch
    local iShape = self.m_iShape
    local mShape = {}
    local iWeapon = GetWeaponType(iSchool,iSchoolBranch)
    for iPos = 1,6 do
        for iLevel = 0,30,10 do
            local iShape = GetEquipStoneShape(iSex,iPos,iLevel,1,iWeapon)
            if mItem[iShape] then
                table.insert(mShape,iShape)
            end
        end
    end
    local iBaseShape = 18000
    for i=0,500,100 do
        local iShape = iBaseShape + i
        for iLevel =0,6 do
            local iGem = iShape + iLevel
            table.insert(mShape,iGem)
        end
    end
    for sid=10000, 12100 do
        local info = res["item"][sid]
        if info then
            table.insert(mShape,sid)
        end
        if #mShape >= 80 then
            break
        end
    end
    return mShape
end

item.GS2CLoginRole = function (self,args)
    local mRole = args.role
    self.m_iGrade = mRole.grade
    self.m_iSex = mRole.sex
    self.m_iSchool = mRole.school
    self.m_iSchoolBranch = mRole.school_branch
    self.m_iShape = mRole.model_info.shape
    self.m_iPid = args.pid
    self:sleep(10+math.random(5))
    self:run_cmd("C2GSGMCmd",{
        cmd = "choosemap",
    })
    self:run_cmd("C2GSGMCmd",{
        cmd = string.format("rewardcoin %d 100000000000",self.m_iPid)
    })
    self:sleep(5+math.random(5))
    local lShape = GetInitRobotItem(self)

    self:run_cmd("C2GSGMCmd", {cmd=string.format("init_item_robot %s", tserialize(lShape))})
    self:fork(function ()
        while 1 do
            self:sleep(3+math.random(3))
            local iCmd = math.random(12)
            if iCmd <=3 then
                local iShape = 14999 + math.random(2)
                self:run_cmd("C2GSGMCmd",{
                    cmd = string.format("clone %d 2",iShape)
                })
            elseif iCmd <=5 then
                local mItemList = self.m_oItemMgr:GetTestItemList()
                if #mItemList > 0 then
                    local iItemId = mItemList[math.random(#mItemList)]
                    self:run_cmd("C2GSItemUse",{itemid = iItemId,amount = 1})
                end
            elseif iCmd == 6 then
                self:run_cmd("C2GSGMCmd",{
                    cmd = "rewardexp 0 10000"
                })
            elseif iCmd == 7 then
                self:run_cmd("C2GSFastAddGemExp",{})
            elseif iCmd == 8 then
                local iPos = self.m_oItemMgr:PromotePos()
                if iPos> 0 and self.m_oItemMgr:HasStone(iPos) then
                    local oStone = self.m_oItemMgr:GetStone(iPos)
                    local mNet = {
                        pos = iPos,
                        itemid = oStone:ID(),
                    }
                    self:run_cmd("C2GSPromoteEquipLevel",mNet)
                end
            elseif iCmd == 9 then
                local mNet = {
                    pos = math.random(4),
                }
                self:run_cmd("C2GSBuyPartnerBaseEquip",mNet)
            elseif iCmd == 10 then
                local oItem = self.m_oItemMgr:GetPartnerEquip()
                if oItem then
                    local mNet = {
                        amount = 1,
                        itemid = oItem.m_ID,
                        target = 1,
                    }
                    self:run_cmd("C2GSUsePartnerItem",mNet)
                end
            else
                self:run_cmd("C2GSArrangeItem",{})
            end
        end
    end)
end

item.GS2CPropChange = function (self,args)
    local mRole = args.role
    local iGrade = mRole.grade or 0
    if iGrade > self.m_iGrade then
        self.m_iGrade = iGrade
    end
end

item.GS2CLoginItem = function (self,args)
    if not self.m_oItemMgr then
        self.m_oItemMgr = CItemMgr:New()
    end
    local mData = args.itemdata or {}
    for _,mItemData in pairs(mData) do
        local iItemId = mItemData["id"]
        local oItem = CItem:New(iItemId,mItemData)
        self.m_oItemMgr:AddItem(oItem)
    end
end

item.GS2CAddItem = function (self,args)
    if not self.m_oItemMgr then
        return
    end
    local mData = args.itemdata or {}
    local iItemId = mData.id
    local iAmount = mData.amount
    local oItem = CItem:New(iItemId,mData)
    self.m_oItemMgr:AddItem(oItem)
end

item.GS2CItemAmount = function (self,args)
    if not self.m_oItemMgr then
        return
    end
    local iItemId = args.id
    local iAmount = args.amount
    self.m_oItemMgr:SetAmount(iItemId,iAmount)
end

item.GS2CDelItem = function (self,args)
    if not self.m_oItemMgr then
        return
    end
    local iItemId = args.id
    self:RemoveItem(iItemId)
end

item.GS2CLoginPartner = function (self,args)
    --[[
    self:sleep(3+math.random(3))
    self:run_cmd("C2GSGMCmd",{
        cmd = "fullpartner",
    })
    ]]
end

CItemMgr = {}
CItemMgr.__index = CItemMgr

function CItemMgr:New()
    local o = {}
    setmetatable(o,self)
    o.m_mItem = {}
    return o
end

function CItemMgr:AddItem(oItem)
    local iItemId = oItem.m_ID
    self.m_mItem[iItemId] = oItem
end

function CItemMgr:RemoveItem(iItemId)
    self.m_mItem[iItemId] = nil
end

function CItemMgr:SetAmount(iItemId,iAmount)
    local oItem = self.m_mItem[iItemId]
    if oItem then
        oItem:SetAmount(iAmount)
    end
    if iAmount <= 0 then
        self:RemoveItem(iItemId)
    end
end

function CItemMgr:ShapeAmount(iShape)
    local iCnt = 0
    for _,oItem in pairs(self.m_mItem) do
        if oItem:Shape() == iShape then
            iCnt = iCnt + oItem:GetAmount()
        end
    end
    return iCnt
end

function CItemMgr:ItemList()
    return table_key_list(self.m_mItem)
end

function CItemMgr:GetTestItemList(lShape)
    lShape = lShape or {15000,15001,15002}
    local mRet = {}
    for id,oItem in pairs(self.m_mItem) do
        if table_in_list(lShape,oItem:Shape()) then
            table.insert(mRet,id)
        end
    end
    return mRet
end

function CItemMgr:Size()
    local iCnt = 0
    for _,_ in pairs(self.m_mItem) do
        iCnt = iCnt + 1
    end
    return iCnt
end

function CItemMgr:HasGem()
    for _,oItem in pairs(self.m_mItem) do
        if oItem:IsGem() then
            return true
        end
    end
    return false
end

function CItemMgr:HasStone(iPos)
    for _,oItem in pairs(self.m_mItem) do
        if oItem:IsEquipStone(iPos) then
            return true
        end
    end
    return false
end

function CItemMgr:GetStone(iPos)
    for _,oItem in pairs(self.m_mItem) do
        if oItem:IsEquipStone(iPos) then
            return oItem
        end
    end
end

function CItemMgr:PromotePos()
    local mPos = {}
    for iPos = 1, 6 do
        if self:HasStone(iPos) then
            table.insert(mPos,iPos)
        end
    end
    if #mPos <= 0 then
        return 0
    end
    return mPos[math.random(#mPos)]
end

function CItemMgr:GetPartnerEquip()
    for _,oItem in pairs(self.m_mItem) do
        if oItem:IsPartnerEquip() then
            return oItem
        end
    end
end

CItem = {}
CItem.__index = CItem

function CItem:New(id,mArgs)
    local o = {}
    setmetatable(o,self)
    o.m_ID = id
    o.m_mData = mArgs
    return o
end

function CItem:ID()
    return self.m_ID
end

function CItem:Shape()
    return self.m_mData["sid"]
end

function CItem:GetAmount()
    return self.m_mData["amount"]
end

function CItem:SetAmount(iAmount)
    self.m_mData["amount"] = iAmount
end

function CItem:GetItemData()
    local iShape = self:Shape()
    local mData = res["item"][iShape]
    assert(mData,string.format("itembase GetItemData err:%s",iShape))
    return mData
end

function CItem:IsGem()
    local mItemData = self:GetItemData()
    if mItemData["type"] == 3 then
        return true
    end
end

function CItem:IsEquip()
    local mItemData = self:GetItemData()
    if mItemData["type"] == 4 then
        return true
    end
end

--装备灵石
function CItem:IsStone()
    local mItemData = self:GetItemData()
    if mItemData["type"] == 6 then
        return true
    end
end

function CItem:EquipPos()
    local mItemData = self:GetItemData()
    return mItemData["pos"]
end

function CItem:IsEquipStone(iPos)
    if not self:IsStone() then
        return false
    end
    local mItemData = self:GetItemData()
    if mItemData["pos"] ~= iPos then
        return false
    end
    return true
end

function CItem:IsPartnerEquip()
    local iShape = self:Shape()
    if iShape >= 6000001 and iShape <= 6999999 then
        return true
    end
    return false
end

return item
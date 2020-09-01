local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/itembase"))
local loaditem = import(service_path("item/loaditem"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "gem"

function NewItem(sid)
    local o = CItem:New(sid)
    o.m_mApply = {}
    return o
end

function CItem:Create(...)
    super(CItem).Create(self,...)
    if not self:GetData("exp") then
        local iExp = self:GetItemData()["exp"]
        self:SetData("exp",iExp)
    end
end

function CItem:GetUpLevelExp()
    return self:GetItemData()["up_level_exp"]
end

function CItem:Level()
    return self:GetItemData()["level"]
end

function CItem:MaxLevel()
    if not self.m_iMaxLevel then
        local res = require "base.res"
        local sMaxLevel = res["daobiao"]["global"]["equip_gem_max_level"]["value"]
        self.m_iMaxLevel = tonumber(sMaxLevel)
    end
    return self.m_iMaxLevel
end

function CItem:IsMaxLevel()
    if self:Level() >= self:MaxLevel() then
        return true
    end
    return false
end

function CItem:MaxExp()
    local iLevel = self:MaxLevel()
    local iNowLevel = self:Level()
    local iNewShape = iLevel - iNowLevel + self:SID()
    local oNewGem = loaditem.GetItem(iNewShape)
    return oNewGem:GetData("exp")
end

function CItem:WieldPos()
    return self:GetItemData()["pos"]
end

--升级所需经验
function CItem:GetUpLevelNeedExp()
    local iNewShape = self:SID() + 1
    local oNewGem = loaditem.GetItem(iNewShape)
    local iExp = oNewGem:GetData("exp")
    local iExp = math.max(iExp-self:GetData("exp",0),0)
    return iExp
end

function CItem:AddExp(iExp,sReason)
    local iOldExp = self:GetData("exp",0)
    local iNewExp = iOldExp + iExp
    self:SetData("exp",iNewExp)
end

function CItem:GetExp()
    return self:GetData("exp",0)
end

function CItem:AddApply(sApply,sAttr)
    self.m_mApply[sApply] = sAttr
end

function CItem:GetApply(sApply,rDefault)
    rDefault = rDefault or 0
    return self.m_mApply[sApply] or rDefault
end

function CItem:GetAttrData()
    local res = require "base.res"
    return res["daobiao"]["attrname"]
end

function CItem:Effect(oPlayer)
    local mAttr = self:GetAttrData()
    for sAttr,_ in pairs(mAttr) do
        local iValue = self:GetItemData()[sAttr]
        if iValue and iValue > 0 then
            self:AddApply(sAttr,iValue)
            oPlayer.m_oEquipMgr:AddApply(sAttr,self:WieldPos(),iValue)
        end
    end
end

function CItem:UnEffect(oPlayer)
    for sApply,iValue in pairs(self.m_mApply) do
        oPlayer.m_oEquipMgr:AddApply(sApply,self:WieldPos(),-iValue)
    end
end

function CItem:ApplyInfo()
    local mData = {}
    mData["exp"] = self:GetExp()
    for sApply,iValue in pairs(self.m_mApply) do
        mData[sApply] = iValue
    end
    return mData
end
--import module
local datactrl = import(lualib_path("public.datactrl"))

local defines = {
    ITEM_KEY_BIND = 1,                               --绑定
    ITEM_KEY_TIME = 2,                               --时效道具
}

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

CItem = {}
CItem.__index = CItem
inherit(CItem,datactrl.CDataCtrl)

CItem.m_ItemType = "base"

function CItem:New(sid)
    local o = super(CItem).New(self)
    o:Init(sid)
    return o
end

function CItem:Init(sid)
    self.m_ID = self:DispatchItemID()
    self.m_SID = sid
    self.m_iAmount = 1
    self.m_iItemLevel = self:GetItemData()["quality"] or 1
    self.m_iCreateTime = get_time()
end

function CItem:DispatchItemID()
    return 0
end

function CItem:GetContainer()
end

function CItem:GetPlayerObj(iPid)
end

function CItem:Setup()
end

function CItem:Validate()
    return true
end

function CItem:ValidCombine(oSrcItem)
    if self:SID() ~= oSrcItem:SID() then
        return false
    end
    if self:IsTimeItem() then
        return false
    end
    return true
end

function CItem:GetItemData()
    local res = require "base.res"
    local mData = res["daobiao"]["item"][self.m_SID]
    assert(mData,string.format("itembase GetItemData err:%s",self.m_SID))
    return mData
end

function CItem:Load(mData)
    if not mData then
        return
    end
    self.m_iAmount = mData["amount"] or self.m_iAmount
    self.m_SID = mData["sid"] or self.m_SID
    self.m_mData = mData["data"] or {}
    self.m_iItemLevel = mData["item_level"] or self.m_iItemLevel
    self.m_iCreateTime = mData["create_time"] or self.m_iCreateTime
end

function CItem:Save()
    local mData = {}
    mData["amount"] = self.m_iAmount
    mData["sid"] = self.m_SID
    mData["data"] = self.m_mData or {}
    mData["item_level"] = self.m_iItemLevel
    mData["create_time"] = self:GetCreateTime()
    return mData
end

function CItem:Create()
end

function CItem:ID()
    return self.m_ID
end

function CItem:SID()
    return self.m_SID
end

function CItem:TaskSID()
    local iTaskSID = self:GetItemData()["taskid"]
    if iTaskSID == 0 then
        return self:SID()
    end
    return iTaskSID
end

function CItem:ItemType()
    return self.m_ItemType
end

function CItem:Shape()
    return self.m_SID
end

function CItem:SetName(sName)
    self:SetData("name", sName)
end

function CItem:Name()
    return  self:GetData("name") or self:GetItemData()["name"]
end

function CItem:SalePrice()
    return self:GetItemData()["sale_price"] or 0
end

function CItem:BuyPrice()
    return self:GetItemData()["buy_price"] or 0
end


--品质
function CItem:Quality()
    return self.m_iItemLevel
end

function CItem:GetMaxAmount()
    assert(self:GetItemData()["max_overlay"] >= 1,string.format("max_overlay err:%s",self:Shape()))
    return self:GetItemData()["max_overlay"]
end

function CItem:Type()
    return self:GetItemData()["type"]
end

function CItem:GetBagLimit()
    return self:GetItemData()["baglimit"]
end

function CItem:GetOverFlowTips()
    return self:GetItemData()["overflow_tips"]
end

function CItem:GetAmount()
    return self.m_iAmount
end

function CItem:GetPower()
    return 0
end

function CItem:GetTraceName()
    local iOwner,iTraceNo = table.unpack(self:GetData("TraceNo",{}))
   return string.format("%s %d:<%d,%d>",self:Name(),self:SID(),iOwner,iTraceNo)
end

function CItem:GetCreateTime()
    return self.m_iCreateTime
end

function CItem:GetLock()
    return 0
end

function CItem:GetBuyInfo()
    return self:GetItemData()["buy_cost"] or {}
end

function CItem:TraceNo()
    local iOwner,iTraceNo = table.unpack(self:GetData("TraceNo",{}))
    return iTraceNo or 0
end

function CItem:SetCreateTime(iTime)
    if iTime > 0 then
        self:Dirty()
        self.m_iCreateTime = iTime
    end
end

function CItem:SetAmount(iAmount, sReason)
    self:Dirty()
    self.m_iAmount = iAmount
    if self.m_iAmount <= 0 then
        local oContainer = self:GetContainer()
        if oContainer then
            oContainer:RemoveItem(self, sReason)
        end
    end
end

function CItem:AddAmount(iAmount,sReason,mArgs)
    self:Dirty()
    self.m_iAmount = self.m_iAmount + iAmount
end

function CItem:GetPid()
    local iOwner,iTraceNo = table.unpack(self:GetData("TraceNo",{}))
    return iOwner or 0
end

function CItem:TimeOut()
    self:Dirty()
    local iAmount = self:GetAmount()
    local oContainer = self:GetContainer()
    if oContainer then
        oContainer:AddAmount(self,-iAmount,"TimeOut")
    else
        self:AddAmount(-iAmount,"TimeOut")
    end
end

function CItem:IsTimeOut()
    local iNow = get_time()
    if self:IsTimeItem() and iNow > self:GetData("Time", 0) then
        return true
    end
    return false
end

function CItem:IsTimeItem()
    if self:GetData("Time",0) ~= 0 then
        return true
    end
    return false
end

function CItem:Bind(iPid)
    self:SetData("Bind", iPid)
end

function CItem:IsBind()
    if self:GetData("Bind",0) ~= 0 then
        return true
    end
    return false
end

function CItem:IsBuff()
    return false
end

function CItem:MinUseGrade()
    return self:GetItemData()["min_grade"]
end

function CItem:MaxUseGrade()
    return self:GetItemData()["max_grade"]
end

function CItem:ValidUse(who, iUseAmount)
    return true
end

function CItem:Use(who,target,iAmount)
    self:TrueUse(who, target, iAmount)
end

function CItem:TrueUse(who,target, amount)
    --
end

function CItem:GetUseReward()
    return self:GetItemData()["use_reward"] or {}
end

--同种类型道具数目
function CItem:GetItemAmount()
    local  oContainer = self:GetContainer()
    if oContainer then
        return oContainer:GetItemAmount(self:Shape())
    end
end

--是否回收
function CItem:ValidRecycle()
    return false
end

function CItem:SortNo()
    local iNo = self:GetItemData()["sort"] or 100
    return iNo
end

--key值
function CItem:Key()
    local iKey = 0
    if self:IsBind() then
        iKey = iKey | defines.ITEM_KEY_BIND
    end
    if self:IsTimeItem() then
        iKey = iKey | defines.ITEM_KEY_TIME
    end
    return iKey
end

function CItem:ApplyInfo()
    local mData = {}
    return mData
end

function CItem:Desc()
    return ""
end

function CItem:Refresh()
    local iOwner = self:GetPid()
    local oPlayer = self:GetPlayerObj(iOwner)
    if oPlayer then
        oPlayer.m_oItemCtrl:GS2CAddItem(self)
    end
end

--快捷使用
function CItem:IsQuickUse( ... )
    local iQuickUse = self:GetItemData()["quickable"] or 0
    if iQuickUse == 1 then
        return true
    end
    return false
end

--能否给予
function CItem:IsGive()
    local iGive = self:GetItemData()["giftable"] or 0
    if iGive == 1 then
        return true
    end
    return false
end

--能否摆摊
function CItem:IsStore()
    local iStore = self:GetItemData()["stallable"] or 0
    if iStore == 1 then
        return true
    end
    return false
end

--合成分解信息
function CItem:DeComposeInfo()
    local mData = self:GetItemData()
    return mData["de_compose"]
end

function CItem:ComposeAmount()
    local mData = self:GetItemData()
    return mData["compose_amount"] or 0
end

function CItem:ComposeItemInfo()
    local mData = self:GetItemData()
    return mData["compose_item"] or {}
end

function CItem:CoinCost()
    local mData = self:GetItemData()
    return mData["coin_cost"] or 0
end

function CItem:ChooseAmount()
    local mData = self:GetItemData()
    return mData["gift_choose_amount"] or 0
end

function CItem:PackItemInfo()
     local mNet = {}
    mNet["id"] = self.m_ID
    mNet["sid"] = self:SID()
    mNet["name"] = self:Name()
    mNet["itemlevel"] = self:Quality()
    mNet["amount"] = self:GetAmount()
    mNet["key"] = self:Key()
    if self:IsTimeItem() then
        mNet["end_time"] = self:GetData("Time") - get_time()
    end
    mNet["create_time"] = self:GetCreateTime()
    mNet["apply_info"] = self:ApplyInfo()
    mNet["desc"] = self:Desc()
    mNet["power"] = self:GetPower()
    mNet["lock"] = self:GetLock()
    return mNet
end

function CItem:GS2CItemAmount(mArgs)
    mArgs = mArgs or {}
    local mNet = {}
    mNet["id"] = self.m_ID
    mNet["amount"] = self:GetAmount()
    mNet["create_time"] = self:GetCreateTime()
    local oPlayer = self:GetPlayerObj(self:GetOwner())
    if oPlayer then
        oPlayer:Send("GS2CItemAmount",mNet)
    end
end

function CItem:GetOwner()
    return self:GetPid()
end

function CItem:OnAddToContainer()
end

function CItem:GS2CItemQuickUse()
    local mNet = {}
    mNet["id"] = self.m_ID
    local oPlayer = self:GetPlayerObj(self:GetOwner())
    if oPlayer then
        oPlayer:Send("GS2CItemQuickUse",mNet)
    end
end

function CItem:GS2CRefreshItemApply()
    local oPlayer = self:GetPlayerObj(self:GetOwner())
    if oPlayer then
        oPlayer:Send("GS2CRefreshItemApply",{
            itemid = self:ID(),
            apply_info = self:ApplyInfo(),
            })
    end
end

function CItem:RefreshLock()
    local oPlayer = self:GetPlayerObj(self:GetOwner())
    if oPlayer then
        oPlayer:Send("GS2CLockItem",{
            itemid = self:ID(),
            lock = self:GetLock(),
            })
    end
end

--生成简要信息
function CItem:GetBriefInfo()
    local mData = {}
    mData["id"] = self.m_ID
    mData["sid"] = self:SID()
    mData["name"] = self:Name()
    mData["amount"] = self:GetAmount()
    mData["maxamount"] = self:GetMaxAmount()
    return mData
end

function CItem:GetShowInfo()
    return {
        id = self:ID(),
        sid = self:SID(),
        virtual = self:SID(),
        amount = self:GetAmount(),
    }
end

function CItem:LogInfo()
    return {
        ["物品编号"] = self:SID(),
        ["数量"] = self:GetAmount(),
    }
end
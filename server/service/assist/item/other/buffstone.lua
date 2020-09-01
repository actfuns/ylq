local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local res = require "base.res"

local gamedefines = import(lualib_path("public.gamedefines"))

local itembase = import(service_path("item/itembase"))
local loaditem = import(service_path("item/loaditem"))
local itemdefines = import(service_path("item/itemdefines"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    return o
end

function CItem:Load(mData)
    mData = mData or {}
    super(CItem).Load(self,mData)
    self.m_mApply = mData["apply"] or self.m_mApply
    self.m_mRatioApply =mData["ratio_apply"] or self.m_mRatioApply
end

function CItem:Save()
    local mData = super(CItem).Save(self)
    mData["apply"] = self.m_mApply
    mData["ratio_apply"] = self.m_mRatioApply
    return mData
end

function CItem:IsBuff()
    return true
end

function CItem:TrueUse(oPlayer, iTarget, iAmount,mArgs)
    local iSid = self:SID()
    local iPid = oPlayer:GetPid()
    local oBuffStone = oPlayer.m_oItemCtrl:HasBuffStone(iSid)
    if oBuffStone then
        global.oAssistMgr:Notify(iPid, "该部位已存在神格道具")
        return
    end
    -- if oPlayer:GetGrade() < 10 then
    --     global.oAssistMgr:Notify(iPid, "等级不足")
    --     return
    -- end
    local iEndSec = self:EndSecond() or 86400
    local iTestSec = oPlayer:GetInfo("stonebufftime")
    if iTestSec then
        iEndSec = iTestSec
    end
    assert(iEndSec > 0, string.format("buffstone err, pid:%s, sid:%s, id:%s", iPid, iSid, self:ID()))
    local sReason = "使用道具"
    local oNew = loaditem.Create(iSid)
    oPlayer.m_oItemCtrl:DispatchItemID(oNew)
    oNew:SetData("TraceNo",self:GetData("TraceNo",{}))
    oNew:SetData("Time", get_time() + iEndSec)

    oPlayer.m_oItemCtrl:AddAmount(self,-iAmount,sReason)
    oNew:InitApply(oPlayer)
    oPlayer.m_oItemCtrl:WieldBuffStone(oNew)
    oPlayer.m_oItemCtrl:StartBuffStoneTimer(iSid)
    oNew:WieldStone(oPlayer)
    oPlayer.m_oStoneMgr:ShareUpdate()
    oPlayer:Send("GS2CAddBuffItem", {itemdata = oNew:PackItemInfo()})
    oPlayer:SynShareObj({stone_share = 1})
    global.oAssistMgr:PushAchieve(iPid, "使用神格次数", {value = 1})
end

function CItem:EndSecond()
    return self:GetItemData()["use_timeout"]
end

function CItem:EndTime()
    return self:GetData("Time", 0)
end

function CItem:GetApply(sAttr, rDefault)
    rDefault  = rDefault or 0
    return self.m_mApply[sAttr] or rDefault
end

function CItem:AddApply(sAttr, iVal)
    self:Dirty()
    local iAttr = self.m_mApply[sAttr] or 0
    self.m_mApply[sAttr] = iAttr + iVal
end

function CItem:GetRatioApply(sAttr, rDefault)
    rDefault  = rDefault or 0
    return self.m_mRatioApply[sAttr] or rDefault
end

function CItem:AddRatioApply(sAttr, iVal)
    self:Dirty()
    local iRatio = self.m_mRatioApply[sAttr] or 0
    self.m_mRatioApply[sAttr] = iRatio + iVal
end

function CItem:InitApply(oPlayer)
    self:Dirty()
    local iGrade = oPlayer:GetGrade()
    local idx = self:SID() * 1000 + iGrade
    local sAttr = res["daobiao"]["buffstone"][idx]["buff"]
    if sAttr and sAttr ~= "" then
        self.m_mApply = formula_string(sAttr, {}) or {}
    end
    local sRatio = res["daobiao"]["buffstone"][idx]["buff_ratio"]
    if sRatio and sRatio ~= "" then
        self.m_mRatioApply = formula_string(sRatio, {}) or {}
    end
    -- self:CalApply(oPlayer)
end

function CItem:WieldStone(oPlayer)
    self:SetInfo("wield", 1)
    self:CalApply(oPlayer)
end

function CItem:IsWield()
    return self:GetInfo("wield")
end


function CItem:CalApply(oPlayer)
    local iPid = oPlayer:GetPid()
    for sAttr, iVal in pairs(self.m_mApply) do
        oPlayer.m_oStoneMgr:AddApply(sAttr, iPid, iVal)
    end
    for sAttr,iVal in pairs(self.m_mRatioApply) do
        oPlayer.m_oStoneMgr:AddRatioApply(sAttr, iPid, iVal)
    end
end

function CItem:UnWieldStone(oPlayer)
    self:SetInfo("wield", nil)
    self:UnCalApply(oPlayer)
end

function CItem:UnCalApply(oPlayer)
    local iPid = oPlayer:GetPid()
    for sAttr, iVal in pairs(self.m_mApply) do
        oPlayer.m_oStoneMgr:AddApply(sAttr, iPid, -iVal)
    end
    for sAttr,iVal in pairs(self.m_mRatioApply) do
        oPlayer.m_oStoneMgr:AddRatioApply(sAttr, iPid, -iVal)
    end
end

function CItem:Strength(oPlayer)
    self:Dirty()
    self:SetData("strength", 1)
    self:UnCalApply(oPlayer)
    local mApply = {}
    for sAttr, iVal in pairs(self.m_mApply) do
        mApply[sAttr] = math.floor(iVal * (1 + 0.25))
    end
    self.m_mApply = mApply

    local mRatioApply = {}
    for sAttr, iVal in pairs(self.m_mRatioApply) do
        mRatioApply[sAttr] = math.floor(iVal * (1 + 0.25))
    end
    self.m_mRatioApply = mRatioApply
    self:CalApply(oPlayer)
end

function CItem:IsStrength(oPlayer)
    if self:GetData("strength") == 1 then
        return true
    end
    return false
end

function CItem:ResetEndTime()
    self:Dirty()
    local iEndSec = self:EndSecond()
    self:SetData("Time", get_time() + iEndSec)
end

function CItem:ApplyInfo()
    local lApply = {}
    for sAttr, iVal in pairs(self.m_mApply) do
        table.insert(lApply, {key = sAttr, value = iVal})
    end
    for sAttr, iVal in pairs(self.m_mRatioApply) do
        table.insert(lApply, {key =sAttr .. "_ratio", value = iVal})
    end
    return lApply
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end
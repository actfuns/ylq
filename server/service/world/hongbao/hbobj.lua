--import module
local skynet = require "skynet"
local global = require "global"

local datactrl = import(lualib_path("public.datactrl"))
local hbdefines = import(service_path("hongbao.hbdefines"))

function NewHbObj(...)
    return CHbObj:New(...)
end

CHbObj = {}
CHbObj.__index = CHbObj
inherit(CHbObj, datactrl.CDataCtrl)

function CHbObj:New(mArgs)
    local o = super(CHbObj).New(self)
    o.m_Name = mArgs.name
    o.m_iOwner = mArgs.owner
    o.m_iShape = mArgs.shape
    o.m_sTitle = mArgs.title
    o.m_iGold = mArgs.gold
    o.m_iKeepGold = mArgs.gold
    o.m_iAmount = mArgs.amount
    o.m_iID = mArgs.id
    o.m_mDrawList = {}
    o.m_sType = mArgs.type
    o.m_EndTime = mArgs.endtime
    o.m_BeginTime = mArgs.begintime
    o.m_SID = mArgs.sid or 0
    return o
end

function CHbObj:Save()
    local mData = {}
    mData.name = self.m_Name
    mData.owner = self.m_iOwner
    mData.shape = self.m_iShape
    mData.title = self.m_sTitle
    mData.gold = self.m_iGold
    mData.keep_gold = self.m_iKeepGold
    mData.amount = self.m_iAmount
    mData.draw_list = self.m_mDrawList
    mData.id = self.m_iID
    mData.type = self.m_sType
    mData.endtime = self.m_EndTime
    mData.begintime = self.m_BeginTime
    mData.sid = self.m_SID
    return mData
end

function CHbObj:Load(mData)
    mData = mData or {}
    self.m_Name = mData.name or self.m_Name
    self.m_iOwner = mData.owner or self.m_iOwner
    self.m_iShape = mData.shape or self.m_iShape
    self.m_sTitle = mData.title or self.m_sTitle
    self.m_iGold = mData.gold or self.m_iGold
    self.m_iKeepGold= mData.keep_gold or self.m_iKeepGold
    self.m_iAmount = mData.amount or self.m_iAmount
    self.m_mDrawList = mData.draw_list or self.m_mDrawList
    self.m_iID = mData.id or self.m_iID
    self.m_sType = mData.type or self.m_sType
    self.m_EndTime = mData.endtime or self.m_EndTime
    self.m_BeginTime = mData.begintime or self.m_BeginTime
    self.m_SID = mData.sid or self.m_SID
end

function CHbObj:GetName()
    return self.m_Name
end

function CHbObj:GetOwner()
    return self.m_iOwner
end

function CHbObj:SID()
    return self.m_SID
end

function CHbObj:Type()
    return self.m_sType
end

function CHbObj:ID()
    return self.m_iID or 1
end

function CHbObj:GetGold()
    return self.m_iGold
end

function CHbObj:GetAmount()
    return self.m_iAmount
end

function CHbObj:GetKeepGold()
    return self.m_iKeepGold
end

function CHbObj:GetRemainHbObjAmount()
    local iRemainAmount = self.m_iAmount - table_count(self.m_mDrawList)
    return iRemainAmount
end

function CHbObj:MakeHbObjGold()
    local iRemainAmount = self:GetRemainHbObjAmount()
    assert(iRemainAmount >= 1,"err HbObj gold")
    local iKeepGold = self.m_iKeepGold
    if iRemainAmount == 1 then
        return iKeepGold
    end
    local iGold = math.floor(iKeepGold//iRemainAmount)
    iGold = math.random(1,2*iGold)
    return iGold
end

function CHbObj:ValidDrawHbObj(oPlayer)
    local iPid = oPlayer:GetPid()
    local iRemainAmount = self:GetRemainHbObjAmount()
    if iRemainAmount < 1 then
        return false
    end
    if self.m_mDrawList[db_key(iPid)] then
        return false
    end
    local iTime = get_time()
    if self.m_EndTime < iTime then
        return false
    end
    return true
end

function CHbObj:IsOver()
    local iTime = get_time()
    if self.m_EndTime < iTime then
        return true
    end
    return false
end

function CHbObj:AddDrawHbObj(oPlayer,iGold)
    self:Dirty()
    local iPid = oPlayer:GetPid()
    self.m_mDrawList[db_key(iPid)] = {name=oPlayer:GetName(),gold=iGold,}
end

function CHbObj:GetMaxGold()
    local iGold = 0
    for _,info in pairs(self.m_mDrawList) do
        iGold = math.max(iGold,info["gold"])
    end
    return iGold
end

function CHbObj:GetMaxGoldPlayerName()
    local iGold
    local sName = ""
    for _,info in pairs(self.m_mDrawList) do
        if not iGold or info["gold"] >= iGold then
            iGold = info["gold"]
            sName = info["name"]
        end
    end
    return sName
end

function CHbObj:GetMinGoldPlayerName()
    local iGold
    local sName = ""
    for _,info in pairs(self.m_mDrawList) do
        if not iGold or info["gold"] <= iGold then
            iGold = info["gold"]
            sName = info["name"]
        end
    end
    return sName
end

function CHbObj:PackHbObj()
    local mDrawData = {}
    for iPid,mData in pairs(self.m_mDrawList) do
        local sName = mData["name"]
        local iGold = mData["gold"]
        table.insert(mDrawData,{pid=iPid,name=sName,gold=iGold,})
    end
    return {
        shape = self.m_iShape,
        title = self.m_sTitle,
        amount = self.m_iAmount,
        remain_gold = self.m_iKeepGold,
        draw_list = mDrawData,
    }
end

function CHbObj:ShowHongBaoInfo(oPlayer)
    oPlayer:Send("GS2CHongBaoInfo",self:PackHbObj())
end

function CHbObj:DrawHbObj(oPlayer)
    self:Dirty()
    local iGold = self:MakeHbObjGold()
    local sReason = hbdefines.GetHongBaoTypeName(self.m_sType)
    oPlayer:RewardCoin(iGold,sReason, {cancel_tip=1})
    self:AddDrawHbObj(oPlayer,iGold)
    self.m_iKeepGold = self.m_iKeepGold - iGold
    self:ShowPlayerHBInfo(oPlayer)
    return iGold
end

function CHbObj:GetDrawHbObjInfo(iPid)
    local mData = self.m_mDrawList[db_key(iPid)] or {}
    return {
        idx = self:ID(),
        shape = self.m_iShape,
        pid = iPid,
        gold = mData["gold"] or 0,
        title = self.m_sTitle,
    }
end

function CHbObj:ShowPlayerHBInfo(oPlayer)
    oPlayer:Send("GS2CPlayerHBInfo",self:GetDrawHbObjInfo(oPlayer:GetPid()))
end

function CHbObj:Title()
    return self.m_sTitle
end

function CHbObj:GetBeginTime()
    return self.m_BeginTime
end
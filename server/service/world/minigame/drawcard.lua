--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"

local loaditem = import(service_path("item.loaditem"))

CGame = {}
CGame.__index = CGame
CGame.m_sName = "drawcard"
inherit(CGame, logic_base_cls())

function NewGame(mArgs)
    return CGame:New(mArgs)
end

function CGame:New(mArgs)
    local o = super(CGame).New(self)
    o.m_Owner = mArgs.pid or 0
    o.m_Num = mArgs.num or 4
    o.m_CardInfo = {}
    o.m_RewardItemInfo = mArgs.rewarditem or {}
    o.m_EndTime = get_time() + (mArgs.overtime or 30)
    o.m_Reason = mArgs.reason or "翻牌游戏"
    o.m_EarnInfo = {}
    o.m_Mem = mArgs.mem or {}
    o.m_Mul = mArgs.mul or 1
    o.m_AddRatio = mArgs.addratio or {}
    o.m_sTip = mArgs.tip
    return o
end

function CGame:Init()
end

function CGame:GameStart(oPlayer,mArgs)
    local oWorldMgr = global.oWorldMgr
    local mNet = {
            num = self.m_Num,
            endtime = self.m_EndTime,
            memlist = {}
    }
    local oWorldMgr = global.oWorldMgr
    local mMem = self.m_Mem
    for _,mid in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
        if oMem then
            table.insert(mNet.memlist,{pid=mid,name=oMem:GetName(),shape=oMem:GetShape()})
        end
    end

    oPlayer:Send("GS2CGameCardStart",mNet)
    self.m_mEndCallBack = mArgs.endgame
    self.m_PlayerInfo = {pid=oPlayer:GetPid(),name=oPlayer:GetName(),shape=oPlayer:GetShape()}
end

function CGame:GameEnd(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mEarnInfo = self.m_EarnInfo or {}
    if oPlayer and table_count(mEarnInfo) <= 0 then
        self:DrawCard(oPlayer,math.random(self.m_Num))
    end
    for idx=1,self.m_Num do
        if not self:HasOpen(idx) then
            self:OpenCard(idx)
        end
    end
    self:TellOtherInfo("GS2CFinalMemCardInfo")
    if oPlayer and self.m_mEndCallBack then
        self.m_mEndCallBack(oPlayer,self)
    end
end

function CGame:GameOp(oPlayer,mCmd)
    local idx = mCmd.idx
    idx = tonumber(idx)
    if not idx then return end
    if self:HasOpen(idx) then
        return
    end
    local iCost = self:OpenGoldCoin()
    if iCost <= 0 then
        self:DrawCard(oPlayer,idx)
        return
    end
    if oPlayer:ValidGoldCoin(iCost) then
        oPlayer:ResumeGoldCoin(iCost,self.m_Reason)
        self:DrawCard(oPlayer,idx)
    end
end

function CGame:GetMaxRatio()
    local iRatio = 0
    for _,info in pairs(self.m_RewardItemInfo) do
        iRatio = iRatio + info["ratio"]
    end
    return iRatio
end

function CGame:OpenGoldCoin()
    local iCnt = 0
    for iNo=1,self.m_Num do
        if self:HasOpen(iNo) then
            iCnt = iCnt + 100
        end
    end
    return iCnt
end

function CGame:OpenCard(idx)
    local iMaxRatio = self:GetMaxRatio()
    local iRandom = math.random(iMaxRatio)
    local iTotal = 0
    local mItemInfo
    for _,info in pairs(self.m_RewardItemInfo) do
        iTotal = iTotal + info["ratio"]
        if iRandom <= iTotal then
            mItemInfo = table_copy(info)
            break
        end
    end
    local iOpenCnt = table_count(self.m_CardInfo) + 1
    local iRatio = self.m_AddRatio[iOpenCnt] or 0
    if math.random(100) <= iRatio then
        mItemInfo.amount = mItemInfo.amount * self.m_Mul
        mItemInfo.mul = self.m_Mul
    end
    self.m_CardInfo[idx] = mItemInfo
    return mItemInfo
end

function CGame:HasOpen(idx)
    return self.m_CardInfo[idx]
end

function CGame:IsEnd()
    return table_count(self.m_CardInfo) >= self.m_Num
end

function CGame:DrawCard(oPlayer,idx)
    if idx <= 0 or idx > self.m_Num then
        return
    end
    if self:HasOpen(idx) then
        return
    end
    local mEarnInfo = self.m_EarnInfo or {}
    local mItemInfo = self:OpenCard(idx)
    local sid,iAmount = mItemInfo["sid"],mItemInfo["amount"]
    mEarnInfo[sid] = mEarnInfo[sid] or 0
    mEarnInfo[sid] = mEarnInfo[sid] + iAmount
    self.m_EarnInfo = mEarnInfo
    local mItem = {}
    while(iAmount>0) do
        local oItem = loaditem.ExtCreate(sid)
        local iAddAmount = math.min(oItem:GetMaxAmount(),iAmount)
        iAmount = iAmount - iAddAmount
        oItem:SetAmount(iAddAmount)
        table.insert(mItem,oItem)
    end
    for _,oItem in pairs(mItem) do
        oPlayer:RewardItem(oItem,self.m_Reason)
    end
    self:GS2COpenCardInfo(oPlayer)
    self:TellOtherInfo("GS2CMemCardInfo")

    local iMul = mItemInfo.mul or 0
    local sTip = self.m_sTip
    if iMul > 0 and sTip then
        sTip = string.gsub(sTip,"$username",oPlayer:GetName())
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:SendSysChat(sTip,1,1)
    end

end

function CGame:GS2COpenCardInfo(oPlayer)
    local mNet = {cardlist={}}
    for idx=1,self.m_Num do
        local mItem = self.m_CardInfo[idx]
        if mItem then
            table.insert(mNet.cardlist,{idx=idx,sItem=mItem["sid"],amount=mItem["amount"],mul=mItem.mul or 1})
        else
            table.insert(mNet.cardlist,{idx=idx,gold=self:OpenGoldCoin()})
        end
    end
    oPlayer:Send("GS2COpenCardInfo",mNet)
end

function CGame:GetEarnItem()
    return self.m_EarnInfo
end

function CGame:TellOtherInfo(sMessage)
    local oWorldMgr = global.oWorldMgr
    local mNet = {
        info=self.m_PlayerInfo,
        cardlist={}
    }
    for idx=1,self.m_Num do
        local mItem = self.m_CardInfo[idx]
        if mItem then
            table.insert(mNet.cardlist,{idx=idx,sItem=mItem["sid"],amount=mItem["amount"],mul=mItem.mul or 1})
        else
            table.insert(mNet.cardlist,{idx=idx,gold=self:OpenGoldCoin()})
        end
    end

    local mMem = self.m_Mem
    for _,mid in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
        if oMem then
            oMem:Send(sMessage,mNet)
        end
    end
end
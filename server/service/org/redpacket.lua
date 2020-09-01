--import module
local skynet = require "skynet"
local global = require "global"

local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))
local orgdefines = import(service_path("orgdefines"))

function NewRedPacket(...)
    return CRedPacket:New(...)
end

CRedPacket = {}
CRedPacket.__index = CRedPacket
inherit(CRedPacket, datactrl.CDataCtrl)

function CRedPacket:New(mArgs)
    local o = super(CRedPacket).New(self)
    o.m_iOrg = mArgs.org_id
    o.m_iOwner = mArgs.owner
    o.m_iShape = mArgs.shape
    o.m_sTitle = mArgs.title
    o.m_iGold = mArgs.gold
    o.m_iKeepGold = mArgs.gold
    o.m_iAmount = mArgs.amount
    o.m_iID = mArgs.idx
    o.m_mDrawList = {}
    o.m_iStartTime = get_time()
    return o
end

function CRedPacket:Save()
    local mData = {}
    mData.org_id = self.m_iOrg
    mData.owner = self.m_iOwner
    mData.shape = self.m_iShape
    mData.title = self.m_sTitle
    mData.gold = self.m_iGold
    mData.keep_gold = self.m_iKeepGold
    mData.amount = self.m_iAmount
    mData.draw_list = self.m_mDrawList
    mData.idx = self.m_iID
    mData.starttime = self.m_iStartTime
    return mData
end

function CRedPacket:Load(mData)
    mData = mData or {}
    self.m_iOrg = mData.org_id or self.m_iOrg
    self.m_iOwner = mData.owner or self.m_iOwner
    self.m_iShape = mData.shape or self.m_iShape
    self.m_sTitle = mData.title or self.m_sTitle
    self.m_iGold = mData.gold or self.m_iGold
    self.m_iKeepGold= mData.keep_gold or self.m_iKeepGold
    self.m_iAmount = mData.amount or self.m_iAmount
    self.m_mDrawList = mData.draw_list or self.m_mDrawList
    self.m_iID = mData.idx or self.m_iID
    self.m_iStartTime = mData.starttime or self.m_iStartTime
end

function CRedPacket:GetOrg()
    local oOrgMgr = global.oOrgMgr
    local oOrg = oOrgMgr:GetNormalOrg(self.m_iOrg)
    return oOrg
end

function CRedPacket:GetOwner()
    local oOrg = self:GetOrg()
    return oOrg:GetMember(self.m_iOwner)
end

function CRedPacket:ID()
    return self.m_iID or 1
end

function CRedPacket:GetGold()
    return self.m_iGold
end

function CRedPacket:GetKeepGold()
    return self.m_iKeepGold
end

function CRedPacket:GetRemainRedPacketAmount()
    local iRemainAmount = self.m_iAmount - table_count(self.m_mDrawList)
    return iRemainAmount
end

function CRedPacket:ValidDraw()
    local iDrawAmount = table_count(self.m_mDrawList)
    if iDrawAmount >= self.m_iAmount then
        return false
    end
    return true
end

--在线人数加成
function CRedPacket:GetOrgOnlineRatio()
    local oOrg = self:GetOrg()
    local mRatio = orgdefines.GetHongBaoRatio()
    local iCnt = oOrg:GetOnlineMemberCnt()
    local iRatio = 0
    local iMaxCnt = 0
    for iMemCnt,mData in pairs(mRatio) do
        local iAddRatio = mData["ratio"]
        if iMemCnt == iCnt then
            return iAddRatio
        end
        if iMemCnt > iMaxCnt then
            iMaxCnt = iMemCnt
            iRatio = iAddRatio
        end
    end
    return iRatio
end

function CRedPacket:MakeRedPacketGold()
    local iRemainAmount = self:GetRemainRedPacketAmount()
    assert(iRemainAmount >= 1,"err redpacket gold")
    local iKeepGold = self.m_iKeepGold
    local oOrg = self:GetOrg()
    if iRemainAmount == 1 then
        return iKeepGold
    end
    local iGold = math.floor(iKeepGold//iRemainAmount)
    iGold = math.random(1,iGold)
    return iGold
end

function CRedPacket:ValidDrawRedPacket(oPlayer)
    local iPid = oPlayer:GetPid()
    local iRemainAmount = self:GetRemainRedPacketAmount()
    if iRemainAmount < 1 then
        return false
    end
    if self.m_mDrawList[tostring(iPid)] then
        return false
    end
    return true
end

function CRedPacket:DrawOrgRedPacket(oPlayer)
    self:Dirty()
    local iRatio = self:GetOrgOnlineRatio()
    local iGold = self:MakeRedPacketGold()
    local iRewardGold = math.floor(iGold*(100+iRatio)/100)

    global.oOrgMgr:RewardOrgRedPacket(oPlayer:GetPid(),iRewardGold,self:ID())
    oPlayer:SetOrgRedPacket(self:ID())

    self:AddDrawRedPacket(oPlayer,iGold)
    self.m_iKeepGold = self.m_iKeepGold - iGold
    local mData = self:PackRedPacket()
    oPlayer:Send("GS2COrgRedPacket",mData)

    self:NotifyOrgMem(oPlayer,iGold)

    if self:GetRemainRedPacketAmount() <= 0 then
        local oOrg = self:GetOrg()
        oOrg:UpdateOrgInfo({red_packet_rest=true})
        self:NotifyOver()
    end
end

function CRedPacket:NotifyOver()
    local oOrgMgr = global.oOrgMgr
    local sText = oOrgMgr:GetOrgText(7004)
    local mMinInfo,mMaxInfo
    local mDrawList = self.m_mDrawList
    for _,mInfo in pairs(mDrawList) do
        mMinInfo = mMinInfo or mInfo
        mMaxInfo = mMaxInfo or mInfo
        if mInfo.gold < mMinInfo.gold then
            mMinInfo = mInfo
        end
        if mInfo.gold > mMaxInfo.gold then
            mMaxInfo = mInfo
        end
    end
    local iCostTime = get_time() - self.m_iStartTime
    sText = string.gsub(sText,"$time",get_second2string(iCostTime))
    sText = string.gsub(sText,"$username1",mMinInfo.name)
    sText = string.gsub(sText,"$username2",mMaxInfo.name)
    sText = string.gsub(sText,"$amount",mMaxInfo.gold)
    sText = string.gsub(sText,"$icon",self:CoinIcon(gamedefines.COIN_FLAG.COIN_COIN))
    oOrgMgr:SendOrgChat(sText,self.m_iOrg,{pid = 0})
end

function CRedPacket:NotifyOrgMem(oPlayer,iGold)
    local oOrgMgr = global.oOrgMgr
    local iAvgGold = self:GetGold() // self.m_iAmount
    local iText
    if iGold >= 2 * iAvgGold then
        iText = 7001
    elseif iGold >= iAvgGold // 2 then
        iText = 7002
    else
        iText = 7003
    end
    local sText = oOrgMgr:GetOrgText(iText)
    sText = string.gsub(sText,"$username",oPlayer:GetName())
    sText = string.gsub(sText,"$amount",iGold)
    sText = string.gsub(sText,"$icon",self:CoinIcon(gamedefines.COIN_FLAG.COIN_COIN))

    oOrgMgr:SendOrgChat(sText,oPlayer:GetOrgID(),{pid = 0})
end

function CRedPacket:CoinIcon(iType)
    local mCoinInfo = gamedefines.COIN_TYPE[iType]
    assert(mCoinInfo,string.format("org err CoinIcon %d",iType))
    return mCoinInfo.icon or mCoinInfo.name
end

function CRedPacket:AddDrawRedPacket(oPlayer,iGold)
    self:Dirty()
    local iPid = oPlayer:GetPid()
    self.m_mDrawList[db_key(iPid)] = {
        name = oPlayer:GetName(),
        gold = iGold,
    }
end

function CRedPacket:PackRedPacket()
    local mDrawData = {}
    for iPid,mData in pairs(self.m_mDrawList) do
        local sName = mData["name"]
        local iGold = mData["gold"]
        table.insert(mDrawData,{
            pid =  iPid,
            name = sName,
            gold = iGold,
        })
    end
    return {
        shape = self.m_iShape,
        title = self.m_sTitle,
        amount = self.m_iAmount,
        remain_gold = self.m_iKeepGold,
        draw_list = mDrawData,
    }
end

function CRedPacket:GetDrawRedPacketInfo(iPid)
    local mData = self.m_mDrawList[tostring(iPid)] or {}
    return {
        idx = self:ID(),
        shape = self.m_iShape,
        pid = iPid,
        gold = mData["gold"],
        title = self.m_sTitle,
    }
end


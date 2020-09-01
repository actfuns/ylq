--import module
local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"

local rankbase = import(service_path("rankbase"))


function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, rankbase.CRankBase)

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true, true,}
    self.m_iSaveLimit = 600 --保证所有可参加的玩家
    self.m_DefaultRank = 1000
end

function CRank:PushDataToRank(mData)
    for _,v in pairs(mData) do
        self:_PushDataToRank(v)
    end
end

function CRank:_PushDataToRank(mData)
    local bNeedSort = false
    local sKey, mUnit = self:GenRankUnit(mData)

    if self.m_mRankData[sKey] then
        if self:NeedReplaceRankData(sKey, mUnit) then
            self:Dirty()
            self.m_mRankData[sKey] = nil
            extend.Array.remove(self.m_lSortList, sKey)
            self:InsertToOrderRank(sKey, mUnit)
        end
    else
        self:InsertToOrderRank(sKey, mUnit)
    end
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.hit, mData.pid,mData.name,mData.shape}
end

function CRank:UpdateName(sName, mData)
    mData[3] = sName
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, pid = mData[2]}
end

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.hit = mData[1]
    end
    return mVal
end

function CRank:EqualVal(mOldVal, mNewVal)
    mOldVal = mOldVal or {}
    mNewVal = mNewVal or {}
    return mOldVal.hit == mOldVal.hit
end

function CRank:GetExtraRankData(mData)
    if mData.endui then
        local mRank = self:MyRank(mData.pid) or {}

        local mTop20 = self:TopRange(1,10,function (mPack,mUint,i)
            mPack.hit = mUint[1]
            mPack.pid = mUint[2]
            mPack.name = mUint[3]
            mPack.shape = mUint[4]
            mPack.rank = i
            end)
        for _,mUint in pairs(mTop20) do
            if mUint.pid == mData.pid or mRank.hit ==mUint.hit then
                mRank.rank = mUint.rank
                break
            end
        end
        return {rank=mRank,top20 = mTop20}
    end
    if mData.reward then
        local mTop500 = self:TopRange(1,510,function (mPack,mUint,i)
            mPack.pid = mUint[2]
            mPack.rank = i
            end)
        return {rank=mTop500,}
    end
    if mData.damage then
        local mTop2 = self:TopRange(1,2,function (mPack,mUint,i)

            mPack.pid = mUint[2]
            mPack.hit = mUint[1]
            mPack.name = mUint[3]
            mPack.rank = i
            end)
        return {rank=mTop2,}
    end


end


function CRank:TopRange(idx,iNum,packfunc)
    local iStart = idx or 1
    local iEnd = iStart + (iNum or 20) - 1
    local mTop = {}
    local iLast = 1
    local iHit
    local sKey,mUint,iRank,mPack
    for i =iStart,iEnd do
        sKey = self.m_lSortList[i]
        if not sKey then
            break
        end
        mUint = self.m_mRankData[sKey]
        iRank = i
        if iHit and iHit == mUint[1] then
            iRank = iLast
        end
        iLast = iRank
        iHit = mUint[1]
        mPack = {}
        packfunc(mPack,mUint,iRank)
        table.insert(mTop,mPack)
    end
    return mTop
end

function CRank:MyRank(pid)
    local iLen = self.m_DefaultRank
    if #self.m_lSortList <=0 then
        return
    end
    local sKey = db_key(pid)
    local mUint = self.m_mRankData[sKey]
    if not mUint then
        return
    end
    for iRank,sK in pairs(self.m_lSortList) do
        if sK == sKey then
            iLen = iRank
            break
        end
    end
    local mPack = {}
    mPack.hit = mUint[1]
    mPack.rank = iLen
    return mPack
end

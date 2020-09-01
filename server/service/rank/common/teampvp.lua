--import module
local global = require "global"
local skynet = require "skynet"
local rankbase = import(service_path("rankbase"))
local interactive = require "base.interactive"
local playersend = require "base.playersend"

function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, rankbase.CRankBase)

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true, false,}
    self.m_iShowLimit = 100
    self.m_iShowPage = 1
    self.m_NeedSort = false
end

function CRank:Save()
    return {}
end

function CRank:PushDataToRank(mData)
    self.m_NeedSort = true
    super(CRank).PushDataToRank(self,mData)
end

function CRank:CheckShowData()
    if not self.m_NeedSort then
        return
    end
    self.m_NeedSort = false
    self:DoStubShowData()
end

function CRank:Key(mData)
    return mData[2]
end


function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.point,mData.win,mData.pid,mData.name,mData.fail}
end



function CRank:GetCondition(iRank, mData)
    return {rank = iRank, pid = mData[3]}
end

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.point = mData[1]
        mVal.win = mData[2]
    end
    return mVal
end

function CRank:EqualVal(mOldVal, mNewVal)
    mOldVal = mOldVal or {}
    mNewVal = mNewVal or {}
    return mOldVal.point == mNewVal.point and mOldVal.win == mNewVal.win
end

function CRank:GetExtraRankData(mData)
    local iPid = mData.pid
    local iRank = 0
    local iLimit = mData.limit
    self:CheckShowData()
    local lResult = self:GetRankShowDataByLimit(iLimit)
    local mTop50 = {}
    local mUnit
    for _,lInfo in pairs(lResult) do
        mUnit ={
        score = lInfo[1],
        win = lInfo[2],
        pid = lInfo[3],
        name = lInfo[4],
        rank=lInfo[7],
         }
        table.insert(mTop50,mUnit)
    end
    if iPid ~= 0 then
        local mMyRank = self:GetShowRankDataByKey(db_key(iPid)) or {}
        local mNet = {
            rank = mTop50,
            myscore = mMyRank[1] or 0,
            mywin = mMyRank[2] or 0,
            myfail = mData.fail or 0,
            myrank = mMyRank[7] or 0
        }
        playersend.Send(iPid,"GS2CTeamPVPRank",mNet)
    else
        return {rank = mTop50}
    end

end

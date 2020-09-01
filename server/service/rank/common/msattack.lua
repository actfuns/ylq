--import module
local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"
local interactive = require "base.interactive"
local playersend = require "base.playersend"

local rankbase = import(service_path("rankbase"))


function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, rankbase.CRankBase)

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true,false,false}
    self.m_lJoin = {}
    self.m_iSaveLimit = 300
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.point,mData.time,mData.pid,mData.name,mData.shape,mData.school,mData.orgname}
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, pid = mData[3]}
end

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.point = mData[1]
    end
    return mVal
end

function CRank:EqualVal(mOldVal, mNewVal)
    mOldVal = mOldVal or {}
    mNewVal = mNewVal or {}
    return mOldVal.point == mNewVal.point
end

function CRank:UpdateName(sName, mData)
    mData[4] = sName
end

function CRank:SyncMsAttackMyRank(iPid)
    local sKey = db_key(iPid)
    local mUnit = self.m_mRankData[sKey]
    if not mUnit then
        return
    end
    local mInfo = {
        point = mUnit[1],
        pid = mUnit[3],
        name = mUnit[4],
        shape = mUnit[5],
        school = mUnit[6],
        orgname = mUnit[7],
    }
    local iIdx = self:BinarySearch(sKey, mUnit)
    local iLen = #self.m_lSortList
    for idx=iIdx,1,-1 do
        if self.m_lSortList[idx] == sKey then
            mInfo.rank = idx
            break
        end
    end

    playersend.Send(iPid,"GS2CMsattackMyInfo",{info=mInfo})
end

function CRank:GetMsAttackRankData(iPid,iType,iStart,iEnd)
    local mList = {}
    local sKey,mUnit
    for idx=iStart,iEnd do
        sKey = self.m_lSortList[idx]
        if not sKey then
            break
        end
        mUnit = self.m_mRankData[sKey]
        if mUnit then
            table.insert(mList,{
                point = mUnit[1],
                pid = mUnit[3],
                name = mUnit[4],
                shape = mUnit[5],
                school = mUnit[6],
                orgname = mUnit[7],
                rank = idx,
            })
        end
    end
    playersend.Send(iPid,"GS2CRankMsattackInfo",{type=iType,list=mList})
end

function CRank:RefreshData()
end

function CRank:PushDataToRank(mData,mArgs,bReInsert)
    super(CRank).PushDataToRank(self,mData,mArgs,bReInsert)
    self:SyncMsAttackMyRank(mData.pid)
    self.m_lJoin[mData.pid] = true
end

function CRank:ResetRankData()
    self.m_lJoin = {}
    super(CRank).ResetRankData(self)
end

function CRank:SyncAllPlayerInfo()
    local mJoin =  self.m_lJoin or {}
    for iPid,_ in pairs(mJoin) do
        self:SyncMsAttackMyRank(iPid)
    end
end

function CRank:GetRewardNameList()
    local mRet = {join=self.m_lJoin,rank={}}
    local mJoin = table_copy(self.m_lJoin)
    local mUnit
    for idx, sKey in ipairs(self.m_lSortList) do
        mUnit = self.m_mRankData[sKey]
        if mUnit then
            local pid = mUnit[3]
            local point = mUnit[1]
            mJoin[pid] = nil
            table.insert(mRet.rank,{pid,point})
        end
    end
    for pid,_ in pairs(mJoin) do
        table.insert(mRet.rank,pid)
    end
    return mRet
end
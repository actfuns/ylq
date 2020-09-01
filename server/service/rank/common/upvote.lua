--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local rankbase = import(service_path("rankbase"))


function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, rankbase.CRankBase)

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true, true, true, false}
    self.m_iShowLimit = 1000
    self.m_iSaveLimit = 1100
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.upvote, mData.time, mData.active_time, mData.pid, mData.name, mData.school,}
end

function CRank:DoStubShowData()
    super(CRank).DoStubShowData(self)
    self:SendShowRankToWorld()
end

function CRank:Load(m)
    super(CRank).Load(self, m)
    self:SendShowRankToWorld()
end

function CRank:PackShowRankData(iPid, iPage)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub
    mNet.my_rank = self.m_mShowRank[db_key(iPid)]

    local mData = self:GetShowRankData(iPage)
    local lUpvoteRank = {}
    local mUnit
    for idx, lInfo in ipairs(mData) do
        mUnit = {}
        mUnit.upvote = lInfo[1]
        mUnit.pid = lInfo[4]
        mUnit.name = lInfo[5]
        mUnit.school = lInfo[6]
        mUnit.rank_shift = lInfo[7]
        table.insert(lUpvoteRank, mUnit)
    end
    if #lUpvoteRank then
        mNet.upvote_rank = lUpvoteRank
    end
    return mNet
end

function CRank:UpdateActiveTime(sKey)
    if not self.m_mRankData[sKey] then
        return
    end
    self.m_mRankData[sKey][3] = get_time()
    self:Dirty()
end

function CRank:OnLogin(iPid, bReEnter)
    local sKey = db_key(iPid)
    self:UpdateActiveTime(sKey)
end

function CRank:OnLogout(iPid)
    local sKey = db_key(iPid)
    self:UpdateActiveTime(sKey)
end

function CRank:RemoteGetTop3Profile()
end

function CRank:SendShowRankToWorld()
    local mData = {rank_name = self.m_sRankName, show_rank = self.m_mShowRank}
    interactive.Send(".world", "rank", "KeepUpvoteShowRank", mData)
end

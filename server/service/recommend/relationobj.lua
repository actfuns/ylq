
--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

function NewCRelationMgr(...)
    local o = CRelationMgr:New(...)
    return o
end

CRelationMgr = {}
CRelationMgr.__index = CRelationMgr
inherit(CRelationMgr, logic_base_cls())

function CRelationMgr:New()
    local o = super(CRelationMgr).New(self)
    o.m_mRelation = {} --信息集合
    o.m_mGradeIndex = {} --等级索引
    return o
end


function CRelationMgr:ClearAllCache()
    self.m_mRelation = {}
    self.m_mGradeIndex = {} 
end


function CRelationMgr:UpdateRelationInfo(pid,mInfo)
    local oRelation = self.m_mRelation[pid]
    if oRelation then
        local iGrade = oRelation.grade 
        if self.m_mGradeIndex[iGrade] then
            self.m_mGradeIndex[iGrade][pid]=nil
        end
    end
    local iGrade = mInfo.grade
    self.m_mRelation[pid] = mInfo
    if not self.m_mGradeIndex[iGrade] then
        self.m_mGradeIndex[iGrade] = {}
    end
    self.m_mGradeIndex[iGrade][pid] = mInfo
end


function CRelationMgr:LoadRelationInfo(iPid,backfun)
    interactive.Request(".world", "friend", "GetFriendInfo", {pid = iPid}, function (mRecord, mData)
        backfun(mRecord,mData)
    end)
end


function CRelationMgr:RecommendFriend(pid,mArg,mRecordBack)
    local oRelation = self.m_mRelation[pid]
    if not oRelation then
        self:LoadRelationInfo(pid,function (mRecord,mData)
            if not mData then 
                interactive.Response(mRecordBack.source, mRecordBack.session, {success = false })
                return
            end
            self:UpdateRelationInfo(mData.pid,mData.data)
            self:_RecommendFriend(pid,mArg,mRecordBack)
        end)
    else
        self:_RecommendFriend(pid,mArg,mRecordBack)
    end
end


function CRelationMgr:_RecommendFriend(pid,mArg,mRecordBack)
    local mExcludeList = mArg.plist or {}
    local mLabel = mArg.label or {}
    local iNeed = mArg.need or 10
    local oRelation = self.m_mRelation[pid]
    local mPlist = {}
    local iGrade = oRelation.grade
    local iExtent = 10
    table.insert(mExcludeList,oRelation.friendlist)
    local iGrade1,iGrade2,iGrade3,iGrade4 = iGrade+iExtent ,iGrade,iGrade-iExtent,iGrade
    while iExtent < 100 do
        iGrade1 = iGrade1 - iExtent
        iGrade2 = iGrade2 - iExtent
        iGrade3 = iGrade3 + iExtent
        iGrade4 = iGrade4 + iExtent
        local mlist = self:CollectRelation(iGrade1,iGrade2,mLabel,mExcludeList,iNeed-#mPlist)
        if #mlist ~=0 then
            for _,v in ipairs(mlist) do 
                table.insert(mPlist,v)
            end
        end
        mlist = self:CollectRelation(iGrade3,iGrade4,mLabel,mExcludeList,iNeed-#mPlist,mPlist)
        if #mlist ~=0 then
            for _,v in ipairs(mlist) do 
                table.insert(mPlist,v)
            end
        end
        
        if iNeed- #mPlist <=0 then
            break
        end
        iExtent=iExtent+10
    end
    interactive.Response(mRecordBack.source, mRecordBack.session, { success = true , data = mPlist ,})
end


function CRelationMgr:CollectRelation(grade1,grade2,mLabel,mExcludelist,iLimit)
    local iCnt = 0
    local mTargetList = {}
    for iGrade = grade1,grade2 do 
        local gradelist = self.m_mGradeIndex[iGrade]
        if gradelist then
            for pid,g in pairs(gradelist) do
                if not mExcludelist[pid] then
                    local mRelation = self.m_mRelation[pid]
                    if #mLabel~=0 and mRelation then
                        for _,sLabel in pairs(mLabel) do 
                            if sLabel(mRelation.label,sLabel) then
                                table.insert(mTargetList,pid)
                                iCnt=iCnt+1
                                break
                            end
                        end
                    else
                        table.insert(mTargetList,pid)
                        iCnt=iCnt+1
                    end
                end
            end
        end
    end
    return mTargetList
end



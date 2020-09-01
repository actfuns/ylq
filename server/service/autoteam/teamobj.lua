--import module
local global = require "global"
local extend = require "base.extend"

local gamedefines = import(lualib_path("public.gamedefines"))

local memobj = import(service_path("memobj"))

function NewTeam(...)
    return CTeam:New(...)
end

CTeam = {}
CTeam.__index = CTeam
inherit(CTeam, logic_base_cls())

function CTeam:New(iTeamID, mArgs)
    local o = super(CTeam).New(self)
    o.m_ID = iTeamID
    o:Init(mArgs)
    return o
end

function CTeam:Init(mArgs)
    self.m_iLeader = mArgs.leader
    self.m_mMember = {}
    local mMem = mArgs.mem
    for _,mData in ipairs(mMem) do
        local pid = mData["pid"]
        local oMem = memobj.NewMember(pid,mData)
        self.m_mMember[pid] = oMem
    end
    self.m_AutoTarget = mArgs.target_info
    self.m_iMatchStartTime = get_time()
    self.m_iMatchCount = 0  --匹配次数
    self.m_mBlackList = mArgs.black_list or {}
end

function CTeam:Release()
    for _,oMem in pairs(self.m_mMember) do
        baseobj_safe_release(oMem)
    end
    self.m_mMember = {}
    super(CTeam).Release(self)
end

function CTeam:MemberEnter(pid, mArgs)
    local oMem = memobj.NewMember(pid, mArgs)
    if oMem then
        self:AddMember(oMem)
    end
end

function CTeam:AddMember(oMem)
    self.m_mMember[oMem.m_ID] = oMem
end

function CTeam:GetMember(iPid)
    return self.m_mMember[iPid]
end

function CTeam:Leave(iPid)
    local oMem = self:GetMember(iPid)
    if oMem then
        baseobj_delay_release(oMem)
    end
    self.m_mMember[iPid] = nil
end

function CTeam:GetTargetID()
    return self.m_AutoTarget["auto_target"]
end

function CTeam:AddMem2BlackList(pid, iEndTimeStamp)
    self.m_mBlackList[pid] = iEndTimeStamp or (get_time() + 5 * 60)
end

function CTeam:StartAutoMatch()
    local iTeamID = self.m_ID
    local iTargetID = self.m_AutoTarget["auto_target"]
    self:DelTimeCb("TeamAutoMatch")
    self:AddTimeCb("TeamAutoMatch", 3 * 1000, function () 
        local oTargetMgr = global.oTargetMgr
        local oTeam = oTargetMgr:GetTargetTeam(iTargetID,iTeamID)
        if oTeam then
            oTeam:AutoMatching()
        end
    end)
    local iDelay =  10 * 60
    self:AddTimeCb("TeamMatchTimeOut", iDelay * 1000,  function ()
        local oTargetMgr = global.oTargetMgr
        local oTeam = oTargetMgr:GetTargetTeam(iTargetID,iTeamID)
        oTeam:MatchTimeOut()
    end)
end

function CTeam:AutoMatching()
    self:DelTimeCb("TeamAutoMatch")
    local oTargetMem = self:AutoMatch()
    if oTargetMem then
        self:AutoMatchSuccess(oTargetMem)
    end
    local iCount = self.m_iMatchCount
    if iCount == 5 then
        local oTargetMgr = global.oTargetMgr
        oTargetMgr:CheckTargetTeamNotify(self:GetTargetID(), self.m_ID)
    end
    local iTeamID = self.m_ID
    local iTargetID = self.m_AutoTarget["auto_target"]
    self:AddTimeCb("TeamAutoMatch", 3 * 1000, function()
        local oTargetMgr = global.oTargetMgr
        local oTeam = oTargetMgr:GetTargetTeam(iTargetID,iTeamID)
        oTeam:AutoMatching()
    end)
    self.m_iMatchCount = iCount + 1
end

function CTeam:MatchTimeOut()
        local oTargetMgr = global.oTargetMgr
        oTargetMgr:TargetTeamTimeOut(self:GetTargetID(), self.m_ID)
end

function CTeam:AutoMatch()
        local oTargetMgr = global.oTargetMgr
        local iTargetID = self.m_AutoTarget["auto_target"]
        local iMinGrade = self.m_AutoTarget["min_grade"]
        local iMaxGrade = self.m_AutoTarget["max_grade"]
        local oLeader = self:GetMember(self.m_iLeader)
        if not oLeader then
            return false
        end
        local iLeaderGrade = oLeader:GetGrade()
        local lMatchPlayers = oTargetMgr:GetTargetMemList(iTargetID)
        local iMinWeight , mMem = 100, nil
        local mWeight = {
            black_list = 4,
            school = 2,
            grade = 1,
            time = 0,
        }
        if next(lMatchPlayers) then
            local iNowTime =get_time()
            for pid, oMem in pairs(lMatchPlayers) do
                local iGrade = oMem:GetGrade()
                if (iGrade >= iMinGrade and iGrade <= iMaxGrade and oMem:GetMinGrade() <= iLeaderGrade and oMem:GetMaxGrade()>= iLeaderGrade) then
                    local iCountWeight = 0.0
                    if self:InBlackList(pid) then
                        -- 30秒不匹配黑名单
                        local iBlackListEndTime = self.m_mBlackList[pid]
                        if iNowTime < (iBlackListEndTime - 5 * 60 + 30)  then
                            iCountWeight = 1000
                        else
                            iCountWeight = iCountWeight + mWeight.black_list
                        end
                    end
                    local iSchool = oMem:GetSchool()
                    if self:HasSchool(iSchool) then
                        iCountWeight = iCountWeight + mWeight.school
                    end
                    local oLeader = self:GetMember(self.m_iLeader )
                    local iGradeWeight = mWeight.grade + (math.abs(iGrade - oLeader:GetGrade()) / 1000)
                    local iOldestTime = iNowTime - 5 * 60
                    local iMemStartTime = oMem:GetStartTime()
                    local iTimeWeight = mWeight.time + (math.abs(iMemStartTime - iOldestTime) / 1000)
                    iCountWeight = iCountWeight + iGradeWeight + iTimeWeight
                    if (iCountWeight < iMinWeight) and not(iGrade - oLeader:GetGrade() < 5 and oMem.m_iTarget ==1) then
                        iMinWeight = iCountWeight
                        mMem = oMem
                    end
                end
            end
        end
        return mMem
end

function CTeam:HasSchool(iSchool)
    for pid, oMem in pairs(self.m_mMember) do
        if oMem:GetSchool() == iSchool then
            return true
        end
    end
    return false
end

function CTeam:InBlackList(pid)
    local iEndTime = self.m_mBlackList[pid]
    if iEndTime then
        if iEndTime < get_time() then
            self.m_mBlackList[pid] = nil
            return false
        else
            return true
        end
    end
    return false
end

function CTeam:AutoMatchSuccess(oMem)
    if oMem then
        local oTargetMgr = global.oTargetMgr
        local iTargetID = self:GetTargetID()
        local iTeamID = self.m_ID
        local pid = oMem.m_ID
        oTargetMgr:AutoMatchSuccess(iTargetID, iTeamID, pid)
    end
end

function CTeam:CancelAutoMatch()
    self:DelTimeCb("TeamAutoMatch")
end
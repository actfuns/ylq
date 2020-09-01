local global = require "global"
local res = require "base.res"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"

local memobj = import(service_path("memobj"))
local teamobj = import(service_path("teamobj"))

function NewTargetMgr(...)
    return CTargetMgr:New(...)
end

function NewTarget(...)
    return CTarget:New(...)
end


CTargetMgr = {}
CTargetMgr.__index = CTargetMgr
inherit(CTargetMgr,logic_base_cls())

function CTargetMgr:New()
    local o = super(CTargetMgr).New(self)
    o:Init()
    return o
end

function CTargetMgr:Init()
    self.m_mTargetList = {}
    local lTarget = res["daobiao"]["autoteam"]
    for iTarget, _ in pairs(lTarget) do
        self.m_mTargetList[iTarget] = NewTarget(iTarget)
    end
end

function CTargetMgr:GetTarget(iTarget)
    return self.m_mTargetList[iTarget]
end

function CTargetMgr:GetTargetMember(iTarget, iPid)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        return oTarget:GetMember(iPid)
    end
end

function CTargetMgr:GetTargetTeam(iTarget, iTeam)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        return oTarget:GetTeam(iTeam)
    end
end

function CTargetMgr:GetTargetTeamList(iTarget)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        return oTarget:GetTeamList()
    end
end

function CTargetMgr:GetTargetMemList(iTarget)
    local mTarget = res["daobiao"]["autoteam"][iTarget]
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        if mTarget.parentId ~= 0 and self:GetTarget(mTarget.parentId) then
            local mList1 = oTarget:GetMemberList()
            local oParent = self:GetTarget(mTarget.parentId)
            local mList2 = oParent:GetMemberList()
            local mList3 = table_copy(mList1)
            return table_combine(mList3,mList2)
        else
            return oTarget:GetMemberList()
        end
    end
end

function CTargetMgr:AddTargetMem(iTarget, iPid, mArgs)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        oTarget:AddMember(iPid, mArgs)
    end
end

function CTargetMgr:AddTargetTeam(iTarget, iTeam, mArgs)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        oTarget:AddTeam(iTeam, mArgs)
    end
end

function CTargetMgr:RemoveTargetMember(iTarget, iPid)
    if iTarget == 1 then
        
    else
        local oTarget = self:GetTarget(iTarget)
        local oMem = oTarget:GetMember(iPid)
        if oTarget then
            oTarget:RemoveMember(iPid)
        end
    end
end

function CTargetMgr:RemoveTargetTeam(iTarget, iTeam)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        oTarget:RemoveTeam(iTeam)
    end
end

function CTargetMgr:UpdateTargetTeamMem(iTarget, iTeam, iPid, mArgs)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        oTarget:UpdateTeamMember(iTeam, iPid, mArgs)
    end
end

function CTargetMgr:MemLeaveTargetTeam(iTarget, iTeam, iPid)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        oTarget:MemberLeaveTeam(iTeam, iPid)
    end
end

function CTargetMgr:DisconnectedTargetMem(iTarget, iPid)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        oTarget:RemoveMember(iPid)
    end
end

function CTargetMgr:MemberEnterTargetTeam(iTarget, iTeam, iPid, mArgs)
    local oTarget = self:GetTarget(iTarget)
    if oTarget then
        oTarget:MemberEnterTeam(iTeam, iPid, mArgs)
    end
end

function CTargetMgr:AddMem2TeamBlackList(iTarget, iTeam, iPid, iEndTimeStamp)
    local oTargetTeam = self:GetTargetTeam(iTarget, iTeam)
    if oTargetTeam then
        oTargetTeam:AddMem2BlackList(iPid, iEndTimeStamp)
    end
end

function CTargetMgr:CountTargetAutoMatch(iTarget, iPid)
    local iMemCount  = 0
    local iTeamCount = 0
    if iTarget == 0 then
        for id, oTarget in pairs(self.m_mTargetList) do
            local lTargetTeam = oTarget:GetTeamList()
            local lTargetMem = oTarget:GetMemberList()
            iTeamCount = iTeamCount + table_count(lTargetTeam)
            iMemCount = iMemCount + table_count(lTargetMem)
        end
    else
        local oTarget = self:GetTarget(iTarget)
        if oTarget then
            local lTargetTeam = oTarget:GetTeamList()
            local lTargetMem = oTarget:GetMemberList()
            iTeamCount = iTeamCount + table_count(lTargetTeam)
            iMemCount = iMemCount + table_count(lTargetMem)
        end
    end
    local mNet = {}
    mNet["auto_target"] = iTarget
    mNet["member_count"] = iMemCount
    mNet["team_count"] = iTeamCount
    playersend.Send(iPid,"GS2CCountAutoMatch",mNet)
end

function CTargetMgr:AutoMatchSuccess(iTarget, iTeam, pid)
    interactive.Send(".world", "team", "AutoMatchSuccess", {targetid = iTarget, teamid =iTeam, pid = pid})
end

function CTargetMgr:TargetTeamTimeOut(iTarget, iTeam)
    interactive.Send(".world", "team", "TeamAutoMatchTimeOut", {targetid = iTarget, teamid = iTeam})
    self:RemoveTargetTeam(iTarget, iTeam)
end

function CTargetMgr:CheckTargetMemberNotify(iTarget, pid)
    if iTarget ~= 1 then
        self:CheckByRule1(iTarget,pid)
    end
end

function CTargetMgr:CheckByRule1( iTarget,pid )
    local oTargetMem = self:GetTargetMember(iTarget, pid)
    if oTargetMem then
        local lTargetMem = self:GetTargetMemList(iTarget)
        local lTargetTeam = self:GetTargetTeamList(iTarget)
        local iTargetTeamCount = table_count(lTargetTeam)
        local iTargetMemCount = table_count(lTargetMem)
        if iTargetTeamCount < 1 and iTargetMemCount  >=5 then
            interactive.Send(".world", "team", "NotifyAutoMatchMember", {targetid = iTarget, pid = pid})
        end
    end
end

function CTargetMgr:CheckTargetTeamNotify(iTarget, iTeam)
    local oTargetTeam = self:GetTargetTeam(iTarget, iTeam)
    if oTargetTeam then
        local lTargetMem = self:GetTargetMemList(iTarget)
        local lTargetTeam = self:GetTargetTeamList(iTarget)
        local iTargetTeamCount = table_count(lTargetTeam)
        local iTargetMemCount = table_count(lTargetMem)
        if iTargetTeamCount >= 5 and iTargetMemCount < 1 then
            interactive.Send(".world", "team", "NotifyAutoMatchTeam", {targetid = iTarget, teamid = iTeam})
        end
    end
end

function CTargetMgr:TargetMemberTimeOut(iTarget, pid)
    if self:GetTargetMember(iTarget, pid) then
        interactive.Send(".world", "team", "MemAutoMatchTimeOut", {targetid = iTarget, pid = pid})
        self:RemoveTargetMember(iTarget, pid)
    end
end

CTarget = {}
CTarget.__index = CTarget
inherit(CTarget, logic_base_cls())

function CTarget:New(iTarget)
    local o = super(CTarget).New(self)
    o.m_ID = iTarget
    o.m_mTeamList = {}
    o.m_mMemList = {}
    return o
end

function CTarget:GetTargetID()
    return self.m_ID
end

function CTarget:GetTeam(iTeam)
    return self.m_mTeamList[iTeam]
end

function CTarget:GetMember(pid)
    return self.m_mMemList[pid]
end

function CTarget:GetTeamList()
    return self.m_mTeamList
end

function CTarget:GetMemberList()
    return self.m_mMemList
end

function CTarget:AddMember(pid, mArgs)
    local oMem = self.m_mMemList[pid]
    if oMem then
        return 
    end
    oMem = memobj.NewMember(pid,mArgs)
    self.m_mMemList[oMem.m_ID] = oMem
    oMem:StartAutoMatch()
end

function CTarget:RemoveMember(iMemID)
    local oTargetMem = self:GetMember(iMemID)
    if oTargetMem then
        oTargetMem:CancelAutoMatch()
        
        baseobj_delay_release(oTargetMem)
    end
    self.m_mMemList[iMemID] = nil
end

function CTarget:AddTeam(iTeam, mArgs)
    local oTeam = self.m_mTeamList[iTeam]
    if oTeam then
        return 
    end
    oTeam = teamobj.NewTeam(iTeam, mArgs)
    oTeam:StartAutoMatch()
    self.m_mTeamList[oTeam.m_ID] = oTeam
end

function CTarget:RemoveTeam(iTeam)
    local oTargetTeam = self:GetTeam(iTeam)
    if oTargetTeam then
        oTargetTeam:CancelAutoMatch()
        baseobj_delay_release(oTargetTeam)
    end
    self.m_mTeamList[iTeam] = nil
end

function CTarget:UpdateTeamMember(iTeam, iPid, mArgs)
    local oTeam = self:GetTeam(iTeam)
    if oTeam then
        local oMem = oTeam:GetMember(iPid)
        if oMem then
            oMem:Update(mArgs)
        end
    end
end

function CTarget:MemberEnterTeam(iTeam, iPid, mArgs)
    local oTeam = self:GetTeam(iTeam)
    if oTeam then
        oTeam:MemberEnter(iPid, mArgs)
    end
end

function CTarget:MemberLeaveTeam(iTeam, iPid)
    local oTeam = self:GetTeam(iTeam)
    if oTeam then
        oTeam:Leave(iPid)
    end
end
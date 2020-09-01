--import module
local global = require "global"
local skynet = require "skynet"
local playersend = require "base.playersend"

function OnLogin(mRecord,mData)
end

function PlayerStartAutoMatch(mRecord,mData)
    local pid = mData.pid
    local iTargetID = mData.targetid
    local mArgs = mData.mem_info
    mArgs.iMinGrade = mData.min_grade
    mArgs.iMaxGrade = mData.max_grade
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:AddTargetMem(iTargetID,pid, mArgs)
end

function CanclePlayerAutoMatch(mRecord,mData)
    local pid = mData.pid
    local iTargetID = mData.targetid
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:RemoveTargetMember(iTargetID, pid)
end

function UpdateTeamMember(mRecord,mData)
    local iTeamID = mData.teamid
    local pid = mData.pid
    local iTargetID = mData.targetid
    local mArgs = mData.mem_info
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:UpdateTargetTeamMem(iTargetID, iTeamID, pid, mArgs)
end

function UpdateTargetMember(mRecord, mData)
    local pid = mData.pid
    local iTargetID = mData.targetid
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:UpdateTargetMember(iTargetID, pid)
end

function OnDisconnected(mRecord,mData)
    local iTargetID = mData.targetid
    local pid = mData.pid
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:DisconnectedTargetMem(iTargetID, pid)
end

function TeamStartAutoMatch(mRecord,mData)
    local iTeamID = mData.teamid
    local iTargetID = mData.targetid
    local mArgs = mData.team_info
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:AddTargetTeam(iTargetID, iTeamID, mArgs)
end

function CancleTeamAutoMatch(mRecord,mData)
    local iTargetID = mData.targetid
    local iTeamID = mData.teamid
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:RemoveTargetTeam(iTargetID, iTeamID)
end

function OnEnterTeam(mRecord,mData)
    local iTargetID = mData.targetid
    local iTeamID = mData.teamid
    local pid = mData.pid
    local mArgs = mData.mem_info
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:MemberEnterTargetTeam(iTargetID, iTeamID, pid, mArgs)
end

function OnLeaveTeam(mRecord,mData)
    local iTargetID = mData.targetid
    local iTeamID = mData.teamid
    local pid = mData.pid
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:MemLeaveTargetTeam(iTargetID, iTeamID, pid)
end

function TeamCancle(mRecord,mData)
    local iTargetID = mData.targetid
    local iTeamID = mData.teamid
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:RemoveTargetTeam(iTargetID, iTeamID)
end

function CountAutoMatch(mRecord, mData)
    local iTargetID = mData["targetid"]
    local iPid = mData["pid"]
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:CountTargetAutoMatch(iTargetID,iPid)
end

function AddMem2TeamBlackList(mRecord, mData)
    local iTargetID = mData["targetid"]
    local iTeamID = mData["teamid"]
    local pid = mData["pid"]
    local iEndTimeStamp = mData["timestamp"]
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:AddMem2TeamBlackList(iTargetID, iTeamID, pid, iEndTimeStamp)
end

function GetTargetMemList(mRecord,mData)
    local iTargetID = mData["targetid"]
    local iPid = mData["pid"]
    local oTargetMgr = global.oTargetMgr
    local mMem = oTargetMgr:GetTargetMemList(iTargetID)
    local lMem = {}
    for id,oMem in pairs(mMem) do
        table.insert(lMem,{pid=id,player_info = oMem:PackMemInfo()})
    end
    playersend.Send(iPid,"GS2CTargetMemList",{info=lMem})
end
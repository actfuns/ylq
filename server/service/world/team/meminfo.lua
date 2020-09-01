local global = require "global"
local net = require "base.net"

function NewMember(...)
    return CMember:New(...)
end

StatusHelperFunc = {}

function StatusHelperFunc.hp(o)
    return o:GetHp()
end

function StatusHelperFunc.max_hp(o)
    return o:GetMaxHp()
end

function StatusHelperFunc.model_info(o)
    return o:GetModelInfo()
end

function StatusHelperFunc.name(o)
    return o:GetName()
end

function StatusHelperFunc.grade(o)
    return o:GetGrade()
end

function StatusHelperFunc.school(o)
    return o:GetSchool()
end

function StatusHelperFunc.status(o)
    return o:Status()
end

function StatusHelperFunc.school_branch(o)
    return o:Schoolbranch()
end

function StatusHelperFunc.bcmd(o)
    return o:InBattleCommand()
end

CMember = {}
CMember.__index = CMember
inherit(CMember,logic_base_cls())

function CMember:New(pid,mArgs)
    local o = super(CMember).New(self)
    o.m_ID = pid
    o:Init(mArgs)
    return o
end

function CMember:Init(mArgs)
    self.m_mModelInfo = mArgs.model_info
    self.m_sName = mArgs.name or ""
    self.m_iSchool = mArgs.school or 1
    self.m_iGrade = mArgs.grade or 0
    self.m_iHp = mArgs.hp or 0
    self.m_iMaxHp = mArgs.maxhp or 0
    self.m_iMp = mArgs.mp or 0
    self.m_iMaxMp = mArgs.maxmp or 0
    self.m_iStatus = 1
    self.m_iActive = 1
    self.m_iSchoolBranch = mArgs.school_branch
    self.m_WarBattleCmd = 0
    self.m_iTeam = mArgs.teamid
end

function CMember:TeamID()
    return self.m_iTeam
end

function CMember:MemberID()
    return self.m_ID
end

function CMember:Update(mArgs)
    local mKey = {}
    for key,_ in pairs(mArgs) do
        if StatusHelperFunc[key] then
            mKey[key] = 1
        end
    end

    if table_count(mKey) <= 0 then
        return
    end
    self.m_mModelInfo = mArgs.model_info or self.m_mModelInfo
    self.m_sName = mArgs.name or self.m_sName
    self.m_iSchool = mArgs.school or self.m_iSchool
    self.m_iGrade = mArgs.grade or self.m_iGrade
    self.m_iHp = mArgs.hp or self.m_iHp
    self.m_iMaxHp = mArgs.maxhp or self.m_iMaxHp
    self.m_iMp = mArgs.mp or self.m_iMp
    self.m_iMaxMp = mArgs.maxmp or self.m_iMaxMp
    self.m_iSchoolBranch = mArgs.school_branch or self.m_iSchoolBranch
    self:StatusChange(mKey)
end

function CMember:SetStatus(iStatus)
    self.m_iStatus = iStatus
end

function CMember:Status()
    return self.m_iStatus
end

function CMember:PackInfo()

    return {
        pid = self.m_ID,
        status_info = self:GetSimpleStatus(),
        partner_info = self:GetPartnerInfo(),
    }
end

function CMember:PackAutoTeamInfo()
    local mArgs = {
        pid = self.m_ID,
        grade = self.m_iGrade,
        school = self.m_iSchool,
        name = self.m_sName,
        model_info = self.m_mModelInfo,
        school_branch = self.m_iSchoolBranch
    }
    return mArgs
end

function CMember:Schoolbranch()
    return self.m_iSchoolBranch
end

function CMember:GetHp()
    return self.m_iHp
end

function CMember:GetMp()
    return self.m_iMp
end

function CMember:GetMaxHp()
    return self.m_iMaxHp
end

function CMember:GetMaxMp()
    return self.m_iMaxMp
end

function CMember:GetName()
    return self.m_sName
end

function CMember:GetGrade()
    return self.m_iGrade
end

function CMember:GetModelInfo()
    return self.m_mModelInfo
end

function CMember:GetSchool()
    return self.m_iSchool
end

function CMember:GetSimpleStatus(m)
    local mRet = {}
    if not m then
        m = StatusHelperFunc
    end
    for k, _ in pairs(m) do
        local f = assert(StatusHelperFunc[k], string.format("GetSimpleStatus fail f get %s", k))
        mRet[k] = f(self)
    end
    return net.Mask("MemStatusInfo", mRet)
end

function CMember:InBattleCommand()
    return self.m_WarBattleCmd
end

function CMember:SetBattleCommand(iSet)
    self.m_WarBattleCmd = iSet
    self:StatusChange()
end

function CMember:GetPartnerInfo()
    local mRet = {}
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_ID)
    if oPlayer then
        mRet = oPlayer.m_oPartnerCtrl:GetTeamPartner()
    end
    return mRet
end

function CMember:StatusChange(m)
    local mStatus = self:GetSimpleStatus(m)
    self:SendAll("GS2CRefreshMemberInfo", {
        pid = self.m_ID,
        status_info = mStatus,
    })
end

function CMember:SendAll(sMessage,mNet)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_ID)
    if not oPlayer then
        return
    end
    local oTeam 
    if self.m_iTeam then
        oTeam = global.oTeamMgr:GetTeam(self.m_iTeam)
    else
        oTeam = oPlayer:HasTeam()
    end
    if not oTeam then
        return
    end
    local mMem = oTeam:OnlineMember()
    for pid,_ in pairs(mMem) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            oPlayer:Send(sMessage,mNet)
        end
    end
end
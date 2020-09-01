local global = require "global"

function NewMember(...)
    return CMember:New(...)
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
    self.m_sName = mArgs.name
    self.m_iSchool = mArgs.school
    self.m_iGrade = mArgs.grade
    self.m_iTarget = mArgs.target
    self.m_iStartMatchTime = get_time()
    self.m_iMinGrade = mArgs.iMinGrade
    self.m_iMaxGrade = mArgs.iMaxGrade
    self.m_iSchoolBranch = mArgs.school_branch
end

function CMember:PackMemInfo()
    return{
        model_info = self.m_mModelInfo,
        name = self.m_sName,
        school = self.m_iSchool,
        grade = self.m_iGrade,
        school_branch = self.m_iSchoolBranch,
    }
end

function CMember:GetMinGrade()
    return self.m_iMinGrade
end

function CMember:GetMaxGrade()
    return self.m_iMaxGrade
end

function CMember:GetGrade()
    return self.m_iGrade
end

function CMember:GetSchool()
    return self.m_iSchool
end

function CMember:GetName()
    return self.m_sName
end

function CMember:Update(mArgs)
    self.m_mModelInfo = mArgs.model_info or self.m_mModelInfo
    self.m_sName = mArgs.name or self.m_sName
    self.m_iSchool = mArgs.school or self.m_iSchool
    self.m_iGrade = mArgs.grade or self.m_iGrade
end

function CMember:StartAutoMatch()
    local iTargetID = self.m_iTarget
    local iID = self.m_ID
    self:DelTimeCb("CheckNotify")
    self:AddTimeCb("CheckNotify", 15*1000, function ()
        local oTargetMgr = global.oTargetMgr
        oTargetMgr:CheckTargetMemberNotify(iTargetID, iID)
    end)
    self:DelTimeCb("MemberMatchTimeOut")
    local iDelay =  5 * 60
    self:AddTimeCb("MemberMatchTimeOut", iDelay * 1000,  function ()
        local oTargetMgr = global.oTargetMgr
        local oTarget = oTargetMgr:GetTarget(iTargetID)
        local oMem = oTarget:GetMember(iID)
        oMem:AutoMatchTimeOut()
    end)
end

function CMember:CheckNotify()
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:CheckTargetMemberNotify(self.m_iTarget, self.m_ID)
end

function CMember:AutoMatchTimeOut()
    local oTargetMgr = global.oTargetMgr
    oTargetMgr:TargetMemberTimeOut(self.m_iTarget, self.m_ID)
end

function CMember:CancelAutoMatch()
    self:DelTimeCb("CheckNotify")
    self:DelTimeCb("MemberMatchTimeOut")
end

function CMember:GetStartTime()
    return self.m_iStartMatchTime
end
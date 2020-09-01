--import module

local global = require "global"

local loadskill = import(service_path("skill/loadskill"))
local analy = import(lualib_path("public.dataanaly"))

function NewSchoolSkillLearn( ... )
    local o = CSchoolSkillLearn:New()
    return o
end

function NewCultivateSkillLearn( ... )
    local o = CCultivateSkillLearn:New()
    return o
end

CSkillLearn = {}
CSkillLearn.__index = CSkillLearn
inherit(CSkillLearn,logic_base_cls())

function CSkillLearn:New()
    local o = super(CSkillLearn).New(self)
    return o
end

function CSkillLearn:ValidLearn(oPlayer)
end

function CSkillLearn:Learn(oPlayer)
end

function CSkillLearn:FastLearn(oPlayer)
end

CSchoolSkillLearn = {}
CSchoolSkillLearn.__index = CSchoolSkillLearn
inherit(CSchoolSkillLearn,CSkillLearn)

function CSchoolSkillLearn:New()
    local o = super(CSchoolSkillLearn).New(self)
    return o
end

function CSchoolSkillLearn:ValidLearn(oPlayer,iSk)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oSk = loadskill.GetSkill(iSk)
    local iLevel = oPlayer:GetSkillLevel(iSk)
    local iSchoolBranch = oPlayer:GetSchoolBranch()
    local iPoint = oSk:LearnNeedCost(iLevel)
    local iTopLevel = oSk:LimitLevel(oPlayer)
    if iLevel >= iTopLevel then
        oNotifyMgr:Notify(iPid,"所学习的技能等级不能超过技能等级上限")
        return false
    end
    local iLimitGrade = oSk:LimitGrade(iLevel + 1)
    if oPlayer:GetGrade() < iLimitGrade then
        oNotifyMgr:Notify(iPid,string.format("需要角色到达%s级", iLimitGrade))
        return false
    end
    if not oPlayer.m_oActiveCtrl:ValidResumeSkillPoint(iSchoolBranch,iPoint) then
        oNotifyMgr:Notify(iPid,"技能点不足,无法学习")
        return false
    end
    return true
end

function CSchoolSkillLearn:Learn(oPlayer,iSk)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    if not self:ValidLearn(oPlayer,iSk) then
        return
    end
    local oSk = loadskill.GetSkill(iSk)
    local iLevel = oPlayer:GetSkillLevel(iSk)
    local iNewLevel = iLevel + 1
    local iSchoolBranch = oPlayer:GetSchoolBranch()
    local iPoint = oSk:LearnNeedCost(iLevel)
     if not oPlayer.m_oActiveCtrl:ValidResumeSkillPoint(iSchoolBranch,iPoint) then
        return false
    end
    if iPoint > 0 then
        local sReason = "学习门派主动技能"
        oPlayer.m_oActiveCtrl:ResumeSkillPoint(iSchoolBranch,iPoint,sReason)
    end
    local fCallback = function (mRecord,mData)
        self:LearnCallback(iPid,iSk,iLevel,mData)
    end
    oPlayer.m_oSkillCtrl:LearnSchoolSkill(iSk,iNewLevel,sReason,fCallback)
end

function CSchoolSkillLearn:LearnCallback(iPid,iSk,iLevel,mData)
    if not mData.success then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    oPlayer.m_oSkillMgr:ShareUpdate()
    oPlayer:ActivePropChange()
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30001,1)
    local iNewLevel = oPlayer:GetSkillLevel(iSk)
    LogAnalySkill(oPlayer,1,iSk,iNewLevel,iLevel,{},0,iPoint)
end

function LogAnalySkill(oPlayer,iSkType,iSk,alv,blv,mCost,Coin,Point)
    local mLog = oPlayer:GetPubAnalyData()
    mLog["skill_type"] = iSkType
    mLog["skill_id"] = iSk
    mLog["skill_faction"] = ""
    if iSkType == 1 then
        mLog["skill_faction"] = tostring(oPlayer.m_oBaseCtrl:GetData("school_branch"))
    end
    mLog["skill_before"] = blv
    mLog["skill_after"] = alv
    mLog["consume_detail"] = analy.datajoin(mCost)
    mLog["consume_gold"] = Coin or 0
    mLog["remain_gold"] = oPlayer:Coin()
    mLog["consume_skill_point"] = Point or 0
    mLog["remain_skill_point"] = oPlayer:GetSkillPoint()
    analy.log_data("skillLevelup",mLog)
end
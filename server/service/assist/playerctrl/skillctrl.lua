--import module
local skynet = require "skynet"
local global = require "global"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local loadskill = import(service_path("skill/loadskill"))

local max = math.max
local min = math.min

CSkillCtrl = {}
CSkillCtrl.__index = CSkillCtrl
inherit(CSkillCtrl, datactrl.CDataCtrl)

function CSkillCtrl:New(pid)
    local o = super(CSkillCtrl).New(self, {pid = pid})
    o.m_mList = {}
    return o
end

function CSkillCtrl:Load(mData)
    mData = mData or {}
    local mSkData = mData["skdata"] or {}
    for iSk,data in pairs(mSkData) do
        iSk = tonumber(iSk)
        local oSk = loadskill.LoadSkill(iSk,data)
        self.m_mList[iSk] = oSk
    end
end

function CSkillCtrl:Save()
    local mData = {}
    local mSkData = {}
    for iSk,oSk in pairs(self.m_mList) do
        mSkData[db_key(iSk)] = oSk:Save()
    end
    mData["skdata"] = mSkData
    return mData
end

function CSkillCtrl:Release()
    for _,oSk in pairs(self.m_mList) do
        baseobj_safe_release(oSk)
    end
    self.m_mList = {}
    super(CSkillCtrl).Release(self)
end

function CSkillCtrl:GetSkill(iSk)
    return self.m_mList[iSk]
end

function CSkillCtrl:AddSkill(oSk)
    self:Dirty()
    local iSk = oSk:ID()
    self.m_mList[iSk] = oSk
end

function CSkillCtrl:SkillList()
    return self.m_mList
end

function CSkillCtrl:GetSkillLevel()
    local mLevel = {}
    for iSk,oSk in pairs(self.m_mList) do
        mLevel[iSk] = oSk:Level()
    end
    return mLevel
end

function CSkillCtrl:SetLevel(iSk,iLevel,bNoRefresh)
    self:Dirty()
    local oSk = self.m_mList[iSk]
    if not oSk then
        oSk =  loadskill.NewSkill(iSk)
        self.m_mList[iSk] = oSk
    end
    oSk:SetLevel(iLevel)
    if not bNoRefresh then
        self:GS2CRefreshSkill(oSk)
    end
end

function CSkillCtrl:SetCultivateLevel(iSk, iLevel)
    self:Dirty()

    local oSk = self:GetSkill(iSk)
    if not oSk then
        oSk = loadskill.NewSkill(iSk)
        self:AddSkill(oSk)
    end
    oSk:SetLevel(iLevel)
end

function CSkillCtrl:OnLogin(oPlayer,bReEnter)
    local iSchool = oPlayer:GetSchool()
    local iSchoolBranch = oPlayer:GetSchoolBranch()
    local mSkill = loadskill.GetSchoolSkill(iSchool,iSchoolBranch)
    local mSchoolData = {}
    for _,iSk in ipairs(mSkill) do
        local oSk = self:GetSkill(iSk)
        if oSk then
            table.insert(mSchoolData,oSk:PackNetInfo())
        end
    end
    local mCultivate = loadskill.GetCultivateSkill()
    local mCultivateData = {}
    for _, iSk in ipairs(mCultivate) do
        local oSk = self:GetSkill(iSk)
        if oSk then
            table.insert(mCultivateData, oSk:PackNetInfo())
        end
    end
    local mNet = {}
    mNet["school"] = mSchoolData
    mNet["cultivate"] = mCultivateData
    if oPlayer then
        oPlayer:Send("GS2CLoginSkill",mNet)
    end
    oPlayer:SkillShareUpdate()
end

function CSkillCtrl:OnLogout(oPlayer)
end

function CSkillCtrl:OnDisconnected(oPlayer)
end

function CSkillCtrl:CalApply(oPlayer,bReEnter)
    if not bReEnter then
        local mCultivate = loadskill.GetCultivateSkill()
        for _, iSk in ipairs(mCultivate) do
            local oSk = self:GetSkill(iSk)
            if oSk then
                oSk:SkillEffect(oPlayer)
            end
        end
        local iSchool = oPlayer:GetSchool()
        local iSchoolBranch = oPlayer:GetSchoolBranch()
        local mSchool = loadskill.GetSchoolSkill(iSchool,iSchoolBranch)
        for _,iSk in ipairs(mSchool) do
            local oSk = self:GetSkill(iSk)
            if oSk then
                oSk:SkillEffect(oPlayer)
            end
        end
    end
end

function CSkillCtrl:PackCultivateSkill()
    local mSkill = loadskill.GetCultivateSkill()
    local mLevel = {}
    for _,iSk in pairs(mSkill) do
        local oSk = self:GetSkill(iSk)
        local iLevel = 0
        if oSk then
            iLevel = oSk:Level()
        end
        table.insert(mLevel,iLevel)
    end
    return mLevel
end

function CSkillCtrl:GetSchoolNormalAttackId(oPlayer)
    local iSchool = oPlayer:GetSchool()
    local iSchoolBranch = oPlayer:GetSchoolBranch()
    local mSkill = loadskill.GetSchoolSkill(iSchool,iSchoolBranch)
    for _,iSk in ipairs(mSkill) do
        if iSk % 10 == 1 then
            return iSk
        end
    end
end

function CSkillCtrl:GS2CRefreshSkill(oSk)
    local mNet = {}
    mNet["skill_info"] = oSk:PackNetInfo()
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:Send("GS2CRefreshSkill",mNet)
    end
end

function CSkillCtrl:LogSkill(sType, iSk, iBefore, iAfter, sReason, mArgs)
    local mLog = {
        pid = self:GetInfo("pid"),
        skill_id = iSk,
        before_level = iBefore,
        after_level = iAfter,
        reason = sReason,
    }
    if mArgs then
        table_combine(mLog, mArgs)
    end
    record.user("skill",sType, mLog)
end

function CSkillCtrl:UnDirty()
    super(CSkillCtrl).UnDirty(self)
    for _,oSk in pairs(self.m_mList) do
        if oSk:IsDirty() then
            oSk:UnDirty()
        end
    end
end

function CSkillCtrl:IsDirty()
    local bDirty = super(CSkillCtrl).IsDirty(self)
   if bDirty then
        return true
    end
    for _,oSk in pairs(self.m_mList) do
        if oSk:IsDirty() then
            return true
        end
    end
    return false
end
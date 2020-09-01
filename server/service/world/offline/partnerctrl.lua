--离线伙伴数据
local skynet = require "skynet"
local global = require "global"
local interactive = require "base.interactive"
local extend = require "base/extend"

local defines = import(service_path("offline.defines"))
local CBaseOfflineCtrl = import(service_path("offline.baseofflinectrl")).CBaseOfflineCtrl
local partnerctrl = import(service_path("playerctrl.partnerctrl"))

CPartnerCtrl = {}
CPartnerCtrl.__index = CPartnerCtrl
inherit(CPartnerCtrl, CBaseOfflineCtrl)

function CPartnerCtrl:New(iPid)
    local o = super(CPartnerCtrl).New(self, iPid)
    o.m_sDbFlag = "Partner"
    o.m_lTop10Power = {} --战力前十伙伴
    o.m_ShowPartner = {}
    o.m_mId2Rank = {}
    o.m_lTop4Grade = {}
    o.m_mId2Grade = {}
    return o
end

function CPartnerCtrl:Save()
    local mData = {}

    local lPartner = {}
    for iRank, iParId in ipairs(self.m_lTop10Power) do
        local mInfo = self.m_mId2Rank[iParId]
        if mInfo then
            table.insert(lPartner, mInfo)
        end
    end
    mData.partner_list = lPartner

    local  mShowPartner = {}
    for _,oPartner in ipairs(self.m_ShowPartner)do
        table.insert(mShowPartner,oPartner:Save())
    end
    mData.show_partner = mShowPartner

    local lGradePartner = {}
    for iRank, iParId in ipairs(self.m_lTop4Grade) do
        local mInfo = self.m_mId2Grade[iParId]
        if mInfo then
            table.insert(lGradePartner, mInfo)
        end
    end
    mData.grade_partner = lGradePartner
    return mData
end

function CPartnerCtrl:Load(mData)
    mData = mData or {}

    self.m_mId2Rank = {}
    self.m_lTop10Power = {}
    for iRank, mWarInfo in ipairs(mData.partner_list or {}) do
        self.m_mId2Rank[mWarInfo.parid] = mWarInfo
        self.m_lTop10Power[iRank] = mWarInfo.parid
    end

    local parlist = mData.show_partner or {}
    self.m_ShowPartner  = {}
    for _,mPartner in ipairs(parlist) do
        local oPartner = partnerctrl.NewPartner(self:GetPid(),mPartner)
        table.insert(self.m_ShowPartner,oPartner)
    end

    self.m_mId2Grade = {}
    self.m_lTop10Power = {}
    for iRank, mWarInfo in ipairs(mData.grade_partner or {}) do
        self.m_mId2Grade[mWarInfo.parid] = mWarInfo
        self.m_lTop10Power[iRank] = mWarInfo.parid
    end
end

function CPartnerCtrl:OnLogin(oPlayer, bReEnter)
end

function CPartnerCtrl:OnLogout(oPlayer)
    super(CPartnerCtrl).OnLogout(self, oPlayer)
end

function CPartnerCtrl:IsDirty()
    local bDirty = super(CPartnerCtrl).IsDirty(self)
    if bDirty then
        return true
    end
end

function CPartnerCtrl:UpdateTop10Partner(lPartner)
    self:Dirty()
    lPartner = lPartner or {}
    self.m_lTop10Power = {}
    self.m_mId2Rank = {}
    for iRank, mInfo in ipairs(lPartner) do
        self.m_mId2Rank[mInfo.parid] = mInfo
        self.m_lTop10Power[iRank] = mInfo.parid
    end
    self:OnPartnerPowerChange()
end

function CPartnerCtrl:UpdateTop4GradePartner(lPartner)
    self:Dirty()
    lPartner = lPartner or {}
    self.m_lTop4Grade = {}
    self.m_mId2Grade = {}
    for iRank, mInfo in ipairs(lPartner) do
        self.m_mId2Grade[mInfo.parid] = mInfo
        self.m_lTop4Grade[iRank] = mInfo.parid
    end
end

function CPartnerCtrl:OnPartnerPowerChange()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        global.oRankMgr:PushDataToWarPowerRank(oPlayer)
        oPlayer:OnPartnerPowerChange(self:CountTop4Power())
    end
end

function CPartnerCtrl:RefreshPartner(parlist)
    self:Dirty()
    for _,oPartner in pairs(self.m_ShowPartner) do
        baseobj_safe_release(oPartner)
    end

    self.m_ShowPartner  = {}
    for _,mPartner in ipairs(parlist) do
        local oPartner = partnerctrl.NewPartner(self:GetPid(),mPartner)
        table.insert(self.m_ShowPartner,oPartner)
    end
end

function CPartnerCtrl:GetShowPartner()
    return self.m_ShowPartner
end

function CPartnerCtrl:PackWarInfo(iParId)
    local mWarInfo = {}
    local m = self.m_mId2Rank[iParId]
    if m then
        mWarInfo = table_deep_copy(m)
        mWarInfo.perform = self:GetPerform(mWarInfo.skill)
        mWarInfo.equip = self:PackWarEquip(m.equip)
        mWarInfo.skill = nil
        mWarInfo.pos = nil
    end
    return mWarInfo
end

function CPartnerCtrl:GetPerform(lSkill)
    lSkill = lSkill or {}
    local mPerform = {}
     for _, m in ipairs(lSkill) do
        local iSk, iLevel = table.unpack(m)
        mPerform[iSk] = iLevel
     end
     return mPerform
end

function CPartnerCtrl:PackWarEquip(mEquip)
    local lSid = {}
    for _, m in ipairs(mEquip  or {}) do
        table.insert(lSid, m["data"]["sid"])
    end
    return lSid
end

function CPartnerCtrl:CountTop4Power()
    local iPower = 0
    local iLen = math.min(4, #self.m_lTop10Power)
    for i = 1, iLen do
        local iParId = self.m_lTop10Power[i]
        local mInfo = self.m_mId2Rank[iParId]
        if mInfo then
            iPower = iPower + mInfo.power
        end
    end
    return math.floor(iPower)
end

function CPartnerCtrl:GetPataPtnInfoList(iLimit)
    iLimit = iLimit or 5
    local lPartinfo = {}
    local mExclude = {[1754] = 1, [1755] = 1}
    local iLimit = math.min(#self.m_lTop10Power, iLimit)
    for iRank = 1, iLimit do
        local iParId = self.m_lTop10Power[iRank]
        local mInfo = self.m_mId2Rank[iParId]
        if mInfo then
            local iType = mInfo.type
            if not mExclude[iType] then
                table.insert(lPartinfo, {
                    parid = mInfo.parid,
                    star = mInfo.star,
                    rare = mInfo.rare,
                    grade = mInfo.grade,
                    power = mInfo.power,
                    name = mInfo.name,
                    modeid = mInfo.type,
                    })
            end
        end
    end
    return lPartinfo
end

function CPartnerCtrl:GetPtnCnt()
    return #self.m_lTop10Power
end

function CPartnerCtrl:GetWarInfoByID(iParId)
    return self:PackWarInfo(iParId)
end

function CPartnerCtrl:PackTop4SimpleInfo()
    local mRet = {}
    local iLen = math.min(4, #self.m_lTop10Power)
    for i = 1, iLen do
        local iParId = self.m_lTop10Power[i]
        local mInfo = self.m_mId2Rank[iParId]
        if mInfo then
            table.insert(mRet, {
                ttype = 1,
                name = mInfo.name,
                power = mInfo.power,
                grade = mInfo.grade,
                parsid = mInfo.type,
                model_info = table_deep_copy(mInfo.model_info),
                othername = self:GetPartnerConfigName(mInfo.type)
                })
        end
    end
    return mRet
end

function CPartnerCtrl:GetPartnerConfigName(iPartnerSid)
    local res = require "base.res"
    local mData = res["daobiao"]["partner"]["partner_info"][iPartnerSid]
    assert(mData, string.format("partner info config err:%s,%s", self:GetPid(), iPartnerSid))
    return mData.name
end

function CPartnerCtrl:GetTopGrade(iTop)
    iTop = iTop or 4
    local lGrade = {}
    for iRank, iParId in ipairs(self.m_lTop4Grade) do
        local mInfo = self.m_mId2Grade[iParId]
        table.insert(lGrade, mInfo.grade)
    end

    return lGrade
end
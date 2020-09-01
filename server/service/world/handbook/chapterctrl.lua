local global = require "global"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local loadchapter = import(service_path("handbook.loadchapter"))

function NewChapterCtrl()
    local o = CChapterCtrl:New()
    return o
end

CChapterCtrl = {}
CChapterCtrl.__index = CChapterCtrl
inherit(CChapterCtrl, datactrl.CDataCtrl)

function CChapterCtrl:New()
    local o = super(CChapterCtrl).New(self)
    o.m_mList = {}
    return o
end

function CChapterCtrl:Release()
    for _, oChapter in pairs(self.m_mList) do
        baseobj_safe_release(oChapter)
    end
    self.m_mList = nil
    super(CChapterCtrl).Release(self)
end

function CChapterCtrl:Load(mData)
    local mChapterData = mData or {}
    for sChapterID, data in pairs(mChapterData) do
        local iChapterID = tonumber(sChapterID)
        local oChapter = loadchapter.LoadChapter(iChapterID, data)
        self.m_mList[iChapterID] = oChapter
    end
end

function CChapterCtrl:Save()
    local mChapterData = {}
    for iChapterID, oChapter in pairs(self.m_mList) do
        mChapterData[db_key(iChapterID)]  = oChapter:Save()
    end
    return mChapterData
end

function CChapterCtrl:OnLogin(oPlayer, bReEnter)
    for _, oChapter in pairs(self.m_mList) do
        oChapter:PreCheck()
    end
end

function CChapterCtrl:UnDirty()
    super(CChapterCtrl).UnDirty(self)
    for _, oChapter in pairs(self.m_mList) do
        oChapter:UnDirty()
    end
end

function CChapterCtrl:IsDirty()
    if super(CChapterCtrl).IsDirty(self) then
        return true
    end
    for _, oChapter in pairs(self.m_mList) do
        if oChapter:IsDirty() then
            return true
        end
    end
    return false
end

function CChapterCtrl:GetList()
    return self.m_mList
end

function CChapterCtrl:GetChapter(iChapterID)
    return self.m_mList[iChapterID]
end

function CChapterCtrl:AddChapter(iChapterID)
    self:Dirty()
    local oChapter = loadchapter.CreateChapter(iChapterID)
    self.m_mList[iChapterID] = oChapter
    oChapter:PreCheck()
    return oChapter
end

function CChapterCtrl:AddCondition(iChapterID, iConditionID)
    local oChapter = self:GetChapter(iChapterID)
    if not oChapter then
        oChapter = self:AddChapter(iChapterID)
    end
    oChapter:AddCondition(iConditionID)
    return oChapter
end

function CChapterCtrl:HasCondition(iChapterID, iConditionID)
    local oChapter = self:GetChapter(iChapterID)
    if not oChapter then
        oChapter = self:AddChapter(iChapterID)
    end
    return oChapter:HasCondition(iConditionID)
end

function CChapterCtrl:IsUnlock(iChapterID)
    local oChapter = self:GetChapter(iChapterID)
    if oChapter then
        return oChapter:IsUnlock()
    end
    return false
end

function CChapterCtrl:ConditionDone(iChapterID)
    local oChapter = self:GetChapter(iChapterID)
    if oChapter then
        return oChapter:IsConditionDone()
    end
    return false
end

function CChapterCtrl:PackChapterInfo(iChapterID)
    local oChapter = self:GetChapter(iChapterID)
    if not oChapter then
        oChapter = self:AddChapter(iChapterID)
    end
    return oChapter:PackNetInfo()
end

function CChapterCtrl:TestCmd(oPlayer, sCmd, mData, sReason)
    
end
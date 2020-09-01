--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local playersend = require "base.playersend"

function NewRankMgr(...)
    local o = CRankMgr:New(...)
    return o
end

CRankMgr = {}
CRankMgr.__index = CRankMgr
inherit(CRankMgr, logic_base_cls())


function CRankMgr:New()
    local o = super(CRankMgr).New(self)
    o.m_mRankObj = {}
    o.m_mName2RankObj = {}
    o.m_mUpvote = {}
    return o
end

function CRankMgr:GetRankObj(idx)
    if self.m_mRankObj[idx] then
        return self.m_mRankObj[idx]
    end

    local sName = self:GetRankName(idx)
    if not sName then return nil end

    local sPath = self:GetRankPath(sName)
    local sModule = import(service_path(sPath))
    local oRank = sModule.NewRankObj(idx, sName)
    oRank:LoadFinish()
    oRank:Schedule()
    oRank:ConfigSaveFunc()
    self.m_mRankObj[idx] = oRank
    self.m_mName2RankObj[sName] = oRank
    return oRank
end

function CRankMgr:GetRankObjByName(sName)
    return self.m_mName2RankObj[sName]
end

function CRankMgr:GetRankName(idx)
    local res = require "base.res"
    for id, mInfo in ipairs(res["daobiao"]["rank"]) do
        if mInfo.id == idx then
            return mInfo.file
        end
    end
end

function CRankMgr:GetAllRankInfo()
    local res = require "base.res"
    return res["daobiao"]["rank"]
end

function CRankMgr:GetRankIdx(sName)
    local res = require "base.res"
    for id, mInfo in ipairs(res["daobiao"]["rank"]) do
        if mInfo.file == sName then
            return mInfo.id
        end
    end
end

function CRankMgr:NewHour(iWeekDay, iHour)
    for idx, oRank in pairs(self.m_mRankObj) do
        safe_call(oRank.NewHour,oRank,iWeekDay,iHour)
    end
end

function CRankMgr:OnUpdateName(iKey, sName)
    local sKey = tostring(iKey)
    local bUpdate = false
    for idx, oRank in pairs(self.m_mRankObj) do
        if oRank:OnUpdateName(sKey, sName) then
            self:ClearClientRankData(oRank.m_iRankIndex)
        end
    end
end

function CRankMgr:OnUpdatePosition(iKey, iPosition)
    local sKey = tostring(iKey)
    local bUpdate = false
    for idx, oRank in pairs(self.m_mRankObj) do
        bUpdate = oRank:OnUpdatePosition(sKey, iPosition)
        if bUpdate then
            self:ClearClientRankData(idx)
        end
    end
end

function CRankMgr:DeleteOrg(iOrgId)
    local sKey = tostring(iKey)
    for idx, oRank in pairs(self.m_mRankObj) do
        if oRank:GetOrgUnit(iOrgId) then
            oRank:RemoveOrgUint(iOrgId)
            self:ClearClientRankData(idx)
        end
    end
    for idx, oRank in pairs(self.m_mRankObj) do
        if oRank:IsOrgRank() then
            oRank:RemoveDataFromRank({key=iOrgId})
        end
    end
end

function CRankMgr:OnLogin(iPid, bReEnter)
    for idx, oRank in pairs(self.m_mRankObj) do
        oRank:OnLogin(iPid, bReEnter)
    end
end

function CRankMgr:OnLogout(iPid)
    for idx, oRank in pairs(self.m_mRankObj) do
        oRank:OnLogout(iPid)
    end
end

function CRankMgr:GetRankPath(sName)
    local sPath = "common." .. sName
    local sFile = string.gsub(service_path(sPath), "%.", "/") .. ".lua"
    -- assert (exist_file(sFile), string.format("doesn't exist rank:%s", sFile))
    if exist_file(sFile) then
        return sPath
    end
end

function CRankMgr:LoadAllRank()
    local mAllInfo = self:GetAllRankInfo()
    for id, mInfo in pairs(mAllInfo) do
        local idx, sName = mInfo.id, mInfo.file
        local sPath = self:GetRankPath(sName)
        if sPath then
            local sModule = import(service_path(sPath))
            local oRank = sModule.NewRankObj(idx, sName)
            oRank:LoadDb()
            self.m_mRankObj[idx] = oRank
            self.m_mName2RankObj[sName] = oRank
        end
    end
end

function CRankMgr:CloseGS()
    save_all()
end

function CRankMgr:ClearClientRankData(idx)
    local gamedefines = import(lualib_path("public.gamedefines"))

    local mData = {
        message = "GS2CClearAllRankData",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = {idx = idx},
        exclude = mExclude,
    }
    interactive.Send(".broadcast", "channel", "SendChannel", mData)
end

function CRankMgr:OnOrgLeaderChange(iOrgId, mLeader)
    local sKey = tostring(iOrgId)
    for idx, oRank in pairs(self.m_mRankObj) do
        if oRank:OnOrgLeaderChange(sKey, mLeader) then
            self:ClearClientRankData(idx)
        end
    end

end

function CRankMgr:OnUpdateOrgInfo(iOrgId,mInfo)
    for idx, oRank in pairs(self.m_mRankObj) do
        if oRank:IsOrgRank() then
            if oRank:OnUpdateOrgInfo(iOrgId,mInfo) then
                self:ClearClientRankData(idx)
            end
        end
    end
end

function CRankMgr:RushRankEnd(lRank)
    local mRank = {}
    for _, idx in ipairs(lRank) do
        local oRankObj = self:GetRankObj(idx)
        if oRankObj then
            oRankObj:DoRushRankEnd()
        end
    end
    self:DelTimeCb("RushRankEnd")
    self:AddTimeCb("RushRankEnd", 10 * 60 * 1000,function()
        self:_RushRankEnd(lRank)
    end)
end

function CRankMgr:_RushRankEnd(lRank)
    self:DelTimeCb("RushRankEnd")
    local mRank = {}
    for _, idx in ipairs(lRank) do
        local oRankObj = self:GetRankObj(idx)
        if oRankObj then
            mRank[idx] = oRankObj:PackRushRankInfo()
        end
    end
    if next(mRank) then
        interactive.Send(".world", "rank", "SendRushRankReward", {rank = mRank})
    end
end

function CRankMgr:CheckRushRankEnd(lEndRank)
end

function CRankMgr:QueryRankBack(lRank)
    lRank = lRank or {}
    if #lRank <= 0 then
        return
    end
    self:DelTimeCb("_QueryRankBack")
    self:AddTimeCb("_QueryRankBack", 10 * 1000,function()
        self:_QueryRankBack(lRank)
    end)
end

function CRankMgr:_QueryRankBack(lRank)
    local lNet = {}
    self:DelTimeCb("_QueryRankBack")
    for _, idx in ipairs(lRank) do
        local oRankObj = self:GetRankObj(idx)
        if oRankObj then
            list_combine(lNet, oRankObj:QueryRankBack())
        end
    end
    if next(lNet) then
        interactive.Send(".world", "rank", "SendRankBack", {rank = lNet})
    end
end

function CRankMgr:Send(iPid, sMessage, mData)
    playersend.Send(iPid,sMessage,mData)
end
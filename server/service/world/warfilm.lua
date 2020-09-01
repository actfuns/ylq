--战斗录像
local global = require "global"
local extend = require "base.extend"
local res = require "base.res"

local interactive = require "base.interactive"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))



function NewWarFilmMgr(...)
    return CWarFilmMgr:New(...)
end

CWarFilmMgr = {}
CWarFilmMgr.__index = CWarFilmMgr
inherit(CWarFilmMgr,logic_base_cls())

function CWarFilmMgr:New()
    local o = super(CWarFilmMgr).New(self)
    o.m_mList = {}
    o.m_Version = 2
    return o
end

function CWarFilmMgr:Schedule()
    local f1
    f1 = function ()
        self:DelTimeCb("_CheckSave")
        self:AddTimeCb("_CheckSave",5 * 60 * 1000,f1)
        self:_CheckSave()
    end
    f1()
    local f2
    f2 = function ()
        self:DelTimeCb("_CheckClean")
        self:AddTimeCb("_CheckClean",5 * 60 * 1000,f2)
        self:_CheckClean()
    end
    f2()
end

function CWarFilmMgr:_CheckSave()
    local iMaxCnt = 50
    local iCnt = 0
    for _,oFilm in pairs(self.m_mList) do
        if oFilm:IsDirty() and iCnt < iMaxCnt then
            iCnt = iCnt + 1
            oFilm:NowSave()
        end
    end
end

function CWarFilmMgr:_CheckClean()
    local mClean = {}
    for sFilmId,oFilm in pairs(self.m_mList) do
        if not oFilm:IsActive() then
            mClean[sFilmId] = true
        end
    end
    for sFilmId,_ in pairs(mClean) do
        self:RemoveFilm(sFilmId)
    end
end

function CWarFilmMgr:OnCloseGS()
    for _,oFilm in pairs(self.m_mList) do
        if oFilm:IsDirty() then
            oFilm:NowSave()
        end
    end
end

function CWarFilmMgr:NewWarFilm(sFilmId)
    local oFilm = CFilm:New(sFilmId)
    self.m_mList[sFilmId] = oFilm
    return oFilm
end

function CWarFilmMgr:AddWarFilm(mFilmData,warArg)
    local oWorldMgr = global.oWorldMgr
    local sFilmId = oWorldMgr:DispatchWarFilmId()
    local oFilm = CFilm:New(sFilmId,mFilmData)
    oFilm:SetVersion(self.m_Version)
    oFilm:SetWarArg(warArg)
    oFilm:NowSave()
    self.m_mList[sFilmId] = oFilm
    return oFilm
end

function CWarFilmMgr:GetFilm(sFilmId)
    return self.m_mList[sFilmId]
end

function CWarFilmMgr:RemoveFilm(sFilmId)
    local oFilm = self.m_mList[sFilmId]
    self.m_mList[sFilmId] = nil
    if oFilm then
        baseobj_delay_release(oFilm)
    end
end

function CWarFilmMgr:StartFilm(oPlayer,sFilmId,mArgs)
    local iPid = oPlayer:GetPid()
    if oPlayer.m_oActiveCtrl:GetNowWar() then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oFilm = self.m_mList[sFilmId]
    if not oFilm then
        local fCallback = function (oFilm)
            oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if not oPlayer then
                return
            end
            if not oFilm then
                oNotifyMgr.Notify(oPlayer:GetPid(),"没有该录像")
                return
            end
            if oFilm.m_Version ~= self.m_Version then
                oNotifyMgr.Notify(iPid,"录像版本过低")
                return
            end
            oFilm:StartFilm(oPlayer,sFilmId,mArgs)
        end
        self:LoadFilm(sFilmId,fCallback)
    else
            if oFilm.m_Version ~= self.m_Version then
                oNotifyMgr.Notify(iPid,"录像版本过低")
                return
            end
        oFilm:StartFilm(oPlayer,sFilmId,mArgs)
    end
end

function CWarFilmMgr:LoadFilm(sFilmId,fCallback)
    local o = self:GetFilm(sFilmId)
    if o then
        if o:IsLoading() then
            o:AddWaitFunc(fCallback)
        else
            fCallback(o)
            o:SetLastTime()
        end
    else
        o = self:NewWarFilm(sFilmId)
        o:AddWaitFunc(fCallback)
        local mData = {
            film_id = sFilmId
        }
        local mArgs = {
            module = "warfilmdb",
            cmd = "LoadWarFilm",
            data = mData,
        }
        gamedb.LoadDb("warfilm","common","LoadDb", mArgs, function (mRecord,mData)
            local o = self:GetFilm(sFilmId)
            assert(o and o:IsLoading(), string.format("LoadWarFilm fail %s",sFilmId))
            if not mData.success then
                o:LoadFinish()
                o:WakeUpFailFunc()
                self:RemoveFilm(sFilmId)
            else
                local m = mData.data
                o:Load(m)
                o:LoadFinish()
                o:WakeUpFunc()
            end
        end)
    end
end

CFilm = {}
CFilm.__index = CFilm
inherit(CFilm,datactrl.CDataCtrl)

function CFilm:New(sWarFilmId,mFilmData)
    local o = super(CFilm).New(self)
    o.m_iLastTime = get_time()
    o.m_bLoading = true
    o.m_lWaitFuncList = {}
    o.m_Version = 1
    o.m_sFilmId = sWarFilmId
    o.m_mData = mFilmData
    o.m_WarArg = {}
    return o
end

function CFilm:Save()
    local mData = {}
    mData.film_id = self.m_sFilmId or 1
    mData.version = self.m_Version
    mData.film_data = table_deep_copy(self.m_mData) or {}
    mData.war_arg = self.m_WarArg or {}
    return mData
end

function CFilm:Load(mData)
    mData = mData or {}
    self.m_sFilmId = mData.film_id
    self.m_mData = mData.film_data
    self.m_Version = mData.version or 1
    self.m_WarArg = mData.war_arg or {}
end

function CFilm:SetVersion(iVer)
    self.m_Version = iVer
    self:Dirty()
end

function CFilm:SetWarArg(mArg)
    self.m_WarArg = mArg
end

function CFilm:NowSave()
    local mData = {
        film_id = self:GetFilmId(),
        data = self:Save()
    }
    gamedb.SaveDb("warfilm","common", "SaveDb", {module = "warfilmdb",cmd="SaveWarFilm",data = mData})
    self:UnDirty()
end

function CFilm:IsLoading()
    return self.m_bLoading
end

function CFilm:LoadFinish()
    self.m_bLoading = false
end

function CFilm:AddWaitFunc(fCallback)
    table.insert(self.m_lWaitFuncList, fCallback)
end

function CFilm:WakeUpFunc()
    for _, fCallback in ipairs(self.m_lWaitFuncList) do
        fCallback(self)
    end
    self:SetLastTime()
end

function CFilm:WakeUpFailFunc()
    for _, fCallback in ipairs(self.m_lWaitFuncList) do
        fCallback(nil)
    end
end

function CFilm:SetLastTime()
    self.m_iLastTime = get_time()
end

function CFilm:GetLastTime()
    return self.m_iLastTime
end

function CFilm:IsActive()
    local iNowTime = get_time()
    if iNowTime - self:GetLastTime() <= 5 * 60 then
        return true
    end
    local iWarId = self:GetInfo("war_id")
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if not oWar then
        return false
    end
    return false
end

function CFilm:GetFilmId()
    return self.m_sFilmId
end

function CFilm:StartFilm(oPlayer,iFilm,mArg)
    mArg = mArg or {}
    if oPlayer.m_oActiveCtrl:GetNowWar() then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    if oPlayer:HasTeam() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"组队下不能观看录像")
        return
    end
    local oWarMgr = global.oWarMgr
    local iPid = oPlayer:GetPid()
    local mArgs = {
        remote_war_type = "warfilm",
        remote_args = self.m_mData,
        war_film = true,
        war_type = self.m_WarArg["war_type"],
        lineup = self.m_WarArg["lineup"] or 0,
    }
    local oWar = oWarMgr:CreateWar(mArgs)
    oWar:SetData("war_film_id",self.m_mData["war_id"])

    local iWarId = oWar:GetWarId()
    self:SetInfo("war_id",iWarId)

    local mArgs = {
        observer_view = mArg["observer_view"] or 1,
        war_film = 1,
        war_id = self.m_mData["war_id"],
        flim_ver = self.m_Version,
    }
    oWar:EnterObserver(oPlayer,mArgs)
    local sFilmId = self:GetFilmId()
    local oWarFilmMgr = global.oWarFilmMgr
    local fWarEndCallback = function (mArgs)
        local oFilm = oWarFilmMgr:GetFilm(sFilmId)
        if oFilm then
            oFilm:WarEndCallback(iPid,mArgs)
        end
    end
    oWarMgr:SetWarEndCallback(oWar:GetWarId(),fWarEndCallback)
    oWarMgr:StartWar(oWar:GetWarId())
end

function CFilm:WarEndCallback(oWar,iPid,mArgs)
end
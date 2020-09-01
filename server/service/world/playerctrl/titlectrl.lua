--import module

local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local titledefines = import(service_path("title.titledefines"))
local loadtitle = import(service_path("title.loadtitle"))


CTitleCtrl = {}
CTitleCtrl.__index = CTitleCtrl
inherit(CTitleCtrl, datactrl.CDataCtrl)

function CTitleCtrl:New(iPid)
    local o = super(CTitleCtrl).New(self,{pid=iPid})
    o.m_mTitles = {}
    return o
end

function CTitleCtrl:GetPid()
    return self:GetInfo("pid")
end

function CTitleCtrl:Save()
    local mData = {}
    local mTitleData = {}
    for _,oTitle in pairs(self.m_mTitles) do
        table.insert(mTitleData, oTitle:Save())
    end

    mData.title_list = mTitleData
    mData.arena_tid = self:GetData("arena_tid")
    mData.top_tid = self:GetData("top_tid")
    mData.bot_tid = self:GetData("bot_tid")
    return mData
end

function CTitleCtrl:Load(mData)
    if not mData then return end

    for _,m in ipairs(mData.title_list or {}) do
        if loadtitle.HasTitle(m.titleid) then
            local oTitle = loadtitle.NewTitle(self:GetPid(), m.titleid, m.create_time)
            oTitle:Load(m)
            self.m_mTitles[m.titleid] = oTitle
        end
    end
    if mData.arena_tid and loadtitle.HasTitle(mData.arena_tid) then
        self:SetData("arena_tid", mData.arena_tid)
    end
    if mData.top_tid and loadtitle.HasTitle(mData.top_tid) then
        self:SetData("top_tid", mData.top_tid)
    end
    if mData.bot_tid and loadtitle.HasTitle(mData.bot_tid) then
        self:SetData("bot_tid", mData.bot_tid)
    end
end

function CTitleCtrl:Release()
    for _,oTitle in pairs(self.m_mTitles) do
        baseobj_safe_release(oTitle)
    end
    self.m_mTitles = {}
    super(CTitleCtrl).Release(self)
end

function CTitleCtrl:ValidAdd(oPlayer,iTid)
    if iTid == 1001 then
        local mData = oPlayer.m_oBaseCtrl:GetData("ArenaData",{})
        if table_count(mData) <= 0 then
            return false
        end
    end
    return true
end

function CTitleCtrl:AddTitle(oPlayer, iTid, ... )
    if not self:ValidAdd(oPlayer,iTid) then
        return
    end
    local oOldTitle = self:GetTitleByTid(iTid)
    if oOldTitle then
        return
    end

    local oTitle = loadtitle.NewTitle(self:GetPid(), iTid, ... )
    if oTitle:IsExpire() then
        return
    end
    self:Dirty()

    self.m_mTitles[iTid] = oTitle
    local iOldTid
    local iShowType = oTitle:GetShowType()
    local oUseTitle
    if iShowType == 1 then
        oUseTitle = self:GetTitleByTid(self:GetData("top_tid"))
    elseif iShowType == 2 then
        oUseTitle = self:GetTitleByTid(self:GetData("arena_tid"))
    elseif iShowType == 3 then
        oUseTitle = self:GetTitleByTid(self:GetData("bot_tid"))
    end
    if not oUseTitle then
       self:UseTitle(oPlayer, iTid)
    elseif  oTitle:GetGroup() == oUseTitle:GetGroup() and oTitle:GetShow() > oUseTitle:GetShow() then
        self:UseTitle(oPlayer, iTid)
    end
    oPlayer:Send("GS2CAddTitleInfo", {info=oTitle:PackTitleInfo()})
    record.user("title","add",{pid=self:GetPid(),tid=iTid})
    self:TipEarnTitle(oPlayer,oTitle)
end

function CTitleCtrl:TipEarnTitle(oPlayer,oTitle)
    local mConfigData = oTitle:GetTitleData()
    local sDesc = mConfigData["desc"] or ""
    local sMsg = "获得称号#O["..oTitle:GetName().."]#n：\n"..sDesc
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),{"GS2CConsumeMsg"},sMsg,{})
end

function CTitleCtrl:RemoveTitles(oPlayer, lTitID)
    local mTid = self:GetUseTidList()
    for _,iTid in pairs(mTid) do
        if table_in_list(lTitID, iTid) then
            self:UnUseTitle(oPlayer,iTid)
        end
    end

    for _,i in ipairs(lTitID) do
        local oTitle = self.m_mTitles[i]
        if oTitle then
            baseobj_safe_release(oTitle)
            self.m_mTitles[i] = nil
            self:Dirty()
            record.user("title","rm",{pid=self:GetPid(),tid=i})
        end
    end
    if #lTitID > 0 then
        oPlayer:Send("GS2CRemoveTitles", {tidlist=lTitID})
    end
end

function CTitleCtrl:SyncTitleName(oPlayer, iTid, name)
     local oTitle = self:GetTitleByTid(iTid)
     if not oTitle then return end

    self:Dirty()
    oTitle:SetName(name)
    oPlayer:Send("GS2CUpdateTitleInfo", {info=oTitle:PackTitleInfo()})
 end

function CTitleCtrl:GetUseTidList()
    local mAttr = {"arena_tid","top_tid","bot_tid"}
    local list = {}
    for _,sAttr in pairs(mAttr) do
        local value = self:GetData(sAttr)
        if value and value ~= 0 then
            table.insert(list,value)
        end
    end
    return list
end

function CTitleCtrl:GetTitleByTid(iTid)
    return self.m_mTitles[iTid]
end

function CTitleCtrl:GetTitleInfo()
    local infos = {}
    local mTid = self:GetUseTidList()
    for _,iTid in pairs(mTid) do
        local oTitle = self:GetTitleByTid(iTid)
        if oTitle then
            table.insert(infos,oTitle:GetTitleInfo())
        end
    end
    return infos
end

function CTitleCtrl:UseTitle(oPlayer, iTid)
    local oTitle = self:GetTitleByTid(iTid)
    if not oTitle then return end
    if oTitle:IsPartnerTitle() then
        return
    end
    local iShowType = oTitle:GetShowType()
    if iShowType == 1 then
        self:SetData("top_tid", iTid)
    elseif iShowType == 2 then
        self:SetData("arena_tid", iTid)
    elseif iShowType == 3 then
        self:SetData("bot_tid", iTid)
    end
    oTitle:SetUseTime()

    oPlayer:PropChange("title_info")

    oPlayer:SyncSceneInfo({title_info=oPlayer:PackTitleInfo()})
    self:Dirty()
end

function CTitleCtrl:UnUseTitle(oPlayer,iTid)
    local oTitle = self:GetTitleByTid(iTid)
    if not oTitle then return end
    local iShowType = oTitle:GetShowType()
    if iShowType == 1 then
        self:SetData("top_tid", 0)
    elseif iShowType == 2 then
        self:SetData("arena_tid", 0)
    elseif iShowType == 3 then
        self:SetData("bot_tid", 0)
    end
    oPlayer:PropChange("title_info")
    oPlayer:SyncSceneInfo({title_info=oPlayer:PackTitleInfo()})
    self:Dirty()
end

function CTitleCtrl:OnLogin(oPlayer, bReEnter)
end

function CTitleCtrl:OnLogout(oPlayer)
end

function CTitleCtrl:OnDisconnected(oPlayer)
end

function CTitleCtrl:UnDirty()
    super(CTitleCtrl).UnDirty(self)
    for _, oTitle in pairs(self.m_mTitles) do
        if oTitle:IsDirty() then
            oTitle:UnDirty()
        end
    end
end

function CTitleCtrl:IsDirty()
    local bDirty = super(CTitleCtrl).IsDirty(self)
    if bDirty then return true end

    for _,oTitle in pairs(self.m_mTitles) do
        if oTitle:IsDirty() then return true end
    end
    return false
end

function CTitleCtrl:BackEndData()
    local sTmp
    local mUseTidList = self:GetUseTidList()
    for _,iTid in pairs(mUseTidList) do
        local oTitle = self:GetTitleByTid(iTid)
        sTmp = sTmp and (sTmp..",") or ""
        sTmp = sTmp .. oTitle:GetName()
    end
    return sTmp
end

function CTitleCtrl:RemoveTitlesByKey(oPlayer,sKey)
    local lTitID = {}
    for iTid,oTitle in pairs(self.m_mTitles) do
        if oTitle:GetKey() == sKey then
            table.insert(lTitID,iTid)
        end
    end
    self:RemoveTitles(oPlayer,lTitID)
end
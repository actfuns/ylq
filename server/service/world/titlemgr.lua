local global = require "global"
local interactive = require "base.interactive"
local extend = require "base.extend"
local res = require "base.res"
local colorstring = require "public.colorstring"

local titledefines = import(service_path("title.titledefines"))
local loadtitle = import(service_path("title.loadtitle"))

function NewTitleMgr(...)
    return CTitleMgr:New(...)
end

CTitleMgr = {}
CTitleMgr.__index = CTitleMgr
inherit(CTitleMgr,logic_base_cls())

function CTitleMgr:New()
    local o = super(CTitleMgr).New(self)
    o.m_TypeTidList = {}
    return o
end

function CTitleMgr:AddTitle(iPid, iTid, ... )
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:AddTitle(iTid, get_time(), ... )
    else
        local oPubMgr = global.oPubMgr
        oPubMgr:OnlineExecute(iPid, "AddTitle", {iTid, get_time(), ... })
    end
end

function CTitleMgr:CheckAdjust(iPid, iTid, ...)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:CheckTitleAdjust(iTid, ...)
    else
        local oPubMgr = global.oPubMgr
        oPubMgr:OnlineExecute(iPid, "CheckTitleAdjust", {iTid,...})
    end
end

function CTitleMgr:RemoveOneTitle(iPid, iTid)
    self:RemoveTitles({iTid})
end

function CTitleMgr:RemoveTitles(iPid, lTids)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:RemoveTitles(lTids)
    else
        local oPubMgr = global.oPubMgr
        oPubMgr:OnlineExecute(iPid, "RemoveTitles", {lTids})
    end
end

function CTitleMgr:SyncTitleName(iPid, iTid, name)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:SyncTitleName(iTid, name)
    else
        local oPubMgr = global.oPubMgr
        oPubMgr:OnlineExecute(iPid, "SyncTitleName", {iTid, name})
    end
end

function CTitleMgr:UseTitle(oPlayer, iTid)
    oPlayer.m_oTitleCtrl:UseTitle(oPlayer, iTid)
end

function CTitleMgr:UnUseTitle(oPlayer,iTid)
    oPlayer.m_oTitleCtrl:UnUseTitle(oPlayer,iTid)
end

function CTitleMgr:GetTitleText(iText, m)
    local sText = colorstring.GetTextData(iText, {"title"})
    if sText and m then
        sText = colorstring.FormatColorString(sText, m)
    end
    return sText
end

function CTitleMgr:GetTitleDataByTid(iTid)
    return loadtitle.GetTitleDataByTid(iTid)
end

function CTitleMgr:OnLogin(oPlayer,bReEnter)

end

function CTitleMgr:OpenTitleListUI(oPlayer)
    local tTidList = table_key_list(res["daobiao"]["title"]["title"])
    local mNet = {}
    local iPid = oPlayer:GetPid()
    for _,iTid in pairs(tTidList) do
        local oTitle = oPlayer.m_oTitleCtrl:GetTitleByTid(iTid)
        if oTitle then
            table.insert(mNet, oTitle:PackTitleInfo())
        else
            local mData = res["daobiao"]["title"]["title"][iTid]
            local mInfo = {tid=iTid,name=mData.name,create_time=0,left_time=0,progress=self:CalTitleProgress(iPid,iTid)}
            table.insert(mNet, mInfo)
        end
    end
    oPlayer:Send("GS2CTitleInfoList", {infos=mNet})
end

function CTitleMgr:CalTitleProgress(iPid,iTid)
    local mData = res["daobiao"]["title"]["title"][iTid]
    local iType = mData["condition_type"]
    local value = mData["other_value"]
    local oWorldMgr = global.oWorldMgr
    if iType == titledefines.TITLE_CONDITION_TYPE.TITLE_ARENA then
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oPlayer then
            return 0
        end
        local mData = oPlayer.m_oBaseCtrl:GetData("ArenaData",{})
        if table_count(mData) <= 0 then
            return 0
        end
        return oPlayer:ArenaScore()
    end
    return 0
end

function CTitleMgr:ForceAddTitle(iPid,iTid)
    local mData = res["daobiao"]["title"]["title"][iTid]
    local name = mData["name"]
    self:AddTitle(iPid, iTid, name)
end

function CTitleMgr:CheckTitleCondition(iPid,iTid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer and oPlayer.m_oTitleCtrl:GetTitleByTid(iTid) then
        return
    end
    local mData = res["daobiao"]["title"]["title"][iTid]
    local value = mData["condition_value"]
    local name = mData["name"]
    local progress = self:CalTitleProgress(iPid,iTid)
    if progress >= value then
        self:AddTitle(iPid, iTid, name)
    elseif oPlayer then
        oPlayer:Send("GS2CUpdateTitleInfo", {
                info={
                    tid=iTid,name=name,create_time=0,
                    left_time=0,progress=progress
                }
            }
        )
    end
end

function CTitleMgr:GetTidListByType(iType)
    if not self.m_TypeTidList[iType] then
        for iTid,info in pairs(res["daobiao"]["title"]["title"]) do
            local cType = info.condition_type
            self.m_TypeTidList[cType] = self.m_TypeTidList[cType] or {}
            table.insert(self.m_TypeTidList[cType],iTid)
        end
    end
    return self.m_TypeTidList[iType] or {}
end

function CTitleMgr:CheckTitleByType(iPid,sType)
    local iType = titledefines.TITLE_NAME_TYPE[sType]
    local TidList = self:GetTidListByType(iType)
    for _,iTid in pairs(TidList) do
        self:CheckTitleCondition(iPid,iTid)
    end
end

function CTitleMgr:RemoveTitlesByKey(iPid,sKey)
    local lTitID = {}
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:RemoveTitlesByKey(sKey)
    else
        local oPubMgr = global.oPubMgr
        oPubMgr:OnlineExecute(iPid, "RemoveTitlesByKey", {sKey})
    end
end
local global = require "global"
local extend = require "base.extend"

local datactrl = import(lualib_path("public.datactrl"))
local mailobj = import(service_path("mail.mailobj"))
local loaditem = import(service_path("item.loaditem"))
local loadpartner = import(service_path("partner/loadpartner"))

function NewSysMailCache(...)
    return CSysMailCache:New(...)
end

CSysMailCache = {}
CSysMailCache.__index = CSysMailCache
inherit(CSysMailCache, datactrl.CDataCtrl)

function CSysMailCache:New()
    local o = super(CSysMailCache).New(self)
    o.m_mReadyMails = {}
    o.m_mSysMails = {}
    o:SetData("version", 0)
    return o
end

function CSysMailCache:Load(mData)
    if not mData then return end

    self:SetData("version", mData.version or 0)
    for sMailId, info in pairs(mData.smails or {}) do
        local iMail = tonumber(sMailId)
        local oMail = NewMailCacheObj(iMail)
        oMail:Load(info)
        if not oMail:IsExpire() then
            self.m_mSysMails[iMail] = oMail
        else
            baseobj_delay_release(oMail)
        end
    end
    for _,info in pairs(mData.rmails or {}) do
        local oMail = NewMailCacheObj()
        oMail:Load(info)
        if not oMail:IsExpire() then
            table.insert(self.m_mReadyMails,oMail)
        else
            baseobj_delay_release(oMail)
        end
    end
end

function CSysMailCache:Save()
    local mData = {}
    mData.version = self:GetData("version")
    local mMails = {}
    for iMail, oMail in pairs(self.m_mSysMails) do
        mMails[db_key(iMail)] = oMail:Save()
    end
    mData.smails = mMails
    local mRMails = {}
    for iMail, oMail in pairs(self.m_mReadyMails) do
        mRMails[db_key(iMail)] = oMail:Save()
    end
    mData.rmails = mRMails
    return mData
end

function CSysMailCache:MergeFrom(mData)
    self:Dirty()
    self:SetData("version", math.max(self:GetData("version"), mData.version))
    self.m_mSysMails = {}
    return true
end

function CSysMailCache:GetNewVersion()
    local iVer = self:GetData("version", 0) + 1
    self:SetData("version", iVer)
    return iVer
end

function CSysMailCache:CheckSysValid()
    local lVersion = {}
    for iVer, oMail in pairs(self.m_mSysMails) do
        if oMail:IsExpire() then
            table.insert(lVersion, iVer)
        end
    end
    if #lVersion <= 0 then return end

    self:Dirty()
    for _, iVer in pairs(lVersion) do
        local oMail = self.m_mSysMails[iVer]
        self.m_mSysMails[iVer] = nil
        baseobj_delay_release(oMail)
    end
end

function CSysMailCache:CreateMailCacheObj(iVer, mData)
    local oMail = NewMailCacheObj(iVer)
    oMail:Create(mData)
    return oMail
end

function CSysMailCache:AddSysMail(mData)
    self:Dirty()
    local iVer = self:GetNewVersion()
    local oMail = self:CreateMailCacheObj(iVer, mData)
    self.m_mSysMails[iVer] = oMail
end

function CSysMailCache:LoginCheckSysMail(oPlayer)
    local oMailBox = oPlayer:GetMailBox()
    local iSysVersion = self:GetData("version",0)
    local iCurVersion = oMailBox:GetSysVersion()

    if iCurVersion >= iSysVersion then return end
    self:CheckSysValid()

    oMailBox:SetSysVersion(iSysVersion)
    for i = iCurVersion+1, iSysVersion do
        local oMail = self.m_mSysMails[i]
        if oMail and oMail:IsValid(oPlayer) then
            oMail:SendSysMail(oPlayer:GetPid())
        end
    end
end

function CSysMailCache:CheckItemAndPartner(mData)
    local mItem = mData.items or {}
    for _, info in ipairs(mItem) do
        loaditem.GetItem(info.sid)
    end
    local mPartner = mData.partner
    for _,info in ipairs(mPartner) do
        local sid = tonumber(info.sid) or string.match(info.sid,"(%d+)(.+)")
        sid = tonumber(sid)
        assert(sid, string.format("addreadymail partner err"))
        local oPartner = loadpartner.GetPartnerData(sid)
        assert(oPartner, string.format("addreadymail partner sid err"))
    end
end

function CSysMailCache:AddReadyMail(mData)
    self:Dirty()
    self:CheckItemAndPartner(mData)
    local oMail = self:CreateMailCacheObj(nil, mData)
    table.insert(self.m_mReadyMails,oMail)
end

function CSysMailCache:CheckReadyChange()
    self:Dirty()
    local mSend = {}
    for iNo=#self.m_mReadyMails,1,-1 do
        local oMail = self.m_mReadyMails[iNo]
        if oMail and oMail:IsExpire() then
            table.remove(self.m_mReadyMails,iNo)
            baseobj_delay_release(oMail)
        elseif oMail and oMail:IsTimeSend() then
            table.remove(self.m_mReadyMails,iNo)
            table.insert(mSend,oMail:Save())
            baseobj_delay_release(oMail)
        end
    end
    for _,mData in pairs(mSend) do
        self:AddSysMail(mData)
    end
    if #mSend > 0 then
        for pid, oPlayer in pairs(global.oWorldMgr:GetOnlinePlayerList()) do
            self:LoginCheckSysMail(oPlayer)
        end
    end
end

-- 具体对象，定时发送
function NewMailCacheObj(...)
    return CMailCacheObj:New(...)
end

CMailCacheObj = {}
CMailCacheObj.__index = CMailCacheObj
inherit(CMailCacheObj, datactrl.CDataCtrl)

function CMailCacheObj:New(iMailId)
    local o = super(CMailCacheObj).New(self, {mailid=iMailId})
    o:Init()
    return o
end

function CMailCacheObj:Init()
    self.m_lPid = {}
    self.m_iStartTime = 0
    self.m_iEndTime = 0
    self.m_lChannels = {}
    self.m_bAllChannel = false
    self.m_lPlatforms = {}
    self.m_bAllPlatforms = false
    self.m_iMinGrade = 0
    self.m_iMaxGrade = 0
    self.m_iCreateTime = 0

    self.m_sTitle = ""
    self.m_sContext = ""
    self.m_lItem = {}
end

function CMailCacheObj:Create(mData)
    local func = function (v) return tonumber(v) end
    local mChannels = mData["channels"] or {}
    local mPlatforms = mData["platforms"] or {}
    if mData["channels"] and type(mData["channels"]) ~= "table" then
        mChannels = split_string(mData["channels"],",",func)
    end
    if mData["platforms"] and type(mData["platforms"]) ~= "table" then
        mPlatforms = split_string(mData["platforms"],",",func)
    end
    self.m_lPid = mData["playerids"] or {}
    self.m_iStartTime = mData["start_time"] or 0
    self.m_iEndTime = mData["end_time"] or 0
    self.m_bAllChannel = mData["all_channel"] or false
    self.m_lChannels = mChannels
    self.m_bAllPlatforms = mData["all_platform"] or false
    self.m_lPlatforms = mPlatforms
    self.m_iMinGrade = mData["min_grade"] or 0
    self.m_iMaxGrade = mData["max_grade"] or 0
    self.m_lPartner = mData["partner"] or {}
    self.m_sTitle = mData["title"] or "未知主题"
    self.m_sContext = mData["context"] or "无"
    self.m_lItem = mData["items"] or {}
    self.m_iCreateTime = get_time()
end

function CMailCacheObj:GetMailInfo()
    local mData = {}
    mData["createtime"] = self.m_iStartTime
    mData["title"] = self.m_sTitle
    mData["context"] = self.m_sContext
    mData["expert"] = self.m_iEndTime - self.m_iStartTime
    return mData
end

function CMailCacheObj:Save()
    local mData = {}
    mData["playerids"] = self.m_lPid
    mData["start_time"] = self.m_iStartTime
    mData["end_time"] = self.m_iEndTime
    mData["all_channel"] = self.m_bAllChannel
    mData["channels"] = self.m_lChannels
    mData["all_platform"] = self.m_bAllPlatforms
    mData["platforms"] = self.m_lPlatforms
    mData["min_grade"] = self.m_iMinGrade
    mData["max_grade"] = self.m_iMaxGrade
    mData["title"] = self.m_sTitle
    mData["context"] = self.m_sContext
    mData["items"] = self.m_lItem
    mData["createtime"] = self.m_iCreateTime
    mData["partner"] = self.m_lPartner
    return mData
end

function CMailCacheObj:Load(mData)
    mData = mData or {}
    self.m_lPid = mData["playerids"] or {}
    self.m_iStartTime = mData["start_time"] or 0
    self.m_iEndTime = mData["end_time"] or 0
    self.m_bAllChannel = mData["all_channel"] or false
    self.m_lChannels = mData["channels"] or {}
    self.m_bAllPlatforms = mData["all_platform"] or false
    self.m_lPlatforms = mData["platforms"] or {}
    self.m_iMinGrade = mData["min_grade"] or 0
    self.m_iMaxGrade = mData["max_grade"] or 0
    self.m_iCreateTime = mData["createtime"] or get_time()

    self.m_sTitle = mData["title"] or "未知主题"
    self.m_sContext = mData["context"] or "无"
    self.m_lItem = mData["items"] or {}
    self.m_lPartner = mData["partner"] or {}
end

function CMailCacheObj:IsExpire()
    return self.m_iEndTime < get_time()
end

function CMailCacheObj:IsTimeSend()
    return self.m_iStartTime <= get_time()
end

function CMailCacheObj:IsValid(oPlayer)
    if not oPlayer then return false end

    local iPlatform = oPlayer:GetPlatform()
    if not self.m_bAllPlatforms and not table_in_list(self.m_lPlatforms,iPlatform) then return end

    local iChannel = oPlayer:GetChannel()
    if not self.m_bAllChannel and not table_in_list(self.m_lChannels,iChannel) then return end

    local iPid = oPlayer:GetPid()
    if #self.m_lPid > 0  and not table_in_list(self.m_lPid,iPid) then return end

    if self.m_iMinGrade > oPlayer:GetGrade() then
        return false
    end
    if self.m_iMaxGrade > 0 and self.m_iMaxGrade < oPlayer:GetGrade() then
        return false
    end
    return true
end

function CMailCacheObj:SendSysMail(iPid)
    local mItems = {}
    for _, info in ipairs(self.m_lItem) do
        local oItem = loaditem.ExtCreate(info.sid)
        oItem:SetAmount(info.amount or 1)
        table.insert(mItems, oItem)
    end
    local mPartner = {}
    for _, info in ipairs(self.m_lPartner) do
        local oPartner = self:CreatePartner(info.sid)
        table.insert(mPartner, oPartner)
    end

    local oMailMgr = global.oMailMgr
    oMailMgr:SendMail(0, "系统", iPid, self:GetMailInfo(), nil, mItems, mPartner)
end

function CMailCacheObj:CreatePartner(sInfo)
    local sid,sArg
    if tonumber(sInfo) then
        sid = tonumber(sInfo)
    else
        sid,sArg = string.match(sInfo,"(%d+)(.+)")
        sid = tonumber(sid)
    end
    local mConfig = {}
    if sArg then
        sArg = string.sub(sArg,2,#sArg-1)
        local mArg = split_string(sArg,",")
        for _,sTmp in ipairs(mArg) do
            local key,value = string.match(sTmp,"(.+)=(.+)")
            if tonumber(value) then
                value = tonumber(value)
            end
            mConfig[key] = value
        end
    end
    mConfig["star"] = mConfig["star"] or 1
    return loadpartner.CreatePartner(sid,{star = mConfig["star"]})
end
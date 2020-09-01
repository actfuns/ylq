--import module

local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local colorstring = require "public.colorstring"

local datactrl = import(lualib_path("public.datactrl"))
local titledefines = import(service_path("title.titledefines"))


function NewTitle(...)
    return CTitle:New(...)
end

CTitle = {}
CTitle.__index = CTitle
inherit(CTitle, datactrl.CDataCtrl)

function CTitle:New(iPid, iTid, create_time, name)
    local o = super(CTitle).New(self, {iTid = iTid, iPid=iPid})
    o:SetData("name", name)
    o:SetData("create_time", create_time or get_time())
    o:SetData("use_time", 0)
    return o
end

function CTitle:Init()
    self:Setup()
end

function CTitle:Setup()
    -- 称谓失效相关处理
    self:_CheckExpire()
end

function CTitle:_CheckExpire()
    if self:IsForever() then
        return
    end
    self:DelTimeCb("_CheckExpire")
    local iLeftTime = self:GetExpireTime()
    iLeftTime = math.max(1, iLeftTime)
    local iPid = self:GetPid()
    local iTid = self:TitleID()
    local oWorldMgr = global.oWorldMgr
    local f = function ()
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local oTitle = oPlayer.m_oTitleCtrl:GetTitleByTid(iTid)
            if oTitle then
                 oTitle:_DoExpire()
            end
        end
    end
    self:AddTimeCb("_CheckExpire", iLeftTime * 1000, f)
end

function CTitle:_DoExpire()
    if is_release(self) then
        return
    end
    self:SendExpireMail()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        oPlayer:RemoveTitles({self:TitleID()})
    end
end

function CTitle:SendExpireMail()
    local oMailMgr = global.oMailMgr
    local mData, name = oMailMgr:GetMailInfo(14)
    if not mData then return end

    local mInfo = table_copy(mData)
    mInfo.context = colorstring.FormatColorString(mInfo.context, {title=self:GetName()})
    oMailMgr:SendMail(0, name, self:GetPid(), mInfo, {})
end

function CTitle:GetTitleData()
    local mData = res["daobiao"]["title"]["title"][self:TitleID()]
    assert(mData,string.format("CTitle GetTitleData err: %d", self:TitleID()))
    return mData
end

function CTitle:TitleID()
    return self:GetInfo("iTid")
end

function CTitle:GetPid()
    return self:GetInfo("iPid")
end

function CTitle:Save()
    local mData = {}
    mData.titleid = self:TitleID()
    mData.name  =  self:GetData("name")
    mData.create_time = self:GetData("create_time")
    mData.use_time = self:GetData("use_time")
    return mData
end

function CTitle:Load(mData)
    self:SetData("name", mData.name)
    self:SetData("create_time", mData.create_time)
    self:SetData("use_time", mData.use_time)
end

function CTitle:GetName()
    local name = self:GetData("name")
    if not name then
        name = self:GetConfigData()["name"]
    end
    return name
end

function CTitle:SetName(name)
    self:SetData("name", name)
end

function CTitle:GetUseTime()
    return self:GetData("use_time")
end

function CTitle:SetUseTime()
    self:SetData("use_time", get_time())
end

function CTitle:GetConfigData()
    return self:GetTitleData()
end

function CTitle:GetKey()
    return self:GetConfigData()["key"]
end

function CTitle:IsForever()
    return self:GetConfigData()["duration_time"] <= 0
end

function CTitle:GetExpireTime()
    if self:IsForever() then return 0 end
    return self:GetData("create_time") + self:GetConfigData()["duration_time"]  * 60 - get_time()
end

function CTitle:IsExpire()
    if self:IsForever() then
        return false
    end
    return get_time() >= self:GetData("create_time") + self:GetConfigData()["duration_time"]  * 60
end

function CTitle:GetGroup()
    return self:GetConfigData()["group"]
end

function CTitle:GetShowType()
    return self:GetConfigData()["show_type"]
end

function CTitle:GetShow()
    return self:GetConfigData()["lv"]
end

function CTitle:IsEffect()
    return self:GetConfigData()["effect"] == 1
end

function CTitle:IsInChat()
    return self:GetConfigData()["in_chat"] == 1
end

function CTitle:IsPartnerTitle()
    return self:GetConfigData()["type"] == 1
end

function CTitle:GetAttr(attr)
    if not self:IsEffect() then return 0 end

    local iAttr = titledefines.ATTRS[attr]
    if not iAttr then
        return 0
    end

    local mAttr = self:GetConfigData()["effect_props"][iAttr]
    if mAttr then
        return mAttr["val"]
    end
    return 0
end

function CTitle:PackTitleInfo()
    local mNet = {}
    local iTid = self:TitleID()
    mNet.tid = iTid
    mNet.name = self:GetName()
    mNet.create_time = self:GetData("create_time")
    mNet.left_time = self:GetExpireTime() + get_time()
    mNet.progress = res["daobiao"]["title"]["title"][iTid]["condition_value"]
    return mNet
end

function CTitle:GetTitleInfo()
    local mNet = {}
    local iTid = self:TitleID()
    mNet.tid = iTid
    mNet.name = self:GetName()
    mNet.create_time = self:GetData("create_time")
    mNet.left_time = self:GetExpireTime() + get_time()
    mNet.progress = res["daobiao"]["title"]["title"][iTid]["condition_value"]
    return mNet
end

function CTitle:CheckAdjust(...)
end
local global = require "global"
local extend = require "base.extend"
local gamedefines = import(lualib_path("public.gamedefines"))
local kaopureport = import(lualib_path("public.kaopureport"))
local serverinfo = import(lualib_path("public.serverinfo"))

function NewKaopuMgr()
    return CKaopuMgr:New()
end

CKaopuMgr = {}
CKaopuMgr.__index = CKaopuMgr
inherit(CKaopuMgr, logic_base_cls())

function CKaopuMgr:New()
    local o = super(CKaopuMgr).New(self)
    return o
end

function CKaopuMgr:PushData(oPlayer,sKey,mData)
    kaopureport.PushData(oPlayer:GetPlatform(),sKey,mData)
end

function CKaopuMgr:PushLData(oPlayer,sKey,mData)
    kaopureport.PushLData(oPlayer:GetPlatform(),sKey,mData)
end

function CKaopuMgr:FormatTimeToSec(iTime)
    local m = os.date("*t", iTime)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d",m.year,m.month,m.day,m.hour,m.min,m.sec)
end

function CKaopuMgr:GetPubField(oPlayer)
    return {
        openid = oPlayer:GetAccount(),
        servername = serverinfo.get_server_name(),
        serverid = get_server_id(),
        rolename = oPlayer:GetName(),
        channelkey = oPlayer:GetKPChannel(),
        rolelevel = oPlayer:GetGrade(),
        roleid = oPlayer:GetPid(),
    }
end

function CKaopuMgr:ValidRecord(oPlayer)
    if not is_production_env() then
        return false
    end
    if oPlayer:GetKPChannel() then
        return true
    end
    return false
end

function CKaopuMgr:OnDisconnected(oPlayer)
    if not self:ValidRecord(oPlayer) then
        return
    end
    local mData = self:GetPubField(oPlayer)
    local iLoginTime = oPlayer.m_oActiveCtrl:GetData("login_realtime",0)
    local iLogOutTime = get_time()
    mData.logintime = self:FormatTimeToSec(iLoginTime)
    mData.loginouttime = self:FormatTimeToSec(iLogOutTime)
    mData.onlinetime = iLogOutTime - iLoginTime
    self:PushData(oPlayer,"userlogin",mData)
end

function CKaopuMgr:OnlineUserNumber(mOnline)
    if not is_production_env() then
        return
    end
    mOnline = mOnline or {}
    for iPlatform,mInfo in pairs(mOnline) do
        local mlData = {}
        for sChannelKey,iCnt in pairs(mInfo) do
            table.insert(mlData,{
                    servername=serverinfo.get_server_name(),
                    serverid=MY_SERVER_KEY,
                    channelkey=sChannelKey,
                    eventtime=self:FormatTimeToSec(get_time()),
                    usernumber=iCnt,
            })
        end
        if iPlatform == "IOS" then
            kaopureport.PushLData(3,"usernumberonline",mlData)
        elseif iPlatform == "ANDROID" then
            kaopureport.PushLData(1,"usernumberonline",mlData)
        end
    end
end


function CKaopuMgr:GainGoldCoin(oPlayer, mInfo)
    if not self:ValidRecord(oPlayer) then
        return
    end
    local mData = self:GetPubField(oPlayer)
    table_combine(mData, mInfo)
    mData.eventtime = self:FormatTimeToSec(mData.eventtime)
    kaopureport.PushData(oPlayer:GetPlatform(),"GainMoney",mData)
end

function CKaopuMgr:ConsumeGoldCoin(oPlayer, mInfo)
    if not self:ValidRecord(oPlayer) then
        return
    end
    local mData = self:GetPubField(oPlayer)
    table_combine(mData, mInfo)
    mData.eventtime = self:FormatTimeToSec(mData.eventtime)
    kaopureport.PushData(oPlayer:GetPlatform(),"consume",mData)
end
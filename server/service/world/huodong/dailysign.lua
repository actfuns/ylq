--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "累积签到"
inherit(CHuodong, huodongbase.CHuodong)


function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_SendRewardMailOnce = true
    return o
end

function CHuodong:OnLogin(oPlayer, bReEnter)
    self:PreCheck(oPlayer, bReEnter)
    self:SendDailySignInfo(oPlayer)
end

function CHuodong:OnLogout(oPlayer)
end

function CHuodong:NewDayRefresh(oPlayer)
    self:PreCheck(oPlayer)
    self:SendDailySignInfo(oPlayer)
end


function CHuodong:PreCheck(oPlayer,bReEnter)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["signtype"]
    for sKey, m in pairs(mData) do
        if self:IsMaxSignDay(oPlayer, sKey) and not oPlayer:IsTodaySigned(sKey) then
            oPlayer.m_oActiveCtrl:ResetDailySign(sKey)
        end
    end
end

function CHuodong:IsClose(oPlayer, sKey)
    local oWorldMgr = global.oWorldMgr
    local sKey = sKey .. "_sign"
    if oWorldMgr:IsClose(sKey) then
        oPlayer:NotifyMessage("该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return true
    end

    return false
end

function CHuodong:IsOpenGrade(oPlayer, sKey)
    local oWorldMgr = global.oWorldMgr
    local sKey = sKey .. "_sign"
    local iOpenGrade = oWorldMgr:QueryControl(sKey, "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CHuodong:DailySignIn(oPlayer, sKey)
    if not self:ValidDailySign(oPlayer, sKey) then
        return
    end
    local iSignDay = oPlayer:GetDailySignDay(sKey)
    local mData = self:GetDailySignData(sKey, iSignDay + 1)
    oPlayer:DailySign(sKey)
    self:GiveReward(oPlayer, sKey, mData.reward)
    self:SendDailySignInfo(oPlayer, sKey)
end

function CHuodong:GiveReward(oPlayer, sKey, mReward)
    local lGive = { {mReward.sid, mReward.amount},}
    local sReason = self.m_sName .. "_" .. sKey
    if oPlayer:ValidGive(lGive) then
        oPlayer:GiveItem(lGive, sReason, {cancel_tip = 1})
    else
        local iMailId = 1
        self:SendMail(oPlayer, sKey, mReward, iMailId)
    end
end

function CHuodong:SendMail(oPlayer, sKey, mReward, iMailId)
    local oMailMgr = global.oMailMgr
    local mData, name = oMailMgr:GetMailInfo(iMailId)
    local oItem = loaditem.ExtCreate(mReward.sid)
    oItem:SetAmount(mReward.amount)
    oMailMgr:SendMail(0, name, oPlayer:GetPid(), mData, {}, {oItem})
end

function CHuodong:GetDailySignData(sKey, iDay)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName][sKey][iDay]
     assert(mData,string.format("CHuodong GetTollGateData err: %s %s", self.m_sName, sKey))
     return mData
end

function CHuodong:MaxSignDay(sKey)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["signtype"][sKey]
    assert(mData, string.format("sign type:%s, not exist!", sKey))
    return mData.day
end

function CHuodong:WithSignType(sKey)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["signtype"][sKey]
    if mData then
        return true
    end
    return false
end

function CHuodong:IsMaxSignDay(oPlayer, sKey)
    local iMaxSign = self:MaxSignDay(sKey)
    local iSigned = oPlayer:GetDailySignDay(sKey)
    return iSigned >= iMaxSign
end

function CHuodong:ValidDailySign(oPlayer, sKey)
    if not self:WithSignType(sKey) then
        oPlayer:NotifyMessage("类型不存在")
        return false
    end

    if self:IsMaxSignDay(oPlayer, sKey) then
        oPlayer:NotifyMessage("已达最大次数")
        return false
    end

    if oPlayer:IsTodaySigned(sKey) then
        oPlayer:NotifyMessage("今日已签到")
        return false
    end

    return true
end

function CHuodong:SendDailySignInfo(oPlayer, sKey)
    local lKeys = {}
    if sKey then
        table.insert(lKeys, sKey)
    else
        local res = require "base.res"
        local mData = res["daobiao"]["huodong"][self.m_sName]["signtype"]
        for sKey, m in pairs(mData) do
            local mNet = oPlayer:PackDailySignInfo(sKey)
            table.insert(lKeys, sKey)
        end
    end

    local lNet = {}
    for _, sKey in ipairs(lKeys) do
        local mNet = oPlayer:PackDailySignInfo(sKey)
        table.insert(lNet, mNet)
    end
    oPlayer:Send("GS2CDailySignInfo", {sign_info = lNet})
end
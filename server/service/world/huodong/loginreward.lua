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
CHuodong.m_sTempName = "登录奖励"
inherit(CHuodong, huodongbase.CHuodong)

LOGIN_DAYS = 15
LOGIN_DAYS_BIT = (1<<LOGIN_DAYS) - 1
MAX_BREED_VAL = gamedefines.MAX_BREED_VAL

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_SendRewardMailOnce = true
    return o
end

function CHuodong:Init()
    self:TryStartRewardMonitor()
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
    end
end

function CHuodong:OnLogin(oPlayer, bReEnter)
    --body
end

function CHuodong:IsClose(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if oWorldMgr:IsClose("loginreward") then
        oNotifyMgr:Notify(iPid, "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return true
    end

    return false
end

function CHuodong:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("loginreward", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CHuodong:GetReward(oPlayer, iDay)
    if iDay > LOGIN_DAYS then
        return
    end
    local iLoginDay = oPlayer.m_oActiveCtrl:GetData("count_login_day", 0)
    if iDay > iLoginDay then
        return
    end
    local iBitDay = (1<<(iDay - 1))
    local iRewarded = oPlayer.m_oActiveCtrl:GetData("login_rewarded_day", 0)
    if ((iRewarded & iBitDay) ~ iBitDay) > 0 then

        local iOldRewarded = iRewarded
        iRewarded = iRewarded | iBitDay
        oPlayer.m_oActiveCtrl:SetData("login_rewarded_day", iRewarded)

        self:GiveReward(oPlayer, iDay)
        oPlayer:Send("GS2CLoginRewardDay", {rewarded_day = iRewarded,})
        global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
        self:CheckShowUI(oPlayer, iDay)

        record.user("loginreward", "attach_reward", {
            pid = oPlayer:GetPid(),
            name = oPlayer:GetName(),
            grade = oPlayer:GetGrade(),
            login_day = iLoginDay,
            attach_day = iDay,
            old_reward_day = iOldRewarded,
            now_reward_day = iRewarded,
            })
    end
end

function CHuodong:GiveReward(oPlayer, iDay)
    local mData = self:GetLoginRewardData(iDay)
    self:Reward(oPlayer:GetPid(), mData.reward, {cancel_tip = 1})
    local lExtra = mData.extra_reward or {}
    if next(lExtra) then
        for _, iReward in ipairs(lExtra) do
            self:Reward(oPlayer:GetPid(), iReward, {cancel_tip = 1})
        end
    end
end

function CHuodong:CheckShowUI(oPlayer, iDay)
    if iDay < LOGIN_DAYS then
        local iLoginDay = oPlayer.m_oActiveCtrl:GetData("count_login_day", 0)
        local mData = self:GetLoginRewardData(iDay)
        if (iDay == iLoginDay) and (mData.next_day_ui == 1) then
            oPlayer:Send("GS2CShowLoginRewardUI", {next_day = iDay + 1})
        end
    end
end

function CHuodong:GetLoginRewardData(iDay)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["reward"][iDay]
     assert(mData,string.format("CHuodong GetTollGateData err: %s %d", self.m_sName, iDay))
     return mData
end

function CHuodong:ValidAddFullBreedVal(oPlayer)
    local iReceive = oPlayer.m_oActiveCtrl:GetData("breed_rwd", 0)
    if iReceive == 1 then
        return false
    end
    local iVal = oPlayer.m_oActiveCtrl:GetData("breed_val", 0)
    if iVal >= MAX_BREED_VAL then
        oPlayer:NotifyMessage("孵化值已满")
        return false
    end
    local iNeed = MAX_BREED_VAL - iVal
    if not oPlayer:ValidColorCoin(iNeed) then
        return false
    end
    return true
end

function CHuodong:AddFullBreedVal(oPlayer)
    -- local sReason = "购买七日孵化值"
    -- local iVal = oPlayer.m_oActiveCtrl:GetData("breed_val", 0)
    -- local iNeed = MAX_BREED_VAL - iVal
    -- if oPlayer:ValidGoldCoin(iNeed) then
    --     oPlayer:ResumeGoldCoin(iNeed, sReason)
    --     oPlayer.m_oActiveCtrl:SetData("breed_val", MAX_BREED_VAL)
    --     oPlayer.m_oActiveCtrl:GS2CLoginRewardInfo()
    -- end
end

function CHuodong:ValidGetBreedValRwd(oPlayer)
    local iReceive = oPlayer.m_oActiveCtrl:GetData("breed_rwd", 0)
    if iReceive > 0 then
        return false
    end
    local iVal = oPlayer.m_oActiveCtrl:GetData("breed_val", 0)
    if iVal < MAX_BREED_VAL then
        return false
    end
    return true
end

function CHuodong:GetBreedValRwd(oPlayer)
    local sReason = "七日孵化奖励"
    local iPartype = 418
    local list = {{iPartype,1}}
    if oPlayer.m_oPartnerCtrl:ValidGive(list) then
        oPlayer:GivePartner(list, sReason)
        oPlayer.m_oActiveCtrl:SetData("breed_rwd",1)
        oPlayer.m_oActiveCtrl:GS2CLoginRewardInfo()
    else
        local loadpartner = import(service_path("partner.loadpartner"))
        local oPartner = loadpartner.CreatePartner(iPartype)
        local iMailId = 1
        local oMailMgr = global.oMailMgr
        local mData, name = oMailMgr:GetMailInfo(iMailId)
        oMailMgr:SendMail(0, name, oPlayer:GetPid(), mData, {}, {}, {oPartner})
        oNotifyMgr:Notify(oPlayer:GetPid(), string.format("你的背包已满，%s将以邮件的形式发送至邮箱，请及时领取", itemobj:Name()))
    end
end
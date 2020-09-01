local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local achievepush = import(service_path("achieve.achievepush"))
local achievefix = import(service_path("achieve.achievefix"))
local loaditem = import(service_path("item/loaditem"))


function NewAchieveMgr()
    return CAchieveMgr:New()
end

CAchieveMgr = {}
CAchieveMgr.__index = CAchieveMgr
inherit(CAchieveMgr, logic_base_cls())

function CAchieveMgr:New()
    local o = super(CAchieveMgr).New(self)
    o.m_AchievePush = achievepush.NewAchievePush()
    o.m_AchieveFix = achievefix.NewAchieveFix()
    o.m_iRemoteAddr = ".achieve"
    o:Init()
    return o
end

function CAchieveMgr:Init()
    self:UpdateOpenDay()
end

function CAchieveMgr:GetRemoteAddr()
    return self.m_iRemoteAddr
end

function CAchieveMgr:CloseGS()
    interactive.Send(self.m_iRemoteAddr, "common", "CloseGS", {})
end

function CAchieveMgr:OnLogin(oPlayer, bReEnter)
    interactive.Send(self.m_iRemoteAddr, "common", "OnLogin", {
        pid = oPlayer:GetPid(),
        create_time = oPlayer:GetCreateTime(),
    })
    local oOfflineP = oPlayer:GetOfflinePartner()
    self:PushAchieve(oPlayer:GetPid(),"玩家战力",{power=oPlayer:GetPower()})
    self.m_AchieveFix:OnLogin(oPlayer, bReEnter)
    self:SendSevDayBuy(oPlayer)
end

function CAchieveMgr:OnLogout(oPlayer)
    interactive.Send(self.m_iRemoteAddr, "common", "OnLogout", {
        pid = oPlayer:GetPid(),
        })
end

function CAchieveMgr:OnDisconnected(oPlayer)
    interactive.Send(self.m_iRemoteAddr,"common", "Disconnected", {
        pid = oPlayer:GetPid(),
        })
end

function CAchieveMgr:Forward(sCmd, iPid, mData)
    interactive.Send(self.m_iRemoteAddr, "common", "Forward", {
        pid = iPid, cmd = sCmd, data = mData,
    })
end

function CAchieveMgr:NewDay(iDay)
    interactive.Send(".achieve","common","NewDay",{
        open_day = global.oWorldMgr:GetOpenDays(),
    })
end

function CAchieveMgr:UpdateOpenDay()
    interactive.Send(".achieve","common","SyncServerDay",{
        open_day = global.oWorldMgr:GetOpenDays(),
    })
end

function CAchieveMgr:ClearAchieveDegree(iPid,sKey)
    interactive.Send(".achieve","common","ClearAchieveDegree",{
        pid = iPid , key= sKey
    })
end

function CAchieveMgr:PushAchieve(iPid,sKey,mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        safe_call(self.m_AchievePush.PushAchieve,self.m_AchievePush,iPid,sKey,mArgs)
    else
        local oPubMgr = global.oPubMgr
        oPubMgr:OnlineExecute(iPid,"PushAchieve",{sKey,mArgs})
    end
end

function CAchieveMgr:GetAchieveRwItem(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][iAchieveID]["rewarditem"]
end

function CAchieveMgr:GetPictureRWItem(iPictureID)
    local res = require "base.res"
    local mData = res["daobiao"]["achieve"]["picture"]
    for _,info in pairs(mData) do
        if info["id"] == iPictureID then
            return table_deep_copy(info["rewarditem"])
        end
    end
    print("GetPictureRWItem faild",iPictureID)
end

function CAchieveMgr:GetSevenDayRwItem(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][iAchieveID]["rewarditem"]
end

function CAchieveMgr:GetSevenDayPointTitle(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday_point"][iAchieveID]["title"]
end

function CAchieveMgr:GetAchievePointRwItem(id)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["reward"][id]["rewarditem"]
end

function CAchieveMgr:GetSevenDayPointRwItem(id)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday_point"][id]["rewarditem"]
end

function CAchieveMgr:GetSevenDayGiftRwItem(iDay)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday_gift"][iDay]["rewarditem"]
end

function CAchieveMgr:GetAchieveTaskRWItem(id)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["achievetask"][id]["rewarditem"]
end

function CAchieveMgr:BuildItemList(mReward)
    local mItem = {}
    for _,info in pairs(mReward) do
        local sShape = info["sid"]
        local iAmount = info["num"]
        for iNo=1,100 do
            local oItem = loaditem.ExtCreate(sShape)
            local iAddAmount = math.min(oItem:GetMaxAmount(),iAmount)
            iAmount = iAmount - iAddAmount
            oItem:SetAmount(iAddAmount)
            table.insert(mItem,oItem)
            if iAmount <= 0 then
                break
            end
        end
    end
    return mItem
end

function CAchieveMgr:RewardAchItem(iPid,mData)
    local iAchieveID = mData.achieveid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mReward = self:GetAchieveRwItem(iAchieveID)
    local mItem = self:BuildItemList(mReward)
    local sReason = string.format("成就: %d",iAchieveID)
    local mLogItem = {}
    for _,oItem in pairs(mItem) do
        table.insert(mLogItem,oItem:LogInfo())
        oPlayer:RewardItem(oItem,sReason)
    end
    record.log_db("achieve", "ach_reward",{pid=iPid,aid=iAchieveID,item=mLogItem})
    self:PushAchieve(iPid,"领取成就奖励",{value=1})
end

function CAchieveMgr:RewardPointItem(iPid,mData)
    local id = mData.id
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mReward = self:GetAchievePointRwItem(id)
    local mItem = self:BuildItemList(mReward)
    local sReason = string.format("成就总点数: %d",id)
    local mLogItem = {}
    for _,oItem in pairs(mItem) do
        table.insert(mLogItem,oItem:LogInfo())
        oPlayer:RewardItem(oItem,sReason,{cancel_tip=true})
    end
    global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
    record.log_db("achieve", "point_reward",{pid=iPid,id=id,item=mLogItem})
    self:PushAchieve(iPid,"领取成就奖励",{value=1})
end

function CAchieveMgr:RewardPicItem(iPid,mData)
    local iPictureID = mData.pictureid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mReward = self:GetPictureRWItem(iPictureID)
    local mItem = self:BuildItemList(mReward)
    local sReason = string.format("世界图鉴: %d",iPictureID)
    for _,oItem in pairs(mItem) do
        oPlayer:RewardItem(oItem,sReason)
    end
    self:PushAchieve(iPid,"领取世界之源奖励",{value=1})
end

function CAchieveMgr:RewardSevItem(iPid, mData)
    local iAchieveID = mData.achieveid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mReward = self:GetSevenDayRwItem(iAchieveID)
    local mItem = self:BuildItemList(mReward)
    local sReason = string.format("七日目标成就: %d",iAchieveID)
    local mLogItem = {}
    for _,oItem in pairs(mItem) do
        table.insert(mLogItem,oItem:LogInfo())
        oPlayer:RewardItem(oItem,sReason)
    end
    record.log_db("achieve", "sev_reward",{pid=iPid,aid=iAchieveID,item=mLogItem})
end

function CAchieveMgr:RewardSevPointItem(iPid, mData)
    local id = mData.id
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mReward = self:GetSevenDayPointRwItem(id)
    local mItem = self:BuildItemList(mReward)
    local sReason = string.format("七日目标成就点数: %d",id)
    local mLogItem = {}
    for _,oItem in pairs(mItem) do
        table.insert(mLogItem,oItem:LogInfo())
        oPlayer:RewardItem(oItem,sReason)
    end
    local iTitle = self:GetSevenDayPointTitle(id)
    if iTitle and iTitle > 0 then
        oPlayer:AddTitle(iTitle, get_time())
    end
    record.log_db("achieve", "sev_point_reward",{pid=iPid,id=id,item=mLogItem, title = iTitle or 0})
end

function CAchieveMgr:RewardSevGiftItem(iPid, mData)
    local iDay = mData.day
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mReward = self:GetSevenDayGiftRwItem(iDay)
    local mItem = self:BuildItemList(mReward)
    local sReason = string.format("七日目标，购买: %d天礼包",iDay)
    local mLogItem = {}
    for _,oItem in pairs(mItem) do
        table.insert(mLogItem,oItem:LogInfo())
        oPlayer:RewardItem(oItem,sReason)
    end
    record.log_db("achieve", "sev_gift_reward",{pid=iPid,day=iDay,item=mLogItem})
end

function CAchieveMgr:SendSevMail(iPid, mData)
    local oWorldMgr = global.oWorldMgr
    local lAch = mData.unget_achieve or {}
    local lDegress = mData.unget_degress or {}
    local lItems = {}
    if #lAch > 0  then
        for _, iAch in ipairs(lAch) do
            local mReward = self:GetSevenDayRwItem(iAch)
            local l = self:BuildItemList(mReward)
            if #l > 0 then
                list_combine(lItems, l)
            end
        end
    end
    if #lDegress > 0 then
        for _, id in ipairs(lDegress) do
            local mReward = self:GetSevenDayPointRwItem(id)
            local l = self:BuildItemList(mReward)
            if #l > 0 then
                list_combine(lItems, l)
            end
        end
    end
    if #lItems > 0 then
        local iMailId = 54
        local oMailMgr = global.oMailMgr
        local m, name = oMailMgr:GetMailInfo(iMailId)
        oMailMgr:SendMail(0, name, iPid, m, {}, lItems)
        record.log_db("achieve", "sev_end_mail",{pid=iPid,sevinfo=ConvertTblToStr(mData)})
    end
end

function CAchieveMgr:ReachAchieve(iPid,mData)
    local iAchieveID = mData.achieveid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30023,1)
    end
end

function CAchieveMgr:ReachPicture(iPid,mData)
    local iPictureID = mData.pictureid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30024,1)
    end
end

function CAchieveMgr:GetSevdayGiftInfo(iDay)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday_gift"][iDay]
end

function CAchieveMgr:BuySevenDayGift(oPlayer, mData)
    local iDay = mData.day
    local mInfo = self:GetSevdayGiftInfo(iDay)
    if not mInfo then
        return
    end
    if self:IsSevAchieveClose(oPlayer) then
        return
    end
    local lBuy = oPlayer.m_oActiveCtrl:GetData("sevenday_gift", {})
    if table_in_list(lBuy, iDay) then
        return
    end
    local iVal = mInfo.cost or 18
    if oPlayer:ValidGoldCoin(iVal) then
        table.insert(lBuy, iDay)
        oPlayer:ResumeGoldCoin(iVal,"购买七日目标礼包")
        self:RewardSevGiftItem(oPlayer:GetPid(), {day = iDay})
        oPlayer.m_oActiveCtrl:SetData("sevenday_gift", lBuy)
        self:SendSevDayBuy(oPlayer)
    end
end

function CAchieveMgr:SendSevDayBuy(oPlayer)
    local lBuy = oPlayer.m_oActiveCtrl:GetData("sevenday_gift", {})
    oPlayer:Send("GS2CSevenDayBuy", {
        already_buy = table_value_list(lBuy),
        })
end

function CAchieveMgr:IsSevAchieveClose(oPlayer)
    local res = require "base.res"
    local val = res['daobiao']["global"]["sevenday_close"]["value"] or 8
    val = tonumber(val)
    if oPlayer:GetCreateDay() > val then
        return true
    end
    return false
end

function CAchieveMgr:RewardAchieveTaskItem(iPid,mData)
    local iTaskId = mData.taskid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mReward = self:GetAchieveTaskRWItem(iTaskId)
    local mItem = self:BuildItemList(mReward)
    local sReason = string.format("成就任务: %d",iTaskId)
    for _,oItem in pairs(mItem) do
        oPlayer:RewardItem(oItem,sReason)
    end
    record.user("achievetask","task_reward",{pid = iPid,taskid=iTaskId})
end
--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local loaditem = import(service_path("item.loaditem"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

local STATUS = {
    READY = 0,
    START = 1,
    END = 2,
}

CHuodong = {}
CHuodong.__index = CHuodong
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:NewHour(iWeekDay, iHour)
end

function CHuodong:OnLogin(oPlayer, bReEnter)
    if self:IsOpenGrade(oPlayer) then
        if not bReEnter then
            self:PreCheck(oPlayer)
            self:CheckStart(oPlayer)
        end
        local idx = self:StartingIdx(oPlayer)
        self:SendGradeGift(oPlayer, idx)
    end
end

function CHuodong:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iOpenGrade = oWorldMgr:QueryControl("grade_gift", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CHuodong:PreCheck(oPlayer)
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    if #lGrade <= 0 then
        --后续开放新等级，旧号需要重新开启
        local res = require "base.res"
        local mData = res["daobiao"]["huodong"][self:ResName()]["grade_gift"]
        local lDataGrade = table_key_list(mData)
        table.sort(lDataGrade)
        for _, i in ipairs(lDataGrade) do
            if i <= oPlayer:GetGrade() then
                self:AddNewGradeGift(oPlayer, i)
            end
        end
    end
end

function CHuodong:GetGiftData(iGrade)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["grade_gift"][iGrade]
    return mData
end

function CHuodong:OnUpGrade(oPlayer, iGrade)
    local mData = self:GetGiftData(iGrade)
    if mData then
        local idx = self:AddNewGradeGift(oPlayer)
        if not self:IsStarting(oPlayer) then
            self:SetGiftStatus(oPlayer, idx, STATUS.START)
            self:StartTimer(oPlayer, idx)
            local mGrade = self:GetGradeGiftInfo(oPlayer, idx)
            self:SendGradeGift(oPlayer, idx, 1)
        end
    end
end

function CHuodong:AddNewGradeGift(oPlayer, iGrade)
    local iGrade = iGrade or oPlayer:GetGrade()
    -- local mGradeData = self:GetGiftData(iGrade)
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    table.insert(lGrade, {
        grade = iGrade,
        status = STATUS.READY,
        starttime = self:CalStartTime(oPlayer),
        createtime = get_time(),
        free = 0,
        buy = 0,
        })
    oPlayer.m_oActiveCtrl:SetData("grade_gift", lGrade)

    return #lGrade
end

function CHuodong:CalStartTime(oPlayer)
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    local n = #lGrade
    if n == 0 then
        return get_time()
    end
    local m = lGrade[n]
    local mData = self:GetGiftData(m.grade)
    if not mData then
        return get_time()
    end
    local iRemain = math.max((m.starttime + mData.timeout) - get_time(), 0)
    return get_time() + iRemain
end

function CHuodong:GetGradeGiftInfo(oPlayer, idx)
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    return lGrade[idx]
end

function CHuodong:GetGradeGiftByGrade(oPlayer, iGrade)
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    for idx, m in ipairs(lGrade) do
        if m.grade == iGrade then
            return m, idx
        end
    end
    return nil
end

function CHuodong:SetGradeGift(oPlayer, lGrade)
    oPlayer.m_oActiveCtrl:SetData("grade_gift", lGrade)
end

function CHuodong:IsStarting(oPlayer)
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    for _, m in ipairs(lGrade) do
        if self:GetGiftData(m.grade) then
            if m.status == STATUS.START then
                return true
            end
        else
            record.warning("grade_gift config error, grade:%s", m.grade)
        end
    end
    return false
end

function CHuodong:RemoveNotExist(oPlayer, lRemove)
    if #lRemove > 0 then
        local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
        for _, idx in ipairs(lRemove) do
            table.remove(lGrade, idx)
            --log
        end
    end
end

function CHuodong:StartingIdx(oPlayer)
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    for idx, m in ipairs(lGrade) do
        if self:GetGiftData(m.grade) then
            if m.status == STATUS.START then
                return idx
            end
        else
            record.warning("grade_gift config error, grade:%s", m.grade)
        end
    end
    return nil
end

function CHuodong:CheckStart(oPlayer)
    local iTime = 0
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    for idx, m in ipairs(lGrade) do
        local mData = self:GetGiftData(m.grade)
        if self:IsTimeOut(m.starttime + mData.timeout) then
            if m.status ~= STATUS.END then
                self:SetGiftStatus(oPlayer, idx, STATUS.END)
            end
        elseif m.status == STATUS.READY then
            self:SetGiftStatus(oPlayer, idx, STATUS.START)
            self:StartTimer(oPlayer, idx)
            return idx
        elseif m.status == STATUS.START then
            self:StartTimer(oPlayer, idx)
            return idx
        else
            -- grade gift passed
        end
    end
end

function CHuodong:IsTimeOut(iEndtime)
    return iEndtime <= get_time()
end

function CHuodong:SetGiftStatus(oPlayer, idx, iStatus)
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    local m =lGrade[idx] or {}
    m.status = iStatus
    lGrade[idx] = m
    self:SetGradeGift(oPlayer, lGrade)

    record.user("gradegift", "gift_status", {
        pid = oPlayer:GetPid(),
        gift_grade = m.grade,
        status = iStatus,
        })
    --record log
end

function CHuodong:StartTimer(oPlayer, idx)
    local iPid = oPlayer:GetPid()
    local mGrade = self:GetGradeGiftInfo(oPlayer, idx)
    if mGrade and mGrade.status == STATUS.START then
        local iGrade = mGrade.grade
        local mData = self:GetGiftData(iGrade)
        mGrade.starttime = math.min(mGrade.starttime, get_time())
        local iSec =(mGrade.starttime + mData.timeout) - get_time()
        if iSec > 0 then
            oPlayer:DelTimeCb("GradeGiftTimeOut")
            oPlayer:AddTimeCb("GradeGiftTimeOut", iSec * 1000, function()
                self:GradeGiftFinish(iPid, idx)
            end)
        else
            self:GradeGiftFinish(iPid, idx)
        end
        local oHuodong = global.oHuodongMgr:GetHuodong("welfare")
        if oHuodong then
            oHuodong:CheckGradeGift(oPlayer,iGrade)
        end
    end
end

function CHuodong:GradeGiftFinish(iPid, idx)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:DelTimeCb("GradeGiftTimeOut")
        self:SetGiftStatus(oPlayer, idx, STATUS.END)
        local m = self:GetGradeGiftInfo(oPlayer, idx + 1)
        if m then
            self:SetGiftStatus(oPlayer, idx + 1, STATUS.START)
            self:StartTimer(oPlayer, idx + 1)
        end
        self:SendGradeGift(oPlayer, idx + 1)
    end
end

function CHuodong:GetNextGrade(oPlayer)
    local iGrade = oPlayer:GetGrade()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["grade_gift"]
    local lGrade = table_key_list(mData)
    table.sort(lGrade)
    for _, i in ipairs(lGrade) do
        if i > iGrade then
            return i
        end
    end
    return lGrade[#lGrade]
end

function CHuodong:ValidGainFree(oPlayer, iGrade)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local mData = self:GetGiftData(iGrade)
    if not mData then
        oNotifyMgr:Notify(iPid, "配置信息不存在")
        return false
    end
    local m = self:GetGradeGiftByGrade(oPlayer, iGrade)
    if not m then
        oNotifyMgr:Notify(iPid, "礼包未开启")
        return false
    end
    if m.free == 1 then
        oNotifyMgr:Notify(iPid, "免费礼包已领取")
        return false
    end
    if m.status == STATUS.READY then
        oNotifyMgr:Notify(iPid, "礼包未开启")
        return false
    end
    if m.status == STATUS.END then
        oNotifyMgr:Notify(iPid, "礼包已结束")
        return false
    end
    local mItem = mData.free_gift or {}
    local lGive = {}
    for _, m in ipairs(mItem) do
        table.insert(lGive, {m.sid, m.amount})
    end
    if #lGive > 0 then
        if not oPlayer:ValidGive(lGive) then
            oNotifyMgr:Notify(iPid, "背包已满")
            return false
        end
    end
    return true
end

function CHuodong:ReceiveFreeGift(oPlayer, iGrade)
    if not self:ValidGainFree(oPlayer, iGrade) then
        return
    end
    local mData = self:GetGiftData(iGrade)
    local m, idx = self:GetGradeGiftByGrade(oPlayer,iGrade)
    m.free = 1
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    self:SetGradeGift(oPlayer, lGrade)
    self:RewardItems(oPlayer, mData.free_gift, "免费等级礼包")
    if m.buy == 1 then
        self:GradeGiftFinish(oPlayer:GetPid(), idx)
    else
        self:SendGradeGift(oPlayer, idx)
    end
    record.user("gradegift", "free_gift", {
        pid = oPlayer:GetPid(),
        gift_grade = m.grade,
        free = m.free,
        item = ConvertTblToStr(mData.free_gift),
        })
end

function CHuodong:ValidBuyGift(oPlayer, iGrade, sPayKey)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local mData = self:GetGiftData(iGrade)
    if not mData then
        oNotifyMgr:Notify(iPid, "配置信息不存在")
        return false
    end
    local m = self:GetGradeGiftByGrade(oPlayer, iGrade)
    if not m then
        oNotifyMgr:Notify(iPid, "礼包未开启")
        return false
    end
    if m.buy == 1 then
        oNotifyMgr:Notify(iPid, "礼包已购买")
        return false
    end
    if m.status == STATUS.READY then
        oNotifyMgr:Notify(iPid, "礼包未开启")
        return false
    end
    if m.status == STATUS.END then
        oNotifyMgr:Notify(iPid, "礼包已结束")
        return false
    end
    if not (mData.payid ~= sPayKey or mData.iospayid ~= sPayKey) then
        oNotifyMgr:Notify(iPid, "礼包商品id错误")
        record.error("ValidBuyGift error, pid%s, grade:%s, payid:%s", iPid, iGrade, sPayKey)
        return false
    end
    local mItem = mData.buy_gift or {}
    local lGive = {}
    for _, m in ipairs(mItem) do
        table.insert(lGive, {m.sid, m.amount})
    end
    if #lGive > 0 then
        if not oPlayer:ValidGive(lGive) then
            oNotifyMgr:Notify(iPid, "背包已满")
            return false
        end
    end
    return true
end

function CHuodong:BuyGradeGift(oPlayer, iGrade)
    local mData = self:GetGiftData(iGrade)
    local m, idx = self:GetGradeGiftByGrade(oPlayer, iGrade)
    m.buy = 1
    local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
    self:SetGradeGift(oPlayer, lGrade)
    self:RewardItems(oPlayer, mData.buy_gift, "购买等级礼包")
    if m.free == 1 then
        self:GradeGiftFinish(oPlayer:GetPid(), idx)
    else
        self:SendGradeGift(oPlayer, idx)
    end

    record.user("gradegift", "buy_gift", {
        pid = oPlayer:GetPid(),
        gift_grade = m.grade,
        buy = m.buy,
        item = ConvertTblToStr(mData.buy_gift),
        })
end

function CHuodong:RewardItems(oPlayer, mItem, sReason)
    local lGive = {}
    mItem = mItem or {}
    for _, m in ipairs(mItem) do
        table.insert(lGive, {m.sid, m.amount})
    end
    if #lGive > 0 then
        oPlayer:GiveItem(lGive,sReason,{cancel_tip = 1, cancel_channel =1})
        global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
    end
end

function CHuodong:SendGradeGift(oPlayer, idx, iOpenUI)
    local m = self:GetGradeGiftInfo(oPlayer, idx)
    local iGrade = m and m.grade
    if not m then
        iGrade = self:GetNextGrade(oPlayer)
        m = self:GetGradeGiftByGrade(oPlayer, iGrade)
    end
    local mData = self:GetGiftData(iGrade)
    if mData then
        local mNet = {}
        mNet.open_ui = iOpenUI
        mNet.grade = mData.grade
        mNet.old_price = mData.old_price
        mNet.now_price = mData.now_price
        mNet.discount = mData.discount
        mNet.endtime = mData.timeout + get_time()
        mNet.status = STATUS.READY
        mNet.free_gift = self:PackShowItem(0, mData.free_gift)
        mNet.buy_gift = self:PackShowItem(1, mData.buy_gift)
        mNet.payid = mData.payid
        mNet.ios_payid = mData.iospayid
        if m then
            mNet.endtime = mData.timeout + m.starttime
            mNet.status = m.status or mNet.status
            mNet.buy_gift.done = m.buy
            mNet.free_gift.done = m.free
        end
        oPlayer:Send("GS2CGradeGiftInfo", mNet)
    end
end

function CHuodong:PackShowItem(iType, mItem)
    mItem = mItem or {}
    local mNet = {}
    mNet.type = iType
    mNet.done = 0
    local l = {}
    for _, m in ipairs(mItem) do
        local oItem = loaditem.GetItem(m.sid)
        local mShow = oItem:GetShowInfo()
        if oItem:ItemType() ~= "virtual" then
            mShow.amount = m.amount
        end
        table.insert(l, mShow)
    end
    mNet.items = l
    return mNet
end

function CHuodong:TestOP(oPlayer, iFlag, ...)
    local args = {...}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    if iFlag == 100 then
        oChatMgr:HandleMsgChat(oPlayer,"101-购买礼包")
    elseif iFlag == 101 then
        local iGrade = args[1] or 0
        local mData = self:GetGiftData(iGrade)
        if mData then
            if self:ValidBuyGift(oPlayer, iGrade, mData.payid) then
                local oHuodong = global.oHuodongMgr:GetHuodong("charge")
                if oHuodong then
                    oHuodong:TestOP(oPlayer, 1006, iGrade, "giftbag_" .. mData.now_price, mData.payid)
                    oNotifyMgr:Notify(iPid, "高危操作！")
                end
            end
        else
            oNotifyMgr:Notify(iPid, "礼包不存在")
        end
    elseif iFlag == 102 then
        self:SetGradeGift(oPlayer, {})
        self:PreCheck(oPlayer)
        self:CheckStart(oPlayer)
        self:SendGradeGift(oPlayer,self:StartingIdx(oPlayer))
        oNotifyMgr:Notify(iPid, "已重置礼包信息")
    elseif iFlag == 1001 then
        local lGrade = oPlayer.m_oActiveCtrl:GetData("grade_gift", {})
        print("grade:", lGrade)
    else
        oNotifyMgr:Notify(iPid, "指令不存在")
    end
end
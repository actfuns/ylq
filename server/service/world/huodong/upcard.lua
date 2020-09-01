--import module
--伙伴up活动
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"
local skynet = require "skynet"

local analy = import(lualib_path("public.dataanaly"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item.loaditem"))
local loadpartner = import(service_path("partner/loadpartner"))
local partnerdefine = import(service_path("partner.partnerdefine"))
local res = require "base.res"

local CHuodong = import(service_path("huodong.huodongbase")).CHuodong

local MAX_BARRAGE = 100

function NewHuodong(sHuodongName)
    return CUPCard:New(sHuodongName)
end

CUPCard = {}
CUPCard.__index = CUPCard
inherit(CUPCard, CHuodong)

function CUPCard:New(sHuodongName)
    local o = super(CUPCard).New(self, sHuodongName)
    o.m_iRefreshDay = 0
    o.m_mRefreshPartner = {}
    o.m_Barrage = {}
    o.m_iLastTime = 0
    o.m_LastChooseCommon = 0
    o.m_CardConfig = 0
    o.m_OuQiID = 0
    return o
end

function CUPCard:OnLogin(oPlayer, bReEnter)
    self:OpenDrawCardUI(oPlayer)
end

function CUPCard:NeedSave()
    return true
end

function CUPCard:Load(mData)
    mData = mData or {}
    self.m_iRefreshDay = mData["day_no"] or self.m_iRefreshDay
    local mPartner = mData["partner_list"] or {}
    for sRare,iType in pairs(mPartner) do
        self.m_mRefreshPartner[tonumber(sRare)] = iType
    end
    self.m_LastChooseCommon = mData.choose_common or 0
    self.m_CardConfig = mData.card_config or 0
    self.m_OuQiList = mData.ouqi_list or {}
    self.m_OuQiID = mData.ouqi or 0
    self.m_Barrage =mData.barrage or {}
    self:CheckRefresh()
    self:CheckOuQiTimeout()
end

function CUPCard:Save()
    local mData = {}
    mData["day_no"] = self.m_iRefreshDay
    local mPartner = {}
    for iRare,iType in pairs(self.m_mRefreshPartner) do
        mPartner[db_key(iRare)] = iType
    end
    mData["partner_list"] = mPartner
    mData["choose_common"] = self.m_LastChooseCommon
    mData["card_config"] = self.m_CardConfig
    mData["ouqi_list"] = self.m_OuQiList
    mData["ouqi"] = self.m_OuQiID
    mData["barrage"] = self.m_Barrage or {}
    return mData
end

function CUPCard:CheckRefresh()
    local iDayNo = get_dayno()
    local iLastDayNo = self.m_iRefreshDay
    if iDayNo - iLastDayNo >= 3 or self.m_CardConfig==0 then
        self:UPRefreshPartner()
    end
end

function CUPCard:CheckOuQiTimeout()
    self:DelTimeCb("_CheckOuQiTimeout")
    self:AddTimeCb("_CheckOuQiTimeout",300*1000,function ()
        self:CheckOuQiTimeout()
    end)
    local iTime = get_time()
    self:Dirty()
    for sKey,mOuQi in pairs(self.m_OuQiList) do
        if mOuQi.time < iTime then
            self.m_OuQiList[sKey] = nil
        end
    end
end

function CUPCard:Init()
    super(CUPCard).Init(self)
    self:DelTimeCb("auto_barrage")
    self:AddTimeCb("auto_barrage",self:GetConfigValue("auto_barrage"),function ()
        self:AutoBarrage()
    end)
end

function CUPCard:GetWuHunData()
    local res = require "base.res"
    return res["daobiao"]["partner"]["wuhun_card"]
end

function CUPCard:UPRefreshPartner()

    self:Dirty()
    self.m_iRefreshDay = get_dayno()
    self.m_mRefreshPartner = {}
    local mWuHunData = self:GetWuHunData()
    local res = require "base.res"
    local mInfo = res["daobiao"]["partner"]["upcard_config"]
    local mTimeCard = mInfo["time"]
    local iNowDay = get_dayno()
    self.m_CardConfig = 0
    local mCardConf
    --先从限时获取
    for sid,mData in pairs(mTimeCard) do
        local iStartDay = get_dayno(mData.openday.start)
        if iNowDay == iStartDay then
            self.m_CardConfig = sid
            mCardConf = mData
        end
    end

    -- 再从普通获取
    if self.m_CardConfig == 0 then
        local mCommon = mInfo.common
        local keyslist = extend.Table.keys(mCommon)
        local iMax = extend.Array.max(keyslist)
        local iMin = extend.Array.min(keyslist)
        local iChoose = math.max(iMin,self.m_LastChooseCommon+1)
        if iChoose > iMax then
            iChoose = iMin
        end
        for i=iChoose+1,iMax do
            if  mCommon[i] then
                iChoose = i
                break
            end
        end

        self.m_CardConfig = iChoose
        self.m_LastChooseCommon = iChoose
        mCardConf = mCommon[iChoose]
    end

    local mCardInfo = self:GetUPCardInfo(mCardConf.group)
    for iRare,mData in pairs(mCardInfo) do
        local mPartner = mData["partnerlist"]
        local iType = extend.Random.random_choice(mPartner)
        self.m_mRefreshPartner[iRare] = iType
    end
end

function CUPCard:GetUPCardInfo(sid)
    local res = require "base.res"
    return res["daobiao"]["partner"]["upcard_info"][sid]
end

function CUPCard:UpCardConf(uid)
    local mData
    local res = require "base.res"
    local mConf = res["daobiao"]["partner"]["upcard_config"]
    if uid >10000 then
        mData = mConf.time[uid]
    else
        mData = mConf.common[uid]
    end
    return mData
end


function CUPCard:GetPartnerUP()
    local mType = {}
    for iRare,iType in pairs(self.m_mRefreshPartner) do
        table.insert(mType,iType)
    end
    return mType
end


function CUPCard:GetRarePartnerUP(iRare)
    return self.m_mRefreshPartner[iRare]
end

function CUPCard:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        local iDayNo = get_dayno()
        local iLastDayNo = self.m_iRefreshDay or 0
        if iDayNo - iLastDayNo >= 3 then
            self:UPRefreshPartner()
        end
    end
end

function CUPCard:BarrageSend(oPlayer,mData)
    local sType = mData["type"]
    local sContent = mData["content"]
    local bValid = mData["valid"] or false
    local iPid = oPlayer.m_iPid
    local mData = {
        type = sType,
        send_id = iPid,
        content = sContent,
    }
    self.m_iLastTime = get_time()
    local oInterfaceMgr = global.oInterfaceMgr
    oInterfaceMgr:SendBarrage(mData)
    if bValid then
        self:Dirty()
        table.insert(self.m_Barrage, {
            pid = iPid,
            content = sContent,
            time = get_time(),
            })
    end
    if #self.m_Barrage > MAX_BARRAGE then
        self:Dirty()
        table.remove(self.m_Barrage, 1)
    end
end

function CUPCard:GetBarrageData()
    local res = require "base.res"
    return res["daobiao"]["barrage"]
end

function CUPCard:RandBarrage()
    local idx = math.random(1, MAX_BARRAGE)
    return self.m_Barrage[idx]
end

function CUPCard:AutoBarrage()
    local oInterfaceMgr = global.oInterfaceMgr
    local oWorldMgr = global.oWorldMgr
    local iType = gamedefines.INTERFACE_TYPE.BARRAGE_TYPE
    local mPlayers = oInterfaceMgr:GetFacePlayers(iType)
    if table_count(mPlayers) <= 0 then
        self:DelTimeCb("auto_barrage")
        return
    end
    self:AddTimeCb("auto_barrage",self:GetConfigValue("auto_barrage"),function ()
        self:AutoBarrage()
    end)
    local iCurTime = get_time()
    local iLimit = math.max(1,self:GetConfigValue("auto_barrage"))
    if self.m_iLastTime + iLimit > iCurTime then
        return
    end
    if oWorldMgr:IsClose("draw_card") then
        return
    end
    self.m_iLastTime = iCurTime
    local mData = self:RandBarrage()
    if not mData then
        mData = self:GetBarrageData()
        mData = mData[math.random(#mData)]
    end
    local sContent = mData["content"]
    local mData = {
        type = "partner",
        send_id = 0,
        content = sContent,
    }
    oInterfaceMgr:SendBarrage(mData)
end

function CUPCard:EnterInterface(oPlayer,iType)
    local oInterfaceMgr = global.oInterfaceMgr
    local iType = 1
    local mPlayers = oInterfaceMgr:GetFacePlayers(iType)
    local iPid = oPlayer.m_iPid
    if table_count(mPlayers) == 1 and mPlayers[iPid] then
        self:DelTimeCb("auto_barrage")
        self:AddTimeCb("auto_barrage",self:GetConfigValue("auto_barrage"),function ()
            self:AutoBarrage()
        end)
    end
end

function CUPCard:CloseInterface(oPlayer,iType)
    local oInterfaceMgr = global.oInterfaceMgr
    local mPlayers = oInterfaceMgr:GetFacePlayers(iType)
    if table_count(mPlayers) <= 0 then
        self:DelTimeCb("auto_barrage")
    end
end

function CUPCard:CreateOuQi(oPlayer)
    if self.m_OuQiID >= 10000000 then
        self.m_OuQiID = 0
    end
    self:Dirty()
    self.m_OuQiID = self.m_OuQiID + 1
    local mData = {
    pid = oPlayer:GetPid(),
    left = 5,
    plist = {},
    time = get_time() + 2*3600,
    }
    self.m_OuQiList[db_key(self.m_OuQiID)] = mData
    local oChatMgr = global.oChatMgr
    local msg = self:GetConfigValue("ouqi_text")
    local sText=string.format("{link12,%d,'%s'}",self.m_OuQiID,msg)
    --oChatMgr:HandleSysChat(sText)
    oChatMgr:SendWOrldChat(oPlayer,sText)
end


function CUPCard:GetOuQi(oPlayer,oid)
    local sKey = db_key(oid)
    local oNotifyMgr = global.oNotifyMgr
    local mOuQi = self.m_OuQiList[sKey]
    if not mOuQi then
        oNotifyMgr:Notify(oPlayer:GetPid(),"欧气已经消散，请等待下次领取~~")
        return
    end
    self:Dirty()
    if mOuQi.time < get_time() then
        self.m_OuQiList[sKey] = nil
        oNotifyMgr:Notify(oPlayer:GetPid(),"欧气已经消散，请等待下次领取~~")
        return
    end
    if extend.Array.member(mOuQi.plist,oPlayer:GetPid()) then
        oNotifyMgr:Notify(oPlayer:GetPid(),"你已经获取过该冒险者分享的欧气，无法再次领取~")
        return
    end
    if oPlayer.m_oStateCtrl:GetState(1003) then
        oNotifyMgr:Notify(oPlayer:GetPid(),"你已经存在欧气的祝福，将欧气留给其他冒险者吧")
        return
    end
    if oPlayer.m_oToday:Query("getOuQi",0) > 10 then
        oNotifyMgr:Notify(oPlayer:GetPid(),"你今天获取欧气的已满，请明天再来获取吧~~")
        return
    end
    mOuQi.left = mOuQi.left - 1
    if mOuQi.left <= 0 then
        self.m_OuQiList[sKey] = nil
    else
        table.insert(mOuQi.plist,oPlayer:GetPid())
    end
    oPlayer.m_oToday:Add("getOuQi",1)
    oPlayer.m_oStateCtrl:AddState(1003,{time=2*3600})
    oNotifyMgr:Notify(oPlayer:GetPid(),"成功领取2小时欧气，快去进行招募吧")
end

--------------------------------抽卡--------------------------------------
function CUPCard:IsClose(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if oWorldMgr:IsClose("draw_card") then
        oNotifyMgr:Notify(iPid, "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return true
    end

    return false
end

function CUPCard:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("draw_card", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

--高级抽卡
function CUPCard:DrawWuHunCard(oPlayer, mArgs)
    mArgs = mArgs or {}
    local iShape = mArgs["sp_item"] or 0
    local iDrawCnt = mArgs["card_cnt"] or 1
    if not self:ValidDrawWuHunCard(oPlayer, iDrawCnt) then
        return
    end
    if iDrawCnt > 1 then
        self:MultiDrawWuHunCard(oPlayer, iDrawCnt, mArgs)
        return
    end
    if iShape == 0 and self:FreeDrawWuHun(oPlayer, iDrawCnt, mArgs) then
        return
    end

    if iShape > 0 then
        self:DoWuHunSSRCard(oPlayer, iDrawCnt, mArgs)
    else
        self:DoWuHunCommonCard(oPlayer, iDrawCnt, mArgs)
    end
end

function CUPCard:FreeDrawWuHun(oPlayer, iDrawCnt, mArgs)
    if oPlayer.m_oActiveCtrl:GetData("free_wuhun") <= get_time() then
        mArgs["sp_item"] = 0
        local iCD = self:GetConfigValue("free_wuhun") or 24 * 60 * 60
        oPlayer.m_oActiveCtrl:SetData("free_wuhun", get_time() + iCD)
        self:DoWuHunCard(oPlayer,iDrawCnt,mArgs)
        self:OpenDrawCardUI(oPlayer)
        return true
    end
    return false
end

function CUPCard:MultiDrawWuHunCard(oPlayer, iDrawCnt, mArgs)
    local iMulCost = self:GetWuHunMultiGoldCoin(oPlayer, iDrawCnt)
    if oPlayer:ValidGoldCoin(iMulCost) then
        oPlayer:ResumeGoldCoin(iMulCost, "王者招募",{cancel_tip = 1, cancel_show =1})
        self:DoWuHunCard(oPlayer,iDrawCnt,mArgs)
        self:OpenDrawCardUI(oPlayer)
    end
end

function CUPCard:ValidDrawWuHunCard(oPlayer, iDrawCnt)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if iDrawCnt > 5 then
        return false
    end
    if self:IsBanShu() then
        local iDrawed = oPlayer.m_oToday:Query("upcard_WH_cnt",0)
        if iDrawed >= 10 then
            oNotifyMgr:Notify(iPid,"每天只能招募10次")
            return false
        end
    end
    if iDrawCnt > 1 then
        local iMulCost = self:GetWuHunMultiGoldCoin(oPlayer, iDrawCnt)
        if not oPlayer:ValidGoldCoin(iMulCost) then
            return false
        end
    end
    if oPlayer.m_oPartnerCtrl:EmptyPartnerSpace() < iDrawCnt then
        oNotifyMgr:Notify(iPid,"你的伙伴数量已满，请清理位置后再进行招募")
        return false
    end
    return true
end

function CUPCard:DoWuHunSSRCard(oPlayer, iDrawCnt, mArgs)
    mArgs = mArgs or {}
    if self:ValidDoWuHunSSRCard(oPlayer, mArgs) then
        local iShape = mArgs.sp_item
        local iPid = oPlayer:GetPid()
        local oWorldMgr = global.oWorldMgr
        local fCallback = function (mRecord,mData)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            local bSuc = mData.success
            if bSuc then
                self:DoWuHunCard(oPlayer,iDrawCnt,mArgs)
            else
                record.info("DoWuHunSSRCard: pid:%s,item:%s amount change!", iPid, iShape)
                --self:DoWuHunCommonCard(oPlayer,iDrawCnt,iUp,bDmClose)
            end
        end
        oPlayer:RemoveItemAmount(iShape,iDrawCnt,"高级抽卡", {cancel_tip = 1},fCallback)
    end
end

function CUPCard:ValidDoWuHunSSRCard(oPlayer, mArgs)
    local iShape = mArgs.sp_item or 0
    local res = require "base.res"
    local m = res["daobiao"]["partner"]["item_card"][iShape]
    if m then
        return true
    end
    return false
end

--iUp, bDmClose
function CUPCard:DoWuHunCommonCard(oPlayer, iDrawCnt, mArgs)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local sReason = "高级抽卡"
    local iPid = oPlayer:GetPid()
    -- local iGoldCoin = self:GetConfigValue("wuhun_gold_cost")
    local iShape = self:GetConfigValue("wuhun_card")
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        local bSuc = mData.success
        if not bSuc then
            local iGoldCoin = self:GetWuHunGoldCoin(oPlayer)
            if not oPlayer:ValidGoldCoin(iGoldCoin, {cancel_tip = 1}) then
                return
            end
            oPlayer:ResumeGoldCoin(iGoldCoin,sReason, {cancel_tip = 1})
            mArgs.logcost = iGoldCoin
        else
            mArgs.sp_item =iShape
        end
        self:DoWuHunCard(oPlayer, iDrawCnt, mArgs)
        self:OpenDrawCardUI(oPlayer)
    end
    oPlayer:RemoveItemAmount(iShape , iDrawCnt ,sReason, {cancel_tip = 1},fCallback)
end

--iUp, bDmClose, iShape, iLogCost
function CUPCard:DoWuHunCard(oPlayer, iDrawCnt, mArgs)
    local sReason = "高级抽卡"
    local iPid = oPlayer:GetPid()
    local lRemotePart = {}
    local mCntPartner = {}
    local iShape = mArgs.sp_item or 0
    local iUp = mArgs.up
    -- local iType, iStar = self:ChooseWuHunPartnerType(oPlayer,iShape, iUp)
    self:CreateWuHunPartners(lRemotePart, mCntPartner,oPlayer,iDrawCnt, mArgs)
    local args = {}
    if iShape ~= self:GetConfigValue("wuhun_item_card") then
        args = {normal=true}
    end
    self:GivePartners(oPlayer, lRemotePart, 2, sReason, args)
    local mGive = self:GiveMetarial(oPlayer,2,iDrawCnt)
    self:CheckSSRCard(oPlayer, lRemotePart)
    if self:IsBanShu() then
        oPlayer.m_oToday:Add("upcard_WH_cnt",iDrawCnt)
    end
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30002,iDrawCnt)
    oPlayer:AddSchedule("upcard", {cancel_tip = 1})
    global.oAchieveMgr:PushAchieve(iPid,"王者招募次数",{value=iDrawCnt})
    oPlayer.m_NotifyBarrage = 1
    record.user("partner","wuhun_card", {
        pid = iPid,
        par = lRemotePart,
        cost = mArgs.logcost or 0,
        item = iShape,
        })
    self:LogAnalyCard(oPlayer,{[iShape]=iDrawCnt},0,mCntPartner,mGive,mArgs.dm_close)
end

function CUPCard:OnDoWuHunCard(oPlayer, iDrawCnt, mArgs)
    if mArgs.sp_item == 0 or mArgs.sp_item == self:GetConfigValue("wuhun_card") then
        self:AddWuHunCardBaoDi(oPlayer, iDrawCnt, mArgs)
    end
    if mArgs.logcost and mArgs.logcost > 0 then
        oPlayer.m_oToday:Add("wuhun_draw", 1)
    end
end

function CUPCard:AddWuHunCardBaoDi(oPlayer, iDrawCnt, mArgs)
    local res = require "base.res"
    local mBaodi = oPlayer:GetWuHunBaodi()
    local iWave = mBaodi.wave
    local mData = res["daobiao"]["partner"]["wuhun_baodi"]
    if mBaodi.num <= mBaodi.count+ 1 then
        iWave = iWave + 1
        local lWave = table_key_list(mData)
        if not mData[iWave] then
            iWave = math.max(table.unpack(lWave))
        end
        mBaodi.wave = iWave
        mBaodi.num = mData[iWave].count
        mBaodi.count = 0
    else
        mBaodi.count = mBaodi.count + 1
    end
    oPlayer:SetWuHunBaodi(mBaodi)
end

function CUPCard:CreateWuHunPartners(lRemotePart, mLogPart, oPlayer,iDrawCnt, mArgs)
    local res = require "base.res"
    local mStarWeight = res["daobiao"]["partner"]["star_weight"]["wuhun"]
    for i=1, iDrawCnt do
        local iType,iStar = self:ChooseWuHunPartnerType(oPlayer,i,mArgs)
        local args = {
           star = iStar or table_choose_key(mStarWeight),
        }
        table.insert(lRemotePart, {iType, 1, args})
        mLogPart[iType] = (mLogPart[iType] or 0) + 1
    end
end

function CUPCard:CheckSSRCard(oPlayer, lPartner)
    local oNotifyMgr = global.oNotifyMgr
    -- 欧气加成,SSR 发公告
    lPartner = lPartner or {}
    for _, m in ipairs(lPartner) do
        local iType = m[1]
        local mPtnData = loadpartner.GetPartnerData(iType)
        if mPtnData.rare == 4 then
            self:CreateOuQi(oPlayer)
            local sMsg = self:GetConfigValue("ssr_text")
            sMsg = string.gsub(sMsg,"$PLAYER",{["$PLAYER"]=oPlayer:GetName()})
            sMsg = string.gsub(sMsg,"$PARTNER",mPtnData.name)
            oNotifyMgr:SendPrioritySysChat("draw_card",sMsg,1)
        end
    end
end

--普通抽卡
function CUPCard:DrawWuLingCard(oPlayer, iDrawCnt, bDmClose)
    local sReason = "普通抽卡"
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr

    local iPid = oPlayer:GetPid()
    local iShape = self:GetConfigValue("wuling_card")
    local iShapeCnt = oPlayer:GetItemAmount(iShape)
    if iShapeCnt <= 0 then
        oNotifyMgr:Notify(iPid,"勇者契约不足")
        return
    end
    iDrawCnt = math.min(5, iShapeCnt)
    if not self:ValidDrawWuLingCard(oPlayer, iDrawCnt) then
        return
    end
    local fCallback = function (mRecord,mData)
        local bSuc = mData.success
        if not bSuc then
            oNotifyMgr:Notify(iPid,"勇者契约不足")
            return
        end
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        self:TrueDrawWuLingCard(oPlayer,iShape,iDrawCnt)
    end
    oPlayer:RemoveItemAmount(iShape, iDrawCnt, sReason, {cancel_tip = 1},fCallback)
end

function CUPCard:TrueDrawWuLingCard(oPlayer,iShape,iDrawCnt)
    local sReason = "普通抽卡"
    local lRemotePart ={}
    local mCntPartner = {}
    self:CreateWuLingPartners(lRemotePart, mCntPartner, oPlayer, iDrawCnt)
    self:GivePartners(oPlayer, lRemotePart, 1, sReason, {normal=true})
    local mGive = self:GiveMetarial(oPlayer,1,iDrawCnt)
    if self:IsBanShu() then
        oPlayer.m_oToday:Add("upcard_WL_cnt",iDrawCnt)
    end
    oPlayer:AddSchedule("upcard", {cancel_tip = 1})
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30002,iDrawCnt)
    self:LogAnalyCard(oPlayer,{[iShape]=iDrawCnt},0,mCntPartner,mGive,bDmClose)
end

function CUPCard:ValidDrawWuLingCard(oPlayer, iDrawCnt)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local iShape = self:GetConfigValue("wuling_card")
    --[[
    local iShapeCnt = oPlayer:GetItemAmount(iShape)
    if iShapeCnt <= 0 then
        oNotifyMgr:Notify(iPid,"勇者契约不足")
        return false
    end
    ]]
    if self:IsBanShu() then
        local iRemainCnt = 10 - iDrawCnt - oPlayer.m_oToday:Query("upcard_WL_cnt",0)
        if iRemainCnt <= 0  then
            oNotifyMgr:Notify(iPid,"每天只能招募10次")
            return false
        end
    end
    if oPlayer.m_oPartnerCtrl:EmptyPartnerSpace() < iDrawCnt then
        oNotifyMgr:Notify(iPid,"你的伙伴数量已满，请清理位置后再进行招募")
        return false
    end
    return true
end

function CUPCard:IsBanShu()
    local sType = skynet.getenv("server_type")
    if sType == "banshu" then
        return true
    end
    return false
end

function CUPCard:CreateWuLingPartners(lRemotePart, mLogPart, oPlayer, iDrawCnt)
    local res = require "base.res"
    local mStarWeight = res["daobiao"]["partner"]["star_weight"]["wuling"]
    for i =1,iDrawCnt do
        local iType, iStar = self:ChooseWuLingPartnerType(oPlayer)
        local mArgs = {
            star = iStar or table_choose_key(mStarWeight)
        }
        table.insert(lRemotePart, {iType,1, mArgs})
        local mLog = {
            pid = oPlayer:GetPid(),
            par = iType,
        }
        record.user("partner","wuling_card",mLog)
        local iPartCnt = mLogPart[iType] or 0
        mLogPart[iType] = iPartCnt + 1
    end
end

function CUPCard:GivePartners(oPlayer, lRemotePart, iType, sReason, mArgs)
    oPlayer.m_oPartnerCtrl:Forward( "C2GSDrawCard", oPlayer:GetPid(), {
        type = iType,
        reason = sReason,
        partners = lRemotePart,
        args = mArgs,
        })
end

function CUPCard:ChooseWuLingPartnerType(oPlayer, iCnt)
    local res = require "base.res"
    local iRankCard = oPlayer.m_oActiveCtrl:GetData("wuling_rank_card", 0) + 1
    local mRankCard = res["daobiao"]["partner"]["wuling_rank_card"][iRankCard]
    if mRankCard then
        oPlayer.m_oActiveCtrl:SetData("wuling_rank_card", iRankCard)
        local lPartnerId = mRankCard.partner_list
        local iType = lPartnerId[math.random(#lPartnerId)]
        return iType, mRankCard.star
    end
    local mWuLing = res["daobiao"]["partner"]["wuling_card"]
    local mRatio = {}
    for iNo,mData in pairs(mWuLing) do
        mRatio[iNo] = mData["ratio"]
    end
    local iNo = table_choose_key(mRatio)
    local mData = mWuLing[iNo]
    local mPartner = mData["partner_list"]
    local iType = mPartner[math.random(#mPartner)]
    oPlayer.m_oActiveCtrl:SetData("wuling_rank_card", iRankCard)
    return iType
end

function CUPCard:GiveMetarial(oPlayer,iFlag,iCnt)
    local lType = self:GetMetarialTypes()
    local mGive = {}
    if #lType > 0 then
        for i = 1, iCnt do
            local oGive = loaditem.Create(1016)
            local iPos = math.random(1,4)
            local iSetType = lType[math.random(#lType)]
            local iStar
            if iFlag == 1 then
                -- iItem = oHuodong:GetConfigValue("wuling_metarial")
                iStar = 1
            else
                iStar = 2
                -- iItem = oHuodong:GetConfigValue("wuhun_metarial")
            end
            oGive:SetData("star", iStar)
            oGive:SetData("type", iSetType)
            oGive:SetData("pos", iPos)
            oGive:SetAmount(1)
            local SID = oGive:GetRewardSID()
            oPlayer:RewardItem(oGive,"抽卡赠送", {cancel_tip = 1})
            mGive[SID] = mGive[SID] or 0
            mGive[SID] = mGive[SID] + 1
        end
    else
        record.warning("CUPCard:GiveMetarial %s", oPlayer:GetPid())
    end
    return mGive
end

function CUPCard:GetMetarialTypes()
    local res = require "base.res"
    local mTypeData = res["daobiao"]["partner_item"]["equip_set"]
    local lType = {}
    for iType, m in pairs(mTypeData) do
        if m.set_type == 0 then
            table.insert(lType, iType)
        end
    end
    return lType
end

function CUPCard:GetPartypeByItem(oPlayer, iShape)
    local res = require "base.res"
    local mWeight = res["daobiao"]["partner"]["item_card"][iShape]
    if mWeight then
        local mData = extend.Array.weight_choose(mWeight, "weight")
        if mData then
            local lPartnerId = mData.partner_list
            return lPartnerId[math.random(#lPartnerId)]
        end
    end
end

function CUPCard:GetPartypeByBaoDi(oPlayer, iCnt, mArgs)
    local mBaodi = oPlayer:GetWuHunBaodi()
    local iCount = mBaodi.count + 1
    if iCount >= mBaodi.num then
            local res = require "base.res"
            local iWave = mBaodi.wave
            local mData = res["daobiao"]["partner"]["wuhun_baodi"][iWave]
            if mData then
                local iType = self:RandBaodiType(mData)
                if iType then
                    self:OnDoWuHunCard(oPlayer, iCnt, mArgs)
                    return iType
                end
            end
    end
    return nil
end

function CUPCard:RandBaodiType(mData)
    local rate = mData.rate
    local iSSRRate = rate.SSR
    local lPartnerId = {}
    if math.random(10000) <= iSSRRate then
        lPartnerId = mData.SSR
    else
        lPartnerId = mData.SR
    end
    return lPartnerId[math.random(#lPartnerId)]
end

function CUPCard:GetWuHunRankDrawType(oPlayer, iCnt, mArgs)
    local res = require "base.res"
    local iRankCard = oPlayer.m_oActiveCtrl:GetData("wuhun_rank_card", 0) + 1
    local mRankCard = res["daobiao"]["partner"]["wuhun_rank_card"][iRankCard]
    if mRankCard then
        oPlayer.m_oActiveCtrl:SetData("wuhun_rank_card", iRankCard)
        local lPartnerId = mRankCard.partner_list
        local iType = lPartnerId[math.random(#lPartnerId)]
        self:OnDoWuHunCard(oPlayer, iCnt, mArgs)
        return iType, mRankCard.star
    end
end

function CUPCard:ChooseWuHunPartnerType(oPlayer,iCnt, mArgs)
    local res = require "base.res"
    mArgs = mArgs or {}
    local iSid = mArgs.sp_item
    local iUp = mArgs.up or 0
    local iStar
    local iType = self:GetPartypeByItem(oPlayer, iSid)
    if iType then
        return iType
    end
    iType,iStar = self:GetWuHunRankDrawType(oPlayer, iCnt, mArgs)
    if iType then
        return iType, iStar
    end
    local iRankCard = oPlayer.m_oActiveCtrl:GetData("wuhun_rank_card", 0) + 1
    oPlayer.m_oActiveCtrl:SetData("wuhun_rank_card", iRankCard)
    iType = self:GetPartypeByBaoDi(oPlayer, 1, mArgs)
    if iType then
        return iType
    end
    local mWuHun = res["daobiao"]["partner"]["wuhun_card"]
    local mOuQiInfo = res["daobiao"]["partner"]["ouqi"]
    local mRatio = {}
    if oPlayer.m_oStateCtrl:GetState(1003) then
        for iNo,mData in pairs(mOuQiInfo) do
            mRatio[iNo] = mData["ratio"]
        end
    else
        for iNo,mData in pairs(mWuHun) do
            mRatio[iNo] = mData["ratio"]
        end
    end
    local iNo = table_choose_key(mRatio)
    local mData = mWuHun[iNo]
    local iRare = mData["rare"]
    local mPartner = mData["partner_list"]
    local mPartnerRatio = {}
    if bUP == 1 then
        local iType = self:GetRarePartnerUP(iRare)
        if iType then
            local iCnt = #mPartner - 1
            if iCnt == 0 then
                mPartnerRatio[iType] = 100
            else
                mPartnerRatio[iType] = 25

                local iRatio = math.floor(100 / iCnt)
                for _,k in pairs(mPartner) do
                    if k ~= iType then
                        mPartnerRatio[k] = iRatio
                    end
                end
            end
            local iType = table_choose_key(mPartnerRatio)
            self:OnDoWuHunCard(oPlayer, iCnt, mArgs)
            return iType
        end
    end
    self:OnDoWuHunCard(oPlayer, iCnt, mArgs)
    return mPartner[math.random(#mPartner)]
end

function CUPCard:ValidOpenDrawCardUI(oPlayer)
    if not oPlayer:IsSingle() then
        oPlayer:NotifyMessage("请先暂离队伍")
        return false
    end
    if oPlayer:GetNowWar() then
        oPlayer:NotifyMessage("正在战斗")
        return false
    end
    return true
end

function CUPCard:OpenDrawCardUI(oPlayer)
    oPlayer:Send("GS2CDrawCardUI",{
    })
end

function CUPCard:GetWuHunGoldCoin(oPlayer)
    if oPlayer:IsZskVip() then
        return 150
    end
    local res = require "base.res"
    local iDailyDraw = oPlayer.m_oToday:Query("wuhun_draw", 0) + 1
    local mReduce = res["daobiao"]["partner"]["wuhun_reduce"]
    if mReduce[iDailyDraw] then
        return mReduce[iDailyDraw].cost
    else
        local lDraw = table_key_list(mReduce)
        local iMaxDraw = math.max(table.unpack(lDraw))
        if iDailyDraw > iMaxDraw then
            return mReduce[iMaxDraw].cost
        else
            return 200
        end
    end
end

function CUPCard:GetWuHunMultiGoldCoin(oPlayer, iDrawCnt)
    iDrawCnt = iDrawCnt or 5
    assert(iDrawCnt > 0)
    if oPlayer:IsZskVip() then
        return iDrawCnt * 150
    end
    local iCost = 0
    local res = require "base.res"
    local iDailyDraw = oPlayer.m_oToday:Query("wuhun_draw", 0) + 1
    local mReduce = res["daobiao"]["partner"]["wuhun_reduce"]
    for i=1, iDrawCnt do
        local iDraw = iDailyDraw + i
        if mReduce[iDraw] then
            iCost = iCost + mReduce[iDraw].cost
        else
            local lDraw = table_key_list(mReduce)
            local iMaxDraw = math.max(table.unpack(lDraw))
            if iDraw > iMaxDraw then
                iCost = iCost + mReduce[iMaxDraw].cost
            else
                iCost = iCost + 200
            end
        end
    end
    return iCost
end

function CUPCard:GetWuHunBaodiRemain(oPlayer)
    local mBaodi = oPlayer:GetWuHunBaodi()
    return mBaodi.num - mBaodi.count
end

function CUPCard:CloseDrawCardUI(oPlayer)
    local oSceneMgr = global.oSceneMgr
    local iSceneId = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local mPos = oPlayer.m_oActiveCtrl:GetNowPos()
    oSceneMgr:ReEnterScene(oPlayer)
end

function CUPCard:ValidCloseDrawCardUI(oPlayer)
    if oPlayer:GetNowWar() then
        return false
    end

    return true
end


function CUPCard:LogAnalyCard(oPlayer,mCostItem,iGoldCoin,mPartner,mItem,bDmClose)
    local mLog = oPlayer:GetPubAnalyData()
    mLog["consume_detail"] = analy.datajoin(mCostItem)
    mLog["consume_crystal"] = iGoldCoin
    mLog["gain_partner"] = analy.datajoin(mPartner)
    mLog["gain_item"] = analy.datajoin(mItem)
    mLog["is_dm_close"] = bDmClose
    analy.log_data("recruit",mLog)
end

function CUPCard:TestOP(oPlayer,iFlag,...)
    local args = {...}
    local oNotifyMgr = global.oNotifyMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    if iFlag == 100 then
        oChatMgr:HandleMsgChat(oPlayer,"101-重置up活动")
        oChatMgr:HandleMsgChat(oPlayer,"102-设定欧气剩余为1 oid")
        oChatMgr:HandleMsgChat(oPlayer,"103-给予欧气BUFF")
        oChatMgr:HandleMsgChat(oPlayer,"104-移除欧气BUFF")
        oChatMgr:HandleMsgChat(oPlayer,"105-角色生成欧气")
        oChatMgr:HandleMsgChat(oPlayer,"106-设定今天领过欧气次次数")
        oChatMgr:HandleMsgChat(oPlayer,"107-清空弹幕")
    elseif iFlag == 101 then
        self:UPRefreshPartner()
    elseif lFlag == 102 then
        local sKey = db_key(tonumber(args[1]))
        local mOuQi = self.m_OuQiList[sKey]
        if mOuQi then
            mOuQi.left  = 1
        end
    elseif iFlag == 103 then
        oPlayer.m_oToday:Add("getOuQi",1)
        oPlayer.m_oStateCtrl:AddState(1003,{time=2*3600})
        oNotifyMgr:Notify(oPlayer:GetPid(),"成功领取2小时欧气，快去进行招募吧")
        oPlayer:DoSave()
    elseif iFlag == 104 then
        oPlayer.m_oStateCtrl:RemoveState(1003)
    elseif iFlag == 105 then
        self:CreateOuQi(oPlayer)
    elseif iFlag == 106 then
        local iNum = tonumber(args[1])
        oPlayer.m_oToday:Set("getOuQi",iNum)
    elseif iFlag == 107 then
        self:Dirty()
        self.m_Barrage = {}
        oPlayer:NotifyMessage("弹幕已清除")
    elseif iFlag == 108 then
        local res = require "base.res"
        local mData = res["daobiao"]["partner"]["wuhun_baodi"]
        local mCount = oPlayer.m_oActiveCtrl:GetData("wuhun_baodi_count", {})
        local mBaodi = oPlayer.m_oActiveCtrl:GetData("wuhun_baodi", {})
        for idx , m in pairs(mData) do
            local iCnt =mCount[idx] or 0
            local iBaodi = mBaodi[idx] or 15
            oChatMgr:HandleMsgChat(oPlayer,string.format("id:%s保底次数:#O%s#n,抽卡次数:#O%s#n", idx, iBaodi, iCnt))
        end
        oPlayer:NotifyMessage("操作完成")
    elseif iFlag == 999 then
        local iVal = self:GetConfigValue("auto_barrage")
        oChatMgr:HandleMsgChat(oPlayer,string.format("auto_barrage %d",iVal))
    end
end

function CUPCard:GetMaxHireTimes(iPatnerId)
    local mInfo = res["daobiao"]["partner"]["partner_hire"]
    return mInfo[iPatnerId]["max_times"]
end

function CUPCard:GetUnLockGrade(iPatnerId,iHireTimes)
    local mInfo = res["daobiao"]["partner"]["hire_config"]
    local iMax = 0
    local mMax = {}
    for _,info in pairs(mInfo) do
        if info["parid"] == iPatnerId then
            if iHireTimes == info["times"] then
                return info["level"],info["coin_cost"],info["arena_cost"]
            end
            if iMax < info["times"] then
                iMax = info["times"]
                mMax = info
            end
        end
    end
    return mMax["level"],mMax["coin_cost"],mMax["arena_cost"]
end

function CUPCard:HirePartner(oPlayer,iPatnerId)
    local iHireTimes = oPlayer.m_oHuodongCtrl:GetPartnerHireTime(iPatnerId)
    local iMaxTimes = self:GetMaxHireTimes(iPatnerId)
    if iMaxTimes ~= -1 and iHireTimes >= iMaxTimes then
        return
    end
    local iUnLockGrade,iCoin,iArena = self:GetUnLockGrade(iPatnerId,iHireTimes+1)
    if not iUnLockGrade then
        return
    end
    if oPlayer:GetGrade() < iUnLockGrade then
        return
    end
    if iCoin > 0 then
        if not oPlayer:ValidCoin(iCoin) then
            return
        end
        oPlayer:ResumeCoin(iCoin,"招募")
    end
    if iArena > 0 then
        if not oPlayer:ValidArenaMedal(iArena) then
            return
        end
        oPlayer:ResumeArenaMedal(iArena,"招募")
    end
    oPlayer.m_oPartnerCtrl:GivePartner({{iPatnerId,1}},"招募",{normal=true})
    oPlayer.m_oHuodongCtrl:HirePartner(iPatnerId)
    global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,"伙伴招募次数",{value=1})
    record.user("hirepartner","upcard",{pid=oPlayer.m_iPid,grade = oPlayer:GetGrade(),times=iHireTimes+1,coin=iCoin,arena=iArena,})
end
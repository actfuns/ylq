--import module
local skynet = require "skynet"
local global = require "global"
local res = require "base.res"
local record = require "public.record"
local colorstring = require "public.colorstring"

local shareobj = import(lualib_path("base.shareobj"))
local analy = import(lualib_path("public.dataanaly"))
local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item.loaditem"))


CPlayerActiveCtrl = {}
CPlayerActiveCtrl.__index = CPlayerActiveCtrl
inherit(CPlayerActiveCtrl, datactrl.CDataCtrl)

function GiveChongHua(oPlayer)
    oPlayer:GivePartner({{302,1}},"新手指引")
end

function GiveItem1(oPlayer)
    oPlayer:GiveItem({{14001,3}},"新手指引",{cancel_tip=true})
end

local GuidanceEvent = {
    ["N1Guide_GetPartner302"] = GiveChongHua,
    ["N1Guide_Get3Item14001"] = GiveItem1,
}

function CPlayerActiveCtrl:New(pid)
    local o = super(CPlayerActiveCtrl).New(self, {pid = pid})
    o.m_mNowSceneInfo = nil
    o.m_mNowWarInfo = nil
    o.m_oSceneShareObj = nil
    return o
end

function CPlayerActiveCtrl:Release()
    super(CPlayerActiveCtrl).Release(self)
    if self.m_oSceneShareObj then
        baseobj_safe_release(self.m_oSceneShareObj)
    end
end

function CPlayerActiveCtrl:Load(mData)
    local mData = mData or {}
    local mRoleInitProp = res["daobiao"]["roleprop"][1]

    self:SetData("scene_info", mData.scene_info)
    self:SetData("hp", mData.hp)
    self:SetData("sp", mData.sp)
    self:SetData("coin",mData.coin or 0)
    self:SetData("exp",mData.exp or mRoleInitProp.exp)
    self:SetData("chubeiexp",mData.chubeiexp or 0)
    self:SetData("energy", mData.energy or mRoleInitProp.energy)
    self:SetData("disconnect_time", mData.disconnect_time or get_time())
    self:SetData("coin_over",mData.coin_over or 0)
    self:SetData("skill_point",mData.skill_point or {})
    self:SetData("equip_strength",mData.equip_strength or {})
    self:SetData("auto_skill",mData.auto_skill or 0)
    self:SetData("auto_skill_switch",mData.auto_skill_switch or 0)
    self:SetData("arena",mData.arena or 0)
    self:SetData("org_offer",mData.org_offer or 0)
    self:SetData("medal",mData.medal or 0)
    self:SetData("pt_curlv",mData.pt_curlv or 1)
    self:SetData("pt_maxlv",mData.pt_maxlv or 1)
    self:SetData("pt_tglist",mData.pt_tglist or {})
    self:SetData("treasure_totaltimes",mData.treasure_totaltimes or 0)
    self:SetData("treasure_weektimes",mData.treasure_weektimes or 0)
    self:SetData("teachtask_progress",mData.teachtask_progress or {})
    self:SetData("guidanceinfo",mData.guidanceinfo or {})
    self:SetData("trapmine_point", mData.trapmine_point or 0)
    self:SetData("trapmine_point_day", mData.trapmine_point_day or get_dayno())
    self:SetData("login_time", mData.login_time or 0)
    self:SetData("count_login_day", mData.count_login_day or 0)
    self:SetData("login_rewarded_day", mData.login_rewarded_day or 0)
    self:SetData("wuling_first_card", mData.wuling_first_card or 0)
    self:SetData("wuhun_first_card", mData.wuhun_first_card or 0)
    self:SetData("active",mData.active or 0)
    self:SetData("skin",mData.skin or 0)
    self:SetData("upgrade_time",mData.upgrade_time or 0)
    self:SetData("achieve_fix",mData.achieve_fix or 0)
    self:SetData("npc_fight", mData.npc_fight or {})
    self:SetData("offset",mData.offset or 0)
    self:SetData("follow_partner", mData.follow_partner or {})
    self:SetData("pk_faildtime",mData.pk_faildtime or 0)
    self:SetData("terra_partner",mData.terra_partner or {})
    self:SetData("travel_score", mData.travel_score or 0)
    self:SetData("YJFirstInfo",mData.yj_firstinfo or {})
    self:SetData("YJGuidanceReward",mData.yj_guidancereward or 0)
    self:SetData("yj_fitflag",mData.yj_fitflag or 0)
    self:SetData("endlesspve_first", mData.endlesspve_first or 0)
    self:SetData("wuhun_rank_card", mData.wuhun_rank_card or 0)
    self:SetData("ban_time", mData.ban_time or 0)
    self:SetData("test_attr", mData.test_attr or {})
    self:SetData("lasttask",mData.lasttask or 0)
    self:SetData("daily_sign", mData.daily_sign or {})
    self:SetData("wuling_rank_card", mData.wuling_rank_card or 0)
    self:SetData("initrolename",mData.initrolename or 0)
    self:SetData("sevenday_gift", mData.sevenday_gift or {})
    self:SetData("shop_data",mData.shop or {})
    self:SetData("free_wuhun", mData.free_wuhun or get_time())
    self:SetData("wuhun_baodi", mData.wuhun_baodi or {}) --2018/1/31 去掉暗保底规则
    self:SetData("wuhun_baodi_count", mData.wuhun_baodi_count or {})
    self:SetData("energy_recoverytime",mData.energy_recoverytime)
    self:SetData("breed_val", mData.breed_val or 0)
    self:SetData("breed_rwd", mData.breed_rwd or 0)
    self:SetData("game_push",mData.game_push or {})
    self:SetData("convoy_refresh",mData.convoy_refresh or 0)
    self:SetData("trapmine_offline", mData.trapmine_offline or {})
    self:SetData("disconnect",mData.disconnect or 0)
    self:SetData("onlinegift_rewardtimes",mData.onlinegift_rewardtimes or {})
    self:SetData("shape_list", mData.shape_list or {})
    self:SetData("lingli",mData.lingli or {})
    self:SetData("wuhun_card_baodi", mData.wuhun_card_baodi or {})
    self:SetData("endlesspve_info", mData.endlesspve_info or {})
    self:SetData("hunt_times",mData.hunt_times or 0)
    self:SetData("grade_gift", mData.grade_gift or {})
    self:SetData("one_RMB_gift", mData.one_RMB_gift or {})
    self:SetData("hd_add_charge", mData.hd_add_charge or {})
    self:SetData("hd_day_charge", mData.hd_day_charge or {})
end

function CPlayerActiveCtrl:Save()
    local mData = {}

    mData.scene_info = self:GetData("scene_info")
    mData.hp = self:GetData("hp")
    mData.sp = self:GetData("sp")
    mData.coin = self:GetData("coin")
    mData.exp = self:GetData("exp")
    mData.chubeiexp = self:GetData("chubeiexp")
    mData.energy = self:GetData("energy")
    mData.disconnect_time = self:GetData("disconnect_time")
    mData.coin_over = self:GetData("coin_over")
    mData.skill_point = self:GetData("skill_point")
    mData.equip_strength = self:GetData("equip_strength",{})
    mData.auto_skill = self:GetData("auto_skill",0)
    mData.auto_skill_switch = self:GetData("auto_skill_switch",0)
    mData.arena = self:GetData("arena",0)
    mData.org_offer = self:GetData("org_offer")
    mData.medal = self:GetData("medal",0)
    mData.pt_curlv = self:GetData("pt_curlv",1)
    mData.pt_maxlv = self:GetData("pt_maxlv",1)
    mData.pt_tglist = self:GetData("pt_tglist",{})
    mData.treasure_totaltimes = self:GetData("treasure_totaltimes",0)
    mData.treasure_weektimes = self:GetData("treasure_weektimes",0)
    mData.teachtask_progress = self:GetData("teachtask_progress",{})
    mData.guidanceinfo = self:GetData("guidanceinfo",{})
    mData.trapmine_point = self:GetData("trapmine_point")
    mData.trapmine_point_day = self:GetData("trapmine_point_day")
    mData.login_time = self:GetData("login_time")
    mData.count_login_day = self:GetData("count_login_day", 0)
    mData.login_rewarded_day = self:GetData("login_rewarded_day", 0)
    mData.wuling_first_card = self:GetData("wuling_first_card", 0)
    mData.wuhun_first_card = self:GetData("wuhun_first_card", 0)
    mData.active = self:GetData("active",0)
    mData.skin = self:GetData("skin",0)
    mData.upgrade_time = self:GetData("upgrade_time",0)
    mData.achieve_fix = self:GetData("achieve_fix",0)
    mData.npc_fight = self:GetData("npc_fight", {})
    mData.offset = self:GetData("offset",0)
    mData.follow_partner = self:GetData("follow_partner", {})
    mData.pk_faildtime = self:GetData("pk_faildtime",0)
    mData.terra_partner = self:GetData("terra_partner",{})
    mData.travel_score = self:GetData("travel_score", 0)
    mData.yj_firstinfo = self:GetData("YJFirstInfo",{})
    mData.yj_guidancereward = self:GetData("YJGuidanceReward",0)
    mData.yj_fitflag = self:GetData("yj_fitflag", 0)
    mData.endlesspve_first = self:GetData("endlesspve_first", 0)
    mData.wuhun_rank_card = self:GetData("wuhun_rank_card", 0)
    mData.ban_time = self:GetData("ban_time")
    mData.test_attr = self:GetData("test_attr")
    mData.lasttask = self:GetData("lasttask")
    mData.daily_sign = self:GetData("daily_sign", {})
    mData.wuling_rank_card = self:GetData("wuling_rank_card", 0)
    mData.initrolename = self:GetData("initrolename",0)
    mData.sevenday_gift = self:GetData("sevenday_gift", {})
    mData.shop = self:GetData("shop_data",{})
    mData.free_wuhun = self:GetData("free_wuhun", get_time())
    mData.wuhun_baodi = self:GetData("wuhun_baodi", {}) ----2018/1/31 去掉暗保底规则
    mData.wuhun_baodi_count = self:GetData("wuhun_baodi_count", {})
    mData.energy_recoverytime = self:GetData("energy_recoverytime")
    mData.breed_val = self:GetData("breed_val", 0)
    mData.breed_rwd = self:GetData("breed_rwd", 0)
    mData.game_push = self:GetData("game_push",{})
    mData.convoy_refresh = self:GetData("convoy_refresh",0)
    mData.trapmine_offline = self:GetData("trapmine_offline", {})
    mData.disconnect = self:GetData("disconnect",0)
    mData.onlinegift_rewardtimes = self:GetData("onlinegift_rewardtimes",{})
    mData.shape_list = self:GetData("shape_list", {})
    mData.lingli = self:GetData("lingli",{})
    mData.wuhun_card_baodi = self:GetData("wuhun_card_baodi", {})
    mData.endlesspve_info = self:GetData("endlesspve_info", {})
    mData.hunt_times = self:GetData("hunt_times",0)
    mData.grade_gift = self:GetData("grade_gift", {})
    mData.one_RMB_gift = self:GetData("one_RMB_gift", {})
    mData.hd_add_charge = self:GetData("hd_add_charge", {})
    mData.hd_day_charge = self:GetData("hd_day_charge", {})
    return mData
end

function CPlayerActiveCtrl:OnLogin(oPlayer, bReEnter)
    if not bReEnter then
        self:SetData("lastlogin_time",self:GetData("login_time",0))
        self:SetData("login_time", get_time())
        self:CheckEnergy()
        self:CheckGuidanceVersion(oPlayer)
    end
    self:SetData("login_realtime",get_time())
    self:SetInfo("pk_invite_status",0)
    self:RefreshAllGamePush()
    self:RefreshShapeList(oPlayer, bReEnter)
    self:GS2CGuidanceInfo()
end

function CPlayerActiveCtrl:GetDisconnectTime()
    return self:GetData("disconnect_time")
end

function CPlayerActiveCtrl:SetDisconnectTime(iTime)
    iTime = iTime or get_time()
    self:SetData("disconnect_time", iTime)
end

function CPlayerActiveCtrl:MaxCoin(iType)
    local mCoinInfo = gamedefines.COIN_TYPE[iType]
    assert(mCoinInfo,string.format("MaxCoin %d",iType))
    return mCoinInfo.max
end

function CPlayerActiveCtrl:CoinIcon(iType)
    local mCoinInfo = gamedefines.COIN_TYPE[iType]
    assert(mCoinInfo,string.format("MaxCoin %d",iType))
    return mCoinInfo.icon or mCoinInfo.name
end

function CPlayerActiveCtrl:ValidCoin(iVal, mArgs)
    mArgs = mArgs or {}
    local iCoin = self:GetData("coin",0)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    assert(iCoin>=0,string.format("%d coin err %d", self:GetInfo("pid"), iCoin))
    assert(iVal>0,string.format("%d cost coin err %d", self:GetInfo("pid"), iVal))
    local iCoin = iCoin - oPlayer:GetFrozenMoney("coin")
    if iCoin >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "金币不足"
    end
    local bShort = mArgs.short
    if not mArgs.cancel_tip then
        if bShort then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(self:GetInfo("pid"),sTip)
        end
    end

    if not bShort then
        local oUIMgr = global.oUIMgr
        oUIMgr:GS2CShortWay(self:GetInfo("pid"),1)
    end
    return false
end

function CPlayerActiveCtrl:RewardCoin(iVal, sReason, mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    mArgs = mArgs or {}
    local iPid = self:GetInfo("pid")
    assert(iVal>0,string.format("pid:%s ,CPlayerActiveCtrl:RewardCoin err:%d", iPid, iVal))

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)

    local iMaxCoin = self:MaxCoin(gamedefines.COIN_FLAG.COIN_COIN)
    local iCoin = self:GetData("coin", 0)
    local iAddCoin = math.min(iVal, iMaxCoin - iCoin)
    local iOverCoin = math.max(0, iVal - iAddCoin)
    local iSum = iCoin + iVal
    self:LogCoin("coin",iVal,iCoin,iSum,sReason)
    self:SetData("coin", math.min(iSum, iMaxCoin))

    if oPlayer then
        if iAddCoin > 0 then
            oPlayer:PropChange("coin")
            self:AddShowKeep(1002, iAddCoin)
        end
        local sMsg
        local mNotifyArgs
        local lMessage = {}
        if iAddCoin > 0 then
            sMsg = string.format("获得了%s#amount", self:CoinIcon(gamedefines.COIN_FLAG.COIN_COIN))
            mNotifyArgs = {
                amount = iAddCoin,
            }
        end
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            if sMsg then
                table.insert(lMessage,"GS2CNotify")
            end
        end
        if sMsg and not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
        oPlayer:PushBookCondition("获得金币", {value = iVal})
    end
    if iOverCoin > 0 then
        oNotifyMgr:Notify(iPid, "你的货币已满，请及时使用")
    end
    if  iAddCoin > 0 then
        global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"累计获取金币",{value=iAddCoin})
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_COIN
        mLog["num"] = iAddCoin
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:Coin()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ResumeCoin(iVal, sReason, mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    mArgs = mArgs or {}
    local iCoin = self:GetData("coin",0)
    assert(iVal > 0 and iCoin >= iVal,string.format("pid:%s ResumeCoin err:%d, %d, %s", self:GetInfo("pid"), iCoin, iVal, sReason))

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))

    local iSum = iCoin - iVal
    self:LogCoin("coin",-iVal,iCoin,iSum,sReason)
    self:SetData("coin", iSum)

    if oPlayer then
        oPlayer:PropChange("coin")
        local lMessage = {}
        local sMsg = string.format("消耗了%s#resume", self:CoinIcon(gamedefines.COIN_FLAG.COIN_COIN))
        local mNotifyArgs = {resume = iVal}
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if  iVal > 0 then
        global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"累计消耗金币",{value=iVal})
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_COIN
        mLog["num"] = -iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:Coin()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ServerGradePlus(iVal)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    local iPlayerGrade = oPlayer:GetGrade()
    local mGlobalSetting = res["daobiao"]["global"]
    local iGnoreGrade = tonumber(mGlobalSetting.ignore_expadd_grade.value)
    local iOpenGrade = tonumber(mGlobalSetting.open_expadd_grade.value)
    if iPlayerGrade <= iGnoreGrade then
        return iVal
    end
    local iServerGrade = oWorldMgr:GetServerGrade()
    local iDownServerGrade = iServerGrade - 5
    local iMaxPlayerGrade = oWorldMgr:GetMaxPlayerGrade()
    local iAddRatio = 0
    if iPlayerGrade < iDownServerGrade then
        if iServerGrade < iOpenGrade then
            iAddRatio = 100
        else
            iAddRatio = 120
        end
    elseif iPlayerGrade < iServerGrade then
        iAddRatio = 100
    elseif iPlayerGrade < iMaxPlayerGrade then
        iAddRatio = 20
    end
    iVal = iVal * iAddRatio // 100
    return iVal
end

function CPlayerActiveCtrl:RewardExp(iVal,sReason,mArgs)
    local iExp = self:GetData("exp",0)
    mArgs = mArgs or {}
    local iPid = self:GetInfo("pid")
    assert(iVal > 0,string.format("pid:%s RewardExp err:%d, %s",iPid, iVal, sReason))
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    local iPlayerGrade = oPlayer:GetGrade()
    local iServerGrade = oWorldMgr:GetServerGrade()
    local iDownServerGrade = iServerGrade - 5
    local iMaxPlayerGrade = oWorldMgr:GetMaxPlayerGrade()
    local mGlobalSetting = res["daobiao"]["global"]
    local iGnoreGrade = tonumber(mGlobalSetting.ignore_expadd_grade.value)
    if iPlayerGrade > iGnoreGrade and iPlayerGrade >= iMaxPlayerGrade then
        if iMaxPlayerGrade >= 100 then
            oNotifyMgr:Notify(iPid,"已达到人物最大等级")
            return 0
        end
        oNotifyMgr:Notify(iPid,"已达到服务器等级+5上限，无法继续获得#exp")
        return 0
    end

    local mColor = res["daobiao"]["othercolor"]
    local mExpColor = mColor["exp"]
    if not table_in_list({"story"},sReason) then
       iVal = self:ServerGradePlus(iVal)
    end
    if iVal > 0 then
        local iSum = iExp + iVal
        self:LogCoin("exp",iVal,iExp,iSum,sReason)
        self:SetData("exp",iSum)
        oPlayer:PropChange("exp")
        local sMsg = "获得#exp#amount"
        local mNotifyArgs = {
            amount = iVal,
        }
        local lMessage = {}
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(iPid,lMessage,sMsg,mNotifyArgs)
        end
    end

    oPlayer:CheckUpGrade()
    if iVal > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["role_level_before"] = iPlayerGrade
        mLog["role_level_after"] = oPlayer:GetGrade()
        mLog["exp"] = iVal
        mLog["reason"] = sReason
        analy.log_data("RoleGainExp",mLog)
    end
    return iVal
end

function CPlayerActiveCtrl:AddChubeiExp(iVal,sReason)
    local iChubeiExp = self:GetData("chubeiexp",0)
    assert(iVal>0,string.format("%d exp err %d %d",self:GetInfo("pid"),iChubeiExp,iVal))

    local iChubeiExp = iChubeiExp + iVal
    self:SetData("chubeiexp",iChubeiExp)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    oPlayer:PropChange("chubeiexp")
end


function CPlayerActiveCtrl:SetDurableSceneInfo(iMapId, mPos)
    local m = {
        map_id = iMapId,
        pos = mPos,
    }
    self:SetData("scene_info", m)
end

function CPlayerActiveCtrl:GetDurableSceneInfo()
    return self:GetData("scene_info")
end

function CPlayerActiveCtrl:GetNowScene()
    local m = self.m_mNowSceneInfo
    if not m then
        return
    end
    local oSceneMgr = global.oSceneMgr
    return oSceneMgr:GetScene(m.now_scene)
end

function CPlayerActiveCtrl:GetNowSceneID()
    local m = self.m_mNowSceneInfo
    if not m then
        return
    end
    return m.now_scene
end

function CPlayerActiveCtrl:GetNowPos()
    local mNowPos
    if self.m_oSceneShareObj then
        mNowPos = self.m_oSceneShareObj:GetNowPos()
    end
    local m = self.m_mNowSceneInfo
    if mNowPos then
        m.now_pos = mNowPos
    end
    return m.now_pos
end

function CPlayerActiveCtrl:SetNowSceneInfo(mInfo)
    local m = self.m_mNowSceneInfo
    if not m then
        self.m_mNowSceneInfo = {}
        m = self.m_mNowSceneInfo
    end
    if mInfo.now_scene then
        m.now_scene = mInfo.now_scene
    end
    if mInfo.now_pos then
        m.now_pos = mInfo.now_pos
    end
end

function CPlayerActiveCtrl:ClearNowSceneInfo()
    self.m_mNowSceneInfo = {}
end

function CPlayerActiveCtrl:InWar()
    local oWar = self:GetNowWar()
    if oWar then
        return true
    end
    return false
end

function CPlayerActiveCtrl:GetNowWar()
    local m = self.m_mNowWarInfo
    if not m then
        return
    end
    local oWarMgr = global.oWarMgr
    local iNow = m.now_war
    if  m.kuafu then
        return global. oProxyWarMgr:GetWar(iNow)
    else
        return global.oWarMgr:GetWar(iNow)
    end
end

function CPlayerActiveCtrl:SetNowWarInfo(mInfo)
    local m = self.m_mNowWarInfo
    if not m then
        self.m_mNowWarInfo = {}
        m = self.m_mNowWarInfo
    end
    if mInfo.now_war then
        m.now_war = mInfo.now_war
        if mInfo.kuafu then
            m.kuafu = 1
        end
    end
    if mInfo.solvekaji then
        m.solvekaji = mInfo.solvekaji
    end
end

function CPlayerActiveCtrl:ClearNowWarInfo()
    self.m_mNowWarInfo = {}
end

function CPlayerActiveCtrl:InSolveKaji()
    local m = self.m_mNowWarInfo
    if m.solvekaji then
        return true
    end
    return false
end

function CPlayerActiveCtrl:GetOffer()
    return self:GetData("org_offer")
end

function CPlayerActiveCtrl:ValidOrgOffer(iVal,mArgs)
    mArgs = mArgs or {}
    local iOffer = self:GetData("org_offer",0)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    assert(iOffer>=0,string.format("%d org offer err %d", self:GetInfo("pid"), iOffer))
    assert(iVal>0,string.format("%d cost coin err %d", self:GetInfo("pid"), iVal))
    if iOffer >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "贡献不足"
    end
    if not mArgs.cancel_tip then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(self:GetInfo("pid"),sTip)
    end
    return false
end

function CPlayerActiveCtrl:RewardOrgOffer(iVal,sReason,mArgs)
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr  = global.oChatMgr

    local iPid = self:GetInfo("pid")
    local iOffer = self:GetOffer()
    assert(iVal>0,string.format("%d org_offer err %d %d",self:GetInfo("pid"),iOffer,iVal))
    self:Dirty()
    local iPreOffer = iOffer
    local iMaxOffer = gamedefines.COIN_TYPE[gamedefines.COIN_FLAG.COIN_ORG_OFFER]["max"]
    local iAddOffer = math.min(iVal, iMaxOffer - iOffer)
    local iOffer = iOffer + iVal
    iOffer = math.min(iOffer,iMaxOffer)
    self:SetData("org_offer",iOffer)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:PropChange("org_offer")
        local lMessage = {}
        local sMsg = string.format("获得了%s#amount", self:CoinIcon(gamedefines.COIN_FLAG.COIN_ORG_OFFER))
        local mNotifyArgs = {
            amount = iVal
        }
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
        oPlayer:SyncTosOrg({offer=true})
        global.oOrgMgr:RewardOrgOffer(iPid,iVal)
    end
    if iAddOffer > 0 then
        if not mArgs.cancel_show then
            self:AddShowKeep(1014, iAddOffer)
        end
    end
    if iVal > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_ORG_OFFER
        mLog["num"] = iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:GetOffer()
        analy.log_data("currency",mLog)
        self:LogCoin("offer",iVal, iPreOffer, iOffer, sReason)
    end
end

function CPlayerActiveCtrl:ResumeOrgOffer(iVal,sReason,mArgs)
    self:Dirty()
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    local iPid = self:GetInfo("pid")
    local iOffer = self:GetOffer()
    assert(iVal>0 and iOffer>=iVal,string.format("%d resume_orgoffer err %d %d",self:GetInfo("pid"),iOffer,iVal))
    local iPreOffer = iOffer
    iOffer = iOffer - iVal
    self:SetData("org_offer",iOffer)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:PropChange("org_offer")
        local lMessage = {}
        local sMsg = string.format("消耗了%s#resume", self:CoinIcon(gamedefines.COIN_FLAG.COIN_ORG_OFFER))
        local mNotifyArgs = {resume = iVal}
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
        oPlayer:SyncTosOrg({offer=true})
    end
    if iVal > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_ORG_OFFER
        mLog["num"] = -iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:GetOffer()
        analy.log_data("currency",mLog)
        self:LogCoin("offer",-iVal, iPreOffer, iOffer, sReason)
    end
end

function CPlayerActiveCtrl:GetEnergy()
    return self:GetData("energy")
end

function CPlayerActiveCtrl:GetMaxEnergy()
    local mConfig = res["daobiao"]["global"]["max_energy"]
    local iBase = tonumber(mConfig["value"] or 150)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    local bMonthCard = oPlayer:IsMonthCardVip()
    local bZSCard = oPlayer:IsZskVip()
    iBase = iBase + (bMonthCard and 20 or 0) + (bZSCard and 30 or 0)
    return iBase
end

function CPlayerActiveCtrl:GetInitRoleEnergy()
    local mRoleInitProp = res["daobiao"]["roleprop"][1]
    return mRoleInitProp.energy
end

function CPlayerActiveCtrl:GetEnergyRecoveryTime()
    local mConfig = res["daobiao"]["global"]["energy_recovertime"]
    return tonumber(mConfig["value"] or 10)
end

function CPlayerActiveCtrl:ValidEnergy(iVal,mArgs)
    mArgs = mArgs or {}
    local iEnergy = self:GetData("energy",0)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    assert(iEnergy>=0,string.format("%d energy err %d", self:GetInfo("pid"), iEnergy))
    assert(iVal>0,string.format("%d cost coin err %d", self:GetInfo("pid"), iVal))
    if iEnergy >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "体力不足"
    end
    local bShort = mArgs.short
    if not mArgs.cancel_tip then
        if bShort then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(self:GetInfo("pid"),sTip)
        end
    end

    if not bShort then
        local oUIMgr = global.oUIMgr
        oUIMgr:GS2CShortWay(self:GetInfo("pid"),10)
    end
    return false
end

function CPlayerActiveCtrl:RewardEnergy(iVal,sReason,mArgs)
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr  = global.oChatMgr

    local iPid = self:GetInfo("pid")
    local iEnergy = self:GetEnergy()
    local iMaxEnergy = self:GetMaxEnergy()
    if mArgs.recovery then
        if iEnergy >= iMaxEnergy then
            return
        end
    end
    assert(iVal>0,string.format("%d energy err %d %d",self:GetInfo("pid"),iEnergy,iVal))
    self:Dirty()
    local iPreEnergy = iEnergy
    local iAddEnergy = math.min(iVal, iMaxEnergy - iEnergy)
    if not mArgs.recovery then
        iAddEnergy = iVal
    elseif iAddEnergy > 0 then
        self:SetData("energy_recoverytime",get_time())
    end
    local iEnergy = iEnergy + iVal
    self:SetData("energy",iEnergy)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:PropChange("energy")
        local lMessage = {}
        local sMsg = string.format("获得了%s#amount", self:CoinIcon(gamedefines.COIN_FLAG.COIN_ENERGY))
        local mNotifyArgs = {
            amount = iVal
        }
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if not mArgs.recovery and iAddEnergy > 0 and not mArgs.cancel_show then
        self:AddShowKeep(1020, iAddEnergy)
    end
    self:LogCoin("energy",iVal,iPreEnergy,iEnergy,sReason)
    ---TODO: AddLog
end

function CPlayerActiveCtrl:ResumeEnergy(iVal,sReason,mArgs)
    self:Dirty()
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    local iPid = self:GetInfo("pid")
    local iEnergy = self:GetEnergy()
    assert(iVal>0 and iEnergy>=iVal,string.format("%d resume_energy err %d %d",self:GetInfo("pid"),iEnergy,iVal))
    local iPreEnergy = iEnergy
    iEnergy = iEnergy - iVal
    self:SetData("energy",iEnergy)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:PropChange("energy")
        local lMessage = {}
        local sMsg = string.format("消耗了%s#resume", self:CoinIcon(gamedefines.COIN_FLAG.COIN_ENERGY))
        local mNotifyArgs = {resume = iVal}
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    local iMaxEnergy = self:GetMaxEnergy()
    if iPreEnergy >= iMaxEnergy and iEnergy < iMaxEnergy then
        self:SetData("energy_recoverytime",get_time())
        self:_RecoveryEnergy()
    end
    if iVal > 0 then
        self:LogCoin("energy",-iVal,iPreEnergy,iEnergy,sReason)
        --TODO AddLog
    end
end

--技能点,不能的分支互不影响
function CPlayerActiveCtrl:AddSkillPoint(iPoint, sReason)
    local mPoint = self:GetData("skill_point",{})
    local iSumPoint = mPoint["sum_point"] or 0
    iSumPoint = iSumPoint + iPoint
    mPoint["sum_point"] = iSumPoint
    local mSchoolPoint = mPoint["school_point"] or {}
    for iSchoolBranch = 1,2 do
        local iSchoolPoint = mSchoolPoint[iSchoolBranch] or 0
        local iSum = iSchoolPoint + iPoint
        mSchoolPoint[iSchoolBranch] = iSum
        self:LogSkillPoint(iPoint, iSchoolPoint, iSchoolBranch, sReason)
    end
    mPoint["school_point"] = mSchoolPoint
    self:SetData("skill_point",mPoint)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:PropChange("skill_point")
    end
end

function CPlayerActiveCtrl:GetSkillSumPoint()
    local mPoint = self:GetData("skill_point")
    return mPoint["sum_point"] or 0
end

function CPlayerActiveCtrl:ResetSkillPoint(sReason)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    assert(oPlayer,string.format("SetSkillPoint err:%s",self:GetInfo("pid")))
    local iSchoolBranch = oPlayer:GetSchoolBranch()
    local mPoint = self:GetData("skill_point",{})
    local iSumPoint = mPoint["sum_point"]
    local mSchoolPoint = mPoint["school_point"] or {}
    local iNow = mSchoolPoint[iSchoolBranch] or 0
    self:LogSkillPoint(iSumPoint, iNow, iSchoolBranch, sReason)
    mSchoolPoint[iSchoolBranch] = iSumPoint
    oPlayer:PropChange("skill_point")
end

function CPlayerActiveCtrl:GetSkillPoint(iSchoolBranch)
    local mPoint = self:GetData("skill_point",{})
    local mSchoolPoint = mPoint["school_point"] or {}
    return mSchoolPoint[iSchoolBranch] or 0
end

function CPlayerActiveCtrl:ValidResumeSkillPoint(iSchoolBranch,iPoint,mArgs)
    assert(iPoint >= 0, string.format("ValidResumeSkillPoint err:%s,%s,%s", self:GetInfo("pid"), iSchoolBranch, iPoint))
    local mPoint = self:GetData("skill_point",{})
    local mSchoolPoint = mPoint["school_point"] or {}
    local iHavePoint = mSchoolPoint[iSchoolBranch] or 0
    if iHavePoint < iPoint then
        return false
    end
    return true
end

function CPlayerActiveCtrl:ResumeSkillPoint(iSchoolBranch,iPoint,sReason)
    local mPoint = self:GetData("skill_point",{})
    local mSchoolPoint = mPoint["school_point"] or {}
    local iHavePoint = mSchoolPoint[iSchoolBranch]
    assert(iHavePoint>=iPoint,string.format("resume skill_point err:%s %s %s",self:GetInfo("pid"),iSchoolBranch,iPoint))
    self:LogSkillPoint(-iPoint, iHavePoint, iSchoolBranch, sReason)
    mSchoolPoint[iSchoolBranch] = iHavePoint - iPoint
    self:SetData("skill_point",mPoint)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:PropChange("skill_point")
    end
end

function CPlayerActiveCtrl:LogAnalySkillReset(oPlayer,iBeforPoint, mCost, iConsumeGold, iRemainGold)
    local mLog = oPlayer:GetPubAnalyData()
    mLog["skill_faction"] = tostring(oPlayer.m_oBaseCtrl:GetData("school_branch"))
    mLog["consume_detail"] = analy.datajoin(mCost)
    mLog["skill_point_before"] = iBeforPoint
    mLog["skill_point_after"] = oPlayer:GetSkillPoint()
    mLog["consume_goldcoin"] = iConsumeGold
    mLog["remain_goldcoin"] = iRemainGold
    analy.log_data("skillReset",mLog)
end

function CPlayerActiveCtrl:GetAutoSkill()
    return self:GetData("auto_skill",0)
end

function CPlayerActiveCtrl:SetTreasureTotalTimes(iTime)
    self:SetData("treasure_totaltimes",iTime or 0)
end

function CPlayerActiveCtrl:GetTreasureTotalTimes()
    return self:GetData("treasure_totaltimes",0)
end

function CPlayerActiveCtrl:SetTreasureWeekTimes(iTime)
    self:SetData("treasure_weektimes",iTime or 0)
end

function CPlayerActiveCtrl:GetTreasureWeekTimes()
    return self:GetData("treasure_weektimes",0)
end

function CPlayerActiveCtrl:SetTeachTaskProgress(mProgress)
    self:SetData("teachtask_progress",mProgress)
end

function CPlayerActiveCtrl:GetTeachTaskProgress()
    return self:GetData("teachtask_progress",{})
end

function CPlayerActiveCtrl:SetAutoSkill(iAutoSkill)
    self:SetData("auto_skill",iAutoSkill)
end

function CPlayerActiveCtrl:GetAutoSkillSwitch()
    return self:GetData("auto_skill_switch",0)
end

function CPlayerActiveCtrl:SetAutoSkillSwitch(iAutoSkillSwitch)
    self:SetData("auto_skill_switch",iAutoSkillSwitch)
end

function CPlayerActiveCtrl:RewardArenaMedal(iPoint,sReason, mArgs)
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    local iPid = self:GetInfo("pid")
    local iNow = self:GetData("arena",0)
    assert(iPoint > 0,string.format("RewardArenaMedal %s %d %d",self:GetInfo("pid"),iPoint,iNow))
    local iSum = iNow + iPoint
    self:LogCoin("arena",iPoint,iNow,iSum,sReason)
    self:SetData("arena",iSum)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local lMessage = {}
        local sMsg = string.format("获得了%s#amount", self:CoinIcon(gamedefines.COIN_FLAG.COIN_ARENA))
        local mNotifyArgs = {
            amount = iPoint
        }
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
            --oNotifyMgr:Notify(iPid, sMsg)
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
            --oChatMgr:HandleMsgChat(oPlayer, sMsg)
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if iPoint > 0 then
        self:AddShowKeep(1009, iPoint)
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_ARENA
        mLog["num"] = iPoint
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:ArenaMedal()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ResumeArenaMedal(iPoint,sReason,mArgs)
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr

    local iPid = self:GetInfo("pid")
    local iNow = self:GetData("arena",0)
    local iSub = iNow - iPoint
    assert(iPoint >= 0 and iSub>= 0 ,string.format("ResumeArenaMedal %s %d %d",self:GetInfo("pid"),iPoint,iNow))
    self:LogCoin("arena",-iPoint,iNow,iSub,sReason)
    self:SetData("arena",iSub)

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local lMessage = {}
        local sMsg = string.format("消耗了%s#resume", self:CoinIcon(gamedefines.COIN_FLAG.COIN_ARENA))
        local mNotifyArgs = {
            resume = iPoint
        }
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if iPoint > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_ARENA
        mLog["num"] = -iPoint
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:ArenaMedal()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ValidArenaMedal(iVal,mArgs)
    local iLeft = self:GetData("arena",0)
    assert(iVal>0,string.format("%d cost medal err %d",self:GetInfo("pid"),iVal))
    assert(iLeft>=0,string.format("%d cost medal err %d", self:GetInfo("pid"), iLeft))
    if iLeft >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "荣誉不足"
    end
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(self:GetInfo("pid"),sTip)
    return false
end

function CPlayerActiveCtrl:MaxMedal(iType)
    local iType = gamedefines.COIN_FLAG.COIN_MEDAL
    local mMedalInfo = gamedefines.COIN_TYPE[iType]
    assert(mMedalInfo,string.format("MaxMedal %d",iType))
    return mMedalInfo.max
end

function CPlayerActiveCtrl:ValidMedal(iVal, mArgs)
    mArgs = mArgs or {}
    local iMedal = self:GetData("medal",0)
    assert(iMedal>=0,string.format("%d medal err %d", self:GetInfo("pid"), iMedal))
    assert(iVal>0,string.format("%d cost medal err %d", self:GetInfo("pid"), iVal))
    if iMedal >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "勋章不足"
    end
    local bShort = mArgs.short
    if not mArgs.cancel_tip then
        if bShort then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(self:GetInfo("pid"),sTip)
        end
    end

    if not bShort then
        local oUIMgr = global.oUIMgr
        oUIMgr:GS2CShortWay(self:GetInfo("pid"),4)
    end
    return false
end

function CPlayerActiveCtrl:RewardMedal(iVal, sReason, mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    mArgs = mArgs or {}
    assert(iVal>0,string.format("pid:%s ,CPlayerActiveCtrl:RewardMedal err:%d", self:GetInfo("pid"), iVal))

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))

    local iMaxMedal = self:MaxMedal()
    local iMedal = self:GetData("medal", 0)
    local iAddMedal = math.min(iVal, iMaxMedal - iMedal)
    local iOverMedal = math.max(0, iVal - iAddMedal)
    local iSum = iMedal + iVal
    self:LogCoin("medal",iVal,iMedal,iSum,sReason)
    self:SetData("medal", math.min(iSum, iMaxMedal))

    if iAddMedal > 0 then
        oPlayer:PropChange("medal")
        self:AddShowKeep(1011, iAddMedal)
    end

    local lMessage = {}
    local sMsg
    local mNotifyArgs
    if iAddMedal > 0 then
        sMsg = string.format("获得了%s#amount", self:CoinIcon(gamedefines.COIN_FLAG.COIN_MEDAL))
        mNotifyArgs = {
            amount = iAddMedal
        }
    end

    if mArgs.tips then
        sMsg = mArgs.tips
    end
    if sMsg and not mArgs.cancel_tip then
       table.insert(lMessage,"GS2CNotify")
    end
    if sMsg and not mArgs.cancel_channel then
        table.insert(lMessage,"GS2CConsumeMsg")
    end
    if #lMessage > 0 then
        oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
    end
    if iOverMedal > 0 then
        oNotifyMgr:Notify(self:GetInfo("pid"), "你的勋章已满，请及时使用")
    end
    if iAddMedal > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_MEDAL
        mLog["num"] = iAddMedal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:Medal()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ResumeMedal(iVal, sReason, mArgs)
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local iMedal = self:GetData("medal",0)
    assert(iVal>0 and iMedal>=iVal,string.format("pid:%s ,CPlayerActiveCtrl:ResumeMedal err:%d", self:GetInfo("pid"), iVal))

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))

    local iSum = iMedal - iVal
    self:LogCoin("medal",-iVal,iMedal,iSum,sReason)
    self:SetData("medal", iSum)
    if oPlayer then
        oPlayer:PropChange("medal")
        local lMessage = {}
        local sMsg = string.format("消耗了%s#resume", self:CoinIcon(gamedefines.COIN_FLAG.COIN_MEDAL))
        local mNotifyArgs = {
            resume = iVal
        }
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
           table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if iVal > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_MEDAL
        mLog["num"] = -iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:Medal()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:RewardActive(iVal,sReason,mArgs)
    mArgs = mArgs or {}
    local iMaxCoin = self:MaxCoin(gamedefines.COIN_FLAG.COIN_ACTIVE)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    local iNow = self:GetData("active",0)
    local iSum = iNow + iVal
    local iSum = math.min(iMaxCoin,iSum)
    assert(iVal>0,string.format("pid:%s ,CPlayerActiveCtrl:RewardActive err:%d", self:GetInfo("pid"), iVal))
    self:SetData("active",iSum)
    self:LogCoin("active",iVal,iNow,iSum,sReason)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:PropChange("active")
        local lMessage = {}
        local sMsg = string.format("获得了%s#amount", self:CoinIcon(gamedefines.COIN_FLAG.COIN_ACTIVE))
        local mNotifyArgs = {
            amount = iVal
        }
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
        global.oOrgMgr:RewardActivePoint(oPlayer:GetPid(),iVal,sReason,mArgs)
    end
    self:AddBreedVal(iVal, sReason, mArgs)
    if iVal > 0 then
        global.oFuliMgr:AddConsumePoint(oPlayer,iVal)
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_ACTIVE
        mLog["num"] = iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:Active()
        analy.log_data("currency",mLog)
    end
    if oPlayer then
        global.oFuliMgr:AddLuckActive(oPlayer,iVal)
    end
end

function CPlayerActiveCtrl:ResumeActive(iVal,sReason,mArgs)
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    local iNow = self:GetData("active",0)
    local iSub = iNow - iVal
    assert(iVal >= 0 and iSub>= 0 ,string.format("ResumeActive %s %d %d",self:GetInfo("pid"),iVal,iNow))
    self:LogCoin("active",-iVal,iNow,iSub,sReason)
    self:SetData("active",iSub)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:PropChange("active")
        local lMessage = {}
        local sMsg = string.format("消耗了%s#resume", self:CoinIcon(gamedefines.COIN_FLAG.COIN_ACTIVE))
        local mNotifyArgs = {
            resume = iVal
        }
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if iVal > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_ACTIVE
        mLog["num"] = -iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:Active()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ValidActive(iVal,mArgs)
    local iLeft = self:GetData("active",0)
    assert(iVal>0,string.format("%d cost active err %d",self:GetInfo("pid"),iVal))
    assert(iLeft>=0,string.format("%d cost active err %d", self:GetInfo("pid"), iLeft))
    if iLeft >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "活跃度不足"
    end
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(self:GetInfo("pid"),sTip)
    return false
end

function CPlayerActiveCtrl:AddSkin(iVal,sReason,mArgs)
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    local iPid = self:GetInfo("pid")
    assert(iVal > 0, string.format("%s add skin coin err:%d", iPid, iVal))
    local iMaxCoin = self:MaxCoin(gamedefines.COIN_FLAG.COIN_ACTIVE)
    local iNow = self:GetData("skin",0)
    local iSum = iNow + iVal
    local iSum = math.min(iMaxCoin,iSum)
    local iAdd = iSum - iNow
    self:SetData("skin",iSum)
    self:LogCoin("skin",iVal,iNow,iSum,sReason)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:PropChange("skin")
        if iAdd > 0 then
            self:AddShowKeep(1017, iAdd)
        end
        local lMessage = {}
        local sMsg = string.format("获得了%s#amount", self:CoinIcon(gamedefines.COIN_FLAG.COIN_SKIN))
        local mNotifyArgs = {
            amount = iVal
        }
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if  iVal > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_SKIN
        mLog["num"] = iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:Skin()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ResumeSkin(iVal,sReason,mArgs)
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    local iPid = self:GetInfo("pid")
    local  iNow = self:GetData("skin",0)
    local iSub = iNow - iVal
    assert(iVal >= 0 and iSub>= 0 ,string.format("ResumeSkin %s %d %d",self:GetInfo("pid"),iVal,iNow))

    self:LogCoin("skin",-iVal,iNow,iSub,sReason)
    self:SetData("skin",iSub)

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:PropChange("skin")
        local lMessage = {}
        local sMsg = string.format("消耗了%s#resume", self:CoinIcon(gamedefines.COIN_FLAG.COIN_SKIN))
        local mNotifyArgs = {
            resume = iVal
        }
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if  iVal > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_SKIN
        mLog["num"] = -iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:Skin()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ValidSkin(iVal,mArgs)
    mArgs = mArgs or {}
    local iLeft = self:GetData("skin",0)
    assert(iVal>0,string.format("%d cost active err %d",self:GetInfo("pid"),iVal))
    assert(iLeft>=0,string.format("%d cost active err %d", self:GetInfo("pid"), iLeft))
    if iLeft >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "皮肤卷不足"
    end
    if not mArgs.cancel_tip then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(self:GetInfo("pid"),sTip)
    end
    return false
end



function CPlayerActiveCtrl:ValidTrapminePoint(iVal, mArgs)
    mArgs = mArgs or {}
    local iPoint = self:GetData("trapmine_point",0)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    assert(iPoint>=0,string.format("%d trapmine_point err %d", self:GetInfo("pid"), iPoint))
    assert(iVal>0,string.format("%d cost trapmine_point err %d", self:GetInfo("pid"), iVal))
    if iPoint >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "探索点不足"
    end
    local bShort = mArgs.short
    if not mArgs.cancel_tip then
        if bShort then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(self:GetInfo("pid"),sTip)
        end
    end

    if not bShort then
        local oUIMgr = global.oUIMgr
        oUIMgr:GS2CShortWay(self:GetInfo("pid"), gamedefines.COIN_FLAG.COIN_TRAPMINE_POINT)
    end
    return false
end

function CPlayerActiveCtrl:RewardTrapminePoint(iVal, sReason, mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    mArgs = mArgs or {}
    assert(iVal>0,string.format("pid:%s ,CPlayerActiveCtrl:RewardTrapminePoint err:%d", self:GetInfo("pid"), iVal))

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))

    local iMaxCoin = self:MaxCoin(gamedefines.COIN_FLAG.COIN_TRAPMINE_POINT)
    local iPoint = self:GetData("trapmine_point", 0)
    local iAddCoin = math.min(iVal, iMaxCoin - iPoint)
    local iOverCoin = math.max(0, iVal - iAddCoin)
    local iSum = iPoint + iVal
    self:LogCoin("trapmine_point",iVal, iPoint, iSum, sReason)
    self:SetData("trapmine_point", math.min(iSum, iMaxCoin))

    if oPlayer then
        if iAddCoin > 0 then
            oPlayer:PropChange("trapmine_point")
        end
        local sMsg
        local mNotifyArgs
        local lMessage = {}
        if iAddCoin > 0 then
            sMsg = string.format("获得了%s#amount", self:CoinIcon(gamedefines.COIN_FLAG.COIN_TRAPMINE_POINT))
            mNotifyArgs = {
                amount = iAddCoin
            }
        end
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if sMsg and not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
            --oNotifyMgr:Notify(self:GetInfo("pid"),sMsg)
            if iOverCoin > 0 then
                oNotifyMgr:Notify(self:GetInfo("pid"), "你的探索点已满，请及时使用")
            end
        end
        if sMsg and not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
            --oChatMgr:HandleMsgChat(oPlayer, sMsg)
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if iAddCoin > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_TRAPMINE_POINT
        mLog["num"] = iAddCoin
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:TrapminePoint()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ResumeTrapminePoint(iVal, sReason, mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    mArgs = mArgs or {}
    local iPoint = self:GetData("trapmine_point",0)
    assert(iVal>0 and iPoint >= iVal, string.format("pid:%s, ResumeTrapminePoint err:%d, %d, %s", self:GetInfo("pid"), iPoint, iVal, sReason))

    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)

    local iSum = iPoint - iVal
    self:LogCoin("trapmine_point",-iVal,iPoint,iSum,sReason)
    self:SetData("trapmine_point", iSum)
    if oPlayer then
        oPlayer:PropChange("trapmine_point")
        local lMessage = {}
        local sMsg = string.format("消耗了%s#resume", self:CoinIcon(gamedefines.COIN_FLAG.COIN_TRAPMINE_POINT))
        local mNotifyArgs = {
            resume = iVal
        }
        if mArgs.tips then
            sMsg = mArgs.tips
        end
        if not mArgs.cancel_tip then
           table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if #lMessage > 0 then
            oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),lMessage,sMsg,mNotifyArgs)
        end
    end
    if iVal > 0 then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_TRAPMINE_POINT
        mLog["num"] = -iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = oPlayer:TrapminePoint()
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:ValidTravelScore(iVal, mArgs)
    mArgs = mArgs or {}
    assert(iVal>0,string.format("%d cost TravelScore err %d", self:GetInfo("pid"), iVal))
    local iPid = self:GetInfo("pid")
    local iScore = self:GetData("travel_score",0)
    if iScore >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "积分不足"
    end
    local bShort = mArgs.short
    if not mArgs.cancel_tip then
        if bShort then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(iPid,sTip)
        end
    end

    if not bShort then
        local oUIMgr = global.oUIMgr
        oUIMgr:GS2CShortWay(iPid, gamedefines.COIN_FLAG.COIN_TRAVEL)
    end
    return false
end

function CPlayerActiveCtrl:AddTravelScore(iVal, sReason, mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    mArgs = mArgs or {}

    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iMaxCoin = self:MaxCoin(gamedefines.COIN_FLAG.COIN_TRAVEL)
    local iPoint = self:GetData("travel_score", 0)
    assert(iVal ~= 0, string.format("pid:%s, AddTravelScore err:%d, %d, %s", iPid, iPoint, iVal, sReason))
    local iSum = iPoint + iVal
    assert(iSum >= 0, string.format("pid:%s, AddTravelScore err:%d, %d, %s", iPid, iPoint, iVal, sReason))
    iSum = math.max(math.min(iSum, iMaxCoin), 0)
    self:SetData("travel_score", iSum)

    self:LogCoin("travel_score",iVal, iPoint, iSum, sReason)
    if oPlayer then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["currency_type"] = gamedefines.COIN_FLAG.COIN_TRAVEL
        mLog["num"] = iVal
        mLog["remain_crystal_bd"] = 0
        mLog["remain_crystal"] = oPlayer:ColorCoin()
        mLog["reason"] = sReason
        mLog["remain_currency"] = iSum
        analy.log_data("currency",mLog)
    end
end

function CPlayerActiveCtrl:LogCoin(sType,iVal,iOld,iNow,sReason,mArgs)
    local mLog ={
    pid = self:GetInfo("pid"),
    amount = iVal,
    reason = sReason,
    now = iNow,
    old = iOld,
    }
    if mArgs then
        mLog = table_combine(mLog,mArgs)
    end
    record.user("coin",sType,mLog)
end

function CPlayerActiveCtrl:LogSkillPoint(iVal, iNow, iSchoolBranch, sReason, mArgs)
    local mLog ={
    pid = self:GetInfo("pid"),
    amount = iVal,
    reason = sReason,
    now = iNow,
    branch = iSchoolBranch,
    }
    if mArgs then
        mLog = table_combine(mLog,mArgs)
    end
    record.user("skill","skill_point", mLog)
end


function CPlayerActiveCtrl:AddToTeamBlackList(iPid,iTime)
    self.m_mTeamBlackList = self.m_mTeamBlackList or {}
    self.m_mTeamBlackList[iPid] = {end_time = (get_time() + iTime*60)}
end

function CPlayerActiveCtrl:IsInTeamBlackList(iPid)
    if self.m_mTeamBlackList and self.m_mTeamBlackList[iPid] then
        if self.m_mTeamBlackList[iPid].end_time > get_time() then
            return true
        else
            self.m_mTeamBlackList[iPid] = nil
        end
    end
    return false
end

function CPlayerActiveCtrl:AddShowKeep(iVirtualSid, iVal)
    local oItem = loaditem.GetItem(iVirtualSid)
    local mShowInfo = oItem:GetShowInfo()
    mShowInfo.amount = iVal
    global.oUIMgr:AddKeepItem(self:GetInfo("pid"), mShowInfo)
end

function CPlayerActiveCtrl:GS2CGuidanceInfo()
    local m = self:GetData("guidanceinfo",{})

    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    oPlayer:Send("GS2CGuidanceInfo",{guidanceinfo = m})
end

function CPlayerActiveCtrl:CheckGuidanceVersion(oPlayer)
    local m = self:GetData("guidanceinfo",{})
    local iVersion = m.version
    if not iVersion or iVersion < gamedefines.GUIDE_VERSION then
        self:FixGuidance(oPlayer)
    end
end

function CPlayerActiveCtrl:FixGuidance(oPlayer)
    local mGuidance = res["client_guidance"]
    local m = self:GetData("guidanceinfo",{})
    m.version = gamedefines.GUIDE_VERSION
    if not m.key then
        m.key = {}
    end
    if table_count(m.key) <= 0 then
        self:SetData("guidanceinfo",m)
        return
    end
    local tmp = {}
    local lValue = table_value_list(mGuidance)
    for iKey,info in pairs(mGuidance) do
        local sKey = info["value"]
        if table_in_list(m.key,sKey) then
            table.insert(tmp,iKey)
        end
    end
    m.key = tmp
    self:SetData("guidanceinfo",m)
end

function CPlayerActiveCtrl:PrintOldGuidance()
    print("GM Operation:PrintOldGuidance")
    print(self:GetData("old_guidanceinfo",{}))
end

function CPlayerActiveCtrl:SetGuideFlag(oPlayer,iServerKey)
    local mGuidance = res["client_guidance"]
    if not mGuidance[iServerKey] then
        record.warning("SetGuideFlag error:"..iServerKey)
        return
    end
    local m = self:GetData("guidanceinfo",{})
    if not m.key then
        m.key = {}
    end
    local sFlag = mGuidance[iServerKey]["value"]
    local mDelKey = mGuidance[iServerKey]["del_key"]
    local bInsert = false
    if not table_in_list(m.key,iServerKey) then
        table.insert(m.key,iServerKey)
        self:SetData("guidanceinfo",m)
        bInsert = true
    end
    if bInsert and GuidanceEvent[sFlag] and self:GetData("Trigger"..sFlag,0) == 0 then
        local func = GuidanceEvent[sFlag]
        func(oPlayer)
        self:SetData("Trigger"..sFlag,1)
    end
    if table_count(mDelKey) == 2 then
        local iMin,iMax = table.unpack(mDelKey)
        local iIndex = 1
        while(iIndex <= #(m.key)) do
            if m.key[iIndex] <= iMax and m.key[iIndex] >= iMin then
                table.remove(m.key,iIndex)
            else
                iIndex = iIndex + 1
            end
        end
        self:SetData("guidanceinfo",m)
    end
    return bInsert
end

function CPlayerActiveCtrl:HasGuideKey(iServerKey)
    local m = self:GetData("guidanceinfo",{})
    if not m.key then
        return false
    end
    return table_in_list(m.key,iServerKey)
end


function CPlayerActiveCtrl:GS2CLoginRewardInfo()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    oPlayer:Send("GS2CLoginRewardInfo", {
        login_day = self:GetData("count_login_day", 0);
        rewarded_day = self:GetData("login_rewarded_day", 0),
        breed_val = self:GetData("breed_val", 0),
        breed_rwd = self:GetData("breed_rwd", 0),
        })
end

function CPlayerActiveCtrl:SetBanChat(iTime)
    self:SetData("ban_time", iTime)
end

function CPlayerActiveCtrl:IsBanChat()
    return get_time() < self:GetData("ban_time", 0)
end

function CPlayerActiveCtrl:GetBanChatTime()
   return math.max(self:GetData("ban_time", 0) - get_time(), 0)
end

function CPlayerActiveCtrl:SetSceneShareObj(oShareObj)
    self:ClearSceneShareObj()
    self.m_oSceneShareObj = CScenePlayerShareObj:New()
    self.m_oSceneShareObj:Init(oShareObj)
end

function CPlayerActiveCtrl:ClearSceneShareObj()
    if self.m_oSceneShareObj then
        baseobj_safe_release(self.m_oSceneShareObj)
        self.m_oSceneShareObj = nil
    end
end

function CPlayerActiveCtrl:GetDailySignDay(sKey)
    assert(sKey, "GetDailySignDay: key not exist !")
    local mSign = self:GetData("daily_sign", {})
    return mSign[sKey] or 0
end

function CPlayerActiveCtrl:DailySignIn(sKey)
    assert(sKey, "DailySignIn:key not exist !")
    self:Dirty()
    local mSign = self:GetData("daily_sign", {})
    local iSign = mSign[sKey] or 0
    mSign[sKey] = iSign + 1
    self:SetData("daily_sign", mSign)
end

function CPlayerActiveCtrl:ResetDailySign(sKey)
    assert(sKey, "ResetDailySign:key not exist !")
    self:Dirty()
    local mSign = self:GetData("daily_sign", {})
    mSign[sKey] = 0
    self:SetData("daily_sign", mSign)
end

function CPlayerActiveCtrl:CheckEnergy()
    local iEnergy = self:GetEnergy()
    local iMaxEnergy = self:GetMaxEnergy()
    if iEnergy < iMaxEnergy then
        local iLastRecoveryTime = self:GetData("energy_recoverytime",get_time())
        assert(iLastRecoveryTime,"CheckEnergy failed")
        local iIntervalTime = get_time() - iLastRecoveryTime
        local iRecoveryTime = self:GetEnergyRecoveryTime() * 60
        local iAdd = math.floor(iIntervalTime/iRecoveryTime)
        iAdd = math.min(iAdd,iMaxEnergy-iEnergy)
        if iAdd > 0 then
            self:RewardEnergy(iAdd,"离线恢复体力",{cancel_tip = true,cancel_channel = true,recovery = true,cancel_show = true})
            self:SetData("energy_recoverytime",get_time()-(iIntervalTime - (iAdd*iRecoveryTime)))
        end
        if (iEnergy + iAdd) < iMaxEnergy then
            local iTime = iRecoveryTime - (iIntervalTime - (iAdd*iRecoveryTime))
            self:_RecoveryEnergy(iTime)
        end
    end
end

function CPlayerActiveCtrl:_RecoveryEnergy(iTime)
    self:DelTimeCb("RecoveryEnergy")
    local iCurEnergy = self:GetEnergy()
    local iMaxEnergy = self:GetMaxEnergy()
    if iCurEnergy < iMaxEnergy then
        if not self:GetData("energy_recoverytime") then
            self:SetData("energy_recoverytime",get_time())
        end
        local iPid = self:GetInfo("pid")
        local iRecoveryTime = iTime or (self:GetEnergyRecoveryTime() * 60)
        local func = function()
            local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
            oPlayer.m_oActiveCtrl:RewardEnergy(1,"体力恢复",{recovery = true,cancel_tip = true,cancel_channel = true,cancel_show = true})
            oPlayer.m_oActiveCtrl:_RecoveryEnergy()
        end
        self:AddTimeCb("RecoveryEnergy",iRecoveryTime*1000,func)
    end
end

function CPlayerActiveCtrl:AddBreedVal(iVal, sReason, mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    mArgs = mArgs or {}
    local iPid = self:GetInfo("pid")
    assert(iVal>0,string.format("pid:%s ,CPlayerActiveCtrl:RewardCoin err:%d", iPid, iVal))

    local iMaxBreed = gamedefines.MAX_BREED_VAL
    local iHave = self:GetData("breed_val", 0)
    local iAdd = math.min(iVal, iMaxBreed - iHave)
    local iOverCoin = math.max(0, iVal - iAdd)
    local iSum = iHave + iVal
    -- self:LogCoin("coin",iVal,iCoin,iSum,sReason)
    self:SetData("breed_val", math.min(iSum, iMaxBreed))
    if  iAdd > 0 then
        self:GS2CLoginRewardInfo()
    end
end

function CPlayerActiveCtrl:SetGamePush(sType,iValue)
    local mGamePush = self:GetData("game_push",{})
    if iValue == 1 then
        mGamePush[sType]=iValue
    else
        mGamePush[sType] = nil
    end
    self:SetData("game_push",mGamePush)
    local lGamePush = {}
    table.insert(lGamePush,{type=sType,value=iValue})
    local iPid = self:GetInfo("pid")
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CGamePushSetting",{game_push=lGamePush})
        local oTravel = oPlayer:GetTravel()
        if oTravel then
            oTravel:SetGamePush(iValue)
        end
    end
end

function CPlayerActiveCtrl:IsGamePush(sType)
    local mGamePush = self:GetData("game_push",{})
    if not mGamePush[sType] or mGamePush[sType] == 0 then
        return false
    end
    return true
end

function CPlayerActiveCtrl:RefreshAllGamePush()
    local mGamePush = self:GetData("game_push",{})
    local lGamePush = {}
    for sType,iValue in pairs(mGamePush) do
        table.insert(lGamePush,{type=sType,value=iValue})
    end
    local iPid = self:GetInfo("pid")
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CGamePushSetting",{game_push=lGamePush})
    end
end

function CPlayerActiveCtrl:OnChargeCard(sType)
    if not self:GetTimeCb("_RecoveryEnergy") then
        self:_RecoveryEnergy()
    end
end

local ReceiveTime = {
    [1] = {12,0,17,30},
    [2] = {18,0,22,30}
}

function CPlayerActiveCtrl:ReceiveEnergy(iIndex)
    if not table_in_list({1,2},iIndex) then
        return
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    local iStatus = oPlayer.m_oToday:Query("energy_receive",0)
    local iBit = 1 << (iIndex - 1)
    local iBitStatus = iStatus & iBit
    if iBitStatus ~= 0 then

        return
    end
    local mTime = ReceiveTime[iIndex]
    local iTime = get_time()
    local m = os.date("*t",iTime)
    local iCurHour,iCurMin = m["hour"],m["min"]
    if (iCurHour < mTime[1]) or (iCurHour > mTime[3]) or (iCurHour == mTime[1] and iCurMin < mTime[2]) or (iCurHour == mTime[3] and iCurMin > mTime[4]) then
        return
    end
    oPlayer.m_oToday:Set("energy_receive",iStatus | iBit)
    oPlayer:GS2CTodayInfo({"energy_receive"})
    local iAdd = global.oWorldMgr:QueryGlobalData("freeenergy_value")
    self:RewardEnergy(tonumber(iAdd),string.format("第%d个时间段领取免费体力",iIndex))
end

function CPlayerActiveCtrl:RefreshShapeList(oPlayer, bReEnter)
    local l = self:GetData("shape_list", {})
    oPlayer:Send("GS2CShapeList", {shapes = table_value_list(l)})
end

function CPlayerActiveCtrl:GetEndlessPVEInfo()
    return self:GetData("endlesspve_info", {})
end

function CPlayerActiveCtrl:SetEndlessPVEInfo(mInfo)
    self:SetData("endlesspve_info", mInfo)
end

CScenePlayerShareObj = {}
CScenePlayerShareObj.__index = CScenePlayerShareObj
inherit(CScenePlayerShareObj, shareobj.CShareReader)

function CScenePlayerShareObj:New()
    local o = super(CScenePlayerShareObj).New(self)
    o.m_mPos = {}
    return o
end

function CScenePlayerShareObj:Unpack(m)
    self.m_mPos = m.pos_info
end

function CScenePlayerShareObj:GetNowPos()
    self:Update()
    return self.m_mPos
end
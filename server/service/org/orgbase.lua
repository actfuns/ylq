--import module
local skynet = require "skynet"
local global = require "global"
local res = require "base.res"
local record = require "public.record"
local gamedefines = import(lualib_path("public.gamedefines"))
local interactive = require "base.interactive"

local datactrl = import(lualib_path("public.datactrl"))
local redpacket = import(service_path("redpacket"))
local timectrl = import(lualib_path("public.timectrl"))

function NewBaseMgr(...)
    return COrgBaseMgr:New(...)
end

COrgBaseMgr = {}
COrgBaseMgr.__index = COrgBaseMgr
inherit(COrgBaseMgr, datactrl.CDataCtrl)

function COrgBaseMgr:New(orgid)
    local o = super(COrgBaseMgr).New(self, {orgid = orgid})
    o.m_mRedPacket = {}
    o.m_mOpenWishUI = {}
    o.m_oToday  = timectrl.CToday:New(orgid)
    return o
end

function COrgBaseMgr:GetOrg()
    local orgid = self:GetInfo("orgid")
    local oOrgMgr = global.oOrgMgr
    return oOrgMgr:GetNormalOrg(orgid)
end

function COrgBaseMgr:Create(tArgs)
    self:SetData("level", 1)
    self:SetData("aim", tArgs["aim"] or "")
    self:SetData("sflag",tArgs["sflag"] or "")
    self:SetData("flagbgid",tArgs["flagbgid"] or 1)
    self:SetData("powerlimit",0)
    self:SetData("needallow",0)
    self:SetData("exp",0)
    self:SetData("create_week_no",get_weekno())
    self:SetData("week_no",get_weekno())
    self:SetData("prestige",0)
    self:SetData("rank",0)
end

function COrgBaseMgr:Load(mData)
    mData = mData or {}
    self:SetData("level", mData.level)
    self:SetData("aim", mData.aim)
    self:SetData("powerlimit", mData.powerlimit or 0)
    self:SetData("needallow", mData.needallow or 0)
    self:SetData("exp", mData.exp or 0)
    self:SetData("cash",mData.cash or 0)
    self:SetData("sflag",mData.sflag or "")
    self:SetData("flagbgid",mData.flagbgid or 1)
    self:SetData("sign_degree",mData.sign_degree or 0)
    self:SetData("active_point",mData.active_point or 0)
    self:SetData("week_no",mData.week_no)
    self:SetData("create_week_no",mData.create_week_no)
    self:SetData("active_level",mData.active_level)
    self:SetData("prestige",mData.prestige or 0)
    self:SetData("rank",mData.rank or 0)
    self:SetData("creater",mData.creater or 0)
    self:SetData("spread_endtime",mData.spread_endtime or 0)
    self:SetData("spread_power",mData.spread_power or 0)
    self:SetData("maxlevel",mData.maxlevel or 1)

    local mRedPacket = mData.red_packet or {}
    for idx,mData in pairs(mRedPacket) do
        local oRedPacket = redpacket.NewRedPacket(mData)
        oRedPacket:Load(mData)
        self.m_mRedPacket[idx] = oRedPacket
    end
    local mToday = mData.today or {}
    self.m_oToday:Load(mToday)
end

function COrgBaseMgr:Save()
    local mData = {}
    mData.level = self:GetData("level")
    mData.aim = self:GetData("aim")
    mData.powerlimit = self:GetData("powerlimit",0)
    mData.needallow = self:GetData("needallow",0)
    mData.exp = self:GetData("exp",0)
    mData.cash = self:GetData("cash",0)
    mData.sflag = self:GetData("sflag","")
    mData.flagbgid = self:GetData("flagbgid",1)
    mData.sign_degree = self:GetData("sign_degree",0)
    mData.active_point = self:GetData("active_point",0)
    mData.week_no = self:GetData("week_no")
    mData.create_week_no = self:GetData("create_week_no")
    mData.active_level = self:GetData("active_level")
    mData.prestige = self:GetData("prestige",0)
    mData.rank = self:GetData("rank",0)
    mData.creater = self:GetData("creater",0)
    mData.spread_endtime = self:GetData("spread_endtime",0)
    mData.spread_power = self:GetData("spread_power",0)
    mData.maxlevel = self:GetData("maxlevel",1)

    local mRedPacket = {}
    for idx,oRedPacket in pairs(self.m_mRedPacket) do
        mRedPacket[idx] = oRedPacket:Save()
    end
    mData.red_packet = mRedPacket
    mData.today = self.m_oToday:Save()
    return mData
end

function COrgBaseMgr:Release()
    for _,oRedPacket in pairs(self.m_mRedPacket) do
        baseobj_safe_release(oRedPacket)
    end
    super(COrgBaseMgr).Release(self)
end

function COrgBaseMgr:GetExp()
    return self:GetData("exp",0)
end

function COrgBaseMgr:GetCash()
    return self:GetData("cash",0)
end

function COrgBaseMgr:SetPowerLimit(powerlimit)
    self:SetData("powerlimit",powerlimit)
end

function COrgBaseMgr:SetNeedAllow(needallow)
    self:SetData("needallow",needallow)
end

function COrgBaseMgr:GetPowerLimit()
    return self:GetData("powerlimit")
end

function COrgBaseMgr:GetNeedAllow()
    return self:GetData("needallow")
end

function COrgBaseMgr:SetSFlag(sflag)
    self:SetData("sflag",sflag)
end

function COrgBaseMgr:SetFlagBgID(flagbgid)
    self:SetData("flagbgid",flagbgid)
end

function COrgBaseMgr:GetSFlag()
    return self:GetData("sflag","")
end

function COrgBaseMgr:GetFlagBgID()
    return self:GetData("flagbgid")
end

function COrgBaseMgr:GetAim()
    return self:GetData("aim")
end

function COrgBaseMgr:SetAim(aim)
    self:SetData("aim", aim)
end

function COrgBaseMgr:GetLevel()
    return self:GetData("level", 1)
end

function COrgBaseMgr:GetMaxLevel()
    return self:GetData("maxlevel",1)
end

function COrgBaseMgr:AddCash(iAddCash,sReason,mArgs)
    local mArgs = mArgs or {}
    local iOrgID = self:GetInfo("orgid")
    assert(iAddCash>0,string.format("orgid:%s ,org:addcash err:%d", iOrgID, iAddCash))
    self:Dirty()
    local iCash = self:GetCash()
    local iMaxCash = gamedefines.COIN_TYPE[gamedefines.COIN_FLAG.COIN_ORG_CASH]["max"]
    local iWillAdd = math.min(iAddCash, iMaxCash - iCash)
    iCash = iCash + iAddCash
    iCash = math.min(iCash,iMaxCash)
    self:SetData("cash",iCash)
    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({cash = true})
    local mLogData = {
        orgid = iOrgID,
        reason = sReason,
        cash = iCash,
        val = iAddCash,
    }
    record.log_db("org", "addcash",mLogData)
    local iPid = mArgs.pid
    if iPid then
        if iWillAdd > 0 then
            self:AddShowKeep(iPid, 1015, iWillAdd)
        end
        global.oOrgMgr:Notify(iPid,string.format("获得%s公会资金",iAddCash))
    end
end

function COrgBaseMgr:ValidCash(iVal,mArgs)
    mArgs = mArgs or {}
    local iCash = self:GetData("cash",0)
    local iOrgID = self:GetInfo("orgid")
    assert(iVal>0,string.format("%d org cash err %d", iOrgID, iVal))
    if iCash >= iVal then
        return true
    end
    local sTip = mArgs.tip
    if not sTip then
        sTip = "公会资金不足"
    end
    local iPid = mArgs.pid
    if not mArgs.cancel_tip and iPid then
        global.oOrgMgr:Notify(iPid,sTip)
    end
    return false
end

function COrgBaseMgr:ResumeCash(iVal,sReason,mArgs)
    local oOrgMgr = global.oOrgMgr
    local iOrgID = self:GetInfo("orgid")
    local iCash = self:GetData("cash",0)
    mArgs = mArgs or {}
    assert(iVal>0 and iCash>=iVal,string.format("orgid:%d ,org:ResumeCash err:%d", iOrgID, iVal))

    local oOrg = self:GetOrg()

    iCash = iCash - iVal
    self:SetData("cash", iCash)
    oOrg:UpdateOrgInfo({cash= true})

    local mLogData = {
        orgid = iOrgID,
        reason = sReason,
        cash = iCash,
        val = iVal
    }
    record.log_db("org", "resumecash",mLogData)
end

function COrgBaseMgr:AddExp(iVal,sReason,mArgs)
    mArgs = mArgs or {}
    local iOrgID = self:GetInfo("orgid")
    assert(iVal>0,string.format("%d org cash err %d", iOrgID, iVal))
    self:Dirty()
    local iExp = self:GetExp()
    iExp = iExp + iVal
    self:SetData("exp",iExp)

    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({exp = true})
    local mLogData = {
        orgid = iOrgID,
        reason = sReason,
        exp = iExp,
        val = iVal,
    }
    record.log_db("org", "addexp",mLogData)

    local iPid = mArgs.pid
    if iPid then
        self:AddShowKeep(iPid, 1019, iVal)
        global.oOrgMgr:Notify(iPid,string.format("获得%s公会经验",iVal))
    end
    oOrg:UpdateAllMemShare()
end

function COrgBaseMgr:ValidExp(iVal,mArgs)
    mArgs = mArgs or {}
    local iExp = self:GetData("exp",0)
    local iOrgID = self:GetInfo("orgid")
    assert(iVal>0,string.format("%d org cash err %d", iOrgID, iVal))
    if iExp >= iVal then
        return true
    end
    local iPid = mArgs.pid
    local sTip = mArgs.tip
    if not sTip then
        sTip = "公会资金不足"
    end
    if not mArgs.cancel_tip and iPid then
        global.oOrgMgr:Notify(iPid,sTip)
    end
    return false
end

function COrgBaseMgr:ResumeExp(iVal,sReason,mArgs)
    mArgs = mArgs or {}
    local oOrgMgr = global.oOrgMgr
    local iOrgID = self:GetInfo("orgid")
    mArgs = mArgs or {}
    local iExp = self:GetData("exp",0)
    assert(iVal>0 and iExp>=iVal,string.format("orgid:%s ,org:ResumeCash err:%d", iOrgID, iVal))

    local oOrg = self:GetOrg()
    iExp = iExp - iVal
    self:SetData("exp", iExp)
    oOrg:UpdateOrgInfo({exp= true})
    local mLogData = {
        orgid = iOrgID,
        reason = sReason,
        exp = iExp,
        val = iVal,
    }
    record.log_db("org", "resumeexp",mLogData)
end

function COrgBaseMgr:GetSignDegree()
    return self:GetData("sign_degree",0)
end

function COrgBaseMgr:AddSignDegree(iDegree)
    self:Dirty()
    iDegree = iDegree or 1
    local iNowDegree = self:GetSignDegree()
    iNowDegree = iNowDegree + iDegree
    self:SetData("sign_degree",iNowDegree)
    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({sign_degree = true})
end

function COrgBaseMgr:ClearSignDegree()
    self:SetData("sign_degree",0)
    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({sign_degree = true})
end

function COrgBaseMgr:ResetActivePoint()
    self:Dirty()
    self:SetData("active_point",0)
    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({active_point = true})
end

function COrgBaseMgr:RewardActivePoint(iPoint,sReason,mArgs)
    mArgs = mArgs or {}
    self:Dirty()
    local iNowPoint = self:GetData("active_point",0)
    iNowPoint = iNowPoint + iPoint
    self:SetData("active_point",iNowPoint)
    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({active_point = true})
end

function COrgBaseMgr:GetActivePoint()
    return self:GetData("active_point",0)
end

function COrgBaseMgr:GetOpenRedPacket()
    return table_count(self.m_mRedPacket)
end

function COrgBaseMgr:GetRedPacketRest()
    local iSign = 0
    for idx,oRedPacket in pairs(self.m_mRedPacket) do
        if oRedPacket:GetRemainRedPacketAmount() > 0 then
            iSign = iSign | (1<<(idx-1))
        end
    end
    return iSign
end

function COrgBaseMgr:OpenRedPacket(oPlayer,idx,iGold,iAmount)
    self:Dirty()
    local iOrgID = self:GetInfo("orgid")
    local mArgs = {
        shape = oPlayer:GetShape(),
        title = "公会红包",
        gold = iGold,
        amount = iAmount,
        idx = idx,
        org_id = iOrgID,
    }
    self.m_mRedPacket[idx] = redpacket.NewRedPacket(mArgs)
end

function COrgBaseMgr:ClearRedPacket()
    self:Dirty()
    self.m_mRedPacket = {}
    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({red_packet = true})
    self:CheckRedPacketUI()
end

function COrgBaseMgr:ValidDrawRedPacket(oPlayer,idx)
    local oRedPacket = self.m_mRedPacket[idx]
    if not oRedPacket then
        return false
    end
    return oRedPacket:ValidDrawRedPacket(oPlayer)
end

function COrgBaseMgr:DrawOrgRedPacket(oPlayer,idx)
    local oRedPacket = self.m_mRedPacket[idx]
    local iOrgID = self:GetInfo("orgid")
    assert(oRedPacket,string.format("DrawOrgRedPacket err:%d %d %d",oPlayer:GetPid(),iOrgID,idx))
    self:Dirty()
    oRedPacket:DrawOrgRedPacket(oPlayer)
    if oRedPacket:GetRemainRedPacketAmount() < 1 then
        self:CheckRedPacketUI()
    else
        self:SendRedPacketUI(oPlayer)
    end
end

function COrgBaseMgr:CheckRedPacketUI()
    local oOrgMgr = global.oOrgMgr
    local oOrg = self:GetOrg()
    local memlist = oOrg:GetOrgMemList()
    for _,iPid in pairs(memlist) do
        local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:SendRedPacketUI(oPlayer)
        end
    end
end

function COrgBaseMgr:SendRedPacketUI(oPlayer)
    local redlist = {false,false,false}
    for idx,oRedPacket in ipairs(self.m_mRedPacket) do
        redlist[idx] = oRedPacket:ValidDrawRedPacket(oPlayer)
    end
    oPlayer:Send("GS2CControlRedPacketUI",{redlist=redlist})
end

function COrgBaseMgr:GetDrawRedPacketInfo(iPid,idx)
    local oRedPacket = self.m_mRedPacket[idx]
    if not oRedPacket then
        return
    end
    return oRedPacket:GetDrawRedPacketInfo(iPid)
end

function COrgBaseMgr:SendOrgRedPacket(oPlayer,idx)
    local oRedPacket = self.m_mRedPacket[idx]
    local mData = oRedPacket:PackRedPacket()
    oPlayer:Send("GS2COrgRedPacket",mData)
end

function COrgBaseMgr:GetWeekNo()
    return self:GetData("week_no")
end

function COrgBaseMgr:GetWeekNeedActivePoint()
    local iActiveLevel = self:GetData("active_level") or self:GetLevel()
    local iActivePoint = res["daobiao"]["org"]["org_grade"][iActiveLevel]["active_point"]
    return iActivePoint
end

function COrgBaseMgr:CheckDownLevel()
    local iActivePoint = self:GetActivePoint()
    local iNeedPoint = self:GetWeekNeedActivePoint()
    local iCreateWeekNo = self:GetData("create_week_no",0)

    local iNowWeekNo = get_weekno() - 1

    self:SetData("week_no",get_weekno())
    self:SetData("active_level",nil)
    self:ResetActivePoint()
    if iNowWeekNo <= iCreateWeekNo then
        return
    end

    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsOrgWarOpen() then
        return
    end

    --降级
    if iActivePoint < iNeedPoint then
        self:DownLevel()
    end
end

function COrgBaseMgr:DownLevel()
    local iOrgID = self:GetInfo("orgid")
    local oOrgMgr = global.oOrgMgr
    local iLevel = self:GetLevel()
    self:TrueDownLevel()
    record.user("org", "downlevel", {orgid=iOrgID,new_level=self:GetLevel(),old_level=iLevel})
    if self:GetLevel() < 1 then
        local oOrg = self:GetOrg()
        oOrg:SendAllMemMail(15)
        oOrgMgr:DismissNormalOrg(iOrgID)
    else
        local oOrg = self:GetOrg()
        local sText = oOrgMgr:GetOrgText(4004,{level=self:GetLevel()})
        oOrgMgr:SendOrgChat(sText,iOrgID,{pid = 0})
        local sText = oOrgMgr:GetOrgLog(1005,{orglevel = self:GetLevel()})
        oOrg:AddLog(0,sText)
        oOrg:SendAllMemMail(40)
    end
end

function COrgBaseMgr:PromoteLevel(oPlayer)
    local oOrgMgr = global.oOrgMgr
    local iLevel = self:GetLevel()
    local mData = res["daobiao"]["org"]["org_grade"][iLevel]
    local iExp = mData["exp_need"]
    local iCash = mData["coin_need"]
    if iExp > 0 then
        self:ResumeExp(iExp,"公会升级")
    end
    if iCash > 0 then
        self:ResumeCash(iCash,"公会升级")
    end

    if not self:GetData("active_level") then
        self:SetData("active_level",iLevel)
    end
    self:TruePromoteLevel()

    local iOrgID = self:GetInfo("orgid")

    local sText = oOrgMgr:GetOrgText(4001,{level=self:GetLevel()})
    oOrgMgr:SendOrgChat(sText,iOrgID,{pid = 0})
    oOrgMgr:Notify(oPlayer:GetPid(),oOrgMgr:GetOrgText(4002,{level = self:GetLevel()}))
    local sLog = oOrgMgr:GetOrgLog(1004,{orglevel = self:GetLevel()})
    local oOrg = self:GetOrg()
    if oOrg then
        oOrg:AddLog(oPlayer:GetPid(),sLog)
    end
    record.user("org", "uplevel", {pid=oPlayer:GetPid(), orgid=iOrgID,new_level=self:GetLevel(),old_level=iLevel})
    oOrg:PushAchieveOrgLv()
    oOrg:UpdateAllMemShare()
    oOrgMgr:UpdateRankOrgInfo(oOrg)

    if self:GetLevel() > self:GetMaxLevel() then
        self:GiveGoldCoinBack(self:GetLevel())
    end
    self:CheckMaxLevel()
end

function COrgBaseMgr:GiveGoldCoinBack(iLevel)
    local oOrg = self:GetOrg()
    if oOrg then
        local mData = res["daobiao"]["org"]["org_grade"][iLevel]
        local iGoldCoin = mData["moneyback"]
        local iCreater = oOrg:GetCreater()
        local oMem = oOrg:GetMember(iCreater)
        if oMem and iGoldCoin > 0 then
            local oOrgMgr = global.oOrgMgr
            local mMail, sMail = oOrgMgr:GetMailInfo(46)
            mMail.context = string.gsub(mMail.context,"$level",tostring(iLevel))
            oOrgMgr:SendMail(0, sMail, iCreater, mMail, {
                {sid = gamedefines.COIN_FLAG.COIN_GOLD, value = iGoldCoin}
            })
        end
    end
end

function COrgBaseMgr:TrueDownLevel()
    self:Dirty()
    local iLevel = self:GetData("level",1)
    iLevel = iLevel - 1
    self:SetData("level",iLevel)
    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({level = true})
end

function COrgBaseMgr:TruePromoteLevel()
    self:Dirty()
    local iLevel = self:GetData("level",1)
    iLevel = iLevel + 1
    self:SetData("level",iLevel)
    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({level = true})
end

function COrgBaseMgr:CheckMaxLevel()
    self:Dirty()
    local iLevel = self:GetData("level",1)
    local iMaxLevel = self:GetData("maxlevel",1)
    self:SetData("maxlevel",math.max(iLevel,iMaxLevel))
end

function COrgBaseMgr:InOrgWishUI(iPid)
    if self.m_mOpenWishUI[iPid] then
        return true
    end
    return false
end

function COrgBaseMgr:OpenWishUI(iPid)
    self.m_mOpenWishUI[iPid] = true
end

function COrgBaseMgr:RemoveWish(iPid)
    self.m_mOpenWishUI[iPid] = nil
end

function COrgBaseMgr:BoardCastWishUI(sMessage,mNet)
    local oOrgMgr = global.oOrgMgr
    for iPid,_ in pairs(self.m_mOpenWishUI) do
        local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send(sMessage,mNet)
        end
    end
end

function COrgBaseMgr:OnLeaveOrg(iPid)
    --
end

function COrgBaseMgr:IsOpenRedPacket()
    return self.m_oToday:Query("open_red_packet")
end

function COrgBaseMgr:SetOpenRedPacket()
    self.m_oToday:Set("open_red_packet",true)
end

function COrgBaseMgr:AddShowKeep(iPid, iVirtualSid, iVal)
    interactive.Send(".world", "org", "AddShowKeep", {pid=iPid,virtualsid=iVirtualSid,val=iVal})
end

function COrgBaseMgr:GetRank()
   return self:GetData("rank",0)
end

function COrgBaseMgr:SetRank(iRank)
    self:SetData("rank",iRank)
    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({rank = true})
end

function COrgBaseMgr:GetPrestige()
    return self:GetData("prestige",0)
end

function COrgBaseMgr:AddPrestige(iAdd,sReason,mArgs)
    mArgs = mArgs or {}
    local iPid = mArgs.pid
    local iOrgID = self:GetInfo("orgid")
    assert(iAdd>0,string.format("orgid:%s ,org:addcash err:%d", iOrgID, iAdd))

    self:Dirty()

    local iPrestige = self:GetPrestige()
    local iMaxValue = gamedefines.COIN_TYPE[gamedefines.COIN_FLAG.COIN_ORG_PRESTIGE]["max"]
    local iWillAdd = math.min(iAdd, iMaxValue - iPrestige)
    iPrestige = iPrestige + iAdd
    iPrestige = math.min(iPrestige,iMaxValue)
    self:SetData("prestige",iPrestige)

    local oOrg = self:GetOrg()
    oOrg:UpdateOrgInfo({prestige = true})
    if iPid then
        global.oOrgMgr:Notify(iPid,string.format("获得%s公会声望",iWillAdd))
    end
    global.oOrgMgr:PushDataToOrgPrestigeRank(oOrg)
end

function COrgBaseMgr:QueryKickCnt(iPosition)
   local mKickCnt = self.m_oToday:Query("kickcnt",{})
   return mKickCnt[iPosition]  or 0
end

function COrgBaseMgr:AddKickCnt(iPosition)
    local mKickCnt = self.m_oToday:Query("kickcnt",{})
    if iPosition then
        mKickCnt[iPosition] = mKickCnt[iPosition] or 0
        mKickCnt[iPosition] = mKickCnt[iPosition] + 1
        self.m_oToday:Set("kickcnt",mKickCnt)
    end
end
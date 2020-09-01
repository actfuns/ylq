local global = require "global"
local interactive = require "base.interactive"
local extend = require "base.extend"
local record = require "public.record"
local res = require "base.res"
local cjson = require "cjson"
local httpuse = require "public.httpuse"
local colorstring = require "public.colorstring"
local router = require "base.router"

local shareobj = import(lualib_path("base.shareobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item.loaditem"))
local analy = import(lualib_path("public.dataanaly"))

function NewOrgMgr(...)
    return COrgMgr:New(...)
end

COrgMgr = {}
COrgMgr.__index = COrgMgr
inherit(COrgMgr,logic_base_cls())

function COrgMgr:New()
    local o = super(COrgMgr).New(self)
    o.m_mPlayerShareReader = {}
    return o
end

function COrgMgr:LoginData(oPlayer)
    local mToday = {
        org_build_status = oPlayer.m_oToday:Query("org_build_status",0),
        org_sign_reward = oPlayer.m_oToday:Query("org_sign_reward",0),
        org_red_packet = oPlayer.m_oToday:Query("org_red_packet",0),
        give_org_wish = oPlayer.m_oToday:Query("give_org_wish",{}),
        give_org_equip = oPlayer.m_oToday:Query("give_org_equip",{}),
        org_build_time = oPlayer.m_oToday:Query("org_build_time",0),
        org_wish = oPlayer.m_oToday:Query("org_wish",0),
        org_wish_equip = oPlayer.m_oToday:Query("org_wish_equip",0),
        org_build_type = oPlayer.m_oToday:Query("org_build_type",0),
        give_wish_cnt = oPlayer.m_oToday:Query("give_wish_cnt",0),
    }
    return {
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        org_offer = oPlayer:GetOffer(),
        active_point = oPlayer:Active(),
        shape = oPlayer:GetShape(),
        power = oPlayer:GetPower(),
        model_info = oPlayer:GetModelInfo(),
        leaveorg = oPlayer:GetPreLeaveOrgInfo(),
        today = mToday,
        dayno = get_dayno(),
        school_branch = oPlayer:GetSchoolBranch(),
    }
end

function COrgMgr:OnLogin(oPlayer, bReEnter)
    interactive.Send(".org", "common", "OnLogin", {
        pid = oPlayer:GetPid(),
        reenter = bReEnter,
        info = self:LoginData(oPlayer),
    })
    if not bReEnter then
        self.m_mPlayerShareReader[oPlayer:GetPid()] = NewOrgInfoShareObj()
    end
end

function COrgMgr:GetOrgInfoReader(iPid)
    return self.m_mPlayerShareReader[iPid]
end

function COrgMgr:CloseGS()
    interactive.Send(".org", "common", "CloseGS", {})
end

function COrgMgr:OnDisconnected(oPlayer)
    interactive.Send(".org", "common", "OnDisconnected", {
        pid = oPlayer:GetPid(),
    })
    oPlayer:SyncTosOrg({logout_time=true})
end

function COrgMgr:OnLogout(oPlayer)
    local iPid = oPlayer:GetPid()
    oPlayer:SyncTosOrg({logout_time=true})
    interactive.Send(".org", "common", "OnLogout", {
        pid = oPlayer:GetPid(),
    })
    local oShareObj = self:GetOrgInfoReader(iPid)
    self.m_mPlayerShareReader[iPid] = nil
    if oShareObj then
        oShareObj:Release()
    end
end

function COrgMgr:OnCreateOrg(mOrgInfo)
    local iOrgID = mOrgInfo.orgid
    if not iOrgID then return end
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("terrawars")
    if oHuoDong then
        oHuoDong:AfterCreateOrg(iOrgID,mOrgInfo)
    end
end

function COrgMgr:OnJoinOrg(mPlayerInfo)
    local iPid = mPlayerInfo.pid
    local iOrgID = mPlayerInfo.orgid
    local iPos = mPlayerInfo.position
    if not iOrgID then return end
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("terrawars")
    if oHuoDong then
        oHuoDong:AfterAddMem(iOrgID,mPlayerInfo)
    end
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer and not oPlayer:GetNowWar() then
        oPlayer:Send("GS2COpenOrgMainUI",{})
    end
    if oPlayer then
        self:ResetPlayerOrgAttr(iPid,iPos)
    end
end

function COrgMgr:AddShowKeep(iPid, iVirtualSid, iVal)
    local oItem = loaditem.GetItem(iVirtualSid)
    local mShowInfo = oItem:GetShowInfo()
    mShowInfo.amount = iVal
    global.oUIMgr:AddKeepItem(iPid, mShowInfo)
end

function COrgMgr:SyncPlayerData(iPid,mData)
    interactive.Send(".org", "common", "SyncPlayerData", {
        pid = iPid,
        data = mData
    })
end

function COrgMgr:OrgSignReward(oPlayer,mItemList)
    local iPid = oPlayer:GetPid()
    local mLogItem = {}
    for _,mItemData in pairs(mItemList) do
        local sShape = mItemData["sid"]
        local iAmount = mItemData["amount"]
        while(iAmount > 0) do
            local oItem = loaditem.ExtCreate(sShape)
            local iAddAmount = math.min(oItem:GetMaxAmount(),iAmount)
            iAmount = iAmount - iAddAmount
            oItem:SetAmount(iAddAmount)

            if bBind then
                oItem:Bind(iPid)
            end
            local mShowInfo = oItem:GetShowInfo()
            mLogItem[oItem:SID()] = mShowInfo.amount
            oPlayer:RewardItem(oItem,"公会签到",{cancel_tip=1})
            if iAmount <= 0 then
                break
            end
        end
    end
    global.oUIMgr:ShowKeepItem(iPid)
    oPlayer:LogAnalyGame({},"orgsign",mLogItem)
end

function COrgMgr:GetOrgText(iText, m)
    local sText = colorstring.GetTextData(iText, {"org"})
    if sText and m then
        sText = colorstring.FormatColorString(sText, m)
    end
    return sText
end

function COrgMgr:SpreadOrg(iPid,iOrgID,sOrgName)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end

    local sText = self:GetOrgText(4006,{orgname = sOrgName})

    local sLink = string.format("%s{link10,%d}",sText,iOrgID)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendWorldChat(sLink,{pid = 0})

    oPlayer:NotifyMessage("招募信息发布成功")
end

function COrgMgr:LogAnalyData(iPid,mLog)
    local oWorldMgr = global.oWorldMgr
    mLog = mLog or {}
    if oPlayer then
        mLog = table_combine(mLog,oPlayer:GetPubAnalyData())
        analy.log_data("faction",mLog)
    else
        oWorldMgr:LoadProfile(iPid,function (oProfile)
            mLog = table_combine(mLog,oProfile:GetPubAnalyData())
            analy.log_data("faction",mLog)
        end)
    end
end

function COrgMgr:Forward(sCmd, iPid, mData)
    interactive.Send(".org", "common", "Forward", {
        pid = iPid, cmd = sCmd, data = mData,
    })
end

function COrgMgr:OnKickMember(iPid)
    local oWorldMgr = global.oWorldMgr
    local oKick = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oKick then
        global.oNotifyMgr:Notify(iPid,"您已退出公会，您的个人积分将会清零。")
    else
        local oMailMgr = global.oMailMgr
        local mData, sName = oMailMgr:GetMailInfo(30)
        oMailMgr:SendMail(0, sName,iPid, mData, {}, {},{})
    end
end

function COrgMgr:OnLeaveOrg(iOrgID,iPid,mGiveItem)
    mGiveItem = mGiveItem or {}
    local mMailItem = {}
    for _,mItem in pairs(mGiveItem) do
        local iShape,iAmount = table.unpack(mItem)
        local oItem = loaditem.Create(iShape)
        oItem:SetAmount(iAmount)
        table.insert(mMailItem,oItem)
    end
    if #mMailItem > 0 then
        local mData, sName = global.oMailMgr:GetMailInfo(16)
        global.oMailMgr:SendMail(0, sName,iPid, mData, {}, mMailItem,{})
    end

    local oWorldMgr = global.oWorldMgr
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("terrawars")
    local oKick = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    oHuoDong:AfterLeaveOrg(iOrgID,iPid)
    global.oTitleMgr:RemoveTitlesByKey(iPid,"org")

    self:ClearPlayerOrgAttr(iPid)
end

function COrgMgr:HandleOrgChat(iPid,sMsg)
    interactive.Send(".org", "common", "HandleOrgChat", {
        pid = iPid,
        msg = sMsg,
    })
end


function COrgMgr:RewardOrgCash(iOrgID,iVal,sReason)
    interactive.Send(".org", "common", "RewardOrgCash", {
        orgid = iOrgID,
        value = iVal,
        reason = sReason,
    })
end

function COrgMgr:RewardOrgExp(iOrgID,iVal,sReason)
    interactive.Send(".org", "common", "RewardOrgExp", {
        orgid = iOrgID,
        value = iVal,
        reason = sReason,
    })
end

function COrgMgr:RewardOrgOffer(iPid,iVal)
    interactive.Send(".org", "common", "RewardOrgOffer", {
        pid = iPid,
        value = iVal,
    })
end

function COrgMgr:RewardActivePoint(iPid,iVal,sReason,mArgs)
    interactive.Send(".org", "common", "RewardActivePoint", {
        pid = iPid,
        value = iVal,
        reason = sReason,
        args=mArgs,
    })
end

function COrgMgr:AddPrestige(iOrgID, iVal, sReason, mArgs)
     interactive.Send(".org", "common", "AddPrestige", {
        orgid = iOrgID,
        value = iVal,
        reason = sReason,
        args=mArgs,
    })
end

function COrgMgr:GetOrgLog(iText,m)
    local mData = res["daobiao"]["org"]["org_log"]
    local sText = mData[iText]["text"]
    if sText and m then
        sText = colorstring.FormatColorString(sText,m)
    end
    return sText
end

function COrgMgr:GetPlayerOrgInfo(iPid,sAttr,default)
    local oShareObj = self:GetOrgInfoReader(iPid)
    if oShareObj then
        oShareObj:Update()
        return oShareObj:GetData(sAttr,default)
    end
    return default
end

function COrgMgr:GetOrgMemList(mOrgId,fCallBack)
    local f1
    f1 = function(mRecord, mData)
        fCallBack(mData.data)
    end
    local mData = {
        data = mOrgId,
    }
    interactive.Request(".org","common","GetOrgMemList",mData,f1)
end

function COrgMgr:IsOrgLeader(iPid)
    local iPos = self:GetPlayerOrgInfo(iPid,"orgpos",0)
    return iPos == gamedefines.ORG_POSITION.LEADER
end

function COrgMgr:UpdateOrgInfo(iOrgID,mInfo)
    if mInfo and mInfo["sflag"] then
        local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
        oHuodong:UpdateOrgFlag(iOrgID,mInfo["sflag"])
    end
    -- body
end

function COrgMgr:NewHour(iDay,iHour)
    interactive.Send(".org", "common", "NewHour", {
        weekday = iDay,
        hour = iHour,
    })
end

function COrgMgr:OnUpdatePosition(iPid,iPos)
    self:ResetPlayerOrgAttr(iPid,iPos)
end

function COrgMgr:ResetPlayerOrgAttr(iPid,iPos)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    local mApplyAttr = res["daobiao"]["org"]["org_attr"][iPos]
    if mApplyAttr then
        oPlayer:ExecuteCPower("MultiSetRatioApply","org",mApplyAttr)
        oPlayer:ActivePropChange()
    end
end

function COrgMgr:ClearPlayerOrgAttr(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    oPlayer:ExecuteCPower("ClearRatioApply","org")
    oPlayer:ActivePropChange()
end

function NewOrgInfoShareObj()
    return COrgInfoShareObj:New()
end

COrgInfoShareObj = {}
COrgInfoShareObj.__index = COrgInfoShareObj
inherit(COrgInfoShareObj, shareobj.CShareReader)

function COrgInfoShareObj:New()
    local o = super(COrgInfoShareObj).New(self)
    o.m_mBase = {}
    return o
end

function COrgInfoShareObj:Unpack(m)
    self.m_mBase = m.base or self.m_mBase
end

function COrgInfoShareObj:GetData(sAttr,default)
    return self.m_mBase[sAttr] or default
end

--import module
local global  = require "global"
local extend = require "base.extend"
local colorstring = require "public.colorstring"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    return o
end

function CHuodong:IsClose(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if oWorldMgr:IsClose("sociality") then
        oNotifyMgr:Notify(iPid, "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return true
    end

    return false
end

function CHuodong:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("sociality", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CHuodong:GetSocialText(iText, m)
    if not m then
        m = {"huodong",self.m_sName}
    end
    return colorstring.GetTextData(iText, m)
end

function CHuodong:GetSocialData(iDisplay)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["sociality"][iDisplay]
    assert(mData, string.format("sociality err: %s not exsit!", iDisplay))
    return mData
end

function CHuodong:ValidDisplaySociality(oPlayer, iTargetPid, iDisplay)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    local mData = self:GetSocialData(iDisplay)
    if not mData then
        return false
    end
    if oPlayer:GetNowWar() then
        return false
    end
    local iNow = get_time()
    if not self:IsSingle(iDisplay) then
        local iDisplayCD = oPlayer:GetInfo("display_cd", 0)
        if iDisplayCD > iNow then
            local sMsg = self:GetSocialText(1004)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        local iSuccDisplayCD = oPlayer:GetInfo("success_display_cd", 0)
        if iSuccDisplayCD > iNow then
            local sMsg = self:GetSocialText(1006)
            oNotifyMgr:Notify(iPid, string.format(sMsg, iSuccDisplayCD - iNow))
            return false
        end
        if not oPlayer:IsSingle() then
            local sMsg = self:GetSocialText(1009)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        if iTargetPid == 0 then
            local sMsg = self:GetSocialText(1003)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
        if not oTarget then
            local sMsg = self:GetSocialText(1013)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        if oTarget:GetInfo("social_invite_cd", 0) > iNow then
            local sMsg = self:GetSocialText(1005)
            sMsg = colorstring.FormatColorString(sMsg, {role = oTarget:GetName()})
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        if oTarget:GetNowWar() then
            local sMsg = self:GetSocialText(1012)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        if oTarget:IsInviteSocialDisplay() then
            local sMsg = self:GetSocialText(1005)
            sMsg = colorstring.FormatColorString(sMsg, {role = oTarget:GetName()})
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        if not oTarget:IsSingle() then
            local sMsg = self:GetSocialText(1008)
            sMsg = colorstring.FormatColorString(sMsg, {role = oTarget:GetName()})
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        if self:CheckDoDoubleAction(oTarget) then
            local sMsg = self:GetSocialText(1018)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        if self:CheckDoDoubleAction(oPlayer) then
            local sMsg = self:GetSocialText(1017)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        local iScene1 = oPlayer.m_oActiveCtrl:GetNowSceneID()
        local iScene2 = oTarget.m_oActiveCtrl:GetNowSceneID()
        if (iScene1 ~= iScene2) or oPlayer:IsOutOfAoi(oTarget) then
            local sMsg = self:GetTextData(1014)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
    else
        local iDisplayCD = oPlayer:GetInfo("single_display_cd", 0)
        if iDisplayCD > iNow then
            local sMsg = self:GetSocialText(1004)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
        if self:CheckDoDoubleAction(oPlayer) then
            local sMsg = self:GetSocialText(1017)
            oNotifyMgr:Notify(iPid, sMsg)
            return false
        end
    end
    return true
end

function CHuodong:CheckDoDoubleAction(oPlayer)
    local m = oPlayer:GetInfo("social_display")
    if m then
        local iDisplay = m.display_id
        local iStartTime = m.start_time
        if not self:IsSingle(iDisplay) then
            local mData = self:GetSocialData(iDisplay)
            if (iStartTime + mData.action_time) > get_time() then
                return true
            end
        end
        oPlayer:CancelSocailDisplay()
    end
    return false
end

function CHuodong:IsSingle(iDisplay)
    local mData = self:GetSocialData(iDisplay)
    if mData.double == 1 then
        return false
    else
        return true
    end
end

function CHuodong:DisplaySociality(oPlayer, iTargetPid, iDisplay)
    local mData = self:GetSocialData(iDisplay)
    if mData.emoji == 1 then
        -- self:DisplayEmoji()
    else
        self:DisplayAction(oPlayer,iTargetPid,iDisplay)
    end
end

function CHuodong:DisplayAction(oPlayer,iTargetPid,iDisplay)
    if self:IsSingle(iDisplay) then
        self:SingleDisplayAction(oPlayer, iTargetPid, iDisplay)
    else
        self:DoubleDisplayAction(oPlayer, iTargetPid, iDisplay)
    end
end

function CHuodong:SingleDisplayAction(oPlayer,iTargetPid,iDisplay)
    local mSync = {
        start_time = get_time(),
        display_id = iDisplay,
        target = iTargetPid,
        is_invite = 0,
    }
    self:DoSocialDisplay(oPlayer, mSync)
    oPlayer:SetInfo("single_display_cd", get_time() + self:GetConfigValue("single_display_cd"))
    local mData = self:GetSocialData(iDisplay)
end

function CHuodong:DoSocialDisplay(oPlayer, mSync)
    oPlayer:SetInfo("social_display", mSync)
    oPlayer:SyncSceneInfo({social_display = mSync})
    oPlayer:Send("GS2CSocialDisplayInfo", {social_display = mSync})
end

function CHuodong:DoubleDisplayAction(oPlayer,iTargetPid,iDisplay)
    local oWorldMgr = global.oWorldMgr
    local oHuodongMgr = global.oHuodongMgr
    local oCbMgr = global.oCbMgr

    local iPid = oPlayer:GetPid()
    local mData = self:GetSocialData(iDisplay)
    local iText = mData.text_id
    assert(iText > 0, string.format("sociality err, id: %s, double display text id must > 0", iDisplay))

    local mCBData = self:GetSocialText(iText)
    mCBData = oCbMgr:PackConfirmData(nil, mCBData)
    mCBData["simplerole"] = oPlayer:PackSimpleRoleInfo()
    mCBData["uitype"] = 3
    mCBData["sContent"] = colorstring.FormatColorString(mCBData["sContent"], {role = oPlayer:GetName()})
    local func = function (oPlayer, mData)
        local oHuodong = oHuodongMgr:GetHuodong("sociality")
        if oHuodong then
            oHuodong:DoDoubleDisplayAction(iPid, iTargetPid, iDisplay, mData)
        end
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
    local mBlack = oTarget:GetInfo("sociality_blacklist", {})
    local iBlack = mBlack[iPid]
    if iBlack and iBlack > get_time() then
        self:DisAgreeDisplayAction(iPid, iTargetPid, iDisplay)
        return
    end
    local iTimeOut = mCBData["time"] or 5
    oTarget:SetInfo("social_display_invite", {
        invitor = iPid,
        display = iDisplay,
        sessionidx = iSession,
        timeout = iTimeOut,
        })
    local iSession= oCbMgr:SetCallBack(iTargetPid,"GS2CConfirmUI",mCBData,nil ,func)
    local sCbFunc = string.format("sociality_%s", iTargetPid)
    self:DelTimeCb(sCbFunc)
    self:AddTimeCb(sCbFunc, iTimeOut * 1000, function()
        oCbMgr:RemoveCallBack(iSession)
        local oHuodong = oHuodongMgr:GetHuodong("sociality")
        if oHuodong then
            oHuodong:DoDoubleDisplayAction(iPid, iTargetPid, iDisplay, {
                sessionidx = iSession,
                answer = 0,
                blacklisttime = 0,
                })
        end
    end)
    oPlayer:NotifyMessage(self:GetSocialText(1010))
    oPlayer:SetInfo("display_cd", get_time() + self:GetConfigValue("display_cd"))
    oPlayer:SetInfo("social_invite_cd", get_time() + self:GetConfigValue("display_cd"))
end

function CHuodong:DoDoubleDisplayAction(iPid, iTargetPid, iDisplay, mData)
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
    self:DelTimeCb(string.format("sociality_%s", iTargetPid))
    if oTarget then
        if mData.blacklisttime ~= 0 then
            local mBlack = oTarget:GetInfo("sociality_blacklist", {})
            mBlack[iPid] = get_time() + self:GetConfigValue("black_list_time")
            oTarget:SetInfo("sociality_blacklist", mBlack)
        end
        oTarget:SetInfo("social_display_invite", nil)
    end
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:SetInfo("social_invite_cd", 0)
    end
    if mData.answer == 1 then
        self:AgreeDisplayAction(iPid, iTargetPid, iDisplay)
    else
        self:DisAgreeDisplayAction(iPid, iTargetPid, iDisplay)
    end
end

function CHuodong:AgreeDisplayAction(iPid, iTargetPid, iDisplay)
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    local oHuodongMgr = global.oHuodongMgr

    if self:ValidAgreeDisplayAction(iPid, iTargetPid, iDisplay) then
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
        local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
        local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
        oPlayer:SetInfo("sociality_scene", {pid = iPid, target = iTargetPid, display = iDisplay})
        local mData = {
                    x = mNowPos.x,
                    y = mNowPos.y,
                    face_x = mNowPos.face_x,
                    face_y = mNowPos.face_y,
            }
        local lPid = {iPid, iTargetPid}
        oNowScene:SyncPlayersPos(lPid, mData, function(mRecord, mData)
            self:TrueDoAgreeDisplayAction(iPid, iTargetPid)
        end)
    end
end

function CHuodong:TrueDoAgreeDisplayAction(iPid, iTargetPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
    if not oTarget or not oPlayer then
        return
    end
    local m = oPlayer:GetInfo("sociality_scene")
    if not m then
        return
    end
    local iPid = m.pid
    local iTargetPid = m.target
    local iDisplay = m.display
    if not iTargetPid or not iDisplay then
        return
    end
    oPlayer:SetInfo("sociality_scene", nil)
    if self:ValidAgreeDisplayAction(iPid, iTargetPid, iDisplay) then
        local mSync = {
            start_time = get_time(),
            display_id = iDisplay,
            target = iTargetPid,
            is_invite = 1,
            }
        self:DoSocialDisplay(oPlayer, mSync)
        mSync = {
            start_time = get_time(),
            display_id = iDisplay,
            target = iPid,
            is_invite = 0,
        }
        self:DoSocialDisplay(oTarget, mSync)
        oPlayer:SetInfo("success_display_cd", get_time() + self:GetConfigValue("success_display_cd"))
    end
end

function CHuodong:ValidAgreeDisplayAction(iPid, iTargetPid, iDisplay)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        local sMsg = self:GetTextData(1013)
        oNotifyMgr:Notify(iPid, sMsg)
        return false
    end
    if oPlayer:GetNowWar() then
        return false
    end
    if not oPlayer:IsSingle() then
        return false
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
    if not oTarget then
        self:DisAgreeDisplayAction(iPid, iTargetPid, iDisplay)
        return false
    end
    local iScene1 = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local iScene2 = oTarget.m_oActiveCtrl:GetNowSceneID()
    if (iScene1 ~= iScene2) or oPlayer:IsOutOfAoi(oTarget) then
        local sMsg = self:GetTextData(1014)
        oNotifyMgr:Notify(iTargetPid, sMsg)
        return false
    end
    if oTarget:GetNowWar() then
        local sMsg = self:GetTextData(1012)
        oNotifyMgr:Notify(iPid, sMsg)
        return false
    end
    if not oTarget:IsSingle() then
        local sMsg = self:GetTextData(1015)
        oNotifyMgr:Notify(iPid, sMsg)
        return false
    end
    return true
end

function CHuodong:DisAgreeDisplayAction(iPid, iTargetPid, iDisplay)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    oWorldMgr:LoadProfile(iTargetPid, function(oProfile)
        self:NotifyDisAgree(iPid, oProfile)
    end)
end

function CHuodong:NotifyDisAgree(iPid, oFrdProfile)
        local sMsg = self:GetSocialText(1007)
        sMsg = colorstring.FormatColorString(sMsg, {role = oFrdProfile:GetName()})
        global.oNotifyMgr:Notify(iPid, sMsg)
end
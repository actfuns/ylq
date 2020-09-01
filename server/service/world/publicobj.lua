--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base/extend"
local res = require "base.res"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

local learnskill = import(service_path("skill/skilllearn"))
local loadskill = import(service_path("skill/loadskill"))

local function SortItemFunc(oItem1,oItem2)
    if oItem1:SortNo() ~= oItem2:SortNo() then
        return oItem1:SortNo() < oItem2:SortNo()
    else
        if oItem1:SID() ~= oItem2:SID() then
            return oItem1:SID() < oItem2:SID()
        else
            if oItem1:GetAmount() ~= oItem2:GetAmount() then
                return oItem1:GetAmount() > oItem2:GetAmount()
            else
                return oItem1.m_ID < oItem2.m_ID
            end
        end
    end
    return false
end

function NewPubMgr()
    local o = CPublicMgr:New()
    return o
end

CPublicMgr = {}
CPublicMgr.__index = CPublicMgr
inherit(CPublicMgr, logic_base_cls())

function CPublicMgr:New()
    local o = super(CPublicMgr).New(self)
    o:InitLearnSkill()
    return o
end

function CPublicMgr:InitLearnSkill()
    self.m_oLearnSchoolSkill = learnskill.NewSchoolSkillLearn()
end

function CPublicMgr:OnlineExecute(iPid,sFunc,mArgs)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadPrivy(iPid,function (oPrivy)
        if oPrivy then
            oPrivy:AddFunc(sFunc, mArgs)
        end
    end)
end

function CPublicMgr:GetLearnSkillObj(sType)
    if sType == "school" then
        return self.m_oLearnSchoolSkill
    end
end

function CPublicMgr:AddPkInvite(oPlayer,oTarget)
    self.m_mPkInvite = self.m_mPkInvite or {}
    self.m_mPkInvite[oTarget:GetPid()] = self.m_mPkInvite[oTarget:GetPid()] or {}
    self.m_mPkInvite[oTarget:GetPid()][oPlayer:GetPid()] = get_time()
end

function CPublicMgr:InvitePKTimeLimit(oPlayer,oTarget)
    if not self.m_mPkInvite or not self.m_mPkInvite[oTarget:GetPid()] or not self.m_mPkInvite[oTarget:GetPid()][oPlayer:GetPid()] or (get_time() - self.m_mPkInvite[oTarget:GetPid()][oPlayer:GetPid()]) > 5000 then
        return 0
    end
    return (5 - (get_time() - self.m_mPkInvite[oTarget:GetPid()][oPlayer:GetPid()]))
end

function CPublicMgr:ValidPK(oPlayer,oTarget)
    local oNowWar = oTarget.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        return false
    end
    local oTeam = oPlayer:HasTeam()
    local oTargetTeam = oTarget:HasTeam()
    if oTeam and oTargetTeam then
        if oTeam:TeamID() == oTargetTeam:TeamID() then
            return false
        end
    end
    return true
end

function CPublicMgr:PK(oPlayer,iTarget)
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local oWarMgr = global.oWarMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        return
    end
    if not self:ValidPK(oPlayer,oTarget) then
        return
    end
    local mArgs = {
        war_type = gamedefines.WAR_TYPE.PVP_TYPE,
        pvpflag = 1,
    }
    local oWar = oWarMgr:CreateWar(mArgs)
    oWar:SetData("close_auto_skill",true)

    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    assert(not oNowWar,string.format("CreateWar err %d",iPid))
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    local oNowWar = oTarget.m_oActiveCtrl:GetNowWar()
    assert(not oNowWar,string.format("CreateWar err %d",iPid))
    local ret
    if oPlayer:HasTeam() then
        if oPlayer:IsTeamLeader() then
            ret = oWarMgr:TeamEnterWar(oPlayer,oWar:GetWarId(),{camp_id=1},true)
        else
            ret = oWarMgr:EnterWar(oPlayer, oWar:GetWarId(), {camp_id = 1}, true)
        end
    else
        ret = oWarMgr:EnterWar(oPlayer, oWar:GetWarId(), {camp_id = 1}, true)
    end
    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end
    if oTarget:HasTeam() then
        if oTarget:IsTeamLeader() then
            ret = oWarMgr:TeamEnterWar(oTarget,oWar:GetWarId(),{camp_id=2},true)
        else
            ret = oWarMgr:EnterWar(oTarget, oWar:GetWarId(), {camp_id = 2}, true)
        end
    else
        ret = oWarMgr:EnterWar(oTarget, oWar:GetWarId(), {camp_id = 2}, true)
    end
    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end
    oWarMgr:StartWarConfig(oWar:GetWarId())
end

function CPublicMgr:WatchWar(oPlayer,iTarget)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oWarMgr = global.oWarMgr
    local iPid = oPlayer:GetPid()
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        return
    end
    if oPlayer.m_oActiveCtrl:GetNowWar() then
        return
    end
    if not oPlayer:IsSingle() and not oPlayer:IsTeamLeader() then
        oNotifyMgr:Notify(iPid,"组队下无法进行观战")
        return
    end
    local oNowWar = oTarget.m_oActiveCtrl:GetNowWar()
    if not oNowWar then
        oNotifyMgr:Notify(iPid,string.format("%s不在战斗中，无法观战",oTarget:GetName()))
        return
    end
    if oNowWar:GetData("war_film_id") then
        return
    end
    local bValid,sMsg = oPlayer:ValidWatchWar()
    if not bValid then
        oNotifyMgr:Notify(iPid,sMsg)
        return
    end
    local iCamp = oNowWar:GetCampId(iTarget)
    if not iCamp then
        iCamp = oNowWar:GetObserverCamp(iTarget)
    end
    local mArgs = {
        observer_view = iCamp or 1,
    }
    oWarMgr:ObserverEnterWar(oPlayer,oNowWar:GetWarId(),mArgs)
end

function CPublicMgr:LeaveWatchWar(oPlayer)
    local iPid = oPlayer:GetPid()
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if not oNowWar then
        return
    end
    if not oNowWar:IsObserver(iPid) then
        return
    end
    local oWarMgr = global.oWarMgr
    oWarMgr:LeaveWar(oPlayer)
end

function CPublicMgr:PowerBaseVal(sAttr)
    local iBase = 0
    if sAttr == "critical_damage" then
        iBase = 15000
    end
    if sAttr == "speed" then
        iBase = 400
    end
    return iBase
end

--伙伴导表数据
function CPublicMgr:GetPartnerData(iPartnerType)
    local res = require "base.res"
    local mData = res["daobiao"]["partner"]["partner_info"][iPartnerType]
    assert(mData, string.format("partnerdata err:%s", iPartnerType))
    return mData
end

function CPublicMgr:InvitePlayerPK(oPlayer,mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oSceneMgr = global.oSceneMgr
    local iPid = oPlayer:GetPid()
    local oTeam = oPlayer:HasTeam()
    local iTarget = mData["target_id"]

    if oTeam and not oTeam:IsShortLeave(oPlayer.m_iPid) and oTeam:Leader() ~= oPlayer.m_iPid then
        oNotifyMgr:Notify(oPlayer.m_iPid,"组队状态下只有队长可发起切磋")
        return false
    end

    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        oNotifyMgr:Notify(iPid, "玩家不在线")
        return
    end
    local oTargetTeam = oTarget:HasTeam()
    if oTargetTeam and not oTargetTeam:IsShortLeave(iTarget) then
        iTarget = oTargetTeam:Leader()
        oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        if not oTarget then
            oNotifyMgr:Notify(iPid, "队长不在线")
            return
        end
    end
    if oTarget.m_oActiveCtrl:GetInfo("pk_invite_status",0) == 1 then
        oNotifyMgr:Notify(iPid, "对方正忙，请稍后再试")
        return
    end

    local iOpenGrade = res["daobiao"]["global_control"]["pk"]["open_grade"]
    if oPlayer:GetGrade() < iOpenGrade then
        oNotifyMgr:Notify(iPid,"等级不足20级，无法进行擂台切磋")
        return
    elseif  oTarget:GetGrade() < iOpenGrade then
        oNotifyMgr:Notify(iPid,"对方等级不足20级，无法进行擂台切磋")
        return
    end



    local iTimeLimit = self:InvitePKTimeLimit(oPlayer,oTarget)
    if iTimeLimit > 0 then
        oNotifyMgr:Notify(iPid, string.format("请%d秒后再试",iTimeLimit))
        return
    else
        oTarget.m_oActiveCtrl:SetInfo("pk_invite_status",0)
    end

    local iScene = oPlayer.m_oActiveCtrl:GetNowScene():GetSceneId()
    local mPos = oPlayer:GetNowPos()

    if not oSceneMgr:IsInLeiTai(iScene, mPos.x, mPos.y) then
        oNotifyMgr:Notify(iPid,"切磋请到擂台区域进行")
        if oPlayer.m_oActiveCtrl:GetData("pk_faildtime",0) == 0 then
            oPlayer.m_oActiveCtrl:SetData("pk_faildtime",1)
            self:OpenPkTipsWnd(iPid)
        end
        return
    end

    iScene = oTarget.m_oActiveCtrl:GetNowScene():GetSceneId()
    mPos = oTarget:GetNowPos()
    if not oSceneMgr:IsInLeiTai(iScene, mPos.x, mPos.y) then
        oNotifyMgr:Notify(iPid,"对方不在擂台区，邀请失败！")
        return
    end

    local oNowWar = oTarget.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        oNotifyMgr:Notify(iPid, "对方正在战斗")
        return
    end
    if oTeam and oTargetTeam and oTeam:TeamID() == oTargetTeam:TeamID() then
        oNotifyMgr:Notify(iPid, "无法对队友发起切磋")
        return
    end
    local oCbMgr = global.oCbMgr
    local sContent = string.format("%s邀请你进行切磋",oPlayer:GetName())
    local mData = {
        sContent = sContent,
        sConfirm = "接受",
        sCancle = "拒绝",
        default = 0,
        time = 30,
    }
    local mData = oCbMgr:PackConfirmData(nil, mData)
    local oPubMgr = global.oPubMgr
    local func = function (oT,mData)
        local oWorldMgr = global.oWorldMgr
        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
        local iAnswer = mData["answer"]
        if iAnswer == 1 then
            if oPubMgr:CheckInviteChange(oP,oT) then
                oPubMgr:PK(oP,iTarget)
            end
        else
            oNotifyMgr:Notify(iPid,string.format("%s 拒绝了和你切磋",oT:GetName()))
        end
        oT.m_oActiveCtrl:SetInfo("pk_invite_status",0)
        oP.m_oActiveCtrl:SetInfo("pk_invite_status",0)
    end
    oCbMgr:SetCallBack(iTarget,"GS2CConfirmUI",mData,nil,func)
    self:AddPkInvite(oPlayer,oTarget)
    oTarget.m_oActiveCtrl:SetInfo("pk_invite_status",1)
end

function CPublicMgr:OpenPkTipsWnd(iPid)
    local func = function()
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send("GS2COpenPkTipsWnd",{})
        end
    end
    self:DelTimeCb("openpktipswnd")
    self:AddTimeCb("openpktipswnd",1*1000,func)
end

function CPublicMgr:CheckInviteChange(oPlayer,oTarget)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oSceneMgr = global.oSceneMgr
    local oTeam = oPlayer:HasTeam()
    if oTeam and oTeam:Leader() ~= oPlayer.m_iPid and not oTeam:IsShortLeave(oPlayer.m_iPid)  then
        oNotifyMgr:Notify(oTarget.m_iPid,"对方组队状态已改变")
        return false
    end
    local oTargetTeam = oTarget:HasTeam()
    if oTargetTeam and not oTargetTeam:IsShortLeave(oTarget.m_iPid) and oTargetTeam:Leader() ~= oTarget.m_iPid then
        oNotifyMgr:Notify(oTarget.m_iPid,"组队状态下只有队长可发起切磋")
        return false
    end
    if oTeam and oTargetTeam and oTeam:TeamID() == oTargetTeam:TeamID() then
        oNotifyMgr:Notify(iPid, "无法对队友发起切磋")
        return
    end
    local iScene = oPlayer.m_oActiveCtrl:GetNowScene():GetSceneId()
    local mPos = oPlayer:GetNowPos()
    if not oSceneMgr:IsInLeiTai(iScene, mPos.x, mPos.y) then
        oNotifyMgr:Notify(oTarget.m_iPid,"对方已离开擂台")
        return false
    end
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        oNotifyMgr:Notify(oTarget.m_iPid, "对方正在战斗")
        return false
    end
    return true
end

function CPublicMgr:LogCommon(iPid,sReason,mArgs)
    local cjson = require "cjson"
    local sContent = ConvertTblToStr(mArgs)
    local mLog = {
        id = iPid,
        reason = sReason,
        args = sContent
    }
    record.user("common", "common", mLog)
end

function CPublicMgr:GMRequire(oPlayer,iTarget,sInfo)
    if is_production_env() and not oPlayer:IsGM() then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        oNotifyMgr:Notify(oPlayer:GetPid(),"目标玩家不在线")
        return
    end
    oTarget:Send("GS2CGMRequireInfo",{
        gm_id = oPlayer:GetPid(),
        info = sInfo
    })
end

function CPublicMgr:AnswerGM(oPlayer,iGMPid,sInfo)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oGM = oWorldMgr:GetOnlinePlayerByPid(iGMPid)
    if not oGM then
        oNotifyMgr:Notify(oPlayer:GetPid(),"目标玩家不在线")
        return
    end
    if is_production_env() and not oGM:IsGM() then
        return
    end
    oGM:Send("GS2CAnswerGMInfo",{
        target_id = oPlayer:GetPid(),
        info = sInfo
    })
end
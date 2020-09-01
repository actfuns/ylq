--import module
local skynet = require "skynet"
local global  = require "global"
local record = require "public.record"
local interactive = require "base.interactive"

local netteam = import(service_path("netcmd.team"))
local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local offlinedefines = import(service_path("offline.defines"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

MARRY_COST = 100
DIVORCE_COST = 1000

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "marry"
CHuodong.m_sTempName = "情侣系统"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:Init()
end

function CHuodong:NewHour(iWeekDay, iHour)
end

function CHuodong:OnLogin(oPlayer)
    local mNet = oPlayer.m_oThisTemp:Query("MarryNet")
    if mNet then
        oPlayer:Send("GS2CExpressPop",mNet)
    end
    local oFriend = oPlayer:GetFriend()
    local iMarryID = oFriend:GetMarryID()
    if iMarryID ~= 0 then
        local oWorldMgr = global.oWorldMgr
        local oMate = oWorldMgr:GetOnlinePlayerByPid(iMarryID)
        if oMate then
            local sMsg = self:GetTextData(1017)
            sMsg = string.gsub(sMsg,"$mate",oPlayer:GetName())
            global.oNotifyMgr:SendSelf(oMate,sMsg, 0, 1)
        end
    end
end

function CHuodong:HasMarry(oPlayer)
    local oFriend = oPlayer:GetFriend()
    return oFriend:HasMarry()
end

function CHuodong:LookShiZhe(oPlayer,oNpc)
    local sText = self:GetTextData(1001)
    sText = sText .. "\n" .. self:GetTextData(1002)
    sText = sText .. "\n" .. self:GetTextData(1003)

    local menu = {1}
    sText = sText .. "&T我要告白"

    if self:HasMarry(oPlayer) then
        sText = sText .. "&T我要分手"
        table.insert(menu,2)
        sText = sText .. "&T修改情侣称谓"
        table.insert(menu,3)
    end

    local func = function (oP,mData)
        local iAnswer = mData["answer"]
        iAnswer = menu[iAnswer]
        if iAnswer == 1 then
            self:PrepareExpressLove(oP)
        elseif iAnswer == 2 then
            self:PrepareDivorce(oP)
        elseif iAnswer == 3 then
            self:PopLovesTitleUI(oP)
        end
    end
    oNpc:SayRespond(oPlayer:GetPid(),sText,nil,func)
end

function CHuodong:PrepareExpressLove(oPlayer)
    local sMsg = ""
    local mMem = oPlayer:GetTeamMember() or {oPlayer:GetPid()}
    local oWorldMgr = global.oWorldMgr
    for _,iMid in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(iMid)
        if oMem and self:HasMarry(oMem) then
            sMsg = sMsg .. oMem:GetName()
            break
        end
    end
    oPlayer:Send("GS2CExpressEnterUI",{stip=sMsg})
end

function CHuodong:ValidExpress(oPlayer)
    if not oPlayer:IsTeamLeader() then
        oPlayer:NotifyMessage(self:GetTextData(1008))
        return false
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam or oTeam:MemberSize() ~= 2 then
        oPlayer:NotifyMessage(self:GetTextData(1004))
        return false
    end
    if oTeam:HasShortLeave() then
        oPlayer:NotifyMessage(self:GetTextData(1005))
        return false
    end
    local oWorldMgr = global.oWorldMgr
    local mMem = oPlayer:GetTeamMember() or {oPlayer:GetPid()}
    for _,iMid in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(iMid)
        if oMem and self:HasMarry(oMem) then
            local sText = oMem:GetName() .. self:GetTextData(1007)
            oPlayer:NotifyMessage(sText)
            return false
        end
    end
    if not oPlayer:ValidGoldCoin(100,{tip=self:GetTextData(1006)}) then
        return false
    end
    return true
end

function CHuodong:C2GSSendExpress(oPlayer,sContent)
    if not self:ValidExpress(oPlayer) then
        oPlayer:Send("GS2CExpressWaitUI",{result=false})
        return
    end
    local iPid = oPlayer:GetPid()
    local iTarget
    local mMem = oPlayer:GetTeamMember()
    for _,iMid in pairs(mMem) do
        if iMid ~= iPid then
            iTarget = iMid
            break
        end
    end
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oTarget then
        local iEndTime = get_time()+60
        oPlayer:Send("GS2CExpressWaitUI",{result=true,endtime=iEndTime})
        local mNet = {name=oPlayer:GetName(),content=sContent,endtime=iEndTime}
        oTarget:Send("GS2CExpressPop",mNet)
        oPlayer.m_oThisTemp:Set("marryid",iTarget,60)
        oTarget.m_oThisTemp:Set("marryid",iPid,60)
        oTarget.m_oThisTemp:Set("MarryNet",mNet)
        self:AddTimeCb("ExpressOverTime", 60 * 1000, function ()
            self:ExpressOverTime(iPid,iTarget)
        end)
    else
        oPlayer:NotifyMessage("对方不在线")
        oPlayer:Send("GS2CExpressWaitUI",{result=false})
    end
end

function CHuodong:ExpressOverTime(iPid,iTarget)
    self:DelTimeCb("ExpressOverTime")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oPlayer then
        oPlayer.m_oThisTemp:Delete("marryid")
        oPlayer:Send("GS2CExpressOver",{})
        oPlayer:NotifyMessage(self:GetTextData(1010))
    end
    if oTarget then
        oTarget.m_oThisTemp:Delete("marryid")
        oTarget:Send("GS2CExpressOver",{})
        oTarget.m_oThisTemp:Delete("MarryNet")
    end
end

function CHuodong:C2GSExpressResponse(oPlayer,iResult)
    self:DelTimeCb("ExpressOverTime")
    local iTarget = oPlayer.m_oThisTemp:Query("marryid",0)
    if iTarget == 0 then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        oPlayer:NotifyMessage("对方不在线")
        return
    end
    oPlayer.m_oThisTemp:Delete("marryid")
    oTarget.m_oThisTemp:Delete("marryid")
    if iResult ~= 1 then
        oTarget:Send("GS2CExpressResult",{result=false})
        local mText = {1011,1012}
        local iText = mText[math.random(#mText)]
        oTarget:NotifyMessage(self:GetTextData(iText))
        return
    end
    if not oTarget:ValidGoldCoin(100,{tip=self:GetTextData(1006)}) then
        oPlayer:NotifyMessage(self:GetTextData(1006))
        return false
    end
    oTarget:ResumeGoldCoin(100,"表白")
    oTarget:Send("GS2CExpressResult",{result=true})
    oPlayer:Send("GS2CExpressResult",{result=true})
    self:ExpressSuccess(oTarget,oPlayer)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local mNet = {
        hugid = iTarget,
        hugedid = oPlayer:GetPid(),
        endtime = get_time() + 3,
    }
    oScene:BroadCast("GS2CExpressAction",mNet)
    self:PopLovesTitleUI(oPlayer)
    self:PopLovesTitleUI(oTarget)
end

function CHuodong:ExpressSuccess(oPlayer,oTarget)
    local iPid = oPlayer:GetPid()
    local iTarget = oTarget:GetPid()
    self:SetMarryID(oPlayer,iTarget)
    self:SetMarryID(oTarget,iPid)

    local oTitleMgr = global.oTitleMgr
    local iTid = 1082
    oTitleMgr:AddTitle(iTarget, iTid, oPlayer:GetName())
    oTitleMgr:AddTitle(iPid, iTid, oTarget:GetName())

    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(1013)
    sMsg = string.gsub(sMsg,"$role1",oPlayer:GetName())
    sMsg = string.gsub(sMsg,"$role2",oTarget:GetName())
    sMsg = sMsg .. "{link26,5004,前往表白}"
    oNotifyMgr:SendPrioritySysChat("marry_char",sMsg,1)
end

function CHuodong:SetMarryID(oPlayer,iTarget)
    local oFriend = oPlayer:GetFriend()
    oFriend:SetMarryID(iTarget)
    oFriend:SetRelation(iTarget,offlinedefines.RELATION_LOVES)
end

function CHuodong:ClearMarryID(iPid)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadFriend(iPid, function (oFriend)
        local iMarryID = oFriend:GetMarryID()
        oFriend:SetMarryID(0)
        if iMarryID ~= 0 then
            oFriend:ResetRelation(iMarryID,offlinedefines.RELATION_LOVES)
        end
    end)
end

function CHuodong:PrepareDivorce(oPlayer)
    local iPid = oPlayer:GetPid()
    local oTitle = oPlayer:GetTitle(1082)
    if not oTitle then return end
    local sContent = self:GetTextData(1009)
    sContent = string.gsub(sContent,"$username",oTitle:GetMateName())
    local mNet = {
        sContent = sContent,
        sConfirm = "确定",
        sCancle = "取消",
        default = 0,
        time = 10,
        uitype = 5,
    }
    local oCbMgr = global.oCbMgr
    mNet = oCbMgr:PackConfirmData(nil, mNet)
    local func = function(oPlayer,mData)
        if mData.answer and mData.answer == 1 then
            self:EnSureDivorce(oPlayer)
        end
    end
    oCbMgr:SetCallBack(iPid,"GS2CConfirmUI",mNet,nil,func)
end

function CHuodong:EnSureDivorce(oPlayer)
    local iPid = oPlayer:GetPid()
    local oFriend = oPlayer:GetFriend()
    local iMarryID = oFriend:GetMarryID()
    local oTitle = oPlayer:GetTitle(1082)
    if not oTitle then
        return
    end
    local sMateName = oTitle:GetMateName()
    if not oPlayer:ValidGoldCoin(1000,{tip=self:GetTextData(1014)}) then
        return false
    end
    oPlayer:ResumeGoldCoin(1000,"分手")
    self:ClearMarryID(iPid)
    self:ClearMarryID(iMarryID)

    oPlayer:NotifyMessage(self:GetTextData(1015))

    local oTitleMgr = global.oTitleMgr
    oTitleMgr:RemoveTitles(iPid,{1082})
    oTitleMgr:RemoveTitles(iMarryID,{1082})

    local oMailMgr = global.oMailMgr
    local mMail, sMail = oMailMgr:GetMailInfo(77)
    mMail.context = string.gsub(mMail.context,"$role1",oPlayer:GetName())
    mMail.context = string.gsub(mMail.context,"$role2",sMateName)
    oMailMgr:SendMail(0, sMail, iPid, mMail)
    oMailMgr:SendMail(0, sMail, iMarryID, mMail)
end

function CHuodong:PopLovesTitleUI(oPlayer)
    local oTitle = oPlayer:GetTitle(1082)
    if not oTitle then
        return
    end
    local sPostfix = oTitle:GetPostfix()
    local iVal = 100
    if not sPostfix then
        iVal = 0
    end
    sPostfix = sPostfix or "恋人"
    oPlayer:Send("GS2CLoversTitleUI",{
        postfix = sPostfix,
        cost = iVal,
        name = oTitle:GetMateName(),
    })
end

function CHuodong:C2GSChangeLoversTitle(oPlayer,sPostfix)
    local iPid = oPlayer:GetPid()
    local oTitle = oPlayer:GetTitle(1082)
    if not oTitle then
        return
    end
    local sOldPostfix = oTitle:GetPostfix() or "恋人"
    if sPostfix == sOldPostfix then
        oPlayer:NotifyMessage("没有任何修改")
        return
    end
    local iVal = 100
    if not oTitle:GetPostfix() then
        iVal = 0
    end
    if iVal > 0 then
        if not oPlayer:ValidGoldCoin(iVal,{tip=self:GetTextData(1016)}) then
            return false
        end
        oPlayer:ResumeGoldCoin(iVal,"修改情侣称谓")
    end
    oTitle:SetPostfix(sPostfix)
end
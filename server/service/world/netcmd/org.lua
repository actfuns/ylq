-- import module
local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local extend = require "base.extend"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

function C2GSOrgList(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgList",oPlayer:GetPid(),mData)
end

function C2GSSearchOrg(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSSearchOrg",oPlayer:GetPid(),mData)
end

function C2GSApplyJoinOrg(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSApplyJoinOrg",oPlayer:GetPid(),mData)
end

function C2GSMultiApplyJoinOrg(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSMultiApplyJoinOrg",oPlayer:GetPid(),mData)
end

function C2GSGetOrgInfo(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSGetOrgInfo",oPlayer:GetPid(),mData)
end

function C2GSCreateOrg(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSCreateOrg",oPlayer:GetPid(),mData)
end

function C2GSOrgMainInfo(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgMainInfo",oPlayer:GetPid(),mData)
end

function C2GSOrgMemberList(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgMemberList",oPlayer:GetPid(),mData)
end

function C2GSOrgApplyList(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgApplyList",oPlayer:GetPid(),mData)
end

function C2GSJoinOrgBySpread(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSJoinOrgBySpread",oPlayer:GetPid(),mData)
end

function C2GSOrgDealApply(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgDealApply",oPlayer:GetPid(),mData)
end

function C2GSUpdateAim(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSUpdateAim",oPlayer:GetPid(),mData)
end

function C2GSRejectAllApply(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSRejectAllApply",oPlayer:GetPid(),mData)
end

function C2GSOrgSetPosition(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgSetPosition",oPlayer:GetPid(),mData)
end

function C2GSLeaveOrg(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("terrawars")
    if oHuoDong:IsOnSetGuard(oPlayer:GetPid()) then
        oPlayer:NotifyMessage("正在据点战设置驻守伙伴")
        return
    end
    local oHuoDong = oHDMgr:GetHuodong("orgwar")
    if oHuodong and oHuodong:IsOpen() then
        oPlayer:NotifyMessage("公会战期间不能退出公会")
        return
    end
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("terrawars")
    if oHuoDong and oHuoDong.m_bStart == 1 then
        local oCbMgr = global.oCbMgr
        local sContent = "公会据点战期间退出公会，您的个人积分将会清零，确认退出公会吗？"
        local mNet1 = {
            sContent = sContent,
            uitype = 0,
            sConfirm = "确定",
            sCancle = "取消",
            default = 0,
            time = 30,
        }
        local iPid = oPlayer:GetPid()
        local oWorldMgr = global.oWorldMgr
        mNet1 = oCbMgr:PackConfirmData(nil, mNet1)
        local func = function (oResponse,mData2)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer and mData2.answer ==1 then
                ConfirmLeaveOrg(oPlayer,mData)
            end
        end
        oCbMgr:SetCallBack(oPlayer:GetPid(),"GS2CConfirmUI",mNet1,nil,func)
    else
        ConfirmLeaveOrg(oPlayer,mData)
    end
end

function ConfirmLeaveOrg(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    local oCbMgr = global.oCbMgr
    local sContent = oOrgMgr:GetOrgText(2005)
    local iLeaveTime = oPlayer:GetPreLeaveOrgTime()
    if iLeaveTime == 0 then
        sContent = sContent.."\n（首次退会不会有退会冷却CD）"
    end
    local mNet1 = {
        sContent = sContent,
        uitype = 0,
        sConfirm = "确定",
        sCancle = "取消",
        default = 0,
        time = 30,
    }
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    mNet1 = oCbMgr:PackConfirmData(nil, mNet1)
    local func = function (oResponse,mData2)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer and mData2.answer ==1 then
            oOrgMgr:Forward("C2GSLeaveOrg",iPid,mData)
        end
    end
    oCbMgr:SetCallBack(oPlayer:GetPid(),"GS2CConfirmUI",mNet1,nil,func)
end

function C2GSSpreadOrg(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSSpreadOrg",oPlayer:GetPid(),mData)
end

function C2GSKickMember(oPlayer,mData)
    local iKickPid = mData.pid
    local oKick = global.oWorldMgr:GetOnlinePlayerByPid(iKickPid)
    if oKick then
        local oWar = oKick:GetNowWar()
        if oWar and oWar.m_iWarType == gamedefines.WAR_TYPE.TERRAWARS_TYPE then
            oPlayer:NotifyMessage("目前该玩家正在进行战斗，无法踢出公会。")
            return
        end
    end
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSKickMember",oPlayer:GetPid(),mData)
end

function C2GSInvited2Org(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSInvited2Org",oPlayer:GetPid(),mData)
end

function C2GSDealInvited2Org(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSDealInvited2Org",oPlayer:GetPid(),mData)
end

function C2GSSetApplyLimit(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSSetApplyLimit",oPlayer:GetPid(),mData)
end

function C2GSUpdateFlagID(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSUpdateFlagID",oPlayer:GetPid(),mData)
end

function C2GSGetAim(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSGetAim",oPlayer:GetPid(),mData)
end

function C2GSBanChat(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSBanChat",oPlayer:GetPid(),mData)
end

function C2GSOrgBuild(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgBuild",oPlayer:GetPid(),mData)
end

function C2GSSpeedOrgBuild(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSSpeedOrgBuild",oPlayer:GetPid(),mData)
end

function C2GSDoneOrgBuild(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSDoneOrgBuild",oPlayer:GetPid(),mData)
end

function C2GSOrgSignReward(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgSignReward",oPlayer:GetPid(),mData)
end

function C2GSOrgWishList(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgWishList",oPlayer:GetPid(),mData)
end

function C2GSOrgWish(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgWish",oPlayer:GetPid(),mData)
end

function C2GSOrgEquipWish(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgEquipWish",oPlayer:GetPid(),mData)
end

function C2GSGiveOrgWish(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSGiveOrgWish",oPlayer:GetPid(),mData)
end

function C2GSGiveOrgEquipWish(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSGiveOrgEquipWish",oPlayer:GetPid(),mData)
end

function C2GSLeaveOrgWishUI(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSLeaveOrgWishUI",oPlayer:GetPid(),mData)
end

function C2GSOpenOrgRedPacket(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOpenOrgRedPacket",oPlayer:GetPid(),mData)
end

function C2GSDrawOrgRedPacket(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSDrawOrgRedPacket",oPlayer:GetPid(),mData)
end

function C2GSOrgRedPacket(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgRedPacket",oPlayer:GetPid(),mData)
end

function C2GSOrgLog(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgLog",oPlayer:GetPid(),mData)
end

function C2GSPromoteOrgLevel(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSPromoteOrgLevel",oPlayer:GetPid(),mData)
end

function C2GSOrgRecruit(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgRecruit",oPlayer:GetPid(),mData)
end

function C2GSClickOrgRecruit(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSClickOrgRecruit",oPlayer:GetPid(),mData)
end

function C2GSOrgOnlineCount(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgOnlineCount",oPlayer:GetPid(),mData)
end

function C2GSOpenOrgFBUI(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("orgfuben")
    if oHuodong then
        oHuodong:OpenMainUI(oPlayer)
    end
end

function C2GSClickOrgFBBoss(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("orgfuben")
    if oHuodong then
        oHuodong:EnterGame(oPlayer,mData.bid)
    end
end

function C2GSRestOrgFuBen(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("orgfuben")
    if oHuodong then
        oHuodong:RestOrgFuBen(oPlayer)
    end
end

function C2GSOrgSendMail(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgSendMail",oPlayer:GetPid(),mData)
end

function C2GSOrgQQAction(oPlayer,mData)
    local iOrgID = oPlayer:GetOrgID()
    if not iOrgID or iOrgID == 0 then
        return
    end
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:Forward("C2GSOrgQQAction",oPlayer:GetPid(),mData)
end

function C2GSOrgRename(oPlayer,mData)
    local iOrgID = oPlayer:GetOrgID()
    if not iOrgID or iOrgID == 0 then
        return
    end
    local oOrgMgr = global.oOrgMgr
    if not oPlayer:IsOrgLeader() then
        oPlayer:NotifyMessage("只有会长可以改名")
        return
    end
    local iPid = oPlayer:GetPid()
    local iShape = 10002
    if oPlayer:GetItemAmount(iShape) < 1 then
        return
    end
    local fCallback = function ()
        oOrgMgr:Forward("C2GSOrgRename",iPid,mData)
    end
    local mArgs = {}
    local sReason = "帮忙改名"
    oPlayer:RemoveItemAmount(iShape,1,sReason,mArgs,fCallback)
end
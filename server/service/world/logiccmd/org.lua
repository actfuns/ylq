--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"

local gamedefines = import(lualib_path("public.gamedefines"))

function AddShowKeep(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:AddShowKeep(mData.pid,  mData.virtualsid, mData.val)
end

function SendMail(mRecord, mData)
    global.oMailMgr:SendMail(mData.iSendeId, mData.sSenderName,
        mData.iReceiverId, mData.mMailInfo, mData.mMoney, mData.mItems, mData.mPartners)
end

function GiveItem(mRecord, mData)
    local oWorldMgr = global.oWorldMgr
    local iPid = mData.pid
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:GiveItem(mData.sidlist,mData.sReason,mData.mArgs)
    end
end

function RewardOrgRedPacket(mRecord,mData)
    local oWorldMgr = global.oWorldMgr
    local iPid = mData.pid
    local id = mData.id
    local iRewardGold = mData.gold
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:RewardCoin(iRewardGold,"公会红包", {cancel_tip=1})
        oPlayer:LogAnalyGame({},"orgredpacket",nil,{[gamedefines.COIN_FLAG.COIN_COIN]=iRewardGold})
    end
end

function PropChange(mRecord,mData)
    local iPid = mData.pid
    local mInfo = mData.info
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oWorldMgr:SetPlayerPropChange(oPlayer:GetPid(), mInfo)
    end
end

function ClientPropChange(mRecord,mData)
    local iPid = mData.pid
    local mInfo = mData.info
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:ClientPropChange(mInfo)
    end
end

function ValidGoldCoin(mRecord,mData)
    local iPid = mData.pid
    local iValue = mData.value
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local suc = false
        if oPlayer:ValidGoldCoin(iValue) then
            suc = true
        end
        interactive.Response(mRecord.source, mRecord.session, {
            suc = suc,
        })
    end
end

function ResumeGoldCoin(mRecord,mData)
    local iPid = mData.pid
    local iGoldCoin = mData.value
    local sReason = mData.reason or "公会"
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local suc = false
        if oPlayer:ValidGoldCoin(iGoldCoin) then
            suc = safe_call(oPlayer.ResumeGoldCoin,oPlayer,iGoldCoin,sReason)
        end
        interactive.Response(mRecord.source, mRecord.session, {
            suc = suc,
        })
    end
end

function ResumeCoin(mRecord,mData)
    local iPid = mData.pid
    local iCoin = mData.value
    local sReason = mData.reason or "公会"
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local suc = false
        if oPlayer:ValidCoin(iCoin) then
            suc = safe_call(oPlayer.ResumeCoin,oPlayer,iCoin,sReason)
        end
        interactive.Response(mRecord.source, mRecord.session, {
            suc = suc,
        })
    end
end

function SetLeaveOrgInfo(mRecord,mData)
    local iOrgID = mData.orgid
    local iLeaveTime = mData.leaveorgtime
    local iPid = mData.pid
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iPid,function (oProfile)
        oProfile:SetLeaveOrgInfo(iLeaveTime,iOrgID)
    end)
end

function SendMsg2Org(mRecord,mData)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendOrgChat(mData.msg, mData.orgid, mData.roleinfo)

    local iPid = mData.pid or 0
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        global.oChatMgr:LogAnaly(oPlayer,gamedefines.CHANNEL_TYPE.ORG_TYPE,sMsg)
    end
end

function CalAddOrgTime(mRecord,mData)
    local iPid = mData.pid
    local iTimes = mData.time
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30007,iTimes)
    else
        oWorldMgr:LoadProfile(iPid,function (oProfile)
            oProfile:SetData("addorgtime",oProfile:GetData("addorgtime",0)+iTimes)
            end)
    end
end

function AddSchedule(mRecord,mData)
    local iPid = mData.pid
    local sSchedule = mData.schedule
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:AddSchedule(sSchedule)
    end
end

function SetToday(mRecord,mData)
    local iPid = mData.pid
    local sKey = mData.key
    local Value = mData.value
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oToday:Set(sKey, Value)
    end
end

function RewardOrgOffer(mRecord,mData)
    local iPid = mData.pid
    local iOffer = mData.offer
    local sReason = mData.reason
    local mArgs = mData.args
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:RewardOrgOffer(iOffer,sReason,mArgs)
    end
end

function PushBookCondition(mRecord,mData)
    local iPid = mData.pid
    local sKey = mData.key
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:PushBookCondition(sKey,mData.data)
    end
end

function OrgSignReward(mRecord,mData)
    local iPid = mData.pid
    local mItemList = mData.item_list
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        global.oOrgMgr:OrgSignReward(oPlayer,mItemList)
    end
end

function RemoveItemList(mRecord,mData)
    local iPid = mData.pid
    local sReason = mData.reason or "公会"
    local mItemList = mData.itemlist
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local fCallback = function (_,mData)
            local suc = mData.success
            if not suc then
                oPlayer:NotifyMessage("道具不足，无法完成")
            end
            interactive.Response(mRecord.source, mRecord.session, {
                suc = suc,
            })
        end
        oPlayer.m_oItemCtrl:RemoveItemList(mItemList,sReason,{},fCallback)
    end
end

function ShowKeepItem(mRecord,mData)
    local iPid = mData.pid
    global.oUIMgr:ShowKeepItem(iPid)
end

function SpreadOrg(mRecord,mData)
    local iPid = mData.pid
    local iOrgID = mData.orgid
    local sOrgName = mData.orgname
    global.oOrgMgr:SpreadOrg(iPid,iOrgID,sOrgName)
end

function LogAnalyData(mRecord,mData)
    local iPid = mData.pid
    local mLog = mData.log
    global.oOrgMgr:LogAnalyData(iPid,mLog)
end

function PushOrgPrestigeRank(mRecord,mData)
    local name = mData.name
    local data = mData.data
    local oRankMgr = global.oRankMgr
    oRankMgr:PushDataToRank(name,data)
end

function OnKickMember(mRecord,mData)
    local iPid = mData.pid
    global.oOrgMgr:OnKickMember(iPid)
end

function OnLeaveOrg(mRecord,mData)
    global.oOrgMgr:OnLeaveOrg(mData.orgid,mData.pid,mData.item)
end

function InitOrgShareObj(mRecord,mData)
    local data = mData.data or {}
    local org_share = data.org_share
    local iPid = mData.pid
    local oOrgMgr = global.oOrgMgr
    local oShareObj = oOrgMgr:GetOrgInfoReader(iPid)
    if oShareObj and org_share then
        oShareObj:Init(org_share)
    end
    oOrgMgr:ResetPlayerOrgAttr(iPid,data.org_position)
end

function OnUpdatePosition(mRecord,mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:OnUpdatePosition(mData.pid,mData.position)
end

function OnCreateOrg(mRecord,mData)
    global.oOrgMgr:OnCreateOrg(mData.orginfo)
end

function OnJoinOrg(mRecord,mData)
    global.oOrgMgr:OnJoinOrg(mData.playerinfo)
end

function SyncTerraWarInfo(mRecord,mData)
    local iOrgID = mData.id
    local data = mData.data
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr then
        global.oOrgMgr:UpdateOrgInfo(iOrgID,data)
    end
end

function OrgSendMail(mRecord,mData)
    local sName = mData.name
    local iPid = mData.pid
    local sSubject = mData.subject
    local sContent = mData.content
    local mMem = mData.list

    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end

    local oMailMgr = global.oMailMgr
    local mMail, _ = oMailMgr:GetMailInfo(71)
    mMail.context = sContent
    mMail.subject = sSubject
    for _,iMid in pairs(mMem) do
        oMailMgr:SendMail(iPid, sName, iMid, mMail)
    end
    oPlayer:NotifyMessage("发送成功")
end

function SendAllMemMail(mRecord,mData)
    local iMail = mData.mail
    local mMem = mData.mem or {}

    local oMailMgr = global.oMailMgr
    local mMail, sMail = oMailMgr:GetMailInfo(iMail)

    for _,mid in pairs(mMem) do
        oMailMgr:SendMail(0, sMail, mid, mMail)
    end
end
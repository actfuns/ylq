--import module
local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

local analy = import(lualib_path("public.dataanaly"))
local loadpartner = import(service_path("partner/loadpartner"))
local partnerdefine = import(service_path("partner/partnerdefine"))
local itemdefines = import(service_path("item/itemdefines"))
local loaditem = import(service_path("item/loaditem"))

function C2GSPartnerFight(oPlayer,mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSPartnerFight", iPid, mData)
end

function C2GSPartnerSwitch(oPlayer,mData)
    if #mData.fight_info ~= 2 then
        return
    end
    oPlayer.m_oPartnerCtrl:Forward("C2GSPartnerSwitch", oPlayer:GetPid(), mData)
end

function C2GSOpenDrawCardUI(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local sHDName = "upcard"
    local oHuodong = oHuodongMgr:GetHuodong(sHDName)
    if oHuodong then
        if oHuodong:ValidOpenDrawCardUI(oPlayer) then
            oHuodong:OpenDrawCardUI(oPlayer)
        end
    end
end

function C2GSGetOuQi(oPlayer,mData)
    local oid = mData.oid
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("upcard")
    oHuodong:GetOuQi(oPlayer,oid)
end


function C2GSDrawWuLingCard(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local iDrawCnt = mData["card_cnt"]
    local bDmClose = mData["dm_close"] or false
    local oHuodong = oHuodongMgr:GetHuodong("upcard")
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        if not oHuodong:IsOpenGrade(oPlayer) then
            return
        end
        oHuodong:DrawWuLingCard(oPlayer, iDrawCnt, bDmClose)
    end
end

function C2GSDrawWuHunCard(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("upcard")
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        if not oHuodong:IsOpenGrade(oPlayer) then
            return
        end
        oHuodong:DrawWuHunCard(oPlayer, mData)
    end
end

function C2GSCloseDrawCardUI(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("upcard")
    if oHuodong and oHuodong:ValidCloseDrawCardUI(oPlayer) then
        oHuodong:CloseDrawCardUI(oPlayer)
    end
end

function C2GSUpgradePartnerStar(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSUpgradePartnerStar", iPid, mData)
end

function C2GSSetPartnerLock(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSSetPartnerLock", iPid, {
        partnerid = mData["partnerid"],
        })
end

function C2GSRenamePartner(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSRenamePartner", iPid, mData)
end

function C2GSComposePartner(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSComposePartner", iPid, mData)
end

function C2GSAwakePartner(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSAwakePartner", iPid, mData)
end

function C2GSComposeAwakeItem(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSComposeAwakeItem", iPid, mData)
end

function C2GSPartnerEquipPlanSave(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSPartnerEquipPlanSave", iPid, mData)
end

function C2GSPartnerEquipPlanUse(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSPartnerEquipPlanUse", iPid, mData)
end

function C2GSAddPartnerComment(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oPartnerCmtMgr = global.oPartnerCmtMgr
    local iPartnerType = mData["partner_type"]
    local sMsg = mData["msg"]

    local iPid = oPlayer:GetPid()
    local o = oPartnerCmtMgr:GetObj(iPartnerType)
    if o then
        local bNotify = true
        if o:ValidAdd(iPid, bNotify) then
            o:Add(oPlayer, sMsg)
        end
    else
        local mData = loadpartner.GetPartnerData(iPartnerType)
        if mData then
            local oNew = oPartnerCmtMgr:NewComment(iPartnerType)
            oPartnerCmtMgr:AddComment(oNew)
            oNew:Add(oPlayer, sMsg)
        else
            oNotifyMgr:Notify(iPid, "伙伴不存在")
        end
    end
end

function C2GSPartnerCommentInfo(oPlayer, mData)
    local oPartnerCmtMgr = global.oPartnerCmtMgr
    local iPartnerType = mData["partner_type"]

    local o = oPartnerCmtMgr:GetObj(iPartnerType)
    if not o then
        local mData = loadpartner.GetPartnerData(iPartnerType)
        if mData then
            o = oPartnerCmtMgr:NewComment(iPartnerType)
            oPartnerCmtMgr:AddComment(o)
        else
            oNotifyMgr:Notify(oPlayer:GetPid(), "伙伴不存在")
        end
    end
    if o then
        o:GS2CPartnerCommentInfo(oPlayer)
    end
end

function C2GSUpVotePartnerComment(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oPartnerCmtMgr = global.oPartnerCmtMgr
    local iPartnerType = mData["partner_type"]
    local iID= mData["comment_id"]
    local iType = mData["comment_type"]

    local o = oPartnerCmtMgr:GetObj(iPartnerType)
    if o then
        local bNotify = true
        if o:ValidVote(oPlayer:GetPid(), iType, iID, bNotify) then
            o:UpVote(oPlayer, iType, iID)
        end
    end
end

function C2GSPartnerPictureSwitchPos(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSPartnerPictureSwitchPos", iPid, mData)
end

function C2GSUsePartnerItem(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    oPlayer.m_oPartnerCtrl:Forward("C2GSUsePartnerItem", iPid, mData)
end

function C2GSComposePartnerEquip(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSComposePartnerEquip", oPlayer:GetPid(), mData)
end

function C2GSLockPartnerItem(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSLockPartnerItem", oPlayer:GetPid(), mData)
end

function C2GSSetFollowPartner(oPlayer, mData)
    local iTid = mData.tid
    if iTid and iTid > 0 then
        local oTitle = oPlayer:GetTitle(iTid)
        if oTitle and oTitle:IsPartnerTitle() then
            mData.title = oTitle:GetTitleInfo()
        end
    end
    oPlayer.m_oPartnerCtrl:Forward("C2GSSetFollowPartner", oPlayer:GetPid(), mData)
end

function C2GSQuickWearPartnerEquip(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSQuickWearPartnerEquip", oPlayer:GetPid(), mData)
end

function C2GSUpGradePartner(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSUpGradePartner", oPlayer:GetPid(), mData)
end

function C2GSOpenPartnerUI(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSOpenPartnerUI", oPlayer:GetPid(), mData)
end

function C2GSAddPartnerSkill(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSAddPartnerSkill", oPlayer:GetPid(), mData)
end

function C2GSBuyPartnerBaseEquip(oPlayer,mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSBuyPartnerBaseEquip", oPlayer:GetPid(), mData)
end

function C2GSRecyclePartnerEquipList(oPlayer,mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSRecyclePartnerEquipList", oPlayer:GetPid(), mData)
end

function C2GSStrengthPartnerEquip(oPlayer,mData)
    mData.coin = oPlayer:Coin()
    oPlayer.m_oPartnerCtrl:Forward("C2GSStrengthPartnerEquip", oPlayer:GetPid(), mData)
end

function C2GSUpstarPartnerEquip(oPlayer,mData)
    mData.coin = oPlayer:Coin()
    oPlayer.m_oPartnerCtrl:Forward("C2GSUpstarPartnerEquip", oPlayer:GetPid(), mData)
end

function C2GSInlayPartnerStone(oPlayer,mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSInlayPartnerStone", oPlayer:GetPid(), mData)
end

function C2GSComposePartnerStone(oPlayer,mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSComposePartnerStone", oPlayer:GetPid(), mData)
end

function C2GSUsePartnerSoulType(oPlayer,mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSUsePartnerSoulType", oPlayer:GetPid(), mData)
end

function C2GSUpgradePartnerSoul(oPlayer,mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSUpgradePartnerSoul", oPlayer:GetPid(), mData)
end

function C2GSUsePartnerSoul(oPlayer,mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSUsePartnerSoul", oPlayer:GetPid(), mData)
end


function C2GSSwapPartnerEquip(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSSwapPartnerEquip", oPlayer:GetPid(), mData)
end

function C2GSReceivePartnerChip(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSReceivePartnerChip", oPlayer:GetPid(), mData)
end

function C2GSReDrawPartner(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSReDrawPartner", oPlayer:GetPid(), mData)
end

function C2GSSwapPartnerEquipByPos(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSSwapPartnerEquipByPos", oPlayer:GetPid(), mData)
end

function C2GSAddParSoulPlan(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSAddParSoulPlan", oPlayer:GetPid(), mData)
end

function C2GSDelParSoulPlan(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSDelParSoulPlan", oPlayer:GetPid(), mData)
end

function C2GSModifyParSoulPlan(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSModifyParSoulPlan", oPlayer:GetPid(), mData)
end

function C2GSParSoulPlanUse(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSParSoulPlanUse", oPlayer:GetPid(), mData)
end

function C2GSExchangePartnerChip(oPlayer, mData)
    oPlayer.m_oPartnerCtrl:Forward("C2GSExchangePartnerChip", oPlayer:GetPid(), mData)
end


function LogAnalyCard(oPlayer,mCostItem,iGoldCoin,mPartner,mItem,dm)
    local mLog = oPlayer:GetPubAnalyData()
    mLog["consume_detail"] = analy.datajoin(mCostItem)
    mLog["consume_crystal"] = iGoldCoin
    mLog["gain_partner"] = analy.datajoin(mPartner)
    mLog["gain_item"] = analy.datajoin(mItem)
    mLog["is_dm_close"] = dm
    analy.log_data("recruit",mLog)
end
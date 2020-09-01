local global = require "global"
local extend = require "base/extend"

local gamedefines = import(lualib_path("public.gamedefines"))

local oMailobj = import(service_path("mail.mailobj"))

-----------------------------------------------C2GS--------------------------------------------
function C2GSOpenMail(oPlayer, mData)
    local mailid = mData["mailid"]
    local oMailBox = oPlayer:GetMailBox()
    local oMail = oMailBox:GetMail(mailid)
    if oMail then
        oMail:Open()
        local mNet = oMail:PackInfo()
        oPlayer:Send("GS2CMailInfo", mNet)
        if oMail:Opened() then
            oPlayer:Send("GS2CMailOpened", {mailids={mailid}})
        end
    end
end

function C2GSAcceptAttach(oPlayer, mData)
    local mailid = mData["mailid"]
    local oMailBox = oPlayer:GetMailBox()
    local oMail = oMailBox:GetMail(mailid)
    if oMail then
        local oNotifyMgr = global.oNotifyMgr
        if oMail:HasReceived() then
            oNotifyMgr:Notify(oPlayer:GetPid(), "邮件已领取")
            return
        end
        if not oMail:Validate() then
            oMailBox:DelMail(mailid,"delay Delete")
            oNotifyMgr:Notify(oPlayer:GetPid(), "邮件已过期")
            return
        end
        if not oPlayer.m_oItemCtrl:ValidGive(oMail:GetAttachItemList(),{cancel_tip = 1}) then
            oNotifyMgr:Notify(oPlayer:GetPid(),"邮件中部分物品的物品格已满，领取失败")
            return
        end
        if not oPlayer.m_oPartnerCtrl:ValidGive(oMail:GetAttachPartneList(), {cancel_tip  = 1}) then
            oNotifyMgr:Notify(oPlayer:GetPid(),"邮件中部分物品的物品格已满，领取失败")
            return
        end
        if not CheckCoinItem(oPlayer,oMail) then
            oNotifyMgr:Notify(oPlayer:GetPid(), "邮件中部分货币已满，领取失败")
            return
        end
        if oMail:RecieveAttach(oPlayer) then
            oPlayer:Send("GS2CDelAttach",{["mailid"]= mailid})
            if oMail:Opened() then
                oPlayer:Send("GS2CMailOpened", {mailids={mailid}})
            end
            global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
        end
    end
end

function CheckCoinItem(oPlayer,oMail)
    local oNotifyMgr = global.oNotifyMgr
    local mAttachlist = oMail:GetAttachListByType(oMailobj.ATTACH_MONEY)
    for _,oMoney in ipairs(mAttachlist) do
        local iCoin = 0
        if oMoney.sid == gamedefines.COIN_FLAG.COIN_GOLD then
            iCoin = oPlayer:GoldCoin()
            local iVal = oMoney.value
            if not oPlayer:IsOverflowCoin(gamedefines.COIN_FLAG.COIN_GOLD,iCoin+iVal) then
                return false
            end
        elseif oMoney.sid == gamedefines.COIN_FLAG.COIN_COIN then
            iCoin = oPlayer:Coin()
            local iVal = oMoney.value
            if not oPlayer:IsOverflowCoin(gamedefines.COIN_FLAG.COIN_GOLD,iCoin+iVal) then
                return false
            end
        end
    end
    return true
end

function C2GSAcceptAllAttach(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oMailBox = oPlayer:GetMailBox()
    local iNoExtractCnt = 0
    local lRecieved = {}
    for _, mailid in ipairs(oMailBox:GetAllShowMailIDs()) do
        local oMail = oMailBox:GetMail(mailid)
        if oMail and oMail:Validate() then
            if oMail:AutoExtract() and oPlayer.m_oItemCtrl:ValidGive(oMail:GetAttachItemList(),{cancel_tip = 1}) and CheckCoinItem(oPlayer,oMail) and oPlayer.m_oPartnerCtrl:ValidGive(oMail:GetAttachPartneList()) then
                if not oMail:HasReceived() then
                    if oMail:RecieveAttach(oPlayer) then
                        oPlayer:Send("GS2CDelAttach",{["mailid"]=mailid})
                        table.insert(lRecieved, mailid)
                    end
                end
            else
                iNoExtractCnt = iNoExtractCnt + 1
            end
        end
    end
    if iNoExtractCnt > 0 then
        oNotifyMgr:Notify(oPlayer:GetPid(), "部分邮件中的物品或者货币已满，领取失败")
    end
    if #(lRecieved) == 0 then
        if iNoExtractCnt == 0 then
            oNotifyMgr:Notify(oPlayer:GetPid(), "没有附件可以一键领取了")
        end
    else
        oPlayer:Send("GS2CMailOpened", {mailids=lRecieved})
        global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
    end
end

function C2GSDeleteMail(oPlayer, mData)
    local mailids = mData["mailids"]
    local oMailBox = oPlayer:GetMailBox()
    for _, mid in ipairs(mailids) do
        local oMail = oMailBox:GetMail(mid)
        if oMail and ((oMail:HasAttach() and oMail:HasReceived()) or (not oMail:HasAttach()  and oMail:Opened())) then
            oMailBox:DelMail(mid,"Player Delete")
        end
    end
end

function C2GSDeleteAllMail(oPlayer, mData)
    local oMailBox = oPlayer:GetMailBox()
    local iDelCnt = 0
    local lMailid = {}
    for _, mailid in ipairs(oMailBox:GetAllShowMailIDs()) do
        local oMail = oMailBox:GetMail(mailid)
        if oMail and ((oMail:HasAttach() and oMail:HasReceived()) or (not oMail:HasAttach()  and oMail:Opened())) then
            oMailBox:DelMail(mailid,"Player Delete")
            table.insert(lMailid, mailid)
            iDelCnt = iDelCnt + 1
        end
    end
    if iDelCnt > 0 then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(oPlayer:GetPid(), string.format("已删除%d封邮件", iDelCnt))
    end
    oMailBox:GS2CDelMail(lMailid)
end
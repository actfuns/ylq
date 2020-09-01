local global = require "global"
local extend = require "base.extend"
local res = require "base.res"
local record = require "public.record"

local loadpartner = import(service_path("partner/loadpartner"))
local datactrl = import(lualib_path("public.datactrl"))
local mailobj = import(service_path("mail.mailobj"))
function NewMailMgr(...)
    return CMailMgr:New(...)
end

CMailMgr = {}
CMailMgr.__index = CMailMgr
inherit(CMailMgr,logic_base_cls())

function CMailMgr:New()
    local o = super(CMailMgr).New(self)
    return o
end

function CMailMgr:OnLogin(oPlayer,bReEnter)
    local oSysMailCache = global.oWorldMgr.m_oSysMailCache
    oSysMailCache:LoginCheckSysMail(oPlayer)

    oPlayer:GetMailBox():GS2CLoginMail()
end

function CMailMgr:OnLogout(oPlayer)
end

function CMailMgr:OnDisconnected(oPlayer)
end

function CMailMgr:GetMailInfo(iIdx)
    local mInfo = res["daobiao"]["mail"][iIdx]
    local mData = {
        title = mInfo.desc,
        subject = mInfo.subject,
        context = mInfo.content,
        keeptime = mInfo.keepday * 3600 * 24,
        readtodel = mInfo.readtodel,
        autoextract = mInfo.autoextract,
    }
    return mData, mInfo.name
end

function CMailMgr:NewHour(iDay,iHour)
    local oWorldMgr = global.oWorldMgr
    local oSysMailCache = oWorldMgr.m_oSysMailCache
    oSysMailCache:CheckReadyChange()
end

function CMailMgr:SendReadySysMail(mData)
    local oWorldMgr = global.oWorldMgr
    local oSysMailCache = oWorldMgr.m_oSysMailCache
    oSysMailCache:AddReadyMail(mData)
    oSysMailCache:CheckReadyChange()
end

function CMailMgr:SendAllSysMail(mData)
    local oWorldMgr = global.oWorldMgr
    local oSysMailCache = oWorldMgr.m_oSysMailCache
    oSysMailCache:AddSysMail(mData)
    for pid, oPlayer in pairs(oWorldMgr:GetOnlinePlayerList()) do
        oSysMailCache:LoginCheckSysMail(oPlayer)
    end
end

--sendmail {mailid=导表id, sys=是否系统, 货币={{货币id,货币数量}}},item=物品信息, partner=伙伴信息,mailcnt邮件数量}
function CMailMgr:SendMail(iSendeId, sSenderName, iReceiverId, mMailInfo, mMoney, mItems,mPartners)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadMailBox(iReceiverId, function (oMailBox)
        if oMailBox then
            self:SendMail2(oMailBox, iSendeId, sSenderName, iReceiverId, mMailInfo, mMoney, mItems,mPartners)
        end
    end)
end

function CMailMgr:SendMail2(oMailBox, pid, name, target, mData, mMoney, items,partners)
    mData.expert = mData.expert or 15 * 24 * 3600
    local oMail = mailobj.NewMail(oMailBox:DispitchMailID())
    local iEndTime = oMail:Create({pid, name}, target, mData)
    oMailBox:AddCheck(oMail,iEndTime)
    oMailBox:SortCheck()
    if mMoney and #mMoney > 0 then
        for _,info in pairs(mMoney) do
            if info.value and info.value > 0 then
                local oAttach = mailobj.NewAttach(mailobj.ATTACH_MONEY, info)
                oMail:AddAttach(oAttach)
            end
        end
    end
    if items then
        for _, oItem in ipairs(items) do
            if oItem.m_SID == 1010 then
                local iPartnerId = oItem:GetData("partner")
                local iStar = oItem:GetData("star",1)
                local oPartner = loadpartner.CreatePartner(iPartnerId,{star = iStar})
                local oAttach = mailobj.NewAttach(mailobj.ATTACH_PARTNER, oPartner:Save())
                oMail:AddAttach(oAttach)
            else
                local oAttach = mailobj.NewAttach(mailobj.ATTACH_ITEM, oItem:Save())
                oMail:AddAttach(oAttach)
            end

        end
    end

    if partners then
        for _,oPartner in pairs(partners) do
            local oAttach = mailobj.NewAttach(mailobj.ATTACH_PARTNER, oPartner:Save())
            oMail:AddAttach(oAttach)
        end
    end
    record.user("mail","add_mail",oMail:PackLogInfo())
    oMailBox:AddMail(oMail)
end

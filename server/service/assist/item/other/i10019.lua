local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"
local fstring = require "public.colorstring"

local gamedefines = import(lualib_path("public.gamedefines"))

local itembase = import(service_path("item/itembase"))
local loaditem = import(service_path("item/loaditem"))
local itemdefines = import(service_path("item/itemdefines"))
local loadpartner = import(service_path("partner/loadpartner"))
local partnerdefine = import(service_path("partner/partnerdefine"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:TrueUse(oPlayer, iTarget, iAmount,mArgs)
    local res = require "base.res"
    local iSid = self:SID()
    local mData = res["daobiao"]["partner"]["item_card"][iSid]
    if not mData then
        return
    end

    local  mDraw = oPlayer:HasDrawPartner()
    if mDraw and next(mDraw) then
        global.oAssistMgr:BroadCastNotify(oPlayer:GetPid(), nil, "上次招募结果奖励未领取，默认为该碎片奖励")
        self:SendDrawPartner(oPlayer)
    else
        self:DrawPartner(oPlayer, mArgs)
    end
end

function CItem:DrawPartner(oPlayer, mArgs)
    mArgs = mArgs or {}
    local res = require "base.res"
    local iSid = self:SID()
    local mData = res["daobiao"]["partner"]["item_card"][iSid]
    local mChoose = extend.Array.weight_choose(mData, "weight")
    local lPartype = {}
    for _, iType in ipairs(mChoose.partner_list) do
        if iType ~= mArgs.partype then
            table.insert(lPartype, iType)
        end
    end
    local iPartype = lPartype[math.random(#lPartype)]
    local mPartner = loadpartner.GetPartnerData(iPartype)
    if not mPartner then
        return
    end
    local sReason = mArgs.reason or "使用一发入魂道具"
    local mArgs = {}
    mArgs.cancel_tip = 1
    mArgs.cancel_show = 1
    local mNet = {}
    mNet.par_type = iPartype
    if oPlayer.m_oPartnerCtrl:GetPartnerByType(iPartype) then
        self:AddDrawPartner(oPlayer, iPartype, sReason, mArgs)
        mNet.desc = string.format("你已获得%s，将自动转换成%s个%s碎片", mPartner.name, mPartner.decompose, mPartner.name)
        mNet.redraw_cost = self:RedrawCost()
    else
        self:DoGivePartner(oPlayer, iPartype, sReason, mArgs)
        mNet.desc = "恭喜你获得伙伴：" .. mPartner.name
        mNet.redraw_cost = 0
    end
    self:SendDrawPartner(oPlayer, mNet)
end

function CItem:DoGivePartner(oPlayer, iPartype, sReason, mArgs)
    local oAssistMgr = global.oAssistMgr
    oPlayer.m_oItemCtrl:AddAmount(self, -1, sReason, {cancel_tip = 1})
    local args = {
        {"&role&", oPlayer:GetName()},
        {"&item&", loaditem.ItemColorName(self:SID())},
        {"&partner&", iPartype},
        {"&amount&", 1},
    }
    mArgs.chuanwen = oAssistMgr:GetPartnerTextData(1001, args)
    oPlayer:GivePartner({{iPartype, 1}}, sReason, mArgs)
end

function CItem:AddDrawPartner(oPlayer, iPartype, sReason, mArgs)
    local mDraw = {}
    mDraw.partype = iPartype
    oPlayer:AddDrawPartner({partype = iPartype})
end

function CItem:SendDrawPartner(oPlayer, mNet)
    if not mNet then
        local mDraw = oPlayer:HasDrawPartner()
        if mDraw then
            mNet = {}
            local iPartype = mDraw.partype
            local mPartner = loadpartner.GetPartnerData(iPartype)
            if mPartner then
                mNet.par_type = iPartype
                mNet.desc = string.format("你已获得%s，将自动转换成%s个%s碎片", mPartner.name, mPartner.decompose, mPartner.name)
                mNet.redraw_cost =self:RedrawCost()
            end
        end
    end

    if mNet then
        oPlayer:Send("GS2CDrawCardUI", mNet)
    end
end

function CItem:RedrawCost()
    local oAssistMgr = global.oAssistMgr
    local val = oAssistMgr:QueryGlobalData("redraw_partner")
    return tonumber(val)
end
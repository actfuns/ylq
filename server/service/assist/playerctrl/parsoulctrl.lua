local global = require "global"
local skynet = require "skynet"

local datactrl = import(lualib_path("public.datactrl"))
local itemdefines = import(service_path("item/itemdefines"))
local gamedefines = import(lualib_path("public.gamedefines"))

local MAX_PLAN = 20

CParSoulCtrl = {}
CParSoulCtrl.__index = CParSoulCtrl
inherit(CParSoulCtrl, datactrl.CDataCtrl)

function CParSoulCtrl:New(iPid)
    local o = super(CParSoulCtrl).New(self, {pid = iPid})
    o.m_mSoulPlan = {}
    return o
end

function CParSoulCtrl:Release()
    self.m_mSoulPlan = nil
    super(CParSoulCtrl).Release(self)
end

function CParSoulCtrl:Load(mData)
    mData = mData or {}
    local plans = mData["soul_plan"] or {}
    for _, m in ipairs(plans) do
        self.m_mSoulPlan[m.planid] = {name = m.name, soul_type = m.soul_type or 1}
    end
end

function CParSoulCtrl:Save()
    local mData = {}
    local plans = {}
    for iPlan, m in pairs(self.m_mSoulPlan) do
        table.insert(plans, {planid = iPlan, name = m.name, soul_type = m.soul_type})
    end
    mData["soul_plan"] = plans
    return mData
end

function CParSoulCtrl:InitSoulPlan(oSoul)
    local mPlan = oSoul:GetPlanList()
    if next(mPlan) then
        for iPlan, iPos in pairs(mPlan) do
            local mPlan =self.m_mSoulPlan[iPlan] or {}
            mPlan.soul_type = oSoul:GetSoulType()
            local mSoul = mPlan.soul or {}
            mSoul[iPos] = oSoul:ID()
            mPlan.soul = mSoul
            self.m_mSoulPlan[iPlan] = mPlan
        end
    end
end

function CParSoulCtrl:OnLogin(oPlayer, bReEnter)
    self:PreCheckParSoulPlan(oPlayer, bReEnter)
    local l = {}
    for iPlan, m in pairs(self.m_mSoulPlan) do
        table.insert(l, self:PackSoulPlan(iPlan))
    end

    oPlayer:Send("GS2CLoginParSoulPlan", {plans = l})
end

function CParSoulCtrl:PreCheckParSoulPlan(oPlayer, bReEnter)
    if not bReEnter then
        local oContainer = oPlayer.m_oItemCtrl:GetContainer(gamedefines.ITEM_CONTAINER.PARTNER_SOUL)
        if oContainer then
            local mItemList = oContainer:ItemList()
            for iItemId, oSoul in pairs(mItemList) do
                self:InitSoulPlan(oSoul)
            end
        end
    end
end

function CParSoulCtrl:DispatchPlanID()
    for i=1, MAX_PLAN do
        if not self.m_mSoulPlan[i] then
            return i
        end
    end
    return nil
end

function CParSoulCtrl:GetPid()
    return self:GetInfo("pid")
end

function CParSoulCtrl:ValidAddSoulPlan(oPlayer, sName, iSoulType, lSoul)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    if table_count(self.m_mSoulPlan) >= MAX_PLAN then
        oAssistMgr:BroadCastNotify(iPid, nil, string.format("最多拥有%s个方案", MAX_PLAN))
        return false
    end
    if #lSoul >  itemdefines.lMAX_SOUL_POS then
        oAssistMgr:BroadCastNotify(iPid, nil, "御灵数目非法")
        return false
    end
    return itemdefines.ValidParSoul(oPlayer, iSoulType, lSoul)
end

function CParSoulCtrl:AddSoulPlan(oPlayer, sName, iSoulType, lSoul)
    local oAssistMgr = global.oAssistMgr
    self:Dirty()
    local iPid = oPlayer:GetPid()
    local iPlan = self:DispatchPlanID()
    local mSoul = {}
    for _, m in ipairs(lSoul) do
        local oSoul = oPlayer:HasItem(m.itemid)
        if oSoul then
            oSoul:AddSoulPlan(iPlan, m.pos)
            mSoul[m.pos] = m.itemid
        end
    end
    local mPlan = {}
    mPlan.name = sName or string.format("御灵方案%s", iPlan)
    mPlan.soul_type = iSoulType
    mPlan.soul = mSoul
    self.m_mSoulPlan[iPlan] = mPlan
    oPlayer:Send("GS2CAddParSoulPlan", {plan = self:PackSoulPlan(iPlan)})
end

function CParSoulCtrl:RemoveSoulPlan(oPlayer, iPlan)
    local oAssistMgr = global.oAssistMgr
    local mPlan = self.m_mSoulPlan[iPlan]
    if not mPlan then
        oAssistMgr:BroadCastNotify(self:GetPid(), nil, "方案不存在")
        return
    end
    self:Dirty()
    local mSoul = mPlan.soul or {}
    for iPos, iSoul in pairs(mSoul) do
        local oSoul = oPlayer:HasItem(iSoul)
        if oSoul then
            oSoul:RemoveSoulPlan(iPlan, iPos)
        end
    end
    self.m_mSoulPlan[iPlan] = nil
    oPlayer:Send("GS2CDelParSoulPlan", {idx = iPlan})
end

function CParSoulCtrl:ValidModifySoulPlan(oPlayer, iPlan, sName, iSoulType, lSoul)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local mPlan = self.m_mSoulPlan[iPlan]
    if not mPlan then
        oAssistMgr:BroadCastNotify(iPid, nil, "方案不存在")
        return false
    end
    if iSoulType ~= 0 then
        if #lSoul >  itemdefines.lMAX_SOUL_POS then
            oAssistMgr:BroadCastNotify(iPid, nil, "御灵数目非法")
            return false
        end
        return itemdefines.ValidParSoul(oPlayer, iSoulType, lSoul)
    end
    return true
end

function CParSoulCtrl:ModifySoulPlan(oPlayer, iPlan, sName, iSoulType, lSoul)
    self:Dirty()
    local oAssistMgr = global.oAssistMgr
    local mPlan = self.m_mSoulPlan[iPlan]
    if iSoulType ~= 0 then
        local mSoul = mPlan.soul or {}
        for iPos, iSoul in pairs(mSoul) do
            local oSoul = oPlayer:HasItem(iSoul)
            if oSoul then
                oSoul:RemoveSoulPlan(iPlan, iPos)
            end
        end
        mSoul = {}
        for _, m in ipairs(lSoul) do
            local oSoul = oPlayer:HasItem(m.itemid)
            if oSoul then
                oSoul:AddSoulPlan(iPlan, m.pos)
                mSoul[m.pos] = m.itemid
            end
        end
        mPlan.soul = mSoul
        mPlan.soul_type = iSoulType
    end
    if sName ~= "" then
        mPlan.name = sName
    end
    oPlayer:Send("GS2CUpdateParSoulPlan",{plan =  self:PackSoulPlan(iPlan)})
    oAssistMgr:BroadCastNotify(self:GetPid(),nil, "方案已保存")
end

function CParSoulCtrl:ValidUseParSoulPlan(oPlayer, iPlan, iParId)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local mPlan = self.m_mSoulPlan[iPlan]
    if not mPlan then
        oAssistMgr:BroadCastNotify(iPid, nil, "方案不存在")
        return false
    end
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if not oPartner then
        oAssistMgr:BroadCastNotify(iPid, "伙伴不存在")
        return false
    end
    return true
end

function CParSoulCtrl:UseParSoulPlan(oPlayer, iPlan, iParId)
    local sContent
    local iPid = self:GetPid()
    local lWield = {}
    local mPlan = self.m_mSoulPlan[iPlan]
    local mSoul = mPlan.soul or {}
    for iPos, iSoul in pairs(mSoul) do
        local oSoul = oPlayer:HasItem(iSoul)
        if oSoul and oSoul:IsWield() then
            table.insert(lWield, oSoul)
        end
    end
    if #lWield > 0 then
        self:SendCallBack(oPlayer, iPlan, iParId, lWield)
    else
        self:_UseParSoulPlan(oPlayer, iPlan, iParId, {answer = 1})
    end
end

function CParSoulCtrl:SendCallBack(oPlayer, iPlan, iParId, lWield)
    local oCbMgr = global.oCbMgr
    local iPid = self:GetPid()
    local sContent
    if #lWield == 1 then
        local oSoul = lWield[1]
        local sSoul = string.format("{link15,%s,%s,%s}",oSoul:ID(),iPid,oSoul:Name())
        local iWield = oSoul:GetWield()
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iWield)
        if oPartner then
            local sPartner = string.format("{link19,%s,%s}",oPartner:ID(),oPartner:GetName())
            sContent = string.format("%s正在被%s使用，是否将御灵穿戴至该伙伴身上？",sSoul, sPartner)
        else
            record.error("partnerobj SendCallBack error, pid:%s, parid:%s, traceno:%s",iPid,iWield,oSoul:TraceNo())
            return
        end
    else
        local lMsgs = {}
        for _, oSoul in pairs(lWield) do
            local sMsg = string.format("{link15,%s,%s,%s}",oSoul:ID(),iPid,oSoul:Name())
            table.insert(lMsgs, sMsg)
        end
        sContent = string.format("方案中的%s与其他伙伴相冲突，是否将御灵穿戴至该伙伴身上？",table.concat(lMsgs, ", " ))
    end
    local mData = {
        sContent = sContent,
        sConfirm = "是",
        sCancle = "否",
    }
    mData = oCbMgr:PackConfirmData(nil, mData)
    local func = function(oPlayer, mData)
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
        if oPartner then
            self:_UseParSoulPlan(oPlayer, iPlan, iParId, mData)
        end
    end
    oCbMgr:SetCallBack(iPid, "GS2CConfirmUI", mData, nil, func)
end

function CParSoulCtrl:_UseParSoulPlan(oPlayer, iPlan, iParId, mData)
    if self:ValidUseParSoulPlan(oPlayer, iPlan, iParId) then
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
        oPartner:ResetSoulType()
        local mPlan = self.m_mSoulPlan[iPlan]
        local iSoulType = mPlan.soul_type
        local lSoul = {}
        for iPos, iSoul in pairs(mPlan.soul or {}) do
            local oSoul = oPlayer:HasItem(iSoul)
            if oSoul and (mData.answer == 1 or not  oSoul:IsWield()) then
                table.insert(lSoul, {pos = iPos, itemid = iSoul})
            end
        end
        oPlayer.m_oPartnerCtrl:UseParSoulType(oPlayer, iParId, iSoulType, lSoul, {tips = "一键更换完毕"})
    end
end

function CParSoulCtrl:PackSoulPlan(iPlan)
    local mNet = {}
    local mPlan = self.m_mSoulPlan[iPlan]
    if mPlan then
        mNet.idx = iPlan
        mNet.name = mPlan.name
        mNet.soul_type = mPlan.soul_type
        mNet.souls = {}
        local mSoul = mPlan.soul or {}
        for iPos, iSoul in pairs(mSoul) do
            table.insert(mNet.souls, {pos = iPos, itemid = iSoul})
        end
    end
    return mNet
end
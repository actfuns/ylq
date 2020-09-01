local global = require "global"
local extend = require "base.extend"
local res = require "base.res"
local interactive = require "base.interactive"
local record = require "public.record"
local fstring = require "public.colorstring"
local router = require "base.router"

local datactrl = import(lualib_path("public.datactrl"))
local loadpartner = import(service_path("partner.loadpartner"))
local partnerdefine = import(service_path("partner.partnerdefine"))
local loaditem = import(service_path("item.loaditem"))
local gamedefines = import(lualib_path("public.gamedefines"))
local partnershare = import(service_path("partner/parsharemgr"))
local itemdefines = import(service_path("item.itemdefines"))

local CONTAINER_TYPE = gamedefines.ITEM_CONTAINER
local PARTNER_STATUS = gamedefines.PARTNER_STATUS

function NewPartnerCtrl(...)
    local o = CPartnerCtrl:New(...)
    return o
end

CPartnerCtrl = {}
CPartnerCtrl.__index = CPartnerCtrl
inherit(CPartnerCtrl, datactrl.CDataCtrl)

function CPartnerCtrl:New(pid)
    local o = super(CPartnerCtrl).New(self, {pid = pid})
    o.m_mList = {}
    o.m_mTop10Power = {}
    o.m_mTop4Grade = {}
    o.m_mAwakeItem = {}
    o.m_mOwnedPartner = {}
    o.m_mOwnedEquip = {}
    o.m_mPicturePos = {}
    o.m_ShowPartner = {}
    o.m_bTop10Dirty = true
    o.m_bTop4Dirty = true
    o.m_EqualArena = {}
    o.m_mTravel = {}
    o.m_iFrdPartner = nil
    o.m_iFollow = 0
    o.m_OnceOwn = {}
    o.m_mHouseAttr = {}
    o.m_mRankPPower = {} --同类伙伴战力最高的一个
    o.m_mParSkillGuide = {} --伙伴指引升级
    o.m_mParEquipSet = {} --符文套装激活
    o.m_mParEquipStar = {} --符文套装星级统计
    o.m_mMergePartner = {} --堆叠伙伴
    o.m_mDrawPartner = nil --一发入魂碎片伙伴
    o.m_oShareMgr = partnershare.NewPartnerShare(pid)
    o.m_iParEquipCount = 0 --穿戴符文数量
    o:SetData("trace_no", 1)
    return o
end

function CPartnerCtrl:Release()
    self:DelTimeCb("_CheckTop10")
    self:DelTimeCb("_CheckTop4")
    self:DelTimeCb("_RefreshShow")
    for iParId, oPartner in pairs(self.m_mList) do
        baseobj_safe_release(oPartner)
    end
    self.m_mList = nil
    self.m_mTop10Power = nil
    self.m_mTop4Grade = nil
    self.m_mPicturePos = nil
    self.m_ShowPartner = nil
    self.m_EqualArena = nil
    self.m_OnceOwn = nil
    self.m_mHouseAttr = nil
    self.m_mRankPPower = nil
    self.m_mParSkillGuide = nil
    self.m_mParEquipSet = nil
    self.m_mParEquipStar = nil
    self.m_mDrawPartner = nil
    self.m_oShareMgr:Release()
    self.m_oShareMgr = nil
    super(CPartnerCtrl).Release(self)
end

function CPartnerCtrl:Schedule()
    local iPid = self:GetPid()
    local f1
    f1 = function ()
        local oPlayer = global.oAssistMgr:GetPlayer(iPid)
        if oPlayer then
            oPlayer.m_oPartnerCtrl:DelTimeCb("_CheckTop10")
            oPlayer.m_oPartnerCtrl:AddTimeCb("_CheckTop10", 120*1000, f1)
            oPlayer.m_oPartnerCtrl:_CheckTop10()
        end
    end
    f1()
    local f2
    f2 = function ()
       local oPlayer = global.oAssistMgr:GetPlayer(iPid)
        if oPlayer then
            oPlayer.m_oPartnerCtrl:DelTimeCb("_RefreshShow")
            oPlayer.m_oPartnerCtrl:AddTimeCb("_RefreshShow", 600*1000, f2)
            oPlayer.m_oPartnerCtrl:_RefreshShowPartner()
        end
    end
    f2()
    local f3
    f3 = function ()
        local oPlayer = global.oAssistMgr:GetPlayer(iPid)
        if oPlayer then
            oPlayer.m_oPartnerCtrl:DelTimeCb("_CheckTop4")
            oPlayer.m_oPartnerCtrl:AddTimeCb("_CheckTop4", 120*1000, f3)
            oPlayer.m_oPartnerCtrl:_CheckTop4()
        end
    end
    f3()
end

function CPartnerCtrl:_CheckTop10()
    if self.m_bTop10Dirty then
        local lPowers = {}
        for iParId, oPartner in pairs(self.m_mList) do
            table.insert(lPowers, {parid = iParId, grade = oPartner:GetGrade(), power = oPartner:GetPower()})
        end
        local lTop10 = {}
        if next(lPowers) then
            table.sort(lPowers, function(a, b)
                if a.power == b.power then
                    if a.grade == b.grade then
                        return a.parid < b.parid
                    else
                        return a.grade > b.grade
                    end
                else
                    return a.power > b.power
                end
            end)
            local iLen = math.min(#lPowers, 10)
            for i=1, iLen do
                local m = lPowers[i]
                local oPartner = self:GetPartner(m.parid)
                if oPartner then
                    table.insert(lTop10, oPartner:PackRemoteInfo())
                end
            end
        end
        interactive.Send(".world", "partner", "UpdateTop10PowerPartner", {
            pid = self:GetPid(),
            data = lTop10,
            })
        self.m_bTop10Dirty = false

        local iCntPower = 0
        local iCnt = math.min(#lPowers, 4)
        for i=1, iCnt do
            local m = lPowers[i]
            if m then
                iCntPower = iCntPower + m.power
            end
        end
        self:PushAchieve(self:GetPid(),"玩家战力",{ppower = iCntPower})
    end
end

function CPartnerCtrl:_CheckTop4()
    if self.m_bTop4Dirty then
        local lGrades = {}
        for iParId, oPartner in pairs(self.m_mList) do
            table.insert(lGrades, {parid = iParId, grade = oPartner:GetGrade(), power = oPartner:GetPower()})
        end
        local lTop4 = {}
        if next(lGrades) then
            table.sort(lGrades, function(a, b)
                if a.grade == b.grade then
                    if a.power == b.power then
                        return a.parid < b.parid
                    else
                        return a.power > b.power
                    end
                else
                    return a.grade > b.grade
                end
            end)
            local iLen = math.min(#lGrades, 4)
            for i=1, iLen do
                local m = lGrades[i]
                local oPartner = self:GetPartner(m.parid)
                if oPartner then
                    table.insert(lTop4, oPartner:PackRemoteInfo())
                end
            end
        end
        interactive.Send(".world", "partner", "UpdateTop4GradePartner", {
            pid = self:GetPid(),
            data = lTop4,
            })
        self.m_bTop4Dirty = false
    end
end

function CPartnerCtrl:_RefreshShowPartner()
    if #self.m_ShowPartner == 0 and self.m_SendShowPartnerInfo then
        return
    end
    self:RefreshShowPartner(0)
    self.m_SendShowPartnerInfo = true
end

function CPartnerCtrl:GetPartnerShareReaderCopy()
    return self.m_oShareMgr:GenReaderCopy()
end

function CPartnerCtrl:Load(mData)
    mData = mData or {}
    local iPid = self:GetPid()
    local mPartnerData = mData["partner"] or {}
    for _,data in pairs(mPartnerData) do
        local oPartner = loadpartner.LoadPartner(data["partner_type"],data)
        assert(oPartner,string.format("partner sid error:%d",iPid, data["partner_type"]))
        local _,iTraceNo = table.unpack(oPartner:GetData("traceno",{}))
        self.m_mList[iTraceNo] = oPartner
        oPartner.m_iID = iTraceNo
        oPartner:SetInfo("pid", iPid)
        local iParType = oPartner:PartnerType()
        self.m_oShareMgr:AddPartner(iParType, oPartner:PackShare())
        self:SyncCPowerHouse(oPartner)
        if oPartner:IsFrdTravel() then
            self.m_iFrdPartner = oPartner:ID()
        end
        if oPartner:IsMerge() and not self:GetMergePartner(iParType) then
            self.m_mMergePartner[oPartner:PartnerType()] = oPartner:ID()
        end
    end
    self.m_oShareMgr:ShareUpdateAmount()

    local lOwnedEquip = mData["owned_equip"] or {}
    for _, iEquipSid in ipairs(lOwnedEquip) do
        self.m_mOwnedEquip[iEquipSid] = true
    end
    local lOwnedPartner = mData["owned_partner"] or {}
    for _, iPartnerType in ipairs(lOwnedPartner) do
        self.m_mOwnedPartner[iPartnerType] = true
    end
    local lPartnerPicturePos = mData["partner_picture_pos"] or {}
    for _, mData in ipairs(lPartnerPicturePos) do
        self.m_mPicturePos[mData.shape] = mData
    end
    self:SetData("trace_no",mData["trace_no"] or 1)
    self.m_ShowPartner = mData["show_partner"] or {}
    self.m_EqualArena = mData["equal_arena"] or {}
    local mTravel = mData["travel_info"] or {}
    for sPos, iParId in pairs(mTravel) do
        local iPos = tonumber(sPos)
        self.m_mTravel[iPos] = iParId
    end
    self.m_iFollow = mData["follow"] or 0

    local mOnceOwn = mData["once_own"] or {}
    for _,iPartnerType in pairs(mOnceOwn) do
        self.m_OnceOwn[iPartnerType] = true
    end

    local mSkillGuide = mData["skill_guide"] or {}
    for sType, iCount in pairs(mSkillGuide) do
        local iType = tonumber(sType)
        self.m_mParSkillGuide[iType] = iCount or 0
    end

    local mSet = mData["equip_set"] or {}
    for sType, iCount in pairs(mSet) do
        local iType = tonumber(sType)
        self.m_mParEquipSet[iType] = iCount
    end

    local mStar = mData["equip_star"] or {}
    for sType, m in pairs(mStar) do
        local mm = {}
        for _, l in ipairs(m) do
            local iStar, iCount = table.unpack(l)
            mm[iStar] = iCount
        end
        local iType = tonumber(sType)
        self.m_mParEquipStar[iType] = mm
    end
    self.m_mHouseAttr = mData["house_attr"] or {}

    self.m_iHistoryEquipSet = mData["history_equip_set"]
    self.m_iWieldSoul = mData["history_soul_count"]
    self.m_mDrawPartner = mData["draw_partner"]
    self.m_iParEquipCount = mData["history_equip_count"] or 0
end

function CPartnerCtrl:Save()
    local mData = {}
    local mPartnerData = {}
    for _,oPartner in pairs(self.m_mList) do
        table.insert(mPartnerData,oPartner:Save())
    end
    mData["partner"] = mPartnerData

    local lOwnedEquip = {}
    for iEquipSid, _ in pairs(self.m_mOwnedEquip) do
        table.insert(lOwnedEquip, iEquipSid)
    end
    mData["owned_equip"] = lOwnedEquip

    local lOwnedPartner = {}
    for iPartnerType, _ in pairs(self.m_mOwnedPartner) do
        table.insert(lOwnedPartner, iPartnerType)
    end
    mData["owned_partner"] = lOwnedPartner

    local lPartnerPicturePos = {}
    for iShape, mData in pairs(self.m_mPicturePos) do
        table.insert(lPartnerPicturePos, mData)
    end
    mData["partner_picture_pos"] = lPartnerPicturePos

    local mTravel = {}
    for iPos, iParId in pairs(self.m_mTravel) do
        mTravel[db_key(iPos)] = iParId
    end
    mData["travel_info"] = mTravel

    mData["trace_no"] = self:GetData("trace_no",1)
    mData["show_partner"] = self.m_ShowPartner
    mData["equal_arena"] = self.m_EqualArena or {}
    mData["follow"] = self.m_iFollow

    local mOnceOwn = {}
    for iPartnerType,_ in pairs(self.m_OnceOwn) do
        table.insert(mOnceOwn,iPartnerType)
    end
    mData["once_own"] = mOnceOwn

    local mSkillGuide = {}
    for iType, iCount in pairs(self.m_mParSkillGuide) do
        mSkillGuide[db_key(iType)] = iCount
    end
    mData["skill_guide"] = mSkillGuide

    local mSet = {}
    for iType, iCount in pairs(self.m_mParEquipSet) do
        mSet[db_key(iType)] = iCount
    end
    mData["equip_set"] = mSet

    local mStar = {}
    for iType, m in pairs(self.m_mParEquipStar) do
        local l = {}
        for iStar, iCount in pairs(m) do
            table.insert(l, {iStar, iCount})
        end
        mStar[db_key(iType)] = l
    end
    mData["equip_star"] = mStar
    mData["house_attr"] = self.m_mHouseAttr
    mData["history_equip_set"] = self.m_iHistoryEquipSet
    mData["history_soul_count"] = self.m_iWieldSoul
    mData["draw_partner"] = self.m_mDrawPartner
    mData["history_equip_count"] = self.m_iParEquipCount
    return mData
end

function CPartnerCtrl:GetOwner()
    local iPid = self:GetPid()
    local oAssistMgr = global.oAssistMgr
    return oAssistMgr:GetPlayer(iPid)
end

function CPartnerCtrl:CheckTop10Power(oPartner, bRefresh)
    for i, o in ipairs(self.m_mTop10Power) do
        if o:ID() == oPartner:ID() then
            return
        end
    end
    local bInsert = false
    local iLen = #self.m_mTop10Power
    if iLen == 10 then
        local k = iLen
        local o = self.m_mTop10Power[iLen]
        local iPower = oPartner:GetPower()
        while k > 0 do
            local o = self.m_mTop10Power[k]
            if o:GetPower() >= iPower then
                break
            end
            k = k - 1
        end
        if k < 10 then
            table.insert(self.m_mTop10Power, k + 1, oPartner)
            self.m_mTop10Power[iLen + 1] = nil
            self.m_bTop10Dirty = true
            bInsert = true
        end
    else
        local k = iLen
        for i=iLen, 1, -1 do
            local o = self.m_mTop10Power[i]
            if o:GetPower() >= oPartner:GetPower() then
                break
            end
            k = k - 1
        end
        table.insert(self.m_mTop10Power, k + 1, oPartner)
        self.m_bTop10Dirty = true
        bInsert = true
    end
    if bInsert then
        self:PushAchieve(self:GetPid(),"玩家战力",{ppower=self:CountTop4Power()})
    end
end

function CPartnerCtrl:PushAchieve(iPid,sKey,mArgs)
    interactive.Send(".achieve","common","PushAchieve",{
        pid = iPid , key= sKey , data=mArgs
    })
end

function CPartnerCtrl:HistoryMaxEquipSetAmount()
    return self.m_iHistoryEquipSet or 0
end

function CPartnerCtrl:UpdateEquipSetAmount(iSet)
    if not iSet then
        iSet = 0
        for iParId, o in pairs(self.m_mList) do
            if o:IsFullEquip() then
                iSet = iSet + 1
            end
        end
    end
    self.m_iHistoryEquipSet = iSet
end

function CPartnerCtrl:CountEquipSetAmount()
    local iSet = 0
    for iParId, o in pairs(self.m_mList) do
        if o:IsFullEquip() then
            iSet = iSet + 1
        end
    end
    return iSet
end

function CPartnerCtrl:HistoryMaxSoulAmount()
    return self.m_iWieldSoul or 0
end

function CPartnerCtrl:UpdateWieldSoulAmount(iAmount)
    self:Dirty()
    if not iAmount then
        iAmount = 0
        for iParId, o in pairs(self.m_mList) do
            iAmount = iAmount + o:CountSoul()
        end
    end
    self.m_iWieldSoul = iAmount
end

function CPartnerCtrl:CountWieldSoul()
    local iCount = 0
    for iParId, o in pairs(self.m_mList) do
        iCount = iCount + o:CountSoul()
    end
    return iCount
end

function CPartnerCtrl:CountWieldEquip()
    local iCount = 0
    for iParId, o in pairs(self.m_mList) do
        iCount = iCount + o:CountEquip()
    end
    return iCount
end

function CPartnerCtrl:UpdateWieldEquipAmount(iAmount)
    self:Dirty()
    if not iAmount then
        iAmount = 0
        for iParId, o in pairs(self.m_mList) do
            iAmount = iAmount + o:CountEquip()
        end
    end
    self.m_iParEquipCount = iAmount
end

function CPartnerCtrl:HistoryWieldEquip()
    return self.m_iParEquipCount
end

function CPartnerCtrl:CheckTop4Grade(oPartner, bRefresh)
    for i, o in ipairs(self.m_mTop4Grade) do
        if o:ID() == oPartner:ID() then
            return
        end
    end
    local iLen = #self.m_mTop4Grade
    if iLen == 4 then
        local k = iLen
        local o = self.m_mTop4Grade[iLen]
        local iGrade = oPartner:GetGrade()
        while k > 0 do
            local o = self.m_mTop4Grade[k]
            if o:GetGrade() >= iGrade then
                break
            end
            k = k - 1
        end
        if k < 4 then
            table.insert(self.m_mTop4Grade, k + 1, oPartner)
            self.m_mTop4Grade[iLen + 1] = nil
            self.m_bTop4Dirty = true
        end
    else
        local k = iLen
        for i=iLen, 1, -1 do
            local o = self.m_mTop4Grade[i]
            if o:GetGrade() >= oPartner:GetGrade() then
                break
            end
            k = k - 1
        end
        table.insert(self.m_mTop4Grade, k + 1, oPartner)
        self.m_bTop4Dirty = true
    end
end

function CPartnerCtrl:PropChange(oPartner)
    -- for iRank, o in ipairs(self.m_mTop10Power) do
    --     if o:ID() == oPartner:ID() then
    --         self.m_bTop10Dirty = true
    --         break
    --     end
    -- end
    -- for iRank, o in ipairs(self.m_mTop4Grade) do
    --     if o:ID() == oPartner:ID() then
    --         self.m_bTop4Dirty = true
    --         break
    --     end
    -- end
    self.m_bTop10Dirty = true
    self.m_bTop4Dirty = true
end

function CPartnerCtrl:CheckRemoveTop10Power(oPartner)
    local mExclude = {}
    for i, o in ipairs(self.m_mTop10Power) do
        mExclude[o:ID()] = true
    end
    if not mExclude[oPartner:ID()] then
        return
    end
    self:AdjustTop10Power(oPartner, mExclude)
end

function CPartnerCtrl:CheckRemoveTop4Grade(oPartner)
    local mExclude = {}
    for i, o in ipairs(self.m_mTop4Grade) do
        mExclude[o:ID()] = true
    end
    if not mExclude[oPartner:ID()] then
        return
    end
    self:AdjustTop4Grade(oPartner, mExclude)
end

function CPartnerCtrl:AdjustTop10Power(oRemove, mExclude)
    if self:RemoveTop10Power(oRemove) then
        if not mExclude then
            mExclude = {}
            for i, o in ipairs(self.m_mTop10Power) do
                if o:ID() ~= oRemove:ID() then
                    mExclude[o:ID()] = true
                end
            end
        end
    end
    local o = self:GetMaxPowerObj(mExclude)
    if o then
        self:CheckTop10Power(o, true)
    end
end

function CPartnerCtrl:AdjustTop4Grade(oRemove, mExclude)
    if self:RemoveTop4Grade(oRemove) then
        if not mExclude then
            mExclude = {}
            for i, o in ipairs(self.m_mTop4Grade) do
                if o:ID() ~= oRemove:ID() then
                    mExclude[o:ID()] = true
                end
            end
        end
    end
    local o = self:GetMaxGradeObj(mExclude)
    if o then
        self:CheckTop4Grade(o, true)
    end
end

function CPartnerCtrl:RemoveTop10Power(oPartner)
    for i, o in ipairs(self.m_mTop10Power) do
        if oPartner:ID() == o:ID() then
            self.m_bTop10Dirty = true
            table.remove(self.m_mTop10Power, i)
            return true
        end
    end
    return false
end

function CPartnerCtrl:RemoveTop4Grade(oPartner)
    for i, o in ipairs(self.m_mTop4Grade) do
        if oPartner:ID() == o:ID() then
            self.m_bTop4Dirty = true
            table.remove(self.m_mTop4Grade, i)
            return true
        end
    end
    return false
end

function CPartnerCtrl:GetMaxPowerObj(mExclude)
    mExclude = mExclude or {}
    local o
    for iPartnerId, oPartner in pairs(self.m_mList) do
        if not mExclude[iPartnerId] then
            o = o or oPartner
            if o:GetPower() < oPartner:GetPower() then
                o = oPartner
            end
        end
    end
    return o
end

function CPartnerCtrl:GetMaxGradeObj(mExclude)
    mExclude = mExclude or {}
    local o
    for iPartnerId, oPartner in pairs(self.m_mList) do
        if not mExclude[iPartnerId] then
            o = o or oPartner
            if o:GetGrade() < oPartner:GetGrade() then
                o = oPartner
            end
        end
    end
    return o
end

function CPartnerCtrl:ResortTop10Power(oPlayer)
    self.m_bTop10Dirty = true
    self.m_mTop10Power = {}
    for id, o in pairs(self.m_mList) do
        self:CheckTop10Power(o)
    end
end

function CPartnerCtrl:ResortTop4Grade(oPlayer)
    self.m_bTop4Dirty = true
    self.m_mTop4Grade = {}
    for id, o in pairs(self.m_mList) do
        self:CheckTop4Grade(o)
    end
end

function CPartnerCtrl:GetPower()
    local iPower = 0
    for _, oPartner in ipairs(self.m_mTop10Power) do
        iPower = iPower + oPartner:GetPower()
    end

    return iPower
end

function CPartnerCtrl:CountTop4Power()
    local iPower = 0
    for iNo, oPartner in ipairs(self.m_mTop10Power) do
        iPower = iPower + oPartner:GetPower()
        if iNo >= 4 then
            break
        end
    end
    return iPower
end

function CPartnerCtrl:DispatchTraceNo()
    local iTraceNo = self:GetData("trace_no", 1)
    self:SetData("trace_no", iTraceNo + 1)
    return iTraceNo
end

function CPartnerCtrl:UnDirty()
    super(CPartnerCtrl).UnDirty(self)
    for _,oPartner in pairs(self.m_mList) do
        oPartner:UnDirty()
    end
end

function CPartnerCtrl:IsDirty()
    local bDirty = super(CPartnerCtrl).IsDirty(self)
   if bDirty then
        return true
    end
    for _,oPartner in pairs(self.m_mList) do
        if oPartner:IsDirty() then
            return true
        end
    end
    return false
end

function CPartnerCtrl:PackWarInfo()
    local mWarInfo = {}
    for iID,oPartner in pairs(self.m_mList) do
        mWarInfo[iID] = oPartner:PackWarInfo()
    end
    return mWarInfo
end

function CPartnerCtrl:DoMergePartner(oPartner, sReason, mArgs)
    if not oPartner:IsMerge() then
        record.warning("DoMergePartner, pid:%s, parid:%s, reason:%s", self:GetPid(), oPartner:ID(), sReason)
        return
    end
    local iParType = oPartner:PartnerType()
    local oMerge = self:GetMergePartner(iParType)
    if oMerge then
        self:MergePartner(oPartner,oMerge, sReason, mArgs)
    else
        oMerge = oPartner
        self.m_mMergePartner[iParType] = oPartner:ID()
    end
    return oMerge:ID()
    -- return oPartner:ID()
end

function CPartnerCtrl:GetMergePartner(iParType)
    local iMerge = self.m_mMergePartner[iParType]
    local oMerge = self:GetPartner(iMerge)
    return oMerge
end

function CPartnerCtrl:MergePartner(oSrc, oDest, sReason, mArgs)
    self:Dirty()
    self.m_mList[oSrc:ID()] = nil
    local iAmount =  oSrc:GetAmount()
    oDest:AddAmount(iAmount, sReason, mArgs)

    --pid|玩家id,srcid|被合并,destid|合并目标,partype|伙伴导表id,add|合并数量,after|合并后数量,reason|操作
    record.user("partner", "merge_partner", {
        pid = self:GetPid(),
        srcid = oSrc:ID(),
        destid = oDest:ID(),
        partype = oSrc:PartnerType(),
        add = iAmount,
        after = oDest:GetAmount(),
        reason = sReason,
        })

    baseobj_safe_release(oSrc)
end

function CPartnerCtrl:AddPartner(oPartner, sReason, mArgs)
    self:Dirty()
    mArgs = mArgs or {}
    self:DispatchPartnerID(oPartner)
    self:OnAddPartner(oPartner, sReason, mArgs)
    self:LogPartnerInfo("add_partner", oPartner, sReason, mArgs)
    return oPartner:ID()
end

function CPartnerCtrl:DispatchPartnerID(oPartner)
    local iTraceNo = self:DispatchTraceNo()
    oPartner:SetData("traceno",{self:GetInfo("pid"),iTraceNo})
    oPartner.m_iID = iTraceNo
    oPartner:SetInfo("pid", self:GetInfo("pid"))
end

function CPartnerCtrl:OnAddPartner(oPartner, sReason, mArgs)
    local iParId = oPartner:ID()
    self.m_mList[iParId] = oPartner
    self:SyncCPowerHouse(oPartner)
    self:AddOwnedPartner(oPartner)
    local bRefresh = true
    self:CheckRankPPower(oPartner, bRefresh)
end

function CPartnerCtrl:CheckOnFight(oPartner, sReason)
    local mFight = self:GetData("fight_partner",{})
    local iMaxPos = self:GetFightMaxPos()
    local iPos = 1
    local iParId = mFight[iPos]
    if not iParId then
        self:OnFight(iPos,oPartner:ID(), false, sReason)
        -- self:RemoteFightPartner(iPos, oPartner:ID(), oPartner:PackRemoteInfo())
        return true
    end
    return false
end

function CPartnerCtrl:GetFightMaxPos()
    local oPlayer =  self:GetOwner()
    local mFightData = self:GetOnFightPosList()
    local iMaxPos = 1
    for iPos, m in pairs(mFightData) do
        if m.level <= oPlayer:GetGrade() and iMaxPos < iPos then
            iMaxPos = iPos
        end
    end
    return iMaxPos
end

function CPartnerCtrl:GetOnFightPosList()
    local res = require "base.res"
    return res["daobiao"]["onfight"]
end

function CPartnerCtrl:GetPartner(iPartnerId)
    return self.m_mList[iPartnerId]
end

function CPartnerCtrl:GetList()
    return self.m_mList
end

function CPartnerCtrl:HasParEquipType(iEquipSid)
    return self.m_mOwnedEquip[iEquipSid]
end

function CPartnerCtrl:AddOwnedEquip(iEquipSid)
    if self:HasParEquipType(iEquipSid) then
        return
    end
    self:Dirty()
    self.m_mOwnedEquip[iEquipSid] = true
end

function CPartnerCtrl:AddOwnedPartner(oPartner)
    self:Dirty()
    local iPartnerType =oPartner:PartnerType()
    self.m_mOwnedPartner[iPartnerType] = true
    self.m_oShareMgr:AddPartner(iPartnerType, oPartner:PackShare())
    self.m_oShareMgr:ShareUpdateAmount()
end

function CPartnerCtrl:RecordParEquipSet(iSetType, iCount)
    local iHave = self.m_mParEquipSet[iSetType] or 0
    if iCount <= iHave then
        return
    end
    self:Dirty()
    self.m_mParEquipSet[iSetType] = iCount
    if table_in_list({2,4}, iCount) then
        -- local sKey = string.format("激活%s件套符文次数", iCount)
        -- global.oAssistMgr:PushAchieve(self:GetPid(), sKey, {value = 1})
    end
end

function CPartnerCtrl:ActivePropChange()
    for _, oPartner in pairs(self.m_mList) do
        oPartner:ActivePropChange()
    end
end

function CPartnerCtrl:ValidSwitchPartnerPicture(lPictureData)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local oPlayer = self:GetOwner()
    local iRoleShape = oPlayer:GetShape()
    local mDuplicate = {}
    for _, mData in ipairs(lPictureData) do
        local iShape = mData.shape
        if not self.m_mOwnedPartner[iShape] and iShape ~= iRoleShape then
            return false
        end
        if mDuplicate[iShape] then
            oAssistMgr:Notify(iPid, "伙伴id重复")
            return false
        end
        mDuplicate[iShape] = true
    end
    return true
end

function CPartnerCtrl:SwitchPartnerPicture(lPictureData)
    self:Dirty()
    local mPicture = {}
    for _, mData in ipairs(lPictureData) do
        local iShape = mData.shape
        mPicture[iShape] = {
            x = mData.x,
            y = mData.y,
            z = mData.z,
            direction = mData.direction,
            shape = iShape,
        }
    end
    self.m_mPicturePos = mPicture
    self:GS2CPartnerPicturePosList(self:GetOwner())
end

function CPartnerCtrl:GS2CPartnerPicturePosList(oPlayer, bOnLogin)
    local lPartnerPicturePos = {}
    for iShape, mData in pairs(self.m_mPicturePos) do
        table.insert(lPartnerPicturePos, {
            x = mData.x,
            y = mData.y,
            z = mData.z,
            direction = mData.direction,
            shape = iShape,
            })
    end
    oPlayer:Send("GS2CPartnerPicturePosList", {
        pos_list = lPartnerPicturePos,
        })
    if not bOnLogin then
        local oAssistMgr = global.oAssistMgr
        oAssistMgr:Notify(oPlayer:GetPid(), "图集保存成功!")
    end
end

function CPartnerCtrl:ValidSwitchPartner(lFightInfo)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local iMaxPos = self:GetFightMaxPos()
    local mPos1,mPos2 = table.unpack(lFightInfo)
    if mPos1.pos > iMaxPos or mPos2.pos > iMaxPos then
        oAssistMgr:Notify(iPid, "位置未解锁")
        return false
    end
    if (mPos1.pos < 1 or mPos1.pos > 4)
        or (mPos2.pos < 1 or mPos2.pos > 4) then
        oAssistMgr:Notify(iPid, "位置信息错误")
        return false
    end

    if (mPos1.pos == 1 and mPos1.parid == 0)
        or (mPos2.pos == 1 and mPos2.parid == 0) then
        oAssistMgr:Notify(iPid, "主战伙伴无法下阵")
        return false
    end
    return true
end

function CPartnerCtrl:CheckInFight(iPos, iPartnerId)
    local mFight = self:GetData("fight_partner", {})
    local iFightParid = mFight[iPos]
    if iFightParid and iFightParid == iPartnerId then
        return true
    else
        return false
    end
end

function CPartnerCtrl:SetFightInfo(iPos, iParId)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local oPartner = self:GetPartner(iParId)
    if not oPartner then
        oAssistMgr:Notify(iPid, "伙伴不存在")
        record.warning("SetFightInfo err:%s,%s", iPid, iParId)
        return
    end
    local iType = oPartner:PartnerType()
    if iPos > self:GetFightMaxPos() then
        return
    end
    if oPartner then
        local iOldPos = oPartner:GetFight()
        if iOldPos > 0 then
            if iPos == 1 then
                oAssistMgr:Notify(self:GetPid(), "主战伙伴无法下阵")
                return
            end
            if iOldPos ~= iPos then
                return
            end
            if not self:CheckInFight(iPos, iParId) then
                return
            end
            self:OffFight(iPos, true, "伙伴下阵")
            self:RemoteFightPartner(iPos, 0)
        else
            self:OnFight(iPos, iParId, true, "伙伴上阵")
            self:RemoteFightPartner(iPos, iParId, oPartner:PackRemoteInfo())
        end
        -- oPartner:SyncTeamPartnerInfo()
    end
end

function CPartnerCtrl:OnFight(iPos, iParId, bRefresh, sReason)
    local oPartner = self:GetPartner(iParId)
    if oPartner then
        local iOldPos = oPartner:GetFight()
        if iOldPos > 0 then
            self:OffFight(iOldPos, true, sReason)
            self:RemoteFightPartner(iOldPos, 0)
        end
        local mFight = self:GetData("fight_partner", {})
        local iOldParid = mFight[iPos]
        if iOldParid then
            self:OffFight(iPos, false, sReason)
            self:RemoteFightPartner(iPos, 0)
        end
        oPartner:SetFight(iPos)
        mFight[iPos] = iParId
        self:SetData("fight_partner", mFight)
        if bRefresh then
            self:GS2CRefreshFightPartner(iPos, iParId)
        end
        self:LogFightPos(oPartner:PartnerType(), iParId, iOldPos, oPartner:GetFight(), sReason)
    end
end

function CPartnerCtrl:OffFight(iPos, bRefresh, sReason)
    local mFight = self:GetData("fight_partner")
    local iParId = mFight[iPos]
    if not iParId then
        return
    end
    local oPartner = self:GetPartner(iParId)
    local iOldPos = oPartner:GetFight()
    if oPartner then
        oPartner:SetFight(0)
        mFight[iPos] = nil
        self:SetData("fight_partner", mFight)
        if bRefresh then
            self:GS2CRefreshFightPartner(iPos, 0)
        end
        self:LogFightPos(oPartner:PartnerType(), iParId, iOldPos, oPartner:GetFight(), sReason)
    end
end

function CPartnerCtrl:LogFightPos(iPartnerType, iParId, iOldPos, iNowPos, sReason)
    local mLog = {
        pid = self:GetPid(),
        parid = iParId,
        sid = iPartnerType,
        pos_old = iOldPos,
        pos_now = iNowPos,
        reason = sReason,
    }
    record.user("partner", "partner_fight", mLog)
end

function CPartnerCtrl:ValidFightPos(iPos, iParId)
    local mFight = self:GetData("fight_partner")
    local iTargetParid = mFight[iPos] or 0
    if iTargetParid ~= iParId then
        return false
    end
    return true
end

function CPartnerCtrl:SwitchFightPartner(mPos1, mPos2)
    local oPartner1 = self:GetPartner(mPos1.parid)
    local oPartner2 = self:GetPartner(mPos2.parid)
    if not oPartner1 and not oPartner2 then
        return
    end
    if mPos1.pos == 0 and mPos2.pos == 0 then
        return
    end
    if not self:ValidFightPos(mPos1.pos, mPos2.parid) then
        return
    end
    if not self:ValidFightPos(mPos2.pos, mPos1.parid) then
        return
    end
    local sReason = "交换上阵伙伴"
    self:OffFight(mPos1.pos, false, sReason)
    self:OffFight(mPos2.pos, false, sReason)
    self:OnFight(mPos1.pos, mPos1.parid, false, sReason)
    self:OnFight(mPos2.pos, mPos2.parid, false, sReason)
    local mData1 = oPartner1 and oPartner1:PackRemoteInfo()
    local mData2 = oPartner2 and oPartner2:PackRemoteInfo()
    self:RemoteFightPartner(mPos1.pos, mPos1.parid, mData1)
    self:RemoteFightPartner(mPos2.pos, mPos2.parid, mData2)
    self:GS2CRefreshFightPartner(mPos1.pos, mPos1.parid)
    self:GS2CRefreshFightPartner(mPos2.pos, mPos2.parid)
end

--参战伙伴
function CPartnerCtrl:GetFightPartner()
    local mData = {}
    local mFight = self:GetData("fight_partner",{})
    for iPos = 1,4 do
        local iPartnerId = mFight[iPos]
        if iPartnerId then
            local oPartner = self:GetPartner(iPartnerId)
            if oPartner then
                mData[iPos] = oPartner
            end
        end
    end
    return mData
end

function CPartnerCtrl:GetTeamPartner()
    local mData = {}
    local mFight = self:GetData("fight_partner",{})
    for iPos = 1,4 do
        local iPartnerId = mFight[iPos]
        if iPartnerId then
            local mInfo = {}
            local oPartner = self:GetPartner(iPartnerId)
            mInfo["parid"] = iPartnerId
            mInfo["name"] = oPartner:GetName()
            mInfo["grade"] = oPartner:GetGrade()
            mInfo["pos"] = iPos
            mInfo["model_info"] = oPartner:GetModelInfo()
            table.insert(mData,mInfo)
        end
    end
    return mData
end

function CPartnerCtrl:GetMainPartner()
    local mFight = self:GetData("fight_partner",{})
    local iPartnerId = mFight[1]
    if not iPartnerId then
        return
    end
    local oPartner = self:GetPartner(iPartnerId)
    return oPartner
end

function CPartnerCtrl:RemovePartnerList(lRemove, sReason)
    self:Dirty()

    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(self:GetInfo("pid"))
    for _, iParId in ipairs(lRemove) do
        local oPartner = self:GetPartner(iParId)
        if oPartner then
            local bRefresh = false
            self:RemovePartner(oPartner, bRefresh, sReason)
        end
    end
    self:PartnerAmountChange()
    local mRemove = {}
    for _, iParId in ipairs(lRemove) do
        local o = self:GetPartner(iParId)
        if o then
            o:PropChange("amount")
        else
            mRemove[iParId] = 1
        end
    end
    self:GS2CDelPartner(table_key_list(mRemove))
end

function CPartnerCtrl:RemovePartner(oPartner, bRefresh, sReason)
    self:Dirty()

    -- self:CheckRemoveTop10Power(oPartner)
    -- self:CheckRemoveTop4Grade(oPartner)
    oPartner:AddAmount(-1, sReason)
    if oPartner:GetAmount() <= 0 then
        self:TrueRemovePartner(oPartner, bRefresh, sReason)
    end
end

function CPartnerCtrl:TrueRemovePartner(oPartner, bRefresh, sReason)
    self.m_bTop10Dirty = true
    self.m_bTop4Dirty = true

    local iParId = oPartner:ID()
    local iPos = oPartner:GetFight()
    local mFight = self:GetData("fight_partner")
    if mFight[iPos] == iParId then
        mFight[iPos] = nil
        self:SetData("fight_partner", mFight or {})
        self:GS2CRefreshFightPartner(iFightPos, 0)
    end
    if oPartner:GetData("traceno") then
        oPartner:SetData("traceno",nil)
    end
    if oPartner:IsMerge() then
        self.m_mMergePartner[oPartner:PartnerType()] = nil
    end
    self.m_mList[oPartner.m_iID] = nil
    self:OnRemovePartner(oPartner)
    oPartner:OnRemove()
    if bRefresh then
        self:PartnerAmountChange()
        self:GS2CDelPartner({iParId})
    end
    self:LogPartnerInfo("del_partner", oPartner, sReason, mArgs)
    baseobj_safe_release(oPartner)
end

function CPartnerCtrl:OnRemovePartner(oPartner)
    local iParType = oPartner:PartnerType()
    local iParId = self:GetRankPPower(iParType)
    if iParId == oPartner:ID() then
        self:RemovePPower(iParType)
        local oNext = self:QueryNextPowerPar(iParType, {[iParId] = 1})
        if oNext then
            self:CheckRankPPower(oNext, true)
        else
            self:RemovePPowerRank(iParType)
        end
    end
end

function CPartnerCtrl:QueryNextPowerPar(iParType, mExclude)
    mExclude = mExclude or {}
    local oRetPar
    for iParId, oPartner in pairs(self.m_mList) do
        if not mExclude[iParId] and oPartner:PartnerType() == iParType then
            oRetPar = oRetPar or oPartner
            if oRetPar:GetPower() < oPartner:GetPower() then
                oRetPar = oPartner
            end
        end
    end
    return oRetPar
end

function CPartnerCtrl:RemovePPower(iParType)
    self:Dirty()
    self.m_mRankPPower[iParType] = nil
end

function CPartnerCtrl:RemovePPowerRank(iParType)
    interactive.Send(".rank", "rank", "RemoveDataFromRank", {
        rank_name = "parpower",
        keys = {iParType, self:GetPid()},
        })
end

function CPartnerCtrl:EmptyPartnerSpace()
    local iUse = table_count(self.m_mList)
    return math.max(gamedefines.PARTNER_MAX_AMOUNT - iUse, 0)
end

--list:{sid, amount}
function CPartnerCtrl:ValidGive(mPartnerList, mArgs)
    local oAssistMgr = global.oAssistMgr

    mPartnerList = mPartnerList or {}
    mArgs = mArgs or {}

    local iNeedSpace = 0
    local iPid = self:GetInfo("pid")
    for _, mData in pairs(mPartnerList) do
        local iPartnerType, iAmount = table.unpack(mData)
        assert(iAmount > 0, string.format("partner err: %s,%s,%s",iPid, iPartnerType, iAmount))
        iNeedSpace = iNeedSpace + iAmount
    end

    local bResult = true
    if  self:EmptyPartnerSpace() < iNeedSpace then
        if not mArgs.cancel_tip then
            local sTip = "伙伴已满"
            oAssistMgr:Notify(iPid, sTip)
        end
        bResult = false
    end

    return bResult
end

function CPartnerCtrl:SetOnceOwn(iPartnerType)
    self:Dirty()
    self.m_OnceOwn[iPartnerType] = true
end

function CPartnerCtrl:GetOnceOwn()
    local mNet = {}
    for iParType,_ in pairs(self.m_OnceOwn) do
        local oPartner = self:GetPartnerByType(iParType)
        if oPartner then
            table.insert(mNet,{sid=iParType,star=oPartner:GetStar()})
        end
    end
    return mNet
end

function CPartnerCtrl:GetPartnerByType(iParType)
    for iParId, oPartner in pairs(self.m_mList) do
        if oPartner:PartnerType() == iParType then
            return oPartner
        end
    end
    return nil
end

function CPartnerCtrl:IsOpenSoul()
    local oAssistMgr = global.oAssistMgr
    local oPlayer = self:GetOwner()
    if oPlayer then
        local iOpenGrade = oAssistMgr:QueryControl("parsoul", "open_grade")
        return oPlayer:GetGrade() >= iOpenGrade
    end
    return false
end

function CPartnerCtrl:AddDrawPartner(mDraw)
    self:Dirty()
    self.m_mDrawPartner = mDraw
end

function CPartnerCtrl:HasDrawPartner()
    return self.m_mDrawPartner
end

function CPartnerCtrl:ReDrawPartner(oPlayer)
    local iShape = 10019
    local oItem = oPlayer.m_oItemCtrl:GetItemObj(iShape)
    local sReason = "重新刷新一发入魂"
    local mData = {}
    mData.pid = oPlayer:GetPid()
    mData.goldcoin = oItem:RedrawCost()
    mData.args = {}
    mData.reason = sReason
    if mData.goldcoin <= 0 then
        record.warning("ComposePartner, pid:%s,goldcoin:%s", self:GetPid(), mData.goldcoin)
        return
    end
    interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
        local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
        if oPlayer then
            oPlayer.m_oPartnerCtrl:DoReDrawPartner(m)
        end
    end)
end

function CPartnerCtrl:DoReDrawPartner(m)
    local bSucc = false
    local oPlayer = self:GetOwner()
    if m.success then
        local iShape = 10019
        local oItem = oPlayer.m_oItemCtrl:GetItemObj(iShape)
        if oItem then
            bSucc = true
            local mDraw = oPlayer:HasDrawPartner()
            local iParType = mDraw and mDraw.partype
            oPlayer:ResetDrawPartner()
            oPlayer.m_oItemCtrl:ItemUse(oItem:ID(),m.pid,1, {partype = iParType, reason = m.reason})
        end
    end
    oPlayer:DoResultMoney(bSucc, m)
end

function CPartnerCtrl:TransFirstChargeChip()
    local val = global.oAssistMgr:QueryGlobalData("first_charge_chip")
    return tonumber(val)
end

--list:{sid, amount, mArgs}
function CPartnerCtrl:GivePartner(mPartnerList, sReason, mArgs)
    local oAssistMgr = global.oAssistMgr
    self:Dirty()
    self.m_bTop4Dirty = true
    self.m_bTop10Dirty = true
    mArgs = mArgs or {}
    local iLegend = 0
    local mParId = {}
    local lOnFight = {}
    local mBookAmount = {}
    local mShowPartner = {}
    local mHousePartner = {}
    local oPlayer = self:GetOwner()
    local iPid = self:GetPid()
    for _, mData in ipairs(mPartnerList) do
        local iPartnerType, iAmount, mArg = table.unpack(mData)
        mArg = mArg or {}
        local mPartner = loadpartner.GetPartnerData(iPartnerType)
        assert(mPartner, string.format("partner data: %s not exist! reason:%s", iPartnerType, sReason))
        if  mPartner.usable == 1 then
            local sDesc
            local oPartner = self:GetPartnerByType(iPartnerType)
            if oPartner then
                local iChip = oPartner:Decompose() * iAmount
                if mArgs.first_charge and iAmount > 0 then
                    iChip =  oPartner:Decompose() * (iAmount - 1) + self:TransFirstChargeChip()
                end
                self:Trans2Chip(iPartnerType, iChip, sReason, {cancel_tip = 1, cancel_show = 1})
                sDesc = string.format("你已获得%s，将自动转换成%s个%s碎片", mPartner.name, iChip, mPartner.name)
                if oPartner:Rare() > 1 and mArgs.chuanwen then
                    global.oNotifyMgr:SendSysChat(mArgs.chuanwen , 1, 1)
                end
            else
                local oPartner = loadpartner.CreatePartner(iPartnerType, mArg)
                local iParId = self:AddPartner(oPartner, sReason, {cancel_tip = 1})
                oPartner = self:GetPartner(iParId)
                if self:IsOpenSoul() then
                    oPartner:SetSoulType(oPartner:GetDefaultSoulType())
                end
                sDesc = "恭喜你获得伙伴：" .. mPartner.name
                if iAmount > 1 then
                    local i = iAmount - 1
                    local iChip = oPartner:Decompose() * i
                    if mArgs.first_charge then
                        iChip =  oPartner:Decompose() * (i-1) + self:TransFirstChargeChip()
                    end
                    self:Trans2Chip(iPartnerType, iChip, sReason, {cancel_tip = 1, cancel_show = 1})
                end
                self:SetOnceOwn(iPartnerType)
                if self:CheckOnFight(oPartner, sReason) then
                    table.insert(lOnFight, oPartner)
                end
                mParId[oPartner:ID()] = 1
                local iStar = math.max(oPartner:GetStar(),1)
                local iLevel = math.max(oPartner:GetGrade(), 1)
                mBookAmount[iPartnerType] = 1
                mHousePartner[iPartnerType] = 1
                oAssistMgr:PushAchieve(iPid,"伙伴数量",{target = iPartnerType,value=1})
                oAssistMgr:PushAchieve(iPid,"伙伴星级",{target = iPartnerType,value=iStar})
                oAssistMgr:PushAchieve(iPid,"伙伴总星级",{value=iStar})
                oAssistMgr:PushAchieve(iPid,"伙伴等级",{target = iPartnerType,value=iLevel})
                oAssistMgr:PushAchieve(iPid,string.format("拥有%s星伙伴数量", iStar),{value = 1})
                oPlayer:TriggerPartnerTask(iPartnerType)
                if oPartner:Rare() > 1 then
                    iLegend = iLegend + 1
                end
                --todo tips
                local lMessage = {}
                local sMsg = mArgs.tips
                if not sMsg then
                    sMsg = partnerdefine.FormatPartnerColorName(oPartner:Rare(), "获得[%s]")
                    sMsg = string.format(sMsg, oPartner:GetName())
                end
                if not mArgs.cancel_tip then
                    table.insert(lMessage,"GS2CNotify")
                end
                if not mArgs.cancel_channel then
                    table.insert(lMessage,"GS2CConsumeMsg")
                end
                if #lMessage > 0 then
                    oAssistMgr:BroadCastNotify(iPid,lMessage,sMsg, nil)
                end
                if mArgs.chuanwen then
                    global.oNotifyMgr:SendSysChat(mArgs.chuanwen , 1, 1)
                end
            end
            if not mShowPartner[iPartnerType] then
                mShowPartner[iPartnerType] = sDesc
            end
        else
            record.error("partner service GivePartner err: %s, %s, %s", self:GetPid(), iPartnerType, sReason)
        end
    end
    if iLegend > 0 then
        oAssistMgr:PushAchieve(iPid,"传说伙伴个数",{value=iLegend})
    end
    self:PartnerAmountChange()
    if next(mBookAmount) then
        self:PushBookAmount(mBookAmount)
    end
    local lParIds = table_key_list(mParId)
    self:GS2CAddPartnerList(lParIds)
    if next(lOnFight) then
        for _, oPartner in ipairs(lOnFight) do
            self:GS2CRefreshFightPartner(oPartner:GetFight(), oPartner:ID())
            self:RemoteFightPartner(oPartner:GetFight(), oPartner:ID(), oPartner:PackRemoteInfo())
        end
    end
    if not mArgs.cancel_show then
        self:ShowNewPartnerUI(mShowPartner)
    end
    self:AddHousePartner(mHousePartner, sReason)
    return lParIds
end

function CPartnerCtrl:PushBookAmount(mBookAmount)
    local lBookCondition = {}
    for iPartnerType, iAmount in pairs(mBookAmount) do
        local mCondition = {}
        local m = loadpartner.GetPartnerData(iPartnerType)
        local sKey = string.format("获得%s", m.name)
        table.insert(lBookCondition, {key = sKey,value = iAmount})
    end
    global.oAssistMgr:PushCondition(self:GetPid(), lBookCondition)
end

function CPartnerCtrl:ShowNewPartnerUI(mShow)
    local lNet = {}
    for iParType, sDesc in pairs(mShow) do
        table.insert(lNet, {par_type = iParType, desc = sDesc})
    end
    local oPlayer = self:GetOwner()
    if oPlayer and next(lNet) then
        oPlayer:Send("GS2CShowNewPartnerUI", {par_types = lNet})
    end
end

function CPartnerCtrl:Trans2Chip(iParType,iAmount,sReason,mArg)
    if iAmount > 0 then
        local oAssistMgr = global.oAssistMgr
        local iPid = self:GetPid()
        local oPlayer = self:GetOwner()

        local iChipSid = partnerdefine.GetChipByParType(iParType)
        if oPlayer then
            oPlayer:GiveItem({{iChipSid, iAmount}}, sReason, mArg)
        end
        local m = loadpartner.GetPartnerData(iParType)
        local sMsg = string.format("你已获得%s，将自动转换成%s个%s碎片", m.name, iAmount, m.name)
        oAssistMgr:BroadCastNotify(iPid, nil, sMsg)
    end
end

function CPartnerCtrl:AddHousePartner(mPartner, sReason)
    local iPid = self:GetPid()
    interactive.Send(".world", "partner", "AddHousePartner", {
        pid = self:GetPid(),
        data = mPartner,
        reason = sReason,
        })
end

function CPartnerCtrl:ValidCostPartner(lCostList)
    local iPid = self:GetPid()
    local oAssistMgr = global.oAssistMgr
    local mDuplicate = {}
    for _, iParId in ipairs(lCostList) do
        local oPtn = self:GetPartner(iParId)
        if not oPtn then
            oAssistMgr:Notify(iPid, "伙伴不存在")
            return false
        end
        if not oPtn:ValidRemove() then
            return false
        end
        if mDuplicate[iParId] and not oPtn:IsMerge() then
            return false
        end
        local iCost = mDuplicate[iParId] or 0
        iCost = iCost + 1
        if oPtn:GetAmount() < iCost then
            oAssistMgr:Notify(iPid, "包子不足")
            return false
        end
        mDuplicate[iParId] = iCost
    end
    return true
end

function CPartnerCtrl:ResetPartnerStatus(list)
    for _, iParId in ipairs(list) do
        local o = self:GetPartner(iParId)
        if o then
            o:SetStatus(PARTNER_STATUS.NORMAL)
        end
    end
end

function CPartnerCtrl:ValidCostStarPartner(oPartner, lCostList)
    local iPid = self:GetPid()
    local oAssistMgr = global.oAssistMgr
    local mDuplicate = {}
    for _, iParId in ipairs(lCostList) do
        local oPtn = self:GetPartner(iParId)
        if not oPtn then
            oAssistMgr:Notify(iPid, "消耗伙伴不存在")
            return false
        end
        if not oPtn:ValidRemove() then
            return false
        end
        if oPtn:GetStar() ~= oPartner:GetStar() then
            oAssistMgr:Notify(iPid, "星级不符")
            return false
        end
        if oPtn:IsMerge() and oPtn:GetStar() > 1 then
            oAssistMgr:Notify(iPid, "高星肉包子不可用于升星")
            return false
        end
        if mDuplicate[iParId] then
            oAssistMgr:Notify(iPid, "消耗伙伴重复")
            return false
        end
        mDuplicate[iParId] = 1
    end
    return true
end

function CPartnerCtrl:IncreasePartnerStar(iParId, lCostList)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = self:GetOwner()
    local oPartner = self:GetPartner(iParId)
    if not oPartner or not oPlayer then
        return
    end
    if not oPartner:IsStarLimitGrade() then
        return
    end
    local iPid = self:GetPid()
    if oPartner:IsLimitStar() then
        oAssistMgr:Notify(iPid, "已达最大星级")
        return
    end
    local iParType = oPartner:PartnerType()
    local iChipSid = partnerdefine.GetChipByParType(iParType)
    local mStarData = oPartner:GetStarData()
    local iCostAmount = mStarData.cost_amount
    if not oPlayer:ValidRemoveItemAmount(iChipSid, iCostAmount) then
        oAssistMgr:Notify(iPid, string.format("%s碎片不足", oPartner:GetDefaultName()))
        return
    end
    local sReason = "伙伴升星消耗"
    local mData = {}
    mData.pid = self:GetPid()
    mData.coin = mStarData.cost_coin
    mData.args = {}
    mData.reason = sReason
    if mData.coin <= 0 then
        record.warning("IncreasePartnerStar, pid:%s,coin:%s", self:GetPid(), mData.coin)
        return
    end
    interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
        local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
        if oPlayer then
            oPlayer.m_oPartnerCtrl:DoIncreaseStar(m, iParId, lCostList)
        end
    end)
end

function CPartnerCtrl:DoIncreaseStar(m, iParId, lCostList)
    if m.success then
        self:SuccessIncreaseStar(m, iParId, lCostList)
    end
end

function CPartnerCtrl:SuccessIncreaseStar(m, iParId, lCostList)
    local bSucc = false
    local oPartner = self:GetPartner(iParId)
    local oPlayer = self:GetOwner()
    if oPartner then
        local iParType = oPartner:PartnerType()
        local iChipSid = partnerdefine.GetChipByParType(iParType)
        local mStarData = oPartner:GetStarData()
        local iAmount = mStarData.cost_amount
        if oPlayer.m_oItemCtrl:RemoveItemAmount(iChipSid, iAmount, m.reason, m.args) then
            bSucc = true
            oPartner:IncreaseStar(1)
            local iStar = oPartner:GetStar()
            global.oAssistMgr:PushAchieve(oPlayer:GetPid(),"伙伴星级",{target = iPartnerType,value=iStar})
        end
    end
    oPlayer:DoResultMoney(bSucc, m)
end

function CPartnerCtrl:ComposePartner(iChipSid, iCompose)
    if not iChipSid or not iCompose then
        record.warning("ComposePartner, pid:%s", self:GetPid())
        return
    end
    if iCompose <= 0 then
        record.warning("ComposePartner, pid:%s,compose:%s", self:GetPid(),iCompose)
        return
    end
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local oChip = loaditem.GetItem(iChipSid)
    if oChip:ItemType() ~= "partnerchip" then
        oAssistMgr:Notify(iPid, "非伙伴碎片,合成失败")
        return
    end
    local iPartnerType = oChip:PartnerType()
    local oPartner = self:GetPartnerByType(iPartnerType)
    if oPartner then
        oAssistMgr:Notify(iPid, "已存在同类型伙伴")
        return
    end
    local oPlayer = self:GetOwner()
    local iHaveChip = oPlayer.m_oItemCtrl:GetItemAmount(iChipSid)
    local iComposeCost = oChip:ComposeAmount()
    assert(iComposeCost > 0, string.format("chip compose partner err: %s", iChipSid))
    local iCanCompose = iHaveChip // iComposeCost
    if self:EmptyPartnerSpace() < iCompose then
        oAssistMgr:Notify(iPid, "合成失败,已达伙伴数量上限")
        return
    end
    if iCanCompose >= iCompose then
        local sReason = "碎片合成伙伴消耗"
        local iPartnerType = oChip:PartnerType()
        local iCostChip = iComposeCost * iCompose

        local mData = {}
        mData.pid = iPid
        mData.coin = oChip:CoinCost() * iCompose
        mData.args = {cancel_tip=1}
        mData.reason = sReason
        if mData.coin <= 0 then
            record.warning("ComposePartner, pid:%s,coin:%s", self:GetPid(), mData.coin)
            return
        end
        interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
            local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
            if oPlayer then
                oPlayer.m_oPartnerCtrl:DoComposePartner(m, iPartnerType, iChipSid, iCostChip,iCompose)
            end
        end)
    end
end

function CPartnerCtrl:DoComposePartner(m, iPartnerType, iChipSid, iCostAmount,iCompose)
    local oPlayer = self:GetOwner()
    if m.success then
        local bFlag = true
        local oChip = loaditem.GetItem(iChipSid)
        local iHaveChip = oPlayer.m_oItemCtrl:GetItemAmount(iChipSid)
        local iComposeCost = oChip:ComposeAmount()
        local sMsg
        if self:EmptyPartnerSpace() < iCompose then
            bFlag = false
            sMsg = "伙伴已满,合成失败"
        end
        if iHaveChip < iCostAmount then
            bFlag = false
            sMsg = "碎片不足合成失败"
        end
        local oPartner = self:GetPartnerByType(iPartnerType)
        if oPartner then
            bFlag = false
            sMsg = "已存在同类型伙伴"
            return
        end
        if bFlag then
            oPlayer.m_oItemCtrl:RemoveItemList({{iChipSid, iCostAmount}}, m.reason)
            local mArgs = {}
            mArgs.cancel_tip = 1
            local mData = loadpartner.GetPartnerData(iPartnerType, iPartnerType)
            local args = {
                {"&role&", oPlayer:GetName()},
                {"&partner&", iPartnerType},
                {"&amount&", 1},
            }
            if mData.rare == 1 then
                mArgs.chuanwen =global.oAssistMgr:GetPartnerTextData(1004, args)
            else
                mArgs.chuanwen =global.oAssistMgr:GetPartnerTextData(1002, args)
            end
            local lParIds = self:GivePartner({{iPartnerType, iCompose}}, m.reason, mArgs)
            oPlayer:Send("GS2CComposePartner", {parid = lParIds[1]})
        end
        oPlayer:DoResultMoney(bFlag, m)
        if sMsg then
            global.oAssistMgr:Notify(self:GetPid(), sMsg)
        end
    end
end

function CPartnerCtrl:AwakePartner(iParId)
    local iPid = self:GetPid()
    local oPlayer = self:GetOwner()
    local oAssistMgr = global.oAssistMgr
    local oPartner = self:GetPartner(iParId)
    if not oPartner then
        oAssistMgr:Notify(iPid, "伙伴不存在")
        return
    end
    if not oPartner:ValidAwake() then
        return
    end

    local mCostItem = oPartner:GetAwakeCost()
    for _, mCost in pairs(mCostItem) do
        local iHave = oPlayer.m_oItemCtrl:GetItemAmount(mCost.sid)
        if iHave < mCost.amount then
            oAssistMgr:Notify(iPid, "材料不足,觉醒失败")
            return
        end
    end

    local sReason = "伙伴觉醒消耗"
    local mData = {}
    mData.pid = iPid
    mData.coin = oPartner:GetAwakeCoinCost()
    mData.args = {cancel_tip=1}
    mData.reason = sReason
    if mData.coin <= 0 then
        record.warning("AwakePartner, pid:%s,coin:%s", self:GetPid(), mData.coin)
        return
    end
    interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
        local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
        if oPlayer then
            oPlayer.m_oPartnerCtrl:DoAwakePartner(m, iParId)
        end
    end)
end

function CPartnerCtrl:DoAwakePartner(m, iParId)
    local oPlayer = self:GetOwner()
    local oPartner = self:GetPartner(iParId)
    if oPartner and m.success then
        local bFlag = true
        local mCostItem = oPartner:GetAwakeCost()
        for _, mCost in pairs(mCostItem) do
            local iHave = oPlayer.m_oItemCtrl:GetItemAmount(mCost.sid)
            if iHave < mCost.amount then
                bFlag = false
                break
            end
        end
        if bFlag then
            for _, mCost in pairs(mCostItem) do
                oPlayer.m_oItemCtrl:RemoveItemList({{mCost.sid,mCost.amount}},m.reason)
            end
            oPartner:Awake(oPlayer)
        end
        oPlayer:DoResultMoney(bFlag, m)
    end
end

function CPartnerCtrl:ValidExchangeChip(oPlayer, iChipSid, iAmount)
    local oAssistMgr = global.oAssistMgr
    local mData = loaditem.GetItemData(iChipSid)
    if not mData then
        return false
    end
    if iAmount <= 0 then
        return false
    end
    local oParChip = loaditem.GetItem(tostring(iChipSid))
    if oParChip:ItemType() ~= "partnerchip" then
        return false
    end
    local iParType = oParChip:PartnerType()
    local oPartner = self:GetPartnerByType(iParType)
    if not oPartner then
        oAssistMgr:BroadCastNotify(self:GetPid(), nil, "伙伴不存在")
        return false
    end
    if not oPartner:IsLimitStar() then
        oAssistMgr:BroadCastNotify(self:GetPid(), nil, "伙伴星级未满")
        return false
    end
    local mRare = oPartner:GetRareData()
    local iNeedChip = mRare.exchange_chip * iAmount
    local iHaveChip = oPlayer:GetItemAmount(iChipSid)
    if iNeedChip > iHaveChip then
        oAssistMgr:BroadCastNotify(self:GetPid(), nil, "碎片数量不足")
        return false
    end
    local iTargetSid = partnerdefine.MASTER_CHIP
    if not oPlayer:ValidGive({{iTargetSid, iAmount}}, {cancel_tip = 1}) then
        oAssistMgr:BroadCastNotify(self:GetPid(), nil, "伙伴碎片已达上限")
        return false
    end
    return true
end

function CPartnerCtrl:ExchangeChip(oPlayer, iChipSid, iAmount)
    local oParChip = loaditem.GetItem(tostring(iChipSid))
    local iParType = oParChip:PartnerType()
    local oPartner = self:GetPartnerByType(iParType)
    local mRare = oPartner:GetRareData()
    local iCostCoin = mRare.exchange_coin
    local sReason = "碎片交换消耗"
    local mData = {}
    mData.pid = self:GetPid()
    mData.coin = iCostCoin * iAmount
    mData.args = {cancel_tip=1}
    mData.reason = sReason
    if mData.coin <= 0 then
        record.warning("ExchangeChip, pid:%s,coin:%s", self:GetPid(), mData.coin)
        return
    end
    interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
        local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
        if oPlayer then
            oPlayer.m_oPartnerCtrl:DoExchangeChip(m, iChipSid, iAmount)
        end
    end)
end

function CPartnerCtrl:DoExchangeChip(m, iChipSid, iAmount)
    local oPlayer = self:GetOwner()
    local bFlag = false
    if m.success then
        if self:ValidExchangeChip(oPlayer, iChipSid, iAmount) then
            local oParChip = loaditem.GetItem(tostring(iChipSid))
            local iParType = oParChip:PartnerType()
            local oPartner = self:GetPartnerByType(iParType)
            local mRare = oPartner:GetRareData()
            local iNeedChip = mRare.exchange_chip * iAmount
            local mArgs = {
                cancel_tip = 1,
                cancel_show = 1,
                cancel_channel = 1,
            }
            if oPlayer:RemoveItemAmount(iChipSid, iNeedChip, m.reason, mArgs) then
                bFlag = true
                local iTargetSid = partnerdefine.MASTER_CHIP
                oPlayer:GiveItem({{iTargetSid, iAmount}}, m.reason, mArgs)
                oPlayer:Send("GS2CExchangePartnerChip", {
                    chip_sid = iChipSid,
                    amount = iAmount,
                    target_sid = iTargetSid,
                    })
            end
        end
    end
    oPlayer:DoResultMoney(bFlag, m)
end

function CPartnerCtrl:AddPartnerSkill(iParId)
    local oAssistMgr = global.oAssistMgr
    local oPartner = self:GetPartner(iParId)
    local oPlayer = self:GetOwner()
    if not oPartner then
        return
    end
    if oPartner:IsAllSkillMax() then
        return
    end
    local mCost = oPartner:SkillCost()
    local sReason = "升级伙伴技能"
    local iSid, iAmount = mCost.sid, mCost.amount
    if oPlayer.m_oItemCtrl:RemoveItemAmount(iSid,iAmount,sReason) then
        oPartner:UpGradeSkill(1)
        oAssistMgr:PushAchieve(self:GetPid(), "伙伴升级技能", {value = 1})
    else
        local mData = loaditem.GetItemData(iSid)
        oAssistMgr:BroadCastNotify(self:GetPid(), nil, string.format("%s不足", mData.name))
    end
end

function CPartnerCtrl:OpenPartnerUI(iParId, iOpen, iMD5)
    local oPartner = self:GetPartner(iParId)
    local oPlayer = self:GetOwner()
    if oPartner and oPlayer then
        local mNet = {}
        mNet["parid"] = iParId
        mNet["type"] = iOpen
        mNet["applys"] = oPartner:PackUpgradeAttr()
        if iOpen ~= 1 then
            mNet["applys"] = oPartner:PackUpstarAttr()
        end
        oPlayer:Send("GS2COpenPartnerUI", mNet)
    end
end

function CPartnerCtrl:UpGradePartner(iParId, iUpgrade)
    local oPartner = self:GetPartner(iParId)
    local oPlayer = self:GetOwner()
    if not oPartner or not oPlayer then
        return
    end
    local oAssistMgr = global.oAssistMgr
    local iPid =self:GetPid()
    if oPartner:IsGradeLimit({cancel_tip = 1}) then
        oAssistMgr:BroadCastNotify(iPid,nil ,"伙伴无法超过主角等级5级",{})
        return
    end
    local iItemSid = partnerdefine.UPGRADE_ITEM
    local iHaveItem = oPlayer.m_oItemCtrl:GetItemAmount(iItemSid)
    if not oPlayer:ValidRemoveItemAmount(iItemSid, 1) then
        oAssistMgr:BroadCastNotify(iPid,nil ,"你的伙伴经验道具不足",{})
        return
    end
    local iNeedExp = oPartner:NeedExp(iUpgrade)
    if iNeedExp > 0 then
        local iNeedItem = self:ParUpgradeNeedItem(iNeedExp)
        local iCostItem = math.min(iNeedItem, iHaveItem)
        if iCostItem > 0 then
            local sReason = "伙伴升级消耗"
            local iExp = tonumber(oAssistMgr:QueryGlobalData("partner_item_exp")) or 1000
            oPlayer.m_oItemCtrl:RemoveItemAmount(iItemSid, iCostItem, sReason, {cancel_tip = 1})
            oPartner:RewardExp(iExp * iCostItem, sReason, {show_ui = 1})
            if oPartner:IsGradeLimit({cancel_tip = 1}) then
                local sMsg = "#partner_name等级超过主角等级#O5#n级时，伙伴将不再获得经验"
                oAssistMgr:BroadCastNotify(iPid,nil ,sMsg,{partner_name = oPartner:GetName()})
            end
        end
    end
end

function CPartnerCtrl:ParUpgradeNeedItem(iNeedExp)
    local iNeedItem = 0
    if iNeedExp > 0 then
        local oAssistMgr = global.oAssistMgr
        local iExp = tonumber(oAssistMgr:QueryGlobalData("partner_item_exp")) or 1000
        iNeedItem = iNeedExp // iExp
        if (iNeedExp % iExp) ~= 0 then
            iNeedItem = iNeedItem + 1
        end
    end
    return iNeedItem
end

function CPartnerCtrl:SaveEquipPlan(iParId, iPlanId, lEquip)
    local iPid = self:GetPid()
    local oPlayer = self:GetOwner()
    local oAssistMgr = global.oAssistMgr
    local oPartner = self:GetPartner(iParId)
    if not oPartner then
        return
    end
    local mOldPlan = oPartner:GetEquipPlan(iPlanId)
    if not mOldPlan then
        oAssistMgr:Notify(iPid, "方案不存在")
        return
    end
    local iType = CONTAINER_TYPE.PARTNER_EQUIP
    local mNewPlan = {}
    for _, iEquip in ipairs(lEquip) do
        local o = oPlayer:HasItem(iEquip)
        if not o then
            oAssistMgr:Notify(iPid, "符文不存在")
            return
        end
        if o:Type() ~= iType then
            oAssistMgr:Notify(iPid, string.format("%s不是伙伴符文", o:Name()))
            return
        end
        if o:EquipType() == 60 then
            oAssistMgr:Notify(iPid, "经验符文不可穿戴")
            return
        end
        mNewPlan[o:EquipPos()] = o
    end
    local bRefresh = true
    oPartner:SaveEquipPlan(oPlayer, iPlanId, mNewPlan, bRefresh)
end

function CPartnerCtrl:UsePartnerEquipPlan(iParId, iPlanId, lEquip)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local oPlayer = self:GetOwner()
    local oPartner = self:GetPartner(iParId)
    if not oPartner then
        return
    end
    if iPlanId > 0 then
        local mPlan = oPartner:GetEquipPlan(iPlanId)
        if not mPlan then
            oAssistMgr:Notify(iPid, "方案不存在")
            return
        end
        local iCurId = oPartner:GetEquipPlanID()
        if iCurId == iPlanId then
            oAssistMgr:Notify(iPid, "已启用该方案")
            return
        end
        oPartner:OneKeyPutOnEquip(mPlan, iPlanId, true)
    else
        local mPlan = {}
        local iType = CONTAINER_TYPE.PARTNER_EQUIP
        for _, iEquipId in pairs(lEquip) do
            local o = oPlayer:HasItem(iEquipId)
            if not o then
                oAssistMgr:Notify(iPid, "伙伴符文不存在")
                return
            end
            if o:Type() ~= iType then
                oAssistMgr:Notify(iPid, string.format("%s不是伙伴符文", oItem:Name()))
                return
            end
            mPlan[o:EquipPos()] = o
        end
        oPartner:OneKeyPutOnEquip(mPlan, iPlanId, true)
    end
end

function CPartnerCtrl:GetPataPartnerList()
    local mFightPartner = self:GetFightPartner()
    local partnerlist = {}
    local idlist = {}
    for iPos=1,4 do
        local oPartner = mFightPartner[iPos]
        if oPartner then
            local iRestHp = oPartner.m_oToday:Query("patahp",oPartner:GetAttr("maxhp"))
            if iRestHp > 0 then
                table.insert(partnerlist,oPartner:PackRemoteInfo())
                table.insert(idlist,oPartner:ID())
            end
        end
    end
    local iCnt = 4 - #partnerlist
    local infolist = {}
    if iCnt > 0 then
        local mList = self:GetList()
        for id,oPartner in pairs(mList) do
            local iType = oPartner:PartnerType()
            local iRestHp = oPartner.m_oToday:Query("patahp",oPartner:GetAttr("maxhp"))
            if not table_in_list(idlist,id) and iRestHp > 0 then
                table.insert(infolist,{id,oPartner:GetPower()})
            end
        end
        table.sort(infolist, function (a,b)
            return a[2] > b[2]
        end)
        for _,info in pairs(infolist) do
            local oPartner = self:GetPartner(info[1])
            if oPartner then
                table.insert(partnerlist,oPartner:PackRemoteInfo())
                iCnt = iCnt - 1
                if iCnt <= 0 then
                    break
                end
            end
        end
    end
    return partnerlist
end

function CPartnerCtrl:RecordPataPartnerHP(iParId, iHP)
    local oPartner = self:GetPartner(iParId)
    if oPartner then
        oPartner.m_oToday:Set("patahp",iHP)
        oPartner:ClientPropChange(self:GetOwner(), {["patahp"]=true})
    end
end

function CPartnerCtrl:ResetPataPartnerHP(oPlayer)
    local iPid = oPlayer:GetPid()
    local mList = self:GetList()
    for _,oPartner in pairs(self.m_mList) do
        if oPartner.m_oToday:Query("patahp") then
            oPartner.m_oToday:Delete("patahp")
            oPartner:ClientPropChange(oPlayer,{["patahp"]=true})
        end
    end
    local oAssistMgr = global.oAssistMgr
    oAssistMgr:Notify(iPid, "重置成功")
    record.user("pata", "reset", {pid=iPid})
end

function CPartnerCtrl:GetDayLimitFightPartner(sKey,iFix)
    local mFightPartner = self:GetFightPartner()
    local partnerlist = {}
    local idlist = {}
    for iPos=1,4 do
        local oPartner = mFightPartner[iPos]
        if oPartner then
            if not oPartner.m_oToday:Query(sKey) then
                table.insert(partnerlist,oPartner:PackRemoteInfo())
                table.insert(idlist,oPartner:ID())
            end
        end
    end
    if iFix == 0 then
        return partnerlist
    end

    local iCnt = 4 - #partnerlist
    local infolist = {}
    if iCnt > 0 then
        local mList = self:GetList()
        for id,oPartner in pairs(mList) do
            if not oPartner.m_oToday:Query(sKey) then
                if not table_in_list(idlist,id) then
                    table.insert(infolist,{id,oPartner:GetPower()})
                end
            end
        end
        table.sort(infolist, function (a,b)
            return a[2] > b[2]
        end)
        for _,info in pairs(infolist) do
            local oPartner = self:GetPartner(info[1])
            if oPartner then
                table.insert(partnerlist,oPartner:PackRemoteInfo())
                iCnt = iCnt - 1
                if iCnt <= 0 then
                    break
                end
            end
        end
    end
    return partnerlist

end


function CPartnerCtrl:RecordDayLimitPartner(partnerlist,sKey)
    for _,iParId in ipairs(partnerlist) do
        local oPartner = self:GetPartner(iParId)
        if oPartner then
            oPartner.m_oToday:Set(sKey,1)
        end
    end
end

function CPartnerCtrl:SetAutoSkill(oPlayer, mAutoSkill)
    mAutoSkill = mAutoSkill or {}
    for iParId, iAutoSkill in pairs(mAutoSkill) do
        local oPartner = self:GetPartner(iParId)
        if oPartner then
            oPartner:SetAutoSkill(iAutoSkill)
        end
    end
end

function CPartnerCtrl:PreCheck(oPlayer, bReEnter)
    local iPid = oPlayer:GetPid()
    if not bReEnter then
        local oContainer = oPlayer.m_oItemCtrl:GetContainer(CONTAINER_TYPE.PARTNER_EQUIP)
        if oContainer then
            local mItemList = oContainer:ItemList()
            for iItemId, oItem in pairs(mItemList) do
                oItem:PreCheckPartner(oPlayer)
            end
        end
        local oContainer = oPlayer.m_oItemCtrl:GetContainer(CONTAINER_TYPE.PARTNER_SOUL)
        if oContainer then
            local mItemList = oContainer:ItemList()
            for iItemId, oItem in pairs(mItemList) do
                oItem:PreCheckPartner(oPlayer)
            end
        end
        local mFight = {}
        for iParId, oPartner in pairs(self.m_mList) do
            local iFightPos = oPartner:GetFight()
            if iFightPos > 0 then
                if mFight[iFightPos] then
                    record.error("load partner error: repeated fight ,%s,%s,%s",iPid, mFight[iFightPos], oPartner.m_iID)
                end
                mFight[iFightPos] = oPartner:ID()
            end
            self:CheckRankPPower(oPartner)
        end
        self:SetData("fight_partner", mFight)
    end
    self:Schedule()
    self:PartnerAmountChange()
    local mFight = self:GetData("fight_partner", {})
    for iPos = 1, 4 do
        local iParId = mFight[iPos] or 0
        local oPartner = self:GetPartner(iParId)
        local mData = oPartner and oPartner:PackRemoteInfo()
        self:RemoteFightPartner(iPos, iParId, mData)
    end
end

function CPartnerCtrl:OnLogin(oPlayer, bReEnter)
    self:PreCheck(oPlayer, bReEnter)
    local mData = {}
    local iPage = 200
    local idx = 1
    local lPartnerData = {}
    for iParId,oPartner in pairs(self.m_mList) do
        table.insert(lPartnerData, oPartner:PackNetInfo())
        if idx % iPage == 0 then
            self:GS2CLoginPartnerList(oPlayer, lPartnerData)
            lPartnerData = {}
        end
        idx = idx + 1
    end
    if next(lPartnerData) then
        self:GS2CLoginPartnerList(oPlayer, lPartnerData)
    end

    local mNet = {}
    local mFight = {}
    local mFightData = self:GetData("fight_partner", {})
    for iPos,iParId in pairs(mFightData) do
        table.insert(mFight,{pos = iPos,parid = iParId})
    end
    mData["fight_info"] = mFight

    local lOwnedPartner = {}
    for iPartnerType, _ in pairs(self.m_mOwnedPartner) do
        table.insert(lOwnedPartner, iPartnerType)
    end
    mData["owned_partner_list"] = lOwnedPartner

    local lOwnedEquip = {}
    for iEquipSid, _ in pairs(self.m_mOwnedEquip) do
        table.insert(lOwnedEquip, iEquipSid)
    end
    mData["owned_equip_list"] = lOwnedEquip

    oPlayer:Send("GS2CLoginPartner",mData)
    self:GS2CPartnerPicturePosList(oPlayer,true)
end

function CPartnerCtrl:BKPartnerData()
    local mData = {}
    for _,oPartner in pairs(self.m_mList) do
        if oPartner:GetGrade() > 1 then
            table.insert(mData,oPartner:BackEndData())
        end
        if #mData > 100 then
            break
        end
    end
    return mData
end

function CPartnerCtrl:OnLogout(oPlayer)
    self:AllSendBackendLog()
end

function CPartnerCtrl:OnDisconnected(oPlayer)
end

function CPartnerCtrl:GS2CRefreshFightPartner(iPos, iParId)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(self:GetInfo("pid"))
    if oPlayer then
        local mNet = {
            pos = iPos,
            parid = iParId
        }
        oPlayer:Send("GS2CRefreshFightPartner", {
            fight_info = mNet
            })
    end
end

function CPartnerCtrl:GS2CAddPartner(oPartner)
    local oAssistMgr = global.oAssistMgr
    local mData = oPartner:PackNetInfo()
    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer:Send("GS2CAddPartner",{
            partner_info = mData
        })
    end
end

function CPartnerCtrl:GS2CDelPartner(lRemove)
    lRemove = lRemove or {}
    if #lRemove <= 0 then
        return
    end
    local oAssistMgr = global.oAssistMgr

    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer:Send("GS2CDelPartner",{
            del_list = lRemove
        })
    end
end

function CPartnerCtrl:GS2CRefreshPartnerChip(iPartnerChipType)
    local oAssistMgr = global.oAssistMgr

    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local mChip = self:GetPartnerChip(iPartnerChipType)
        local mNet = {
            partner_chip_type = iPartnerChipType,
            latest_add_time = mChip.latest_add_time,
            chip_amount = mChip.chip_amount,
        }
        oPlayer:Send("GS2CRefreshPartnerChip", {
            partner_chip = mNet,
            })
    end
end

function CPartnerCtrl:GS2CRefreshAwakeItem(iItemType)
    local oAssistMgr = global.oAssistMgr

    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local iHaveAmount = self.m_mAwakeItem[iItemType] or 0
        local mItem = {
            sid = iItemType,
            amount = iHaveAmount,
        }
        oPlayer:Send("GS2CRefreshAwakeItem", {
            awake_item = mItem,
            })
    end
end

function CPartnerCtrl:GS2CLoginPartnerList(oPlayer, lPartnerData)
    if oPlayer then
        oPlayer:Send("GS2CLoginPartnerList", {
            partner_list = lPartnerData,
            })
    end
end

function CPartnerCtrl:GS2CAddPartnerList(lPartnerId)
    local oPlayer = self:GetOwner()
    local mNet = {}
    if oPlayer then
        for i, iParId in ipairs(lPartnerId) do
            local o = self:GetPartner(iParId)
            if o then
                table.insert(mNet, o:PackNetInfo())
            end
            if (i % partnerdefine.PARTNER_LIST_PAGE) == 0 then
                oPlayer:Send("GS2CAddPartnerList", {partner_list = mNet})
                mNet = {}
            end
        end
        if next(mNet) then
            oPlayer:Send("GS2CAddPartnerList", {partner_list = mNet})
        end
    end
end

function CPartnerCtrl:GetInviteInfoList(iLimit)
    iLimit = iLimit or 5
    local partinfo = {}
    for _, oPartner in pairs(self.m_mList) do
        local idx = 1
        for _,info in pairs(partinfo) do
            if oPartner:GetPower() > info["power"] then
                break
            end
            idx = idx + 1
        end
        if idx <= iLimit then
            if idx == iLimit then
                table.remove(partinfo,iLimit)
            end
            table.insert(partinfo,idx,{
                    parid = oPartner:ID(),
                    star = oPartner:GetStar(),
                    rare = oPartner:Rare(),
                    grade = oPartner:GetGrade(),
                    power = oPartner:GetPower(),
                    name = oPartner:GetName(),
                    modeid= oPartner:PartnerType(),
            })
        end
    end
    return partinfo
end

function CPartnerCtrl:GetPartnerCnt()
    return table_count(self.m_mList)
end

function CPartnerCtrl:GetPid()
    return self:GetInfo("pid")
end

function CPartnerCtrl:RemoteFightPartner(iPos, iParId, mData)
    interactive.Send(".world", "partner", "RemoteFightPartner", {
        pid = self:GetPid(),
        pos = iPos,
        parid = iParId,
        data = mData,
        })
end

function CPartnerCtrl:PartnerAmountChange()
    local iHaveAmount = table_count(self.m_mList)
    interactive.Send(".world", "partner", "UpdatePartnerAmount", {
        pid = self:GetPid(),
        amount = iHaveAmount,
        })
end

function CPartnerCtrl:PackRemoteInfo()
    local lPartner = {}
    for iParId, oPartner in pairs(self.m_mList) do
        table.insert(lPartner, oPartner:PackRemoteInfo())
    end
    return lPartner
end

function CPartnerCtrl:SetShowPartner(parlist)
    if #parlist > 3 then
        return
    end
    local mDuplicate = {}
    for _, iParId in ipairs(parlist) do
        if mDuplicate[iParId] then
            return
        end
        mDuplicate[iParId] = 1
    end

    self:Dirty()
    self.m_SendShowPartnerInfo =nil
    local iStatus = PARTNER_STATUS.ON_SHOW

    for _,parid in pairs(self.m_ShowPartner) do
        local oPartner = self:GetPartner(parid)
        if oPartner and oPartner:IsShow() then
            oPartner:SetStatus(iStatus)
        end
    end

    self.m_ShowPartner = {}

    for _,parid in ipairs(parlist) do
        local oPartner = self:GetPartner(parid)
        if oPartner then
            if not oPartner:IsShow() then
                oPartner:SetStatus(iStatus)
            end
            table.insert(self.m_ShowPartner,parid)
        end
    end
end

function CPartnerCtrl:RefreshShowPartner(iRefresh)
    local mShowList = {}
    for _,parid in pairs(self.m_ShowPartner) do
        local oPartner = self:GetPartner(parid)
        if oPartner then
            table.insert(mShowList,oPartner:PackRemoteInfo())
        end
    end

    interactive.Send(".world", "partner", "RefreshShowPartner", {
            pid = self:GetPid(),
            data = mShowList,
            refresh = iRefresh
            })
end

function CPartnerCtrl:GetAllPartnerInfo(m)
    local mPartner = {}
    for iParId, oPartner in pairs(self.m_mList) do
        mPartner[iParId] = oPartner:GetRemoteInfo(m)
    end
    return mPartner
end

function CPartnerCtrl:BackUpTerraWarsInfo()
    local mPartner = {}
    for iParId, oPartner in pairs(self.m_mList) do
        if (not oPartner:OnStatus(gamedefines.PARTNER_STATUS.ON_TERRAWARS)) and oPartner:GetGrade() >= 20 then
            mPartner[iParId] = oPartner:PackRemoteInfo()
        end
        if table_count(mPartner) >=4 then
            break
        end
    end
    return mPartner
end

function CPartnerCtrl:PackTerraWarInfo(mPartner)
    local m = {}
    for _,iParId in pairs(mPartner) do
        local oPartner = self.m_mList[iParId]
        m[iParId] = oPartner:PackRemoteInfo()
    end
    return m
end

function CPartnerCtrl:SyncGuardInfo(mPartner)
    for iParId,iStatus in pairs(mPartner) do
        local oPartner = self.m_mList[iParId]
        if oPartner then
            oPartner:SetStatus(gamedefines.PARTNER_STATUS.ON_TERRAWARS)
        end
    end
end

function CPartnerCtrl:LogPartnerInfo(sType, oPartner, sReason, mArgs)
    local mLog = oPartner:LogInfo()
    mLog.reason = sReason
    record.user("partner", sType, mLog)
end

function CPartnerCtrl:SetEqualArena(iPartList)
    local oAssistMgr = global.oAssistMgr
    local res = require "base.res"
    local iPid = self:GetPid()
    local mData = res["daobiao"]["huodong"]["equalarena"]["partner"]
    for _,iPartner in ipairs(iPartList) do
        local oPartner = self:GetPartner(iPartner)
        if not oPartner or not mData[oPartner:PartnerType()] then
            extend.Array.remove(iPartList,iPartner)
        end

    end

    local iStatus = PARTNER_STATUS.ON_EQUAL_ARENA
    for _,iPartner in ipairs(self.m_EqualArena) do
        local oPartner = self:GetPartner(iPartner)
        if oPartner then
            if oPartner:IsEqualArena() then
                oPartner:SetStatus(iStatus)
            end
        end
    end
    self:Dirty()
    self.m_EqualArena  = {}

    for _,iPartner in ipairs(iPartList) do
        local oPartner = self:GetPartner(iPartner)
        if not oPartner:IsEqualArena() then
            oPartner:SetStatus(iStatus)
        end
    end
    self.m_EqualArena =iPartList
end

function CPartnerCtrl:GetFollowPartner()
    return self:GetPartner(self.m_iFollow)
end

function CPartnerCtrl:SetFollowPartner(iParId, mTitle)
    local oAssistMgr = global.oAssistMgr
    local oPartner = self:GetPartner(iParId)
    if not oPartner then
        return
    end
    self:Dirty()
    local iPid = self:GetPid()
    if (self.m_iFollow == iParId) and oPartner:IsFollow()then
        oPartner:SetStatus(gamedefines.PARTNER_STATUS.ON_FOLLOW)
        self:SyncFollowInfo({})
        oAssistMgr:Notify(iPid, "召回成功，小伙伴已经回到牌组中~")
        return
    end
    local oFollow = self:GetPartner(self.m_iFollow)
    local oldTitles = {}
    if oFollow then
        if oFollow:IsFollow() then
            oFollow:SetStatus(gamedefines.PARTNER_STATUS.ON_FOLLOW)
        end
        if oFollow:PartnerType() == oPartner:PartnerType() then
            oldTitles = oFollow:GetTitleList()
            oFollow:SetTitle({})
        end
    end
    self.m_iFollow = iParId
    if not oPartner:IsFollow() then
        oPartner:SetStatus(gamedefines.PARTNER_STATUS.ON_FOLLOW)
    end
    if next(mTitle) then
        oPartner:UseTitle(mTitle)
    elseif next(oldTitles) then
        oPartner:SetTitle(oldTitles)
    end
    oAssistMgr:Notify(iPid, "设置成功，小伙伴会一直陪伴着你~")
    self:SyncFollowInfo(oPartner:PackFollowInfo())
end

function CPartnerCtrl:SyncFollowInfo(mData)
    interactive.Send(".world", "partner", "SyncFollowInfo", {
        pid = self:GetPid(),
        data = mData,
        })
end


function CPartnerCtrl:SetPartnerTravelPos(lPos)
    self:Dirty()
    local mPos = {}
    for _, m in pairs(lPos) do
        local iPos = m.pos
        local iParId = self.m_mTravel[iPos]
        local oPartner = self:GetPartner(iParId)
        if oPartner and oPartner:IsTravel() then
            oPartner:SetStatus(PARTNER_STATUS.ON_TRAVEL)
        end
        self.m_mTravel[iPos] = nil
    end
    local lRemote = {}
    for _, m in pairs(lPos) do
        local iParId = m.parid
        local mData = {}
        mData["pos"] = m.pos
        mData["parid"] = iParId
        if iParId > 0 then
            self.m_mTravel[m.pos] = iParId
            local oPartner = self:GetPartner(iParId)
            if not oPartner:IsTravel() then
                oPartner:SetStatus(PARTNER_STATUS.ON_TRAVEL)
            end
            mData["data"] = {
                parid = iParId,
                par_name = oPartner:GetName(),
                par_grade = oPartner:GetGrade(),
                par_model = oPartner:GetModelInfo(),
                par_star = oPartner:GetStar(),
                par_awake = oPartner:GetAwake(),
            }
        end
        table.insert(lRemote, mData)
    end
    self:SyncTravelPartner(lRemote)
end

function CPartnerCtrl:QueryTravelPos(iParId)
    if self.m_iFrdPartner == iParId then
        return 5
    end
    for iPos, id in pairs(self.m_mTravel) do
        if iParId == id then
            return iPos
        end
    end
end

function CPartnerCtrl:IsFrdTravel()
    if self.m_iFrdPartner then
        return true
    end
    return false
end

function CPartnerCtrl:SyncTravelPartner(info)
    interactive.Send(".world", "partner", "SyncTravelPartner", {
        pid = self:GetPid(),
        data = info,
        })
end

function CPartnerCtrl:RemoveMineTravel(iParId)
    if self.m_iFrdPartner == iParId then
        self:Dirty()
        self.m_iFrdPartner = nil
    end
    local oPartner = self:GetPartner(iParId)
    if oPartner:IsFrdTravel() then
        oPartner:SetStatus(PARTNER_STATUS.ON_FRD_TRAVEL)
    end
end

function CPartnerCtrl:CheckSetHouseAttr(mBuff)
    mBuff = mBuff or {}
    local mAttr = mBuff.attr or {}
    local mRatio = mBuff.ratio or {}
    local mHAttr = self.m_mHouseAttr.attr or {}
    local mHRatio = self.m_mHouseAttr.ratio or {}
    for sAttr, iVal in pairs(mAttr) do
        if not mHAttr[sAttr] then
            return true
        end
    end

    for sAttr, iVal in pairs(mHAttr) do
        if not mAttr[sAttr] then
            return true
        end
    end

    for sAttr, iVal in pairs(mRatio) do
        if not mHRatio[sAttr] then
            return true
        end
    end

    for sAttr, iVal in pairs(mHRatio) do
        if not mRatio[sAttr] then
            return true
        end
    end
    return false
end

function CPartnerCtrl:SetHouseAttr(mBuff)
    if not self:CheckSetHouseAttr(mBuff) then
        return
    end
    local mAttr = mBuff.attr or {}
    local mRatio = mBuff.ratio or {}
    self.m_mHouseAttr = mBuff
    local l = self:GetList()
    if next(mAttr) or next(mRatio) then
        for iParId, o in pairs(l) do
            o:ActivePropChange()
        end
    end
    self:SyncAllHouse()
end

function CPartnerCtrl:SyncAllHouse()
    for iParId, oPartner in pairs(self.m_mList) do
        self:SyncCPowerHouse(oPartner)
    end
end

function CPartnerCtrl:SyncCPowerHouse(oPartner)
    if oPartner:IsMerge() then
        return
    end
    local mBuff = self.m_mHouseAttr
    local mAttr = mBuff.attr or {}
    local mRatio = mBuff.ratio or {}
    for sAttr,iVal in pairs(mAttr) do
        oPartner:ExecuteCPower("SetApply","house",sAttr,iVal)
    end
    for sAttr,iVal in pairs(mRatio) do
        oPartner:ExecuteCPower("SetRatioApply","house",sAttr,iVal)
    end
end

function CPartnerCtrl:GetHouseAttr(sAttr)
    local mAttr = self.m_mHouseAttr.attr or {}
    return mAttr[sAttr] or 0
end

function CPartnerCtrl:GetHouseRatio(sAttr)
    local mRatio = self.m_mHouseAttr.ratio or {}
    return mRatio[sAttr] or 0
end

function CPartnerCtrl:GetRankPPower(iParType)
    return self.m_mRankPPower[iParType]
end

function CPartnerCtrl:UpdateRankPPower(oPartner)
    self:Dirty()
    local iParType = oPartner:PartnerType()
    self.m_mRankPPower[iParType] = oPartner:ID()
end

function CPartnerCtrl:CheckRankPPower(oPartner, bUpdate)
    if not oPartner:IsRank() then
        return
    end
    local iParType = oPartner:PartnerType()
    local iCurMax = self:GetRankPPower(iParType)
    if iCurMax == oPartner:ID() then
        if bUpdate then
            self:SyncRankPPower(oPartner)
        end
    end
    local oCurMax = self:GetPartner(iCurMax)
    if oCurMax then
        if oCurMax:GetPower() < oPartner:GetPower() then
            self:UpdateRankPPower(oPartner)
            if bUpdate then
                self:SyncRankPPower(oPartner)
            end
        end
    else
        self:UpdateRankPPower(oPartner)
        if bUpdate then
            self:SyncRankPPower(oPartner)
        end
    end
end

function CPartnerCtrl:SyncRankPPower(oPartner)
    local mData = {}
    mData.rank_name = "parpower"
    mData.rank_data = oPartner:PackRankInfo()
    mData.arg = {key = oPartner:PartnerType()}
    interactive.Send(".rank", "rank", "PushDataToRank", mData)
end

function CPartnerCtrl:UpdatePowerRank(mRank)
    mRank = mRank or {}
    for iParId, oPartner in pairs(self.m_mList) do
        local iRank = mRank[iParId]
        if iRank then
            oPartner:SetPowerRank(iRank)
        elseif oPartner:GetPowerRank() > 0 then
            oPartner:SetPowerRank(0)
        end
    end
end

function CPartnerCtrl:AddParSkillCount(iType, iAdd)
    assert(iAdd > 0)
    self:Dirty()
    local iHave = self.m_mParSkillGuide[iType] or 0
    self.m_mParSkillGuide[iType] = iHave + iAdd
end

function CPartnerCtrl:GetParSkillCount(iType)
    return self.m_mParSkillGuide[iType] or 0
end

function CPartnerCtrl:RecordParEquipStar(iSetType, iStar, iCount)
    local mStar = self.m_mParEquipStar[iSetType] or {}
    local iCnt = mStar[iStar] or 0
    if iCnt >= iCount then
        return
    end
    self:Dirty()
    mStar[iStar] = iCount
    self.m_mParEquipStar[iSetType] = mStar
    self:CheckParEquipStarAchieve(iSetType, iStar, iCount)
end

function CPartnerCtrl:OpenParSoul(oPlayer)
    for iParId, oPartner in pairs(self.m_mList) do
        oPartner:SetSoulType(oPartner:GetDefaultSoulType())
        oPartner:PropChange("soul_type")
    end
    record.user("partner", "open_parsoul", {
        pid = oPlayer:GetPid(),
        })
end

function CPartnerCtrl:UseParSoulType(oPlayer, iParId, iSoulType, lSoulPos, mArgs)
    mArgs = mArgs or {}
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local oPartner = self:GetPartner(iParId)
    if not oPartner then
        return
    end
    if iSoulType == 0 then
        oPartner:ResetSoulType(true)
    else
        local mSoulType = itemdefines.GetParSoulTypeData(iSoulType)
        if not mSoulType then
            return
        end
        if not itemdefines.ValidParSoul(oPlayer, iSoulType, lSoulPos) then
            return
        end
        if oPartner:GetSoulType() ~= iSoulType then
            oPartner:ResetSoulType()
            oPartner:SetSoulType(iSoulType)
        end
        if next(lSoulPos) then
            local iHistory = self:HistoryMaxSoulAmount()
            for _, m in ipairs(lSoulPos) do
                local oItem = oPlayer:HasItem(m.itemid)
                local o = oPlayer.m_oPartnerCtrl:GetPartner(oItem:GetWield())
                if o then
                    o:UnWieldSoulById(m.itemid)
                    o:ActivePropChange("soul_type", "souls")
                end
                oPartner:UnWieldSoul(m.pos, true)
                oItem:UseSoul(oPlayer, oPartner, m.pos)
            end
            local iNew = self:CountWieldSoul()
            if iNew > iHistory then
                oAssistMgr:PushAchieve(iPid, "穿戴御灵数量", {value = iNew - iHistory})
                self:UpdateWieldSoulAmount(iNew)
            end
            oAssistMgr:BroadCastNotify(iPid, nil, mArgs.tips or "快速装备完毕")
        end
        oPartner:ActivePropChange("soul_type", "souls")
    end
end

function CPartnerCtrl:CheckParEquipStarAchieve(iSetType, iStar, iCount)
    if iStar > 4 and iCount > 3 then
        -- global.oAssistMgr:PushAchieve(self:GetPid(), "激活5星符文4件套", {value = 1})
    end
end

function CPartnerCtrl:ShareUpdateAmount()
    self.m_oShareMgr:ShareUpdateAmount()
end

function CPartnerCtrl:AllSendBackendLog()
    self:SendBackendLog(self:GetInfo("pid"),"player","partner",self:BKPartnerData())
end

function CPartnerCtrl:SendBackendLog(iPid, sTableName, sType, mData)
    sTableName = sTableName or "player"
    sType = sType or sTableName
    mData = mData or {}

    local mLog = {}

    mLog["pid"] = iPid
    mLog["tablename"] = sTableName
    mLog["type"] = sType
    mLog["data"] = mData or {}

    local sLog = extend.Table.serialize(mLog)

    router.Send("bs", ".backend", "common", "SaveBackendLog", sLog)
end

----------------------------------testop-------------------------------------------------
function CPartnerCtrl:TestCmd(oPlayer, sCmd, m, sReason)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    -- local mArgs = {...}
    if sCmd == "update_fight_partner" then
        local mFight = self:GetData("fight_partner", {})
        for iPos, iParId in pairs(mFight) do
            local oPartner = self:GetPartner(iParId)
            if oPartner then
                self:RemoteFightPartner(iPos, oPartner:ID(), oPartner:PackRemoteInfo())
            end
        end
    elseif sCmd == "addpartner" then
        local res = require "base.res"
        for _, mInfo in pairs(m or {}) do
            local iPartnerType = table.unpack(mInfo)
            local mData = res["daobiao"]["partner"]["partner_info"][iPartnerType]
            if not mData then
                oAssistMgr:Notify(iPid, string.format("伙伴id：%s不存在", iPartnerType))
                return
            end
        end
        if self:ValidGive(m) then
            self:GivePartner(m, sReason, {cancel_tip = 1})
        end
    elseif sCmd == "addexp" then
        local iParId, iExp = table.unpack(m)
        local oPartner = self:GetPartner(iParId)
        if oPartner then
            if not oPartner:IsGradeLimit() then
                oPartner:RewardExp(iExp, sReason)
            end
        else
            oAssistMgr:Notify(iPid," 伙伴不存在")
        end
    elseif sCmd == "addpartnerstar" then
        local iParId, iVal = table.unpack(m)
        local oPartner = self:GetPartner(iParId)
        if oPartner then
            if oPartner:IsLimitStar() then
                oAssistMgr:Notify(iPid, string.format("id:%s 的伙伴已达星级上限", iPartner))
                return
            end
            oPartner:IncreaseStar(iVal)
        else
            oAssistMgr:Notify(iPid, string.format("伙伴id：%s不存在", iPartner))
        end
    elseif sCmd == "awakepartner" then
        local iParId = table.unpack(m)
        local oPartner = self:GetPartner(iParId)
        if oPartner then
            if oPartner:ValidAwake() then
                oPartner:Awake(self:GetOwner())
            end
        else
            oAssistMgr:Notify(iPid, string.format("伙伴id：%s不存在", iParId))
        end
    elseif sCmd == "clearpartner" then
        local lPartner = self:GetList()
        local lRemove = {}
        local mArgs = {cancel_tip = 1}
        for iParId, oPartner in pairs(lPartner) do
            if oPartner:ValidRemove(mArgs) then
                table.insert(lRemove, iParId)
            end
        end
        if next(lRemove) then
            self:RemovePartnerList(lRemove, sReason)
        end
    elseif sCmd == "removepartner" then
        local iParId = table.unpack(m)
        local oPartner = self:GetPartner(iParId)
        if oPartner and oPartner:GetFight() == 0 then
            self:RemovePartner(oPartner, true, sReason)
        end
    elseif sCmd == "cleartodaydata" then
        for iParId, oPartner in pairs(self.m_mList) do
            oPartner.m_oToday:ClearData()
            oPartner:PropChange("patahp")
        end
        self.m_bTop10Dirty = true
    elseif sCmd == "allpartner" then
        local mData = res["daobiao"]["partner"]["partner_info"]
        local lPartnerId = {}
        for iPartnerType, m in pairs(mData) do
            if m.usable == 1 then
                table.insert(lPartnerId, {iPartnerType, 1})
            end
        end
        if next(lPartnerId) then
            if self:ValidGive(lPartnerId) then
                self:GivePartner(lPartnerId, sReason, {cancel_tip = 1})
            else
                oAssistMgr:Notify(iPid,"超出上限,请先清理伙伴")
            end
        end
    elseif sCmd == "setpartnerattr" then
        local iPartner, mAttr = table.unpack(m)
        local oPartner = self:GetPartner(iPartner)
        if not oPartner then
            oAssistMgr:Notify(iPid,"伙伴不存在")
            return
        end
        oPartner:SetData("test_attr", mAttr)
        oPartner:ActivePropChange()
    elseif sCmd == "countpartner" then
        local iCount = table_count(self.m_mList)
        oAssistMgr:Notify(iPid, string.format("总伙伴数量：%s", iCount))
    elseif sCmd == "testpower" then
        local measure = require "measure"
        local iParId = m
        local oPartner = self:GetPartner(iParId)
        if oPartner then
            local ti = measure.timestamp()
            local v
            for iNo=1,3000 do
                v = oPartner:GetPower()
            end
            print ("-----power----",v,measure.timestamp()-ti)
        end
    elseif sCmd == "testcpower" then
        local measure = require "measure"
        local iParId = m
        local oPartner = self:GetPartner(iParId)
        if oPartner then
            local sType = "partner"..oPartner:PartnerType()
            local ti = measure.timestamp()
            local v
            for iNo=1,3000 do
                v = oPartner.m_cPower:GetPower(sType)
            end
            print ("-----cpower----",v,measure.timestamp()-ti)
        end
    elseif sCmd == "fullpartner" then
        local res = require "base.res"
        local mPartner = res["daobiao"]["partner"]["partner_info"]
        local lGive = {}
        for iParType, _ in pairs(mPartner) do
            local o = self:GetPartnerByType(iParType)
            if not o then
                table.insert(lGive, {iParType, 1})
            end
        end
        if #lGive > 0 then
            self:GivePartner(lGive, "gm_fullpartner", {cancel_show = 1, cancel_tip = 1})
            oAssistMgr:Notify(iPid, string.format("获得伙伴数量:%s", #lGive))
        end
    end
end
-----------------------------------------testop end--------------------------------------
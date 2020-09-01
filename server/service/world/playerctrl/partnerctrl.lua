local global = require "global"
local extend = require "base.extend"
local res = require "base.res"
local record = require "public.record"
local interactive = require "base.interactive"
local router = require "base.router"

local datactrl = import(lualib_path("public.datactrl"))
local partnerdefine = import(service_path("partner/partnerdefine"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item.loaditem"))
local itemdefines = import(service_path("item/itemdefines"))
local partnershare = import(service_path("partner/parsharemgr"))

local AWAKE_TYPE = gamedefines.PARTNER_AWAKE_TYPE

local max = math.max
local min = math.min


function NewPartner(...)
    local o = CPartner:New(...)
    return o
end

CPartnerCtrl = {}
CPartnerCtrl.__index = CPartnerCtrl
inherit(CPartnerCtrl, datactrl.CDataCtrl)

function CPartnerCtrl:New(iPid)
    local o = super(CPartnerCtrl).New(self, {pid = iPid})
    o.m_iRemoteAddr = nil
    o.m_mFightPartners = {}
    o.m_iHaveAmount = 0
    o.m_mItem = {}
    o.m_oShareMgr =partnershare.NewPartnerShare(iPid)
    o:ConfirmRemote()
    return o
end

function CPartnerCtrl:Release()
    for iPos, oPartner in pairs(self.m_mFightPartners) do
        baseobj_delay_release(oPartner)
    end
    self.m_iRemoteAddr = nil
    self.m_mFightPartners = nil
    self.m_oShareMgr:Release()
    self.m_oShareMgr = nil
    super(CPartnerCtrl).Release(self)
end

function CPartnerCtrl:InitShareObj(oShareCopy)
    self.m_oShareMgr:InitShareObj(oShareCopy)
end

function CPartnerCtrl:Load(mData)
    mData = mData or {}
    local iPid = self:GetPid()
    for _, data in pairs(mData.fight_partner or {}) do
        local oPartner = NewPartner(iPid, data)
        local iPos = oPartner:GetFightPos()
        self.m_mFightPartners[iPos] = oPartner
    end
    self:SetData("equalarena",mData.equalarena or {})
end

function CPartnerCtrl:Save()
    local mData = {}
    local lFight = {}
    for iPos, oPartner in pairs(self.m_mFightPartners) do
        table.insert(lFight, oPartner:Save())
    end
    mData.fight_partner = lFight
    mData.equalarena = self:GetData("equalarena",{})
    return mData
end

function CPartnerCtrl:GetPartnerByType(iPartype)
    return self.m_oShareMgr:GetPartner(iPartype)
end

function CPartnerCtrl:GetList()
    return {}
end

--list:{sid, amount}
function CPartnerCtrl:ValidGive(list, mArgs)
    local oNotifyMgr = global.oNotifyMgr

    list = list or {}
    mArgs = mArgs or {}

    local iNeedSpace = 0
    local iPid = self:GetPid()
    for _, mData in pairs(list) do
        local iPartnerType, iAmount = table.unpack(mData)
        assert(iAmount > 0, string.format("partner err: %s,%s,%s",iPid, iPartnerType, iAmount))
        iNeedSpace = iNeedSpace + iAmount
    end

    local bResult = true
    if  self:EmptyPartnerSpace() < iNeedSpace then
        if not mArgs.cancel_tip then
            local sTip = "伙伴背包已满"
            oNotifyMgr:Notify(iPid, sTip)
        end
        bResult = false
    end

    return bResult
end

function CPartnerCtrl:ValidGiveItem(lItemList)
    local mItem = {}
    local iGiveEquip = 0
    for _, m in ipairs(lItemList) do
        local iSid, iAmount = table.unpack(m)
        iSid = tonumber(iSid)
        local oItem = loaditem.GetItem(iSid)
        local iType = oItem:Type()
        if iType == gamedefines.ITEM_CONTAINER.PARTNER_EQUIP  then
            iGiveEquip = iGiveEquip + iAmount
        else
            mItem[iSid] = (mItem[iSid] or 0) + iAmount
        end
    end
    for iSid, iAmount in pairs(mItem) do
        local oItem = loaditem.GetItem(iSid)
        local iHave = self.m_mItem[iSid] or 0
        if iHave + iAmount > oItem:GetMaxAmount() then
            return false
        end
    end
    local iHaveEquip = 0
    for iSid, iHave in pairs(self.m_mItem) do
        local oItem = loaditem.GetItem(iSid)
        if oItem:Type() == gamedefines.ITEM_CONTAINER.PARTNER_EQUIP then
            iHaveEquip = iHaveEquip + iHave
        end
    end
    if iGiveEquip + iHaveEquip > gamedefines.PARTNER_EQUIP_MAX_AMOUNT then
        return false
    end
    return true
end

function CPartnerCtrl:NewPartnerList(iPid, lPartnerInfo)
    lPartnerInfo = lPartnerInfo or {}
    local lPartnerObj = {}
    for _, mArgs in ipairs(lPartnerInfo) do
        table.insert(lPartnerObj, NewPartner(iPid, mArgs))
    end
    return lPartnerObj
end

function CPartnerCtrl:OnFight(iPos, iParId, bRefresh, sReason)
    interactive.Send(self.m_iRemoteAddr,"partner","SetFight", {
        pid = self:GetPid(),
        pos = iPos,
        parid = iParId,
        refresh = bRefresh,
        fight = true,
        reason = sReason,
        })
end

function CPartnerCtrl:OffFight(iPos, iParId, bRefresh, sReason)
    interactive.Send(self.m_iRemoteAddr,"partner", "SetFight", {
        pid = self:GetPid(),
        pos = iPos,
        parid = iParId,
        refresh = bRefresh,
        fight = false,
        reason = sReason,
        })
end

function CPartnerCtrl:SetWarPartner(oWar, lPartnerId)
    interactive.Send(self.m_iRemoteAddr, "partner", "SetWarPartner", {
        pid = self:GetPid(),
        war_id = oWar:GetWarId(),
        war_addr = oWar:GetRemoteAddr(),
        war_type = oWar.m_iWarType,
        partner_list = lPartnerId,
        kf_war_addr = oWar.m_iKFRemoteAddr,
        kf_war_id = oWar.m_iKFRemoteWarId,
        })
end

function CPartnerCtrl:OpenParSoul(oPlayer)
    interactive.Send(self.m_iRemoteAddr,"partner","OpenParSoul", {
        pid = self:GetPid(),
        })
end


--参战伙伴
function CPartnerCtrl:GetFightPartner()
    local mData = {}
    for iPos, oPartner in pairs(self.m_mFightPartners) do
        mData[iPos] = oPartner
    end
    return mData
end

function CPartnerCtrl:GetTeamPartner()
    local mData = {}
    for iPos, oPartner in pairs(self.m_mFightPartners) do
        local mInfo = {}
        mInfo["pos"] = iPos
        mInfo["parid"] = oPartner:ID()
        mInfo["name"] = oPartner:GetName()
        mInfo["grade"] = oPartner:GetGrade()
        mInfo["model_info"] = oPartner:GetModelInfo()
        table.insert(mData,mInfo)
    end
    return mData
end

function CPartnerCtrl:GetMainPartner()
    return self.m_mFightPartners[1]
end

function CPartnerCtrl:RemoteUpdatePartner(iParId, mData)
    self:Dirty()
    local oPartner = self:GetPartner(iParId)
    if oPartner then
        oPartner:UpdateData(mData)
    end
end

function CPartnerCtrl:RemoveFightPartner(iParId)
    local oPartner = self:GetPartner(iParId)
    if oPartner then
        self:Dirty()
        local iPos = oPartner:GetFightPos()
        self.m_mFightPartners[iPos] = nil
        baseobj_safe_release(oPartner)
    end
end

function CPartnerCtrl:AddFightPartner(iPos, oPartner)
    self:Dirty()
    local old = self.m_mFightPartners[iPos]
    if old then
        self.m_mFightPartners[iPos] = nil
        baseobj_safe_release(old)
    end
    self.m_mFightPartners[iPos] = oPartner
end

function CPartnerCtrl:SyncFightPartner(iPos, iParId, mData)
    local old = self.m_mFightPartners[iPos]
    if old then
        self:RemoveFightPartner(old:ID())
    end
    self:RemoveFightPartner(iParId)
    local mArgs = {}
    mArgs["pos"] = iPos
    mArgs["parid"] = iParId
    if mData then
        local oPartner = NewPartner(self:GetPid(), mData)
        self:AddFightPartner(iPos, oPartner)
        mArgs["name"] = oPartner:GetName()
        mArgs["grade"] = oPartner:GetGrade()
        mArgs["model_info"] = oPartner:GetModelInfo()
    end
    local oTeamMgr = global.oTeamMgr
    oTeamMgr:OnMemPartnerInfoChange(self:GetPid(), mArgs)

end

function CPartnerCtrl:GetPid()
    return self:GetInfo("pid")
end

function CPartnerCtrl:GetOwner()
    local iPid = self:GetPid()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CPartnerCtrl:GetRemoteAddr()
    return self.m_iRemoteAddr
end

function CPartnerCtrl:ConfirmRemote()
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local iRemoteAddr = oAssistMgr:SelectRemoteAssist(iPid)
    self.m_iRemoteAddr = iRemoteAddr
end

function CPartnerCtrl:Forward(sCmd, iPid, mData)
    interactive.Send(self.m_iRemoteAddr, "partner", "Forward", {
        pid = iPid,
        cmd = sCmd,
        data = mData,
        })
    return true
end

function CPartnerCtrl:TestCmd(iPid, sCmd, mData, sType)
    interactive.Send(self.m_iRemoteAddr, "partner", "TestCmd", {
        pid = iPid,
        type = sType,
        cmd = sCmd,
        data = mData,
        })
end

function CPartnerCtrl:SetHaveAmount(iAmount)
    self.m_iHaveAmount = iAmount or self.m_iHaveAmount
end

function CPartnerCtrl:UpdateFightPartner(iPos, iParId, mData)
    local oPartner = self.m_mFightPartners[iPos]
    if oPartner and oPartner:ID() == iParId then
        self:Dirty()
        oPartner:Init(mData)
        local iPid = self:GetPid()
        local oTeamMgr = global.oTeamMgr
        oTeamMgr:OnMemPartnerInfoChange(iPid, {
            pos = iPos,
            parid = iParId,
            name = oPartner:GetName(),
            grade = oPartner:GetGrade(),
            model_info = oPartner:GetModelInfo(),
            })
    end
end

function CPartnerCtrl:EmptyPartnerSpace()
    return math.max(gamedefines.PARTNER_MAX_AMOUNT - self.m_iHaveAmount, 0)
end

function CPartnerCtrl:GetPartnerCnt()
    return table_count(self.m_mFightPartners)
end


function CPartnerCtrl:GetRankInfo(iPartype)
    local mPar = self:GetPartnerByType(iPartype)
    local m = {}
    if mPar then
        m = {
            partner_type = iPartype,
            parid = mPar.parid,
            name = mPar.name,
            star = mPar.star,
            grade = mPar.grade,
            power = mPar.power,
            awake = mPar.awake,
        }
    end
    return m
end

function CPartnerCtrl:PackPartnerItemData()
    return self.m_mItem
end

function CPartnerCtrl:GivePartner(lPartner, sReason, mArgs)
    lPartner = lPartner or {}
    local iPid = self:GetPid()
    for _, m in ipairs(lPartner) do
        local iSid, iAmount = table.unpack(m)
        local mShowInfo = {
            id = 0,
            sid = iSid,
            amount = iAmount,
            virtual = 1010,
        }
        global.oUIMgr:AddKeepItem(iPid, mShowInfo)
    end
    interactive.Send(self.m_iRemoteAddr, "partner", "GivePartner", {
        pid = iPid,
        partners = lPartner,
        reason = sReason,
        args = mArgs,
        })
end

function CPartnerCtrl:GetPartner(iParid)
    for iPos,oPartner in pairs(self.m_mFightPartners) do
        if oPartner:ID() == iParid then
            return oPartner
        end
    end
end

function CPartnerCtrl:SetAutoSkill(mAutoSkill)
    interactive.Send(self.m_iRemoteAddr, "partner", "SetAutoSkill", {
        pid = self:GetPid(),
        auto_skill = mAutoSkill or {}
        })
    self:Dirty()
    mAutoSkill = mAutoSkill or {}
    for iParid,iAutoSkill in pairs(mAutoSkill) do
        local oPartner = self:GetPartner(iParid)
        if oPartner then
            oPartner:SetAutoSkill(iAutoSkill)
        end
    end
end

function CPartnerCtrl:AddPartnerListExp(mExp,sReason, mArgs)
    interactive.Send(self.m_iRemoteAddr, "partner", "AddPartnerListExp", {
        pid = self:GetPid(),
        data = mExp or {},
        reason = sReason,
        args = mArgs,
        })
end

function CPartnerCtrl:ValidUpgradePartner(iEffectType)
    return true
end

function CPartnerCtrl:PackFightPartnerInfo()
    local mInfo = {}
    for iPos, oPartner in pairs(self.m_mFightPartners) do
        mInfo[oPartner:ID()] = {
            parid = oPartner:ID(),
            name = oPartner:GetName(),
            effect_type = oPartner:GetData("effect_type"),
            grade = oPartner:GetGrade(),
        }
    end
    return mInfo
end

function CPartnerCtrl:RecordPataPartnerHP(iParId, iRestHp)
    interactive.Send(self.m_iRemoteAddr, "partner", "RecordPataPartnerHP", {
        pid = self:GetPid(),
        parid = iParId,
        hp = iRestHp
        })
end

function CPartnerCtrl:ResetPataCnt()
    interactive.Send(self.m_iRemoteAddr, "partner", "ResetPataPartnerHP", {
        pid = self:GetPid(),
        })
end

function CPartnerCtrl:RemoveMineTravelPartner(iParId)
    interactive.Send(self.m_iRemoteAddr, "partner", "RemoveMineTravelPartner", {
        pid = self:GetPid(),
        parid = iParId,
        })
end

function CPartnerCtrl:UnDirty()
    super(CPartnerCtrl).UnDirty(self)
    for _,oPartner in pairs(self.m_mFightPartners) do
        oPartner:UnDirty()
    end
end

function CPartnerCtrl:IsDirty()
    local bDirty = super(CPartnerCtrl).IsDirty(self)
   if bDirty then
        return true
    end
    for _,oPartner in pairs(self.m_mFightPartners) do
        if oPartner:IsDirty() then
            return true
        end
    end
    return false
end


function CPartnerCtrl:SetEqualArena(parlist,func)
    local mData = {pid = self:GetPid(),partner = parlist,respond=1}
    local iPid = self:GetPid()
    local oWorldMgr = global.oWorldMgr
    local refunc = function(mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oPartnerCtrl:__SetEqualArena(mData.data,func)
    end
    interactive.Request(self.m_iRemoteAddr,"partner","SetEqualArena",mData,refunc)

end

function CPartnerCtrl:__SetEqualArena(parlist,func)
    self:SetData("equalarena",parlist)
    if func then
        func(parlist)
    end
end

function CPartnerCtrl:GetPartnerList(parlist,func)
    local mData = {pid = self:GetPid(),partner = parlist}
    local iPid = self:GetPid()
    local oWorldMgr = global.oWorldMgr
    local refunc = function(mRecord,mData)
        func(iPid,mData.data)
    end
    interactive.Request(self.m_iRemoteAddr,"partner","GetPartnerListByPlayer",mData,refunc)
end

function CPartnerCtrl:GetPartnerWarInfoList(parlist,func)
    local mData = {pid = self:GetPid(),partner = parlist}
    local iPid = self:GetPid()
    local oWorldMgr = global.oWorldMgr
    local refunc = function(mRecord,mData)
        func(iPid,mData.data)
    end
    interactive.Request(self.m_iRemoteAddr,"partner","GetPartnerWarInfoListByPlayer",mData,refunc)
end

function CPartnerCtrl:GetAllPartnerInfo(mInfo, func)
    local f1
    f1 = function(mRecord, mData)
        local iPid = mData.pid
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            func(mData.data)
        end
    end
    local mData = {
        pid = self:GetPid(),
        info = mInfo,
    }
    interactive.Request(self.m_iRemoteAddr,"partner","GetAllPartnerInfo",mData,f1)
end

function CPartnerCtrl:BackUpTerraWarsInfo(iPid, func)
    local f1
    f1 = function(mRecord, mData)
        local iPid = mData.pid
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            func(mData.data)
        end
    end
    local mData = {
        pid = iPid,
    }
    interactive.Request(self.m_iRemoteAddr,"partner","BackUpTerraWarsInfo",mData,f1)
end

function CPartnerCtrl:PackTerraWarInfo(mData,func)
    local f1
    f1 = function(mRecord, mData)
        local iPid = mData.pid
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            func(mData.data)
        end
    end
    local mData = {
        pid = self:GetPid(),
        partner = mData,
    }
    interactive.Request(self.m_iRemoteAddr,"partner","PackTerraWarInfo",mData,f1)
end

function CPartnerCtrl:SyncGuardInfo(mPartner)
    local mData = {
        pid = self:GetPid(),
        partner = mPartner,
    }
    interactive.Send(self.m_iRemoteAddr,"partner","SyncGuardInfo",mData)
end

function CPartnerCtrl:SyncHouseAttr(mAttr)
    local mData = {
        pid =self:GetPid(),
        attr = mAttr,
    }
    interactive.Send(self.m_iRemoteAddr,"partner","SyncHouseAttr",mData)
end

function CPartnerCtrl:UpdatePowerRank(mData)
    interactive.Send(self.m_iRemoteAddr,"partner","UpdatePowerRank",mData)
end

function CPartnerCtrl:ValidWarFightPos(lPartnerInfo)
    local iMaxPos = self:GetFightMaxPos()
    lPartnerInfo = lPartnerInfo or {}
    for _, m in ipairs(lPartnerInfo) do
        local iPos =  m.pos % 4
        if iPos == 0 then
            iPos = 4
        end
        if iPos > iMaxPos then
            return false
        end
    end
    return true
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



----
PartnerHelperFunc = {}

function PartnerHelperFunc.sid(oPartner, val)
    oPartner.SetData("sid", val)
end

function PartnerHelperFunc.parid(oPartner, val)
    oPartner:SetData("parid", val)
end

function PartnerHelperFunc.name(oPartner, val)
    oPartner:SetData("name", val)
end

function PartnerHelperFunc.grade(oPartner, val)
    oPartner:SetData("grade", val)
end

function PartnerHelperFunc.exp(oPartner, val)
    oPartner:SetData("exp", val)
end

function PartnerHelperFunc.pos(oPartner, val)
    oPartner:SetData("pos", val)
end

function PartnerHelperFunc.star(oPartner, val)
    oPartner:SetData("star", val)
end

function PartnerHelperFunc.model_info(oPartner, val)
    oPartner:SetData("model_info", val)
end

CPartner = {}
CPartner.__index = CPartner
inherit(CPartner, datactrl.CDataCtrl)

function CPartner:New(iPid, mData)
    local o = super(CPartner).New(self, {pid = iPid})
    o:Init(mData)
    return o
end

function CPartner:Init(mData)
    self:SetData("sid", mData.type or mData.sid)
    self:SetData("parid", mData.parid)
    self:SetData("name", mData.name)
    self:SetData("grade", mData.grade)
    self:SetData("exp", mData.exp or 0)
    self:SetData("pos", mData.pos or 0)
    self:SetData("star", mData.star or 1)
    self:SetData("model_info", mData.model_info)
    self:SetData("max_hp", mData.max_hp)
    self:SetData("attack", mData.attack or 0)
    self:SetData("defense", mData.defense or 0)
    self:SetData("critical_ratio", mData.critical_ratio or 0)
    self:SetData("res_critical_ratio", mData.res_critical_ratio or 0)
    self:SetData("critical_damage", mData.critical_damage or 0)
    self:SetData("cure_critical_ratio", mData.cure_critical_ratio or 0)
    self:SetData("abnormal_attr_ratio", mData.abnormal_attr_ratio or 0)
    self:SetData("res_abnormal_ratio", mData.res_abnormal_ratio or 0)
    self:SetData("speed", mData.speed or 0)
    self:SetData("power", mData.power)
    self:SetData("skill", mData.skill or {})
    self:SetData("awake", mData.awake or 0)
    self:SetData("effect_type", mData.effect_type)
    self:SetData("auto_skill",mData.auto_skill or 0)
    self:SetInfo("patahp", mData.patahp or mData.max_hp)
    self:SetInfo("terrawars_hp",mData.terrawars_hp or mData.max_hp)
    -- self:SetData("equip",mData.equip  or {})
    self:SetData("equip_plan_id",mData.equip_plan_id or 1)
    -- self:SetData("equip_plan",mData.equip_plan  or {})
    self.m_Equip = {}
    for _, m in ipairs(mData.equip  or {}) do
        local iPos = m.pos
        local mEquip = m.data
        local iSid = mEquip["sid"]
        local oEquip = loaditem.LoadItem(iSid,mEquip)
        self.m_Equip[iPos] = oEquip
    end
    self.m_mSoul = {}
    for _, m in ipairs(mData.soul or {}) do
        local iPos = m.pos
        local mSoul = m.data
        local iSid = mSoul["sid"]
        local oSoul = loaditem.LoadItem(iSid,mSoul)
        self.m_mSoul[iPos] = oSoul
    end
end

function CPartner:Save()
    local mData = {}
    mData.sid = self:GetData("sid")
    mData.parid = self:GetData("parid")
    mData.name = self:GetData("name")
    mData.grade = self:GetData("grade")
    mData.exp = self:GetData("exp")
    mData.pos = self:GetData("pos")
    mData.star = self:GetData("star")
    mData.model_info = self:GetData("model_info")
    mData.max_hp = self:GetData("max_hp")
    mData.attack = self:GetData("attack")
    mData.defense = self:GetData("defense")
    mData.critical_ratio = self:GetData("critical_ratio")
    mData.res_critical_ratio = self:GetData("res_critical_ratio")
    mData.critical_damage = self:GetData("critical_damage")
    mData.cure_critical_ratio = self:GetData("cure_critical_ratio")
    mData.abnormal_attr_ratio = self:GetData("abnormal_attr_ratio")
    mData.res_abnormal_ratio = self:GetData("res_abnormal_ratio")
    mData.speed = self:GetData("speed")
    mData.power = self:GetData("power")
    mData.skill = self:GetData("skill")
    mData.awake = self:GetData("awake")
    mData.effect_type = self:GetData("effect_type")
    mData.auto_skill = self:GetData("auto_skill")
    mData.patahp = self:GetData("patahp")
    mData.equip_plan_id = self:GetData("equip_plan_id")
    mData.equip = {}
    for iPos, oEquip in pairs(self.m_Equip) do
        table.insert(mData.equip, {pos = iPos, data = oEquip:Save()})
    end
    mData.soul = {}
    for iPos, oSoul in pairs(self.m_mSoul) do
        table.insert(mData.soul, {pos = iPos, data = oSoul:Save()})
    end

    return mData
end

function CPartner:SID()
    return self:GetData("sid")
end

function CPartner:ID()
    return self:GetData("parid")
end

function CPartner:GetName()
    return self:GetData("name")
end

function CPartner:GetGrade()
    return self:GetData("grade")
end

function CPartner:GetExp()
    return self:GetData("exp")
end

function CPartner:GetFightPos()
    return self:GetData("pos")
end

function CPartner:GetStar()
    return self:GetData("star")
end

function CPartner:GetModelInfo()
    return self:GetData("model_info")
end

function CPartner:GetMaxHP()
    return self:GetData("max_hp")
end

function CPartner:GetHP()
    return self:GetData("hp")
end

function CPartner:GetAttack()
    return self:GetData("attack")
end

function CPartner:GetDefense()
    return self:GetData("defense")
end

function CPartner:GetCriticalRatio()
    return self:GetData("critical_ratio")
end

function CPartner:GetResCriticalRatio()
    return self:GetData("res_critical_ratio")
end

function CPartner:GetCriticalDamage()
    return self:GetData("critical_damage")
end

function CPartner:GetCureCriticalRatio()
    return self:GetData("cure_critical_ratio")
end

function CPartner:GetAbnormalAttrRatio()
    return self:GetData("abnormal_attr_ratio")
end

function CPartner:GetResAbnormalRatio()
    return self:GetData("res_abnormal_ratio")
end

function CPartner:GetSpeed()
    return self:GetData("speed")
end

function CPartner:GetPower()
    return self:GetData("power",0)
end

function CPartner:GetPerformList()
    local lSkill = self:GetData("skill", {})
    local mPerform = {}
    for _, data in ipairs(lSkill) do
        local iSk = data[1]
        local iLevel = data[2]
        mPerform[iSk] = iLevel
    end
    return mPerform
end

function CPartner:IsAwake()
    return self:GetData("awake") == 1
end

function CPartner:GetAutoSkill()
    return self:GetData("auto_skill",0)
end

function CPartner:SetAutoSkill(iAutoSkill)
    self:SetData("auto_skill",iAutoSkill)
end

function CPartner:IsDoubleAttackSuspend()
    return true
end

function CPartner:UpdateData(mData)
    mData = mData or {}
    for k, v in pairs(mData) do
        local f  = assert(PartnerHelperFunc[k], string.format("UpdateData fail f get %s", k))
        f(self, v)
    end
end

function CPartner:PackWarInfo()
    return {
        type = self:SID(),
        parid = self:ID(),
        star = self:GetStar(),
        model_info = self:GetModelInfo(),
        name = self:GetName(),
        grade = self:GetGrade(),
        exp = self:GetExp(),
        max_hp = self:GetData("max_hp"),
        hp = self:GetData("max_hp"),
        attack = self:GetData("attack"),
        defense = self:GetData("defense"),
        critical_ratio = self:GetData("critical_ratio"),
        res_critical_ratio = self:GetData("res_critical_ratio"),
        critical_damage = self:GetData("critical_damage"),
        cure_critical_ratio = self:GetData("cure_critical_ratio"),
        abnormal_attr_ratio = self:GetData("abnormal_attr_ratio"),
        res_abnormal_ratio = self:GetData("res_abnormal_ratio"),
        speed = self:GetData("speed"),
        power = self:GetPower(),
        perform = self:GetPerformList(),
        awake = self:IsAwake(),
        auto_skill = self:GetAutoSkill(),
        double_attack_suspend = self:IsDoubleAttackSuspend(),
        effect_type = self:GetData("effect_type"),
        equip = self:PackWarEquip(),
    }
end

function CPartner:PackWarEquip()
    local lSid  = {}
    for iPos, oEquip in pairs(self.m_Equip) do
        table.insert(lSid, oEquip:SID())
    end
    return lSid
end

function CPartner:PackPataWarInfo()
    local data = self:PackWarInfo()
    local iHp = self:GetInfo("patahp", self:GetMaxHP())
    data.hp = iHp
    return data
end

function CPartner:PackTerraWarInfo()
    local data = self:PackWarInfo()
    local iHp = self:GetInfo("terrawars_hp", self:GetMaxHP())
    data.hp = iHp
    return data
end

function CPartner:GetLimitGrade()
    return 60
end

function CPartner:GetStarData()
    local iStar = self:GetStar()
    local mStar = res["daobiao"]["partner"]["star"][iStar]
    assert(mStar, string.format("partner star err: %s, %s, %s", self:GetInfo("pid"), self:ID(), iStar))
    return mStar
end

function CPartner:PackNetLinkPartner()
    local mNet = {
        pid = self.m_Pid  or 0,
        name = "",
        parinfo = self:PackPartnerBase(),
        equip= self:PackPartnerEquip(),
        soul = self:PackPartnerSoul(),
    }
    return mNet
end

function CPartner:PackPartnerSoul()
    local lSoul = {}
    for iPos, oSoul in pairs(self.m_mSoul) do
        table.insert(lSoul, {pos = iPos, soul = oSoul:PackItemInfo()})
    end
    return lSoul
end

function CPartner:PackPartnerBase()
    return {
    partner_type = self:SID(),
    parid = self:ID(),
    name = self:GetName(),
    star = self:GetStar(),
    model_info = self:GetModelInfo(),
    grade = self:GetGrade(),
    exp = self:GetExp(),
    hp = self:GetData("max_hp"),
    max_hp = self:GetMaxHP(),
    attack = self:GetData("attack"),
    defense = self:GetData("defense"),
    critical_ratio = self:GetData("critical_ratio"),
    res_critical_ratio = self:GetData("res_critical_ratio"),
    abnormal_attr_ratio = self:GetData("abnormal_attr_ratio"),
    res_abnormal_ratio = self:GetData("res_abnormal_ratio"),
    critical_damage = self:GetData("critical_damage"),
    cure_critical_ratio = self:GetCureCriticalRatio(),
    speed = self:GetData("speed"),
    power = self:GetPower(),
    lock = 0,
    awake = self:GetData("awake"),
    skill = self:PackSkill(),
    equip_plan_id = self:GetData("equip_plan_id",1),
    equip_plan = {},
    equip_list = {},
    patahp = self:GetData("patahp",self:GetMaxHP())
    }
end


function CPartner:PackSkill()
    local mNet = {}
    local mSkill = res["daobiao"]["partner"]["partner_info"][self:SID()]["skill_list"]
    local mAllSkill = self:GetData("skill",{})
    for _,mPer in pairs(mAllSkill) do
        local iSkill = mPer[1]
        if extend.Array.find(mSkill,iSkill) then
            table.insert(mNet,{sk=mPer[1],level=mPer[2]})
        end
    end
    return mNet
end

function CPartner:GetEquipInfo()
    return self.m_Equip
end

function CPartner:PackPartnerEquip()
    local  mNet = {}
    for iPos,oEquip in  pairs(self:GetEquipInfo()) do
        table.insert(mNet,{pos=iPos,equip =  oEquip:PackItemInfo()})
    end
    return mNet
end
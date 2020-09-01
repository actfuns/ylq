local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local res = require "base.res"
local record = require "public.record"

local itembase = import(service_path("item/itembase"))
local makeequip = import(service_path("item/makeequip"))
local handleitem = import(service_path("item/handleitem"))
local itemdefines = import(service_path("item/itemdefines"))
local loaditem = import(service_path("item/loaditem"))
local loadskill = import(service_path("skill/loadskill"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "equip"

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    o.m_mK = {}
    o.m_mGem = {}
    o.m_mFuWen = {}
    o.m_mStrength = {}
    o.m_mStoneSE = {}
    o.m_mFuwenPlan = {}
    o.m_iStrengthLevel = 0
    return o
end

function CItem:Load(mData)
    super(CItem).Load(self,mData)
    self.m_mApply = mData["apply"] or self.m_mApply
    self.m_mRatioApply = mData["ratio_apply"] or self.m_mRatioApply
    self.m_mK = mData["k"] or self.m_mK

    local mGem = mData["gem"] or {}
    for iPos,mGemData in pairs(mGem) do
        iPos = tonumber(iPos)
        local iShape = mGemData["sid"]
        local oGem = loaditem.LoadItem(iShape,mGemData)
        self.m_mGem[iPos] = oGem
    end
    self.m_mFuWen = mData["fuwen"] or self.m_mFuWen
    local mFuWen = mData["fuwen_plan"] or {}
    for sPlan, m in pairs(mFuWen) do
        local iPlan = tonumber(sPlan)
        self.m_mFuwenPlan[iPlan] = m
    end

    local mSE = mData["se"] or {}
    for _,mSEData in pairs(mSE) do
        local iSkill = mSEData["skill_id"]
        local oSE = loadskill.LoadSkill(iSkill, mData)
        self.m_mStoneSE[iSkill] = oSE
    end
end

function CItem:Save()
    local mData = super(CItem).Save(self)
    mData["apply"] = self.m_mApply
    mData["ratio_apply"] = self.m_mRatioApply
    mData["k"] = self.m_mK

    local mGem = {}
    for iPos,oGem in pairs(self.m_mGem) do
        mGem[db_key(iPos)] = oGem:Save()
    end
    mData["gem"] = mGem
    local mFuWen = {}
    for iPlan, m in pairs(self.m_mFuwenPlan) do
        mFuWen[db_key(iPlan)] = m
    end
    mData["fuwen_plan"] = mFuWen
    mData["fuwen"] = self.m_mFuWen
    local mSE = {}
    for _,oSE in pairs(self.m_mStoneSE) do
        table.insert(mSE,oSE:Save())
    end
    mData["se"] = mSE
    return mData
end

function CItem:EquipPos()
    return self:GetItemData()["pos"]
end

function CItem:EquipLevel()
    return self:GetItemData()["equip_level"]
end

function CItem:School()
    return self:GetItemData()["school"]
end

function CItem:Sex()
    return self:GetItemData()["sex"]
end

--套装类型
function CItem:SetType()
    local iStoneShape = self:GetStoneShape()
    if iStoneShape then
        local oEquipStone = loaditem.GetItem(iStoneShape)
        return oEquipStone:SetType()
    end
    return 0
end

function CItem:SkillLevel()
    local iStoneShape = self:GetStoneShape()
    if iStoneShape then
        local oEquipStone = loaditem.GetItem(iStoneShape)
        return oEquipStone:SkillLevel()
    end
    return 0
end

function CItem:Model()
    local iStoneShape = self:GetStoneShape()
    if iStoneShape then
        local oEquipStone = loaditem.GetItem(iStoneShape)
        return oEquipStone:Model()
    end
    return 0
end

function CItem:WeaponType()
    return self:GetItemData()["weapon_type"]
end

function CItem:SetItemLevel(iItemLevel)
    if iItemLevel and iItemLevel > 0 then
        self.m_iItemLevel = iItemLevel
    end
end

function CItem:SetLock()
    if self:IsLock() then
        self:SetData("lock", 0)
    else
        self:SetData("lock", 1)
    end
end

function CItem:IsLock()
    return self:GetData("lock", 0) == 1
end

function CItem:Create(...)
    local mArgs = {...}
    mArgs = mArgs[1] or {}
    self:SetItemLevel(mArgs.item_level)
end

function CItem:GetPower()
    local oAssistMgr = global.oAssistMgr
    local iPower = 0
    local iPid = self:GetOwner()
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    local iSchool  = self:GetData("school",1)
    if oPlayer then
        iSchool = oPlayer:GetSchool()
    end

    local mPower = res["daobiao"]["school_convert_power"][iSchool]
    assert(mPower, string.format("equip power err: %s, %s, %s", iPid, self:ID(), iSchool))

    local mAttrName = res["daobiao"]["attrname"]
    for sAttr, mAttr in pairs(mAttrName) do
        local iMul = mPower[sAttr] / 100
        iPower = iPower + self:GetApply(sAttr, 0) * iMul
    end

    local iStoneShape = self:GetStoneShape()

    local oEquipStone = loaditem.GetItem(iStoneShape)
    iPower = iPower + oEquipStone:SEPower()
    return math.floor(iPower)
end

function CItem:CalPower()
    local oAssistMgr = global.oAssistMgr
    local iPower = 0
    local iPid = self:GetOwner()
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    local iSchool  = self:GetData("school",1)
    if oPlayer then
        iSchool = oPlayer:GetSchool()
    end

    local mPower = res["daobiao"]["school_convert_power"][iSchool]
    assert(mPower, string.format("equip power err: %s, %s, %s", iPid, self:ID(), iSchool))

    local mAttrName = res["daobiao"]["attrname"]
    for sAttr, mAttr in pairs(mAttrName) do
        local iMul = mPower[sAttr] / 100
        iPower = iPower + (self:GetApply(sAttr, 0) + self:GetFuWenAttr(sAttr, 0) + self:GetGemAttr(sAttr, 0)) * iMul
    end

    local iStoneShape = self:GetStoneShape()
    local oEquipStone = loaditem.GetItem(iStoneShape)
    iPower = iPower + oEquipStone:SEPower()
    return math.floor(iPower)
end

function CItem:SEPower()
    local iStoneShape = self:GetStoneShape()
    local oEquipStone = loaditem.GetItem(iStoneShape)
    return oEquipStone:SEPower()
end

function CItem:AddApply(sAttr,iValue)
    self:Dirty()
    local iAttr = self.m_mApply[sAttr] or 0
    self.m_mApply[sAttr] = iAttr + iValue
end

function CItem:GetApply(sAttr,rDefault)
    return self.m_mApply[sAttr] or rDefault
end

function CItem:ResetApply()
    self:Dirty()
    self.m_mApply = {}
    self.m_mRatioApply = {}
    self.m_mK = {}
end

function CItem:AddRatioApply(sAttr,iValue)
    self:Dirty()
    local iRatio = self.m_mRatioApply[sAttr] or 0
    self.m_mRatioApply[sAttr] = iRatio + iValue
end

function CItem:GetRatioApply(sAttr,rDefault)
    return self.m_mRatioApply[sAttr] or rDefault
end

function CItem:AddFuWen(sAttr,iValue)
    -- self:Dirty()
    -- self.m_mFuWen[sAttr] = iValue
end

function CItem:GetFuWenAttr(sAttr,rDefault)
    local iValue = rDefault or 0
    local m = self:CurrentFuWen()
    if m[sAttr] then
        iValue = m[sAttr].value or rDefault
    end
    return m[sAttr]
end

function CItem:GetGemAttr(sAttr,rDefault)
    local iAttr = 0
    for iPos, oGem in pairs(self.m_mGem) do
        iAttr = iAttr + oGem:GetApply(sAttr, rDefault)
    end
    return iAttr
end

--装备不能进行穿戴和卸下的操作
function CItem:Use(oPlayer,target)
    --
end

function CItem:Wield(oPlayer)
    self:SetInfo("wield", 1)
    self:CalApply(oPlayer)
end

function CItem:UnWield(oPlayer)
    self:SetInfo("wield", nil)
    self:UnCalApply(oPlayer)
end

function CItem:IsWield()
    return self:GetInfo("wield")
end

--使用装备灵石
function CItem:UseEquipStone(mApply)
    self:Dirty()
    local iStoneShape = mApply["shape"]
    self:SetStoneShape(iStoneShape)
    self:SetName(mApply["name"])
    self:SetData("equip_power", mApply["equip_power"] or 0)

    self:ResetApply()

    local mNewApply = mApply["apply_list"]
    for sAttr,iValue in pairs(mNewApply) do
        self:AddApply(sAttr,iValue)
    end

    local mNewRatioApply = mApply["ratio_apply_list"]
    for sAttr,iRatio in pairs(mNewRatioApply) do
        self:AddRatioApply(sAttr,iValue)
    end

    local mSE = mApply["se"]
    if mSE then
        for iSE, iLevel in pairs(mSE) do
            local oSE = loadskill.NewSkill(iSE)
            oSE:SetLevel(iLevel)
            self.m_mStoneSE[iSE] = oSE
        end
    end
end

function CItem:CreateEquipStone()
    local iStoneShape = self:GetStoneShape()
    if not iStoneShape or iStoneShape == 0 then
        return
    end

    local mArgs = {
        apply = self.m_mApply,
        ratio_apply = self.m_mRatioApply,
        k = self.m_mK,
    }
    local oEquipStone = loaditem.LoadItem(iStoneShape,mArgs)
    return oEquipStone
end

function CItem:CalApply(oPlayer)
    for sAttr,iValue in pairs(self.m_mApply) do
        oPlayer.m_oEquipMgr:AddApply(sAttr,self:EquipPos(),iValue)
    end
    for sAttr,iValue in pairs(self.m_mRatioApply) do
        oPlayer.m_oEquipMgr:AddRatioApply(sAttr,self:EquipPos(),iValue)
    end
    for _,oGem in pairs(self.m_mGem) do
        oGem:Effect(oPlayer)
    end
    -- for sAttr,iValue in pairs(self.m_mFuWen) do
    --     oPlayer.m_oEquipMgr:AddApply(sAttr,self:EquipPos(),iValue)
    -- end
    self:CalFuWen(oPlayer)
    self:StrengthEffect(oPlayer)
    for _,oSE in pairs(self.m_mStoneSE) do
        if oSE:IsEffect() then
            oSE:SkillEffect(oPlayer)
        end
    end
end

function CItem:UnCalApply(oPlayer)
    local iPos = self:EquipPos()
    for sAttr,iValue in pairs(self.m_mApply) do
        oPlayer.m_oEquipMgr:AddApply(sAttr,iPos,-iValue)
    end

    for sAttr,iValue in pairs(self.m_mRatioApply) do
        oPlayer.m_oEquipMgr:AddRatioApply(sAttr,iPos,-iValue)
    end

    -- for sAttr, iValue in pairs(self.m_mFuWen) do
    --     oPlayer.m_oEquipMgr:AddApply(sAttr,iPos,-iValue)
    -- end
    self:UnCalFuWen(oPlayer)
    for _,oGem in pairs(self.m_mGem) do
        oGem:UnEffect(oPlayer)
    end
    self:StrengthUnEffect(oPlayer)
    for _,oSE in pairs(self.m_mStoneSE) do
        oSE:SkillUnEffect(oPlayer)
    end
end

function CItem:GetLock()
    return self:GetData("lock", 0)
end

function CItem:ApplyInfo()
    local mData = {}
    for sAttr,iValue in pairs(self.m_mApply) do
        table.insert(mData,{key=sAttr,value=iValue})
    end
    for sAttr,iValue in pairs(self.m_mRatioApply) do
        table.insert(mData,{key=sAttr,value=iValue})
    end
    table.insert(mData, {key = "equip_power", value = self:GetData("equip_power")})
    return mData
end

function CItem:PackApplyInfo(mKeys)
    local mApplyData = {}
    for sKey, mAttrData in pairs(mKeys) do
        local mData = {}
        for sAttr,iValue in pairs(mAttrData) do
            table.insert(mData, {key=sAttr,value=iValue})
        end
        if sKey == "strength_attr" then
            table.insert(mData,{key = "level",value = self.m_iStrengthLevel})
        end
        if table_count(mData) ~= 0 then
            mApplyData[sKey] = mData
        end
    end
    return mApplyData
end

function CItem:PackFuWenInfo()
    local l = {}
    for iPlan, m in pairs(self.m_mFuwenPlan) do
        local mNet = {}
        mNet["plan"] = iPlan
        local lApply = {}
        for sAttr, m in pairs(m["fuwen"] or {}) do
            table.insert(lApply, {key = sAttr, value = m.value, quality = m.quality})
        end
        mNet["fuwen_attr"] = lApply
        lApply = {}
        for sAttr, m in pairs(m["back_fuwen"] or {}) do
            table.insert(lApply, {key = sAttr, value = m.value, quality = m.quality})
        end
        mNet["back_fuwen"] = lApply
        mNet["level"] = self:FuWenLevel(iPlan)
        table.insert(l, mNet)
    end
    return l
end

function CItem:PackEquipInfo()
    local mEquipInfo = self:PackApplyInfo({
        strength_attr = self.m_mStrength,
    })
    local mGem = {}
    for iPos,oGem in pairs(self.m_mGem) do
        local mApply = {}
        local mApplyInfo = oGem:ApplyInfo()
        for sApply,iValue in pairs(mApplyInfo) do
            table.insert(mApply,{key=sApply,value=iValue})
        end
        table.insert(mGem,{
            pos = iPos,
            sid = oGem:Shape(),
            apply_info = mApply,
        })
    end
    local iPos = self.m_iPos or self:EquipPos()
    mEquipInfo["pos"] = iPos
    mEquipInfo["gem_attr"] = mGem
    mEquipInfo["fuwen"] = self:PackFuWenInfo()
    mEquipInfo["fuwen_plan"] = self:GetData("fuwen_plan")
    mEquipInfo["stone_sid"] = self:GetStoneShape()
    return mEquipInfo
end

function CItem:PackItemInfo()
    local mNet = super(CItem).PackItemInfo(self)
    mNet["equip_info"] = self:PackEquipInfo()
    return mNet
end

--装备灵石
function CItem:GetStoneShape()
    local iShape = self:GetData("stone")
    return iShape
end

function CItem:SetStoneShape(iShape)
    self:SetData("stone",iShape)
end

--复制属性到新装备
function CItem:BackUp(oNewEquip)
    local mPlan = table_deep_copy(self.m_mFuwenPlan)
    oNewEquip:BackFuWenPlan(mPlan)
    oNewEquip:SetData("fuwen_plan", self:GetFuWenPlanID())
    self.m_mFuwenPlan = {}
    for iPos,oGem in pairs(self.m_mGem) do
        oNewEquip:AddGem(iPos,oGem)
    end
    self.m_mGem = {}
end

function CItem:GemLevelSort()
    local mData = {}
    for iPos,oGem in pairs(self.m_mGem) do
        table.insert(mData,{oGem:Level(),iPos})
    end
    local func = function (data1,data2)
        if data1[1] ~= data2[1] then
            return data1[1] < data2[1]
        else
            return data1[2] < data2[2]
        end
    end
    table.sort(mData,func)
    return mData
end

function CItem:AddGem(iPos,oGem)
    self:Dirty()
    self.m_mGem[iPos] = oGem
end

function CItem:RemoveGem(iPos)
    local oGem = self:GetGem(iPos)
    if oGem then
        self:Dirty()
        self.m_mGem[iPos] = nil
    end
end

function CItem:GetGem(iPos)
    return self.m_mGem[iPos]
end

function CItem:GemCount()
    return table_count(self.m_mGem)
end

function CItem:GetMinLevelGemPos(iPosCnt)
    iPosCnt = iPosCnt
    local oGem, iMinPos
    for iPos = 1, iPosCnt do
        local o = self:GetGem(iPos)
        if o then
            oGem = oGem or o
            if oGem:Level() >= o:Level() then
                oGem = o
                iMinPos = iPos
            end
        else
            iMinPos = iPos
            break
        end
    end
    return iMinPos
end

function CItem:AddGemExp(iPos,iExp,sReason)
    local oAssistMgr = global.oAssistMgr
    local oGem = self.m_mGem[iPos]
    assert(oGem,string.format("equip addgemexp err:%s %s %s",self:GetOwner(),iPos,iExp))
    local iPid = self:GetOwner()
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    assert(oPlayer,string.format("equip gemexp err player:%s %s %s",iPid,iPos,iExp))
    oGem:AddExp(iExp,sReason)
    self:Dirty()
    local iExp = oGem:GetExp()
    local iUpLevelExp = oGem:GetUpLevelExp()
    local iGemShape = oGem:SID()
    local iNewShape
    local iRemainExp = iExp
    while(iExp >= iUpLevelExp) do
        iNewShape = iGemShape + 1
        iRemainExp = iExp - iUpLevelExp
        local oNewGem = loaditem.GetItem(iNewShape)
        if oNewGem:IsMaxLevel() then
            break
        end
        iUpLevelExp = oNewGem:GetUpLevelExp()
        iGemShape = iNewShape
    end
    if not iNewShape then
        return
    end
    local oNewGem = loaditem.Create(iNewShape)
    oNewGem:AddExp(iRemainExp)
    oGem:UnEffect(oPlayer)
    self.m_mGem[iPos] = oNewGem
    oNewGem:Effect(oPlayer)

    if oNewGem:Level() >= 3 then
        global.oAssistMgr:PushAchieve(iPid, "宝石3级次数", {value = 1})
    end
end

function CItem:StrengthEffectData(iPos,iStrengthLevel)
    local res = require "base.res"
    local mData = res["daobiao"]["strength"][iPos][iStrengthLevel]
    assert(mData,string.format("strength effect err:%s %s",iPos,iStrengthLevel))
    return mData
end

function CItem:GetAttrData()
    local res = require "base.res"
    return res["daobiao"]["attrname"]
end

function CItem:StrengthEffect(oPlayer)
    local iPos = self:EquipPos()
    local iPid = oPlayer.m_iPid
    local iStrengthLevel = oPlayer:StrengthLevel(iPos)
    if not iStrengthLevel or iStrengthLevel <= 0 then
        return
    end
    self.m_iStrengthLevel = iStrengthLevel
    local mEffectData = self:StrengthEffectData(iPos,iStrengthLevel)
    local mAttr = self:GetAttrData()
    for sAttr,_ in pairs(mAttr) do
        local iValue = mEffectData[sAttr]
        if iValue > 0 then
            self.m_mStrength[sAttr] = math.floor(iValue)
            oPlayer.m_oEquipMgr:AddApply(sAttr,self:EquipPos(),iValue)
        end
    end
end

function CItem:StrengthUnEffect(oPlayer)
    for sApply,iValue in pairs(self.m_mStrength) do
        oPlayer.m_oEquipMgr:AddApply(sApply,self:EquipPos(),-iValue)
    end
end

function CItem:SendFuWen(oPlayer)
    oPlayer:Send("GS2CFuWenInfo",{
        itemid = self:ID(),
        cur_plan = self:GetData("fuwen_plan"),
        fuwen = self:PackFuWenInfo(),
        })
end

function CItem:BackFuWenPlan(mPlan)
    self:Dirty()
    self.m_mFuwenPlan = mPlan or {}
end

function CItem:UseBackFuWen(oPlayer, iLevel)
    local iPlan = self:GetData("fuwen_plan")
    local m = self.m_mFuwenPlan[iPlan]
    if m then
        self:Dirty()

        local mOld = m["fuwen"]
        self:UnCalFuWen(oPlayer)
        m["fuwen"] = m["back_fuwen"]
        m["level"] = iLevel or m["level"]
        self:CalFuWen(oPlayer)
        m["back_fuwen"] = nil

        local mLog = {
            pid = self:GetOwner(),
            pos = self:EquipPos(),
            plan = iPlan,
            old_fuwen = ConvertTblToStr(mOld),
            now_fuwen = ConvertTblToStr(m["fuwen"]),
        }
        record.user("equip", "save_fuwen", mLog)
    end
end

function CItem:FuWenLevel(iPlan)
    local m = self.m_mFuwenPlan[iPlan]
    if m then
        return m["level"] or 0
    end
    return 0
end

function CItem:GetSE()
    return self.m_mStoneSE
end

function CItem:GetFuWenPlanID()
    return self:GetData("fuwen_plan")
end

function CItem:GetFuWenPlan(iPlan)
    return self.m_mFuwenPlan[iPlan]
end

function CItem:CurrentFuWen()
    local iPlan = self:GetData("fuwen_plan")
    local m = self.m_mFuwenPlan[iPlan]
    local mFuWen = {}
    if m then
        mFuWen = m["fuwen"] or mFuWen
    end
    return mFuWen
end

function CItem:CurrentBackFuWen()
    local iPlan = self:GetData("fuwen_plan")
    local m = self.m_mFuwenPlan[iPlan]
    if m then
        return m["back_fuwen"]
    end
end
--mFuWen: fuwen包含品质字段
function CItem:AddFuWenPlan(iPlan, mPlan)
    self:Dirty()
    mPlan = mPlan or {}
    self.m_mFuwenPlan[iPlan] = mPlan
end

function CItem:UseFuWenPlan(oPlayer, iPlan, sReason)
    local m = self.m_mFuwenPlan[iPlan]
    if m then
        self:Dirty()
        self:UnCalFuWen(oPlayer)
        self:SetData("fuwen_plan", iPlan)
        self:CalFuWen(oPlayer)

        local mLog = {
            pid = oPlayer:GetPid(),
            pos = self:EquipPos(),
            plan = iPlan,
            reason = sReason,
        }
        record.user("equip", "use_fuwen_plan", mLog)
    end
end

function CItem:UnCalFuWen(oPlayer)
    -- local bWield = self:GetData("wield")
    local mFuWen = self:CurrentFuWen()
    local iPos = self:EquipPos()
    for sAttr, m in pairs(mFuWen) do
        oPlayer.m_oEquipMgr:AddApply(sAttr,iPos,-m.value)
    end
end

function CItem:CalFuWen(oPlayer)
    -- local bWield = self:GetData("wield")
    if self:IsWield() then
        local mFuWen = self:CurrentFuWen()
        local iPos = self:EquipPos()
        for sAttr, m in pairs(mFuWen) do
            oPlayer.m_oEquipMgr:AddApply(sAttr,iPos,m.value)
        end
    end
end

function CItem:AddBackFuWen(oPlayer,mApply)
    self:Dirty()
    mApply = mApply or {}
    local iPlan = self:GetData("fuwen_plan")
    local m = self.m_mFuwenPlan[iPlan]
    if m then
        m["back_fuwen"] = mApply
        local mLog = {
            pid = oPlayer:GetPid(),
            pos = self:EquipPos(),
            plan = self:GetFuWenPlanID(),
            back_fuwen = ConvertTblToStr(m["back_fuwen"])
        }
        record.user("equip", "new_fuwen", mLog)
    end
end

function CItem:CountGemLevel()
    local iCount = 0
    for iPos ,oGem in pairs(self.m_mGem) do
        iCount = iCount + oGem:Level()
    end
    return iCount
end

function CItem:LogGem(iBeforeExp, iAfterExp, sReason)
    local mLog = {
        pid = self:GetOwner(),
        pos = self:EquipPos(),
        before_exp = iBeforeExp,
        after_exp = iAfterExp,
        reason = sReason,
    }
    record.user("equip", "equip_gem", mLog)
end
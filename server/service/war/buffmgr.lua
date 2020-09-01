--import module

local global = require "global"
local skynet = require "skynet"

local buffload = import(service_path("buff/buffload"))

function NewBuffMgr(...)
    local o = CBuffMgr:New(...)
    return o
end

CBuffMgr = {}
CBuffMgr.__index = CBuffMgr
inherit(CBuffMgr, logic_base_cls())

function CBuffMgr:New(iWarId,iWid)
    local o = super(CBuffMgr).New(self)
    o.m_iWarId = iWarId
    o.m_iWid = iWid
    o.m_mBuffs = {}

    o.m_mAttrRatio = {}
    o.m_mAttrAdd = {}
    o.m_mAttrTempRatio = {}
    o.m_mAttrTempAdd = {}

    o.m_mAttr = {}
    o.m_mFunction = {}
    return o
end

--buff组最大数目
function CBuffMgr:GetBuffGroupMaxCnt(iType)
    local res = require "base.res"
    local mData = res["daobiao"]["bufflimit"][iType]
    return mData["maxcnt"]
end

function CBuffMgr:GetGroupReplaceType(iType)
    local res = require "base.res"
    local mData = res["daobiao"]["buff_smallgroup"][iType]
    assert(mData,string.format("buff small group replace:%s",iType))
    return mData
end


function CBuffMgr:GetWar()
    local oWarMgr = global.oWarMgr
    return oWarMgr:GetWar(self.m_iWarId)
end

function CBuffMgr:GetWarrior()
    local oWar = self:GetWar()
    return oWar:GetWarrior(self.m_iWid)
end

function CBuffMgr:ValidReplaceGroup(oBuff,oNewBuff)
    if oBuff:PerformLevel() ~= oNewBuff:PerformLevel() then
        return oBuff:PerformLevel() < oNewBuff:PerformLevel()
    end
    if oBuff:Bout() ~= oNewBuff:Bout() then
        return oBuff:Bout() < oNewBuff:Bout()
    end
    return true
end

function CBuffMgr:ValidAddBuff(oBuff)
    local oAction = self:GetWarrior()
    return oAction:OnAddBuff(oBuff)
end

function CBuffMgr:AddBuff(iBuffID,iBout,mArgs)
    local oNewBuff = buffload.NewBuff(iBuffID,iBout,mArgs)
    oNewBuff:Init(iBout,mArgs)
    if not self:ValidAddBuff(oNewBuff) then
        return
    end
    local iType = oNewBuff:Type()
    local iGroupType = oNewBuff:GroupType()
    local mBuff = self.m_mBuffs[iType] or {}
    local mGroupBuff = mBuff[iGroupType] or {}
    for _,oBuff in pairs(mGroupBuff) do
        self:OnAddGroupBuff(oNewBuff,oBuff)
        return
    end
    local iCnt = table_count(mBuff)
    local iMaxCnt = self:GetBuffGroupMaxCnt(iType)
    if iCnt >= iMaxCnt then
        local mKey = table_key_list(mBuff)
        local iGroupType = mKey[math.random(#mKey)]
        mGroupBuff = mBuff[iGroupType]
        for _,oBuff in pairs(mGroupBuff) do
            self:RemoveBuff(oBuff)
            self:TrueAddBuff(oNewBuff)
            return
        end
    end
    self:TrueAddBuff(oNewBuff)
    local oAction = self:GetWarrior()
    oAction:OnAddBuffHandle(oNewBuff)
    return oNewBuff
end

function CBuffMgr:OnAddGroupBuff(oNewBuff,oBuff)
    local iGroupType = oNewBuff:GroupType()
    local mReplaceType = self:GetGroupReplaceType(iGroupType)
    local iType = mReplaceType["replace_type"]
    if oNewBuff.m_ID == oBuff.m_ID then
        local iType = oNewBuff:UpdateType()
        if iType == 1 then                                                     --无法叠加
            return
        elseif iType == 2 then                                              --叠加，但是以旧时间为限制
            local oAction = self:GetWarrior()
            oBuff:Overlying(oAction,oNewBuff)
        elseif iType == 3 then                                             --直接覆盖
            self:RemoveBuff(oBuff)
            self:TrueAddBuff(oNewBuff)
        elseif iType == 4 then                                              --取效果最强                                     
            if self:ValidReplaceGroup(oBuff,oNewBuff) then
                self:RemoveBuff(oBuff)
                self:TrueAddBuff(oNewBuff)
            end
        end
        return
    end
    if iType == 1 then                                                     --无法叠加
        return
    elseif iType == 2 then                                              --叠加，但是以旧时间为限制
        --
    elseif iType == 3 then                                             --直接覆盖
        self:RemoveBuff(oBuff)
        self:TrueAddBuff(oNewBuff)
    elseif iType == 4 then                                             --取效果最强
        if self:ValidReplaceGroup(oBuff,oNewBuff) then
            self:RemoveBuff(oBuff)
            self:TrueAddBuff(oNewBuff)
        end
    end
end

function CBuffMgr:TrueAddBuff(oBuff)
    local iBuffID = oBuff.m_ID
    local iType = oBuff:Type()
    local iGroupType = oBuff:GroupType()
    local mBuff = self.m_mBuffs[iType] or {}
    local mGroupBuff = mBuff[iGroupType] or {}
    mGroupBuff[oBuff.m_ID] = oBuff
    mBuff[iGroupType]  = mGroupBuff
    self.m_mBuffs[iType] = mBuff
    
    local oWarrior = self:GetWarrior()
    -- 获得BUFF时，他是当前施法者，不需要减回合
    if oWarrior:IsCurrentAction() then
        oBuff.m_NoSubNowWar = 1
    end
    oBuff:CalInit(oWarrior,self)

    self:BuffEffect(oBuff)

    local oAction = self:GetWarrior()
    if oAction then
        oAction:SendAll("GS2CWarBuffBout", {
            war_id = self.m_iWarId,
            wid = self.m_iWid,
            buff_id = oBuff.m_ID,
            bout  = oBuff:Bout(),
            level = 1,
            produce_wid = oBuff:GetAttack(),
        })
    end
    local mArgs = oBuff:GetArgs()
    local iAttack = mArgs["attack"]
    if iAttack then
        local oWar = self:GetWar()
        local oAttack = oWar:GetWarrior(iAttack)
        if oAttack then
            local mFunction = oAction:GetFunction("OnAddedBuff")
            for _,fCallback in pairs(mFunction) do
                fCallback(oAction,oAttack,oBuff)
            end
            local mFunction = oAttack:GetFunction("OnGiveBuff")
            for _,fCallback in pairs(mFunction) do
                fCallback(oAttack,oAction,oBuff)
            end
        end
    end
end

function CBuffMgr:BuffEffect(oBuff)
    local mEnv = {}
    local sArgs = oBuff:AttrRatioList()
    local iBuffID = oBuff.m_ID
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:SetAttrBaseRatio(sApply,iBuffID,iValue)
        end
    end
    local sArgs = oBuff:AttrValueList()
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:SetAttrAddValue(sApply,iBuffID,iValue)
        end
    end
    local sArgs = oBuff:AttrTempRatio()
    if sArgs and  sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:SetAttrTempRatio(sApply,iBuffID,iValue)
        end
    end
    local sArgs = oBuff:AttrTempAddValue()
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:SetAttrTempValue(sApply,iBuffID,iValue)
        end
    end
    local sArgs = oBuff:AttrMask()
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:SetAttr(sApply,iValue)
            oBuff:SetAttr(sApply,iValue)
        end
    end
end

function CBuffMgr:OnOverlying(oBuff)
    local mEnv = {}
    local sArgs = oBuff:AttrRatioList()
    local iBuffID = oBuff.m_ID
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:AddAttrBaseRatio(sApply,iBuffID,iValue)
        end
    end
    local sArgs = oBuff:AttrValueList()
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:AddAttrValue(sApply,iBuffID,iValue)
        end
    end
    local sArgs = oBuff:AttrTempRatio()
    if sArgs and  sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:AddAttrTempRatio(sApply,iBuffID,iValue)
        end
    end
    local sArgs = oBuff:AttrTempAddValue()
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:AddAttrTempValue(sApply,iBuffID,iValue)
        end
    end
end

function CBuffMgr:RemoveBuff(oBuff)
    local iType = oBuff:Type()
    local iGroupType = oBuff:GroupType()
    local mBuff = self.m_mBuffs[iType] or {}
    local mGroupBuff = mBuff[iGroupType] or {}
    local iBuffID = oBuff.m_ID
    mGroupBuff[iBuffID] = nil
    if table_count(mGroupBuff) <= 0 then
        mBuff[iGroupType] = nil
    else
        mBuff[iGroupType] = mGroupBuff
    end
    self.m_mBuffs[iType] = mBuff

    local oAction = self:GetWarrior()
    oBuff:OnRemove(oAction,oBuffMgr)
    local mAttrName = {"m_mAttrRatio","m_mAttrAdd","m_mAttrTempRatio","m_mAttrTempAdd"}
    for _,sAttrName in pairs(mAttrName) do
        local mApply = self[sAttrName]
        for sAttr,mAttrs in pairs(mApply) do
            mAttrs = mAttrs or {}
            mAttrs[iBuffID] = nil
            if table_count(mAttrs) == 0 then
                mApply[sAttr] = nil
            end
        end
    end

    self:RemoveFunctionByBuff(iBuffID)

    local mSet = oBuff:GetSetAttr()
    for key,value in pairs(mSet) do
        local mBuff = self:GetBuffList()
        local bDelete = true
        for _,oNowBuff in pairs(mBuff) do
            if oNowBuff:HasAttr(key) then
                bDelete = false
                break
            end
        end
        if bDelete then
            self:SetAttr(key,nil)
        end
    end
    oBuff:RefreshBuff(oAction,{level=0,bout=0})
end



function CBuffMgr:TryRemoveCasterBuff()
    local oAction = self:GetWarrior()
    if not oAction.m_CheckCasterBoutEndBuff and not oAction.m_CheckCasterBoutStartBuff then
        return
    end
    oAction.m_CheckCasterBoutEndBuff = nil
    oAction.m_CheckCasterBoutStartBuff = nil
    local oWar = oAction:GetWar()
    local iWid = oAction:GetWid()


    local rf = function (oWarrior,iAttack)
        local lBuff = oWarrior.m_oBuffMgr:GetBuffList()
        for _,oBuff in pairs(lBuff) do
            if (oBuff:IsCasterEndSub() or oBuff:IsCasterStartSub())and oBuff:GetAttack() == iAttack then
                oWarrior.m_oBuffMgr:RemoveBuff(oBuff)
            end
        end
    end

    local f = function (warriorlist)
        for _,o in ipairs(warriorlist) do
            rf(o,iWid)
        end
    end

    f(oAction:GetFriendList(true))
    f(oAction:GetEnemyList(true))
end


function CBuffMgr:TrySubBoutEndCasterBuff(oAction)
    if not oAction or not oAction.m_CheckCasterBoutEndBuff then
        return
    end
    local bRmFlag = true

    local oWar = oAction:GetWar()
    local iWid = oAction:GetWid()


    local rf = function (oWarrior,iAttack)
        local lBuff = oWarrior.m_oBuffMgr:GetBuffList()
        for _,oBuff in pairs(lBuff) do
            if oBuff:IsCasterEndSub() and oBuff:GetAttack() == iAttack then
                bRmFlag = false
                oWarrior.m_oBuffMgr:CheckCasterActionEnd(oAction)
            end
        end
    end

    local f = function (warriorlist)
        for _,o in ipairs(warriorlist) do
            rf(o,iWid)
        end
    end

    f(oAction:GetFriendList(true))
    f(oAction:GetEnemyList(true))
    if bRmFlag then
        oAction.m_CheckCasterBoutEndBuff = nil
    end

end

function CBuffMgr:TrySubBoutStartCasterBuff(oAction)
    if not oAction or not oAction.m_CheckCasterBoutStartBuff then
        return
    end
    local bRmFlag = true

    local oWar = oAction:GetWar()
    local iWid = oAction:GetWid()


    local rf = function (oWarrior,iAttack)
        local lBuff = oWarrior.m_oBuffMgr:GetBuffList()
        for _,oBuff in pairs(lBuff) do
            if oBuff:IsCasterStartSub() and oBuff:GetAttack() == iAttack then
                bRmFlag = false
                oWarrior.m_oBuffMgr:CheckCasterActionStart(oAction)
            end
        end
    end

    local f = function (warriorlist)
        for _,o in ipairs(warriorlist) do
            rf(o,iWid)
        end
    end

    f(oAction:GetFriendList(true))
    f(oAction:GetEnemyList(true))
    if bRmFlag then
        oAction.m_CheckCasterBoutStartBuff = nil
    end

end

function CBuffMgr:GetClassBuff(iClass)
    local mBuff = self.m_mBuffs[iClass] or {}
    local mRet = {}
    for _,mGroupBuff in pairs(mBuff) do
        for _,oBuff in pairs(mGroupBuff) do
            table.insert(mRet,oBuff)
        end
    end
    return mRet
end

function CBuffMgr:ClearBuff()
    local lBuff = self:GetBuffList()
    for _,oBuff in pairs(lBuff) do
        self:RemoveBuff(oBuff)
    end
end

--清除大组buff
function CBuffMgr:RemoveClassBuff(iClass)
    local mBuff = self.m_mBuffs[iClass] or {}
    for _,mGroupBuff in pairs(mBuff) do
        for _,oBuff in pairs(mGroupBuff) do
            self:RemoveBuff(oBuff)
        end
    end
end

--清除小组buff
function CBuffMgr:RemoveGroupClassBuff(iClass,iGroupType)
    local mBuff = self.m_mBuffs[iClass] or {}
    local mGroupBuff = mBuff[iGroupType] or {}
    for _,oBuff in pairs(mGroupBuff) do
        self:RemoveBuff(oBuff)
    end
end

function CBuffMgr:RemoveRandomBuff(iClass)
    local mBuff = self.m_mBuffs[iClass]
    if not mBuff then
        return false
    end
    local mKey = table_key_list(mBuff)
    if #mKey <= 0 then
        return false
    end
    local iGroupType = mKey[math.random(#mKey)]
    self:RemoveGroupClassBuff(iClass,iGroupType)
    return true
end

function CBuffMgr:HasBuff(iBuffID)
    local oBuff = buffload.GetBuff(iBuffID)
    local iType = oBuff:Type()
    local iGroupType = oBuff:GroupType()
    local mBuff = self.m_mBuffs[iType] or {}
    local mGroupBuff = mBuff[iGroupType] or {}
    for _,oBuff in pairs(mGroupBuff) do
        if oBuff.m_ID == iBuffID then
            return oBuff
        end
    end
end

function CBuffMgr:GetAttrBaseRatio(sAttr,rDefault)
    rDefault = rDefault or 0
    local iBaseRatio = 0
    local mRatio = self.m_mAttrRatio[sAttr] or {}
    for _,iRatio in pairs(mRatio) do
        iBaseRatio = iBaseRatio + iRatio
    end
    return iBaseRatio
end

function CBuffMgr:SetAttrBaseRatio(sAttr,iBuffID,iValue)
    local mAttrRatio = self.m_mAttrRatio[sAttr] or {}
    mAttrRatio[iBuffID] = iValue
    self.m_mAttrRatio[sAttr] = mAttrRatio
end

function CBuffMgr:AddAttrBaseRatio(sAttr,iBuffID,iValue)
    local mAttrRatio = self.m_mAttrRatio[sAttr] or {}
    local iRatio = mAttrRatio[iBuffID] or 0
    mAttrRatio[iBuffID] = iRatio + iValue
    self.m_mAttrRatio[sAttr] = mAttrRatio
end

function CBuffMgr:GetAttrAddValue(sAttr,rDefault)
    rDefault = rDefault or 0
    local mAddValue = self.m_mAttrAdd[sAttr] or {}
    local iAddValue = 0
    for _,iValue in pairs(mAddValue) do
        iAddValue = iAddValue + iValue
    end
    return iAddValue
end

function CBuffMgr:SetAttrAddValue(sAttr,iBuffID,iValue)
    local mAttrAdd = self.m_mAttrAdd[sAttr] or {}
    mAttrAdd[iBuffID] = iValue
    self.m_mAttrAdd[sAttr] = mAttrAdd
end

function CBuffMgr:AddAttrValue(sAttr,iBuffID,iValue)
    local mAttrAdd = self.m_mAttrAdd[sAttr] or {}
    local iAdd = mAttrAdd[iBuffID] or 0
    mAttrAdd[iBuffID] = iAdd + iValue
    self.m_mAttrAdd[sAttr] = mAttrAdd
end

function CBuffMgr:GetAttrTempRatio(sAttr,rDefault)
    local iTempRatio = 0
    local mTempRatio = self.m_mAttrTempRatio[sAttr] or {}
    for _,iRatio in pairs(mTempRatio) do
        iTempRatio = iTempRatio + iRatio
    end
    return iTempRatio
end

function CBuffMgr:SetAttrTempRatio(sAttr,iBuffID,iRatio)
    local mTempRatio = self.m_mAttrTempRatio[sAttr] or {}
    mTempRatio[iBuffID] = iRatio
    self.m_mAttrTempRatio[sAttr] = mTempRatio
end

function CBuffMgr:AddAttrTempRatio(sAttr,iBuffID,iRatio)
    local mTempRatio = self.m_mAttrTempRatio[sAttr] or {}
    local iTempRatio = mTempRatio[iBuffID] or 0
    iTempRatio = iTempRatio + iRatio
    self.m_mAttrTempRatio[sAttr] = mTempRatio
end

function CBuffMgr:GetAttrTempAddValue(sAttr,rDefault)
    rDefault = rDefault or 0
    local mTempAdd = self.m_mAttrTempAdd[sAttr] or {}
    local iTempAdd = 0
    for _,iValue in pairs(mTempAdd) do
        iTempAdd = iTempAdd + iValue 
    end
    return iTempAdd
end

function CBuffMgr:SetAttrTempValue(sAttr,iBuffID,iValue)
    local mAttrTemp = self.m_mAttrTempAdd[sAttr] or {}
    mAttrTemp[iBuffID] = iValue
    self.m_mAttrTempAdd[sAttr] = mAttrTemp
end

function CBuffMgr:AddAttrTempValue(sAttr,iBuffID,iValue)
    local mAttrTemp = self.m_mAttrTempAdd[sAttr] or {}
    local iTempAdd = mAttrTemp[iBuffID] or 0
    mAttrTemp[iBuffID] = iTempAdd + iValue
    self.m_mAttrTempAdd[sAttr] = mAttrTemp
end

function CBuffMgr:SetAttr(sAttr,iValue)
    self.m_mAttr[sAttr] = iValue
end

function CBuffMgr:GetAttr(sAttr,rDefault)
    return self.m_mAttr[sAttr] or rDefault
end

function CBuffMgr:GetBuffList()
    local mBuffList = {}
    for _,mBuff in pairs(self.m_mBuffs) do
        for _,mGroupBuff in pairs(mBuff) do
            for _,oBuff in pairs(mGroupBuff) do
                table.insert(mBuffList,oBuff)
            end
        end
    end
    return mBuffList
end

function CBuffMgr:OnBoutStart(oAction)
    local lBuff = self:GetBuffList()
    for _,oBuff in pairs(lBuff) do
        oBuff:OnBuffBoutStart(oAction)
    end
end

function CBuffMgr:ValidSubAttackBuff(oAction)
    if not oAction:QueryBoutArgs("action_sort") then
        return true
    end
    if oAction:IsCurrentAction() then
        return true
    end
    return false
end

function CBuffMgr:CheckAttackBuff(oAction)
    if not self:ValidSubAttackBuff(oAction)  or not oAction:IsCurrentAction()then
        return
    end
    local lBuff = self:GetBuffList()
    for _,oBuff in pairs(lBuff) do
        if self:ValidAttackSub(oBuff) then
            self:SubBout(oAction,oBuff)
        end
    end
end

function CBuffMgr:ValidAttackSub(oBuff)
    local oWar = self:GetWar()
    if not oBuff:IsAttackSub() then
        return false
    end
    if oBuff:GetBuffStartBout() == oWar.m_iBout then
        if oBuff:GetAttack() == self.m_iWid then
            return false
        end
        if oBuff.m_NoSubNowWar then
            return false
        end
    end
    return true
end


function CBuffMgr:CheckActionEndBuff(oAction)
    if  not oAction:IsCurrentAction()then
        return
    end
    local lBuff = self:GetBuffList()
    for _,oBuff in pairs(lBuff) do
        if self:ValidActionEndSub(oBuff)then
            self:SubBout(oAction,oBuff)
        end
    end
    self:TrySubBoutEndCasterBuff(oAction)
end

function CBuffMgr:CheckActionStartBuff(oAction)
    if  not oAction:IsCurrentAction()then
        return
    end
    self:TrySubBoutStartCasterBuff(oAction)
end

function CBuffMgr:CheckCasterActionEnd(oWarrior)
    local lBuff = self:GetBuffList()
    local bRet = false
    local oAction = self:GetWarrior()
    for _,oBuff in pairs(lBuff) do
        if self:ValidCasterEndSub(oBuff,oAction,oWarrior) then
            bRet = true
            self:SubBout(oAction,oBuff)
        end
    end
    return bRet
end

function CBuffMgr:CheckCasterActionStart(oWarrior)
    local lBuff = self:GetBuffList()
    local bRet = false
    local oAction = self:GetWarrior()
    for _,oBuff in pairs(lBuff) do
        if self:ValidCasterStartSub(oBuff,oAction,oWarrior) then
            bRet = true
            self:SubBout(oAction,oBuff)
        end
    end
    return bRet
end

function CBuffMgr:SubBout(oAction,oBuff)
    oBuff:SubBout()
    if oBuff:Bout() < 1 then
        self:RemoveBuff(oBuff)
    else
        oBuff:RefreshBuff(oAction)
    end
end


function CBuffMgr:ValidActionEndSub(oBuff)
    local oWar = self:GetWar()
    if not oBuff:IsActionEndSub() then
        return false
    end
    if oBuff:GetBuffStartBout() == oWar.m_iBout then
        if oBuff.m_NoSubNowWar then
            return false
        end
    end
    return true
end

function CBuffMgr:ValidCasterEndSub(oBuff,oAction,oAttack)
    local oWar = self:GetWar()
    if not oBuff:IsCasterEndSub() then
        return false
    end
    if oBuff:GetAttack() ~= oAttack:GetWid() then
        return false
    end
    if oBuff:GetBuffStartBout() == oWar.m_iBout then
        if oBuff.m_NoSubNowWar then
            return false
        end
    end
    return true
end

function CBuffMgr:ValidCasterStartSub(oBuff,oAction,oAttack)
    local oWar = self:GetWar()
    if not oBuff:IsCasterStartSub() then
        return false
    end
    if oBuff:GetAttack() ~= oAttack:GetWid() then
        return false
    end
    return true
end

function CBuffMgr:OnReplacePartner(oAction)
    self:TryRemoveCasterBuff()
end




function CBuffMgr:OnBoutEnd(oAction)
    local lBuff = self:GetBuffList()
    for _,oBuff in pairs(lBuff) do
        if oBuff:IsBoutEndSub() then
            oBuff:SubBout()
            oBuff:RefreshBuff(oAction)
        end
        oBuff:OnBuffBoutEnd(oAction,self)
        if oBuff:Bout() < 1 then
            self:RemoveBuff(oBuff)
        end
    end
end

function CBuffMgr:OnDead(oAction)
    local lBuff = self:GetBuffList()
    for _,oBuff in pairs(lBuff) do
        if oBuff:IsDieClean() then
            self:RemoveBuff(oBuff)
        end
    end
    self:TryRemoveCasterBuff()
end

function CBuffMgr:HasKey(sKey)
    if self.m_mAttr[sKey] then
        return true
    end
    return false
end

function CBuffMgr:ClassBuffCnt(iClass)
    local mBuff = self.m_mBuffs[iClass] or {}
    local iCnt = 0
    for _,mGroupBuff in pairs(mBuff) do
        for _,oBuff in pairs(mGroupBuff) do
            iCnt = iCnt + 1
        end
    end
    return iCnt
end

function CBuffMgr:HasGroupType(iClass,iGroupType)
    local mBuff = self.m_mBuffs[iClass] or {}
    local mGroupBuff = mBuff[iGroupType]
    return mGroupBuff
end


function CBuffMgr:AddFunction(sKey,iNo,fCallback)
    local mFunctor = self.m_mFunction[sKey] or {}
    mFunctor[iNo] = fCallback
    self.m_mFunction[sKey] = mFunctor
end

function CBuffMgr:GetFunction(sKey)
    return self.m_mFunction[sKey] or {}
end

function CBuffMgr:RemoveFunction(sKey,iNo)
    local mFunctor = self.m_mFunction[sKey] or {}
    mFunctor[iNo] = nil
    self.m_mFunction[sKey] = mFunctor
    local oWarrior = self:GetWarrior()
end

function CBuffMgr:RemoveFunctionByBuff(iNo)
    local mKey = table_key_list(self.m_mFunction)
    for _,sKey in pairs(mKey) do
        self:RemoveFunction(sKey,iNo)
    end
end


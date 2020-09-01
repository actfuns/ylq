--import module

local global = require "global"
local skynet = require "skynet"

local pfload = import(service_path("perform/pfload"))

function NewPerformMgr(...)
    local o = CPerformMgr:New(...)
    return o
end

CPerformMgr = {}
CPerformMgr.__index = CPerformMgr
inherit(CPerformMgr, logic_base_cls())

function CPerformMgr:New(iWarId,iWid)
    local o = super(CPerformMgr).New(self)
    o.m_iWarId = iWarId
    o.m_iWid = iWid
    o.m_mPerform = {}

    o.m_mAttrRatio = {}
    o.m_mAttrAdd = {}

    o.m_mAttrs = {}
    o.m_mFunction = {}
    return o
end

function CPerformMgr:GetWar()
    local oWarMgr = global.oWarMgr
    return oWarMgr:GetWar(self.m_iWarId)
end

function CPerformMgr:GetWarrior()
    local oWar = self:GetWar()
    return oWar:GetWarrior(self.m_iWid)
end

function CPerformMgr:SetPerform(oAttack,iPerform,iLevel)
    local oPerform = pfload.NewPerform(iPerform)
    assert(oPerform,"perform err:%d",iPerform)
    oPerform:SetLevel(iLevel)
    oPerform:CalWarrior(oAttack,self)
    self:CalPerformAttr(oPerform)
    self.m_mPerform[iPerform] = oPerform
end

function CPerformMgr:GetPerform(iPerform)
   return self.m_mPerform[iPerform]
end

function CPerformMgr:GetPerformList()
    local mPerform = {}
    for iPerform,oPerform in pairs(self.m_mPerform) do
        if oPerform:CanPerform() then
            table.insert(mPerform,iPerform)
        end
    end
    return mPerform
end

function CPerformMgr:GetPerformLevelList()
    local lPerform = {}
    for iPerform,oPerform in pairs(self.m_mPerform) do
        if oPerform:CanPerform() then
            table.insert(lPerform, {id=iPerform, level = oPerform:Level()})
        end
    end
    return lPerform
end

function CPerformMgr:Query(k,rDefault)
    return self.m_mAttrs[k] or rDefault
end

function CPerformMgr:Add(key,value)
    local v = self.m_mAttrs[key] or 0
    self.m_mAttrs[key] = value + v
end

function CPerformMgr:Set(key,value)
    self.m_mAttrs[key] = value
end

function CPerformMgr:GetAttrBaseRatio(sAttr)
    local mBaseRatio = self.m_mAttrRatio[sAttr] or {}
    local iBaseRatio = 0
    for _,iRatio in pairs(mBaseRatio) do
        iBaseRatio = iBaseRatio + iRatio
    end
    return iBaseRatio
end

function CPerformMgr:SetAttrBaseRatio(sAttr,iPerform,iValue)
    local mBaseRatio = self.m_mAttrRatio[sAttr] or {}
    mBaseRatio[iPerform] = iValue
    self.m_mAttrRatio[sAttr] = mBaseRatio
end

function CPerformMgr:AddAttrBaseRatio(sAttr,iPerform,iValue)
    local mBaseRatio = self.m_mAttrRatio[sAttr] or {}
    local iRet = mBaseRatio[iPerform] or 0
    mBaseRatio[iPerform] = iRet + iValue
    self.m_mAttrRatio[sAttr] = mBaseRatio
end

function CPerformMgr:GetAttrAddValue(sAttr)
    local mAddValue = self.m_mAttrAdd[sAttr] or {}
    local iAddValue = 0
    for _,iValue in pairs(mAddValue) do
        iAddValue = iAddValue + iValue
    end
    return iAddValue
end

function CPerformMgr:SetAttrAddValue(sAttr,iPerform,iValue)
    local mAddValue = self.m_mAttrAdd[sAttr] or {}
    mAddValue[iPerform] = iValue
    self.m_mAttrAdd[sAttr] = mAddValue
end

function CPerformMgr:AddFunction(sKey,iNo,fCallback)
    local mFunction = self.m_mFunction[sKey] or {}
    mFunction[iNo] = fCallback
    self.m_mFunction[sKey] = mFunction
end

function CPerformMgr:GetFunction(sKey)
    return self.m_mFunction[sKey] or {}
end

function CPerformMgr:RemoveFunction(sKey,iNo)
    local mFunction = self.m_mFunction[sKey] or {}
    mFunction[iNo] = nil
    self.m_mFunction[sKey] = mFunction
end

function CPerformMgr:ActionEnd()
    for iPerform,oPerform in pairs(self.m_mPerform) do
        oPerform:SubCD()
    end
end



function CPerformMgr:CalPerformAttr(oPerform)
    local mData = oPerform:GetSkillData()
    local iEffectType = mData["effect_type"]
    --战斗外生效
    if iEffectType == 1 then
        return
    end
    local sArgs = mData["attr_ratio_list"]
    local iPerform = oPerform:Type()
    local mEnv = {}
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:SetAttrBaseRatio(sApply,iPerform,iValue)
        end
    end
    local sArgs = mData["attr_value_list"]
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:SetAttrAddValue(sApply,iPerform,iValue)
        end
    end
    local sArgs = mData["attr_temp_ratio"]
    if sArgs and  sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:SetAttrTempRatio(sApply,iPerform,iValue)
        end
    end
    local sArgs = mData["attr_temp_addvalue"]
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            self:SetAttrTempValue(sApply,iPerform,iValue)
        end
    end
end
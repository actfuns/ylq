--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"

CBuff = {}
CBuff.__index = CBuff
inherit(CBuff, logic_base_cls())

function CBuff:New(id)
    local o = super(CBuff).New(self)
    o.m_ID = id
    o.m_mAttrs = {}
    return o
end

function CBuff:Init(iBout,mArgs)
     mArgs = mArgs or {}
     self.m_iBout = iBout
     self.m_iBuffLevel = 1
     self.m_mArgs = mArgs
end

function CBuff:GetBuffData()
    local res = require "base.res"
    local mData = res["daobiao"]["buff"][self.m_ID]
    return mData
end

function CBuff:GetBuffEffectData()
    local res = require "base.res"
    local iLv = self.m_mArgs["level"]
    assert(iLv,string.format("buff_effect err:%s %s",self.m_ID,iLv))
    local mData = res["daobiao"]["buff_effect"]
    local ret = {}
    if not mData[self.m_ID] then
        return ret
    end
    local ret = mData[self.m_ID][iLv] or {}
    return ret
end

--等级效果环境变量参数
function CBuff:GetBuffArgsEnv()
    local mData = self:GetBuffEffectData()
    local sArgs = mData["args"]
    local mArgs = {}
    if not sArgs then
        return mArgs
    end
    local mEnv = {}
    mArgs = formula_string(sArgs,mEnv)
    return mArgs
end

function CBuff:Type()
    local mData = self:GetBuffData()
    return mData["type"]
end

function CBuff:GroupType()
    local mData = self:GetBuffData()
    return mData["group_type"]
end

--叠加或者替换
function CBuff:UpdateType()
    local mData = self:GetBuffData()
    return mData["update_type"]
end

function CBuff:SubType()
    local mData = self:GetBuffData()
    local mArgs = self:GetArgs()
    return mArgs["sub_type"] or mData["sub_type"] or {}
end


function CBuff:InSubType(v)
    local mType = self:SubType()
    for _,iType in pairs(mType) do
        if iType == v then
            return true
        end
    end
    return false
end

function CBuff:IsAttackSub()
    return self:InSubType(2)
end


function CBuff:IsBoutEndSub()
    return self:InSubType(1)
end

function CBuff:IsActionEndSub()
    return self:InSubType(4)
end

function CBuff:IsCasterEndSub()
    return self:InSubType(5)
end

function CBuff:IsCasterStartSub()
    return self:InSubType(6)
end


function CBuff:GetAttack()
    return self.m_mArgs["attack"] or 0
end

function CBuff:GetBuffStartBout()
    return self.m_mArgs["buff_bout"]
end

function CBuff:IsDieClean()
    local mData = self:GetBuffData()
    local iFlag = mData["die_clean"] or 1
    if iFlag == 1 then
        return true
    end
    return false
end

function CBuff:IsSkillClean()
    local mData = self:GetBuffData()
    local iFlag = mData["skill_clean"] or 0
    if iFlag == 1 then
        return true
    end
    return false
end

function CBuff:ValidOverlying(oAction,oNewBuff)
    local mData = self:GetBuffData()
    local iLevel = self:BuffLevel()
    local iLimit = mData["delay_level"]
    if iLevel >= iLimit then
        return false
    end
    return true
end

function CBuff:Overlying(oAction,oNewBuff)
    if not self:ValidOverlying(oAction,oNewBuff) then
        return
    end
    local iLevel = self:BuffLevel()
    self:SetBuffLevel(iLevel+1)
    local oBuffMgr = oAction.m_oBuffMgr
    oBuffMgr:OnOverlying(self)
    self:OnOverlying(oAction)
    self:RefreshBuff(oAction)
end

function CBuff:RefreshBuff(oAction,mArgs)
    local mNet =    {
        war_id = oAction:GetWarId(),
        wid = oAction:GetWid(),
        buff_id = self.m_ID,
        bout = self:Bout(),
        level = self:BuffLevel(),
        produce_wid = self:GetAttack(),
    }
    if mArgs then
        for k,v in pairs(mArgs) do
            mNet[k] = v
        end
    end
    oAction:SendAll("GS2CWarBuffBout",mNet)
end

function CBuff:UseBuffLevel(oAction)
    local iLevel = self:BuffLevel()
    self:SetBuffLevel(iLevel-1)
    if self:BuffLevel() <= 0 then
        oAction.m_oBuffMgr:RemoveBuff(self)
    else
        self:RefreshBuff(oAction)
    end
end

function CBuff:OnOverlying(oAction)
    -- body
end

function CBuff:AttrRatioList()
    local mApplyData = self:GetBuffEffectData()
    return mApplyData["attr_ratio_list"]
end

function CBuff:AttrValueList()
    local mApplyData = self:GetBuffEffectData()
    return mApplyData["attr_value_list"]
end

function CBuff:AttrTempRatio()
    local mApplyData = self:GetBuffEffectData()
    return mApplyData["attr_temp_ratio"]
end

function CBuff:AttrTempAddValue()
    local mApplyData = self:GetBuffEffectData()
    return mApplyData["attr_temp_addvalue"]
end

function CBuff:AttrMask()
    local mData = self:GetBuffData()
    return mData["attr_set"]
end

function CBuff:SetAttr(key,value)
    self.m_mAttrs[key] = value
end

function CBuff:GetSetAttr()
    return self.m_mAttrs or {}
end

function CBuff:HasAttr(sKey)
    if self.m_mAttrs[sKey] then
        return true
    end
    return false
end

function CBuff:PerformLevel()
    return self.m_mArgs["level"] or 0
end

--可叠加buff层级
function CBuff:BuffLevel()
    return self.m_iBuffLevel
end

function CBuff:SetBuffLevel(iLevel)
    self.m_iBuffLevel = iLevel
end

function CBuff:GetArgs()
    return self.m_mArgs
end

function CBuff:CalInit(oAction,oBuffMgr)
end

function CBuff:OnRemove(oAction,oBuffMgr)
end

function CBuff:OnBuffBoutStart(oAction,oBuffMgr)

end

function CBuff:OnBuffBoutEnd(oAction,oBuffMgr)
end

function CBuff:Bout()
    return self.m_iBout
end

function CBuff:AddBout(iBout)
    self.m_iBout = self.m_iBout + iBout
end

function CBuff:InBuffClassType(iType)
    local mData = self:GetBuffData()
    local mBuff = mData["buff_class"]
    if extend.Array.find(mBuff,iType) then
        return true
    else
        return false
    end
end


function CBuff:SubBout(iBout)
    iBout = iBout or 1
    self.m_iBout = self.m_iBout - iBout
end

function CBuff:ModifyHp(oVictim,iHp,mArgs)
    mArgs = mArgs or {}
    mArgs["type"] = "buff"
    mArgs["BuffID"] = self.m_ID
    if not mArgs["attack_wid"] then
        mArgs["attack_wid"] = self:GetAttack()
    end
    oVictim:ModifyHp(iHp,mArgs)
end


function CBuff:ShowPerfrom(oAction,mArg)
    mArg = mArg or {}
    local oWar = oAction:GetWar()
    local iSkill = mArg["skill"] or self.m_ID
    local mNet = {skill = iSkill}
    mNet["type"] = mArg["type"] or 5
    mNet["wid"] = mArg["wid"] or oAction:GetWid()
    oWar:SendAll("GS2CShowWarSkill",mNet)
end

function NewBuff(...)
    local o = CBuff:New(...)
    return o
end
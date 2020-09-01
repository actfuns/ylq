--import module

local global = require "global"
local skynet = require "skynet"

local shareobj = import(lualib_path("base.shareobj"))
local attrmgr = import(lualib_path("public.attrmgr"))

function NewEquipMgr(iPid)
    local o = CEquipMgr:New(iPid)
    return o
end

CEquipMgr = {}
CEquipMgr.__index =CEquipMgr
inherit(CEquipMgr,attrmgr.CAttrMgr)

function CEquipMgr:New(iPid)
    local o = super(CEquipMgr).New(self,iPid)
    o.m_iPid = iPid
    o.m_oEquipMgrShareObj = CEquipMgrShareObj:New()
    o.m_iEquipPower = 0
    return o
end

function CEquipMgr:Release()
    baseobj_safe_release(self.m_oEquipMgrShareObj)
    super(CEquipMgr).Release(self)
end

function CEquipMgr:SyncData(mData)
    self.m_mApply = mData.apply or self.m_mApply
    self.m_mRatioApply = mData.ratio_apply or self.m_mRatioApply
    self.m_iEquipPower = mData.power or self.m_iEquipPower
end

function CEquipMgr:InitShareObj(oRemoteShare)
    self.m_oEquipMgrShareObj:Init(oRemoteShare)
end

function CEquipMgr:ShareUpdate()
    self:BeforeShareUpdate()
    self.m_oEquipMgrShareObj:Update()
    self:AfterShareUpdate()
end

function CEquipMgr:BeforeShareUpdate()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iPid)
    if oPlayer then
        local oShareObj = self.m_oEquipMgrShareObj
        local mApply = oShareObj.m_mApply or {}
        local mRatioApply = oShareObj.m_mRatioApply or {}
        local mApplyAttr,mApplyRatioAttr = {},{}
        for sAttr,_ in pairs(mApply) do
            mApplyAttr[sAttr] = 0
        end
        oPlayer:ExecuteCPower("MultiSetApply","equip",mApplyAttr)
        for sAttr,_ in pairs(mRatioApply) do
            mApplyRatioAttr[sAttr] = 0
        end
        oPlayer:ExecuteCPower("MultiSetRatioApply","equip",mApplyRatioAttr)
    end
end

function CEquipMgr:AfterShareUpdate()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iPid)
    if oPlayer then
        local oShareObj = self.m_oEquipMgrShareObj
        local mApply = oShareObj.m_mApply or {}
        local mRatioApply = oShareObj.m_mRatioApply or {}
        local mApplyAttr,mApplyRatioAttr = {},{}
        for sAttr,mInfo in pairs(mApply) do
            mApplyAttr[sAttr] = mApplyAttr[sAttr] or 0
            for _,v in pairs(mInfo) do
                mApplyAttr[sAttr] = mApplyAttr[sAttr] + v
            end
        end
        oPlayer:ExecuteCPower("MultiSetApply","equip",mApplyAttr)
        for sAttr,mInfo in pairs(mRatioApply) do
            mApplyRatioAttr[sAttr] = mApplyRatioAttr[sAttr] or 0
            for _,v in pairs(mInfo) do
                mApplyRatioAttr[sAttr] = mApplyRatioAttr[sAttr] + v
            end
        end
        oPlayer:ExecuteCPower("MultiSetRatioApply","equip",mApplyRatioAttr)
        oPlayer:ExecuteCPower("SetEquipPower",oShareObj:GetWieldEquipPower())
    end
end

function CEquipMgr:GetApply(sApply)
    local mApply = self.m_oEquipMgrShareObj:GetApply(sApply)
    local iValue = 0
    for _,v in pairs(mApply) do
        iValue = iValue + v
    end
    return iValue
end

function CEquipMgr:GetRatioApply(sApply)
    local mRatioApply = self.m_oEquipMgrShareObj:GetRatioApply(sApply)
    local iValue = 0
    for _,v in pairs(mRatioApply) do
        iValue = iValue + v
    end
    return iValue
end

function CEquipMgr:GetWieldEquipPower()
    return self.m_oEquipMgrShareObj:GetWieldEquipPower()
end

CEquipMgrShareObj = {}
CEquipMgrShareObj.__index = CEquipMgrShareObj
inherit(CEquipMgrShareObj, shareobj.CShareReader)

function CEquipMgrShareObj:New()
    local o = super(CEquipMgrShareObj).New(self)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    o.m_iEquipPower = 0
    return o
end

function CEquipMgrShareObj:Unpack(m)
    self.m_mApply = m.apply or self.m_mApply
    self.m_mRatioApply = m.ratio_apply or self.m_mRatioApply
    self.m_iEquipPower = m.power or self.m_iEquipPower
end

function CEquipMgrShareObj:GetApply(sApply)
    return self.m_mApply[sApply] or {}
end

function CEquipMgrShareObj:GetRatioApply(sApply)
    return self.m_mRatioApply[sApply] or {}
end

function CEquipMgrShareObj:GetWieldEquipPower()
    return self.m_iEquipPower
end
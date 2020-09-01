--import module

local global = require "global"
local skynet = require "skynet"

local shareobj = import(lualib_path("base.shareobj"))
local attrmgr = import(lualib_path("public.attrmgr"))

function NewStoneMgr(iPid)
    local o = CStoneMgr:New(iPid)
    return o
end

CStoneMgr = {}
CStoneMgr.__index =CStoneMgr
inherit(CStoneMgr,attrmgr.CAttrMgr)

function CStoneMgr:New(iPid)
    local o = super(CStoneMgr).New(self,iPid)
    o.m_iPid = iPid
    o.m_oStoneMgrShareObj = CStoneMgrShareObj:New()
    return o
end

function CStoneMgr:Release()
    baseobj_safe_release(self.m_oStoneMgrShareObj)
    super(CStoneMgr).Release(self)
end

function CStoneMgr:InitShareObj(oRemoteShare)
    self.m_oStoneMgrShareObj:Init(oRemoteShare)
end

function CStoneMgr:ShareUpdate()
    self:BeforeShareUpdate()
    self.m_oStoneMgrShareObj:Update()
    self:AfterShareUpdate()
end

function CStoneMgr:BeforeShareUpdate()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iPid)
    if oPlayer then
        local oShareObj = self.m_oStoneMgrShareObj
        local mApply = oShareObj.m_mApply or {}
        local mRatioApply = oShareObj.m_mRatioApply or {}
        local mApplyAttr,mApplyRatioAttr = {},{}
        for sAttr,_ in pairs(mApply) do
            mApplyAttr[sAttr] = 0
        end
        oPlayer:ExecuteCPower("MultiSetApply","stone",mApplyAttr)
        for sAttr,_ in pairs(mRatioApply) do
            mApplyRatioAttr[sAttr] = 0
        end
        oPlayer:ExecuteCPower("MultiSetRatioApply","stone",mApplyRatioAttr)
    end
end

function CStoneMgr:AfterShareUpdate()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iPid)
    if oPlayer then
        local oShareObj = self.m_oStoneMgrShareObj
        local mApply = oShareObj.m_mApply or {}
        local mRatioApply = oShareObj.m_mRatioApply or {}
        local mApplyAttr,mApplyRatioAttr = {},{}
        for sAttr,mInfo in pairs(mApply) do
            mApplyAttr[sAttr] = mApplyAttr[sAttr] or 0
            for _,v in pairs(mInfo) do
                mApplyAttr[sAttr] = mApplyAttr[sAttr] + v
            end
        end
        oPlayer:ExecuteCPower("MultiSetApply","stone",mApplyAttr)
        for sAttr,mInfo in pairs(mRatioApply) do
            mApplyRatioAttr[sAttr] = mApplyRatioAttr[sAttr] or 0
            for _,v in pairs(mInfo) do
                mApplyRatioAttr[sAttr] = mApplyRatioAttr[sAttr] + v
            end
        end
        oPlayer:ExecuteCPower("MultiSetRatioApply","stone",mApplyRatioAttr)
    end
end

function CStoneMgr:GetApply(sApply)
    local mApply = self.m_oStoneMgrShareObj:GetApply(sApply)
    local iValue = 0
    for _,v in pairs(mApply) do
        iValue = iValue + v
    end
    return iValue
end

function CStoneMgr:GetRatioApply(sApply)
    local mRatioApply = self.m_oStoneMgrShareObj:GetRatioApply(sApply)
    local iValue = 0
    for _,v in pairs(mRatioApply) do
        iValue = iValue + v
    end
    return iValue
end

CStoneMgrShareObj = {}
CStoneMgrShareObj.__index = CStoneMgrShareObj
inherit(CStoneMgrShareObj, shareobj.CShareReader)

function CStoneMgrShareObj:New()
    local o = super(CStoneMgrShareObj).New(self)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    return o
end

function CStoneMgrShareObj:Unpack(m)
    self.m_mApply = m.apply or self.m_mApply
    self.m_mRatioApply = m.ratio_apply or self.m_mRatioApply
end

function CStoneMgrShareObj:GetApply(sApply)
    return self.m_mApply[sApply] or {}
end

function CStoneMgrShareObj:GetRatioApply(sApply)
    return self.m_mRatioApply[sApply] or {}
end
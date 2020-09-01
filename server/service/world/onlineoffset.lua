local global = require "global"

function NewOnlineOffsetMgr(...)
    return COnlineOffsetMgr:New(...)
end

function Test(oPlayer)
end

local mFuncList = {
   -- [1] = Test,
}


COnlineOffsetMgr = {}
COnlineOffsetMgr.__index = COnlineOffsetMgr
inherit(COnlineOffsetMgr,logic_base_cls())

function COnlineOffsetMgr:New()
    local o = super(COnlineOffsetMgr).New(self)
    return o
end

function COnlineOffsetMgr:GetMaxVersion()
    local iMaxVersion = 0
    for iVersion,_ in pairs(mFuncList) do
        if iMaxVersion < iVersion then
            iMaxVersion = iVersion
        end
    end
    return iMaxVersion
end

function COnlineOffsetMgr:OnLogin(oPlayer)
    local iCurVersion = oPlayer.m_oActiveCtrl:GetData("offset")
    local iMaxVersion = self:GetMaxVersion()
    if iCurVersion >= iMaxVersion then
        return
    end
    oPlayer.m_oActiveCtrl:SetData("offset",iMaxVersion)
    for iVersion = iCurVersion+1,iMaxVersion do
        local sFunc = mFuncList[iVersion]
        if sFunc then
            sFunc(oPlayer)
        end
    end
end
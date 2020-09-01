--
local skynet = require "skynet"
local global = require "global"
local interactive = require "base.interactive"
local extend = require "base/extend"
local record = require "public.record"


local defines = import(service_path("offline.defines"))
local CBaseOfflineCtrl = import(service_path("offline.baseofflinectrl")).CBaseOfflineCtrl
local gamedefines = import(lualib_path("public.gamedefines"))


CPrivyCtrl = {}
CPrivyCtrl.__index = CPrivyCtrl
inherit(CPrivyCtrl, CBaseOfflineCtrl)

function CPrivyCtrl:New(iPid)
    local o = super(CPrivyCtrl).New(self, iPid)
    o.m_sDbFlag = "Privy"

    o.m_lFuncList = {}
    o.m_mOrders = {}
    return o
end

function CPrivyCtrl:Save()
    local data = {}
    data["funclist"] = self.m_lFuncList or {}
    data["orders"] = self.m_mOrders or {}
    return data
end

function CPrivyCtrl:Load(data)
    data = data or {}
    self.m_lFuncList = data["funclist"] or {}
    self.m_mOrders = data["orders"] or {}
end

function CPrivyCtrl:OnLogin(oPlayer, bReEnter)
    self:Dirty()

    local mFunc = self.m_lFuncList
    self.m_lFuncList = {}
    for _,mFuncData in ipairs(mFunc) do
        local iFuncNo,mArgs = table.unpack(mFuncData)
        local sFunc
        if iFuncNo < 10000 then
            sFunc = defines.GetFuncByNo(iFuncNo)
            safe_call(oPlayer[sFunc], oPlayer, table.unpack(mArgs))
        elseif iFuncNo < 11000 then
            sFunc = defines.GetFuncByNo(iFuncNo)
            defines.mOnlineExecute[sFunc](oPlayer, table.unpack(mArgs))
        elseif iFuncNo < 12000 then
            sFunc = defines.GetFuncByNo(iFuncNo)
            local oBackendMgr = global.oBackendMgr
            oBackendMgr[sFunc](oBackendMgr, oPlayer, table.unpack(mArgs))
        else
            sFunc = defines.GetFuncPathByNo(iFuncNo)
            safe_call(sFunc, oPlayer, table.unpack(mArgs))
        end
    end
end

function CPrivyCtrl:UnDirty()
    super(CPrivyCtrl).UnDirty(self)
end

function CPrivyCtrl:IsDirty()
    local bDirty = super(CPrivyCtrl).IsDirty(self)
    if bDirty then
        return true
    end
    return false
end

function CPrivyCtrl:AddDealedOrder(iOrderId)
    self:Dirty()
    self.m_mOrders[db_key(iOrderId)] = 1
end

function CPrivyCtrl:IsDealedOrder(iOrderId)
    return self.m_mOrders[db_key(iOrderId)]
end

function CPrivyCtrl:AddFunc(sFunc,mArgs)
    self:Dirty()
    mArgs = mArgs or {}
    local iFuncNo = defines.GetFuncNo(sFunc)
    assert(iFuncNo and iFuncNo>0,string.format("%d AddFuncList err:%s", self:GetPid(), sFunc))
    table.insert(self.m_lFuncList,{iFuncNo,mArgs})
end


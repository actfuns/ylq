--import module
local skynet = require "skynet"
local global = require "global"

local datactrl = import(lualib_path("public.datactrl"))
local stateload = import(service_path("state/stateload"))

local max = math.max
local min = math.min

CStateCtrl = {}
CStateCtrl.__index = CStateCtrl
inherit(CStateCtrl, datactrl.CDataCtrl)

function CStateCtrl:New(pid)
    local o = super(CStateCtrl).New(self, {pid = pid})
    o.m_mList = {}
    return o
end

function CStateCtrl:Load(mData)
    mData = mData or {}
    local mStateData = mData["state"] or {}
    for iState,data in pairs(mStateData) do
        iState = tonumber(iState)
        local oState = stateload.LoadState(iState,data)
        if not oState:IsOutTime() then
            oState:SetOwner(self:GetInfo("pid"))
            self.m_mList[iState] = oState
        end
    end
end

function CStateCtrl:Save()
    local mData = {}
    local mStateData = {}
    for iState,oState in pairs(self.m_mList) do
        if not oState:IsTempState() then
            mStateData[db_key(iState)] = oState:Save()
        end
    end
    mData["state"] = mStateData
    return mData
end

function CStateCtrl:Release()
    for _,oState in pairs(self.m_mList) do
        baseobj_safe_release(oState)
    end
    self.m_mList = {}
    super(CStateCtrl).Release(self)
end

function CStateCtrl:OnLogin(oPlayer,bReEnter)
    local mData = {}
    for _,oState in pairs(self.m_mList) do
        table.insert(mData,oState:PackNetInfo())
    end
    oPlayer:Send("GS2CLoginState",{state_info = mData})
end

function CStateCtrl:OnLogout(oPlayer)
end

function CStateCtrl:OnDisconnected(oPlayer)
end

function CStateCtrl:GetState(iState)
    return self.m_mList[iState]
end

function CStateCtrl:GetAllMapFlag()
    local iFlag = 0
    for iState,oState in pairs(self.m_mList) do
        iFlag = iFlag | oState:MapFlag()
    end
    return iFlag
end

function CStateCtrl:RefreshMapFlag()
    local iPid = self:GetInfo("pid")
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local iFlag = self:GetAllMapFlag()
        oPlayer:SyncSceneInfo({state=iFlag})
    end
end

function CStateCtrl:AddState(iState,mData)
    local oState = self:GetState(iState)
    --待处理，暂时返回
    if oState then
        return
    end
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    assert(oPlayer,string.format("addstate err:%d %d",iPid,iState))
    self:Dirty()
    oState = stateload.NewState(iState)
    oState:Config(oPlayer,mData)
    oState:SetOwner(iPid)
    self.m_mList[iState] = oState
    self:GS2CAddState(oState)
    return oState
end

function CStateCtrl:RemoveState(iState)
    local oState = self:GetState(iState)
    if not oState then
        return
    end
    self:Dirty()
    self.m_mList[iState] = nil
    self:GS2CRemoveState(oState)
    baseobj_safe_release(oState)
end

function CStateCtrl:GS2CAddState(oState)
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CAddState",{state_info=oState:PackNetInfo()})
end

function CStateCtrl:GS2CRemoveState(oState)
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CRemoveState",{state_id=oState:ID()})
end

function CStateCtrl:UnDirty()
    super(CStateCtrl).UnDirty(self)
    for _,oState in pairs(self.m_mList) do
        if oState:IsDirty() then
            oState:UnDirty()
        end
    end
end

function CStateCtrl:IsDirty()
    local bDirty = super(CStateCtrl).IsDirty(self)
   if bDirty then
        return true
    end
    for _,oState in pairs(self.m_mList) do
        if oState:IsDirty() then
            return true
        end
    end
    return false
end


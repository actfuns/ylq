local global = require "global"

local statebase = import(service_path("state/statebase"))

CState = {}
CState.__index = CState
inherit(CState,statebase.CState)

function CState:New(iState)
    local o = super(CState).New(self,iState)
    return o
end




function NewState(iState)
    local o = CState:New(iState)
    return o
end

function CState:TimeOut(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    assert(oPlayer,string.format("state timeout err:%d %d",iPid,self.m_iID))
    oPlayer.m_oStateCtrl:RemoveState(self.m_iID)
    oPlayer.m_oStateCtrl:RefreshMapFlag()
end
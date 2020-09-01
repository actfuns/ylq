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
